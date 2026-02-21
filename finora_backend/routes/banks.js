/**
 * Bank connection routes — RF-10
 *
 * Endpoints:
 *  GET  /institutions               – Listar bancos soportados (Salt Edge)
 *  POST /connect                    – Iniciar flujo de consentimiento
 *  GET  /callback?ref={id}          – Callback de Salt Edge (?connection_id={id})
 *  GET  /mock-auth?ref={id}         – Página mock de autenticación bancaria
 *  GET  /mock-callback?ref={id}     – Mock callback: crea cuentas demo
 *  GET  /callback-success           – HTML estático "¡Banco conectado!"
 *  GET  /accounts                   – Listar cuentas vinculadas del usuario
 *  GET  /:id/sync-status            – Polling del estado de conexión
 *  POST /:id/sync                   – Forzar re-sync de saldos
 *  POST /:id/import-transactions    – Importar transacciones reales de Salt Edge
 *  DELETE /:id/disconnect           – Eliminar conexión y cuentas
 */

const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const db = require('../services/db');
const saltedge = require('../services/saltedge');

const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-change-in-production';

// ============================================
// AUTH MIDDLEWARE
// ============================================

const authenticateToken = (req, res, next) => {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Unauthorized', message: 'No token provided' });
  }
  const token = authHeader.substring(7);
  try {
    req.user = jwt.verify(token, JWT_SECRET);
    next();
  } catch (error) {
    const msg = error.name === 'TokenExpiredError' ? 'Token expired' : 'Invalid token';
    return res.status(401).json({ error: 'Unauthorized', message: msg });
  }
};

// ============================================
// Helper: construir URL base desde la petición
// ============================================
function baseUrl(req) {
  if (process.env.APP_URL) return process.env.APP_URL.replace(/\/$/, '');
  return `${req.protocol}://${req.get('host')}`;
}

// ============================================
// GET /institutions — listar bancos (RF-10)
// ============================================
router.get('/institutions', authenticateToken, async (req, res) => {
  try {
    // country es opcional: sin él devuelve todos los bancos soportados
    const country = req.query.country || null;
    const institutions = await saltedge.listInstitutions(country);
    res.json({ institutions });
  } catch (err) {
    console.error('banks/institutions error:', err);
    res.status(500).json({ error: 'Internal Server Error', message: err.message });
  }
});

// ============================================
// POST /connect — iniciar OAuth (RF-10)
// ============================================
router.post('/connect', authenticateToken, async (req, res) => {
  const { institution_id } = req.body;
  if (!institution_id) {
    return res.status(400).json({ error: 'Bad Request', message: 'institution_id is required' });
  }

  try {
    // 1. Obtener o crear el Salt Edge Customer para este usuario.
    let saltedgeCustomerId = null;
    const existingConn = await db.query(
      `SELECT saltedge_customer_id FROM bank_connections
       WHERE user_id = $1 AND saltedge_customer_id IS NOT NULL
       LIMIT 1`,
      [req.user.userId]
    );
    if (existingConn.rows.length > 0) {
      saltedgeCustomerId = existingConn.rows[0].saltedge_customer_id;
    } else {
      saltedgeCustomerId = await saltedge.getOrCreateCustomer(req.user.userId);
    }

    // 2. Insertar registro de conexión
    const insertResult = await db.query(
      `INSERT INTO bank_connections
         (user_id, institution_id, status, saltedge_customer_id)
       VALUES ($1, $2, 'pending', $3)
       RETURNING id`,
      [req.user.userId, institution_id, saltedgeCustomerId]
    );
    const connectionId = insertResult.rows[0].id;

    // 3. Obtener nombre/logo del banco
    let institutionName = institution_id;
    let institutionLogo = null;
    try {
      const institutions = await saltedge.listInstitutions();
      const inst = institutions.find(i => i.id === institution_id);
      if (inst) {
        institutionName = inst.name;
        institutionLogo = inst.logo || null;
      }
    } catch (_) { /* no crítico */ }

    // 4. Mock mode: devolver connection_id para que el usuario configure la cuenta
    if (saltedge.isMockMode()) {
      console.log(`[mock/connect] userId=${req.user.userId} connectionId=${connectionId} institution=${institution_id}`);
      await db.query(
        `UPDATE bank_connections
         SET institution_name = $1, institution_logo = $2
         WHERE id = $3`,
        [institutionName, institutionLogo, connectionId]
      );
      return res.json({
        connection_id: connectionId,
        is_mock: true,
        institution_name: institutionName,
        // auth_url ausente → Flutter navega a página de setup de cuenta
      });
    }

    // 5. Real mode: crear sesión OAuth con Salt Edge
    const redirectUrl = `${baseUrl(req)}/api/v1/banks/callback?ref=${connectionId}`;
    const { requisitionId, authUrl } = await saltedge.createRequisition(
      saltedgeCustomerId,
      redirectUrl,
      institution_id
    );

    await db.query(
      `UPDATE bank_connections
       SET requisition_id = $1, auth_url = $2, institution_name = $3, institution_logo = $4
       WHERE id = $5`,
      [requisitionId, authUrl, institutionName, institutionLogo, connectionId]
    );

    res.json({
      connection_id: connectionId,
      auth_url: authUrl,
      institution_name: institutionName,
      is_mock: false,
    });
  } catch (err) {
    console.error('banks/connect error:', err);
    res.status(500).json({ error: 'Internal Server Error', message: err.message });
  }
});

