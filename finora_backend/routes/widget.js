const express = require('express');
const router = express.Router();
const { authenticateToken } = require('../middleware/auth');
const db = require('../services/db');

router.use(authenticateToken);

// ─── WIDGET DATA ENDPOINT ─────────────────────────────────────────────────────

// GET /widget/data  – compact summary for home screen widget and wearable
// Returns: balance, today_spent, budget_pct, active_goal, health_score
router.get('/data', async (req, res) => {
  try {
    const now = new Date();
    const today = now.toISOString().split('T')[0];
    const firstOfMonth = new Date(now.getFullYear(), now.getMonth(), 1)
      .toISOString().split('T')[0];

    // Account balance (sum of income - expenses)
    const balanceResult = await db.query(
      `SELECT
         COALESCE(SUM(CASE WHEN type = 'income' THEN amount ELSE -amount END), 0) AS balance
       FROM transactions WHERE user_id = $1`,
      [req.user.id]
    );

    // Today's spending
    const todayResult = await db.query(
      `SELECT COALESCE(SUM(amount), 0) AS today_spent
       FROM transactions
       WHERE user_id = $1 AND type = 'expense' AND date::date = $2::date`,
      [req.user.id, today]
    );

    // Budget adherence this month
    const budgetResult = await db.query(
      `SELECT
         COALESCE(SUM(b.amount), 0) AS total_budget,
         COALESCE(SUM(tx_sum.spent), 0) AS total_spent
       FROM budgets b
       LEFT JOIN (
         SELECT category, SUM(amount) AS spent
         FROM transactions
         WHERE user_id = $1 AND type = 'expense' AND date >= $2
         GROUP BY category
       ) tx_sum ON tx_sum.category = b.category
       WHERE b.user_id = $1`,
      [req.user.id, firstOfMonth]
    );
    const totalBudget = parseFloat(budgetResult.rows[0].total_budget);
    const totalSpent = parseFloat(budgetResult.rows[0].total_spent);
    const budgetPct = totalBudget > 0
      ? Math.min(Math.round((totalSpent / totalBudget) * 100), 100)
      : 0;

    // Active goal (first by progress)
    const goalResult = await db.query(
      `SELECT name, current_amount, target_amount
       FROM goals
       WHERE user_id = $1 AND status = 'active'
       ORDER BY current_amount / NULLIF(target_amount, 0) DESC
       LIMIT 1`,
      [req.user.id]
    );
    const activeGoal = goalResult.rows.length ? {
      name: goalResult.rows[0].name,
      current: parseFloat(goalResult.rows[0].current_amount),
      target: parseFloat(goalResult.rows[0].target_amount),
      pct: goalResult.rows[0].target_amount > 0
        ? Math.round(goalResult.rows[0].current_amount / goalResult.rows[0].target_amount * 100)
        : 0,
    } : null;

    res.json({
      balance: parseFloat(balanceResult.rows[0].balance),
      today_spent: parseFloat(todayResult.rows[0].today_spent),
      budget_pct: budgetPct,
      active_goal: activeGoal,
      updated_at: now.toISOString(),
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET /widget/settings  – get user widget preferences
router.get('/settings', async (req, res) => {
  try {
    const { rows } = await db.query(
      `SELECT widget_settings FROM users WHERE id = $1`,
      [req.user.id]
    );
    const settings = rows[0]?.widget_settings || {
      show_balance: true,
      show_today_spent: true,
      show_budget_pct: true,
      dark_mode: 'auto',
    };
    res.json({ settings });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// PATCH /widget/settings  – update widget preferences
router.patch('/settings', async (req, res) => {
  const { settings } = req.body;
  if (!settings) return res.status(400).json({ error: 'settings required' });
  try {
    await db.query(
      `UPDATE users SET widget_settings = $1 WHERE id = $2`,
      [JSON.stringify(settings), req.user.id]
    );
    res.json({ settings });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;