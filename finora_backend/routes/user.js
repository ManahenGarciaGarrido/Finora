const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');

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

/**
 * GET /api/v1/user/profile
 * Get user profile
 */
router.get('/profile', authenticateToken, (req, res) => {
  res.status(200).json({
    message: 'Profile retrieved successfully',
    user: {
      userId: req.user.userId,
      email: req.user.email,
    }
  });
});

/**
 * PUT /api/v1/user/profile
 * Update user profile
 */
router.put('/profile', authenticateToken, (req, res) => {
  const { name } = req.body;

  // Here you would update the user in the database
  res.status(200).json({
    message: 'Profile updated successfully',
    user: {
      userId: req.user.userId,
      email: req.user.email,
      name: name || 'Updated Name'
    }
  });
});

/**
 * DELETE /api/v1/user/delete
 * Delete user account
 */
router.delete('/delete', authenticateToken, (req, res) => {
  // Here you would delete the user from the database
  res.status(200).json({
    message: 'Account deleted successfully'
  });
});

module.exports = router;