// ============================================
// GET /callback?ref={connectionId}&connection_id={saltEdgeConnectionId}
// Salt Edge redirige aquí tras la autenticación en el banco (RF-10)
// ============================================
router.get('/callback', async (req, res) => {
  const connectionId = req.query.ref;
  if (!connectionId) {
    return res.status(400).send('Missing ref parameter');
  }

  try {
    const connResult = await db.query(
      'SELECT * FROM bank_connections WHERE id = $1',
      [connectionId]
    );
    if (connResult.rows.length === 0) {
      return res.status(404).send('Connection not found');
    }
    const conn = connResult.rows[0];
    if (conn.status === 'linked') {
      return res.redirect(`${baseUrl(req)}/api/v1/banks/callback-success`);
    }

    // Salt Edge envía el connection_id en el callback
    const saltEdgeConnectionId = req.query.connection_id;
    if (!saltEdgeConnectionId) {
      await db.query("UPDATE bank_connections SET status = 'failed' WHERE id = $1", [connectionId]).catch(() => {});
      return res.redirect(`${baseUrl(req)}/api/v1/banks/callback-success?error=1`);
    }

    // Guardar el Salt Edge connection_id como requisition_id para futuros syncs
    await db.query(
      'UPDATE bank_connections SET requisition_id = $1 WHERE id = $2',
      [saltEdgeConnectionId, connectionId]
    );

    // Obtener cuentas de Salt Edge
    const accounts = await saltedge.fetchAccounts(saltEdgeConnectionId);

    for (const acct of accounts) {
      await db.query(
        `INSERT INTO bank_accounts
           (connection_id, user_id, external_account_id, iban, account_name, currency, balance_cents)
         VALUES ($1, $2, $3, $4, $5, $6, $7)
         ON CONFLICT (external_account_id) DO UPDATE
           SET balance_cents = EXCLUDED.balance_cents,
               account_name  = EXCLUDED.account_name`,
        [connectionId, conn.user_id, acct.externalAccountId, acct.iban,
          acct.name, acct.currency, acct.balanceCents]
      );
    }

    await db.query(
      `UPDATE bank_connections
       SET status = 'linked', linked_at = NOW(), last_sync_at = NOW()
       WHERE id = $1`,
      [connectionId]
    );

    res.redirect(`${baseUrl(req)}/api/v1/banks/callback-success`);
  } catch (err) {
    console.error('banks/callback error:', err);
    await db.query(
      "UPDATE bank_connections SET status = 'failed' WHERE id = $1",
      [connectionId]
    ).catch(() => {});
    res.redirect(`${baseUrl(req)}/api/v1/banks/callback-success?error=1`);
  }
});

