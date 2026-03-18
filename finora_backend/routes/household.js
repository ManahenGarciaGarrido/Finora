/**
 * Household / Shared Finances routes
 *
 * Endpoints:
 *   GET    /household                     - get user's household
 *   POST   /household                     - create household
 *   DELETE /household                     - delete household (owner only)
 *   POST   /household/invite              - invite member by email
 *   DELETE /household/members/:userId     - remove member
 *   GET    /household/members             - list members
 *   POST   /household/transactions        - create shared transaction
 *   GET    /household/transactions        - list shared transactions
 *   GET    /household/balances            - calculate internal balances
 *   POST   /household/settle              - mark balance as settled
 */

const express = require('express');
const router = express.Router();
const db = require('../services/db');
const { authenticateToken } = require('../middleware/auth');
const { body, validationResult } = require('express-validator');
const crypto = require('crypto');

// Helper: get household for user
async function getUserHousehold(userId) {
  const result = await db.query(
    `SELECT h.id, h.name, h.owner_id, h.invite_code, h.created_at
     FROM households h
     JOIN household_members hm ON hm.household_id = h.id
     WHERE hm.user_id = $1`,
    [userId]
  );
  return result.rows[0] || null;
}

// ─── GET /household ────────────────────────────────────────────────────────────

router.get('/', authenticateToken, async (req, res) => {
  try {
    const household = await getUserHousehold(req.user.userId);
    res.json({ household });
  } catch (err) {
    console.error('household/get error:', err);
    res.status(500).json({ error: 'Internal Server Error', message: err.message });
  }
});

// ─── POST /household ───────────────────────────────────────────────────────────

router.post('/', authenticateToken,
  [body('name').isString().trim().notEmpty()],
  async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(422).json({ error: 'Validation Error', details: errors.array() });
    }
    try {
      const userId = req.user.userId;
      const { name } = req.body;
      const inviteCode = crypto.randomBytes(5).toString('hex').toUpperCase();

      const hResult = await db.query(
        `INSERT INTO households (name, owner_id, invite_code)
         VALUES ($1, $2, $3) RETURNING id, name, owner_id, invite_code, created_at`,
        [name, userId, inviteCode]
      );
      const household = hResult.rows[0];

      // Add owner as member
      await db.query(
        `INSERT INTO household_members (household_id, user_id, role)
         VALUES ($1, $2, 'owner')`,
        [household.id, userId]
      );

      res.status(201).json({ household });
    } catch (err) {
      console.error('household/create error:', err);
      res.status(500).json({ error: 'Internal Server Error', message: err.message });
    }
  }
);

// ─── DELETE /household ────────────────────────────────────────────────────────

router.delete('/', authenticateToken, async (req, res) => {
  try {
    const result = await db.query(
      'DELETE FROM households WHERE owner_id = $1 RETURNING id',
      [req.user.userId]
    );
    if (result.rows.length === 0) {
      return res.status(403).json({ error: 'Forbidden', message: 'Only the owner can delete the household' });
    }
    res.json({ success: true });
  } catch (err) {
    console.error('household/delete error:', err);
    res.status(500).json({ error: 'Internal Server Error', message: err.message });
  }
});

// ─── POST /household/invite ───────────────────────────────────────────────────

router.post('/invite', authenticateToken,
  [body('email').isEmail()],
  async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(422).json({ error: 'Validation Error', details: errors.array() });
    }
    try {
      const household = await getUserHousehold(req.user.userId);
      if (!household) {
        return res.status(404).json({ error: 'Not Found', message: 'No household found' });
      }

      const userResult = await db.query(
        'SELECT id FROM users WHERE email = $1',
        [req.body.email]
      );
      if (userResult.rows.length === 0) {
        return res.status(404).json({ error: 'Not Found', message: 'User not found' });
      }
      const invitedUserId = userResult.rows[0].id;

      await db.query(
        `INSERT INTO household_members (household_id, user_id, role)
         VALUES ($1, $2, 'member') ON CONFLICT (household_id, user_id) DO NOTHING`,
        [household.id, invitedUserId]
      );

      res.json({ success: true, message: 'Member invited' });
    } catch (err) {
      console.error('household/invite error:', err);
      res.status(500).json({ error: 'Internal Server Error', message: err.message });
    }
  }
);

// ─── GET /household/members ───────────────────────────────────────────────────

router.get('/members', authenticateToken, async (req, res) => {
  try {
    const household = await getUserHousehold(req.user.userId);
    if (!household) {
      return res.status(404).json({ error: 'Not Found' });
    }
    const result = await db.query(
      `SELECT hm.id, hm.user_id, hm.role, hm.joined_at,
              u.name, u.email
       FROM household_members hm
       JOIN users u ON u.id = hm.user_id
       WHERE hm.household_id = $1
       ORDER BY hm.joined_at ASC`,
      [household.id]
    );
    res.json({ members: result.rows });
  } catch (err) {
    console.error('household/members error:', err);
    res.status(500).json({ error: 'Internal Server Error', message: err.message });
  }
});

// ─── DELETE /household/members/:userId ───────────────────────────────────────

