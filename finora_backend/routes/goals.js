/**
 * RF-18: Creación de objetivos de ahorro
 * RF-19: Seguimiento de progreso de objetivos
 * RF-20: Registro de aportaciones a objetivos
 * RF-21: Recomendaciones inteligentes de ahorro (via AI service)
 * HU-07: Objetivos de ahorro visuales y motivadores
 *
 * Endpoints:
 *   GET    /api/v1/goals                         → Listar objetivos del usuario
 *   POST   /api/v1/goals                         → Crear objetivo (RF-18)
 *   GET    /api/v1/goals/:id                     → Detalle del objetivo
 *   PUT    /api/v1/goals/:id                     → Actualizar objetivo
 *   DELETE /api/v1/goals/:id                     → Eliminar objetivo
 *   GET    /api/v1/goals/:id/progress            → Progreso detallado (RF-19)
 *   POST   /api/v1/goals/:id/contributions       → Añadir aportación (RF-20)
 *   GET    /api/v1/goals/:id/contributions       → Historial de aportaciones (RF-20)
 *   PUT    /api/v1/goals/:id/contributions/:cid  → Editar aportación (RF-20)
 *   DELETE /api/v1/goals/:id/contributions/:cid  → Eliminar aportación (RF-20)
 *   GET    /api/v1/goals/recommendations         → Recomendaciones IA (RF-21)
 */

const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const db = require('../services/db');

const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-change-in-production';
const AI_SERVICE_URL = process.env.AI_SERVICE_URL || 'http://localhost:5001';

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

// ── Helpers ───────────────────────────────────────────────────────────────────

/**
 * Calcula métricas de progreso de un objetivo.
 * RF-19: porcentaje, cantidad restante, proyección de fecha de cumplimiento.
 * HU-07: color de progreso (rojo <30%, amarillo 30-70%, verde >70%).
 */
function calculateProgress(goal) {
  const target = parseFloat(goal.target_amount);
  const current = parseFloat(goal.current_amount);
  const pct = target > 0 ? Math.min(1, current / target) : 0;
  const remaining = Math.max(0, target - current);

  // Color dinámico según progreso (HU-07)
  let progressColor;
  if (pct >= 0.70) {
    progressColor = '#22c55e';  // verde
  } else if (pct >= 0.30) {
    progressColor = '#f59e0b';  // amarillo
  } else {
    progressColor = '#ef4444';  // rojo
  }

  // Proyección de fecha de cumplimiento (RF-19)
  // Basada en el ritmo promedio de aportación de los últimos 3 meses
  let projectedCompletionDate = null;
  if (goal.monthly_rate_cents && goal.monthly_rate_cents > 0 && remaining > 0) {
    const monthsNeeded = remaining / (goal.monthly_rate_cents / 100);
    const projected = new Date();
    projected.setDate(1);
    projected.setMonth(projected.getMonth() + Math.ceil(monthsNeeded));
    projectedCompletionDate = projected.toISOString().split('T')[0];
  }

  return {
    percentage: Math.round(pct * 100),
    percentageDecimal: pct,
    currentAmount: current,
    targetAmount: target,
    remainingAmount: remaining,
    progressColor,
    isCompleted: pct >= 1,
    projectedCompletionDate,
  };
}

/**
 * Obtiene la tasa mensual promedio de aportación de los últimos 3 meses
 * para calcular la proyección de cumplimiento.
 */
async function getMonthlyRate(goalId) {
  const threeMonthsAgo = new Date();
  threeMonthsAgo.setMonth(threeMonthsAgo.getMonth() - 3);

  const result = await db.query(
    `SELECT COALESCE(SUM(amount), 0) AS total
     FROM goal_contributions
     WHERE goal_id = $1 AND date >= $2`,
    [goalId, threeMonthsAgo.toISOString().split('T')[0]]
  );
  const total = parseFloat(result.rows[0].total);
  // Promedio mensual (3 meses), en centavos para evitar flotantes
  return Math.round((total / 3) * 100);
}

/**
 * Llama al servicio de IA para evaluar la viabilidad del objetivo.
 * Si la IA no responde, retorna null (el objetivo se crea igualmente).
 */
