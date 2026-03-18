/**
 * Budget routes — RF-32
 *
 * RF-32: Alertas de exceso de presupuesto
 *  - Configuración de presupuesto mensual por categoría
 *  - Cálculo automático del porcentaje consumido
 *  - Alertas al superar 80% y 100% del presupuesto
 *  - Visualización de estado actual vs presupuesto
 *  - Histórico de cumplimiento
 *
 * Endpoints:
 *   GET    /budget                — lista de presupuestos del usuario
 *   POST   /budget                — crear/actualizar presupuesto de categoría
 *   DELETE /budget/:category      — eliminar presupuesto de categoría
 *   GET    /budget/status         — estado actual (% consumido) mes corriente
 *   GET    /budget/history        — histórico de cumplimiento mensual
 */

const express = require('express');
const router = express.Router();
const db = require('../services/db');
const { authenticateToken } = require('../middleware/auth');
const { body, param, validationResult } = require('express-validator');

// ─── GET /budget ──────────────────────────────────────────────────────────────
// Lista los presupuestos configurados por el usuario.

router.get('/', authenticateToken, async (req, res) => {
  try {
    const result = await db.query(
      `SELECT id, category, monthly_limit::float, rollover_enabled, created_at, updated_at
       FROM budgets
       WHERE user_id = $1
       ORDER BY category ASC`,
      [req.user.userId]
    );
    res.json({ budgets: result.rows });
  } catch (err) {
    console.error('budget/list error:', err);
    res.status(500).json({ error: 'Internal Server Error', message: err.message });
  }
});

// ─── GET /budget/status ───────────────────────────────────────────────────────
// RF-32: Estado actual de presupuestos en el mes en curso.
// Devuelve % consumido, alertas activas (>80%, >100%), sugerencias.

router.get('/status', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.userId;
    const now = new Date();
    const firstDay = new Date(now.getFullYear(), now.getMonth(), 1).toISOString().split('T')[0];
    const today = now.toISOString().split('T')[0];

    // Gasto real por categoría en el mes actual
    const spentResult = await db.query(
      `SELECT
         COALESCE(category, 'Sin categoría') AS category,
         SUM(amount)::float AS spent
       FROM transactions
       WHERE user_id = $1 AND type = 'expense' AND date >= $2 AND date <= $3
       GROUP BY category`,
      [userId, firstDay, today]
    );

    const spentMap = {};
    for (const row of spentResult.rows) {
      spentMap[row.category] = row.spent;
    }

    // Presupuestos configurados
    const budgetResult = await db.query(
      'SELECT id, category, monthly_limit::float FROM budgets WHERE user_id = $1',
      [userId]
    );

    const statuses = budgetResult.rows.map(b => {
      const spent = spentMap[b.category] || 0;
      const pct = b.monthly_limit > 0 ? (spent / b.monthly_limit) * 100 : 0;
      const remaining = Math.max(0, b.monthly_limit - spent);
      const overBudget = spent > b.monthly_limit;
      const nearLimit = pct >= 80 && !overBudget;

      return {
        category: b.category,
        monthly_limit: b.monthly_limit,
        spent: Math.round(spent * 100) / 100,
        remaining: Math.round(remaining * 100) / 100,
        percentage: Math.round(pct * 10) / 10,
        over_budget: overBudget,
        near_limit: nearLimit,
        alert_level: overBudget ? 'critical' : nearLimit ? 'warning' : 'ok',
      };
    });

    // Categorías con gasto pero sin presupuesto configurado
    const unbudgeted = Object.entries(spentMap)
      .filter(([cat]) => !budgetResult.rows.find(b => b.category === cat))
      .map(([category, spent]) => ({ category, spent }));

    res.json({
      period: { from: firstDay, to: today },
      statuses,
      unbudgeted,
      alerts: statuses.filter(s => s.alert_level !== 'ok'),
    });
  } catch (err) {
    console.error('budget/status error:', err);
    res.status(500).json({ error: 'Internal Server Error', message: err.message });
  }
});

// ─── GET /budget/history ──────────────────────────────────────────────────────
// Histórico de cumplimiento de presupuestos de los últimos 6 meses.

router.get('/history', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.userId;
    const months = parseInt(req.query.months) || 6;
    const cutoff = new Date();
    cutoff.setMonth(cutoff.getMonth() - months);
    const cutoffStr = cutoff.toISOString().split('T')[0];

    // Gasto por categoría + mes
    const result = await db.query(
      `SELECT
         TO_CHAR(date, 'YYYY-MM') AS period,
         COALESCE(category, 'Sin categoría') AS category,
         SUM(amount)::float AS spent
       FROM transactions
       WHERE user_id = $1 AND type = 'expense' AND date >= $2
       GROUP BY period, category
       ORDER BY period DESC, category ASC`,
      [userId, cutoffStr]
    );

    // Presupuestos actuales (los usamos como referencia histórica)
    const budgetResult = await db.query(
      'SELECT category, monthly_limit::float FROM budgets WHERE user_id = $1',
      [userId]
    );

    const budgetMap = {};
    for (const b of budgetResult.rows) {
      budgetMap[b.category] = b.monthly_limit;
    }

    // Unir datos
    const history = result.rows.map(row => ({
      period: row.period,
      category: row.category,
      spent: row.spent,
      limit: budgetMap[row.category] || null,
      percentage: budgetMap[row.category]
        ? Math.round((row.spent / budgetMap[row.category]) * 1000) / 10
        : null,
    }));

    res.json({ history });
  } catch (err) {
    console.error('budget/history error:', err);
    res.status(500).json({ error: 'Internal Server Error', message: err.message });
  }
});

