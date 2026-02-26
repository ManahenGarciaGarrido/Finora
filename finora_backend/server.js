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
const categoryRoutes = require('./routes/categories');
const bankRoutes = require('./routes/banks');

// Import services
const emailService = require('./services/email');
const db = require('./services/db');

// RF-11: Background sync scheduler
const cron = require('node-cron');

// Import GDPR middleware
const { gdprAuditMiddleware } = require('./middleware/gdprAudit');

const app = express();
const PORT = process.env.PORT || 3000;

// ============================================
// SECURITY MIDDLEWARE
// ============================================

// Helmet - Security headers
// NOTE: HSTS is intentionally disabled here because this server runs plain HTTP.
// HSTS must only be sent by HTTPS servers; sending it over HTTP causes browsers
// to cache "this host requires HTTPS" and generate ERR_SSL_PROTOCOL_ERROR for
// all subsequent HTTP requests (including OAuth callback pages).
app.use(helmet({
  hsts: false,
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      // Plaid Link JS SDK se sirve desde cdn.plaid.com
      scriptSrc: ["'self'", "'unsafe-inline'", 'https://cdn.plaid.com'],
      styleSrc: ["'self'", "'unsafe-inline'"],
      // Plaid Link hace llamadas internas a sandbox.plaid.com
      connectSrc: ["'self'", 'https://*.plaid.com'],
      // Plaid Link usa iframes para el flujo de OAuth bancario
      frameSrc: ["'self'", 'https://*.plaid.com'],
      imgSrc: ["'self'", 'data:', 'https://*.plaid.com', 'https://placehold.co'],
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
app.use('/api/v1/categories', categoryRoutes);
app.use('/api/v1/banks', bankRoutes);

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
      categories: '/api/v1/categories',
      banks: '/api/v1/banks',
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

    // Auto-migraciones idempotentes: añade columnas que pueden faltar en BDs antiguas.
    // Seguro ejecutar en cada arranque (IF NOT EXISTS).
    try {
      await db.query(`
        ALTER TABLE transactions
          ADD COLUMN IF NOT EXISTS external_tx_id VARCHAR(255)
      `);
      await db.query(`
        CREATE UNIQUE INDEX IF NOT EXISTS idx_transactions_external_tx_id
          ON transactions(external_tx_id)
          WHERE external_tx_id IS NOT NULL
      `);
      console.log('[auto-migrate] ✓ transactions.external_tx_id');
    } catch (migrateErr) {
      console.warn('[auto-migrate] external_tx_id migration warning:', migrateErr.message);
    }
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

    // RF-11: Sincronización automática en background cada 6 horas
    // Expresión cron: "0 */6 * * *" → en punto cada 6 horas (0h, 6h, 12h, 18h)
    cron.schedule('0 */6 * * *', async () => {
      console.log(`[RF-11][cron] Iniciando sincronización automática — ${new Date().toISOString()}`);
      try {
        const http = require('http');
        const cronSecret = process.env.CRON_SECRET || '';
        const options = {
          hostname: 'localhost',
          port: PORT,
          path: '/api/v1/banks/sync-all',
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'X-Cron-Secret': cronSecret,
          },
        };
        const req = http.request(options, (res) => {
          let body = '';
          res.on('data', (chunk) => { body += chunk; });
          res.on('end', () => {
            try {
              const data = JSON.parse(body);
              console.log(`[RF-11][cron] Completado: ${data.imported} nuevas, ${data.skipped} repetidas, ${data.connections} conexiones`);
            } catch (_) {
              console.log('[RF-11][cron] Completado (respuesta no parseable)');
            }
          });
        });
        req.on('error', (err) => console.error('[RF-11][cron] Error HTTP:', err.message));
        req.end();
      } catch (err) {
        console.error('[RF-11][cron] Error inesperado:', err.message);
      }
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