async function evaluateWithAI(userId, targetAmount, deadlineDate) {
  try {
    // Obtener transacciones de los últimos 6 meses para el análisis IA
    const sixMonthsAgo = new Date();
    sixMonthsAgo.setMonth(sixMonthsAgo.getMonth() - 6);

    const txResult = await db.query(
      `SELECT amount, type, category, date::text AS date
       FROM transactions
       WHERE user_id = $1 AND date >= $2
       ORDER BY date ASC`,
      [userId, sixMonthsAgo.toISOString().split('T')[0]]
    );

    const months = deadlineDate
      ? Math.max(1, Math.ceil(
          (new Date(deadlineDate) - new Date()) / (1000 * 60 * 60 * 24 * 30)
        ))
      : 12; // sin fecha límite: proyectar a 12 meses

    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), 15000);

    const response = await fetch(`${AI_SERVICE_URL}/evaluate-savings-goal`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        transactions: txResult.rows,
        goal_amount: parseFloat(targetAmount),
        months_available: months,
      }),
      signal: controller.signal,
    });
    clearTimeout(timer);

    if (!response.ok) return null;
    return await response.json();
  } catch {
    return null; // Flujo alternativo: crear objetivo sin análisis IA
  }
}

// ─── GET / — Listar objetivos del usuario (RF-18, HU-07) ─────────────────────

router.get('/', authenticateToken, async (req, res) => {
  try {
    const result = await db.query(
      `SELECT sg.*,
              COALESCE((
                SELECT SUM(amount) FROM goal_contributions WHERE goal_id = sg.id
              ), 0) AS contributions_total,
              (SELECT COUNT(*) FROM goal_contributions WHERE goal_id = sg.id) AS contributions_count
       FROM savings_goals sg
       WHERE sg.user_id = $1 AND sg.status != 'cancelled'
       ORDER BY sg.created_at DESC`,
      [req.user.userId]
    );

    const goals = await Promise.all(result.rows.map(async (g) => {
      const monthlyRateCents = await getMonthlyRate(g.id);
      const progress = calculateProgress({ ...g, monthly_rate_cents: monthlyRateCents });
      return { ...g, ...progress };
    }));

    res.json({ goals });
  } catch (err) {
    console.error('[goals] GET / error:', err);
    res.status(500).json({ error: 'Internal Server Error', message: err.message });
  }
});

// ─── POST / — Crear objetivo (RF-18, CU-03, RF-21) ───────────────────────────

router.post('/', authenticateToken, async (req, res) => {
  const { name, icon, color, target_amount, deadline, category, notes, monthly_target } = req.body;

  if (!name || !target_amount) {
    return res.status(400).json({
      error: 'Bad Request',
      message: 'name y target_amount son obligatorios',
    });
  }
  if (parseFloat(target_amount) <= 0) {
    return res.status(400).json({
      error: 'Bad Request',
      message: 'target_amount debe ser mayor que 0',
    });
  }

  try {
    // RF-21 / CU-03: Evaluar viabilidad con IA antes de crear
    const aiResult = await evaluateWithAI(req.user.userId, target_amount, deadline);

    const result = await db.query(
      `INSERT INTO savings_goals
         (user_id, name, icon, color, target_amount, deadline, category, notes,
          monthly_target, ai_feasibility, ai_explanation)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
       RETURNING *`,
      [
        req.user.userId,
        name.trim(),
        icon || 'other',
        color || '#6C63FF',
        parseFloat(target_amount),
        deadline || null,
        category || null,
        notes || null,
        monthly_target ? parseFloat(monthly_target) : (aiResult?.monthly_savings || null),
        aiResult?.feasibility || null,
        aiResult?.explanation || null,
      ]
    );

    const goal = result.rows[0];
    const progress = calculateProgress(goal);

    res.status(201).json({
      goal: { ...goal, ...progress },
      ai_analysis: aiResult,
    });
  } catch (err) {
    console.error('[goals] POST / error:', err);
    res.status(500).json({ error: 'Internal Server Error', message: err.message });
  }
});

// ─── GET /recommendations — Recomendaciones IA para nuevos objetivos (RF-21) ──

