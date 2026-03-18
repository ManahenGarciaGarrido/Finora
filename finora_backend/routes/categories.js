const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const { body, param, validationResult } = require('express-validator');
const db = require('../services/db');
const { autoCategory } = require('../services/categoryMapper');

// RF-14: URL del servicio Python de IA (configurable via env)
const AI_SERVICE_URL = process.env.AI_SERVICE_URL || 'http://localhost:5001';

/**
 * RF-14: Llama al servicio Python de IA para categorización.
 * Fallback automático al motor de reglas si el servicio no está disponible.
 */
async function autoCategoryWithAI(description, type) {
  try {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 3000); // 3s timeout
    const response = await fetch(`${AI_SERVICE_URL}/categorize`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ description, type }),
      signal: controller.signal,
    });
    clearTimeout(timeout);
    if (response.ok) {
      const data = await response.json();
      return {
        category:   data.category,
        confidence: data.confidence,
        isFallback: data.is_fallback,
        method:     data.method || 'ai',
      };
    }
  } catch (e) {
    // Servicio AI no disponible — usar motor de reglas local
  }
  // Fallback al motor de reglas (categoryMapper.js)
  return autoCategory(description, type);
}

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

// ============================================
// POST /categories — Crear categoría personalizada (RF-16)
// ============================================
router.post('/',
  authenticateToken,
  [
    body('name')
      .trim()
      .notEmpty().withMessage('El nombre es requerido')
      .isLength({ max: 100 }).withMessage('El nombre no puede superar 100 caracteres'),
    body('type')
      .isIn(['income', 'expense']).withMessage('El tipo debe ser "income" o "expense"'),
    body('icon')
      .trim()
      .notEmpty().withMessage('El icono es requerido')
      .isLength({ max: 50 }).withMessage('El icono no puede superar 50 caracteres'),
    body('color')
      .matches(/^#[0-9A-Fa-f]{6}$/).withMessage('El color debe ser un hexadecimal válido (#RRGGBB)'),
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
      const { name, type, icon, color } = req.body;

      // RF-16: Validar nombre único por usuario (insensible a mayúsculas)
      const existing = await db.query(
        `SELECT id FROM categories
         WHERE user_id = $1 AND LOWER(name) = LOWER($2) AND type = $3`,
        [userId, name, type]
      );
      if (existing.rows.length > 0) {
        return res.status(409).json({
          error: 'Conflict',
          message: `Ya tienes una categoría de ${type === 'expense' ? 'gastos' : 'ingresos'} con ese nombre`
        });
      }

      // Calcular display_order: máximo actual + 1
      const orderResult = await db.query(
        `SELECT COALESCE(MAX(display_order), 0) + 1 AS next_order
         FROM categories WHERE user_id = $1 AND type = $2`,
        [userId, type]
      );
      const displayOrder = orderResult.rows[0].next_order;

      const result = await db.query(
        `INSERT INTO categories (user_id, name, type, icon, color, is_predefined, display_order)
         VALUES ($1, $2, $3, $4, $5, FALSE, $6)
         RETURNING id, name, type, icon, color, is_predefined, display_order, created_at`,
        [userId, name.trim(), type, icon.trim(), color, displayOrder]
      );

      res.status(201).json({
        message: 'Categoría creada exitosamente',
        category: result.rows[0]
      });
    } catch (error) {
      console.error('Error creating category:', error);
      res.status(500).json({
        error: 'Server Error',
        message: 'Error al crear la categoría'
      });
    }
  }
);

