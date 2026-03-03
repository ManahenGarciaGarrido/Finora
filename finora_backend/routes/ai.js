/**
 * RF-22 / HU-09: Predicción de gastos con ML
 * RF-21 / HU-08: Recomendaciones de ahorro inteligente
 *
 * Rutas del backend que obtienen las transacciones del usuario desde la BD
 * y las envían al microservicio Python (finora-ai) para el análisis ML.
 *
 * Endpoints:
 *   POST /api/v1/ai/predict-expenses       → RF-22: Predicción ML de gastos
 *   POST /api/v1/ai/savings                → RF-21: Recomendaciones de ahorro
 *   POST /api/v1/ai/evaluate-savings-goal  → RF-21: Evaluar viabilidad de objetivo
 */

const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const db = require('../services/db');

const AI_SERVICE_URL = process.env.AI_SERVICE_URL || 'http://localhost:5001';
const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-change-in-production';

// ── Autenticación ─────────────────────────────────────────────────────────────
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Unauthorized' });
  }
  const token = authHeader.substring(7);
  try {
    req.user = jwt.verify(token, JWT_SECRET);
    next();
  } catch {
    return res.status(403).json({ error: 'Invalid or expired token' });
  }
};

// ── Helper: llamada al servicio AI con timeout ────────────────────────────────
async function callAiService(endpoint, body, timeoutMs = 30000) {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);
  try {
    const response = await fetch(`${AI_SERVICE_URL}${endpoint}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
      signal: controller.signal,
    });
    clearTimeout(timer);
    if (!response.ok) {
      const text = await response.text();
      throw new Error(`AI service returned ${response.status}: ${text}`);
    }
    return await response.json();
  } catch (err) {
    clearTimeout(timer);
    throw err;
  }
}

// ── Helper: obtener transacciones del usuario ────────────────────────────────
async function getUserTransactions(userId, months = 12) {
  const cutoff = new Date();
  cutoff.setMonth(cutoff.getMonth() - months);

  const result = await db.query(
    `SELECT
       t.id,
       t.amount::float              AS amount,
       t.type,
       COALESCE(t.category, 'Otros') AS category,
       t.description,
       TO_CHAR(t.date, 'YYYY-MM-DD') AS date
     FROM transactions t
     WHERE t.user_id = $1
       AND t.date   >= $2
     ORDER BY t.date ASC`,
    [userId, cutoff.toISOString().split('T')[0]]
  );
  return result.rows;
}

// ── Helper: obtener ingresos promedio del usuario ─────────────────────────────
async function getMonthlyIncomeAverage(userId, months = 3) {
  const cutoff = new Date();
  cutoff.setMonth(cutoff.getMonth() - months);

  const result = await db.query(
    `SELECT COALESCE(AVG(monthly_income), 0)::float AS avg_income
     FROM (
       SELECT DATE_TRUNC('month', date) AS month,
              SUM(amount) AS monthly_income
       FROM transactions
       WHERE user_id = $1
         AND type    = 'income'
         AND date   >= $2
       GROUP BY 1
     ) sub`,
    [userId, cutoff.toISOString().split('T')[0]]
  );
  return result.rows[0]?.avg_income || 0;
}


// ── POST /api/v1/ai/predict-expenses ─────────────────────────────────────────
/**
 * RF-22 / HU-09: Predicción de gastos del próximo mes.
 *
 * Obtiene hasta 12 meses de transacciones y llama al servicio AI.
 * El servicio selecciona Ridge/RandomForest/GradientBoosting según el volumen.
 *
 * Query params:
 *   ?months=12  (meses de histórico a considerar, máx 24)
 *
 * Returns: {
 *   predictions: [{ categoria, prediccion, pred_min, pred_max, modelo, tendencia }],
 *   total_predicted, total_pred_min, total_pred_max,
 *   trend, last_month_total, months_of_data
 * }
 */
router.post('/predict-expenses', authenticateToken, async (req, res) => {
  try {
    const months = Math.min(parseInt(req.query.months || '12', 10), 24);
    const transactions = await getUserTransactions(req.user.userId, months);

    if (transactions.length === 0) {
      return res.json({
        predictions: [],
        total_predicted: 0,
        total_pred_min: 0,
        total_pred_max: 0,
        trend: 'stable',
        last_month_total: 0,
        months_of_data: 0,
        message: 'No hay suficientes transacciones para predecir.',
      });
    }

    const aiResult = await callAiService('/predict-expenses', { transactions });

    return res.json(aiResult);
  } catch (err) {
    console.error('[RF-22] predict-expenses error:', err.message);
    // Fallback cuando el servicio AI no está disponible
    return res.status(503).json({
      error: 'Servicio de predicción no disponible temporalmente.',
      detail: err.message,
    });
  }
});


// ── POST /api/v1/ai/savings ───────────────────────────────────────────────────
/**
 * RF-21 / HU-08: Recomendaciones de ahorro inteligente.
 *
 * Body (opcional): { "months": int }   — meses de histórico (def: 3)
 *
 * Returns: {
 *   recommendations: [...],
 *   savings_potential: float,
 *   score: int,
 *   savings_capacity: { ahorro_bruto, comprometido, disponible },
 *   monthly_summary: { ingreso_promedio, gasto_promedio, meses_analizados }
 * }
 */
router.post('/savings', authenticateToken, async (req, res) => {
  try {
    const months = Math.min(parseInt(req.body?.months || '3', 10), 12);
    const [transactions, monthlyIncome] = await Promise.all([
      getUserTransactions(req.user.userId, months),
      getMonthlyIncomeAverage(req.user.userId, months),
    ]);

    const aiResult = await callAiService('/savings', {
      transactions,
      monthly_income: monthlyIncome,
    });

    return res.json(aiResult);
  } catch (err) {
    console.error('[RF-21] savings error:', err.message);
    return res.status(503).json({
      error: 'Servicio de recomendaciones no disponible temporalmente.',
      detail: err.message,
    });
  }
});


// ── POST /api/v1/ai/evaluate-savings-goal ────────────────────────────────────
/**
 * RF-21 / HU-08: Evalúa si un objetivo de ahorro es realista.
 *
 * Body: { "goal": { "monto_total": float, "plazo_meses": int } }
 *
 * Returns: {
 *   es_realista: bool,
 *   ahorro_recomendado: float,
 *   ahorro_necesario: float,
 *   alerta: str|null,
 *   alternativas: [...],
 *   capacidad: { ahorro_bruto, disponible }
 * }
 */
router.post('/evaluate-savings-goal', authenticateToken, async (req, res) => {
  try {
    const goal = req.body?.goal;
    if (!goal || !goal.monto_total || !goal.plazo_meses) {
      return res.status(400).json({
        error: 'goal.monto_total y goal.plazo_meses son requeridos.',
      });
    }

    const months = 3;
    const [transactions, monthlyIncome] = await Promise.all([
      getUserTransactions(req.user.userId, months),
      getMonthlyIncomeAverage(req.user.userId, months),
    ]);

    const aiResult = await callAiService('/evaluate-savings-goal', {
      transactions,
      monthly_income: monthlyIncome,
      goal,
    });

    return res.json(aiResult);
  } catch (err) {
    console.error('[RF-21] evaluate-savings-goal error:', err.message);
    return res.status(503).json({
      error: 'Servicio de evaluación de objetivos no disponible.',
      detail: err.message,
    });
  }
});

module.exports = router;