router.get('/recommendations', authenticateToken, async (req, res) => {
  try {
    const sixMonthsAgo = new Date();
    sixMonthsAgo.setMonth(sixMonthsAgo.getMonth() - 6);

    const txResult = await db.query(
      `SELECT amount, type, category, date::text AS date
       FROM transactions
       WHERE user_id = $1 AND date >= $2
       ORDER BY date ASC`,
      [req.user.userId, sixMonthsAgo.toISOString().split('T')[0]]
    );

    // Contar objetivos activos para considerar compromisos existentes (RF-21)
    const activeGoalsResult = await db.query(
      `SELECT COALESCE(SUM(monthly_target), 0) AS committed_monthly
       FROM savings_goals
       WHERE user_id = $1 AND status = 'active' AND monthly_target IS NOT NULL`,
      [req.user.userId]
    );
    const committedMonthly = parseFloat(activeGoalsResult.rows[0].committed_monthly);

    if (txResult.rows.length === 0) {
      return res.json({
        has_data: false,
        message: 'Sin historial de transacciones suficiente para calcular recomendaciones.',
        recommendations: [],
      });
    }

    // Llamar al servicio de IA para recomendaciones de ahorro
    const controller = new AbortController();
    setTimeout(() => controller.abort(), 15000);

    const aiResponse = await fetch(`${AI_SERVICE_URL}/savings`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        transactions: txResult.rows,
        existing_commitments: committedMonthly,
      }),
      signal: controller.signal,
    });

    if (!aiResponse.ok) {
      return res.status(502).json({
        error: 'AI Service Error',
        message: 'No se pudo obtener recomendaciones en este momento',
      });
    }

    const aiData = await aiResponse.json();
    res.json({ has_data: true, ...aiData, committed_monthly: committedMonthly });
  } catch (err) {
    console.error('[goals] GET /recommendations error:', err);
    res.status(500).json({ error: 'Internal Server Error', message: err.message });
  }
});

// ─── GET /:id — Detalle del objetivo ─────────────────────────────────────────

router.get('/:id', authenticateToken, async (req, res) => {
  try {
    const result = await db.query(
      `SELECT * FROM savings_goals WHERE id = $1 AND user_id = $2`,
      [req.params.id, req.user.userId]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Not Found', message: 'Objetivo no encontrado' });
    }
    const goal = result.rows[0];
    const monthlyRateCents = await getMonthlyRate(goal.id);
    const progress = calculateProgress({ ...goal, monthly_rate_cents: monthlyRateCents });
    res.json({ goal: { ...goal, ...progress } });
  } catch (err) {
    console.error('[goals] GET /:id error:', err);
    res.status(500).json({ error: 'Internal Server Error', message: err.message });
  }
});

// ─── PUT /:id — Actualizar objetivo ──────────────────────────────────────────

router.put('/:id', authenticateToken, async (req, res) => {
  const { name, icon, color, target_amount, deadline, category, notes, monthly_target, status } = req.body;

  try {
    const current = await db.query(
      'SELECT * FROM savings_goals WHERE id = $1 AND user_id = $2',
      [req.params.id, req.user.userId]
    );
    if (current.rows.length === 0) {
      return res.status(404).json({ error: 'Not Found', message: 'Objetivo no encontrado' });
    }
    const g = current.rows[0];

    const result = await db.query(
      `UPDATE savings_goals SET
         name          = COALESCE($1, name),
         icon          = COALESCE($2, icon),
         color         = COALESCE($3, color),
         target_amount = COALESCE($4, target_amount),
         deadline      = $5,
         category      = $6,
         notes         = $7,
         monthly_target = COALESCE($8, monthly_target),
         status        = COALESCE($9, status),
         completed_at  = CASE
           WHEN $9 = 'completed' AND completed_at IS NULL THEN NOW()
           ELSE completed_at
         END
       WHERE id = $10 AND user_id = $11
       RETURNING *`,
      [
        name?.trim() || null,
        icon || null,
        color || null,
        target_amount ? parseFloat(target_amount) : null,
        deadline !== undefined ? (deadline || null) : g.deadline,
        category !== undefined ? (category || null) : g.category,
        notes !== undefined ? (notes || null) : g.notes,
        monthly_target ? parseFloat(monthly_target) : null,
        status || null,
        req.params.id,
        req.user.userId,
      ]
    );

    const updated = result.rows[0];
    const monthlyRateCents = await getMonthlyRate(updated.id);
    const progress = calculateProgress({ ...updated, monthly_rate_cents: monthlyRateCents });
    res.json({ goal: { ...updated, ...progress } });
  } catch (err) {
    console.error('[goals] PUT /:id error:', err);
    res.status(500).json({ error: 'Internal Server Error', message: err.message });
  }
});

