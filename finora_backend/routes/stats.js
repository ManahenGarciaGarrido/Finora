/**
 * RF-29 / RF-30: Estadísticas y Visualización de Gastos
 *
 * Endpoints:
 * GET /api/v1/stats/summary          → Totales de ingresos/gastos/balance por período
 * GET /api/v1/stats/by-category      → Distribución de gastos por categoría (RF-29)
 * GET /api/v1/stats/monthly          → Evolución mensual de ingresos/gastos (RF-30)
 * GET /api/v1/stats/trends           → Tendencias y comparativas entre períodos
 *
 * Todos los endpoints requieren autenticación JWT.
 * Soportan parámetro `period`: current_month | 3_months | 6_months | 1_year | all
 */

const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const { query, validationResult } = require('express-validator');
const db = require('../services/db');

const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-change-in-production';

// ── Auth middleware ──────────────────────────────────────────────────────────

const authenticateToken = (req, res, next) => {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Unauthorized', message: 'No token provided' });
  }
  const token = authHeader.substring(7);
  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    req.user = decoded;
    next();
  } catch (error) {
    return res.status(401).json({ error: 'Unauthorized', message: 'Invalid or expired token' });
  }
};

// ── Helpers ──────────────────────────────────────────────────────────────────

/**
 * Construye el filtro SQL de fecha según el período solicitado.
 * @param {string} period - Período: current_month | 3_months | 6_months | 1_year | all
 * @returns {{ sql: string, params: any[] }}
 */
function buildDateFilter(period) {
  const now = new Date();
  const year = now.getFullYear();
  const month = now.getMonth() + 1; // 1-based

  switch (period) {
    case 'current_month':
      return {
        sql: "AND date >= date_trunc('month', NOW())",
        params: [],
      };
    case '3_months':
      return {
        sql: "AND date >= date_trunc('month', NOW() - INTERVAL '2 months')",
        params: [],
      };
    case '6_months':
      return {
        sql: "AND date >= date_trunc('month', NOW() - INTERVAL '5 months')",
        params: [],
      };
    case '1_year':
      return {
        sql: "AND date >= date_trunc('month', NOW() - INTERVAL '11 months')",
        params: [],
      };
    case 'all':
    default:
      return { sql: '', params: [] };
  }
}

// ── GET /api/v1/stats/summary ─────────────────────────────────────────────────

/**
 * RF-29: Resumen financiero del período
 *
 * Response: {
 *   period: string,
 *   total_income: number,
 *   total_expenses: number,
 *   net_balance: number,
 *   savings_rate: number,  // porcentaje sobre ingresos
 *   transaction_count: number,
 *   income_count: number,
 *   expense_count: number
 * }
 */
router.get('/summary',
  authenticateToken,
  [
    query('period')
      .optional()
      .isIn(['current_month', '3_months', '6_months', '1_year', 'all'])
      .withMessage('period must be: current_month, 3_months, 6_months, 1_year, all'),
  ],
  async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const period = req.query.period || 'current_month';
    const { sql: dateFilter } = buildDateFilter(period);

    try {
      const result = await db.query(
        `SELECT
           COALESCE(SUM(CASE WHEN type = 'income'  THEN amount ELSE 0 END), 0) AS total_income,
           COALESCE(SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END), 0) AS total_expenses,
           COUNT(*)                                                              AS transaction_count,
           COUNT(CASE WHEN type = 'income'  THEN 1 END)                        AS income_count,
           COUNT(CASE WHEN type = 'expense' THEN 1 END)                        AS expense_count
         FROM transactions
         WHERE user_id = $1
           ${dateFilter}`,
        [req.user.id],
      );

      const row = result.rows[0];
      const totalIncome = parseFloat(row.total_income);
      const totalExpenses = parseFloat(row.total_expenses);
      const netBalance = totalIncome - totalExpenses;
      const savingsRate = totalIncome > 0
        ? Math.max(0, (netBalance / totalIncome) * 100)
        : 0;

      return res.json({
        period,
        total_income: totalIncome,
        total_expenses: totalExpenses,
        net_balance: netBalance,
        savings_rate: Math.round(savingsRate * 10) / 10,
        transaction_count: parseInt(row.transaction_count),
        income_count: parseInt(row.income_count),
        expense_count: parseInt(row.expense_count),
      });
    } catch (err) {
      console.error('[stats/summary] Error:', err.message);
      return res.status(500).json({ error: 'Internal server error' });
    }
  },
);

