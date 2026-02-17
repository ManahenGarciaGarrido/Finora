const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const { body, param, query, validationResult } = require('express-validator');
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
// CREATE TRANSACTION (RF-05)
// ============================================
router.post('/',
  authenticateToken,
  [
    body('amount')
      .isFloat({ min: 0.01 })
      .withMessage('La cantidad debe ser un número positivo mayor que 0'),
    body('type')
      .isIn(['income', 'expense'])
      .withMessage('El tipo debe ser "income" o "expense"'),
    body('category')
      .notEmpty()
      .trim()
      .withMessage('La categoría es requerida'),
    body('description')
      .optional()
      .trim()
      .isLength({ max: 500 })
      .withMessage('La descripción no puede exceder 500 caracteres'),
    body('date')
      .isISO8601()
      .withMessage('La fecha debe ser una fecha válida en formato ISO 8601'),
    body('payment_method')
      .isIn(['cash', 'card', 'transfer'])
      .withMessage('El método de pago debe ser "cash", "card" o "transfer"'),
  ],
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({
          error: 'Validation Error',
          message: 'Los datos proporcionados no son válidos',
          details: errors.array()
        });
      }

      const { amount, type, category, description, date, payment_method } = req.body;
      const userId = req.user.userId;

      const result = await db.query(
        `INSERT INTO transactions (user_id, amount, type, category, description, date, payment_method)
         VALUES ($1, $2, $3, $4, $5, $6, $7)
         RETURNING *`,
        [userId, amount, type, category, description || null, date, payment_method]
      );

      res.status(201).json({
        message: 'Transacción registrada exitosamente',
        transaction: result.rows[0]
      });
    } catch (error) {
      console.error('Error creating transaction:', error);
      res.status(500).json({
        error: 'Server Error',
        message: 'Error al registrar la transacción'
      });
    }
  }
);

// ============================================
// GET ALL TRANSACTIONS (with pagination)
// ============================================
router.get('/',
  authenticateToken,
  [
    query('page').optional().isInt({ min: 1 }).withMessage('La página debe ser un número positivo'),
    query('limit').optional().isInt({ min: 1, max: 100 }).withMessage('El límite debe ser entre 1 y 100'),
    query('type').optional().isIn(['income', 'expense']).withMessage('Tipo inválido'),
    query('category').optional().trim(),
    query('categories').optional().trim(),
    query('from').optional().isISO8601().withMessage('Fecha desde inválida'),
    query('to').optional().isISO8601().withMessage('Fecha hasta inválida'),
    query('payment_method').optional().isIn(['cash', 'card', 'transfer']).withMessage('Método de pago inválido'),
  ],
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({
          error: 'Validation Error',
          details: errors.array()
        });
      }

      const userId = req.user.userId;
      const page = parseInt(req.query.page) || 1;
      const limit = parseInt(req.query.limit) || 20;
      const offset = (page - 1) * limit;

      let whereClause = 'WHERE user_id = $1';
      const params = [userId];
      let paramIndex = 2;

      if (req.query.type) {
        whereClause += ` AND type = $${paramIndex}`;
        params.push(req.query.type);
        paramIndex++;
      }

      if (req.query.categories) {
        // Soporte para múltiples categorías separadas por coma (RF-08)
        const categoryList = req.query.categories.split(',').map(c => c.trim()).filter(c => c.length > 0);
        if (categoryList.length > 0) {
          const placeholders = categoryList.map((_, i) => `$${paramIndex + i}`).join(', ');
          whereClause += ` AND category IN (${placeholders})`;
          params.push(...categoryList);
          paramIndex += categoryList.length;
        }
      } else if (req.query.category) {
        whereClause += ` AND category = $${paramIndex}`;
        params.push(req.query.category);
        paramIndex++;
      }

      if (req.query.payment_method) {
        whereClause += ` AND payment_method = $${paramIndex}`;
        params.push(req.query.payment_method);
        paramIndex++;
      }

      if (req.query.from) {
        whereClause += ` AND date >= $${paramIndex}`;
        params.push(req.query.from);
        paramIndex++;
      }

      if (req.query.to) {
        whereClause += ` AND date <= $${paramIndex}`;
        params.push(req.query.to);
        paramIndex++;
      }

      // Get total count
      const countResult = await db.query(
        `SELECT COUNT(*) FROM transactions ${whereClause}`,
        params
      );
      const total = parseInt(countResult.rows[0].count);

      // Get transactions
      const result = await db.query(
        `SELECT * FROM transactions ${whereClause} ORDER BY date DESC, created_at DESC LIMIT $${paramIndex} OFFSET $${paramIndex + 1}`,
        [...params, limit, offset]
      );

      res.json({
        transactions: result.rows,
        pagination: {
          page,
          limit,
          total,
          totalPages: Math.ceil(total / limit)
        }
      });
    } catch (error) {
      console.error('Error fetching transactions:', error);
      res.status(500).json({
        error: 'Server Error',
        message: 'Error al obtener las transacciones'
      });
    }
  }
);