// ─── DELETE /:id — Eliminar objetivo (cancela en vez de borrar) ───────────────

router.delete('/:id', authenticateToken, async (req, res) => {
  try {
    const result = await db.query(
      `UPDATE savings_goals SET status = 'cancelled' WHERE id = $1 AND user_id = $2 RETURNING id`,
      [req.params.id, req.user.userId]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Not Found', message: 'Objetivo no encontrado' });
    }
    res.json({ message: 'Objetivo cancelado correctamente' });
  } catch (err) {
    console.error('[goals] DELETE /:id error:', err);
    res.status(500).json({ error: 'Internal Server Error', message: err.message });
  }
});

// ─── GET /:id/progress — Progreso detallado (RF-19) ──────────────────────────

router.get('/:id/progress', authenticateToken, async (req, res) => {
  try {
    const goalResult = await db.query(
      'SELECT * FROM savings_goals WHERE id = $1 AND user_id = $2',
      [req.params.id, req.user.userId]
    );
    if (goalResult.rows.length === 0) {
      return res.status(404).json({ error: 'Not Found', message: 'Objetivo no encontrado' });
    }
    const goal = goalResult.rows[0];

    // Aportaciones agrupadas por mes (gráfico de evolución RF-20)
    const monthlyResult = await db.query(
      `SELECT TO_CHAR(date, 'YYYY-MM') AS month,
              SUM(amount) AS total,
              COUNT(*) AS count
       FROM goal_contributions
       WHERE goal_id = $1
       GROUP BY month
       ORDER BY month ASC`,
      [goal.id]
    );

    // Aportaciones totales y tasa mensual
    const allContribsResult = await db.query(
      'SELECT SUM(amount) AS total FROM goal_contributions WHERE goal_id = $1',
      [goal.id]
    );

    const monthlyRateCents = await getMonthlyRate(goal.id);
    const progress = calculateProgress({ ...goal, monthly_rate_cents: monthlyRateCents });

    // Días restantes hasta la deadline (RF-19)
    let daysRemaining = null;
    if (goal.deadline) {
      daysRemaining = Math.ceil(
        (new Date(goal.deadline) - new Date()) / (1000 * 60 * 60 * 24)
      );
    }

    res.json({
      ...progress,
      goal: {
        id: goal.id,
        name: goal.name,
        icon: goal.icon,
        color: goal.color,
        deadline: goal.deadline,
        status: goal.status,
        monthly_target: goal.monthly_target,
        ai_feasibility: goal.ai_feasibility,
        ai_explanation: goal.ai_explanation,
      },
      monthly_evolution: monthlyResult.rows.map(r => ({
        month: r.month,
        total: parseFloat(r.total),
        count: parseInt(r.count),
      })),
      monthly_rate: monthlyRateCents / 100,
      days_remaining: daysRemaining,
      total_contributions: parseFloat(allContribsResult.rows[0].total || 0),
    });
  } catch (err) {
    console.error('[goals] GET /:id/progress error:', err);
    res.status(500).json({ error: 'Internal Server Error', message: err.message });
  }
});

// ─── POST /:id/contributions — Añadir aportación (RF-20) ─────────────────────