router.delete('/members/:userId', authenticateToken, async (req, res) => {
  try {
    const household = await getUserHousehold(req.user.userId);
    if (!household || household.owner_id !== req.user.userId) {
      return res.status(403).json({ error: 'Forbidden' });
    }
    await db.query(
      'DELETE FROM household_members WHERE household_id = $1 AND user_id = $2',
      [household.id, req.params.userId]
    );
    res.json({ success: true });
  } catch (err) {
    console.error('household/remove-member error:', err);
    res.status(500).json({ error: 'Internal Server Error', message: err.message });
  }
});

// ─── POST /household/transactions ─────────────────────────────────────────────

router.post('/transactions', authenticateToken,
  [
    body('amount').isFloat({ min: 0.01 }),
    body('description').isString().trim().notEmpty(),
    body('splits').isArray({ min: 1 }),
  ],
  async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(422).json({ error: 'Validation Error', details: errors.array() });
    }
    try {
      const household = await getUserHousehold(req.user.userId);
      if (!household) {
        return res.status(404).json({ error: 'Not Found' });
      }
      const { amount, description, transaction_id, splits } = req.body;

      const txResult = await db.query(
        `INSERT INTO shared_transactions
           (household_id, transaction_id, created_by, amount, description)
         VALUES ($1, $2, $3, $4, $5)
         RETURNING id`,
        [household.id, transaction_id || null, req.user.userId, amount, description]
      );
      const stId = txResult.rows[0].id;

      for (const split of splits) {
        const splitAmount = (amount * split.percentage) / 100;
        await db.query(
          `INSERT INTO transaction_splits (shared_transaction_id, user_id, percentage, amount)
           VALUES ($1, $2, $3, $4)`,
          [stId, split.user_id, split.percentage, splitAmount]
        );
      }

      res.status(201).json({ success: true, id: stId });
    } catch (err) {
      console.error('household/create-tx error:', err);
      res.status(500).json({ error: 'Internal Server Error', message: err.message });
    }
  }
);

// ─── GET /household/transactions ──────────────────────────────────────────────

router.get('/transactions', authenticateToken, async (req, res) => {
  try {
    const household = await getUserHousehold(req.user.userId);
    if (!household) {
      return res.status(404).json({ error: 'Not Found' });
    }
    const result = await db.query(
      `SELECT st.id, st.amount::float, st.description, st.created_at,
              u.name AS created_by_name,
              json_agg(json_build_object(
                'user_id', ts.user_id,
                'percentage', ts.percentage::float,
                'amount', ts.amount::float,
                'is_settled', ts.is_settled
              )) AS splits
       FROM shared_transactions st
       JOIN users u ON u.id = st.created_by
       LEFT JOIN transaction_splits ts ON ts.shared_transaction_id = st.id
       WHERE st.household_id = $1
       GROUP BY st.id, u.name
       ORDER BY st.created_at DESC`,
      [household.id]
    );
    res.json({ transactions: result.rows });
  } catch (err) {
    console.error('household/transactions error:', err);
    res.status(500).json({ error: 'Internal Server Error', message: err.message });
  }
});

// ─── GET /household/balances ──────────────────────────────────────────────────

router.get('/balances', authenticateToken, async (req, res) => {
  try {
    const household = await getUserHousehold(req.user.userId);
    if (!household) {
      return res.status(404).json({ error: 'Not Found' });
    }
    // Calculate who owes whom
    const result = await db.query(
      `SELECT
         st.created_by AS payer_id,
         ts.user_id AS ower_id,
         SUM(ts.amount)::float AS amount
       FROM shared_transactions st
       JOIN transaction_splits ts ON ts.shared_transaction_id = st.id
       WHERE st.household_id = $1
         AND ts.is_settled = FALSE
         AND ts.user_id != st.created_by
       GROUP BY st.created_by, ts.user_id`,
      [household.id]
    );
    res.json({ balances: result.rows });
  } catch (err) {
    console.error('household/balances error:', err);
    res.status(500).json({ error: 'Internal Server Error', message: err.message });
  }
});

// ─── POST /household/settle ───────────────────────────────────────────────────

router.post('/settle', authenticateToken,
  [body('with_user_id').isUUID()],
  async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(422).json({ error: 'Validation Error', details: errors.array() });
    }
    try {
      const household = await getUserHousehold(req.user.userId);
      if (!household) {
        return res.status(404).json({ error: 'Not Found' });
      }
      await db.query(
        `UPDATE transaction_splits ts
         SET is_settled = TRUE
         FROM shared_transactions st
         WHERE ts.shared_transaction_id = st.id
           AND st.household_id = $1
           AND (
             (ts.user_id = $2 AND st.created_by = $3)
             OR (ts.user_id = $3 AND st.created_by = $2)
           )`,
        [household.id, req.body.with_user_id, req.user.userId]
      );
      res.json({ success: true });
    } catch (err) {
      console.error('household/settle error:', err);
      res.status(500).json({ error: 'Internal Server Error', message: err.message });
    }
  }
);

module.exports = router;