// ============================================
// GET /mock-auth?ref={connectionId} — página mock de autenticación (RF-10)
// ============================================
router.get('/mock-auth', (req, res) => {
  const ref = req.query.ref || '';
  const callbackUrl = `${baseUrl(req)}/api/v1/banks/mock-callback?ref=${encodeURIComponent(ref)}`;

  res.setHeader('Content-Type', 'text/html; charset=utf-8');
  res.send(`<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Banco Demo – Autorizar acceso</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
           background: #f0f4f8; display: flex; justify-content: center;
           align-items: center; min-height: 100vh; padding: 16px; }
    .card { background: white; border-radius: 16px; padding: 40px 32px;
            max-width: 400px; width: 100%; box-shadow: 0 4px 24px rgba(0,0,0,0.1); }
    .logo { width: 64px; height: 64px; background: #3B82F6; border-radius: 16px;
            display: flex; align-items: center; justify-content: center;
            font-size: 28px; margin: 0 auto 24px; }
    h1 { font-size: 22px; color: #1e293b; text-align: center; margin-bottom: 8px; }
    p { font-size: 14px; color: #64748b; text-align: center; margin-bottom: 28px; line-height: 1.5; }
    .perms { background: #f8fafc; border-radius: 12px; padding: 16px; margin-bottom: 28px; }
    .perm { display: flex; align-items: center; gap: 10px; padding: 6px 0;
            font-size: 13px; color: #374151; }
    .perm::before { content: '✓'; color: #22c55e; font-weight: bold; }
    .btn { display: block; width: 100%; padding: 14px; background: #3B82F6; color: white;
           border: none; border-radius: 12px; font-size: 16px; font-weight: 600;
           cursor: pointer; text-decoration: none; text-align: center; margin-bottom: 12px; }
    .btn:hover { background: #2563eb; }
    .btn-cancel { background: white; color: #64748b; border: 1px solid #e2e8f0; font-size: 14px; }
    .btn-cancel:hover { background: #f8fafc; }
    .badge { display: inline-block; background: #dbeafe; color: #1d4ed8;
             font-size: 11px; font-weight: 600; padding: 3px 8px; border-radius: 99px;
             text-transform: uppercase; letter-spacing: 0.05em; margin-bottom: 16px; }
    .center { text-align: center; }
  </style>
</head>
<body>
  <div class="card">
    <div class="logo">🏦</div>
    <div class="center"><span class="badge">Entorno de pruebas</span></div>
    <h1>Banco Demo</h1>
    <p>Finora solicita acceso de solo lectura a tu información bancaria a través de Salt Edge.</p>
    <div class="perms">
      <div class="perm">Ver saldo de cuentas</div>
      <div class="perm">Ver movimientos (12 meses)</div>
      <div class="perm">Datos cifrados y seguros</div>
    </div>
    <a class="btn" href="${callbackUrl}">Autorizar acceso</a>
    <a class="btn btn-cancel" href="javascript:window.close()">Cancelar</a>
  </div>
</body>
</html>`);
});

// ============================================
// GET /mock-callback?ref={connectionId} — crear cuentas mock + redirigir (RF-10)
// ============================================
router.get('/mock-callback', async (req, res) => {
  const connectionId = req.query.ref;
  if (!connectionId) {
    return res.redirect(`${baseUrl(req)}/api/v1/banks/callback-success`);
  }

  try {
    const connResult = await db.query(
      'SELECT * FROM bank_connections WHERE id = $1',
      [connectionId]
    );
    if (connResult.rows.length === 0) {
      return res.redirect(`${baseUrl(req)}/api/v1/banks/callback-success`);
    }
    const conn = connResult.rows[0];

    if (conn.status !== 'linked') {
      const mockConnectionId = conn.requisition_id || connectionId;
      const accounts = await saltedge.fetchAccounts(mockConnectionId);

      for (const acct of accounts) {
        await db.query(
          `INSERT INTO bank_accounts
             (connection_id, user_id, external_account_id, iban, account_name, currency, balance_cents)
           VALUES ($1, $2, $3, $4, $5, $6, $7)
           ON CONFLICT (external_account_id) DO NOTHING`,
          [connectionId, conn.user_id, acct.externalAccountId, acct.iban,
            acct.name, acct.currency, acct.balanceCents]
        );
      }

      await db.query(
        `UPDATE bank_connections
         SET status = 'linked', institution_name = COALESCE(institution_name, 'Banco Demo'),
             linked_at = NOW(), last_sync_at = NOW()
         WHERE id = $1`,
        [connectionId]
      );
    }
  } catch (err) {
    console.error('banks/mock-callback error:', err);
  }

  res.redirect(`${baseUrl(req)}/api/v1/banks/callback-success`);
});

