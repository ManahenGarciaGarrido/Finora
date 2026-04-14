const jwt = require('jsonwebtoken');

// Es mejor centralizar la configuración en un archivo aparte (ej. config.js)
const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-change-in-production';

/**
 * Helper para estandarizar las respuestas de error y reducir repetición visual
 */
const sendUnauthorized = (res, message) => {
  return res.status(401).json({
    error: 'Unauthorized',
    message: message
  });
};

const authenticateToken = (req, res, next) => {
  const authHeader = req.headers.authorization;

  if (!authHeader?.startsWith('Bearer ')) {
    return sendUnauthorized(res, 'No token provided');
  }

  const token = authHeader.substring(7);

  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    req.user = decoded;
    next();
  } catch (error) {
    // Usamos un objeto para mapear errores y evitar múltiples IFs
    const errorMessages = {
      'JsonWebTokenError': 'Invalid token',
      'TokenExpiredError': 'Token expired'
    };

    const message = errorMessages[error.name] || 'Authentication failed';
    return sendUnauthorized(res, message);
  }
};

module.exports = { authenticateToken };