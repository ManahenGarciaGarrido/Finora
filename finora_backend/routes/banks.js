/**
 * Bank connection routes — RF-10 / RF-11
 *
 * Endpoints:
 *  GET  /institutions               – Listar bancos (selector visual)
 *  POST /connect                    – Iniciar flujo de consentimiento Plaid
 *  GET  /plaid-link                 – Página HTML con botón de autorización (real mode)
 *  POST /plaid-authorize            – Crear sandbox token + exchange server-side → linked
 *  POST /plaid-exchange             – Intercambiar public_token → access_token (Dart HTTP)
 *  GET  /callback                   – (legacy / compatibilidad Salt Edge)
 *  GET  /mock-auth?ref={id}         – Página mock de autenticación bancaria
 *  GET  /mock-callback?ref={id}     – Mock callback: crea cuentas demo
 *  GET  /callback-success           – HTML estático "¡Banco conectado!"
 *  GET  /accounts                   – Listar cuentas vinculadas del usuario
 *  POST /accounts/setup             – Crear cuenta bancaria manualmente
 *  GET  /cards                      – Listar tarjetas del usuario
 *  POST /accounts/:accountId/cards  – Añadir tarjeta a una cuenta
 *  POST /accounts/:accountId/import-csv – Importar CSV
 *  GET  /:id/sync-status            – Polling del estado de conexión
 *  POST /:id/sync                   – Forzar re-sync de saldos
 *  POST /:id/import-transactions    – Importar transacciones Plaid (RF-11)
 *  POST /sync-all                   – Sync masivo para cron job interno (RF-11)
 *  DELETE /:id/disconnect           – Eliminar conexión y cuentas
 */

const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const db = require('../services/db');
const plaid = require('../services/plaid');
const { autoCategory } = require('../services/categoryMapper');
const { withRetry, withCache, ratesBreaker } = require('../services/circuitBreaker');

const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-change-in-production';

// ─── Auth middleware ───────────────────────────────────────────────────────────

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

// ─── Helpers ──────────────────────────────────────────────────────────────────

function baseUrl(req) {
  if (process.env.APP_URL) return process.env.APP_URL.replace(/\/$/, '');
  return `${req.protocol}://${req.get('host')}`;
}

/**
 * Convierte amountCents a EUR usando la API pública de Frankfurter (BCE).
 *
 * RNF-16: La tasa de cambio se cachea 1 hora (withCache con allowStale=true).
 *         Si la API de tasas falla, se usa la última tasa conocida (stale fallback).
 *         El circuit breaker de tasas evita saturar el servicio en caso de error.
 *
 * @param {number} amountCents   Importe en centavos en la moneda origen
 * @param {string} currency      Código ISO 4217 (ej: 'USD', 'GBP')
 * @returns {Promise<number>}    Importe en céntimos de EUR
 */
async function toEurCents(amountCents, currency) {
  if (!currency || currency.toUpperCase() === 'EUR') return amountCents;
  const key = currency.toUpperCase();

  const rate = await withCache(
    `rate_${key}_EUR`,
    () => ratesBreaker.call(async () => {
      const controller = new AbortController();
      const timer = setTimeout(() => controller.abort(), 10_000); // 10s timeout
      try {
        const r = await fetch(
          `https://api.frankfurter.app/latest?from=${key}&to=EUR`,
          { signal: controller.signal }
        );
        const data = r.ok ? await r.json() : null;
        const fetchedRate = data?.rates?.EUR;
        if (!fetchedRate) throw new Error(`Tasa no disponible para ${key}`);
        return fetchedRate;
      } finally {
        clearTimeout(timer);
      }
    }),
    60 * 60 * 1000, // TTL: 1 hora
    { allowStale: true }  // RNF-16: fallback a última tasa conocida si falla
  ).catch(() => 1); // Si no hay stale y falla → 1:1 (sin conversión)

  return Math.round(amountCents * rate);
}

// Generador de transacciones demo para cuentas recién importadas.
// cat: categoría tal como aparece en la BD (nombre en español, seeded en seed_categories_for_user)
// pm:  payment_method — valores aceptados por el CHECK constraint de la tabla transactions
const _TX_EXPENSES = [
  { desc: 'Mercadona',         cat: 'Alimentación', pm: 'debit_card'   },
  { desc: 'Carrefour',         cat: 'Alimentación', pm: 'debit_card'   },
  { desc: 'Cafetería',         cat: 'Alimentación', pm: 'debit_card'   },
  { desc: 'Restaurante',       cat: 'Alimentación', pm: 'debit_card'   },
  { desc: 'Repsol',            cat: 'Transporte',   pm: 'debit_card'   },
  { desc: 'Gasolinera BP',     cat: 'Transporte',   pm: 'debit_card'   },
  { desc: 'Renfe',             cat: 'Transporte',   pm: 'debit_card'   },
  { desc: 'Zara',              cat: 'Ropa',         pm: 'debit_card'   },
  { desc: 'H&M',               cat: 'Ropa',         pm: 'credit_card'  },
  { desc: 'Amazon',            cat: 'Otros',        pm: 'credit_card'  },
  { desc: 'El Corte Inglés',   cat: 'Otros',        pm: 'credit_card'  },
  { desc: 'Netflix',           cat: 'Ocio',         pm: 'direct_debit' },
  { desc: 'Spotify',           cat: 'Ocio',         pm: 'direct_debit' },
  { desc: 'Farmacia',          cat: 'Salud',        pm: 'debit_card'   },
  { desc: 'Gimnasio',          cat: 'Salud',        pm: 'direct_debit' },
  { desc: 'Vodafone',          cat: 'Servicios',    pm: 'direct_debit' },
  { desc: 'Iberdrola',         cat: 'Servicios',    pm: 'direct_debit' },
  { desc: 'Alquiler mensual',  cat: 'Vivienda',     pm: 'bank_transfer'},
  { desc: 'Seguro coche',      cat: 'Servicios',    pm: 'direct_debit' },
];
const _TX_INCOMES = [
  { desc: 'Nómina',                 cat: 'Salario',        pm: 'bank_transfer' },
  { desc: 'Bonus trimestral',       cat: 'Salario',        pm: 'bank_transfer' },
  { desc: 'Freelance cliente',      cat: 'Freelance',      pm: 'bank_transfer' },
  { desc: 'Transferencia recibida', cat: 'Otros ingresos', pm: 'bizum'         },
  { desc: 'Devolución Hacienda',    cat: 'Otros ingresos', pm: 'bank_transfer' },
  { desc: 'Dividendos',             cat: 'Otros ingresos', pm: 'bank_transfer' },
];

