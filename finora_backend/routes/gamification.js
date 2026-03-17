const express = require('express');
const router = express.Router();
const { authenticateToken } = require('../middleware/auth');
const db = require('../services/db');

// Apply auth to all routes
router.use(authenticateToken);

// ─── STREAKS ─────────────────────────────────────────────────────────────────

// GET /gamification/streaks  – return user's current streaks
router.get('/streaks', async (req, res) => {
  try {
    const { rows } = await db.query(
      `SELECT * FROM user_streaks WHERE user_id = $1 ORDER BY streak_type`,
      [req.user.id]
    );
    res.json({ streaks: rows });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /gamification/streaks/record  – record activity for streak type
router.post('/streaks/record', async (req, res) => {
  const { streak_type } = req.body;
  if (!streak_type) return res.status(400).json({ error: 'streak_type required' });
  try {
    const today = new Date().toISOString().split('T')[0];
    const existing = await db.query(
      `SELECT * FROM user_streaks WHERE user_id = $1 AND streak_type = $2`,
      [req.user.id, streak_type]
    );
    if (existing.rows.length === 0) {
      await db.query(
        `INSERT INTO user_streaks (user_id, streak_type, current_count, longest_count, last_activity_date)
         VALUES ($1, $2, 1, 1, $3)`,
        [req.user.id, streak_type, today]
      );
    } else {
      const s = existing.rows[0];
      const last = s.last_activity_date ? new Date(s.last_activity_date) : null;
      const lastStr = last ? last.toISOString().split('T')[0] : null;
      if (lastStr === today) {
        return res.json({ streak: s, message: 'already_recorded' });
      }
      const yesterday = new Date();
      yesterday.setDate(yesterday.getDate() - 1);
      const yesterdayStr = yesterday.toISOString().split('T')[0];
      const isConsecutive = lastStr === yesterdayStr;
      const newCount = isConsecutive ? s.current_count + 1 : 1;
      const newLongest = Math.max(s.longest_count, newCount);
      await db.query(
        `UPDATE user_streaks
         SET current_count = $1, longest_count = $2, last_activity_date = $3
         WHERE user_id = $4 AND streak_type = $5`,
        [newCount, newLongest, today, req.user.id, streak_type]
      );
    }
    const updated = await db.query(
      `SELECT * FROM user_streaks WHERE user_id = $1 AND streak_type = $2`,
      [req.user.id, streak_type]
    );
    res.json({ streak: updated.rows[0] });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─── BADGES ──────────────────────────────────────────────────────────────────

// GET /gamification/badges  – all badges + earned status
router.get('/badges', async (req, res) => {
  try {
    const { rows } = await db.query(
      `SELECT b.*,
              ub.earned_at,
              CASE WHEN ub.user_id IS NOT NULL THEN true ELSE false END AS is_earned
       FROM badges b
       LEFT JOIN user_badges ub ON ub.badge_id = b.id AND ub.user_id = $1
       ORDER BY b.category, b.sort_order`,
      [req.user.id]
    );
    res.json({ badges: rows });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /gamification/badges/check  – auto-check and award eligible badges
router.post('/badges/check', async (req, res) => {
  try {
    // Count transactions
    const txCount = await db.query(
      `SELECT COUNT(*) FROM transactions WHERE user_id = $1`,
      [req.user.id]
    );
    // Count goals
    const goalCount = await db.query(
      `SELECT COUNT(*) FROM goals WHERE user_id = $1 AND status = 'completed'`,
      [req.user.id]
    );
    // Streak
    const streakRow = await db.query(
      `SELECT MAX(current_count) as max_streak FROM user_streaks WHERE user_id = $1`,
      [req.user.id]
    );

    const txNum = parseInt(txCount.rows[0].count, 10);
    const goalNum = parseInt(goalCount.rows[0].count, 10);
    const maxStreak = parseInt(streakRow.rows[0].max_streak || '0', 10);

    // Define badge award conditions: { badge_key, condition }
    const conditions = [
      { key: 'first_transaction', met: txNum >= 1 },
      { key: 'ten_transactions', met: txNum >= 10 },
      { key: 'fifty_transactions', met: txNum >= 50 },
      { key: 'first_goal_completed', met: goalNum >= 1 },
      { key: 'three_goals_completed', met: goalNum >= 3 },
      { key: 'streak_7', met: maxStreak >= 7 },
      { key: 'streak_30', met: maxStreak >= 30 },
    ];

    const awarded = [];
    for (const c of conditions) {
      if (!c.met) continue;
      const badge = await db.query(`SELECT id FROM badges WHERE badge_key = $1`, [c.key]);
      if (!badge.rows.length) continue;
      const badgeId = badge.rows[0].id;
      const already = await db.query(
        `SELECT 1 FROM user_badges WHERE user_id = $1 AND badge_id = $2`,
        [req.user.id, badgeId]
      );
      if (!already.rows.length) {
        await db.query(
          `INSERT INTO user_badges (user_id, badge_id, earned_at) VALUES ($1, $2, NOW())`,
          [req.user.id, badgeId]
        );
        awarded.push(c.key);
      }
    }
    res.json({ awarded });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─── CHALLENGES ──────────────────────────────────────────────────────────────

// GET /gamification/challenges  – list active challenges + user participation
router.get('/challenges', async (req, res) => {
  try {
    const { rows } = await db.query(
      `SELECT c.*,
              uc.progress,
              uc.is_completed,
              uc.joined_at,
              CASE WHEN uc.user_id IS NOT NULL THEN true ELSE false END AS is_joined
       FROM challenges c
       LEFT JOIN user_challenges uc ON uc.challenge_id = c.id AND uc.user_id = $1
       WHERE c.is_active = true
       ORDER BY c.ends_at`,
      [req.user.id]
    );
    res.json({ challenges: rows });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /gamification/challenges/:id/join  – join a challenge
router.post('/challenges/:id/join', async (req, res) => {
  try {
    const existing = await db.query(
      `SELECT 1 FROM user_challenges WHERE user_id = $1 AND challenge_id = $2`,
      [req.user.id, req.params.id]
    );
    if (existing.rows.length) {
      return res.status(409).json({ error: 'already_joined' });
    }
    await db.query(
      `INSERT INTO user_challenges (user_id, challenge_id, progress, is_completed, joined_at)
       VALUES ($1, $2, 0, false, NOW())`,
      [req.user.id, req.params.id]
    );
    res.json({ message: 'joined' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// PATCH /gamification/challenges/:id/progress  – update challenge progress
router.patch('/challenges/:id/progress', async (req, res) => {
  const { progress } = req.body;
  if (progress === undefined) return res.status(400).json({ error: 'progress required' });
  try {
    const challenge = await db.query(`SELECT * FROM challenges WHERE id = $1`, [req.params.id]);
    if (!challenge.rows.length) return res.status(404).json({ error: 'not found' });
    const target = challenge.rows[0].target_value;
    const isCompleted = progress >= target;
    await db.query(
      `UPDATE user_challenges SET progress = $1, is_completed = $2
       WHERE user_id = $3 AND challenge_id = $4`,
      [progress, isCompleted, req.user.id, req.params.id]
    );
    res.json({ progress, is_completed: isCompleted });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─── HEALTH SCORE ─────────────────────────────────────────────────────────────

// GET /gamification/health-score  – compute financial health score 0-100
router.get('/health-score', async (req, res) => {
  try {
    const now = new Date();
    const firstOfMonth = new Date(now.getFullYear(), now.getMonth(), 1).toISOString();

    // Budget adherence: ratio of budgets not exceeded this month
    const budgets = await db.query(
      `SELECT b.amount as limit_amount,
              COALESCE(SUM(t.amount), 0) as spent
       FROM budgets b
       LEFT JOIN transactions t ON t.user_id = b.user_id
         AND t.category = b.category
         AND t.type = 'expense'
         AND t.date >= $2
       WHERE b.user_id = $1
       GROUP BY b.amount`,
      [req.user.id, firstOfMonth]
    );
    const budgetScore = budgets.rows.length === 0 ? 50 :
      (budgets.rows.filter(r => parseFloat(r.spent) <= parseFloat(r.limit_amount)).length
        / budgets.rows.length) * 100;

    // Savings rate: income vs expenses this month
    const savingsData = await db.query(
      `SELECT type, COALESCE(SUM(amount), 0) as total
       FROM transactions
       WHERE user_id = $1 AND date >= $2
       GROUP BY type`,
      [req.user.id, firstOfMonth]
    );
    let income = 0, expenses = 0;
    savingsData.rows.forEach(r => {
      if (r.type === 'income') income = parseFloat(r.total);
      if (r.type === 'expense') expenses = parseFloat(r.total);
    });
    const savingsRate = income > 0 ? Math.min(((income - expenses) / income) * 100, 100) : 0;
    const savingsScore = Math.max(0, savingsRate);

    // Goal progress: avg completion of active goals
    const goals = await db.query(
      `SELECT COALESCE(AVG(LEAST(current_amount / NULLIF(target_amount, 0) * 100, 100)), 50) as avg_progress
       FROM goals WHERE user_id = $1 AND status != 'completed'`,
      [req.user.id]
    );
    const goalScore = parseFloat(goals.rows[0].avg_progress || 50);

    // Streak bonus: max streak / 30 days * 20 pts bonus
    const streak = await db.query(
      `SELECT COALESCE(MAX(current_count), 0) as max FROM user_streaks WHERE user_id = $1`,
      [req.user.id]
    );
    const streakBonus = Math.min((parseInt(streak.rows[0].max, 10) / 30) * 20, 20);

    // Weighted final score
    const score = Math.round(
      budgetScore * 0.35 +
      savingsScore * 0.35 +
      goalScore * 0.20 +
      streakBonus * 0.10
    );

    const breakdown = {
      budget_adherence: Math.round(budgetScore),
      savings_rate: Math.round(savingsScore),
      goal_progress: Math.round(goalScore),
      streak_bonus: Math.round(streakBonus),
    };

    let grade = 'D';
    if (score >= 90) grade = 'A+';
    else if (score >= 80) grade = 'A';
    else if (score >= 70) grade = 'B';
    else if (score >= 60) grade = 'C';

    res.json({ score, grade, breakdown });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;