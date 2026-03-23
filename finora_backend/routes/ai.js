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


// ── GET /api/v1/ai/anomalies ──────────────────────────────────────────────────
/**
 * RF-23 / HU-10: Detección de gastos anómalos del usuario.
 *
 * Analiza el historial de transacciones y devuelve los gastos que superan
 * 2 desviaciones estándar respecto a la media de su categoría (Z-score > 2).
 *
 * Query params:
 *   ?months=6  (meses de histórico, máx 12)
 *
 * Returns: {
 *   anomalies: [{ id, date, category, amount, mean_amount, z_score,
 *                 percent_above_avg, severity, description, message }],
 *   total_anomalies: int,
 *   categories_analyzed: int,
 *   category_stats: { category: { mean, std, count } }
 * }
 */
router.get('/anomalies', authenticateToken, async (req, res) => {
  try {
    const months = Math.min(parseInt(req.query.months || '6', 10), 12);
    const transactions = await getUserTransactions(req.user.userId, months);

    if (transactions.length === 0) {
      return res.json({
        anomalies: [],
        total_anomalies: 0,
        categories_analyzed: 0,
        category_stats: {},
        message: 'No hay transacciones suficientes para detectar anomalías.',
      });
    }

    const aiResult = await callAiService('/detect-anomalies', { transactions });
    return res.json(aiResult);
  } catch (err) {
    console.error('[RF-23] anomalies error:', err.message);
    return res.status(503).json({
      error: 'Servicio de detección de anomalías no disponible.',
      detail: err.message,
    });
  }
});


// ── POST /api/v1/ai/chat ──────────────────────────────────────────────────────
/**
 * RF-25: Asistente conversacional Finn vía Ollama (LLM local) + RAG
 *
 * Ollama corre localmente en el mismo servidor (http://localhost:11434) sin
 * coste ni límite de peticiones. Inyecta el contexto financiero real del
 * usuario en el system prompt para respuestas personalizadas.
 *
 * Configuración por variables de entorno:
 *   OLLAMA_URL   — URL base de Ollama (default: http://localhost:11434)
 *   OLLAMA_MODEL — modelo a usar      (default: qwen2.5:1.5b)
 */
