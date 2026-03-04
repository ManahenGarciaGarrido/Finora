const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const { body, param, query, validationResult } = require('express-validator');
const db = require('../services/db');

const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-change-in-production';
const AI_SERVICE_URL = process.env.AI_SERVICE_URL || 'http://localhost:5001';

// ── RF-23 / HU-10: Async anomaly check — fire-and-forget ────────────────────
/**
 * Verifica si una transacción recién registrada es anómala respecto al
 * historial de la misma categoría del usuario.
 * Si es anómala, crea una notificación in-app.
 * Corre en background (no bloquea la respuesta al cliente).
 */
async function _checkAnomalyAsync(userId, newTx) {
  try {
    // Obtener historial últimos 3 meses de la misma categoría
    const cutoff = new Date();
    cutoff.setMonth(cutoff.getMonth() - 3);
    const histResult = await db.query(
      `SELECT id, amount::float AS amount, type, category, description,
              TO_CHAR(date, 'YYYY-MM-DD') AS date
       FROM transactions
       WHERE user_id = $1 AND type = 'expense' AND category = $2 AND date >= $3
       ORDER BY date ASC`,
      [userId, newTx.category, cutoff.toISOString().split('T')[0]]
    );

    const history = histResult.rows;
    if (history.length < 4) return; // Historial insuficiente para estadísticas

    // Llamar al servicio AI
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), 10000);
    let aiResult;
    try {
      const resp = await fetch(`${AI_SERVICE_URL}/detect-anomalies`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ transactions: history }),
        signal: controller.signal,
      });
      clearTimeout(timer);
      if (!resp.ok) return;
      aiResult = await resp.json();
    } catch {
      clearTimeout(timer);
      return;
    }

    // ¿Está la nueva transacción entre las anomalías?
    const anomaly = (aiResult.anomalies || []).find(a => a.id === newTx.id);
    if (!anomaly) return;

    // Crear notificación HU-10
    await db.query(
      `INSERT INTO notifications (user_id, type, title, body, metadata)
       VALUES ($1, 'anomaly_alert', $2, $3, $4)`,
      [
        userId,
        '⚠️ Gasto inusual detectado',
        anomaly.message,
        JSON.stringify({
          transaction_id: newTx.id,
          category:       anomaly.category,
          amount:         anomaly.amount,
          z_score:        anomaly.z_score,
          severity:       anomaly.severity,
        }),
      ]
    );
  } catch (err) {
    // Fire-and-forget: errores no críticos, no afectan al usuario
    console.warn('[RF-23] _checkAnomalyAsync error:', err.message);
  }
}

const VALID_PAYMENT_METHODS = [
  'cash', 'card', 'transfer',
  'debit_card', 'credit_card', 'prepaid_card',
  'bank_transfer', 'bizum', 'paypal',
  'apple_pay', 'google_pay', 'direct_debit',
  'cheque', 'crypto', 'voucher', 'sepa', 'wire',
];

// Authentication middleware
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({
      error: 'Unauthorized',
      message: 'No token provided'
    });
  }

  const token = authHeader.substring(7);

  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    req.user = decoded;
    next();
  } catch (error) {
    if (error.name === 'JsonWebTokenError') {
      return res.status(401).json({
        error: 'Unauthorized',
        message: 'Invalid token'
      });
    }
    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({
        error: 'Unauthorized',
        message: 'Token expired'
      });
    }
    return res.status(401).json({
      error: 'Unauthorized',
      message: 'Authentication failed'
    });
  }
};