// targetBalanceCents: saldo EUR ya convertido y mostrado al usuario en la pantalla de selección.
// Las transacciones se generan para sumar exactamente ese importe, así ambas vistas
// (selección y detalle de cuenta) muestran siempre el mismo número.
async function generateRandomTransactions(bankAccountId, userId, targetBalanceCents) {
  const count = 20 + Math.floor(Math.random() * 11); // 20–30 transacciones
  const today = new Date();

  // 1. Generar transacciones aleatorias
  const txList = [];
  let totalIncomeCents  = 0;
  let totalExpenseCents = 0;

  for (let i = 0; i < count; i++) {
    const daysAgo = Math.floor(Math.random() * 89) + 1; // 1–89 días atrás
    const txDate = new Date(today);
    txDate.setDate(txDate.getDate() - daysAgo);

    const isExpense = Math.random() < 0.65;
    const amountCents = isExpense
      ? Math.floor((5  + Math.random() * 295)  * 100) // 5 – 300 €
      : Math.floor((300 + Math.random() * 1700) * 100); // 300 – 2000 €

    const pool = isExpense ? _TX_EXPENSES : _TX_INCOMES;
    const { desc, cat, pm } = pool[Math.floor(Math.random() * pool.length)];

    if (isExpense) totalExpenseCents += amountCents;
    else           totalIncomeCents  += amountCents;

    txList.push({ amountCents, isExpense, desc, cat, pm, dateStr: txDate.toISOString().split('T')[0] });
  }

  // 2. Ajustar con un ingreso inicial (día 90) para que ingresos - gastos = targetBalanceCents exacto.
  //    El objetivo es el saldo EUR real de la cuenta (el mismo que se mostró en la selección).
  const netCents = totalIncomeCents - totalExpenseCents;
  const extraIncomeCents = targetBalanceCents - netCents;

  if (extraIncomeCents > 0) {
    // Dispersar la apertura entre 3 y 18 meses atrás (con variación de día)
    // para que 12 cuentas vinculadas no tengan todas la misma fecha.
    const openingDate = new Date(today);
    const monthsBack = 3 + Math.floor(Math.random() * 16); // 3–18 meses
    const extraDays  = Math.floor(Math.random() * 28);      // 0–27 días adicionales
    openingDate.setMonth(openingDate.getMonth() - monthsBack);
    openingDate.setDate(openingDate.getDate() - extraDays);
    txList.push({
      amountCents: extraIncomeCents,
      isExpense:   false,
      desc:        'Apertura de cuenta',
      cat:         'Otros ingresos',
      pm:          'bank_transfer',
      dateStr:     openingDate.toISOString().split('T')[0],
    });
    totalIncomeCents += extraIncomeCents;
  }
  // Si extraIncomeCents <= 0 el net ya supera el objetivo; el balance se dejará en netCents
  // (siempre positivo por diseño: los ingresos son de 300-2000€ y los gastos de 5-300€).

  // 3. Insertar todas las transacciones
  for (const tx of txList) {
    const amount = (tx.amountCents / 100).toFixed(2);
    await db.query(
      `INSERT INTO transactions
         (user_id, bank_account_id, amount, type, description, category, date, payment_method)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
      [userId, bankAccountId, amount, tx.isExpense ? 'expense' : 'income', tx.desc, tx.cat, tx.dateStr, tx.pm]
    );
  }
}

// ─── GET /institutions ────────────────────────────────────────────────────────

router.get('/institutions', authenticateToken, async (req, res) => {
  try {
    const country = req.query.country || null;
    const institutions = await plaid.listInstitutions(country);
    res.json({ institutions });
  } catch (err) {
    console.error('banks/institutions error:', err);
    res.status(500).json({ error: 'Internal Server Error', message: err.message });
  }
});

// ─── POST /connect ─────────────────────────────────────────────────────────────
//
// Inicia el flujo Plaid:
//  - Mock mode  → devuelve is_mock:true (Flutter navega a setup manual)
//  - Real mode  → crea link_token y devuelve auth_url apuntando a /plaid-link

router.post('/connect', authenticateToken, async (req, res) => {
  const { institution_id } = req.body;
  if (!institution_id) {
    return res.status(400).json({ error: 'Bad Request', message: 'institution_id is required' });
  }

  try {
    // CU-02 FA1: Verificar límite de 3 intentos fallidos en la última hora
    const failedAttempts = await db.query(
      `SELECT COUNT(*) AS cnt FROM bank_connections
       WHERE user_id = $1 AND institution_id = $2 AND status = 'failed'
         AND created_at > NOW() - INTERVAL '1 hour'`,
      [req.user.userId, institution_id]
    );
    const attemptCount = parseInt(failedAttempts.rows[0].cnt);
    if (attemptCount >= 3) {
      return res.status(429).json({
        error: 'MAX_ATTEMPTS_REACHED',
        message: 'Has alcanzado el límite de 3 intentos fallidos para este banco. Espera 1 hora o contacta con soporte.',
        code: 'MAX_ATTEMPTS_REACHED',
        retry_after_minutes: 60,
      });
    }

    // Obtener nombre/logo del banco para mostrarlo en la UI
    let institutionName = institution_id;
    let institutionLogo = null;
    try {
      const institutions = await plaid.listInstitutions();
      const inst = institutions.find(i => i.id === institution_id);
      if (inst) {
        institutionName = inst.name;
        institutionLogo = inst.logo || null;
      }
    } catch (_) { /* no crítico */ }

    // Insertar registro de conexión en estado pending
    const insertResult = await db.query(
      `INSERT INTO bank_connections (user_id, institution_id, status, institution_name, institution_logo)
       VALUES ($1, $2, 'pending', $3, $4)
       RETURNING id`,
      [req.user.userId, institution_id, institutionName, institutionLogo]
    );
    const connectionId = insertResult.rows[0].id;

    // Mock mode: Flutter navega a la página de setup manual
    if (plaid.isMockMode()) {
      console.log(`[mock/connect] userId=${req.user.userId} connectionId=${connectionId} institution=${institution_id}`);
      return res.json({
        connection_id: connectionId,
        is_mock: true,
        institution_name: institutionName,
      });
    }

    // Sandbox mode: crear token server-side, obtener lista de cuentas con tasas
    // de cambio reales y devolver a Flutter para que el usuario elija cuáles vincular.
    const publicToken = await plaid.createSandboxPublicToken(institution_id);
    const { access_token } = await plaid.exchangePublicToken(publicToken);

    // Guardar access_token para usarlo después en /import-accounts
    await db.query(
      'UPDATE bank_connections SET requisition_id = $1 WHERE id = $2',
      [access_token, connectionId]
    );

    const rawAccounts = await plaid.fetchAccounts(access_token);

    // Convertir saldos a EUR con tasa de cambio real (frankfurter.app / BCE)
    const pendingAccounts = await Promise.all(rawAccounts.map(async acct => ({
      external_account_id: acct.externalAccountId,
      name:                acct.name,
      currency:            acct.currency,
      balance_cents:       acct.balanceCents,
      balance_eur_cents:   await toEurCents(acct.balanceCents, acct.currency),
      iban:                acct.iban,
    })));

    console.log(`[sandbox/connect] userId=${req.user.userId} connectionId=${connectionId} pending=${pendingAccounts.length}`);
    res.json({
      connection_id:    connectionId,
      auth_url:         '',
      institution_name: institutionName,
      is_mock:          false,
      pending_accounts: pendingAccounts,
    });
  } catch (err) {
    console.error('banks/connect error:', err);
    res.status(500).json({ error: 'Internal Server Error', message: err.message });
  }
});

// ─── GET /plaid-link ──────────────────────────────────────────────────────────
//
// Página de autorización bancaria para el WebView de Flutter.
//
// Reemplaza el flujo anterior basado en el SDK de Plaid Link JS, que en
// Android WebView realizaba una redirección de página completa a los
// servidores de Plaid, descargando el contexto JavaScript de la página
// original y haciendo que onSuccess nunca se disparara.
//
// Solución: botón simple → form POST → /plaid-authorize (sin JS externo).
// El backend crea el public_token vía API de sandbox de Plaid,
// intercambia el token y redirige a /callback-success.
// Flutter detecta callback-success en onPageFinished y cierra el WebView.

router.get('/plaid-link', (req, res) => {
  const connectionId = req.query.ref || '';
  const base = baseUrl(req);

  res.setHeader('Content-Type', 'text/html; charset=utf-8');
  res.send(`<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Conectar banco — Finora</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
           background: #f0f4f8; display: flex; justify-content: center;
           align-items: center; min-height: 100vh; padding: 16px; }
    .card { background: white; border-radius: 16px; padding: 40px 32px;
            max-width: 400px; width: 100%; box-shadow: 0 4px 24px rgba(0,0,0,0.1);
            text-align: center; }
    .logo { font-size: 56px; margin-bottom: 20px; }
    h1 { font-size: 22px; color: #1e293b; margin-bottom: 10px; }
    p  { font-size: 14px; color: #64748b; line-height: 1.6; margin-bottom: 24px; }
    .badge { display: inline-block; background: #dbeafe; color: #1d4ed8;
             font-size: 11px; font-weight: 600; padding: 3px 10px; border-radius: 99px;
             text-transform: uppercase; letter-spacing: 0.05em; margin-bottom: 14px; }
    .perms { background: #f8fafc; border-radius: 12px; padding: 16px; margin-bottom: 28px;
             text-align: left; }
    .perm { display: flex; align-items: center; gap: 10px; padding: 5px 0;
            font-size: 13px; color: #374151; }
    .perm::before { content: '✓'; color: #22c55e; font-weight: bold; flex-shrink: 0; }
    .btn { display: block; width: 100%; padding: 14px; background: #3B82F6; color: white;
           border: none; border-radius: 12px; font-size: 16px; font-weight: 600;
           cursor: pointer; margin-bottom: 12px; }
    .btn:hover { background: #2563eb; }
    .btn:active { opacity: 0.85; }
    .btn:disabled { opacity: 0.6; cursor: not-allowed; }
    .spinner { display: none; width: 18px; height: 18px;
               border: 2px solid rgba(255,255,255,0.4); border-top-color: white;
               border-radius: 50%; animation: spin 0.8s linear infinite;
               vertical-align: middle; margin-right: 8px; }
    @keyframes spin { to { transform: rotate(360deg); } }
  </style>
</head>
<body>
  <div class="card">
    <div class="logo">🏦</div>
    <div><span class="badge">Plaid · Sandbox</span></div>
    <h1>Autorizar acceso bancario</h1>
    <p>Finora solicitará acceso de solo lectura a tu información bancaria.</p>
    <div class="perms">
      <div class="perm">Ver saldo de cuentas</div>
      <div class="perm">Ver movimientos (últimos 90 días)</div>
      <div class="perm">Datos cifrados · Solo lectura</div>
    </div>
    <form action="${base}/api/v1/banks/plaid-authorize" method="POST"
          onsubmit="handleSubmit(this)">
      <input type="hidden" name="ref" value="${connectionId}">
      <button type="submit" class="btn" id="authBtn">
        <span class="spinner" id="sp"></span>Autorizar acceso
      </button>
    </form>
  </div>
  <script>
    function handleSubmit(form) {
      const btn = document.getElementById('authBtn');
      const sp  = document.getElementById('sp');
      btn.disabled = true;
      sp.style.display = 'inline-block';
      btn.childNodes[btn.childNodes.length - 1].textContent = 'Conectando…';
    }
  </script>
</body>
</html>`);
});

// ─── POST /plaid-authorize ────────────────────────────────────────────────────
//
// Autorización bancaria sin redirección en el WebView.
// Recibe el connectionId vía form POST desde /plaid-link.
// Crea un public_token de sandbox directamente en el servidor usando la API
// de Plaid (/sandbox/public_token/create), lo intercambia por un access_token,
// persiste las cuentas y marca la conexión como linked.
// Redirige a /callback-success → Flutter detecta la URL en onNavigationRequest
// y cierra el WebView automáticamente.
//
// Sin autenticación JWT: la seguridad proviene del connectionId opaco (UUID).

router.post('/plaid-authorize', async (req, res) => {
  const connectionId = req.body.ref;
  const base = baseUrl(req);

  if (!connectionId) {
    return res.redirect(`${base}/api/v1/banks/callback-success?error=1`);
  }

  try {
    const connResult = await db.query(
      'SELECT * FROM bank_connections WHERE id = $1',
      [connectionId]
    );
    if (connResult.rows.length === 0) {
      console.warn(`[plaid-authorize] connectionId=${connectionId} not found`);
      return res.redirect(`${base}/api/v1/banks/callback-success?error=1`);
    }
    const conn = connResult.rows[0];

    // Crear public_token de sandbox en el servidor (sin SDK de Plaid Link)
    const institutionId = conn.institution_id || 'ins_109508';
    const publicToken = await plaid.createSandboxPublicToken(institutionId);

    // Intercambiar public_token → access_token
    const { access_token } = await plaid.exchangePublicToken(publicToken);

    // Guardar access_token en requisition_id
    await db.query(
      'UPDATE bank_connections SET requisition_id = $1 WHERE id = $2',
      [access_token, connectionId]
    );

    // Obtener cuentas desde Plaid
    const accounts = await plaid.fetchAccounts(access_token);
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

    // Marcar conexión como linked
    await db.query(
      `UPDATE bank_connections
       SET status = 'linked', linked_at = NOW(), last_sync_at = NOW()
       WHERE id = $1`,
      [connectionId]
    );

    // RNF-05: Crear consentimiento PSD2 (90 días según normativa SCA)
    await createPsd2Consent(connectionId, conn.user_id);

    console.log(`[plaid-authorize] connectionId=${connectionId} userId=${conn.user_id} accounts=${accounts.length}`);
    res.redirect(`${base}/api/v1/banks/callback-success`);
  } catch (err) {
    console.error('banks/plaid-authorize error:', err);
    res.redirect(`${base}/api/v1/banks/callback-success?error=1`);
  }
});

// ─── POST /plaid-exchange ─────────────────────────────────────────────────────
//
// Intercambia el public_token de Plaid Link por un access_token permanente.
// Llamado por el cliente HTTP Dart de Flutter (ya no desde el WebView),
// lo que garantiza que el JWT y la red funcionan correctamente.

router.post('/plaid-exchange', authenticateToken, async (req, res) => {
  const { public_token, ref: connectionId, institution_name } = req.body;

  if (!connectionId || !public_token) {
    return res.status(400).json({ error: 'Bad Request', message: 'public_token y ref son requeridos' });
  }

  try {
    // 1. Obtener la conexión de la BD (verificar que pertenece al usuario autenticado)
    const connResult = await db.query(
      'SELECT * FROM bank_connections WHERE id = $1 AND user_id = $2',
      [connectionId, req.user.userId]
    );
    if (connResult.rows.length === 0) {
      return res.status(404).json({ error: 'Not Found', message: 'Connection not found' });
    }
    const conn = connResult.rows[0];

    // 2. Intercambiar public_token → access_token
    const { access_token } = await plaid.exchangePublicToken(public_token);

    // Guardar el access_token en requisition_id (campo de propósito genérico)
    await db.query(
      'UPDATE bank_connections SET requisition_id = $1 WHERE id = $2',
      [access_token, connectionId]
    );

    // 3. Obtener cuentas desde Plaid
    const accounts = await plaid.fetchAccounts(access_token);

    // Usar institution_name enviado por el browser (viene de Plaid metadata)
    const instName = institution_name || conn.institution_name || 'Banco';

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

    // 4. Marcar conexión como linked
    await db.query(
      `UPDATE bank_connections
       SET status = 'linked', institution_name = $1,
           linked_at = NOW(), last_sync_at = NOW()
       WHERE id = $2`,
      [instName, connectionId]
    );

    // RNF-05: Crear consentimiento PSD2 (90 días según normativa SCA)
    await createPsd2Consent(connectionId, conn.user_id);

    console.log(`[plaid-exchange] connectionId=${connectionId} userId=${conn.user_id} accounts=${accounts.length}`);
    res.json({ ok: true, accounts: accounts.length });
  } catch (err) {
    console.error('banks/plaid-exchange error:', err);
    res.status(500).json({ error: 'Internal Server Error', message: err.message });
  }
});

// ─── GET /callback ────────────────────────────────────────────────────────────
//
// Callback de compatibilidad (ya no es el flujo principal con Plaid).
// Se mantiene por si algún proveedor futuro redirige aquí.

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

    await db.query("UPDATE bank_connections SET status = 'failed' WHERE id = $1", [connectionId]).catch(() => {});
    res.redirect(`${baseUrl(req)}/api/v1/banks/callback-success?error=1`);
  } catch (err) {
    console.error('banks/callback error:', err);
    res.redirect(`${baseUrl(req)}/api/v1/banks/callback-success?error=1`);
  }
});

// ─── GET /mock-auth ───────────────────────────────────────────────────────────

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
    <p>Finora solicita acceso de solo lectura a tu información bancaria.</p>
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

// ─── GET /mock-callback ───────────────────────────────────────────────────────

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
      const mockAccessToken = conn.requisition_id || connectionId;
      const accounts = await plaid.fetchAccounts(mockAccessToken);

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

      // RNF-05: Crear consentimiento PSD2
      await createPsd2Consent(connectionId, conn.user_id);
    }
  } catch (err) {
    console.error('banks/mock-callback error:', err);
  }

  res.redirect(`${baseUrl(req)}/api/v1/banks/callback-success`);
});

// ─── GET /callback-success ────────────────────────────────────────────────────

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

// ─── GET /accounts ────────────────────────────────────────────────────────────

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

// ─── POST /accounts/setup ─────────────────────────────────────────────────────

router.post('/accounts/setup', authenticateToken, async (req, res) => {
  const { connection_id, account_name, account_type = 'current', iban, balance_cents = 0 } = req.body;
  if (!connection_id || !account_name) {
    return res.status(400).json({ error: 'Bad Request', message: 'connection_id y account_name son obligatorios' });
  }

  try {
    const connResult = await db.query(
      'SELECT * FROM bank_connections WHERE id = $1 AND user_id = $2',
      [connection_id, req.user.userId]
    );
    if (connResult.rows.length === 0) {
      return res.status(404).json({ error: 'Not Found', message: 'Conexión no encontrada' });
    }

    const accountResult = await db.query(
      `INSERT INTO bank_accounts
         (connection_id, user_id, account_name, account_type, iban, currency, balance_cents)
       VALUES ($1, $2, $3, $4, $5, 'EUR', $6)
       RETURNING *`,
      [connection_id, req.user.userId, account_name, account_type, iban || null, Number(balance_cents) || 0]
    );
    const account = accountResult.rows[0];

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

// ─── GET /cards ───────────────────────────────────────────────────────────────

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

// ─── POST /accounts/:accountId/cards ──────────────────────────────────────────

router.post('/accounts/:accountId/cards', authenticateToken, async (req, res) => {
  const { card_name, card_type = 'debit', last_four } = req.body;
  if (!card_name) {
    return res.status(400).json({ error: 'Bad Request', message: 'card_name es obligatorio' });
  }

  try {
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

// ─── DELETE /cards/:cardId ─────────────────────────────────────────────────────

router.delete('/cards/:cardId', authenticateToken, async (req, res) => {
  try {
    const result = await db.query(
      'DELETE FROM bank_cards WHERE id = $1 AND user_id = $2 RETURNING id',
      [req.params.cardId, req.user.userId]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Not Found', message: 'Tarjeta no encontrada' });
    }
    res.json({ deleted: true });
  } catch (err) {
    console.error('banks/cards/delete error:', err);
    res.status(500).json({ error: 'Internal Server Error', message: err.message });
  }
});

// ─── POST /accounts/:accountId/import-csv ─────────────────────────────────────

router.post('/accounts/:accountId/import-csv', authenticateToken, async (req, res) => {
  const { rows } = req.body;
  if (!Array.isArray(rows) || rows.length === 0) {
    return res.status(400).json({ error: 'Bad Request', message: 'rows debe ser un array no vacío' });
  }

  try {
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
      const txDate = date.slice(0, 10);

      const existing = await db.query(
        `SELECT id FROM transactions
         WHERE user_id = $1 AND date = $2 AND amount = $3 AND type = $4
           AND (description = $5 OR ($5 IS NULL AND description IS NULL))`,
        [req.user.userId, txDate, absAmount, txType, description || null]
      );

      if (existing.rows.length > 0) { skipped++; continue; }

      await db.query(
        `INSERT INTO transactions
           (user_id, amount, type, category, description, date, payment_method, bank_account_id)
         VALUES ($1, $2, $3, $4, $5, $6, 'bank_transfer', $7)`,
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

// ─── GET /:id/sync-status ─────────────────────────────────────────────────────

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

// ─── POST /:id/sync ───────────────────────────────────────────────────────────

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
    // requisition_id almacena el Plaid access_token tras el intercambio
    const accounts = await plaid.fetchAccounts(conn.requisition_id);

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

    await db.query('UPDATE bank_connections SET last_sync_at = NOW() WHERE id = $1', [req.params.id]);

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

// ─── POST /:id/import-transactions (RF-11) ────────────────────────────────────
//
// Importa transacciones reales de Plaid para todas las cuentas de esta conexión.
// Convención Plaid: amount > 0 = gasto (débito), amount < 0 = ingreso (crédito).

router.post('/:id/import-transactions', authenticateToken, async (req, res) => {
  // RNF-07: Medir duración total de la sincronización
  const syncStart = Date.now();

  try {
    const connResult = await db.query(
      "SELECT * FROM bank_connections WHERE id = $1 AND user_id = $2 AND status = 'linked'",
      [req.params.id, req.user.userId]
    );
    if (connResult.rows.length === 0) {
      return res.status(404).json({ error: 'Not Found', message: 'Connection not found or not linked' });
    }
    const conn = connResult.rows[0];

    // RNF-05: Verificar estado del consentimiento PSD2
    const consentResult = await db.query(
      `SELECT *, EXTRACT(DAY FROM (expires_at - NOW())) AS days_remaining
       FROM psd2_consents WHERE connection_id = $1`,
      [req.params.id]
    );
    if (consentResult.rows.length > 0) {
      const consent = consentResult.rows[0];
      const daysLeft = Math.floor(Number(consent.days_remaining));

      if (consent.status === 'revoked') {
        return res.status(403).json({
          error: 'CONSENT_REVOKED',
          message: 'El consentimiento bancario ha sido revocado. Reconecta el banco para continuar.',
          code: 'CONSENT_REVOKED',
        });
      }
      if (consent.status === 'expired' || daysLeft <= 0) {
        // Marcar como expirado si no lo estaba ya
        await db.query(
          "UPDATE psd2_consents SET status = 'expired' WHERE connection_id = $1",
          [req.params.id]
        );
        return res.status(403).json({
          error: 'CONSENT_EXPIRED',
          message: 'El consentimiento PSD2 ha expirado (90 días). Renueva el acceso en la configuración.',
          code: 'CONSENT_EXPIRED',
          renewalUrl: `${req.protocol}://${req.get('host')}/api/v1/banks/${req.params.id}/consent/renew`,
        });
      }
      // Avisar si quedan ≤14 días para la expiración
      if (daysLeft <= 14 && !consent.renewal_notified_at) {
        await db.query(
          'UPDATE psd2_consents SET renewal_notified_at = NOW() WHERE connection_id = $1',
          [req.params.id]
        );
        // renewal_warning se incluye en la respuesta abajo
        req._consentRenewalDays = daysLeft;
      }
    }

    const accResult = await db.query(
      'SELECT * FROM bank_accounts WHERE connection_id = $1',
      [req.params.id]
    );

    const fromDate = req.body.from_date || (() => {
      const d = new Date();
      d.setDate(d.getDate() - 90);
      return d.toISOString().split('T')[0];
    })();

    let totalImported = 0;
    let totalSkipped = 0;

    // Plaid: un access_token cubre todas las cuentas del Item
    // Obtenemos transacciones por access_token, luego las distribuimos por account_id
    const accessToken = conn.requisition_id;
    const allTransactions = await plaid.fetchTransactions(accessToken, fromDate);

    // Mapa: account_id de Plaid → id interno de bank_accounts
    const accountMap = {};
    for (const account of accResult.rows) {
      if (account.external_account_id) {
        accountMap[account.external_account_id] = account.id;
      }
    }
    // Fallback: si solo hay una cuenta, asignar todas las transacciones a ella
    const fallbackAccountId = accResult.rows.length === 1 ? accResult.rows[0].id : null;

    for (const tx of allTransactions) {
      // Plaid: amount > 0 → gasto, amount < 0 → ingreso
      const absAmount = Math.abs(tx.amount);
      const txType = tx.amount > 0 ? 'expense' : 'income';
      const category = autoCategory(tx.description, txType);

      // Resolver bank_account_id por account_id de Plaid (si disponible)
      const bankAccountId = (tx.account_id && accountMap[tx.account_id])
        || fallbackAccountId
        || (accResult.rows[0]?.id || null);

      const insertResult = await db.query(
        `INSERT INTO transactions
           (user_id, amount, type, category, description, date, payment_method, external_tx_id, bank_account_id)
         VALUES ($1, $2, $3, $4, $5, $6, 'bank_transfer', $7, $8)
         ON CONFLICT (external_tx_id) WHERE external_tx_id IS NOT NULL DO NOTHING
         RETURNING id`,
        [conn.user_id, absAmount, txType, category, tx.description,
          tx.date, tx.id, bankAccountId]
      );

      if (insertResult.rows.length > 0) totalImported++;
      else totalSkipped++;
    }

    await db.query('UPDATE bank_connections SET last_sync_at = NOW() WHERE id = $1', [req.params.id]);

    // RNF-07: Registrar log de sincronización con duración real
    const syncDurationMs = Date.now() - syncStart;
    try {
      await db.query(
        `INSERT INTO sync_logs
           (connection_id, user_id, trigger_type, status, imported_count, skipped_count, duration_ms)
         VALUES ($1, $2, 'manual', 'success', $3, $4, $5)`,
        [req.params.id, conn.user_id, totalImported, totalSkipped, syncDurationMs]
      );
    } catch (logErr) {
      console.warn('sync_logs insert warning:', logErr.message);
    }

    // HU-06: Crear notificación in-app si se importaron nuevas transacciones
    if (totalImported > 0) {
      try {
        await db.query(
          `INSERT INTO notifications (user_id, type, title, body, metadata)
           VALUES ($1, 'bank_sync', $2, $3, $4)`,
          [
            conn.user_id,
            'Nuevas transacciones',
            `Se ${totalImported === 1 ? 'ha importado 1 transacción' : `han importado ${totalImported} transacciones`} de tu banco`,
            JSON.stringify({ imported: totalImported, skipped: totalSkipped, connection_id: req.params.id }),
          ]
        );
      } catch (notifErr) {
        console.warn('notifications insert warning:', notifErr.message);
      }
    }

    const responseBody = {
      message: 'Import completed',
      imported: totalImported,
      skipped: totalSkipped,
      last_sync_at: new Date().toISOString(),
      duration_ms: Date.now() - syncStart, // RNF-07: duración real para el frontend
    };

    // RNF-05: Avisar si el consentimiento está próximo a expirar
    if (req._consentRenewalDays !== undefined) {
      responseBody.consent_renewal_warning = {
        message: `Tu consentimiento bancario expira en ${req._consentRenewalDays} días. Renuévalo para mantener la sincronización.`,
        daysRemaining: req._consentRenewalDays,
        renewEndpoint: `/${req.params.id}/consent/renew`,
      };
    }

    res.json(responseBody);
  } catch (err) {
    console.error('banks/import-transactions error:', err);
    res.status(500).json({ error: 'Internal Server Error', message: err.message });
  }
});

