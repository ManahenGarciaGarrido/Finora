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

module.exports = router;