// ============================================
// CREATE TRANSACTION (RF-05)
// ============================================
router.post('/',
  authenticateToken,
  [
    body('amount')
      .isFloat({ min: 0.01 })
      .withMessage('La cantidad debe ser un número positivo mayor que 0'),
    body('type')
      .isIn(['income', 'expense'])
      .withMessage('El tipo debe ser "income" o "expense"'),
    body('category')
      .notEmpty()
      .trim()
      .withMessage('La categoría es requerida'),
    body('description')
      .optional()
      .trim()
      .isLength({ max: 500 })
      .withMessage('La descripción no puede exceder 500 caracteres'),
    body('date')
      .isISO8601()
      .withMessage('La fecha debe ser una fecha válida en formato ISO 8601'),
    body('payment_method')
      .isIn(VALID_PAYMENT_METHODS)
      .withMessage('Método de pago inválido'),
    body('bank_account_id').optional({ nullable: true }).isUUID().withMessage('ID de cuenta bancaria inválido'),
    body('card_id').optional({ nullable: true }).isUUID().withMessage('ID de tarjeta inválido'),
  ],
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({
          error: 'Validation Error',
          message: 'Los datos proporcionados no son válidos',
          details: errors.array()
        });
      }

      const { amount, type, category, description, date, payment_method, bank_account_id, card_id } = req.body;
      const userId = req.user.userId;

      const result = await db.query(
        `INSERT INTO transactions (user_id, amount, type, category, description, date, payment_method, bank_account_id, card_id)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
         RETURNING *`,
        [userId, amount, type, category, description || null, date, payment_method, bank_account_id || null, card_id || null]
      );

      const tx = result.rows[0];
      let accountId = tx.bank_account_id;
      if (!accountId && tx.card_id) {
        const cardRow = await db.query('SELECT bank_account_id FROM bank_cards WHERE id = $1', [tx.card_id]);
        if (cardRow.rows.length > 0) accountId = cardRow.rows[0].bank_account_id;
      }
      if (accountId) {
        const sign = tx.type === 'income' ? 1 : -1;
        await db.query(
          'UPDATE bank_accounts SET balance_cents = balance_cents + $1, updated_at = NOW() WHERE id = $2',
          [Math.round(parseFloat(tx.amount) * 100) * sign, accountId]
        );
      }

      res.status(201).json({
        message: 'Transacción registrada exitosamente',
        transaction: tx
      });

      // RF-23 / HU-10: Verificar anomalía de forma asíncrona (fire-and-forget)
      if (tx.type === 'expense') {
        _checkAnomalyAsync(userId, tx).catch(() => {});
      }
    } catch (error) {
      console.error('Error creating transaction:', error);
      res.status(500).json({
        error: 'Server Error',
        message: 'Error al registrar la transacción'
      });
    }
  }
);