// ─── POST /sync-all (RF-11) ───────────────────────────────────────────────────
//
// Endpoint interno para cron job. NO requiere JWT de usuario.
// Protegido por X-Cron-Secret.

router.post('/sync-all', async (req, res) => {
  const cronSecret = process.env.CRON_SECRET;
  if (cronSecret && req.headers['x-cron-secret'] !== cronSecret) {
    return res.status(403).json({ error: 'Forbidden', message: 'Invalid cron secret' });
  }

  // RNF-07: Medir duración total del sync masivo
  const syncAllStart = Date.now();

  try {
    const connsResult = await db.query(
      "SELECT * FROM bank_connections WHERE status = 'linked'"
    );

    let totalConnections = 0;
    let totalImported = 0;
    let totalSkipped = 0;
    const errors = [];
    const progress = []; // RNF-07: progreso por conexión

    for (const conn of connsResult.rows) {
      const connSyncStart = Date.now(); // RNF-07: medir duración por conexión
      try {
        totalConnections++;
        const accessToken = conn.requisition_id;

        // 1. Actualizar saldos
        const accounts = await plaid.fetchAccounts(accessToken);
        for (const acct of accounts) {
          await db.query(
            `INSERT INTO bank_accounts
               (connection_id, user_id, external_account_id, iban, account_name, currency, balance_cents)
             VALUES ($1, $2, $3, $4, $5, $6, $7)
             ON CONFLICT (external_account_id) DO UPDATE
               SET balance_cents = EXCLUDED.balance_cents,
                   account_name  = EXCLUDED.account_name,
                   updated_at    = NOW()`,
            [conn.id, conn.user_id, acct.externalAccountId, acct.iban,
              acct.name, acct.currency, acct.balanceCents]
          );
        }

        // 2. Importar transacciones de los últimos 7 días
        const since = new Date();
        since.setDate(since.getDate() - 7);
        const fromDate = since.toISOString().split('T')[0];

        const accResult = await db.query(
          'SELECT * FROM bank_accounts WHERE connection_id = $1',
          [conn.id]
        );

        const accountMap = {};
        for (const account of accResult.rows) {
          if (account.external_account_id) accountMap[account.external_account_id] = account.id;
        }
        const fallbackAccountId = accResult.rows.length === 1 ? accResult.rows[0].id : null;

        const transactions = await plaid.fetchTransactions(accessToken, fromDate);
        for (const tx of transactions) {
          const absAmount = Math.abs(tx.amount);
          const txType = tx.amount > 0 ? 'expense' : 'income';
          const category = autoCategory(tx.description, txType);
          const bankAccountId = (tx.account_id && accountMap[tx.account_id])
            || fallbackAccountId
            || (accResult.rows[0]?.id || null);

          const insertResult = await db.query(
            `INSERT INTO transactions
               (user_id, amount, type, category, description, date, payment_method, external_tx_id, bank_account_id)
             VALUES ($1, $2, $3, $4, $5, $6, 'bank_transfer', $7, $8)
             ON CONFLICT (external_tx_id) WHERE external_tx_id IS NOT NULL DO NOTHING
             RETURNING id`,
            [conn.user_id, absAmount, txType, category, tx.description,
              tx.date, tx.id, bankAccountId]
          );

          if (insertResult.rows.length > 0) totalImported++;
          else totalSkipped++;
        }

        await db.query('UPDATE bank_connections SET last_sync_at = NOW() WHERE id = $1', [conn.id]);

        // RNF-07: Registrar log de cron sync por conexión
        const connDurationMs = Date.now() - connSyncStart;
        try {
          await db.query(
            `INSERT INTO sync_logs
               (connection_id, user_id, trigger_type, status, imported_count, skipped_count, duration_ms)
             VALUES ($1, $2, 'cron', 'success', $3, $4, $5)`,
            [conn.id, conn.user_id, 0, 0, connDurationMs]
          );
        } catch (_) { /* non-critical */ }

        progress.push({ connection_id: conn.id, status: 'success', duration_ms: connDurationMs });
      } catch (connErr) {
        const connDurationMs = Date.now() - connSyncStart;
        console.error(`[sync-all] Error syncing connection ${conn.id}:`, connErr.message);
        errors.push({ connectionId: conn.id, error: connErr.message });

        // RNF-07: Log de error por conexión
        try {
          await db.query(
            `INSERT INTO sync_logs
               (connection_id, user_id, trigger_type, status, imported_count, skipped_count, duration_ms, error_message)
             VALUES ($1, $2, 'cron', 'error', 0, 0, $3, $4)`,
            [conn.id, conn.user_id, connDurationMs, connErr.message.substring(0, 255)]
          );
        } catch (_) { /* non-critical */ }

        progress.push({ connection_id: conn.id, status: 'error', error: connErr.message, duration_ms: connDurationMs });
      }
    }

    const totalDurationMs = Date.now() - syncAllStart;
    console.log(`[sync-all] Done: ${totalConnections} connections, ${totalImported} imported, ${totalSkipped} skipped, ${totalDurationMs}ms`);
    res.json({
      message: 'Sync-all completed',
      connections: totalConnections,
      imported: totalImported,
      skipped: totalSkipped,
      errors,
      progress,                       // RNF-07: progreso por conexión
      duration_ms: totalDurationMs,   // RNF-07: duración total
      timestamp: new Date().toISOString(),
    });
  } catch (err) {
    console.error('[sync-all] Fatal error:', err);
    res.status(500).json({ error: 'Internal Server Error', message: err.message });
  }
});