router.post('/chat', authenticateToken, async (req, res) => {
  try {
    const { message, history = [] } = req.body;
    if (!message || typeof message !== 'string') {
      return res.status(400).json({ error: 'message is required' });
    }

    const userId = req.user.userId;
    const ollamaUrl   = process.env.OLLAMA_URL   || 'http://localhost:11434';
    const ollamaModel = process.env.OLLAMA_MODEL  || 'qwen2.5:1.5b';

    // ── Obtener contexto financiero RAG ─────────────────────────────────────
    const now = new Date();
    const start30d     = new Date(now); start30d.setDate(now.getDate() - 30);
    const start3m      = new Date(now); start3m.setMonth(now.getMonth() - 3);
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);

    const [balanceRes, flowRes, catRes, recentRes] = await Promise.all([
      db.query(
        `SELECT COALESCE(SUM(balance_cents), 0)::float / 100 AS total
         FROM bank_accounts WHERE user_id = $1`,
        [userId],
      ),
      db.query(
        `SELECT
           COALESCE(SUM(CASE WHEN type='income'  THEN amount ELSE 0 END),0)::float AS income,
           COALESCE(SUM(CASE WHEN type='expense' THEN amount ELSE 0 END),0)::float AS expenses
         FROM transactions WHERE user_id=$1 AND date>=$2`,
        [userId, start30d.toISOString().split('T')[0]],
      ),
      db.query(
        `SELECT COALESCE(category,'Otros') AS category, SUM(amount)::float AS total
         FROM transactions
         WHERE user_id=$1 AND type='expense' AND date>=$2
         GROUP BY 1 ORDER BY total DESC LIMIT 5`,
        [userId, startOfMonth.toISOString().split('T')[0]],
      ),
      db.query(
        `SELECT amount::float, type, COALESCE(category,'Otros') AS category,
                description, TO_CHAR(date,'DD/MM/YYYY') AS date
         FROM transactions
         WHERE user_id=$1 AND date>=$2
         ORDER BY date DESC LIMIT 15`,
        [userId, start3m.toISOString().split('T')[0]],
      ),
    ]);

    const balance   = balanceRes.rows[0]?.total ?? 0;
    const income30d = flowRes.rows[0]?.income   ?? 0;
    const exp30d    = flowRes.rows[0]?.expenses  ?? 0;
    const topCats   = catRes.rows;
    const recent    = recentRes.rows;

    const catLines = topCats.length
      ? topCats.map(c => `  • ${c.category}: ${c.total.toFixed(2)} €`).join('\n')
      : '  (sin datos este mes)';
    const txLines = recent.length
      ? recent.map(t =>
          `  [${t.date}] ${t.type === 'income' ? '+' : '-'}${Math.abs(t.amount).toFixed(2)} € — ${t.category} — ${t.description}`
        ).join('\n')
      : '  (sin transacciones recientes)';

    const systemPrompt = `Eres Finn, el asistente financiero personal de Finora. \
Eres amable, claro y orientado a dar consejos prácticos en español. \
Tienes acceso al resumen financiero REAL del usuario:

=== DATOS FINANCIEROS DEL USUARIO ===
Saldo total actual: ${balance.toFixed(2)} €
Ingresos últimos 30 días: ${income30d.toFixed(2)} €
Gastos últimos 30 días: ${exp30d.toFixed(2)} €
Superávit/déficit mensual: ${(income30d - exp30d).toFixed(2)} €

Top categorías de gasto este mes:
${catLines}

Últimas transacciones (máx. 15):
${txLines}
=====================================

Usa estos datos reales para responder de forma personalizada. \
Si el usuario pregunta por su saldo, gastos o ingresos, usa los números de arriba. \
Responde siempre en español. Sé conciso (máx. 3-4 párrafos) y ofrece \
siempre una recomendación accionable.`;

    // ── Llamar a Ollama (API /api/chat compatible con OpenAI) ────────────────
    const messages = [{ role: 'system', content: systemPrompt }];
    for (const h of history) {
      messages.push({ role: h.role === 'assistant' ? 'assistant' : 'user', content: h.content });
    }
    messages.push({ role: 'user', content: message });

    // Timeout de 60s — suficiente para CPU, evita colgar la request indefinidamente
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), 60000);

    const ollamaRes = await fetch(`${ollamaUrl}/api/chat`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      signal: controller.signal,
      body: JSON.stringify({
        model: ollamaModel,
        messages,
        stream: false,
        options: {
          temperature: 0.7,
          num_predict: 400,   // ~300 palabras — suficiente y más rápido
          num_ctx: 2048,      // ventana de contexto reducida para más velocidad en CPU
          repeat_penalty: 1.1,
        },
      }),
    });
    clearTimeout(timer);

    if (!ollamaRes.ok) {
      const errText = await ollamaRes.text();
      console.error('[RF-25] Ollama error:', errText);
      return res.status(502).json({ error: 'Ollama error', detail: errText });
    }

    const data = await ollamaRes.json();
    const text = data.message?.content;
    if (!text) return res.status(502).json({ error: 'No response from Ollama' });
    return res.json({ response: text });

  } catch (err) {
    console.error('[RF-25] chat error:', err.message);
    // Si Ollama no está levantado devuelve error claro
    if (err.code === 'ECONNREFUSED') {
      return res.status(503).json({
        error: 'El servicio de IA local no está disponible. Asegúrate de que Ollama está corriendo.',
      });
    }
    return res.status(500).json({ error: err.message });
  }
});