// ============================================
// GET /callback-success — página de éxito estática (RF-10)
// ============================================
router.get('/callback-success', (req, res) => {
  const isError = req.query.error === '1';
  res.setHeader('Content-Type', 'text/html; charset=utf-8');
  res.send(`<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${isError ? 'Error' : '¡Banco conectado!'}</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
           background: #f0f4f8; display: flex; justify-content: center;
           align-items: center; min-height: 100vh; padding: 16px; }
    .card { background: white; border-radius: 16px; padding: 40px 32px;
            max-width: 400px; width: 100%; box-shadow: 0 4px 24px rgba(0,0,0,0.1);
            text-align: center; }
    .icon { font-size: 64px; margin-bottom: 24px; }
    h1 { font-size: 24px; color: #1e293b; margin-bottom: 12px; }
    p { font-size: 14px; color: #64748b; line-height: 1.6; margin-bottom: 28px; }
    .btn { display: inline-block; padding: 14px 32px; background: #3B82F6; color: white;
           border: none; border-radius: 12px; font-size: 16px; font-weight: 600;
           cursor: pointer; text-decoration: none; }
    .btn:hover { background: #2563eb; }
    .btn-error { background: #ef4444; }
    .countdown { font-size: 12px; color: #94a3b8; margin-top: 16px; }
  </style>
</head>
<body>
  <div class="card">
    <div class="icon">${isError ? '❌' : '✅'}</div>
    <h1>${isError ? 'Error al conectar' : '¡Banco conectado!'}</h1>
    <p>${isError
      ? 'No se pudo conectar el banco. Por favor, inténtalo de nuevo desde la app.'
      : 'Tu banco se ha conectado correctamente. Ya puedes volver a Finora.'
    }</p>
    <button class="btn${isError ? ' btn-error' : ''}" onclick="closeAndReturn()">
      ← Volver a Finora
    </button>
    ${!isError ? '<p class="countdown" id="cd">Cerrando en <span id="s">3</span>s…</p>' : ''}
  </div>
  <script>
    function closeAndReturn() {
      window.close();
      // Fallback: go back in history (works when opened via in-app browser)
      history.go(-999);
    }
    ${!isError ? `
    let secs = 3;
    const el = document.getElementById('s');
    const timer = setInterval(() => {
      secs--;
      if (el) el.textContent = secs;
      if (secs <= 0) { clearInterval(timer); closeAndReturn(); }
    }, 1000);
    ` : ''}
  </script>
</body>
</html>`);
});

// ============================================
// GET /accounts — listar cuentas bancarias vinculadas (RF-10)
// ============================================
router.get('/accounts', authenticateToken, async (req, res) => {
  try {
    console.log(`[accounts] querying for userId=${req.user.userId}`);
    const result = await db.query(
      `SELECT ba.id, ba.connection_id, ba.external_account_id, ba.iban,
              ba.account_name, ba.account_type, ba.currency, ba.balance_cents,
              bc.institution_name, bc.institution_logo, bc.status as connection_status,
              bc.last_sync_at
       FROM bank_accounts ba
       JOIN bank_connections bc ON bc.id = ba.connection_id
       WHERE ba.user_id = $1 AND bc.status = 'linked'
       ORDER BY ba.created_at ASC`,
      [req.user.userId]
    );

    console.log(`[accounts] found ${result.rows.length} accounts for userId=${req.user.userId}`);
    res.json({ accounts: result.rows });
  } catch (err) {
    console.error('banks/accounts error:', err);
    res.status(500).json({ error: 'Internal Server Error', message: err.message });
  }
});