// ─── POST /:id/import-accounts ───────────────────────────────────────────────
//
// El usuario confirmó qué cuentas quiere vincular desde la pantalla de selección.
// Importa solo las cuentas seleccionadas, convierte saldos a EUR con tasa real
// y genera transacciones demo para que el balance tenga sentido.
// Marca la conexión como 'linked'.

router.post('/:id/import-accounts', authenticateToken, async (req, res) => {
  const connectionId = req.params.id;
  const { selected_account_ids } = req.body;

  if (!Array.isArray(selected_account_ids) || selected_account_ids.length === 0) {
    return res.status(400).json({ error: 'Bad Request', message: 'selected_account_ids requerido' });
  }

  try {
    const connResult = await db.query(
      'SELECT * FROM bank_connections WHERE id = $1 AND user_id = $2',
      [connectionId, req.user.userId]
    );
    if (connResult.rows.length === 0) {
      return res.status(404).json({ error: 'Not Found', message: 'Conexión no encontrada' });
    }
    const conn = connResult.rows[0];
    const accessToken = conn.requisition_id;

    // Obtener todas las cuentas del proveedor y filtrar las seleccionadas
    const allAccounts = await plaid.fetchAccounts(accessToken);
    const selected = allAccounts.filter(a => selected_account_ids.includes(a.externalAccountId));

    if (selected.length === 0) {
      return res.status(400).json({ error: 'Bad Request', message: 'Ninguna cuenta válida seleccionada' });
    }

    // Limpiar transacciones y cuentas previas de esta conexión
    // (bank_account_id usa ON DELETE SET NULL, así que hay que borrar transacciones primero
    //  para evitar que transacciones demo antiguas contaminen el balance del usuario)
    await db.query(
      `DELETE FROM transactions
       WHERE bank_account_id IN (
         SELECT id FROM bank_accounts WHERE connection_id = $1
       )`,
      [connectionId]
    );
    await db.query('DELETE FROM bank_accounts WHERE connection_id = $1', [connectionId]);

    const importedAccounts = [];
    for (const acct of selected) {
      const eurCents = await toEurCents(acct.balanceCents, acct.currency);

      const result = await db.query(
        `INSERT INTO bank_accounts
           (connection_id, user_id, external_account_id, iban, account_name, currency, balance_cents)
         VALUES ($1, $2, $3, $4, $5, 'EUR', $6)
         RETURNING *`,
        [connectionId, conn.user_id, acct.externalAccountId, acct.iban, acct.name, eurCents]
      );
      const bankAccount = result.rows[0];
      importedAccounts.push(bankAccount);

      // Generar transacciones demo cuya suma coincide exactamente con eurCents,
      // el mismo saldo que el usuario vio en la pantalla de selección de cuentas.
      // balance_cents ya fue insertado correctamente arriba — no hace falta UPDATE.
      await generateRandomTransactions(bankAccount.id, conn.user_id, eurCents);
    }

    // Marcar conexión como linked
    await db.query(
      `UPDATE bank_connections
       SET status = 'linked', linked_at = NOW(), last_sync_at = NOW()
       WHERE id = $1`,
      [connectionId]
    );

    // RNF-05: Crear consentimiento PSD2 (90 días)
    await createPsd2Consent(connectionId, conn.user_id);

    console.log(`[import-accounts] userId=${conn.user_id} connectionId=${connectionId} imported=${importedAccounts.length}`);
    res.json({ ok: true, accounts: importedAccounts.length });
  } catch (err) {
    console.error('[import-accounts] error:', err);
    res.status(500).json({ error: 'Internal Server Error', message: err.message });
  }
});