// ── GET /api/v1/stats/by-category ────────────────────────────────────────────

/**
 * RF-29: Distribución de gastos por categoría
 *
 * Response: {
 *   period: string,
 *   total_expenses: number,
 *   categories: [{ category, total, percentage, transaction_count }]
 * }
 */
router.get('/by-category',
  authenticateToken,
  [
    query('period').optional()
      .isIn(['current_month', '3_months', '6_months', '1_year', 'all']),
    query('type').optional().isIn(['expense', 'income']),
  ],
  async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const period = req.query.period || 'current_month';
    const txType = req.query.type || 'expense';
    const { sql: dateFilter } = buildDateFilter(period);

    try {
      // Totales por categoría con porcentaje usando window function
      const result = await db.query(
        `SELECT
           category,
           SUM(amount)                          AS total,
           COUNT(*)                             AS transaction_count,
           SUM(SUM(amount)) OVER ()             AS grand_total
         FROM transactions
         WHERE user_id = $1
           AND type = $2
           ${dateFilter}
         GROUP BY category
         ORDER BY total DESC`,
        [req.user.id, txType],
      );

      const grandTotal = result.rows.length > 0
        ? parseFloat(result.rows[0].grand_total)
        : 0;

      const categories = result.rows.map(row => {
        const total = parseFloat(row.total);
        return {
          category: row.category,
          total,
          percentage: grandTotal > 0
            ? Math.round((total / grandTotal) * 1000) / 10  // 1 decimal
            : 0,
          transaction_count: parseInt(row.transaction_count),
        };
      });

      return res.json({
        period,
        type: txType,
        total_expenses: grandTotal,
        categories,
      });
    } catch (err) {
      console.error('[stats/by-category] Error:', err.message);
      return res.status(500).json({ error: 'Internal server error' });
    }
  },
);

// ── GET /api/v1/stats/monthly ─────────────────────────────────────────────────

/**
 * RF-30: Evolución mensual de ingresos y gastos
 *
 * Response: {
 *   period: string,
 *   months: [{
 *     year, month, month_label,
 *     income, expenses, balance,
 *     income_count, expense_count
 *   }]
 * }
 */
router.get('/monthly',
  authenticateToken,
  [
    query('period').optional()
      .isIn(['3_months', '6_months', '1_year', 'all']),
  ],
  async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const period = req.query.period || '6_months';
    const { sql: dateFilter } = buildDateFilter(period);

    try {
      const result = await db.query(
        `SELECT
           EXTRACT(YEAR  FROM date)::int                                AS year,
           EXTRACT(MONTH FROM date)::int                                AS month,
           COALESCE(SUM(CASE WHEN type='income'  THEN amount ELSE 0 END), 0) AS income,
           COALESCE(SUM(CASE WHEN type='expense' THEN amount ELSE 0 END), 0) AS expenses,
           COUNT(CASE WHEN type='income'  THEN 1 END)                        AS income_count,
           COUNT(CASE WHEN type='expense' THEN 1 END)                        AS expense_count
         FROM transactions
         WHERE user_id = $1
           ${dateFilter}
         GROUP BY year, month
         ORDER BY year, month`,
        [req.user.id],
      );

      const spanishMonths = [
        'Enero','Febrero','Marzo','Abril','Mayo','Junio',
        'Julio','Agosto','Septiembre','Octubre','Noviembre','Diciembre',
      ];

      const months = result.rows.map(row => {
        const income = parseFloat(row.income);
        const expenses = parseFloat(row.expenses);
        return {
          year: row.year,
          month: row.month,
          month_label: `${spanishMonths[row.month - 1]} ${row.year}`,
          income,
          expenses,
          balance: income - expenses,
          income_count: parseInt(row.income_count),
          expense_count: parseInt(row.expense_count),
        };
      });

      return res.json({ period, months });
    } catch (err) {
      console.error('[stats/monthly] Error:', err.message);
      return res.status(500).json({ error: 'Internal server error' });
    }
  },
);