// ============================================
// POST /accounts/setup — crear cuenta bancaria desde página de configuración
// Body: { connection_id, account_name, account_type, iban, balance_cents }
// ============================================
router.post('/accounts/setup', authenticateToken, async (req, res) => {
  const { connection_id, account_name, account_type = 'current', iban, balance_cents = 0 } = req.body;
  if (!connection_id || !account_name) {
    return res.status(400).json({ error: 'Bad Request', message: 'connection_id y account_name son obligatorios' });
  }

  try {
    // Verificar que la conexión pertenece al usuario
    const connResult = await db.query(
      'SELECT * FROM bank_connections WHERE id = $1 AND user_id = $2',
      [connection_id, req.user.userId]
    );
    if (connResult.rows.length === 0) {
      return res.status(404).json({ error: 'Not Found', message: 'Conexión no encontrada' });
    }

    // Crear la cuenta bancaria
    const accountResult = await db.query(
      `INSERT INTO bank_accounts
         (connection_id, user_id, account_name, account_type, iban, currency, balance_cents)
       VALUES ($1, $2, $3, $4, $5, 'EUR', $6)
       RETURNING *`,
      [connection_id, req.user.userId, account_name, account_type, iban || null, Number(balance_cents) || 0]
    );
    const account = accountResult.rows[0];

    // Marcar la conexión como linked
    await db.query(
      `UPDATE bank_connections
       SET status = 'linked', linked_at = NOW(), last_sync_at = NOW()
       WHERE id = $1`,
      [connection_id]
    );

    const conn = connResult.rows[0];
    res.status(201).json({
      account: {
        ...account,
        institution_name: conn.institution_name,
        institution_logo: conn.institution_logo,
      },
    });
  } catch (err) {
    console.error('banks/accounts/setup error:', err);
    res.status(500).json({ error: 'Internal Server Error', message: err.message });
  }
});

// ============================================
// GET /cards — listar tarjetas del usuario (RF-10)
// ============================================
router.get('/cards', authenticateToken, async (req, res) => {
  try {
    const result = await db.query(
      `SELECT bc.*, ba.account_name, ba.iban
       FROM bank_cards bc
       JOIN bank_accounts ba ON ba.id = bc.bank_account_id
       WHERE bc.user_id = $1
       ORDER BY bc.created_at ASC`,
      [req.user.userId]
    );
    res.json({ cards: result.rows });
  } catch (err) {
    console.error('banks/cards error:', err);
    res.status(500).json({ error: 'Internal Server Error', message: err.message });
  }
});

// ============================================
// POST /accounts/:accountId/cards — añadir tarjeta a una cuenta
// Body: { card_name, card_type, last_four }
// ============================================
router.post('/accounts/:accountId/cards', authenticateToken, async (req, res) => {
  const { card_name, card_type = 'debit', last_four } = req.body;
  if (!card_name) {
    return res.status(400).json({ error: 'Bad Request', message: 'card_name es obligatorio' });
  }

  try {
    // Verificar que la cuenta pertenece al usuario
    const accResult = await db.query(
      'SELECT id FROM bank_accounts WHERE id = $1 AND user_id = $2',
      [req.params.accountId, req.user.userId]
    );
    if (accResult.rows.length === 0) {
      return res.status(404).json({ error: 'Not Found', message: 'Cuenta no encontrada' });
    }

    const cardResult = await db.query(
      `INSERT INTO bank_cards (bank_account_id, user_id, card_name, card_type, last_four)
       VALUES ($1, $2, $3, $4, $5)
       RETURNING *`,
      [req.params.accountId, req.user.userId, card_name, card_type, last_four || null]
    );

    res.status(201).json({ card: cardResult.rows[0] });
  } catch (err) {
    console.error('banks/accounts/cards error:', err);
    res.status(500).json({ error: 'Internal Server Error', message: err.message });
  }
});