// ── GET /api/v1/ai/subscriptions ─────────────────────────────────────────────
/**
 * RF-24 / HU-11: Detección automática de suscripciones y pagos recurrentes.
 *
 * Analiza el historial para identificar pagos con periodicidad regular
 * (semanal, mensual, trimestral, anual) y monto estable (variación < 10%).
 *
 * Query params:
 *   ?months=6  (meses de histórico, máx 12)
 *
 * Returns: {
 *   subscriptions: [{ name, category, amount, monthly_cost, periodicity,
 *                     periodicity_label, occurrences, last_charge, next_charge,
 *                     days_until_next, amount_variation }],
 *   total_subscriptions: int,
 *   total_monthly_cost: float,
 *   total_annual_cost: float
 * }
 */
router.get('/subscriptions', authenticateToken, async (req, res) => {
  try {
    const months = Math.min(parseInt(req.query.months || '6', 10), 12);
    const transactions = await getUserTransactions(req.user.userId, months);

    if (transactions.length === 0) {
      return res.json({
        subscriptions: [],
        total_subscriptions: 0,
        total_monthly_cost: 0,
        total_annual_cost: 0,
        message: 'No hay transacciones suficientes para detectar suscripciones.',
      });
    }

    const aiResult = await callAiService('/detect-subscriptions', { transactions });
    return res.json(aiResult);
  } catch (err) {
    console.error('[RF-24] subscriptions error:', err.message);
    return res.status(503).json({
      error: 'Servicio de detección de suscripciones no disponible.',
      detail: err.message,
    });
  }
});


// ── POST /api/v1/ai/check-anomaly ─────────────────────────────────────────────
/**
 * RF-23 / HU-10: Verifica si una transacción recién registrada es anómala.
 *
 * Llamado internamente después de crear una transacción (async, no bloquea).
 * Crea una notificación in-app si detecta anomalía.
 *
 * Body: { "transaction_id": uuid, "amount": float, "category": str, "type": str }
 */
router.post('/check-anomaly', authenticateToken, async (req, res) => {
  // Responder inmediatamente para no bloquear al cliente
  res.status(202).json({ message: 'Verificación de anomalía iniciada' });

  try {
    const { transaction_id, amount, category, type } = req.body;
    if (type !== 'expense' || !transaction_id || !amount) return;

    // Obtener histórico de los últimos 6 meses para el análisis
    const transactions = await getUserTransactions(req.user.userId, 6);
    if (transactions.length < 6) return; // Historial insuficiente

    const aiResult = await callAiService('/detect-anomalies', { transactions });
    const anomaly  = (aiResult.anomalies || []).find(a => a.id === transaction_id);

    if (!anomaly) return; // Transacción normal

    // Crear notificación HU-10
    await db.query(
      `INSERT INTO notifications (user_id, type, title, body, metadata)
       VALUES ($1, 'anomaly_alert', $2, $3, $4)`,
      [
        req.user.userId,
        '⚠️ Gasto inusual detectado',
        anomaly.message,
        JSON.stringify({
          transaction_id,
          category: anomaly.category,
          amount:   anomaly.amount,
          z_score:  anomaly.z_score,
          severity: anomaly.severity,
        }),
      ]
    );
  } catch (err) {
    // Fire-and-forget: errores no críticos
    console.warn('[RF-23] check-anomaly background error:', err.message);
  }
});

// ── GET /api/v1/ai/context ────────────────────────────────────────────────────
/**
 * Devuelve un snapshot financiero resumido del usuario para que el cliente
 * pueda inyectarlo como contexto en llamadas directas a Gemini.
 * Respuesta ligera: una sola query SQL agregada.
 *
 * Returns: {
 *   balance_total: float,
 *   income_30d: float,
 *   expenses_30d: float,
 *   top_categories: [{ category, total }],   // top 3 gastos este mes
 *   currency: 'EUR'
 * }
 */