// ============================================
// PUT /categories/:id — Editar categoría personalizada (RF-16)
// ============================================
router.put('/:id',
  authenticateToken,
  [
    param('id').isUUID().withMessage('ID de categoría inválido'),
    body('name')
      .optional().trim()
      .isLength({ min: 1, max: 100 }).withMessage('El nombre debe tener entre 1 y 100 caracteres'),
    body('icon')
      .optional().trim()
      .isLength({ min: 1, max: 50 }).withMessage('El icono debe tener entre 1 y 50 caracteres'),
    body('color')
      .optional()
      .matches(/^#[0-9A-Fa-f]{6}$/).withMessage('El color debe ser un hexadecimal válido (#RRGGBB)'),
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
      const categoryId = req.params.id;

      // Verificar que existe y pertenece al usuario
      const existing = await db.query(
        'SELECT * FROM categories WHERE id = $1 AND user_id = $2',
        [categoryId, userId]
      );
      if (existing.rows.length === 0) {
        return res.status(404).json({
          error: 'Not Found',
          message: 'Categoría no encontrada'
        });
      }

      const cat = existing.rows[0];

      // RF-16: No se pueden editar categorías predefinidas del sistema
      if (cat.is_predefined) {
        return res.status(403).json({
          error: 'Forbidden',
          message: 'Las categorías predefinidas no se pueden editar'
        });
      }

      const { name, icon, color } = req.body;

      // RF-16: Validar nombre único si se va a cambiar
      if (name && name.trim().toLowerCase() !== cat.name.toLowerCase()) {
        const duplicate = await db.query(
          `SELECT id FROM categories
           WHERE user_id = $1 AND LOWER(name) = LOWER($2) AND type = $3 AND id != $4`,
          [userId, name, cat.type, categoryId]
        );
        if (duplicate.rows.length > 0) {
          return res.status(409).json({
            error: 'Conflict',
            message: 'Ya tienes una categoría con ese nombre'
          });
        }
      }

      const result = await db.query(
        `UPDATE categories
         SET name = COALESCE($1, name),
             icon = COALESCE($2, icon),
             color = COALESCE($3, color),
             updated_at = NOW()
         WHERE id = $4 AND user_id = $5
         RETURNING id, name, type, icon, color, is_predefined, display_order, created_at, updated_at`,
        [name?.trim() || null, icon?.trim() || null, color || null, categoryId, userId]
      );

      res.json({
        message: 'Categoría actualizada exitosamente',
        category: result.rows[0]
      });
    } catch (error) {
      console.error('Error updating category:', error);
      res.status(500).json({
        error: 'Server Error',
        message: 'Error al actualizar la categoría'
      });
    }
  }
);

// ============================================
// DELETE /categories/:id — Eliminar categoría personalizada (RF-16)
// Solo se puede eliminar si no tiene transacciones asociadas
// ============================================
router.delete('/:id',
  authenticateToken,
  [
    param('id').isUUID().withMessage('ID de categoría inválido'),
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
      const categoryId = req.params.id;

      // Verificar que existe y pertenece al usuario
      const existing = await db.query(
        'SELECT * FROM categories WHERE id = $1 AND user_id = $2',
        [categoryId, userId]
      );
      if (existing.rows.length === 0) {
        return res.status(404).json({
          error: 'Not Found',
          message: 'Categoría no encontrada'
        });
      }

      const cat = existing.rows[0];

      // RF-16: No se pueden eliminar categorías predefinidas
      if (cat.is_predefined) {
        return res.status(403).json({
          error: 'Forbidden',
          message: 'Las categorías predefinidas no se pueden eliminar'
        });
      }

      // RF-16: No eliminar si tiene transacciones asociadas
      const txCount = await db.query(
        'SELECT COUNT(*) AS cnt FROM transactions WHERE user_id = $1 AND category = $2',
        [userId, cat.name]
      );
      const count = parseInt(txCount.rows[0].cnt);
      if (count > 0) {
        return res.status(409).json({
          error: 'Conflict',
          message: `No se puede eliminar: tienes ${count} transacci${count === 1 ? 'ón' : 'ones'} con esta categoría. Reasígnalas primero.`,
          transaction_count: count
        });
      }

      await db.query('DELETE FROM categories WHERE id = $1 AND user_id = $2', [categoryId, userId]);

      res.json({
        message: 'Categoría eliminada exitosamente',
        id: categoryId
      });
    } catch (error) {
      console.error('Error deleting category:', error);
      res.status(500).json({
        error: 'Server Error',
        message: 'Error al eliminar la categoría'
      });
    }
  }
);