// ============================================
// GET ALL TRANSACTIONS (with pagination)
// ============================================
router.get('/',
  authenticateToken,
  [
    query('page').optional().isInt({ min: 1 }).withMessage('La página debe ser un número positivo'),
    query('limit').optional().isInt({ min: 1, max: 500 }).withMessage('El límite debe ser entre 1 y 500'),
    query('type').optional().isIn(['income', 'expense']).withMessage('Tipo inválido'),
    query('category').optional().trim(),
    query('categories').optional().trim(),
    query('from').optional().isISO8601().withMessage('Fecha desde inválida'),
    query('to').optional().isISO8601().withMessage('Fecha hasta inválida'),
    query('payment_method').optional().isIn(VALID_PAYMENT_METHODS).withMessage('Método de pago inválido'),
  ],
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({
          error: 'Validation Error',
          details: errors.array()
        });
      }

      const userId = req.user.userId;
      const page = parseInt(req.query.page) || 1;
      const limit = parseInt(req.query.limit) || 20;
      const offset = (page - 1) * limit;

      let whereClause = 'WHERE user_id = $1';
      const params = [userId];
      let paramIndex = 2;

      if (req.query.type) {
        whereClause += ` AND type = $${paramIndex}`;
        params.push(req.query.type);
        paramIndex++;
      }

      if (req.query.categories) {
        // Soporte para múltiples categorías separadas por coma (RF-08)
        const categoryList = req.query.categories.split(',').map(c => c.trim()).filter(c => c.length > 0);
        if (categoryList.length > 0) {
          const placeholders = categoryList.map((_, i) => `$${paramIndex + i}`).join(', ');
          whereClause += ` AND category IN (${placeholders})`;
          params.push(...categoryList);
          paramIndex += categoryList.length;
        }
      } else if (req.query.category) {
        whereClause += ` AND category = $${paramIndex}`;
        params.push(req.query.category);
        paramIndex++;
      }

      if (req.query.payment_method) {
        whereClause += ` AND payment_method = $${paramIndex}`;
        params.push(req.query.payment_method);
        paramIndex++;
      }

      if (req.query.from) {
        whereClause += ` AND date >= $${paramIndex}`;
        params.push(req.query.from);
        paramIndex++;
      }

      if (req.query.to) {
        whereClause += ` AND date <= $${paramIndex}`;
        params.push(req.query.to);
        paramIndex++;
      }

      // RF-12: Filtrar por cuenta bancaria específica
      if (req.query.bank_account_id) {
        whereClause += ` AND bank_account_id = $${paramIndex}`;
        params.push(req.query.bank_account_id);
        paramIndex++;
      }

      // RNF-20: Count, totales y datos en una sola consulta usando window functions.
      // Incluye SUM de ingresos/gastos sobre TODO el conjunto filtrado (no solo la página),
      // para que el cliente pueda mostrar el balance real aunque solo haya cargado la pág 1.
      const result = await db.query(
        `SELECT *,
                COUNT(*) OVER () AS _total_count,
                SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END) OVER () AS _total_income,
                SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END) OVER () AS _total_expense
         FROM transactions
         ${whereClause}
         ORDER BY date DESC, created_at DESC
         LIMIT $${paramIndex}
         OFFSET $${paramIndex + 1}`,
        [...params, limit, offset]
      );

      // Extraer totales de la primera fila (si hay resultados)
      const firstRow = result.rows[0];
      const total        = firstRow ? parseInt(firstRow._total_count)       : 0;
      const totalIncome  = firstRow ? parseFloat(firstRow._total_income)    : 0;
      const totalExpense = firstRow ? parseFloat(firstRow._total_expense)   : 0;

      // Limpiar columnas auxiliares antes de devolver
      const transactions = result.rows.map(
        ({ _total_count, _total_income, _total_expense, ...tx }) => tx
      );

      res.json({
        transactions,
        pagination: {
          page,
          limit,
          total,
          totalPages: Math.ceil(total / limit),
          hasMore: offset + transactions.length < total,
        },
        // Totales sobre el conjunto completo (respetan los filtros activos)
        totals: { income: totalIncome, expense: totalExpense },
      });
    } catch (error) {
      console.error('Error fetching transactions:', error);
      res.status(500).json({
        error: 'Server Error',
        message: 'Error al obtener las transacciones'
      });
    }
  }
);

// ============================================
// GET SINGLE TRANSACTION
// ============================================
router.get('/:id',
  authenticateToken,
  [
    param('id').isUUID().withMessage('ID de transacción inválido'),
  ],
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({
          error: 'Validation Error',
          details: errors.array()
        });
      }

      const result = await db.query(
        'SELECT * FROM transactions WHERE id = $1 AND user_id = $2',
        [req.params.id, req.user.userId]
      );

      if (result.rows.length === 0) {
        return res.status(404).json({
          error: 'Not Found',
          message: 'Transacción no encontrada'
        });
      }

      res.json({ transaction: result.rows[0] });
    } catch (error) {
      console.error('Error fetching transaction:', error);
      res.status(500).json({
        error: 'Server Error',
        message: 'Error al obtener la transacción'
      });
    }
  }
);

