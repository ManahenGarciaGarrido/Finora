const express = require('express');
const router = express.Router();
const { authenticateToken } = require('../middleware/auth');
const db = require('../services/db');

router.use(authenticateToken);

// Ensure fiscal_category column exists on running DB (migration may not have run)
db.query(`ALTER TABLE transactions ADD COLUMN IF NOT EXISTS fiscal_category VARCHAR(100)`).catch(() => {});

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

// GET /fiscal/all-transactions?year=2025  – list ALL transactions (optionally filtered by year)
// When year is omitted, returns ALL transactions so user can tag any expense as deductible.
router.get('/all-transactions', async (req, res) => {
  const year = req.query.year ? parseInt(req.query.year, 10) : null;
  try {
    const { rows } = year
      ? await db.query(
          `SELECT id, description, amount, date, category, fiscal_category
           FROM transactions
           WHERE user_id = $1
             AND EXTRACT(YEAR FROM date) = $2
           ORDER BY fiscal_category NULLS LAST, date DESC`,
          [req.user.id, year]
        )
      : await db.query(
          `SELECT id, description, amount, date, category, fiscal_category
           FROM transactions
           WHERE user_id = $1
           ORDER BY fiscal_category NULLS LAST, date DESC`,
          [req.user.id]
        );
    res.json({ transactions: rows, year: year || 'all' });
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

// GET /fiscal/export?year=2024&format=json|csv|xlsx  – export fiscal data
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
      res.setHeader('Content-Type', 'text/csv; charset=utf-8');
      res.setHeader('Content-Disposition', `attachment; filename="fiscal_${year}.csv"`);
      return res.send('\uFEFF' + lines.join('\n')); // BOM for Excel UTF-8 compatibility
    }

    if (format === 'xlsx') {
      const ExcelJS = require('exceljs');
      const workbook = new ExcelJS.Workbook();
      workbook.creator = 'Finora';
      workbook.created = new Date();
      workbook.modified = new Date();

      // ── Category totals ──────────────────────────────────────────────────
      const categoryTotals = {};
      let grandTotal = 0;
      rows.forEach(r => {
        const cat = r.fiscal_category || 'other';
        categoryTotals[cat] = (categoryTotals[cat] || 0) + parseFloat(r.amount);
        grandTotal += parseFloat(r.amount);
      });

      // ── Sheet 1: Resumen ─────────────────────────────────────────────────
      const summarySheet = workbook.addWorksheet('Resumen');
      summarySheet.columns = [
        { key: 'label', width: 36 },
        { key: 'value', width: 20 },
      ];

      const titleRow = summarySheet.addRow(['INFORME FISCAL FINORA', '']);
      titleRow.font = { bold: true, size: 16, color: { argb: 'FF6C63FF' } };
      titleRow.height = 28;

      summarySheet.addRow([`Ejercicio fiscal: ${year}`, '']);
      summarySheet.addRow([`Generado el: ${new Date().toLocaleDateString('es-ES')}`, '']);
      summarySheet.addRow([]);

      const headerRow = summarySheet.addRow(['CONCEPTO', 'IMPORTE (€)']);
      headerRow.font = { bold: true, color: { argb: 'FFFFFFFF' } };
      headerRow.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FF6C63FF' } };
      headerRow.alignment = { horizontal: 'center' };

      const catLabels = {
        freelance: 'Gasto deducible autónomo',
        donation: 'Donaciones',
        capital_gain: 'Rendimiento de capital',
        other: 'Otros deducibles',
      };
      Object.entries(categoryTotals).forEach(([cat, total]) => {
        const row = summarySheet.addRow([catLabels[cat] || cat, parseFloat(total).toFixed(2)]);
        row.getCell(2).alignment = { horizontal: 'right' };
        row.getCell(2).numFmt = '#,##0.00 €';
      });

      summarySheet.addRow([]);
      const totalRow = summarySheet.addRow(['TOTAL DEDUCIBLE', parseFloat(grandTotal).toFixed(2)]);
      totalRow.font = { bold: true };
      totalRow.getCell(2).font = { bold: true, color: { argb: 'FF388E3C' } };
      totalRow.getCell(2).numFmt = '#,##0.00 €';
      totalRow.getCell(2).alignment = { horizontal: 'right' };

      summarySheet.addRow([]);
      summarySheet.addRow(['* Datos exportados desde la app Finora', '']);
      summarySheet.addRow(['* Verifica con tu asesor fiscal antes de presentar', '']);

      // ── Sheet 2: Gastos deducibles ────────────────────────────────────────
      const txSheet = workbook.addWorksheet('Gastos Deducibles');
      txSheet.columns = [
        { header: 'Descripción', key: 'description', width: 40 },
        { header: 'Importe (€)', key: 'amount', width: 15 },
        { header: 'Fecha', key: 'date', width: 14 },
        { header: 'Categoría', key: 'category', width: 20 },
        { header: 'Tipo fiscal', key: 'fiscal_category', width: 28 },
      ];

      const txHeaderRow = txSheet.getRow(1);
      txHeaderRow.font = { bold: true, color: { argb: 'FFFFFFFF' } };
      txHeaderRow.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FF6C63FF' } };
      txHeaderRow.alignment = { horizontal: 'center' };
      txHeaderRow.height = 22;

      rows.forEach((r, i) => {
        const row = txSheet.addRow({
          description: r.description,
          amount: parseFloat(r.amount),
          date: new Date(r.date).toLocaleDateString('es-ES'),
          category: r.category,
          fiscal_category: catLabels[r.fiscal_category] || r.fiscal_category,
        });
        row.getCell('amount').numFmt = '#,##0.00 €';
        row.getCell('amount').font = { color: { argb: 'FF388E3C' } };
        row.getCell('amount').alignment = { horizontal: 'right' };
        if (i % 2 === 1) {
          row.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFF3F2FF' } };
        }
      });

      // Total row in tx sheet
      const txTotal = txSheet.addRow({
        description: 'TOTAL',
        amount: parseFloat(grandTotal),
        date: '',
        category: '',
        fiscal_category: '',
      });
      txTotal.font = { bold: true };
      txTotal.getCell('amount').numFmt = '#,##0.00 €';
      txTotal.getCell('amount').alignment = { horizontal: 'right' };
      txTotal.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFE8E6FF' } };

      // ── Sheet 3: Gráfico (category chart data) ───────────────────────────
      const chartSheet = workbook.addWorksheet('Gráfico Categorías');
      chartSheet.columns = [
        { header: 'Categoría', key: 'cat', width: 32 },
        { header: 'Total (€)', key: 'total', width: 18 },
      ];
      const chartHeaderRow = chartSheet.getRow(1);
      chartHeaderRow.font = { bold: true, color: { argb: 'FFFFFFFF' } };
      chartHeaderRow.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FF6C63FF' } };

      const catDataRows = [];
      Object.entries(categoryTotals).forEach(([cat, total]) => {
        const row = chartSheet.addRow({ cat: catLabels[cat] || cat, total: parseFloat(total) });
        row.getCell('total').numFmt = '#,##0.00 €';
        catDataRows.push(row.number);
      });

      // Add bar chart
      if (catDataRows.length > 0) {
        const firstDataRow = catDataRows[0];
        const lastDataRow = catDataRows[catDataRows.length - 1];
        chartSheet.addChart({
          type: 'bar',
          series: [
            {
              name: { formula: `'Gráfico Categorías'!$B$1` },
              labels: { formula: `'Gráfico Categorías'!$A$${firstDataRow}:$A$${lastDataRow}` },
              values: { formula: `'Gráfico Categorías'!$B$${firstDataRow}:$B$${lastDataRow}` },
            },
          ],
          title: { name: `Gastos deducibles por categoría — ${year}` },
          legend: { position: 'bottom' },
          plotArea: { bar: { barDir: 'col', grouping: 'clustered' } },
          tl: { col: 3, row: 1 },
          br: { col: 11, row: 18 },
        });
      }

      res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      res.setHeader('Content-Disposition', `attachment; filename="fiscal_${year}.xlsx"`);
      await workbook.xlsx.write(res);
      return res.end();
    }

    res.json({ transactions: rows, year, exported_at: new Date().toISOString() });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;