// ============================================
// POST /categories/auto-categorize — Categorización automática (RF-14)
// Analiza el descriptor de una transacción y devuelve categoría + confianza
// ============================================
router.post('/auto-categorize',
  authenticateToken,
  [
    body('description').trim().notEmpty().withMessage('La descripción es requerida'),
    body('type').isIn(['income', 'expense']).withMessage('El tipo debe ser "income" o "expense"'),
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

      const { description, type } = req.body;
      // RF-14: Intentar con servicio Python de IA primero, fallback a reglas
      const result = await autoCategoryWithAI(description, type);

      res.json({
        category:   result.category,
        confidence: result.confidence,
        is_fallback: result.isFallback,
        method:     result.method || 'rules',
      });
    } catch (error) {
      console.error('Error en auto-categorize:', error);
      res.status(500).json({
        error: 'Server Error',
        message: 'Error en la categorización automática'
      });
    }
  }
);

// ============================================
// POST /categories/feedback — Aprendizaje de correcciones (RF-14, RF-17)
// Registra cuando el usuario corrige una categoría (para mejorar el modelo)
// ============================================
router.post('/feedback',
  authenticateToken,
  [
    body('description').trim().notEmpty().withMessage('La descripción es requerida'),
    body('type').isIn(['income', 'expense']).withMessage('El tipo es requerido'),
    body('corrected_category').trim().notEmpty().withMessage('La categoría corregida es requerida'),
    body('original_category').optional().trim(),
    body('transaction_id').optional().isUUID(),
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
      const { description, type, corrected_category, original_category, transaction_id } = req.body;

      // Guardar feedback para aprendizaje futuro del modelo
      // La tabla category_feedback almacena correcciones que mejoran el modelo
      await db.query(
        `INSERT INTO category_feedback
           (user_id, description, transaction_type, corrected_category, original_category, transaction_id)
         VALUES ($1, $2, $3, $4, $5, $6)
         ON CONFLICT (user_id, description, transaction_type)
         DO UPDATE SET
           corrected_category = EXCLUDED.corrected_category,
           updated_at = NOW()`,
        [userId, description.trim(), type, corrected_category, original_category || null, transaction_id || null]
      ).catch(() => {
        // Si la tabla no existe aún, continuar sin error (se creará en migración)
      });

      res.json({
        message: 'Feedback registrado. Gracias por mejorar la categorización.',
        description,
        corrected_category
      });
    } catch (error) {
      console.error('Error registrando feedback:', error);
      res.status(500).json({
        error: 'Server Error',
        message: 'Error al registrar el feedback'
      });
    }
  }
);

// ============================================
// POST /categories/recategorize — Recategorizar múltiples transacciones (RF-17)
// Cambia la categoría de todas las transacciones similares de golpe
// ============================================
router.post('/recategorize',
  authenticateToken,
  [
    body('description').trim().notEmpty().withMessage('La descripción es requerida'),
    body('new_category').trim().notEmpty().withMessage('La nueva categoría es requerida'),
    body('type').isIn(['income', 'expense']).withMessage('El tipo es requerido'),
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
      const { description, new_category, type } = req.body;

      // RF-17: Actualizar todas las transacciones con la misma descripción y tipo
      const result = await db.query(
        `UPDATE transactions
         SET category = $1, updated_at = NOW()
         WHERE user_id = $2
           AND LOWER(description) = LOWER($3)
           AND type = $4
           AND category != $1
         RETURNING id`,
        [new_category, userId, description.trim(), type]
      );

      const updatedCount = result.rows.length;

      // Registrar como feedback para el modelo
      if (updatedCount > 0) {
        await db.query(
          `INSERT INTO category_feedback
             (user_id, description, transaction_type, corrected_category)
           VALUES ($1, $2, $3, $4)
           ON CONFLICT (user_id, description, transaction_type)
           DO UPDATE SET corrected_category = EXCLUDED.corrected_category, updated_at = NOW()`,
          [userId, description.trim(), type, new_category]
        ).catch(() => {});
      }

      res.json({
        message: `${updatedCount} transacci${updatedCount === 1 ? 'ón' : 'ones'} recategorizada${updatedCount === 1 ? '' : 's'} a "${new_category}"`,
        updated_count: updatedCount,
        new_category
      });
    } catch (error) {
      console.error('Error en recategorize:', error);
      res.status(500).json({
        error: 'Server Error',
        message: 'Error al recategorizar las transacciones'
      });
    }
  }
);

module.exports = router;