// ─── DELETE /:id/disconnect ───────────────────────────────────────────────────

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

// ─── RNF-05: Gestión de consentimientos PSD2 ─────────────────────────────────

/**
 * Crea o actualiza el registro de consentimiento PSD2 para una conexión bancaria.
 * Llamado internamente cuando una conexión pasa a estado 'linked'.
 * PSD2: el consentimiento expira a los 90 días (SCA obligatoria cada 90 días).
 *
 * @param {string} connectionId
 * @param {string} userId
 * @param {string} [scope]
 */
async function createPsd2Consent(connectionId, userId, scope = 'read_accounts,read_transactions') {
  const expiresAt = new Date();
  expiresAt.setDate(expiresAt.getDate() + 90);

  await db.query(
    `INSERT INTO psd2_consents (user_id, connection_id, scope, expires_at)
     VALUES ($1, $2, $3, $4)
     ON CONFLICT (connection_id)
     DO UPDATE SET status = 'active', expires_at = EXCLUDED.expires_at,
                   revoked_at = NULL, updated_at = NOW()`,
    [userId, connectionId, scope, expiresAt.toISOString()]
  ).catch(err => {
    console.warn(`[psd2] No se pudo crear consentimiento para ${connectionId}:`, err.message);
  });
}

// ─── GET /consents (RNF-05) ───────────────────────────────────────────────────
//
// Lista todos los consentimientos PSD2 activos del usuario.
// Incluye: estado, scope, fecha de concesión, expiración y días restantes.

