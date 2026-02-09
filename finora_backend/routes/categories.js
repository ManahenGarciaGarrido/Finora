const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const db = require('../services/db');

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
      return res.status(401).json({
        error: 'Unauthorized',
        message: 'Invalid token'
      });
    }
    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({
        error: 'Unauthorized',
        message: 'Token expired'
      });
    }
    return res.status(401).json({
      error: 'Unauthorized',
      message: 'Authentication failed'
    });
  }
};

// ============================================
// GET ALL CATEGORIES (RF-15)
// Returns predefined (system) + user's custom categories
// ============================================
router.get('/',
  authenticateToken,
  async (req, res) => {
    try {
      const userId = req.user.userId;

      // Get only categories belonging to this user
      const result = await db.query(
        `SELECT id, name, type, icon, color, is_predefined, display_order, created_at
         FROM categories
         WHERE user_id = $1
         ORDER BY type, display_order, name`,
        [userId]
      );

      res.json({
        categories: result.rows
      });
    } catch (error) {
      console.error('Error fetching categories:', error);
      res.status(500).json({
        error: 'Server Error',
        message: 'Error al obtener las categorías'
      });
    }
  }
);

// ============================================
// GET CATEGORIES BY TYPE
// ============================================
router.get('/type/:type',
  authenticateToken,
  async (req, res) => {
    try {
      const { type } = req.params;
      const userId = req.user.userId;

      if (!['income', 'expense'].includes(type)) {
        return res.status(400).json({
          error: 'Validation Error',
          message: 'El tipo debe ser "income" o "expense"'
        });
      }

      const result = await db.query(
        `SELECT id, name, type, icon, color, is_predefined, display_order
         FROM categories
         WHERE user_id = $1 AND type = $2
         ORDER BY display_order, name`,
        [userId, type]
      );

      res.json({
        categories: result.rows
      });
    } catch (error) {
      console.error('Error fetching categories by type:', error);
      res.status(500).json({
        error: 'Server Error',
        message: 'Error al obtener las categorías'
      });
    }
  }
);

module.exports = router;