// ============================================
// POST /accounts/:accountId/import-csv
// Importar transacciones desde CSV (JSON rows con deduplicación)
// Body: { rows: [{ date, description, amount, type, category? }] }
// ============================================
router.post('/accounts/:accountId/import-csv', authenticateToken, async (req, res) => {
  const { rows } = req.body;
  if (!Array.isArray(rows) || rows.length === 0) {
    return res.status(400).json({ error: 'Bad Request', message: 'rows debe ser un array no vacío' });
  }

  try {
    // Verificar que la cuenta pertenece al usuario
    const accResult = await db.query(
      'SELECT id FROM bank_accounts WHERE id = $1 AND user_id = $2',
      [req.params.accountId, req.user.userId]
    );
    if (accResult.rows.length === 0) {
      return res.status(404).json({ error: 'Not Found', message: 'Cuenta no encontrada' });
    }

    let imported = 0;
    let skipped = 0;

    for (const row of rows) {
      const { date, description, amount, type, category } = row;
      if (!date || amount === undefined || !type) continue;

      const absAmount = Math.abs(Number(amount));
      const txType = type === 'income' ? 'income' : 'expense';
      const txCategory = category || (txType === 'expense' ? 'Otros' : 'Otros ingresos');
      const txDate = date.slice(0, 10); // ensure YYYY-MM-DD

      // Deduplicación: mismo usuario + fecha + descripción + cantidad + tipo
      const existing = await db.query(
        `SELECT id FROM transactions
         WHERE user_id = $1 AND date = $2 AND amount = $3 AND type = $4
           AND (description = $5 OR ($5 IS NULL AND description IS NULL))`,
        [req.user.userId, txDate, absAmount, txType, description || null]
      );

      if (existing.rows.length > 0) {
        skipped++;
        continue;
      }

      await db.query(
        `INSERT INTO transactions
           (user_id, amount, type, category, description, date, payment_method, bank_account_id)
         VALUES ($1, $2, $3, $4, $5, $6, 'transfer', $7)`,
        [req.user.userId, absAmount, txType, txCategory, description || null, txDate, req.params.accountId]
      );
      imported++;
    }

    res.json({ imported, skipped });
  } catch (err) {
    console.error('banks/accounts/import-csv error:', err);
    res.status(500).json({ error: 'Internal Server Error', message: err.message });
  }
});

// ============================================
// GET /:id/sync-status — polling del estado de conexión (RF-10)
// ============================================
router.get('/:id/sync-status', authenticateToken, async (req, res) => {
  try {
    const connResult = await db.query(
      'SELECT * FROM bank_connections WHERE id = $1 AND user_id = $2',
      [req.params.id, req.user.userId]
    );

    if (connResult.rows.length === 0) {
      return res.status(404).json({ error: 'Not Found', message: 'Connection not found' });
    }

    const conn = connResult.rows[0];
    let accounts = [];

    if (conn.status === 'linked') {
      const accResult = await db.query(
        'SELECT * FROM bank_accounts WHERE connection_id = $1 ORDER BY created_at ASC',
        [req.params.id]
      );
      accounts = accResult.rows;
    }

    res.json({
      status: conn.status,
      institution_name: conn.institution_name,
      institution_logo: conn.institution_logo,
      linked_at: conn.linked_at,
      last_sync_at: conn.last_sync_at,
      accounts,
    });
  } catch (err) {
    console.error('banks/sync-status error:', err);
    res.status(500).json({ error: 'Internal Server Error', message: err.message });
  }
});

// ============================================
// POST /:id/sync — re-sincronizar saldos desde Salt Edge (RF-10)
// ============================================
router.post('/:id/sync', authenticateToken, async (req, res) => {
  try {
    const connResult = await db.query(
      "SELECT * FROM bank_connections WHERE id = $1 AND user_id = $2 AND status = 'linked'",
      [req.params.id, req.user.userId]
    );

    if (connResult.rows.length === 0) {
      return res.status(404).json({ error: 'Not Found', message: 'Connection not found or not linked' });
    }

    const conn = connResult.rows[0];
    // requisition_id almacena el Salt Edge connection_id tras el callback
    const accounts = await saltedge.fetchAccounts(conn.requisition_id);

    for (const acct of accounts) {
      await db.query(
        `INSERT INTO bank_accounts
           (connection_id, user_id, external_account_id, iban, account_name, currency, balance_cents)
         VALUES ($1, $2, $3, $4, $5, $6, $7)
         ON CONFLICT (external_account_id) DO UPDATE
           SET balance_cents = EXCLUDED.balance_cents,
               account_name  = EXCLUDED.account_name`,
        [conn.id, conn.user_id, acct.externalAccountId, acct.iban,
          acct.name, acct.currency, acct.balanceCents]
      );
    }

    await db.query(
      'UPDATE bank_connections SET last_sync_at = NOW() WHERE id = $1',
      [req.params.id]
    );

    const accResult = await db.query(
      'SELECT * FROM bank_accounts WHERE connection_id = $1 ORDER BY created_at ASC',
      [req.params.id]
    );

    res.json({ message: 'Sync completed', accounts: accResult.rows });
  } catch (err) {
    console.error('banks/sync error:', err);
    res.status(500).json({ error: 'Internal Server Error', message: err.message });
  }
});

