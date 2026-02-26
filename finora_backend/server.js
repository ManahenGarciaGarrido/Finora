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
const notificationRoutes = require('./routes/notifications'); // HU-06

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
app.use('/api/v1/notifications', notificationRoutes); // HU-06

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

    // RNF-05: PSD2 consent management table
    // Almacena consentimientos bancarios con fecha de expiración (90 días, norma PSD2 SCA)
    try {
      await db.query(`
        CREATE TABLE IF NOT EXISTS psd2_consents (
          id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
          user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
          connection_id UUID NOT NULL REFERENCES bank_connections(id) ON DELETE CASCADE,
          consent_reference VARCHAR(255),
          status VARCHAR(20) NOT NULL DEFAULT 'active'
            CHECK (status IN ('active', 'expired', 'revoked')),
          scope TEXT NOT NULL DEFAULT 'read_accounts,read_transactions',
          granted_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
          expires_at TIMESTAMP NOT NULL,
          revoked_at TIMESTAMP,
          renewal_notified_at TIMESTAMP,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          UNIQUE(connection_id)
        )
      `);
      await db.query(`
        CREATE INDEX IF NOT EXISTS idx_psd2_consents_user_id ON psd2_consents(user_id)
      `);
      await db.query(`
        CREATE INDEX IF NOT EXISTS idx_psd2_consents_expires_at ON psd2_consents(expires_at)
      `);
      console.log('[auto-migrate] ✓ psd2_consents table (RNF-05)');
    } catch (migrateErr) {
      console.warn('[auto-migrate] psd2_consents migration warning:', migrateErr.message);
    }

    // RNF-07: Tabla de log de sincronización (historial y monitorización)
    try {
      await db.query(`
        CREATE TABLE IF NOT EXISTS sync_logs (
          id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
          connection_id UUID REFERENCES bank_connections(id) ON DELETE SET NULL,
          user_id UUID REFERENCES users(id) ON DELETE SET NULL,
          trigger_type VARCHAR(20) NOT NULL DEFAULT 'cron'
            CHECK (trigger_type IN ('cron', 'manual', 'initial')),
          status VARCHAR(20) NOT NULL DEFAULT 'success'
            CHECK (status IN ('success', 'error', 'partial')),
          imported_count INTEGER DEFAULT 0,
          skipped_count INTEGER DEFAULT 0,
          duration_ms INTEGER,
          error_message TEXT,
          synced_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
        )
      `);
      await db.query(`
        CREATE INDEX IF NOT EXISTS idx_sync_logs_connection_id ON sync_logs(connection_id)
      `);
      await db.query(`
        CREATE INDEX IF NOT EXISTS idx_sync_logs_synced_at ON sync_logs(synced_at DESC)
      `);
      console.log('[auto-migrate] ✓ sync_logs table (RNF-07)');
    } catch (migrateErr) {
      console.warn('[auto-migrate] sync_logs migration warning:', migrateErr.message);
    }

    // HU-06: Tabla de notificaciones in-app
    try {
      await db.query(`
        CREATE TABLE IF NOT EXISTS notifications (
          id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
          user_id      UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
          type         VARCHAR(50) NOT NULL DEFAULT 'bank_sync',
          title        VARCHAR(255) NOT NULL,
          body         TEXT NOT NULL,
          metadata     JSONB,
          read_at      TIMESTAMP,
          created_at   TIMESTAMP NOT NULL DEFAULT NOW()
        );
        CREATE INDEX IF NOT EXISTS idx_notifications_user_id  ON notifications(user_id);
        CREATE INDEX IF NOT EXISTS idx_notifications_read_at  ON notifications(user_id, read_at) WHERE read_at IS NULL;
        CREATE INDEX IF NOT EXISTS idx_notifications_created  ON notifications(created_at DESC);
      `);
      console.log('[auto-migrate] ✓ notifications table (HU-06)');
    } catch (migrateErr) {
      console.warn('[auto-migrate] notifications migration warning:', migrateErr.message);
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

    // RNF-05: Expiración automática de consentimientos PSD2 (diario a las 3am)
    // Marca como 'expired' los consentimientos que han superado su fecha de vencimiento.
    cron.schedule('0 3 * * *', async () => {
      console.log(`[RNF-05][cron] Verificando consentimientos PSD2 expirados — ${new Date().toISOString()}`);
      try {
        const result = await db.query(
          `UPDATE psd2_consents
           SET status = 'expired', updated_at = NOW()
           WHERE status = 'active' AND expires_at < NOW()
           RETURNING connection_id`
        );
        if (result.rows.length > 0) {
          console.log(`[RNF-05][cron] ${result.rows.length} consentimientos marcados como expirados`);
        }
      } catch (err) {
        console.error('[RNF-05][cron] Error al verificar consentimientos:', err.message);
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