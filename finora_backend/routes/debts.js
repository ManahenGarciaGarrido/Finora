/**
 * Debt & Loan routes
 *
 * Endpoints:
 *   GET    /debts                     - list user's debts
 *   POST   /debts                     - create debt
 *   PUT    /debts/:id                 - update debt
 *   DELETE /debts/:id                 - delete debt
 *   POST   /debts/calculate/loan      - loan calculator
 *   POST   /debts/calculate/mortgage  - mortgage calculator
 *   GET    /debts/strategies          - snowball vs avalanche comparison
 */

const express = require('express');
const router = express.Router();
const db = require('../services/db');
const { authenticateToken } = require('../middleware/auth');
const { body, param, validationResult } = require('express-validator');

// ─── GET /debts ───────────────────────────────────────────────────────────────

router.get('/', authenticateToken, async (req, res) => {
  try {
    const result = await db.query(
      `SELECT id, name, type, creditor_name, amount::float, remaining_amount::float,
              interest_rate::float, due_date, monthly_payment::float, notes, is_active,
              created_at, updated_at
       FROM debts
       WHERE user_id = $1 AND is_active = TRUE
       ORDER BY remaining_amount DESC`,
      [req.user.userId]
    );
    res.json({ debts: result.rows });
  } catch (err) {
    console.error('debts/list error:', err);
    res.status(500).json({ error: 'Internal Server Error', message: err.message });
  }
});

// ─── POST /debts/calculate/loan ───────────────────────────────────────────────

router.post('/calculate/loan', authenticateToken,
  [
    body('principal').isFloat({ min: 1 }),
    body('annual_rate').isFloat({ min: 0 }),
    body('months').isInt({ min: 1 }),
  ],
  async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(422).json({ error: 'Validation Error', details: errors.array() });
    }
    try {
      const { principal, annual_rate, months } = req.body;
      const r = annual_rate / 100 / 12;
      let monthly_payment;
      if (r === 0) {
        monthly_payment = principal / months;
      } else {
        monthly_payment = principal * r * Math.pow(1 + r, months) / (Math.pow(1 + r, months) - 1);
      }
      const total_payment = monthly_payment * months;
      const total_interest = total_payment - principal;
      res.json({
        monthly_payment: Math.round(monthly_payment * 100) / 100,
        total_interest: Math.round(total_interest * 100) / 100,
        total_payment: Math.round(total_payment * 100) / 100,
      });
    } catch (err) {
      res.status(500).json({ error: 'Internal Server Error', message: err.message });
    }
  }
);

// ─── POST /debts/calculate/mortgage ──────────────────────────────────────────

router.post('/calculate/mortgage', authenticateToken,
  [
    body('principal').isFloat({ min: 1 }),
    body('annual_rate').isFloat({ min: 0 }),
    body('months').isInt({ min: 1 }),
  ],
  async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(422).json({ error: 'Validation Error', details: errors.array() });
    }
    try {
      const { principal, annual_rate, months, early_payment = 0 } = req.body;
      const r = annual_rate / 100 / 12;
      let monthly_payment;
      if (r === 0) {
        monthly_payment = principal / months;
      } else {
        monthly_payment = principal * r * Math.pow(1 + r, months) / (Math.pow(1 + r, months) - 1);
      }
      const total_payment = monthly_payment * months;
      const total_interest = total_payment - principal;

      let savings_with_early = null;
      if (early_payment > 0) {
        // Simulate with extra payment
        let balance = principal;
        let totalPaidWithExtra = 0;
        let monthsWithExtra = 0;
        while (balance > 0 && monthsWithExtra < months * 2) {
          const interestCharge = balance * r;
          const principalPaid = Math.min(balance, monthly_payment - interestCharge + early_payment);
          balance -= principalPaid;
          totalPaidWithExtra += monthly_payment + early_payment;
          monthsWithExtra++;
          if (balance <= 0) break;
        }
        savings_with_early = Math.round((total_payment - totalPaidWithExtra) * 100) / 100;
      }

      res.json({
        monthly_payment: Math.round(monthly_payment * 100) / 100,
        total_interest: Math.round(total_interest * 100) / 100,
        total_payment: Math.round(total_payment * 100) / 100,
        ...(savings_with_early !== null ? { savings_with_early } : {}),
      });
    } catch (err) {
      res.status(500).json({ error: 'Internal Server Error', message: err.message });
    }
  }
);

// ─── GET /debts/strategies ────────────────────────────────────────────────────