// ── GET /api/v1/stats/trends ──────────────────────────────────────────────────

/**
 * RF-30: Comparativa entre el mes actual y el mes anterior
 *
 * Response: {
 *   current_month: { income, expenses, balance },
 *   previous_month: { income, expenses, balance },
 *   changes: { income_pct, expenses_pct, balance_pct },
 *   top_expense_categories: [{ category, total, vs_last_month_pct }]
 * }
 */
router.get('/trends',
  authenticateToken,
  async (req, res) => {
    try {
      const result = await db.query(
        `WITH monthly AS (
           SELECT
             date_trunc('month', date) AS month_start,
             SUM(CASE WHEN type='income'  THEN amount ELSE 0 END) AS income,
             SUM(CASE WHEN type='expense' THEN amount ELSE 0 END) AS expenses
           FROM transactions
           WHERE user_id = $1
             AND date >= date_trunc('month', NOW() - INTERVAL '1 month')
           GROUP BY month_start
         )
         SELECT * FROM monthly ORDER BY month_start DESC`,
        [req.user.id],
      );

      const rows = result.rows;
      const current = rows[0] || { income: 0, expenses: 0 };
      const previous = rows[1] || { income: 0, expenses: 0 };

      const pctChange = (curr, prev) => {
        if (!prev || prev === 0) return curr > 0 ? 100 : 0;
        return Math.round(((curr - prev) / prev) * 1000) / 10;
      };

      const currentIncome = parseFloat(current.income) || 0;
      const currentExpenses = parseFloat(current.expenses) || 0;
      const previousIncome = parseFloat(previous.income) || 0;
      const previousExpenses = parseFloat(previous.expenses) || 0;

      // Top categorías de gasto del mes actual vs mes anterior
      const catResult = await db.query(
        `WITH curr AS (
           SELECT category, SUM(amount) AS total
           FROM transactions
           WHERE user_id = $1 AND type = 'expense'
             AND date >= date_trunc('month', NOW())
           GROUP BY category
         ),
         prev AS (
           SELECT category, SUM(amount) AS total
           FROM transactions
           WHERE user_id = $1 AND type = 'expense'
             AND date >= date_trunc('month', NOW() - INTERVAL '1 month')
             AND date  < date_trunc('month', NOW())
           GROUP BY category
         )
         SELECT
           c.category,
           c.total AS current_total,
           COALESCE(p.total, 0) AS prev_total
         FROM curr c
         LEFT JOIN prev p ON c.category = p.category
         ORDER BY c.total DESC
         LIMIT 5`,
        [req.user.id],
      );

      const topCategories = catResult.rows.map(row => {
        const curr = parseFloat(row.current_total);
        const prev = parseFloat(row.prev_total);
        return {
          category: row.category,
          total: curr,
          vs_last_month_pct: pctChange(curr, prev),
        };
      });

      return res.json({
        current_month: {
          income: currentIncome,
          expenses: currentExpenses,
          balance: currentIncome - currentExpenses,
        },
        previous_month: {
          income: previousIncome,
          expenses: previousExpenses,
          balance: previousIncome - previousExpenses,
        },
        changes: {
          income_pct: pctChange(currentIncome, previousIncome),
          expenses_pct: pctChange(currentExpenses, previousExpenses),
          balance_pct: pctChange(
            currentIncome - currentExpenses,
            previousIncome - previousExpenses,
          ),
        },
        top_expense_categories: topCategories,
      });
    } catch (err) {
      console.error('[stats/trends] Error:', err.message);
      return res.status(500).json({ error: 'Internal server error' });
    }
  },
);

module.exports = router;