/**
 * Export routes — RF-34 + RF-35
 *
 * RF-34: Exportación de transacciones a CSV
 *  - Selector de rango de fechas y categorías
 *  - Columnas: Fecha, Descripción, Categoría, Cantidad, Tipo, Método de pago
 *  - Descarga directa con nombre de archivo timestamped
 *
 * RF-35: Generación de informes financieros en PDF
 *  - Resumen ejecutivo: ingresos, gastos, balance
 *  - Datos por categoría (pie) + evolución temporal (line)
 *  - Tabla detallada de transacciones
 *  - El frontend (Flutter + pdf package) renderiza el PDF a partir de estos datos
 *
 * Endpoints:
 *   GET /export/csv       — genera y devuelve CSV
 *   GET /export/pdf-data  — devuelve JSON estructurado para generar PDF en cliente
 *
 * Query param común: lang — 'es' (default) | 'en'
 */

const express = require('express');
const router = express.Router();
const ExcelJS = require('exceljs');
const db = require('../services/db');
const { authenticateToken } = require('../middleware/auth');
const { query, validationResult } = require('express-validator');

// ─── i18n strings ─────────────────────────────────────────────────────────────

const I18N = {
  es: {
    // Excel sheet names
    sheetSummary: 'Resumen',
    sheetCategories: 'Categorías',
    sheetTransactions: 'Transacciones',
    // Excel labels
    labelIncome: 'Ingresos totales',
    labelExpense: 'Gastos totales',
    labelBalance: 'Balance',
    labelPeriod: 'Período',
    labelTransactionCount: 'Nº transacciones',
    labelTop10Categories: 'Top 10 categorías de gasto',
    labelCategory: 'Categoría',
    labelAmount: 'Importe',
    labelCount: 'Transacciones',
    labelPct: '% del total',
    labelChartTitle: 'Gastos por categoría',
    labelDetailedTransactions: 'Transacciones del período',
    // Excel filename
    xlsxFilename: (date) => `finora_informe_${date}.xlsx`,
    // CSV headers
    headers: ['Fecha', 'Descripción', 'Categoría', 'Cantidad', 'Tipo', 'Método de pago'],
    // CSV type values
    expense: 'Gasto',
    income: 'Ingreso',
    // Fallback values
    noCategory: 'Sin categoría',
    noPaymentMethod: 'No especificado',
    // Filename
    filename: (date) => `finora_transacciones_${date}.csv`,
    // Month names (1-indexed)
    months: ['Enero','Febrero','Marzo','Abril','Mayo','Junio',
             'Julio','Agosto','Septiembre','Octubre','Noviembre','Diciembre'],
    // Period labels
    yearLabel: (year) => `Año ${year}`,
    customLabel: (from, to) => `${from} a ${to}`,
    // CSV delimiter (semicolon for Spanish Excel compatibility)
    delimiter: ';',
  },
  en: {
    // Excel sheet names
    sheetSummary: 'Summary',
    sheetCategories: 'Categories',
    sheetTransactions: 'Transactions',
    // Excel labels
    labelIncome: 'Total income',
    labelExpense: 'Total expenses',
    labelBalance: 'Balance',
    labelPeriod: 'Period',
    labelTransactionCount: 'No. transactions',
    labelTop10Categories: 'Top 10 expense categories',
    labelCategory: 'Category',
    labelAmount: 'Amount',
    labelCount: 'Transactions',
    labelPct: '% of total',
    labelChartTitle: 'Expenses by category',
    labelDetailedTransactions: 'Transactions for period',
    // Excel filename
    xlsxFilename: (date) => `finora_report_${date}.xlsx`,
    // CSV headers
    headers: ['Date', 'Description', 'Category', 'Amount', 'Type', 'Payment Method'],
    expense: 'Expense',
    income: 'Income',
    noCategory: 'No category',
    noPaymentMethod: 'Not specified',
    filename: (date) => `finora_transactions_${date}.csv`,
    months: ['January','February','March','April','May','June',
             'July','August','September','October','November','December'],
    yearLabel: (year) => `Year ${year}`,
    customLabel: (from, to) => `${from} to ${to}`,
    delimiter: ',',
  },
};

