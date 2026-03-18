/**
 * Notifications routes — HU-06
 *
 * In-app notifications created when bank sync detects new transactions.
 * Also used for consent renewal warnings and system alerts.
 *
 * Endpoints:
 *   GET    /notifications              — lista notificaciones del usuario
 *   PUT    /notifications/read-all     — marca todas como leídas
 *   PUT    /notifications/:id/read     — marca una como leída
 *   DELETE /notifications/:id          — elimina una notificación
 */

const express = require('express');
const router = express.Router();
const db = require('../services/db');
const { authenticateToken } = require('../middleware/auth');

// ─── GET /notifications ───────────────────────────────────────────────────────
// Devuelve las últimas notificaciones del usuario + contador de no leídas.

router.get('/', authenticateToken, async (req, res) => {
  try {
    const { limit = 30, offset = 0 } = req.query;
    const userId = req.user.userId;

    const [notifResult, unreadResult] = await Promise.all([
      db.query(
        `SELECT id, type, title, body, metadata, read_at, created_at
         FROM notifications
         WHERE user_id = $1
         ORDER BY created_at DESC
         LIMIT $2 OFFSET $3`,
        [userId, parseInt(limit), parseInt(offset)]
      ),
      db.query(
        'SELECT COUNT(*) AS cnt FROM notifications WHERE user_id = $1 AND read_at IS NULL',
        [userId]
      ),
    ]);

    res.json({
      notifications: notifResult.rows,
      unread_count: parseInt(unreadResult.rows[0].cnt),
      total: notifResult.rows.length,
    });
  } catch (err) {
    console.error('notifications/list error:', err);
    res.status(500).json({ error: 'Internal Server Error', message: err.message });
  }
});

// ─── PUT /notifications/read-all ─────────────────────────────────────────────
// Marca TODAS las notificaciones no leídas del usuario como leídas.
// IMPORTANT: Must be defined BEFORE /:id/read to avoid route shadowing.

router.put('/read-all', authenticateToken, async (req, res) => {
  try {
    const result = await db.query(
      `UPDATE notifications
       SET read_at = NOW()
       WHERE user_id = $1 AND read_at IS NULL
       RETURNING id`,
      [req.user.userId]
    );
    res.json({ success: true, marked: result.rows.length });
  } catch (err) {
    console.error('notifications/read-all error:', err);
    res.status(500).json({ error: 'Internal Server Error', message: err.message });
  }
});

// ─── PUT /notifications/:id/read ─────────────────────────────────────────────
// Marca una notificación específica como leída.

router.put('/:id/read', authenticateToken, async (req, res) => {
  try {
    const result = await db.query(
      `UPDATE notifications SET read_at = NOW()
       WHERE id = $1 AND user_id = $2 AND read_at IS NULL
       RETURNING id`,
      [req.params.id, req.user.userId]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Not Found', message: 'Notification not found or already read' });
    }
    res.json({ success: true });
  } catch (err) {
    console.error('notifications/read error:', err);
    res.status(500).json({ error: 'Internal Server Error', message: err.message });
  }
});

// ─── DELETE /notifications/:id ────────────────────────────────────────────────
// Elimina una notificación del usuario.

router.delete('/:id', authenticateToken, async (req, res) => {
  try {
    const result = await db.query(
      'DELETE FROM notifications WHERE id = $1 AND user_id = $2 RETURNING id',
      [req.params.id, req.user.userId]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Not Found', message: 'Notification not found' });
    }
    res.json({ success: true });
  } catch (err) {
    console.error('notifications/delete error:', err);
    res.status(500).json({ error: 'Internal Server Error', message: err.message });
  }
});

// ─── POST /notifications/register-token ──────────────────────────────────────
// RF-31: Registra el token FCM del dispositivo para push notifications.
// Body: { token, platform: 'ios' | 'android' }

router.post('/register-token', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.userId;
    const { token, platform } = req.body;

    if (!token || typeof token !== 'string') {
      return res.status(422).json({ error: 'Validation Error', message: 'token requerido' });
    }

    await db.query(
      `INSERT INTO push_tokens (user_id, token, platform, updated_at)
       VALUES ($1, $2, $3, NOW())
       ON CONFLICT (token)
       DO UPDATE SET user_id = $1, platform = $3, updated_at = NOW()`,
      [userId, token, platform || 'unknown']
    );

    res.json({ success: true, message: 'Token FCM registrado correctamente' });
  } catch (err) {
    console.error('notifications/register-token error:', err);
    res.status(500).json({ error: 'Internal Server Error', message: err.message });
  }
});

// ─── GET /notifications/settings ─────────────────────────────────────────────
// RF-31/RF-32/RF-33: Devuelve preferencias de notificación push del usuario.

router.get('/settings', authenticateToken, async (req, res) => {
  try {
    const result = await db.query(
      `SELECT push_new_transactions, push_budget_alerts, push_goal_reminders,
              push_min_amount, push_quiet_hours_enabled, push_quiet_start, push_quiet_end
       FROM notification_settings WHERE user_id = $1`,
      [req.user.userId]
    );

    const defaults = {
      push_new_transactions: true,
      push_budget_alerts: true,
      push_goal_reminders: true,
      push_min_amount: 0,
      push_quiet_hours_enabled: false,
      push_quiet_start: '22:00',
      push_quiet_end: '08:00',
    };

    res.json(result.rows.length > 0 ? result.rows[0] : defaults);
  } catch (err) {
    console.error('notifications/settings GET error:', err);
    res.status(500).json({ error: 'Internal Server Error', message: err.message });
  }
});

// ─── PUT /notifications/settings ─────────────────────────────────────────────
// RF-31/RF-32/RF-33: Actualiza preferencias de notificación push.

router.put('/settings', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.userId;
    const {
      push_new_transactions, push_budget_alerts, push_goal_reminders,
      push_min_amount, push_quiet_hours_enabled, push_quiet_start, push_quiet_end,
    } = req.body;

    await db.query(
      `INSERT INTO notification_settings
         (user_id, push_new_transactions, push_budget_alerts, push_goal_reminders,
          push_min_amount, push_quiet_hours_enabled, push_quiet_start, push_quiet_end)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8)
       ON CONFLICT (user_id) DO UPDATE SET
         push_new_transactions    = COALESCE($2, notification_settings.push_new_transactions),
         push_budget_alerts       = COALESCE($3, notification_settings.push_budget_alerts),
         push_goal_reminders      = COALESCE($4, notification_settings.push_goal_reminders),
         push_min_amount          = COALESCE($5, notification_settings.push_min_amount),
         push_quiet_hours_enabled = COALESCE($6, notification_settings.push_quiet_hours_enabled),
         push_quiet_start         = COALESCE($7, notification_settings.push_quiet_start),
         push_quiet_end           = COALESCE($8, notification_settings.push_quiet_end),
         updated_at               = NOW()`,
      [userId,
       push_new_transactions ?? null, push_budget_alerts ?? null, push_goal_reminders ?? null,
       push_min_amount ?? null, push_quiet_hours_enabled ?? null,
       push_quiet_start ?? null, push_quiet_end ?? null]
    );

    res.json({ success: true, message: 'Preferencias de notificación actualizadas' });
  } catch (err) {
    console.error('notifications/settings PUT error:', err);
    res.status(500).json({ error: 'Internal Server Error', message: err.message });
  }
});

module.exports = router;