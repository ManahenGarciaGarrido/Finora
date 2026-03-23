const express = require('express');
const router = express.Router();
const { authenticateToken } = require('../middleware/auth');
const db = require('../services/db');
let pdfParse;
try { pdfParse = require('pdf-parse'); } catch (_) { pdfParse = null; }

router.use(authenticateToken);

// ─── OCR / RECEIPT IMPORT ─────────────────────────────────────────────────────

// POST /ocr/extract  – receive text extracted by ML Kit on device, parse it
// Body: { raw_text: string, source: 'camera'|'gallery' }
router.post('/extract', async (req, res) => {
  const { raw_text } = req.body;
  if (!raw_text) return res.status(400).json({ error: 'raw_text required' });

  try {
    const text = raw_text;
    const lines = text.split('\n').map(l => l.trim()).filter(Boolean);

    // Heuristic amount extraction: find TOTAL keyword first, then largest value
    let amount = null;
    const totalMatch = text.match(/(?:total|importe|a\s*pagar|amount)[^\d]*(\d{1,6}[.,]\d{2})/i);
    if (totalMatch) {
      amount = parseFloat(totalMatch[1].replace(',', '.'));
    } else {
      const amountMatches = text.match(/\d{1,6}[.,]\d{2}/g) || [];
      const amounts = amountMatches
        .map(m => parseFloat(m.replace(',', '.')))
        .sort((a, b) => b - a);
      amount = amounts[0] || null;
    }

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

    // Improved merchant extraction: skip address lines, find business name
    // Patterns to skip: street addresses, postal codes, city-only lines, phone numbers
    const addressPatterns = [
      /^c\//i,           // "C/ ..."
      /^calle/i,         // "Calle ..."
      /^av(da|enida)?\.?/i, // "Avda. / Avenida ..."
      /^p(las|zo|aseo)?\.?\s/i, // "Pza. / Paseo ..."
      /^\d{5}\s/,        // Postal code "28001 Madrid"
      /\d{9}/,           // Phone number
      /^nif|^cif|^nif:/i, // Tax ID lines
      /^tel[ée]?f?[oó]?n?[oó]?/i, // Telephone
      /^fax/i,
      /^\+\d{2}/,        // International phone
      /^www\./i,
      /@/,               // Email
      /^fecha/i,         // "Fecha: ..."
      /^hora/i,          // "Hora: ..."
      /^ticket|^recibo|^factura|^albar[aá]n/i,
    ];

    // Prefer lines from the first 5 that look like a business name
    const merchantCandidates = lines.slice(0, 8).filter(l => {
      if (l.length < 3 || l.length > 60) return false;
      if (/^\d/.test(l) && !/^[A-Z]/.test(l)) return false; // starts with digit but not capital
      if (/^[€$£]/.test(l)) return false;
      for (const pat of addressPatterns) {
        if (pat.test(l)) return false;
      }
      return true;
    });

    const merchantLine = merchantCandidates[0] || null;

    // AI categorization hint based on merchant keywords
    const merchantLower = (merchantLine || '').toLowerCase();
    let suggestedCategory = 'Otros';
    if (/mercadona|lidl|carrefour|aldi|eroski|dia|alcampo|hipercor|supermercado/.test(merchantLower)) {
      suggestedCategory = 'Alimentación';
    } else if (/restaurante|bar|cafeter[ií]a|pizz|hamburgues|mc\s*donald|burger|kfc|subway|pizza/.test(merchantLower)) {
      suggestedCategory = 'Restaurantes';
    } else if (/farmacia|pharmacy|parafarmacia/.test(merchantLower)) {
      suggestedCategory = 'Salud';
    } else if (/gasolinera|repsol|cepsa|bp|shell|galp|petrol/.test(merchantLower)) {
      suggestedCategory = 'Transporte';
    } else if (/zara|h&m|mango|primark|corte ingl[eé]s|decathlon|sport/.test(merchantLower)) {
      suggestedCategory = 'Ropa';
    } else if (/amazon|fnac|mediamarkt|pccomponentes|el corte ingl/.test(merchantLower)) {
      suggestedCategory = 'Tecnología';
    }

    const description = merchantLine
      ? merchantLine.substring(0, 50)
      : 'Ticket importado';

    res.json({
      amount,
      date: extractedDate || new Date().toISOString().split('T')[0],
      description,
      merchant: merchantLine,
      suggested_category: suggestedCategory,
      raw_lines: lines.slice(0, 8),
      confidence: amount ? 'high' : 'low',
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /ocr/import-receipt  – create transaction from extracted receipt data
// Body: { amount, date, description, category, payment_method }
router.post('/import-receipt', async (req, res) => {
  const { amount, date, description, category = 'Otros', payment_method = 'cash' } = req.body;
  if (!amount || !description) {
    return res.status(400).json({ error: 'amount and description required' });
  }
  try {
    const { rows } = await db.query(
      `INSERT INTO transactions
         (user_id, amount, description, category, date, type, payment_method)
       VALUES ($1, $2, $3, $4, $5, 'expense', $6)
       RETURNING *`,
      [req.user.userId, amount, description, category, date || new Date(), payment_method]
    );
    res.status(201).json({ transaction: rows[0] });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─── CSV IMPORT ───────────────────────────────────────────────────────────────

// POST /ocr/parse-csv  – parse CSV content and return preview rows
// Soporta formatos de bancos españoles (BBVA, Santander, CaixaBank, ING, etc.)
// Body: { csv_content: string, header_map?: { amount, date, description } }
router.post('/parse-csv', async (req, res) => {
  const { csv_content, header_map } = req.body;
  if (!csv_content) return res.status(400).json({ error: 'csv_content required' });

  try {
    const rawLines = csv_content.trim().split(/\r?\n/);

    // Detectar separador escaneando las primeras líneas con contenido
    // (no solo la primera, ya que muchos bancos empiezan con metadatos sin separador)
    let sep = ',';
    {
      let semis = 0, commas = 0, tabs = 0;
      for (const l of rawLines.slice(0, 15)) {
        semis  += (l.match(/;/g)  || []).length;
        commas += (l.match(/,/g)  || []).length;
        tabs   += (l.match(/\t/g) || []).length;
      }
      if (tabs > 4) sep = '\t';
      else if (semis > commas) sep = ';';
    }

    // Saltar líneas de cabecera que no son datos (ej: resúmenes, logos de banco)
    let dataStart = 0;
    for (let i = 0; i < Math.min(rawLines.length, 15); i++) {
      const cols = rawLines[i].split(sep);
      const lower = rawLines[i].toLowerCase();
      if (cols.length >= 3 && (
        lower.includes('fecha') || lower.includes('date') ||
        lower.includes('importe') || lower.includes('amount') ||
        lower.includes('concepto') || lower.includes('description') ||
        lower.includes('movimiento') || lower.includes('valor')
      )) {
        dataStart = i;
        break;
      }
    }

    const lines = rawLines.slice(dataStart);
    if (lines.length < 2) return res.status(400).json({ error: 'empty_csv' });

    const splitLine = (line) => {
      // Maneja campos con comillas que contienen el separador
      const result = [];
      let current = '';
      let inQuotes = false;
      for (let i = 0; i < line.length; i++) {
        const ch = line[i];
        if (ch === '"') {
          inQuotes = !inQuotes;
        } else if (ch === sep && !inQuotes) {
          result.push(current.trim());
          current = '';
        } else {
          current += ch;
        }
      }
      result.push(current.trim());
      return result;
    };

    const headers = splitLine(lines[0]).map(h => h.replace(/"/g, '').trim().toLowerCase());
    const map = header_map || {};

    // Detección automática de columnas para bancos españoles comunes
    const amountIdx = map.amount !== undefined ? map.amount
      : headers.findIndex(h =>
          h.includes('importe') || h.includes('amount') || h.includes('valor') ||
          h.includes('cargo') || h.includes('abono') || h.includes('saldo') && h !== 'saldo final' ||
          h === 'movimiento');
    const dateIdx = map.date !== undefined ? map.date
      : headers.findIndex(h =>
          h.includes('fecha') || h.includes('date') || h.includes('f.valor') || h === 'f. valor');
    const descIdx = map.description !== undefined ? map.description
      : headers.findIndex(h =>
          h.includes('concepto') || h.includes('descripci') || h.includes('detail') ||
          h.includes('desc') || h.includes('beneficiario') || h.includes('comercio'));

    // Detectar columna de tipo (cargo/abono) para bancos que separan ingresos/gastos
    const typeIdx = headers.findIndex(h => h === 'tipo' || h === 'cargo' || h === 'abono');

    const parseSpanishDate = (raw) => {
      if (!raw) return null;
      // dd/mm/yyyy, dd-mm-yyyy, dd.mm.yyyy, yyyy-mm-dd
      const m1 = raw.match(/^(\d{1,2})[\/\-.](\d{1,2})[\/\-.](\d{2,4})$/);
      if (m1) {
        const [, d, mo, y] = m1;
        const yr = y.length === 2 ? `20${y}` : y;
        return `${yr}-${mo.padStart(2, '0')}-${d.padStart(2, '0')}`;
      }
      const m2 = raw.match(/^(\d{4})[\/\-](\d{2})[\/\-](\d{2})$/);
      if (m2) return raw;
      return null;
    };

    const parseAmount = (raw) => {
      if (!raw) return null;
      let s = raw.trim().replace(/\s/g, '').replace(/[€$£+]/g, '');
      const hasDot   = s.includes('.');
      const hasComma = s.includes(',');
      if (hasDot && hasComma) {
        // Ambos presentes: el último es el separador decimal
        if (s.lastIndexOf(',') > s.lastIndexOf('.')) {
          s = s.replace(/\./g, '').replace(',', '.'); // Formato español: 1.234,56
        } else {
          s = s.replace(/,/g, ''); // Formato inglés: 1,234.56
        }
      } else if (hasComma) {
        s = s.replace(',', '.'); // Coma decimal: 50,00 → 50.00
      }
      // Solo puntos o ninguno: parseFloat lo maneja bien (50.00 → 50.00)
      const val = parseFloat(s);
      return isNaN(val) ? null : val;
    };

    const rows = lines.slice(1).map((line, i) => {
      const cols = splitLine(line);
      if (cols.length < 2) return null;
      const rawAmount = amountIdx >= 0 ? cols[amountIdx] : null;
      const amount = parseAmount(rawAmount);
      const type = amount !== null && amount < 0 ? 'expense' : 'income';
      return {
        index: i,
        date: parseSpanishDate(dateIdx >= 0 ? cols[dateIdx] : null),
        description: descIdx >= 0 ? cols[descIdx]?.substring(0, 80) : line.substring(0, 40),
        amount: amount !== null ? Math.abs(amount) : null,
        type,
        raw: cols,
      };
    }).filter(r => r !== null && r.amount !== null && r.amount > 0);

    res.json({
      headers,
      rows: rows.slice(0, 200),
      total_rows: rows.length,
      column_mapping: { amount: amountIdx, date: dateIdx, description: descIdx },
      separator: sep,
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
          [req.user.userId, row.amount, row.date, row.description]
        );
        if (dup.rows.length) { skipped++; continue; }
      }
      const txType = row.type === 'income' ? 'income' : 'expense';
      const txCategory = row.category || (txType === 'income' ? 'Otros ingresos' : 'Otros');
      await db.query(
        `INSERT INTO transactions
           (user_id, amount, description, category, date, type, payment_method)
         VALUES ($1, $2, $3, $4, $5, $6, 'bank_transfer')`,
        [
          req.user.userId,
          row.amount,
          row.description || 'Importado',
          txCategory,
          row.date || new Date(),
          txType,
        ]
      );
      imported++;
    } catch (e) {
      errors.push({ row, error: e.message });
    }
  }

  res.json({ imported, skipped, errors: errors.slice(0, 10) });
});

// POST /ocr/parse-pdf  – extract transactions from a PDF bank statement
// Body: { pdf_base64: string }
router.post('/parse-pdf', async (req, res) => {
  const { pdf_base64 } = req.body;
  if (!pdf_base64) return res.status(400).json({ error: 'pdf_base64 required' });
  if (!pdfParse) return res.status(503).json({ error: 'pdf-parse not installed. Run npm install.' });

  try {
    const buffer = Buffer.from(pdf_base64, 'base64');
    const data = await pdfParse(buffer);
    const text = data.text || '';

    const rawLines = text.split(/\r?\n/).map(l => l.trim()).filter(Boolean);

    // Detect if any line has a date pattern + amount pattern → likely a bank statement table
    const datePattern = /\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4}/;
    const amountPattern = /[-+]?\d{1,6}[.,]\d{2}/;

    const parseSpanishDate = (raw) => {
      if (!raw) return null;
      const m1 = raw.match(/^(\d{1,2})[\/\-.](\d{1,2})[\/\-.](\d{2,4})$/);
      if (m1) {
        const [, d, mo, y] = m1;
        const yr = y.length === 2 ? `20${y}` : y;
        return `${yr}-${mo.padStart(2, '0')}-${d.padStart(2, '0')}`;
      }
      const m2 = raw.match(/^(\d{4})[\/\-](\d{2})[\/\-](\d{2})$/);
      if (m2) return raw;
      return null;
    };

    const parseAmount = (raw) => {
      if (!raw) return null;
      let s = raw.trim().replace(/\s/g, '').replace(/[€$£+]/g, '');
      const hasDot   = s.includes('.');
      const hasComma = s.includes(',');
      if (hasDot && hasComma) {
        if (s.lastIndexOf(',') > s.lastIndexOf('.')) {
          s = s.replace(/\./g, '').replace(',', '.');
        } else {
          s = s.replace(/,/g, '');
        }
      } else if (hasComma) {
        s = s.replace(',', '.');
      }
      const val = parseFloat(s);
      return isNaN(val) ? null : val;
    };

    const rows = [];
    let idx = 0;

    for (const line of rawLines) {
      // Find date token in line
      const dateMatch = line.match(/(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4})/);
      // Find all amount tokens in line
      const amountMatches = [...line.matchAll(/([-+]?\d{1,6}[.,]\d{2})/g)];
      if (!dateMatch || amountMatches.length === 0) continue;

      const date = parseSpanishDate(dateMatch[1]);
      if (!date) continue;

      // Use the last amount match (usually the transaction amount, not balance)
      const rawAmt = amountMatches[amountMatches.length - 1][1];
      const amount = parseAmount(rawAmt);
      if (amount === null || Math.abs(amount) === 0) continue;

      // Build description: remove date and amount tokens from line, take what remains
      let desc = line
        .replace(dateMatch[0], '')
        .replace(new RegExp(amountMatches.map(m => m[1].replace(/[.+\-]/g, '\\$&')).join('|'), 'g'), '')
        .replace(/\s+/g, ' ')
        .trim()
        .substring(0, 80);

      if (!desc) desc = 'Movimiento importado';

      rows.push({
        index: idx++,
        date,
        description: desc,
        amount: Math.abs(amount),
        type: amount < 0 ? 'expense' : 'income',
        raw: [line],
      });
    }

    res.json({
      headers: ['fecha', 'concepto', 'importe'],
      rows: rows.slice(0, 200),
      total_rows: rows.length,
      column_mapping: { date: 0, description: 1, amount: 2 },
      separator: 'pdf',
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;