// ─── Helpers ─────────────────────────────────────────────────────────────────

/** Escapa un valor para CSV (RFC 4180). */
function csvEscape(value, delimiter) {
  if (value == null) return '';
  const str = String(value);
  if (str.includes(delimiter) || str.includes('"') || str.includes('\n')) {
    return `"${str.replace(/"/g, '""')}"`;
  }
  return str;
}

/** Formatea una fila CSV a partir de un array de valores. */
function csvRow(values, delimiter) {
  return values.map(v => csvEscape(v, delimiter)).join(delimiter);
}

// ─── GET /export/csv ──────────────────────────────────────────────────────────
// RF-34: Exporta transacciones del usuario a CSV con filtros opcionales.
// Query params:
//   from       — fecha inicio (YYYY-MM-DD), default: primer día del mes actual
//   to         — fecha fin   (YYYY-MM-DD), default: hoy
//   categories — categorías separadas por coma (all si omitido)
//   type       — 'income' | 'expense' | 'all' (default: 'all')
//   lang       — 'es' | 'en' (default: 'es')

router.get(
  '/csv',
  authenticateToken,
  [
    query('from').optional().isISO8601().withMessage('from must be YYYY-MM-DD'),
    query('to').optional().isISO8601().withMessage('to must be YYYY-MM-DD'),
    query('type').optional().isIn(['income', 'expense', 'all']),
    query('lang').optional().isIn(['es', 'en']),
  ],
  async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(422).json({ error: 'Validation Error', details: errors.array() });
    }

    try {
      const userId = req.user.userId;
      const now = new Date();
      const defaultFrom = new Date(now.getFullYear(), now.getMonth(), 1).toISOString().split('T')[0];
      const defaultTo = now.toISOString().split('T')[0];

      const from = req.query.from || defaultFrom;
      const to = req.query.to || defaultTo;
      const type = req.query.type || 'all';
      const lang = (req.query.lang || 'es').toLowerCase();
      const t = I18N[lang] || I18N.es;
      const categories = req.query.categories
        ? req.query.categories.split(',').map(c => c.trim()).filter(Boolean)
        : [];

      // Construir filtros dinámicos
      const params = [userId, from, to];
      let whereClauses = ['t.user_id = $1', 't.date >= $2', 't.date <= $3'];

      if (type !== 'all') {
        params.push(type);
        whereClauses.push(`t.type = $${params.length}`);
      }
      if (categories.length > 0) {
        params.push(categories);
        whereClauses.push(`t.category = ANY($${params.length})`);
      }

      const whereSQL = whereClauses.join(' AND ');

      const result = await db.query(
        `SELECT
           TO_CHAR(t.date, 'YYYY-MM-DD') AS fecha,
           t.description                  AS descripcion,
           t.category                     AS categoria,
           t.amount::float                AS cantidad,
           t.type                         AS tipo,
           t.payment_method               AS metodo_pago
         FROM transactions t
         WHERE ${whereSQL}
         ORDER BY t.date DESC, t.created_at DESC`,
        params
      );

      const rows = result.rows;
      const delim = t.delimiter;

      // Cabecera CSV
      const header = csvRow(t.headers, delim);
      const lines = [header];
      for (const row of rows) {
        // Cantidad: negativa para gastos en el CSV
        const amount = row.tipo === 'expense' ? -Math.abs(row.cantidad) : Math.abs(row.cantidad);
        lines.push(csvRow([
          row.fecha,
          row.descripcion,
          row.categoria || t.noCategory,
          amount.toFixed(2),
          row.tipo === 'expense' ? t.expense : t.income,
          row.metodo_pago || t.noPaymentMethod,
        ], delim));
      }

      const csvContent = lines.join('\r\n');
      const dateStr = new Date().toISOString().slice(0, 10).replace(/-/g, '');
      const filename = t.filename(dateStr);

      res.setHeader('Content-Type', 'text/csv; charset=utf-8');
      res.setHeader('Content-Disposition', `attachment; filename="${filename}"`);
      // BOM para compatibilidad con Excel
      res.send('\uFEFF' + csvContent);
    } catch (err) {
      console.error('export/csv error:', err);
      res.status(500).json({ error: 'Internal Server Error', message: err.message });
    }
  }
);