router.get('/strategies', authenticateToken, async (req, res) => {
  try {
    const result = await db.query(
      `SELECT id, name, remaining_amount::float, interest_rate::float, monthly_payment::float
       FROM debts WHERE user_id = $1 AND is_active = TRUE AND type = 'own'`,
      [req.user.userId]
    );
    const debts = result.rows;
    if (debts.length === 0) {
      return res.json({ snowball: null, avalanche: null, message: 'No debts found' });
    }

    const simulate = (debtList) => {
      let remaining = debtList.map(d => ({ ...d, rem: d.remaining_amount }));
      let totalInterest = 0;
      let months = 0;
      const order = debtList.map(d => d.name);
      while (remaining.some(d => d.rem > 0) && months < 600) {
        months++;
        for (const d of remaining) {
          if (d.rem <= 0) continue;
          const interest = d.rem * (d.interest_rate / 100 / 12);
          totalInterest += interest;
          const payment = Math.min(d.rem + interest, d.monthly_payment || 100);
          d.rem = Math.max(0, d.rem + interest - payment);
        }
      }
      return { order, total_interest: Math.round(totalInterest * 100) / 100, months_to_payoff: months };
    };

    const snowballOrder = [...debts].sort((a, b) => a.remaining_amount - b.remaining_amount);
    const avalancheOrder = [...debts].sort((a, b) => b.interest_rate - a.interest_rate);

    res.json({
      snowball: simulate(snowballOrder),
      avalanche: simulate(avalancheOrder),
    });
  } catch (err) {
    console.error('debts/strategies error:', err);
    res.status(500).json({ error: 'Internal Server Error', message: err.message });
  }
});

// ─── POST /debts ──────────────────────────────────────────────────────────────

router.post('/', authenticateToken,
  [
    body('name').isString().trim().notEmpty(),
    body('type').isIn(['own', 'owed']),
    body('amount').isFloat({ min: 0.01 }),
    body('remaining_amount').isFloat({ min: 0 }),
  ],
  async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(422).json({ error: 'Validation Error', details: errors.array() });
    }
    try {
      const {
        name, type, creditor_name, amount, remaining_amount,
        interest_rate = 0, due_date, monthly_payment, notes,
      } = req.body;
      const result = await db.query(
        `INSERT INTO debts (user_id, name, type, creditor_name, amount, remaining_amount,
           interest_rate, due_date, monthly_payment, notes)
         VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)
         RETURNING id, name, type, creditor_name, amount::float, remaining_amount::float,
           interest_rate::float, due_date, monthly_payment::float, notes, is_active, created_at, updated_at`,
        [req.user.userId, name, type, creditor_name || null, amount, remaining_amount,
          interest_rate, due_date || null, monthly_payment || null, notes || null]
      );
      res.status(201).json({ debt: result.rows[0] });
    } catch (err) {
      console.error('debts/create error:', err);
      res.status(500).json({ error: 'Internal Server Error', message: err.message });
    }
  }
);

// ─── PUT /debts/:id ───────────────────────────────────────────────────────────

router.put('/:id', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    const {
      name, type, creditor_name, amount, remaining_amount,
      interest_rate, due_date, monthly_payment, notes,
    } = req.body;
    const result = await db.query(
      `UPDATE debts
       SET name = COALESCE($1, name),
           type = COALESCE($2, type),
           creditor_name = COALESCE($3, creditor_name),
           amount = COALESCE($4, amount),
           remaining_amount = COALESCE($5, remaining_amount),
           interest_rate = COALESCE($6, interest_rate),
           due_date = COALESCE($7, due_date),
           monthly_payment = COALESCE($8, monthly_payment),
           notes = COALESCE($9, notes),
           updated_at = NOW()
       WHERE id = $10 AND user_id = $11
       RETURNING id, name, type, creditor_name, amount::float, remaining_amount::float,
         interest_rate::float, due_date, monthly_payment::float, notes, is_active, created_at, updated_at`,
      [name, type, creditor_name, amount, remaining_amount,
       interest_rate, due_date, monthly_payment, notes, id, req.user.userId]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Not Found' });
    }
    res.json({ debt: result.rows[0] });
  } catch (err) {
    console.error('debts/update error:', err);
    res.status(500).json({ error: 'Internal Server Error', message: err.message });
  }
});

// ─── DELETE /debts/:id ────────────────────────────────────────────────────────

router.delete('/:id', authenticateToken, async (req, res) => {
  try {
    const result = await db.query(
      'UPDATE debts SET is_active = FALSE, updated_at = NOW() WHERE id = $1 AND user_id = $2 RETURNING id',
      [req.params.id, req.user.userId]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Not Found' });
    }
    res.json({ success: true });
  } catch (err) {
    console.error('debts/delete error:', err);
    res.status(500).json({ error: 'Internal Server Error', message: err.message });
  }
});

module.exports = router;