router.get('/context', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.userId;
    const now = new Date();
    const startOf30d = new Date(now);
    startOf30d.setDate(startOf30d.getDate() - 30);
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);

    const [balanceRes, flowRes, catRes] = await Promise.all([
      // Total balance
      db.query(
        `SELECT COALESCE(SUM(balance_cents), 0)::float / 100 AS total
         FROM bank_accounts
         WHERE user_id = $1`,
        [userId],
      ),
      // Income & expenses last 30 days
      db.query(
        `SELECT
           COALESCE(SUM(CASE WHEN type = 'income'  THEN amount ELSE 0 END), 0)::float AS income,
           COALESCE(SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END), 0)::float AS expenses
         FROM transactions
         WHERE user_id = $1 AND date >= $2`,
        [userId, startOf30d.toISOString().split('T')[0]],
      ),
      // Top 3 expense categories this calendar month
      db.query(
        `SELECT COALESCE(category, 'Otros') AS category,
                SUM(amount)::float AS total
         FROM transactions
         WHERE user_id = $1 AND type = 'expense' AND date >= $2
         GROUP BY 1
         ORDER BY total DESC
         LIMIT 3`,
        [userId, startOfMonth.toISOString().split('T')[0]],
      ),
    ]);

    return res.json({
      balance_total: balanceRes.rows[0]?.total ?? 0,
      income_30d:    flowRes.rows[0]?.income   ?? 0,
      expenses_30d:  flowRes.rows[0]?.expenses ?? 0,
      top_categories: catRes.rows,
      currency: 'EUR',
    });
  } catch (err) {
    console.error('[ai/context] error:', err.message);
    return res.status(500).json({ error: 'Context unavailable' });
  }
});


// ── POST /api/v1/ai/affordability ─────────────────────────────────────────────
/**
 * RF-26 / HU-13: Análisis "¿Puedo permitírmelo?".
 *
 * Body: { "query": string, "amount"?: float }
 *
 * Returns: { "can_afford": bool, "verdict": string, "recommendation": string,
 *             "available_balance": float, "monthly_surplus": float }
 */
router.post('/affordability', authenticateToken, async (req, res) => {
  try {
    const { query, amount } = req.body;
    if (!query) {
      return res.status(400).json({ error: 'El campo query es requerido.' });
    }

    const transactions = await getUserTransactions(req.user.userId, 3);
    const monthlyIncome = await getMonthlyIncomeAverage(req.user.userId, 3);

    const aiResult = await callAiService('/affordability', {
      query,
      amount: amount || null,
      transactions,
      monthly_income: monthlyIncome,
    });

    return res.json(aiResult);
  } catch (err) {
    console.error('[RF-26] affordability error:', err.message);
    return res.status(503).json({
      error: 'Servicio de análisis de affordability no disponible.',
      detail: err.message,
    });
  }
});


// ── GET /api/v1/ai/recommendations ───────────────────────────────────────────
/**
 * RF-27 / HU-14: Recomendaciones proactivas de optimización financiera.
 *
 * Analiza el historial de transacciones y devuelve sugerencias de ahorro
 * priorizadas por impacto económico potencial.
 *
 * Query params:
 *   ?months=3  (meses de histórico, máx 12)
 *
 * Returns: {
 *   recommendations: [{ category, message, saving_potential, priority }],
 *   total_saving_potential: float,
 *   score: int
 * }
 */
router.get('/recommendations', authenticateToken, async (req, res) => {
  try {
    const months = Math.min(parseInt(req.query.months || '3', 10), 12);
    const [transactions, monthlyIncome] = await Promise.all([
      getUserTransactions(req.user.userId, months),
      getMonthlyIncomeAverage(req.user.userId, months),
    ]);

    if (transactions.length === 0) {
      return res.json({
        recommendations: [],
        total_saving_potential: 0,
        score: 0,
        message: 'No hay transacciones suficientes para generar recomendaciones.',
      });
    }

    const aiResult = await callAiService('/recommendations', {
      transactions,
      monthly_income: monthlyIncome,
    });

    return res.json(aiResult);
  } catch (err) {
    console.error('[RF-27] recommendations error:', err.message);
    return res.status(503).json({
      error: 'Servicio de recomendaciones no disponible.',
      detail: err.message,
    });
  }
});


module.exports = router;