// ============================================
// GET SINGLE TRANSACTION
// ============================================
router.get('/:id',
  authenticateToken,
  [
    param('id').isUUID().withMessage('ID de transacción inválido'),
  ],
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({
          error: 'Validation Error',
          details: errors.array()
        });
      }

      const result = await db.query(
        'SELECT * FROM transactions WHERE id = $1 AND user_id = $2',
        [req.params.id, req.user.userId]
      );

      if (result.rows.length === 0) {
        return res.status(404).json({
          error: 'Not Found',
          message: 'Transacción no encontrada'
        });
      }

      res.json({ transaction: result.rows[0] });
    } catch (error) {
      console.error('Error fetching transaction:', error);
      res.status(500).json({
        error: 'Server Error',
        message: 'Error al obtener la transacción'
      });
    }
  }
);

// ============================================
// UPDATE TRANSACTION (RF-06)
// ============================================
router.put('/:id',
  authenticateToken,
  [
    param('id').isUUID().withMessage('ID de transacción inválido'),
    body('amount')
      .isFloat({ min: 0.01 })
      .withMessage('La cantidad debe ser un número positivo mayor que 0'),
    body('type')
      .isIn(['income', 'expense'])
      .withMessage('El tipo debe ser "income" o "expense"'),
    body('category')
      .notEmpty()
      .trim()
      .withMessage('La categoría es requerida'),
    body('description')
      .optional()
      .trim()
      .isLength({ max: 500 })
      .withMessage('La descripción no puede exceder 500 caracteres'),
    body('date')
      .isISO8601()
      .withMessage('La fecha debe ser una fecha válida en formato ISO 8601'),
    body('payment_method')
      .isIn(['cash', 'card', 'transfer'])
      .withMessage('El método de pago debe ser "cash", "card" o "transfer"'),
  ],
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({
          error: 'Validation Error',
          message: 'Los datos proporcionados no son válidos',
          details: errors.array()
        });
      }

      const userId = req.user.userId;
      const transactionId = req.params.id;

      // Verificar que la transacción existe y pertenece al usuario
      const existing = await db.query(
        'SELECT id FROM transactions WHERE id = $1 AND user_id = $2',
        [transactionId, userId]
      );

      if (existing.rows.length === 0) {
        return res.status(404).json({
          error: 'Not Found',
          message: 'Transacción no encontrada'
        });
      }

      const { amount, type, category, description, date, payment_method } = req.body;

      const result = await db.query(
        `UPDATE transactions
         SET amount = $1, type = $2, category = $3, description = $4,
             date = $5, payment_method = $6, updated_at = NOW()
         WHERE id = $7 AND user_id = $8
         RETURNING *`,
        [amount, type, category, description || null, date, payment_method, transactionId, userId]
      );

      res.json({
        message: 'Transacción actualizada exitosamente',
        transaction: result.rows[0]
      });
    } catch (error) {
      console.error('Error updating transaction:', error);
      res.status(500).json({
        error: 'Server Error',
        message: 'Error al actualizar la transacción'
      });
    }
  }
);

// ============================================
// DELETE TRANSACTION (RF-06)
// ============================================
router.delete('/:id',
  authenticateToken,
  [
    param('id').isUUID().withMessage('ID de transacción inválido'),
  ],
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({
          error: 'Validation Error',
          details: errors.array()
        });
      }

      const result = await db.query(
        'DELETE FROM transactions WHERE id = $1 AND user_id = $2 RETURNING id',
        [req.params.id, req.user.userId]
      );

      if (result.rows.length === 0) {
        return res.status(404).json({
          error: 'Not Found',
          message: 'Transacción no encontrada'
        });
      }

      res.json({
        message: 'Transacción eliminada exitosamente',
        id: result.rows[0].id
      });
    } catch (error) {
      console.error('Error deleting transaction:', error);
      res.status(500).json({
        error: 'Server Error',
        message: 'Error al eliminar la transacción'
      });
    }
  }
);

// ============================================
// GET BALANCE SUMMARY
// ============================================
router.get('/summary/balance',
  authenticateToken,
  async (req, res) => {
    try {
      const userId = req.user.userId;

      const result = await db.query(
        `SELECT
          COALESCE(SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END), 0) as total_income,
          COALESCE(SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END), 0) as total_expenses,
          COALESCE(SUM(CASE WHEN type = 'income' THEN amount ELSE -amount END), 0) as balance,
          COUNT(*) as total_transactions
        FROM transactions WHERE user_id = $1`,
        [userId]
      );

      res.json({
        summary: {
          totalIncome: parseFloat(result.rows[0].total_income),
          totalExpenses: parseFloat(result.rows[0].total_expenses),
          balance: parseFloat(result.rows[0].balance),
          totalTransactions: parseInt(result.rows[0].total_transactions)
        }
      });
    } catch (error) {
      console.error('Error fetching balance summary:', error);
      res.status(500).json({
        error: 'Server Error',
        message: 'Error al obtener el resumen del balance'
      });
    }
  }
);

module.exports = router;