router.post('/:id/contributions', authenticateToken, async (req, res) => {
  const { amount, date, note, bank_account_id } = req.body;

  if (!amount || parseFloat(amount) <= 0) {
    return res.status(400).json({
      error: 'Bad Request',
      message: 'amount debe ser mayor que 0',
    });
  }

  try {
    const goalResult = await db.query(
      'SELECT * FROM savings_goals WHERE id = $1 AND user_id = $2 AND status = $3',
      [req.params.id, req.user.userId, 'active']
    );
    if (goalResult.rows.length === 0) {
      return res.status(404).json({
        error: 'Not Found',
        message: 'Objetivo no encontrado o ya completado/cancelado',
      });
    }
    const goal = goalResult.rows[0];

    const contribDate = date || new Date().toISOString().split('T')[0];

    // Insertar aportación
    const contribResult = await db.query(
      `INSERT INTO goal_contributions (goal_id, user_id, amount, date, note)
       VALUES ($1, $2, $3, $4, $5) RETURNING *`,
      [goal.id, req.user.userId, parseFloat(amount), contribDate, note || null]
    );
    const contribution = contribResult.rows[0];

    // Actualizar current_amount (RF-19: actualización en tiempo real)
    const newAmount = parseFloat(goal.current_amount) + parseFloat(amount);
    const isCompleted = newAmount >= parseFloat(goal.target_amount);

    await db.query(
      `UPDATE savings_goals SET
         current_amount = $1,
         status = CASE WHEN $2 THEN 'completed' ELSE status END,
         completed_at = CASE WHEN $2 AND completed_at IS NULL THEN NOW() ELSE completed_at END
       WHERE id = $3`,
      [newAmount, isCompleted, goal.id]
    );

    // Registrar la aportación como transacción de gasto en categoría Ahorro (RF-20)
    const paymentMethod = bank_account_id ? 'bank_transfer' : 'cash';
    await db.query(
      `INSERT INTO transactions (user_id, amount, type, category, description, date, payment_method, bank_account_id)
       VALUES ($1, $2, 'expense', 'Ahorro', $3, $4, $5, $6)`,
      [
        req.user.userId,
        parseFloat(amount),
        `Aportación para ${goal.name}`,
        contribDate,
        paymentMethod,
        bank_account_id || null,
      ]
    ).catch(err => console.error('[goals] Warning: could not create savings transaction:', err.message));

    // Si hay cuenta bancaria, actualizar su saldo
    if (bank_account_id) {
      await db.query(
        'UPDATE bank_accounts SET balance_cents = balance_cents - $1, updated_at = NOW() WHERE id = $2 AND user_id = $3',
        [Math.round(parseFloat(amount) * 100), bank_account_id, req.user.userId]
      ).catch(() => {});
    }

    // Notificación in-app al completar el objetivo (HU-07)
    if (isCompleted) {
      await db.query(
        `INSERT INTO notifications (user_id, type, title, body, metadata)
         VALUES ($1, 'goal_completed', $2, $3, $4)`,
        [
          req.user.userId,
          '¡Objetivo conseguido! 🎉',
          `Has alcanzado tu objetivo "${goal.name}". ¡Enhorabuena!`,
          JSON.stringify({ goal_id: goal.id, goal_name: goal.name }),
        ]
      ).catch(() => {});
    }

    // Devolver progreso actualizado
    const updatedGoal = { ...goal, current_amount: newAmount };
    const monthlyRateCents = await getMonthlyRate(goal.id);
    const progress = calculateProgress({ ...updatedGoal, monthly_rate_cents: monthlyRateCents });

    res.status(201).json({
      contribution,
      progress,
      goal_completed: isCompleted,
    });
  } catch (err) {
    console.error('[goals] POST /:id/contributions error:', err);
    res.status(500).json({ error: 'Internal Server Error', message: err.message });
  }
});

// ─── GET /:id/contributions — Historial de aportaciones (RF-20) ──────────────

router.get('/:id/contributions', authenticateToken, async (req, res) => {
  const { limit = 50, offset = 0 } = req.query;
  try {
    // Verificar que el objetivo pertenece al usuario
    const goalCheck = await db.query(
      'SELECT id FROM savings_goals WHERE id = $1 AND user_id = $2',
      [req.params.id, req.user.userId]
    );
    if (goalCheck.rows.length === 0) {
      return res.status(404).json({ error: 'Not Found', message: 'Objetivo no encontrado' });
    }

    const result = await db.query(
      `SELECT * FROM goal_contributions
       WHERE goal_id = $1
       ORDER BY date DESC, created_at DESC
       LIMIT $2 OFFSET $3`,
      [req.params.id, parseInt(limit), parseInt(offset)]
    );

    const total = await db.query(
      'SELECT COUNT(*) FROM goal_contributions WHERE goal_id = $1',
      [req.params.id]
    );

    res.json({
      contributions: result.rows,
      total: parseInt(total.rows[0].count),
    });
  } catch (err) {
    console.error('[goals] GET /:id/contributions error:', err);
    res.status(500).json({ error: 'Internal Server Error', message: err.message });
  }
});

