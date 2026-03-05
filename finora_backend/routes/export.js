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
 */

const express = require('express');
const router = express.Router();
const db = require('../services/db');
const { authenticateToken } = require('../middleware/auth');
const { query, validationResult } = require('express-validator');

// ─── Helpers ─────────────────────────────────────────────────────────────────

/** Escapa un valor para CSV (RFC 4180). */
function csvEscape(value) {
  if (value == null) return '';
  const str = String(value);
  if (str.includes(',') || str.includes('"') || str.includes('\n')) {
    return `"${str.replace(/"/g, '""')}"`;
  }
  return str;
}

/** Formatea una fila CSV a partir de un array de valores. */
function csvRow(values) {
  return values.map(csvEscape).join(',');
}

// ─── GET /export/csv ──────────────────────────────────────────────────────────
// RF-34: Exporta transacciones del usuario a CSV con filtros opcionales.
// Query params:
//   from       — fecha inicio (YYYY-MM-DD), default: primer día del mes actual
//   to         — fecha fin   (YYYY-MM-DD), default: hoy
//   categories — categorías separadas por coma (all si omitido)
//   type       — 'income' | 'expense' | 'all' (default: 'all')

router.get(
  '/csv',
  authenticateToken,
  [
    query('from').optional().isISO8601().withMessage('from must be YYYY-MM-DD'),
    query('to').optional().isISO8601().withMessage('to must be YYYY-MM-DD'),
    query('type').optional().isIn(['income', 'expense', 'all']),
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
           COALESCE(t.category, 'Sin categoría') AS categoria,
           t.amount::float                AS cantidad,
           t.type                         AS tipo,
           COALESCE(t.payment_method, 'No especificado') AS metodo_pago
         FROM transactions t
         WHERE ${whereSQL}
         ORDER BY t.date DESC, t.created_at DESC`,
        params
      );

      const rows = result.rows;

      // Cabecera CSV
      const header = csvRow(['Fecha', 'Descripción', 'Categoría', 'Cantidad', 'Tipo', 'Método de pago']);
      const lines = [header];
      for (const row of rows) {
        // Cantidad: negativa para gastos en el CSV
        const amount = row.tipo === 'expense' ? -Math.abs(row.cantidad) : Math.abs(row.cantidad);
        lines.push(csvRow([
          row.fecha,
          row.descripcion,
          row.categoria,
          amount.toFixed(2),
          row.tipo === 'expense' ? 'Gasto' : 'Ingreso',
          row.metodo_pago,
        ]));
      }

      const csvContent = lines.join('\r\n');
      const dateStr = new Date().toISOString().slice(0, 10).replace(/-/g, '');
      const filename = `finora_transacciones_${dateStr}.csv`;

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

router.get(
  '/pdf-data',
  authenticateToken,
  [
    query('period').optional().isIn(['month', 'year', 'custom']),
    query('year').optional().isInt({ min: 2000, max: 2100 }),
    query('month').optional().isInt({ min: 1, max: 12 }),
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

      let from, to, periodLabel;

      if (period === 'month') {
        from = `${year}-${String(month).padStart(2, '0')}-01`;
        const lastDay = new Date(year, month, 0).getDate();
        to = `${year}-${String(month).padStart(2, '0')}-${lastDay}`;
        const monthNames = ['Enero','Febrero','Marzo','Abril','Mayo','Junio',
                            'Julio','Agosto','Septiembre','Octubre','Noviembre','Diciembre'];
        periodLabel = `${monthNames[month - 1]} ${year}`;
      } else if (period === 'year') {
        from = `${year}-01-01`;
        to = `${year}-12-31`;
        periodLabel = `Año ${year}`;
      } else {
        // custom
        from = req.query.from || `${year}-01-01`;
        to = req.query.to || now.toISOString().split('T')[0];
        periodLabel = `${from} a ${to}`;
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
           COALESCE(category, 'Sin categoría') AS categoria,
           SUM(amount)::float AS total,
           COUNT(*) AS transacciones
         FROM transactions
         WHERE user_id = $1 AND type = 'expense' AND date >= $2 AND date <= $3
         GROUP BY category
         ORDER BY total DESC
         LIMIT 10`,
        [userId, from, to]
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

      // 4. Top 20 transacciones para tabla detallada
      const transactionsResult = await db.query(
        `SELECT
           TO_CHAR(date, 'YYYY-MM-DD') AS fecha,
           description AS descripcion,
           COALESCE(category, 'Sin categoría') AS categoria,
           amount::float AS cantidad,
           type AS tipo,
           COALESCE(payment_method, '') AS metodo_pago
         FROM transactions
         WHERE user_id = $1 AND date >= $2 AND date <= $3
         ORDER BY date DESC
         LIMIT 50`,
        [userId, from, to]
      );

      // Obtener perfil del usuario para el informe
      const userResult = await db.query(
        'SELECT name, email FROM users WHERE id = $1',
        [userId]
      );

      res.json({
        metadata: {
          generated_at: new Date().toISOString(),
          period_label: periodLabel,
          from,
          to,
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
        transacciones: transactionsResult.rows,
      });
    } catch (err) {
      console.error('export/pdf-data error:', err);
      res.status(500).json({ error: 'Internal Server Error', message: err.message });
    }
  }
);

module.exports = router;