// ─── POST /budget ─────────────────────────────────────────────────────────────
// RF-32: Crear o actualizar el presupuesto de una categoría.

router.post(
  '/',
  authenticateToken,
  [
    body('category').isString().trim().notEmpty().withMessage('category requerida'),
    body('monthly_limit').isFloat({ min: 0.01 }).withMessage('monthly_limit debe ser > 0'),
  ],
  async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(422).json({ error: 'Validation Error', details: errors.array() });
    }

    try {
      const userId = req.user.userId;
      const { category, monthly_limit } = req.body;

      // UPSERT por user + category
      const result = await db.query(
        `INSERT INTO budgets (user_id, category, monthly_limit)
         VALUES ($1, $2, $3)
         ON CONFLICT (user_id, category)
         DO UPDATE SET monthly_limit = $3, updated_at = NOW()
         RETURNING id, category, monthly_limit::float, rollover_enabled, created_at, updated_at`,
        [userId, category, monthly_limit]
      );

      res.status(201).json({ budget: result.rows[0] });
    } catch (err) {
      console.error('budget/create error:', err);
      res.status(500).json({ error: 'Internal Server Error', message: err.message });
    }
  }
);

// ─── DELETE /budget/:category ─────────────────────────────────────────────────
// Elimina el presupuesto de una categoría específica.

router.delete(
  '/:category',
  authenticateToken,
  async (req, res) => {
    try {
      const userId = req.user.userId;
      const category = decodeURIComponent(req.params.category);

      const result = await db.query(
        'DELETE FROM budgets WHERE user_id = $1 AND category = $2 RETURNING id',
        [userId, category]
      );

      if (result.rows.length === 0) {
        return res.status(404).json({ error: 'Not Found', message: 'Presupuesto no encontrado' });
      }

      res.json({ success: true });
    } catch (err) {
      console.error('budget/delete error:', err);
      res.status(500).json({ error: 'Internal Server Error', message: err.message });
    }
  }
);

// ─── GET /budget/suggest ──────────────────────────────────────────────────────
// AI budget suggestion based on average spending of last 3 months.

router.get('/suggest', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.userId;
    const cutoff = new Date();
    cutoff.setMonth(cutoff.getMonth() - 3);
    const cutoffStr = cutoff.toISOString().split('T')[0];

    const result = await db.query(
      `SELECT
         COALESCE(category, 'Sin categoría') AS category,
         AVG(monthly_spent)::float AS avg_monthly
       FROM (
         SELECT
           COALESCE(category, 'Sin categoría') AS category,
           TO_CHAR(date, 'YYYY-MM') AS month,
           SUM(amount)::float AS monthly_spent
         FROM transactions
         WHERE user_id = $1 AND type = 'expense' AND date >= $2
         GROUP BY category, month
       ) sub
       GROUP BY category
       ORDER BY avg_monthly DESC`,
      [userId, cutoffStr]
    );

    const suggestions = result.rows.map(r => ({
      category: r.category,
      suggested_limit: Math.ceil(r.avg_monthly * 1.1 / 10) * 10, // round up to nearest 10, add 10% buffer
      avg_monthly: Math.round(r.avg_monthly * 100) / 100,
    }));

    res.json({ suggestions, based_on_months: 3 });
  } catch (err) {
    console.error('budget/suggest error:', err);
    res.status(500).json({ error: 'Internal Server Error', message: err.message });
  }
});

// ─── PATCH /budget/:category/rollover ─────────────────────────────────────────
// Toggle rollover for a budget category.

router.patch(
  '/:category/rollover',
  authenticateToken,
  [body('rollover_enabled').isBoolean().withMessage('rollover_enabled must be boolean')],
  async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(422).json({ error: 'Validation Error', details: errors.array() });
    }
    try {
      const userId = req.user.userId;
      const category = decodeURIComponent(req.params.category);
      const { rollover_enabled } = req.body;

      const result = await db.query(
        `UPDATE budgets SET rollover_enabled = $1, updated_at = NOW()
         WHERE user_id = $2 AND category = $3
         RETURNING id, category, monthly_limit::float, rollover_enabled, updated_at`,
        [rollover_enabled, userId, category]
      );

      if (result.rows.length === 0) {
        return res.status(404).json({ error: 'Not Found', message: 'Budget not found' });
      }

      res.json({ budget: result.rows[0] });
    } catch (err) {
      console.error('budget/rollover error:', err);
      res.status(500).json({ error: 'Internal Server Error', message: err.message });
    }
  }
);

module.exports = router;