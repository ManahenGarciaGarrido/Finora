const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const { body, validationResult } = require('express-validator');
const db = require('../services/db');
const bcrypt = require('bcryptjs');

const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-change-in-production';

// Authentication middleware
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({
      error: 'Unauthorized',
      message: 'No token provided'
    });
  }

  const token = authHeader.substring(7);

  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    req.user = decoded;
    next();
  } catch (error) {
    if (error.name === 'JsonWebTokenError') {
      return res.status(401).json({ error: 'Unauthorized', message: 'Invalid token' });
    }
    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({ error: 'Unauthorized', message: 'Token expired' });
    }
    return res.status(401).json({ error: 'Unauthorized', message: 'Authentication failed' });
  }
};

/**
 * GET /api/v1/user/profile
 * Returns full profile from DB (RF-09)
 */
router.get('/profile', authenticateToken, async (req, res) => {
  try {
    const result = await db.query(
      'SELECT id, email, name, created_at FROM users WHERE id = $1',
      [req.user.userId]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Not Found', message: 'Usuario no encontrado' });
    }
    const user = result.rows[0];
    res.status(200).json({
      message: 'Profile retrieved successfully',
      user: {
        userId: user.id,
        email: user.email,
        name: user.name || '',
        createdAt: user.created_at,
      }
    });
  } catch (error) {
    console.error('Error fetching profile:', error);
    res.status(500).json({ error: 'Server Error', message: 'Error al obtener el perfil' });
  }
});

/**
 * PUT /api/v1/user/profile
 * Update display name (RF-09)
 */
router.put('/profile',
  authenticateToken,
  [
    body('name')
      .trim()
      .notEmpty().withMessage('El nombre es requerido')
      .isLength({ max: 255 }).withMessage('El nombre no puede superar 255 caracteres'),
  ],
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({
          error: 'Validation Error',
          message: errors.array()[0].msg,
          details: errors.array()
        });
      }

      const { name } = req.body;
      const result = await db.query(
        'UPDATE users SET name = $1, updated_at = NOW() WHERE id = $2 RETURNING id, email, name',
        [name.trim(), req.user.userId]
      );

      if (result.rows.length === 0) {
        return res.status(404).json({ error: 'Not Found', message: 'Usuario no encontrado' });
      }

      const user = result.rows[0];
      res.status(200).json({
        message: 'Perfil actualizado exitosamente',
        user: {
          userId: user.id,
          email: user.email,
          name: user.name,
        }
      });
    } catch (error) {
      console.error('Error updating profile:', error);
      res.status(500).json({ error: 'Server Error', message: 'Error al actualizar el perfil' });
    }
  }
);

/**
 * PUT /api/v1/user/change-password
 * Change user password (RF-03 / security)
 */
router.put('/change-password',
  authenticateToken,
  [
    body('currentPassword').notEmpty().withMessage('La contraseña actual es requerida'),
    body('newPassword')
      .isLength({ min: 8 }).withMessage('La nueva contraseña debe tener al menos 8 caracteres'),
  ],
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({
          error: 'Validation Error',
          message: errors.array()[0].msg,
          details: errors.array()
        });
      }

      const { currentPassword, newPassword } = req.body;

      // Fetch stored password hash
      const result = await db.query(
        'SELECT id, password FROM users WHERE id = $1',
        [req.user.userId]
      );
      if (result.rows.length === 0) {
        return res.status(404).json({ error: 'Not Found', message: 'Usuario no encontrado' });
      }

      const user = result.rows[0];

      // Verify current password
      const isValid = await bcrypt.compare(currentPassword, user.password);
      if (!isValid) {
        return res.status(401).json({
          error: 'Unauthorized',
          message: 'La contraseña actual es incorrecta'
        });
      }

      // Hash new password and save
      const newHash = await bcrypt.hash(newPassword, 10);
      await db.query(
        'UPDATE users SET password = $1, updated_at = NOW() WHERE id = $2',
        [newHash, req.user.userId]
      );

      res.status(200).json({ message: 'Contraseña actualizada exitosamente' });
    } catch (error) {
      console.error('Error changing password:', error);
      res.status(500).json({ error: 'Server Error', message: 'Error al cambiar la contraseña' });
    }
  }
);

/**
 * DELETE /api/v1/user/delete
 * Delete user account (GDPR - RNF-04)
 */
router.delete('/delete', authenticateToken, async (req, res) => {
  try {
    await db.query('DELETE FROM users WHERE id = $1', [req.user.userId]);
    res.status(200).json({ message: 'Cuenta eliminada exitosamente' });
  } catch (error) {
    console.error('Error deleting account:', error);
    res.status(500).json({ error: 'Server Error', message: 'Error al eliminar la cuenta' });
  }
});

module.exports = router;