// ============================================
// UPDATE TRANSACTION (RF-06)
// ============================================
router.put('/:id',
  authenticateToken,
  [
    param('id').isUUID().withMessage('ID de transacción inválido'),
    body('amount')
      .isFloat({ min: 0.01 })
      .withMessage('La cantidad debe ser un número positivo mayor que 0'),
    body('type')
      .isIn(['income', 'expense'])
      .withMessage('El tipo debe ser "income" o "expense"'),
    body('category')
      .notEmpty()
      .trim()
      .withMessage('La categoría es requerida'),
    body('description')
      .optional()
      .trim()
      .isLength({ max: 500 })
      .withMessage('La descripción no puede exceder 500 caracteres'),
    body('date')
      .isISO8601()
      .withMessage('La fecha debe ser una fecha válida en formato ISO 8601'),
    body('payment_method')
      .isIn(VALID_PAYMENT_METHODS)
      .withMessage('Método de pago inválido'),
    body('bank_account_id').optional({ nullable: true }).isUUID().withMessage('ID de cuenta bancaria inválido'),
    body('card_id').optional({ nullable: true }).isUUID().withMessage('ID de tarjeta inválido'),
  ],
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({
          error: 'Validation Error',
          message: 'Los datos proporcionados no son válidos',
          details: errors.array()
        });
      }

      const userId = req.user.userId;
      const transactionId = req.params.id;

      // Verificar que la transacción existe y pertenece al usuario
      const existing = await db.query(
        'SELECT * FROM transactions WHERE id = $1 AND user_id = $2',
        [transactionId, userId]
      );

      if (existing.rows.length === 0) {
        return res.status(404).json({
          error: 'Not Found',
          message: 'Transacción no encontrada'
        });
      }
      const old = existing.rows[0];

      const { amount, type, category, description, date, payment_method, bank_account_id, card_id } = req.body;

      const result = await db.query(
        `UPDATE transactions
         SET amount = $1, type = $2, category = $3, description = $4,
             date = $5, payment_method = $6, bank_account_id = $7, card_id = $8, updated_at = NOW()
         WHERE id = $9 AND user_id = $10
         RETURNING *`,
        [amount, type, category, description || null, date, payment_method, bank_account_id || null, card_id || null, transactionId, userId]
      );
      const updated = result.rows[0];

      // Revertir efecto de la transacción anterior sobre el saldo de cuenta
      let oldAccountId = old.bank_account_id;
      if (!oldAccountId && old.card_id) {
        const cardRow = await db.query('SELECT bank_account_id FROM bank_cards WHERE id = $1', [old.card_id]);
        if (cardRow.rows.length > 0) oldAccountId = cardRow.rows[0].bank_account_id;
      }
      if (oldAccountId) {
        const oldSign = old.type === 'income' ? -1 : 1; // invertir para revertir
        await db.query(
          'UPDATE bank_accounts SET balance_cents = balance_cents + $1, updated_at = NOW() WHERE id = $2',
          [Math.round(parseFloat(old.amount) * 100) * oldSign, oldAccountId]
        );
      }

      // Aplicar efecto de la transacción nueva sobre el saldo de cuenta
      let newAccountId = updated.bank_account_id;
      if (!newAccountId && updated.card_id) {
        const cardRow = await db.query('SELECT bank_account_id FROM bank_cards WHERE id = $1', [updated.card_id]);
        if (cardRow.rows.length > 0) newAccountId = cardRow.rows[0].bank_account_id;
      }
      if (newAccountId) {
        const newSign = updated.type === 'income' ? 1 : -1;
        await db.query(
          'UPDATE bank_accounts SET balance_cents = balance_cents + $1, updated_at = NOW() WHERE id = $2',
          [Math.round(parseFloat(updated.amount) * 100) * newSign, newAccountId]
        );
      }

      res.json({
        message: 'Transacción actualizada exitosamente',
        transaction: updated
      });
    } catch (error) {
      console.error('Error updating transaction:', error);
      res.status(500).json({
        error: 'Server Error',
        message: 'Error al actualizar la transacción'
      });
    }
  }
);

