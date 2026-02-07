require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');

// Import routes
const authRoutes = require('./routes/auth');
const userRoutes = require('./routes/user');
const healthRoutes = require('./routes/health');
const gdprRoutes = require('./routes/gdpr');
const transactionRoutes = require('./routes/transactions');

// Import services
const emailService = require('./services/email');
const db = require('./services/db');

// Import GDPR middleware
const { gdprAuditMiddleware } = require('./middleware/gdprAudit');

const app = express();
const PORT = process.env.PORT || 3000;

// ============================================
// SECURITY MIDDLEWARE
// ============================================

// Helmet - Security headers
app.use(helmet({
  hsts: {
    maxAge: 31536000, // 1 year
    includeSubDomains: true,
    preload: true
  },
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      scriptSrc: ["'self'", "'unsafe-inline'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
    },
  },
}));

// CORS Configuration
const corsOptions = {
  origin: process.env.ALLOWED_ORIGINS ? process.env.ALLOWED_ORIGINS.split(',') : '*',
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  credentials: true,
  maxAge: 86400 // 24 hours
};
app.use(cors(corsOptions));

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // Limit each IP to 100 requests per windowMs
  message: 'Too many requests from this IP, please try again later.',
  standardHeaders: true,
  legacyHeaders: false,
});
app.use('/api/', limiter);

// Stricter rate limit for auth endpoints
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 5, // Limit each IP to 5 requests per windowMs
  message: 'Too many authentication attempts, please try again later.',
  skipSuccessfulRequests: true,
});

// ============================================
// GENERAL MIDDLEWARE
// ============================================

// Logging
app.use(morgan('combined'));

// Body parsing
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Request timestamp
app.use((req, res, next) => {
  req.timestamp = new Date().toISOString();
  next();
});

// GDPR Audit middleware (logs data access for compliance)
app.use('/api/v1', gdprAuditMiddleware);

// ============================================
// ROUTES
// ============================================

// Health check (no rate limit)
app.use('/health', healthRoutes);

// API routes
app.use('/api/v1/auth', authLimiter, authRoutes);
app.use('/api/v1/user', userRoutes);
app.use('/api/v1/gdpr', gdprRoutes);
app.use('/api/v1/transactions', transactionRoutes);

// Root endpoint
app.get('/', (req, res) => {
  res.json({
    message: 'Finora API',
    version: '1.0.0',
    status: 'running',
    timestamp: req.timestamp,
    endpoints: {
      health: '/health',
      auth: '/api/v1/auth',
      user: '/api/v1/user',
      gdpr: '/api/v1/gdpr',
      transactions: '/api/v1/transactions',
    }
  });
});

// ============================================
// ERROR HANDLING
// ============================================

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    error: 'Not Found',
    message: 'The requested resource was not found',
    path: req.path,
    timestamp: req.timestamp
  });
});

// Global error handler
app.use((err, req, res, next) => {
  console.error('Error:', err);

  const statusCode = err.statusCode || 500;
  const message = err.message || 'Internal Server Error';

  res.status(statusCode).json({
    error: err.name || 'Error',
    message: message,
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack }),
    timestamp: req.timestamp
  });
});

// ============================================
// SERVER START
// ============================================

const startServer = async () => {
  try {
    // Test database connection
    const dbHealth = await db.healthCheck();
    if (dbHealth.status !== 'healthy') {
      console.error('Database connection failed:', dbHealth.error);
      // Continue anyway, health endpoint will report unhealthy
    }

    // Verify email service
    await emailService.verifyConnection();

    app.listen(PORT, () => {
      console.log('='.repeat(50));
      console.log(`Finora API Server`);
      console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
      console.log(`Server running on port ${PORT}`);
      console.log(`Database: ${dbHealth.status}`);
      console.log(`HTTPS/TLS: ${process.env.NODE_ENV === 'production' ? 'Enabled' : 'Disabled (dev)'}`);
      console.log(`Started at: ${new Date().toISOString()}`);
      console.log('='.repeat(50));
    });
  } catch (error) {
    console.error('Failed to start server:', error);
    process.exit(1);
  }
};

startServer();

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM signal received: closing HTTP server');
  app.close(() => {
    console.log('HTTP server closed');
  });
});

module.exports = app;