// ─── PUT /:id/contributions/:cid — Editar aportación (RF-20) ─────────────────

router.put('/:id/contributions/:cid', authenticateToken, async (req, res) => {
  const { amount, date, note } = req.body;
  try {
    const contribResult = await db.query(
      `SELECT gc.*, sg.current_amount AS goal_current
       FROM goal_contributions gc
       JOIN savings_goals sg ON sg.id = gc.goal_id
       WHERE gc.id = $1 AND gc.goal_id = $2 AND gc.user_id = $3`,
      [req.params.cid, req.params.id, req.user.userId]
    );
    if (contribResult.rows.length === 0) {
      return res.status(404).json({ error: 'Not Found', message: 'Aportación no encontrada' });
    }
    const old = contribResult.rows[0];
    const newAmount = amount ? parseFloat(amount) : parseFloat(old.amount);

    // Actualizar aportación
    const updated = await db.query(
      `UPDATE goal_contributions SET amount = $1, date = $2, note = $3
       WHERE id = $4 RETURNING *`,
      [newAmount, date || old.date, note !== undefined ? note : old.note, req.params.cid]
    );

    // Recalcular current_amount del objetivo
    const diff = newAmount - parseFloat(old.amount);
    await db.query(
      `UPDATE savings_goals SET current_amount = GREATEST(0, current_amount + $1) WHERE id = $2`,
      [diff, req.params.id]
    );

    res.json({ contribution: updated.rows[0] });
  } catch (err) {
    console.error('[goals] PUT /:id/contributions/:cid error:', err);
    res.status(500).json({ error: 'Internal Server Error', message: err.message });
  }
});

// ─── DELETE /:id/contributions/:cid — Eliminar aportación (RF-20) ────────────

router.delete('/:id/contributions/:cid', authenticateToken, async (req, res) => {
  try {
    const contribResult = await db.query(
      `SELECT gc.amount FROM goal_contributions gc
       WHERE gc.id = $1 AND gc.goal_id = $2 AND gc.user_id = $3`,
      [req.params.cid, req.params.id, req.user.userId]
    );
    if (contribResult.rows.length === 0) {
      return res.status(404).json({ error: 'Not Found', message: 'Aportación no encontrada' });
    }
    const amount = parseFloat(contribResult.rows[0].amount);

    await db.query('DELETE FROM goal_contributions WHERE id = $1', [req.params.cid]);

    // Restar del current_amount (sin ir por debajo de 0)
    await db.query(
      `UPDATE savings_goals SET
         current_amount = GREATEST(0, current_amount - $1),
         status = CASE WHEN status = 'completed' AND current_amount - $1 < target_amount
                       THEN 'active' ELSE status END
       WHERE id = $2`,
      [amount, req.params.id]
    );

    res.json({ message: 'Aportación eliminada correctamente' });
  } catch (err) {
    console.error('[goals] DELETE /:id/contributions/:cid error:', err);
    res.status(500).json({ error: 'Internal Server Error', message: err.message });
  }
});

// ─── POST /:id/advice — Consejo IA sobre aportación propuesta (RF-21) ────────
//
// Evalúa si el importe propuesto es adecuado dado el flujo mensual del usuario.
// Body: { proposed_amount: float }
// Returns: { suggestion, advice, ahorro_necesario, ahorro_recomendado, capacidad }