// ============================================
// DELETE TRANSACTION (RF-06)
// ============================================
router.delete('/:id',
  authenticateToken,
  [
    param('id').isUUID().withMessage('ID de transacción inválido'),
  ],
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({
          error: 'Validation Error',
          details: errors.array()
        });
      }

      // Obtener datos completos antes de borrar para revertir el saldo
      const fetchResult = await db.query(
        'SELECT * FROM transactions WHERE id = $1 AND user_id = $2',
        [req.params.id, req.user.userId]
      );

      if (fetchResult.rows.length === 0) {
        return res.status(404).json({
          error: 'Not Found',
          message: 'Transacción no encontrada'
        });
      }
      const tx = fetchResult.rows[0];

      await db.query(
        'DELETE FROM transactions WHERE id = $1 AND user_id = $2',
        [req.params.id, req.user.userId]
      );

      // Revertir efecto sobre el saldo de la cuenta
      let accountId = tx.bank_account_id;
      if (!accountId && tx.card_id) {
        const cardRow = await db.query('SELECT bank_account_id FROM bank_cards WHERE id = $1', [tx.card_id]);
        if (cardRow.rows.length > 0) accountId = cardRow.rows[0].bank_account_id;
      }
      if (accountId) {
        const sign = tx.type === 'income' ? -1 : 1; // invertir para revertir
        await db.query(
          'UPDATE bank_accounts SET balance_cents = balance_cents + $1, updated_at = NOW() WHERE id = $2',
          [Math.round(parseFloat(tx.amount) * 100) * sign, accountId]
        );
      }

      res.json({
        message: 'Transacción eliminada exitosamente',
        id: tx.id
      });
    } catch (error) {
      console.error('Error deleting transaction:', error);
      res.status(500).json({
        error: 'Server Error',
        message: 'Error al eliminar la transacción'
      });
    }
  }
);

// ============================================
// GET BALANCE SUMMARY
// ============================================
router.get('/summary/balance',
  authenticateToken,
  async (req, res) => {
    try {
      const userId = req.user.userId;

      const result = await db.query(
        `SELECT
          COALESCE(SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END), 0) as total_income,
          COALESCE(SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END), 0) as total_expenses,
          COALESCE(SUM(CASE WHEN type = 'income' THEN amount ELSE -amount END), 0) as balance,
          COUNT(*) as total_transactions
        FROM transactions WHERE user_id = $1`,
        [userId]
      );

      res.json({
        summary: {
          totalIncome: parseFloat(result.rows[0].total_income),
          totalExpenses: parseFloat(result.rows[0].total_expenses),
          balance: parseFloat(result.rows[0].balance),
          totalTransactions: parseInt(result.rows[0].total_transactions)
        }
      });
    } catch (error) {
      console.error('Error fetching balance summary:', error);
      res.status(500).json({
        error: 'Server Error',
        message: 'Error al obtener el resumen del balance'
      });
    }
  }
);

// ============================================
// IMPORT TRANSACTIONS FROM CSV (RF-10 fallback)
//
// Acepta el contenido del CSV como string en el body JSON.
// Compatible con los formatos de exportación de los principales bancos españoles.
//
// Body: { "csv": "<contenido del fichero>", "bank": "<nombre banco opcional>" }
//
// Formatos soportados automáticamente:
//   BBVA, Santander, CaixaBank, Sabadell, Bankinter, ING —
//   cualquier banco que exporte Fecha/Date + Concepto/Descripción + Importe/Amount
//   con separador coma, punto y coma o tabulación.
// ============================================

// ── CSV parser helpers ────────────────────────────────────────────────────

function detectSeparator(line) {
  const counts = { ';': 0, ',': 0, '\t': 0 };
  for (const c of line) if (c in counts) counts[c]++;
  return Object.entries(counts).sort((a, b) => b[1] - a[1])[0][0];
}

