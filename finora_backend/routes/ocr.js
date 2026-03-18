const express = require('express');
const router = express.Router();
const { authenticateToken } = require('../middleware/auth');
const db = require('../services/db');

router.use(authenticateToken);

// ─── OCR / RECEIPT IMPORT ─────────────────────────────────────────────────────

// POST /ocr/extract  – receive text extracted by ML Kit on device, parse it
// Body: { raw_text: string, source: 'camera'|'gallery' }
router.post('/extract', async (req, res) => {
  const { raw_text } = req.body;
  if (!raw_text) return res.status(400).json({ error: 'raw_text required' });

  try {
    const text = raw_text;

    // Heuristic amount extraction: find largest numeric value with 2 decimal places
    const amountMatches = text.match(/\d{1,6}[.,]\d{2}/g) || [];
    const amounts = amountMatches
      .map(m => parseFloat(m.replace(',', '.')))
      .sort((a, b) => b - a);
    const amount = amounts[0] || null;

    // Date extraction: common date formats
    const dateMatch = text.match(
      /(\d{1,2})[\/\-.](\d{1,2})[\/\-.](\d{2,4})/
    );
    let extractedDate = null;
    if (dateMatch) {
      const [, day, month, year] = dateMatch;
      const fullYear = year.length === 2 ? `20${year}` : year;
      extractedDate = `${fullYear}-${month.padStart(2, '0')}-${day.padStart(2, '0')}`;
    }

    // Merchant extraction: first non-empty line after removing numbers/special chars
    const lines = text.split('\n').map(l => l.trim()).filter(Boolean);
    const merchantLine = lines.find(l =>
      l.length > 3 && !/^\d/.test(l) && !/^[€$£]/.test(l)
    );

    // Description: combine merchant hint with first few words
    const description = merchantLine
      ? merchantLine.substring(0, 50)
      : 'Imported receipt';

    res.json({
      amount,
      date: extractedDate || new Date().toISOString().split('T')[0],
      description,
      raw_lines: lines.slice(0, 5),
      confidence: amount ? 'high' : 'low',
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /ocr/import-receipt  – create transaction from extracted receipt data
// Body: { amount, date, description, category }
router.post('/import-receipt', async (req, res) => {
  const { amount, date, description, category = 'other' } = req.body;
  if (!amount || !description) {
    return res.status(400).json({ error: 'amount and description required' });
  }
  try {
    const { rows } = await db.query(
      `INSERT INTO transactions
         (user_id, amount, description, category, date, type, source)
       VALUES ($1, $2, $3, $4, $5, 'expense', 'ocr')
       RETURNING *`,
      [req.user.id, amount, description, category, date || new Date()]
    );
    res.status(201).json({ transaction: rows[0] });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─── CSV IMPORT ───────────────────────────────────────────────────────────────

// POST /ocr/parse-csv  – parse CSV content and return preview rows
// Body: { csv_content: string, header_map: { amount, date, description } }
router.post('/parse-csv', async (req, res) => {
  const { csv_content, header_map } = req.body;
  if (!csv_content) return res.status(400).json({ error: 'csv_content required' });

  try {
    const lines = csv_content.trim().split('\n');
    if (lines.length < 2) return res.status(400).json({ error: 'empty_csv' });

    const headers = lines[0].split(',').map(h => h.replace(/"/g, '').trim().toLowerCase());
    const map = header_map || {};

    // Auto-detect column indices
    const amountIdx = map.amount !== undefined ? map.amount
      : headers.findIndex(h => h.includes('amount') || h.includes('importe') || h.includes('valor'));
    const dateIdx = map.date !== undefined ? map.date
      : headers.findIndex(h => h.includes('date') || h.includes('fecha'));
    const descIdx = map.description !== undefined ? map.description
      : headers.findIndex(h => h.includes('desc') || h.includes('concepto') || h.includes('detail'));

    const rows = lines.slice(1).map((line, i) => {
      const cols = line.split(',').map(c => c.replace(/"/g, '').trim());
      const raw_amount = amountIdx >= 0 ? cols[amountIdx] : null;
      const amount = raw_amount ? parseFloat(raw_amount.replace(',', '.')) : null;
      return {
        index: i,
        date: dateIdx >= 0 ? cols[dateIdx] : null,
        description: descIdx >= 0 ? cols[descIdx] : line.substring(0, 40),
        amount: isNaN(amount) ? null : Math.abs(amount),
        raw: cols,
      };
    }).filter(r => r.amount !== null && r.amount > 0);

    res.json({
      headers,
      rows: rows.slice(0, 100), // preview up to 100
      total_rows: rows.length,
      column_mapping: { amount: amountIdx, date: dateIdx, description: descIdx },
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /ocr/import-csv  – batch import transactions from parsed CSV rows
// Body: { rows: [{ amount, date, description, category }], skip_duplicates: bool }
router.post('/import-csv', async (req, res) => {
  const { rows = [], skip_duplicates = true } = req.body;
  if (!rows.length) return res.status(400).json({ error: 'rows required' });

  let imported = 0;
  let skipped = 0;
  const errors = [];

  for (const row of rows) {
    try {
      if (skip_duplicates) {
        const dup = await db.query(
          `SELECT 1 FROM transactions
           WHERE user_id = $1 AND amount = $2 AND date::date = $3::date
             AND description = $4 LIMIT 1`,
          [req.user.id, row.amount, row.date, row.description]
        );
        if (dup.rows.length) { skipped++; continue; }
      }
      await db.query(
        `INSERT INTO transactions
           (user_id, amount, description, category, date, type, source)
         VALUES ($1, $2, $3, $4, $5, 'expense', 'csv_import')`,
        [
          req.user.id,
          row.amount,
          row.description || 'Imported',
          row.category || 'other',
          row.date || new Date(),
        ]
      );
      imported++;
    } catch (e) {
      errors.push({ row, error: e.message });
    }
  }

  res.json({ imported, skipped, errors: errors.slice(0, 10) });
});

module.exports = router;