router.post('/:id/advice', authenticateToken, async (req, res) => {
  const { proposed_amount } = req.body;
  if (!proposed_amount || parseFloat(proposed_amount) <= 0) {
    return res.status(400).json({ error: 'Bad Request', message: 'proposed_amount debe ser mayor que 0' });
  }

  try {
    const goalResult = await db.query(
      'SELECT * FROM savings_goals WHERE id = $1 AND user_id = $2',
      [req.params.id, req.user.userId]
    );
    if (goalResult.rows.length === 0) {
      return res.status(404).json({ error: 'Not Found', message: 'Objetivo no encontrado' });
    }
    const goal = goalResult.rows[0];

    // Transacciones últimos 3 meses para análisis
    const threeMonthsAgo = new Date();
    threeMonthsAgo.setMonth(threeMonthsAgo.getMonth() - 3);

    const txResult = await db.query(
      `SELECT amount, type, category, date::text AS date
       FROM transactions
       WHERE user_id = $1 AND date >= $2
       ORDER BY date DESC`,
      [req.user.userId, threeMonthsAgo.toISOString().split('T')[0]]
    );

    const transactions = txResult.rows.map(r => ({
      amount: parseFloat(r.amount),
      type: r.type,
      category: r.category,
      date: r.date,
    }));

    // Meses hasta el deadline
    let plazoMeses = 12;
    if (goal.deadline) {
      const now = new Date();
      const dl = new Date(goal.deadline);
      plazoMeses = Math.max(1, Math.ceil((dl - now) / (1000 * 60 * 60 * 24 * 30)));
    }

    const remaining = Math.max(0, parseFloat(goal.target_amount) - parseFloat(goal.current_amount));

    // Llamar al servicio IA
    let aiData = null;
    try {
      const controller = new AbortController();
      const timeout = setTimeout(() => controller.abort(), 10000);
      const aiResp = await fetch(`${AI_SERVICE_URL}/evaluate-savings-goal`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          transactions,
          goal: { monto_total: remaining, plazo_meses: plazoMeses },
        }),
        signal: controller.signal,
      });
      clearTimeout(timeout);
      if (aiResp.ok) aiData = await aiResp.json();
    } catch (e) {
      console.warn('[goals] advice: AI service unavailable:', e.message);
    }

    // Interpretar respuesta IA
    const proposed = parseFloat(proposed_amount);
    let suggestion = 'correct';
    let advice = null;

    if (aiData) {
      const needed = aiData.ahorro_necesario ?? (remaining / plazoMeses);
      const capacity = aiData.capacidad?.disponible ?? proposed;

      if (proposed < needed * 0.7) {
        suggestion = 'increase';
        advice = `Con ${proposed.toFixed(2)} € al mes no alcanzarás el objetivo a tiempo. Se necesitan al menos ${needed.toFixed(2)} €/mes. ${aiData.alerta || ''}`.trim();
      } else if (proposed > capacity * 0.9 && capacity > 0) {
        suggestion = 'decrease';
        advice = `Esta cantidad representa más del 90 % de tu capacidad de ahorro disponible (${capacity.toFixed(2)} €/mes). Considera reducirla para mantener margen de maniobra.`;
      } else {
        advice = `Aportación adecuada. Con ${proposed.toFixed(2)} € al mes puedes alcanzar el objetivo en el plazo previsto. ${aiData.alerta || ''}`.trim();
      }

      return res.json({
        suggestion,
        advice,
        ahorro_necesario: aiData.ahorro_necesario,
        ahorro_recomendado: aiData.ahorro_recomendado,
        capacidad: aiData.capacidad,
        plazo_meses: plazoMeses,
      });
    }

    // Fallback sin IA
    const fallbackNeeded = remaining / plazoMeses;
    if (proposed < fallbackNeeded * 0.7) {
      suggestion = 'increase';
      advice = `Para alcanzar el objetivo en plazo necesitas aportar al menos ${fallbackNeeded.toFixed(2)} €/mes.`;
    } else {
      advice = `La cantidad parece adecuada para alcanzar el objetivo en ${plazoMeses} meses.`;
    }

    res.json({ suggestion, advice, ahorro_necesario: fallbackNeeded, plazo_meses: plazoMeses });
  } catch (err) {
    console.error('[goals] POST /:id/advice error:', err);
    res.status(500).json({ error: 'Internal Server Error', message: err.message });
  }
});

module.exports = router;