function splitCSVRow(line, sep) {
  const cols = [];
  let cur = '';
  let inQuotes = false;
  for (const ch of line) {
    if (ch === '"') { inQuotes = !inQuotes; }
    else if (ch === sep && !inQuotes) { cols.push(cur.trim().replace(/^"|"$/g, '')); cur = ''; }
    else { cur += ch; }
  }
  cols.push(cur.trim().replace(/^"|"$/g, ''));
  return cols;
}

function parseDate(raw) {
  if (!raw) return null;
  const s = raw.trim();
  // DD/MM/YYYY o DD-MM-YYYY
  let m = s.match(/^(\d{1,2})[\/\-](\d{1,2})[\/\-](\d{4})$/);
  if (m) return `${m[3]}-${m[2].padStart(2, '0')}-${m[1].padStart(2, '0')}`;
  // YYYY-MM-DD o YYYY/MM/DD
  m = s.match(/^(\d{4})[\/\-](\d{1,2})[\/\-](\d{1,2})$/);
  if (m) return `${m[1]}-${m[2].padStart(2, '0')}-${m[3].padStart(2, '0')}`;
  return null;
}

function parseAmount(raw) {
  if (!raw || raw.trim() === '' || raw.trim() === '-') return null;
  // Quitar símbolos de moneda y espacios
  let s = raw.trim().replace(/[€$£\s]/g, '');
  // Detectar formato europeo: 1.234,56 → 1234.56
  if (/\d{1,3}(\.\d{3})+(,\d{1,2})?$/.test(s)) {
    s = s.replace(/\./g, '').replace(',', '.');
  } else {
    // Formato anglosajón o coma como decimal: 1,234.56 o 42,50
    s = s.replace(/,(?=\d{3})/g, '').replace(',', '.');
  }
  const n = parseFloat(s);
  return isNaN(n) ? null : n;
}

function findColIdx(headers, candidates) {
  const norm = headers.map(h => h.toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g, '').trim());
  for (const cand of candidates) {
    const idx = norm.findIndex(h => h === cand || h.startsWith(cand));
    if (idx !== -1) return idx;
  }
  return -1;
}

function isHeaderRow(cols) {
  // Consideramos que es cabecera si ninguna celda parsea como fecha
  return cols.every(c => parseDate(c) === null);
}

function parseCSV(csvText) {
  // Normalizar saltos de línea y eliminar BOM
  const lines = csvText.replace(/^\uFEFF/, '').replace(/\r\n/g, '\n').replace(/\r/g, '\n').split('\n').filter(l => l.trim());
  if (lines.length < 2) return { error: 'El fichero CSV está vacío o tiene menos de 2 filas' };

  const sep = detectSeparator(lines[0]);

  // Buscar la fila de cabecera (primera fila que no es una fecha)
  let headerIdx = 0;
  let headers = splitCSVRow(lines[headerIdx], sep);
  // Algunos bancos tienen filas de metadata antes; buscamos la que tenga columnas útiles
  for (let i = 0; i < Math.min(5, lines.length); i++) {
    const cols = splitCSVRow(lines[i], sep);
    const norm = cols.map(c => c.toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g, '').trim());
    if (norm.some(c => ['fecha', 'date', 'data'].includes(c) || c.startsWith('fecha'))) {
      headerIdx = i;
      headers = cols;
      break;
    }
  }

  // Mapear columnas
  const dateCol   = findColIdx(headers, ['fecha operacion', 'fecha operac', 'fecha valor', 'fecha', 'date', 'data', 'f.operacion', 'f.valor']);
  const descCol   = findColIdx(headers, ['concepto', 'descripcion', 'description', 'concepte', 'movimiento', 'texto', 'detalle', 'observaciones', 'beneficiario/ordenante']);
  const amtCol    = findColIdx(headers, ['importe', 'amount', 'import', 'cantidad', 'importe eur', 'importe (eur)']);
  const debitCol  = findColIdx(headers, ['cargo', 'debito', 'salida', 'debe', 'debit', 'disposicion']);
  const creditCol = findColIdx(headers, ['abono', 'credito', 'entrada', 'haber', 'credit', 'ingreso']);

  if (dateCol === -1) {
    return { error: 'No se encontró columna de fecha. Asegúrate de que el CSV tiene una columna Fecha/Date/Data.' };
  }
  if (descCol === -1) {
    return { error: 'No se encontró columna de descripción. Asegúrate de que el CSV tiene una columna Concepto/Descripción.' };
  }
  if (amtCol === -1 && (debitCol === -1 || creditCol === -1)) {
    return { error: 'No se encontró columna de importe. El CSV debe tener Importe, o columnas Cargo/Abono separadas.' };
  }

  const rows = [];
  for (let i = headerIdx + 1; i < lines.length; i++) {
    const cols = splitCSVRow(lines[i], sep);
    if (cols.length < 2) continue;

    const dateStr = cols[dateCol];
    const date    = parseDate(dateStr);
    if (!date) continue; // fila sin fecha válida (totales, líneas vacías, etc.)

    const description = (descCol !== -1 ? cols[descCol] : '').trim() || 'Transacción bancaria';

    let amount;
    if (amtCol !== -1) {
      amount = parseAmount(cols[amtCol]);
    } else {
      // Dos columnas separadas: cargo (negativo) y abono (positivo)
      const debit  = parseAmount(cols[debitCol])  || 0;
      const credit = parseAmount(cols[creditCol]) || 0;
      amount = credit > 0 ? credit : (debit > 0 ? -debit : null);
    }

    if (amount === null) continue;

    rows.push({ date, description, amount });
  }

  return { rows, sep, dateCol, descCol, amtCol };
}