// ============================================
// POST /:id/import-transactions — importar transacciones desde Salt Edge (RF-10)
//
// Descarga las transacciones reales de cada cuenta vinculada a esta conexión
// y las inserta en la tabla transactions del usuario, evitando duplicados
// mediante external_tx_id.
// ============================================
router.post('/:id/import-transactions', authenticateToken, async (req, res) => {
  try {
    const connResult = await db.query(
      "SELECT * FROM bank_connections WHERE id = $1 AND user_id = $2 AND status = 'linked'",
      [req.params.id, req.user.userId]
    );

    if (connResult.rows.length === 0) {
      return res.status(404).json({ error: 'Not Found', message: 'Connection not found or not linked' });
    }

    const conn = connResult.rows[0];

    // Obtener todas las cuentas de esta conexión
    const accResult = await db.query(
      'SELECT * FROM bank_accounts WHERE connection_id = $1',
      [req.params.id]
    );

    // Fecha desde la que importar (por defecto 90 días)
    const fromDate = req.body.from_date || (() => {
      const d = new Date();
      d.setDate(d.getDate() - 90);
      return d.toISOString().split('T')[0];
    })();

    let totalImported = 0;
    let totalSkipped = 0;

    for (const account of accResult.rows) {
      const transactions = await saltedge.fetchTransactions(
        account.external_account_id,
        fromDate
      );

      for (const tx of transactions) {
        // Convertir al formato de la app:
        //   amount < 0 → type='expense', amount=abs(amount)
        //   amount >= 0 → type='income', amount=amount
        const absAmount = Math.abs(tx.amount);
        const txType = tx.amount < 0 ? 'expense' : 'income';

        // Insertar solo si no existe ya (deduplicación por external_tx_id)
        const insertResult = await db.query(
          `INSERT INTO transactions
             (user_id, amount, type, category, description, date, payment_method, external_tx_id)
           VALUES ($1, $2, $3, $4, $5, $6, 'transfer', $7)
           ON CONFLICT (external_tx_id) DO NOTHING
           RETURNING id`,
          [
            conn.user_id,
            absAmount,
            txType,
            txType === 'expense' ? 'Otros' : 'Otros ingresos',
            tx.description,
            tx.date,
            tx.id,
          ]
        );

        if (insertResult.rows.length > 0) {
          totalImported++;
        } else {
          totalSkipped++;
        }
      }
    }

    res.json({
      message: 'Import completed',
      imported: totalImported,
      skipped: totalSkipped,
    });
  } catch (err) {
    console.error('banks/import-transactions error:', err);
    res.status(500).json({ error: 'Internal Server Error', message: err.message });
  }
});

// ============================================
// DELETE /:id/disconnect — eliminar conexión y cuentas (RF-10)
// ============================================
router.delete('/:id/disconnect', authenticateToken, async (req, res) => {
  try {
    const connResult = await db.query(
      'SELECT * FROM bank_connections WHERE id = $1 AND user_id = $2',
      [req.params.id, req.user.userId]
    );

    if (connResult.rows.length === 0) {
      return res.status(404).json({ error: 'Not Found', message: 'Connection not found' });
    }

    await db.query('DELETE FROM bank_accounts WHERE connection_id = $1', [req.params.id]);

    // Marcar como desconectado (conserva traza de auditoría)
    await db.query(
      "UPDATE bank_connections SET status = 'disconnected' WHERE id = $1",
      [req.params.id]
    );

    res.json({ message: 'Bank disconnected successfully' });
  } catch (err) {
    console.error('banks/disconnect error:', err);
    res.status(500).json({ error: 'Internal Server Error', message: err.message });
  }
});

module.exports = router;
