const express = require('express');
const router = express.Router();
const { authenticateToken } = require('../middleware/auth');
const db = require('../services/db');

router.use(authenticateToken);

// ─── DEDUCTIBLE EXPENSES ──────────────────────────────────────────────────────

// GET /fiscal/deductible?year=2024  – list transactions tagged as fiscal
router.get('/deductible', async (req, res) => {
  const year = req.query.year || new Date().getFullYear();
  try {
    const { rows } = await db.query(
      `SELECT id, description, amount, date, category, fiscal_category
       FROM transactions
       WHERE user_id = $1
         AND fiscal_category IS NOT NULL
         AND EXTRACT(YEAR FROM date) = $2
       ORDER BY date DESC`,
      [req.user.id, year]
    );
    const total = rows.reduce((sum, r) => sum + parseFloat(r.amount), 0);
    res.json({ transactions: rows, total, year });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// PATCH /fiscal/tag/:transactionId  – tag or untag a transaction as fiscal
router.patch('/tag/:transactionId', async (req, res) => {
  const { fiscal_category } = req.body;
  try {
    const { rows } = await db.query(
      `UPDATE transactions
       SET fiscal_category = $1
       WHERE id = $2 AND user_id = $3
       RETURNING id, description, amount, fiscal_category`,
      [fiscal_category || null, req.params.transactionId, req.user.id]
    );
    if (!rows.length) return res.status(404).json({ error: 'not found' });
    res.json({ transaction: rows[0] });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─── IRPF ESTIMATOR ───────────────────────────────────────────────────────────

// POST /fiscal/irpf  – estimate IRPF tax
// Body: { annual_income, extra_deductions, autonomous_community }
router.post('/irpf', async (req, res) => {
  try {
    const { annual_income = 0, extra_deductions = 0 } = req.body;

    // Fetch total deductible expenses for current year automatically
    const year = new Date().getFullYear();
    const deductibles = await db.query(
      `SELECT COALESCE(SUM(amount), 0) as total
       FROM transactions
       WHERE user_id = $1 AND fiscal_category IS NOT NULL
         AND EXTRACT(YEAR FROM date) = $2`,
      [req.user.id, year]
    );
    const deductibleTotal = parseFloat(deductibles.rows[0].total) + parseFloat(extra_deductions);

    const base = Math.max(0, parseFloat(annual_income) - deductibleTotal);

    // Spanish IRPF 2024 brackets (state + autonomous average)
    const brackets = [
      { from: 0, to: 12450, rate: 0.19 },
      { from: 12450, to: 20200, rate: 0.24 },
      { from: 20200, to: 35200, rate: 0.30 },
      { from: 35200, to: 60000, rate: 0.37 },
      { from: 60000, to: 300000, rate: 0.45 },
      { from: 300000, to: Infinity, rate: 0.47 },
    ];

    let tax = 0;
    const bracketBreakdown = [];
    let remaining = base;

    for (const b of brackets) {
      if (remaining <= 0) break;
      const taxable = Math.min(remaining, b.to - b.from);
      const bracketTax = taxable * b.rate;
      bracketBreakdown.push({
        from: b.from,
        to: b.to === Infinity ? null : b.to,
        rate: b.rate,
        taxable_amount: taxable,
        tax: bracketTax,
      });
      tax += bracketTax;
      remaining -= taxable;
    }

    const netIncome = parseFloat(annual_income) - tax;
    const effectiveRate = parseFloat(annual_income) > 0
      ? (tax / parseFloat(annual_income)) * 100
      : 0;

    res.json({
      annual_income: parseFloat(annual_income),
      deductible_total: deductibleTotal,
      taxable_base: base,
      estimated_tax: tax,
      net_income: netIncome,
      effective_rate: effectiveRate,
      brackets: bracketBreakdown,
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─── TAX CALENDAR ─────────────────────────────────────────────────────────────

// GET /fiscal/calendar  – return upcoming Spanish tax deadlines
router.get('/calendar', async (req, res) => {
  const year = parseInt(req.query.year || new Date().getFullYear(), 10);
  const events = [
    { date: `${year}-01-30`, title: 'Modelo 130 – Q4 prev. year', type: 'quarterly' },
    { date: `${year}-04-20`, title: 'Modelo 130 – Q1', type: 'quarterly' },
    { date: `${year}-04-06`, title: 'Campaña IRPF abre', type: 'annual' },
    { date: `${year}-06-27`, title: 'Último día para domiciliar IRPF', type: 'annual' },
    { date: `${year}-07-01`, title: 'Modelo 130 – Q2', type: 'quarterly' },
    { date: `${year}-07-31`, title: 'Fin campaña IRPF', type: 'annual' },
    { date: `${year}-10-20`, title: 'Modelo 130 – Q3', type: 'quarterly' },
    { date: `${year}-12-31`, title: 'Fin ejercicio fiscal', type: 'annual' },
  ];
  res.json({ events, year });
});

// ─── EXPORT ───────────────────────────────────────────────────────────────────

// GET /fiscal/export?year=2024&format=json  – export fiscal data
router.get('/export', async (req, res) => {
  const year = req.query.year || new Date().getFullYear();
  const format = req.query.format || 'json';
  try {
    const { rows } = await db.query(
      `SELECT id, description, amount, date, category, fiscal_category
       FROM transactions
       WHERE user_id = $1
         AND fiscal_category IS NOT NULL
         AND EXTRACT(YEAR FROM date) = $2
       ORDER BY date`,
      [req.user.id, year]
    );

    if (format === 'csv') {
      const lines = ['id,description,amount,date,category,fiscal_category'];
      rows.forEach(r => {
        lines.push(
          `"${r.id}","${r.description}",${r.amount},"${r.date}","${r.category}","${r.fiscal_category}"`
        );
      });
      res.setHeader('Content-Type', 'text/csv');
      res.setHeader('Content-Disposition', `attachment; filename="fiscal_${year}.csv"`);
      return res.send(lines.join('\n'));
    }

    res.json({ transactions: rows, year, exported_at: new Date().toISOString() });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;