router.get('/consents', authenticateToken, async (req, res) => {
  try {
    const result = await db.query(
      `SELECT pc.*, bc.institution_name, bc.institution_logo,
              EXTRACT(DAY FROM (pc.expires_at - NOW())) AS days_remaining
       FROM psd2_consents pc
       JOIN bank_connections bc ON bc.id = pc.connection_id
       WHERE pc.user_id = $1
       ORDER BY pc.expires_at ASC`,
      [req.user.userId]
    );

    const consents = result.rows.map(row => ({
      id:              row.id,
      connectionId:    row.connection_id,
      institutionName: row.institution_name,
      institutionLogo: row.institution_logo,
      status:          row.status,
      scope:           row.scope,
      grantedAt:       row.granted_at,
      expiresAt:       row.expires_at,
      daysRemaining:   Math.max(0, Math.floor(Number(row.days_remaining))),
      renewalRequired: Number(row.days_remaining) <= 14,
      revokedAt:       row.revoked_at,
    }));

    res.json({ consents });
  } catch (err) {
    console.error('banks/consents error:', err);
    res.status(500).json({ error: 'Internal Server Error', message: err.message });
  }
});

// ─── POST /:id/consent/renew (RNF-05) ─────────────────────────────────────────
//
// Renueva el consentimiento PSD2 para una conexión bancaria.
// Reinicia el período de 90 días (PSD2 SCA).