// ─── GET /export/pdf-data ─────────────────────────────────────────────────────
// RF-35: Devuelve los datos estructurados necesarios para que el cliente
//         (Flutter + pdf package) genere el informe financiero en PDF.
// Query params:
//   period — 'month' | 'year' | 'custom' (default: 'month')
//   year   — año (default: actual)
//   month  — mes 1-12 (default: actual, solo si period=month)
//   from   — fecha inicio (solo si period=custom)
//   to     — fecha fin   (solo si period=custom)
//   lang   — 'es' | 'en' (default: 'es')

router.get(
  '/pdf-data',
  authenticateToken,
  [
    query('period').optional().isIn(['month', 'year', 'custom']),
    query('year').optional().isInt({ min: 2000, max: 2100 }),
    query('month').optional().isInt({ min: 1, max: 12 }),
    query('lang').optional().isIn(['es', 'en']),
  ],
  async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(422).json({ error: 'Validation Error', details: errors.array() });
    }

    try {
      const userId = req.user.userId;
      const now = new Date();
      const period = req.query.period || 'month';
      const year = parseInt(req.query.year) || now.getFullYear();
      const month = parseInt(req.query.month) || now.getMonth() + 1;
      const lang = (req.query.lang || 'es').toLowerCase();
      const t = I18N[lang] || I18N.es;

      let from, to, periodLabel;

      if (period === 'month') {
        from = `${year}-${String(month).padStart(2, '0')}-01`;
        const lastDay = new Date(year, month, 0).getDate();
        to = `${year}-${String(month).padStart(2, '0')}-${lastDay}`;
        periodLabel = `${t.months[month - 1]} ${year}`;
      } else if (period === 'year') {
        from = `${year}-01-01`;
        to = `${year}-12-31`;
        periodLabel = t.yearLabel(year);
      } else {
        // custom
        from = req.query.from || `${year}-01-01`;
        to = req.query.to || now.toISOString().split('T')[0];
        periodLabel = t.customLabel(from, to);
      }

      // 1. Resumen ejecutivo (ingresos, gastos, balance)
      const summaryResult = await db.query(
        `SELECT
           SUM(CASE WHEN type = 'income'  THEN amount ELSE 0 END)::float AS total_ingresos,
           SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END)::float AS total_gastos,
           COUNT(*) AS num_transacciones
         FROM transactions
         WHERE user_id = $1 AND date >= $2 AND date <= $3`,
        [userId, from, to]
      );

      const summary = summaryResult.rows[0];
      const totalIngresos = summary.total_ingresos || 0;
      const totalGastos = summary.total_gastos || 0;

      // 2. Gastos por categoría (para gráfico de donut)
      const categoryResult = await db.query(
        `SELECT
           COALESCE(category, $4) AS categoria,
           SUM(amount)::float AS total,
           COUNT(*) AS transacciones
         FROM transactions
         WHERE user_id = $1 AND type = 'expense' AND date >= $2 AND date <= $3
         GROUP BY category
         ORDER BY total DESC
         LIMIT 10`,
        [userId, from, to, t.noCategory]
      );

      // 3. Evolución temporal (agrupado por semana o mes según el período)
      const groupBy = period === 'month' ? "TO_CHAR(date, 'YYYY-MM-DD')" : "TO_CHAR(date, 'YYYY-MM')";
      const evolutionResult = await db.query(
        `SELECT
           ${groupBy} AS periodo,
           SUM(CASE WHEN type = 'income'  THEN amount ELSE 0 END)::float AS ingresos,
           SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END)::float AS gastos
         FROM transactions
         WHERE user_id = $1 AND date >= $2 AND date <= $3
         GROUP BY ${groupBy}
         ORDER BY periodo ASC`,
        [userId, from, to]
      );

      // 4. Top 50 transacciones para tabla detallada
      const transactionsResult = await db.query(
        `SELECT
           TO_CHAR(date, 'YYYY-MM-DD') AS fecha,
           description AS descripcion,
           COALESCE(category, $4) AS categoria,
           amount::float AS cantidad,
           type AS tipo,
           COALESCE(payment_method, '') AS metodo_pago
         FROM transactions
         WHERE user_id = $1 AND date >= $2 AND date <= $3
         ORDER BY date DESC
         LIMIT 50`,
        [userId, from, to, t.noCategory]
      );

      // Obtener perfil del usuario para el informe
      const userResult = await db.query(
        'SELECT name, email FROM users WHERE id = $1',
        [userId]
      );

      // Traducir tipo en filas de transacciones
      const transacciones = transactionsResult.rows.map(row => ({
        ...row,
        tipo_label: row.tipo === 'expense' ? t.expense : t.income,
      }));

      res.json({
        metadata: {
          generated_at: new Date().toISOString(),
          period_label: periodLabel,
          from,
          to,
          lang,
          user_name: userResult.rows[0]?.name || 'Usuario',
        },
        summary: {
          total_ingresos: totalIngresos,
          total_gastos: totalGastos,
          balance: totalIngresos - totalGastos,
          num_transacciones: parseInt(summary.num_transacciones) || 0,
        },
        gastos_por_categoria: categoryResult.rows,
        evolucion_temporal: evolutionResult.rows,
        transacciones,
      });
    } catch (err) {
      console.error('export/pdf-data error:', err);
      res.status(500).json({ error: 'Internal Server Error', message: err.message });
    }
  }
);