// ── Endpoint ──────────────────────────────────────────────────────────────

router.post('/import-csv',
  authenticateToken,
  async (req, res) => {
    try {
      const csvText = req.body?.csv;
      if (!csvText || typeof csvText !== 'string' || csvText.trim().length === 0) {
        return res.status(400).json({
          error: 'Bad Request',
          message: 'Campo "csv" obligatorio con el contenido del fichero CSV.'
        });
      }

      if (csvText.length > 5 * 1024 * 1024) {
        return res.status(400).json({ error: 'Bad Request', message: 'El fichero CSV supera el límite de 5 MB.' });
      }

      const parsed = parseCSV(csvText);
      if (parsed.error) {
        return res.status(422).json({ error: 'Parse Error', message: parsed.error });
      }
      if (parsed.rows.length === 0) {
        return res.status(422).json({ error: 'Parse Error', message: 'No se encontraron transacciones válidas en el fichero.' });
      }

      const userId = req.user.userId;
      let imported = 0;
      let skipped  = 0;

      for (const tx of parsed.rows) {
        const absAmount = Math.abs(tx.amount);
        const txType    = tx.amount < 0 ? 'expense' : 'income';
        const category  = txType === 'expense' ? 'Otros' : 'Otros ingresos';

        // ID único para deduplicación: hash de fecha + descripción + importe
        const hash = crypto.createHash('sha256')
          .update(`${tx.date}|${tx.description}|${tx.amount}`)
          .digest('hex')
          .substring(0, 32);
        const externalId = `csv_${hash}`;

        const result = await db.query(
          `INSERT INTO transactions
             (user_id, amount, type, category, description, date, payment_method, external_tx_id)
           VALUES ($1, $2, $3, $4, $5, $6, 'transfer', $7)
           ON CONFLICT (external_tx_id) DO NOTHING
           RETURNING id`,
          [userId, absAmount, txType, category, tx.description, tx.date, externalId]
        );

        result.rows.length > 0 ? imported++ : skipped++;
      }

      res.json({
        message: 'Importación completada',
        imported,
        skipped,
        total_parsed: parsed.rows.length,
      });
    } catch (error) {
      console.error('Error importing CSV:', error);
      res.status(500).json({ error: 'Server Error', message: 'Error al importar el fichero CSV.' });
    }
  }
);

module.exports = router;