router.post('/:id/consent/renew', authenticateToken, async (req, res) => {
  const connectionId = req.params.id;
  try {
    const connResult = await db.query(
      "SELECT * FROM bank_connections WHERE id = $1 AND user_id = $2 AND status = 'linked'",
      [connectionId, req.user.userId]
    );
    if (connResult.rows.length === 0) {
      return res.status(404).json({ error: 'Not Found', message: 'Conexión no encontrada o no activa' });
    }

    const newExpiresAt = new Date();
    newExpiresAt.setDate(newExpiresAt.getDate() + 90);

    await db.query(
      `INSERT INTO psd2_consents (user_id, connection_id, scope, expires_at)
       VALUES ($1, $2, 'read_accounts,read_transactions', $3)
       ON CONFLICT (connection_id)
       DO UPDATE SET status = 'active', expires_at = EXCLUDED.expires_at,
                     revoked_at = NULL, renewal_notified_at = NULL, updated_at = NOW()`,
      [req.user.userId, connectionId, newExpiresAt.toISOString()]
    );

    console.log(`[consent/renew] userId=${req.user.userId} connectionId=${connectionId} expires=${newExpiresAt.toISOString()}`);
    res.json({
      ok: true,
      message: 'Consentimiento renovado. Acceso garantizado por 90 días más.',
      expiresAt: newExpiresAt.toISOString(),
      daysGranted: 90,
    });
  } catch (err) {
    console.error('banks/consent/renew error:', err);
    res.status(500).json({ error: 'Internal Server Error', message: err.message });
  }
});