// ─── GET /export/excel ────────────────────────────────────────────────────────
// Genera un .xlsx con tres hojas: Resumen, Categorías (con gráfico de barras)
// y Transacciones detalladas (filas coloreadas).
// Query params: period, year, month, from, to, lang (igual que /pdf-data)

router.get(
  '/excel',
  authenticateToken,
  [
    query('period').optional().isIn(['month', 'year', 'custom']),
    query('year').optional().isInt({ min: 2000, max: 2100 }),
    query('month').optional().isInt({ min: 1, max: 12 }),
    query('lang').optional().isIn(['es', 'en']),
  ],
  async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(422).json({ error: 'Validation Error', details: errors.array() });
    }

    try {
      const userId = req.user.userId;
      const now = new Date();
      const period = req.query.period || 'month';
      const year = parseInt(req.query.year) || now.getFullYear();
      const month = parseInt(req.query.month) || now.getMonth() + 1;
      const lang = (req.query.lang || 'es').toLowerCase();
      const t = I18N[lang] || I18N.es;

      // ── Calcular rango de fechas ──────────────────────────────────────────
      let from, to, periodLabel;
      if (period === 'month') {
        from = `${year}-${String(month).padStart(2, '0')}-01`;
        const lastDay = new Date(year, month, 0).getDate();
        to = `${year}-${String(month).padStart(2, '0')}-${lastDay}`;
        periodLabel = `${t.months[month - 1]} ${year}`;
      } else if (period === 'year') {
        from = `${year}-01-01`;
        to = `${year}-12-31`;
        periodLabel = t.yearLabel(year);
      } else {
        from = req.query.from || `${year}-01-01`;
        to = req.query.to || now.toISOString().split('T')[0];
        periodLabel = t.customLabel(from, to);
      }

      // ── Queries ───────────────────────────────────────────────────────────
      const [summaryResult, categoryResult, txResult] = await Promise.all([
        db.query(
          `SELECT
             SUM(CASE WHEN type='income'  THEN amount ELSE 0 END)::float AS total_ingresos,
             SUM(CASE WHEN type='expense' THEN amount ELSE 0 END)::float AS total_gastos,
             COUNT(*) AS num_transacciones
           FROM transactions WHERE user_id=$1 AND date>=$2 AND date<=$3`,
          [userId, from, to]
        ),
        db.query(
          `SELECT
             COALESCE(category, $4) AS categoria,
             SUM(amount)::float AS total,
             COUNT(*) AS transacciones
           FROM transactions
           WHERE user_id=$1 AND type='expense' AND date>=$2 AND date<=$3
           GROUP BY category ORDER BY total DESC LIMIT 10`,
          [userId, from, to, t.noCategory]
        ),
        db.query(
          `SELECT
             TO_CHAR(date,'YYYY-MM-DD') AS fecha,
             description AS descripcion,
             COALESCE(category,$4) AS categoria,
             amount::float AS cantidad,
             type AS tipo,
             COALESCE(payment_method,'') AS metodo_pago
           FROM transactions
           WHERE user_id=$1 AND date>=$2 AND date<=$3
           ORDER BY date DESC`,
          [userId, from, to, t.noCategory]
        ),
      ]);

      const sumRow = summaryResult.rows[0];
      const totalIngresos = sumRow.total_ingresos || 0;
      const totalGastos = sumRow.total_gastos || 0;
      const balance = totalIngresos - totalGastos;
      const categories = categoryResult.rows;
      const transactions = txResult.rows;

      // ── Colores de marca ──────────────────────────────────────────────────
      const PRIMARY   = '0F172A';
      const SUCCESS   = '059669';
      const DANGER    = 'DC2626';
      const WARNING   = 'D97706';
      const GRAY_BG   = 'F3F4F6';
      const GRAY_TEXT = '6B7280';
      const WHITE     = 'FFFFFF';
      const ACCENT    = '6366F1'; // indigo for bar fill

      const fmtNum = (v) => parseFloat(v.toFixed(2));

      // ── Workbook ──────────────────────────────────────────────────────────
      const wb = new ExcelJS.Workbook();
      wb.creator = 'Finora';
      wb.created = now;

      // ══════════════════════════════════════════════════════════════════════
      // HOJA 1 — RESUMEN
      // ══════════════════════════════════════════════════════════════════════
      const ws1 = wb.addWorksheet(t.sheetSummary);
      ws1.columns = [
        { width: 28 },
        { width: 20 },
      ];

      // Título
      ws1.mergeCells('A1:B1');
      const titleCell = ws1.getCell('A1');
      titleCell.value = 'FINORA';
      titleCell.font = { name: 'Calibri', bold: true, size: 18, color: { argb: `FF${PRIMARY}` } };
      titleCell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: `FF${GRAY_BG}` } };
      titleCell.alignment = { vertical: 'middle', horizontal: 'center' };
      ws1.getRow(1).height = 36;

      ws1.mergeCells('A2:B2');
      const subtitleCell = ws1.getCell('A2');
      subtitleCell.value = periodLabel;
      subtitleCell.font = { name: 'Calibri', size: 12, color: { argb: `FF${GRAY_TEXT}` } };
      subtitleCell.alignment = { vertical: 'middle', horizontal: 'center' };
      ws1.getRow(2).height = 22;

      ws1.getRow(3).height = 8; // spacer

      // Helper: add labeled metric row
      const addMetricRow = (rowNum, label, value, argbColor) => {
        const row = ws1.getRow(rowNum);
        row.height = 28;
        const lc = row.getCell(1);
        lc.value = label;
        lc.font = { name: 'Calibri', size: 11, color: { argb: `FF${PRIMARY}` } };
        lc.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: `FF${GRAY_BG}` } };
        lc.border = {
          top: { style: 'thin', color: { argb: 'FFE5E7EB' } },
          bottom: { style: 'thin', color: { argb: 'FFE5E7EB' } },
          left: { style: 'thin', color: { argb: 'FFE5E7EB' } },
        };
        lc.alignment = { vertical: 'middle', indent: 1 };

        const vc = row.getCell(2);
        vc.value = fmtNum(value);
        vc.numFmt = '#,##0.00';
        vc.font = { name: 'Calibri', bold: true, size: 13, color: { argb: argbColor } };
        vc.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: `FF${WHITE}` } };
        vc.border = {
          top: { style: 'thin', color: { argb: 'FFE5E7EB' } },
          bottom: { style: 'thin', color: { argb: 'FFE5E7EB' } },
          right: { style: 'thin', color: { argb: 'FFE5E7EB' } },
        };
        vc.alignment = { vertical: 'middle', horizontal: 'right', indent: 1 };
      };

      addMetricRow(4, t.labelPeriod, 0, `FF${PRIMARY}`);
      ws1.getCell('B4').value = periodLabel;
      ws1.getCell('B4').numFmt = '';
      ws1.getCell('B4').font = { name: 'Calibri', bold: true, size: 11, color: { argb: `FF${PRIMARY}` } };

      addMetricRow(5, t.labelIncome, totalIngresos, `FF${SUCCESS}`);
      addMetricRow(6, t.labelExpense, totalGastos, `FF${DANGER}`);
      addMetricRow(7, t.labelBalance, balance, balance >= 0 ? `FF${SUCCESS}` : `FF${DANGER}`);
      addMetricRow(8, t.labelTransactionCount, parseInt(sumRow.num_transacciones) || 0, `FF${PRIMARY}`);
      ws1.getCell('B8').numFmt = '0';

      // ══════════════════════════════════════════════════════════════════════
      // HOJA 2 — CATEGORÍAS (tabla + gráfico de barras nativo)
      // ══════════════════════════════════════════════════════════════════════
      const ws2 = wb.addWorksheet(t.sheetCategories);
      ws2.columns = [
        { width: 24 }, // Categoría
        { width: 16 }, // Importe
        { width: 14 }, // Nº transacciones
        { width: 12 }, // % del total
      ];

      // Cabecera de sección
      ws2.mergeCells('A1:D1');
      const catTitle = ws2.getCell('A1');
      catTitle.value = t.labelTop10Categories;
      catTitle.font = { name: 'Calibri', bold: true, size: 13, color: { argb: `FF${WHITE}` } };
      catTitle.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: `FF${PRIMARY}` } };
      catTitle.alignment = { vertical: 'middle', horizontal: 'center' };
      ws2.getRow(1).height = 26;

      // Encabezados de tabla
      const catHeaders = [t.labelCategory, t.labelAmount, t.labelCount, t.labelPct];
      const catHeaderRow = ws2.getRow(2);
      catHeaderRow.height = 22;
      catHeaders.forEach((h, i) => {
        const c = catHeaderRow.getCell(i + 1);
        c.value = h;
        c.font = { name: 'Calibri', bold: true, size: 10, color: { argb: `FF${WHITE}` } };
        c.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: `FF${ACCENT}` } };
        c.alignment = { vertical: 'middle', horizontal: i === 0 ? 'left' : 'right', indent: 1 };
        c.border = { bottom: { style: 'medium', color: { argb: 'FFE5E7EB' } } };
      });

      // Filas de datos
      categories.forEach((cat, idx) => {
        const rowNum = idx + 3;
        const row = ws2.getRow(rowNum);
        row.height = 20;
        const pct = totalGastos > 0 ? cat.total / totalGastos : 0;
        const isEven = idx % 2 === 0;
        const rowBg = isEven ? `FF${WHITE}` : `FFF9FAFB`;

        const vals = [cat.categoria, fmtNum(cat.total), parseInt(cat.transacciones), fmtNum(pct * 100)];
        const fmts = ['', '#,##0.00', '0', '0.0"%"'];
        vals.forEach((v, i) => {
          const c = row.getCell(i + 1);
          c.value = v;
          c.numFmt = fmts[i];
          c.font = { name: 'Calibri', size: 10, color: { argb: `FF${PRIMARY}` } };
          c.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: rowBg } };
          c.alignment = { vertical: 'middle', horizontal: i === 0 ? 'left' : 'right', indent: 1 };
          c.border = { bottom: { style: 'thin', color: { argb: 'FFE5E7EB' } } };
        });
      });



      // ══════════════════════════════════════════════════════════════════════
      // HOJA 3 — TRANSACCIONES
      // ══════════════════════════════════════════════════════════════════════
      const ws3 = wb.addWorksheet(t.sheetTransactions);
      ws3.columns = [
        { width: 13 }, // Fecha
        { width: 32 }, // Descripción
        { width: 18 }, // Categoría
        { width: 14 }, // Importe
        { width: 12 }, // Tipo
        { width: 18 }, // Método de pago
      ];

      // Título
      ws3.mergeCells('A1:F1');
      const txTitle = ws3.getCell('A1');
      txTitle.value = t.labelDetailedTransactions;
      txTitle.font = { name: 'Calibri', bold: true, size: 13, color: { argb: `FF${WHITE}` } };
      txTitle.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: `FF${PRIMARY}` } };
      txTitle.alignment = { vertical: 'middle', horizontal: 'center' };
      ws3.getRow(1).height = 26;

      // Encabezados
      const txHeaders = t.headers;
      const txHeaderRow = ws3.getRow(2);
      txHeaderRow.height = 22;
      txHeaders.forEach((h, i) => {
        const c = txHeaderRow.getCell(i + 1);
        c.value = h;
        c.font = { name: 'Calibri', bold: true, size: 10, color: { argb: `FF${WHITE}` } };
        c.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: `FF${ACCENT}` } };
        c.alignment = { vertical: 'middle', horizontal: i <= 1 ? 'left' : 'right', indent: 1 };
        c.border = { bottom: { style: 'medium', color: { argb: 'FFE5E7EB' } } };
      });

      // Filas de transacciones
      transactions.forEach((tx, idx) => {
        const isExp = tx.tipo === 'expense';
        const rowNum = idx + 3;
        const row = ws3.getRow(rowNum);
        row.height = 18;
        const isEven = idx % 2 === 0;
        const rowBg = isEven ? `FF${WHITE}` : `FFF9FAFB`;
        const amountColor = isExp ? `FF${DANGER}` : `FF${SUCCESS}`;
        const amount = isExp ? -Math.abs(tx.cantidad) : Math.abs(tx.cantidad);

        const vals = [
          tx.fecha,
          tx.descripcion,
          tx.categoria,
          fmtNum(amount),
          isExp ? t.expense : t.income,
          tx.metodo_pago || t.noPaymentMethod,
        ];
        const fmts = ['yyyy-mm-dd', '', '', '#,##0.00;[Red]-#,##0.00', '', ''];

        vals.forEach((v, i) => {
          const c = row.getCell(i + 1);
          c.value = v;
          c.numFmt = fmts[i];
          c.font = {
            name: 'Calibri',
            size: 9,
            color: { argb: i === 3 ? amountColor : `FF${PRIMARY}` },
            bold: i === 3,
          };
          c.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: rowBg } };
          c.alignment = {
            vertical: 'middle',
            horizontal: i >= 3 ? 'right' : 'left',
            indent: 1,
          };
          c.border = { bottom: { style: 'hair', color: { argb: 'FFE5E7EB' } } };
        });
      });

      // Auto-filter en encabezados
      ws3.autoFilter = {
        from: { row: 2, column: 1 },
        to: { row: 2, column: 6 },
      };

      // Freeze header rows
      ws3.views = [{ state: 'frozen', ySplit: 2 }];
      ws2.views = [{ state: 'frozen', ySplit: 2 }];

      // ── Enviar respuesta ──────────────────────────────────────────────────
      const dateStr = now.toISOString().slice(0, 10).replace(/-/g, '');
      const filename = t.xlsxFilename(dateStr);

      res.setHeader(
        'Content-Type',
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
      );
      res.setHeader('Content-Disposition', `attachment; filename="${filename}"`);

      const buffer = await wb.xlsx.writeBuffer();
      res.send(buffer);
    } catch (err) {
      console.error('export/excel error:', err);
      res.status(500).json({ error: 'Internal Server Error', message: err.message });
    }
  }
);

module.exports = router;