// ─── DELETE /:id/consent (RNF-05) ─────────────────────────────────────────────
//
// Revoca el consentimiento PSD2. PSD2: revocación implica cese de acceso a datos.
// La conexión pasa a estado 'disconnected'.

router.delete('/:id/consent', authenticateToken, async (req, res) => {
  const connectionId = req.params.id;
  try {
    const connResult = await db.query(
      'SELECT * FROM bank_connections WHERE id = $1 AND user_id = $2',
      [connectionId, req.user.userId]
    );
    if (connResult.rows.length === 0) {
      return res.status(404).json({ error: 'Not Found', message: 'Conexión no encontrada' });
    }

    await db.query(
      `UPDATE psd2_consents
       SET status = 'revoked', revoked_at = NOW(), updated_at = NOW()
       WHERE connection_id = $1`,
      [connectionId]
    );
    await db.query(
      "UPDATE bank_connections SET status = 'disconnected' WHERE id = $1",
      [connectionId]
    );

    console.log(`[consent/revoke] userId=${req.user.userId} connectionId=${connectionId}`);
    res.json({
      ok: true,
      message: 'Consentimiento revocado. El banco ha sido desconectado conforme a PSD2.',
    });
  } catch (err) {
    console.error('banks/consent/revoke error:', err);
    res.status(500).json({ error: 'Internal Server Error', message: err.message });
  }
});

// ─── GET /sync-logs (RNF-07) ─────────────────────────────────────────────────
//
// Devuelve el historial de sincronizaciones del usuario (para el indicador de
// progreso en el frontend). Incluye duración, estado y contador de importadas.

router.get('/sync-logs', authenticateToken, async (req, res) => {
  try {
    const { limit = 20, connection_id } = req.query;
    const userId = req.user.userId;

    let query = `SELECT sl.*, bc.institution_name
                 FROM sync_logs sl
                 LEFT JOIN bank_connections bc ON bc.id = sl.connection_id
                 WHERE sl.user_id = $1`;
    const params = [userId];

    if (connection_id) {
      params.push(connection_id);
      query += ` AND sl.connection_id = $${params.length}`;
    }

    query += ` ORDER BY sl.synced_at DESC LIMIT $${params.length + 1}`;
    params.push(parseInt(limit));

    const result = await db.query(query, params);
    res.json({ sync_logs: result.rows });
  } catch (err) {
    console.error('sync-logs error:', err);
    res.status(500).json({ error: 'Internal Server Error', message: err.message });
  }
});

// ─── GET /health/circuit-breaker (RNF-16) ─────────────────────────────────────
//
// Endpoint de monitorización del circuit breaker de servicios externos.

const { plaidBreaker: _plaidBreaker, ratesBreaker: _ratesBreaker } = require('../services/circuitBreaker');

router.get('/health/circuit-breaker', (req, res) => {
  res.json({
    plaid:   _plaidBreaker.status(),
    rates:   _ratesBreaker.status(),
    timestamp: new Date().toISOString(),
  });
});

module.exports = router;
module.exports.createPsd2Consent = createPsd2Consent;