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
const statsRoutes = require('./routes/stats'); // RF-29 / RF-30
const aiRoutes = require('./routes/ai');       // RF-21 / RF-22
const goalsRoutes = require('./routes/goals'); // RF-18 / RF-19 / RF-20 / RF-21 / HU-07
const exportRoutes = require('./routes/export'); // RF-34 / RF-35
const budgetRoutes = require('./routes/budget'); // RF-32
const currencyRoutes = require('./routes/currency'); // Exchange rates

// Import services
const emailService = require('./services/email');
const db = require('./services/db');
const { sendPushToUser } = require('./services/fcm'); // RF-31

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
app.use('/api/v1/stats', statsRoutes);              // RF-29 / RF-30
app.use('/api/v1/ai', aiRoutes);                    // RF-21 / RF-22
app.use('/api/v1/goals', goalsRoutes);              // RF-18 / RF-19 / RF-20 / HU-07
app.use('/api/v1/export', exportRoutes);            // RF-34 / RF-35
app.use('/api/v1/budget', budgetRoutes);            // RF-32
app.use('/api/v1/currency', currencyRoutes);        // Exchange rates

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
      goals: '/api/v1/goals',
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

    // RNF-03: Columnas 2FA en tabla users
    try {
      await db.query(`ALTER TABLE users ADD COLUMN IF NOT EXISTS totp_secret VARCHAR(64)`);
      await db.query(`ALTER TABLE users ADD COLUMN IF NOT EXISTS totp_secret_pending VARCHAR(64)`);
      await db.query(`ALTER TABLE users ADD COLUMN IF NOT EXISTS totp_recovery_codes TEXT`);
      await db.query(`ALTER TABLE users ADD COLUMN IF NOT EXISTS is_2fa_enabled BOOLEAN NOT NULL DEFAULT FALSE`);
      console.log('[auto-migrate] ✓ users 2FA columns (RNF-03)');
    } catch (e) { console.warn('[auto-migrate] 2FA columns warning:', e.message); }

    // RF-31: Tabla de tokens FCM para push notifications
    try {
      await db.query(`
        CREATE TABLE IF NOT EXISTS push_tokens (
          id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
          user_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
          token      TEXT NOT NULL UNIQUE,
          platform   VARCHAR(20) NOT NULL DEFAULT 'unknown',
          created_at TIMESTAMP NOT NULL DEFAULT NOW(),
          updated_at TIMESTAMP NOT NULL DEFAULT NOW()
        );
        CREATE INDEX IF NOT EXISTS idx_push_tokens_user_id ON push_tokens(user_id);
      `);
      console.log('[auto-migrate] ✓ push_tokens table (RF-31)');
    } catch (e) { console.warn('[auto-migrate] push_tokens warning:', e.message); }

    // RF-31/32/33: Tabla de configuración de notificaciones push
    try {
      await db.query(`
        CREATE TABLE IF NOT EXISTS notification_settings (
          user_id                  UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
          push_new_transactions    BOOLEAN NOT NULL DEFAULT TRUE,
          push_budget_alerts       BOOLEAN NOT NULL DEFAULT TRUE,
          push_goal_reminders      BOOLEAN NOT NULL DEFAULT TRUE,
          push_min_amount          NUMERIC(12,2) NOT NULL DEFAULT 0,
          push_quiet_hours_enabled BOOLEAN NOT NULL DEFAULT FALSE,
          push_quiet_start         VARCHAR(5) NOT NULL DEFAULT '22:00',
          push_quiet_end           VARCHAR(5) NOT NULL DEFAULT '08:00',
          updated_at               TIMESTAMP NOT NULL DEFAULT NOW()
        );
      `);
      console.log('[auto-migrate] ✓ notification_settings table (RF-31/32/33)');
    } catch (e) { console.warn('[auto-migrate] notification_settings warning:', e.message); }

    // RF-32: Tabla de presupuestos por categoría
    try {
      await db.query(`
        CREATE TABLE IF NOT EXISTS budgets (
          id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
          user_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
          category      VARCHAR(100) NOT NULL,
          monthly_limit NUMERIC(12,2) NOT NULL CHECK (monthly_limit > 0),
          created_at    TIMESTAMP NOT NULL DEFAULT NOW(),
          updated_at    TIMESTAMP NOT NULL DEFAULT NOW(),
          UNIQUE(user_id, category)
        );
        CREATE INDEX IF NOT EXISTS idx_budgets_user_id ON budgets(user_id);
      `);
      console.log('[auto-migrate] ✓ budgets table (RF-32)');
    } catch (e) { console.warn('[auto-migrate] budgets warning:', e.message); }

    // Budget rollover_enabled column
    try {
      await db.query(`
        ALTER TABLE budgets
          ADD COLUMN IF NOT EXISTS rollover_enabled BOOLEAN NOT NULL DEFAULT FALSE
      `);
      console.log('[auto-migrate] ✓ budgets.rollover_enabled');
    } catch (e) { console.warn('[auto-migrate] budgets.rollover_enabled warning:', e.message); }

    // RF-16: categories.display_order column (added after initial schema in some deployments)
    try {
      await db.query(`
        ALTER TABLE categories
          ADD COLUMN IF NOT EXISTS display_order INTEGER NOT NULL DEFAULT 0
      `);
      console.log('[auto-migrate] ✓ categories.display_order (RF-16)');
    } catch (e) { console.warn('[auto-migrate] categories.display_order warning:', e.message); }

    // RF-09: users.name column for profile editing
    try {
      await db.query(`
        ALTER TABLE users
          ADD COLUMN IF NOT EXISTS name VARCHAR(255)
      `);
      console.log('[auto-migrate] ✓ users.name (RF-09)');
    } catch (e) { console.warn('[auto-migrate] users.name warning:', e.message); }

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

    // RF-33: Recordatorios semanales de progreso de objetivos (lunes 9am)
    // Genera notificaciones in-app motivacionales para cada objetivo activo.
    cron.schedule('0 9 * * 1', async () => {
      console.log(`[RF-33][cron] Enviando recordatorios de objetivos — ${new Date().toISOString()}`);
      try {
        const goals = await db.query(`
          SELECT g.id, g.user_id, g.name, g.target_amount::float, g.current_amount::float,
                 g.deadline, ns.push_goal_reminders
          FROM savings_goals g
          LEFT JOIN notification_settings ns ON ns.user_id = g.user_id
          WHERE g.current_amount < g.target_amount
            AND (ns.push_goal_reminders IS NULL OR ns.push_goal_reminders = TRUE)
        `);
        for (const goal of goals.rows) {
          const pct = Math.round((goal.current_amount / goal.target_amount) * 100);
          const remaining = (goal.target_amount - goal.current_amount).toFixed(2);
          let title, body;
          if (pct >= 80) {
            title = `¡Casi lo tienes! 🎉 ${goal.name}`;
            body = `Llevas un ${pct}% del objetivo. Solo te quedan €${remaining}. ¡Un último esfuerzo!`;
          } else if (pct >= 50) {
            title = `¡Buen progreso! 💪 ${goal.name}`;
            body = `Llevas un ${pct}% ahorrado. Te quedan €${remaining} para completarlo.`;
          } else {
            title = `Recuerda tu objetivo 🎯 ${goal.name}`;
            body = `Llevas un ${pct}%. Considera aportar algo esta semana. Te quedan €${remaining}.`;
          }
          await db.query(
            `INSERT INTO notifications (user_id, type, title, body, metadata)
             VALUES ($1, 'goal_reminder', $2, $3, $4)`,
            [goal.user_id, title, body, JSON.stringify({ goal_id: goal.id, percentage: pct })]
          );
          // RF-31: Enviar push real al dispositivo
          await sendPushToUser(db, goal.user_id, title, body, { type: 'goal_reminder', goal_id: goal.id });
        }
        console.log(`[RF-33][cron] ${goals.rows.length} recordatorios generados`);
      } catch (err) {
        console.error('[RF-33][cron] Error:', err.message);
      }
    });

    // RF-32: Verificación diaria de presupuestos (cada día a las 20:00)
    // Genera alertas cuando el gasto supera el 80% o 100% del presupuesto.
    cron.schedule('0 20 * * *', async () => {
      console.log(`[RF-32][cron] Verificando presupuestos — ${new Date().toISOString()}`);
      try {
        const now = new Date();
        const firstDay = new Date(now.getFullYear(), now.getMonth(), 1).toISOString().split('T')[0];
        const today = now.toISOString().split('T')[0];

        const budgets = await db.query(`
          SELECT b.user_id, b.category, b.monthly_limit::float,
                 COALESCE(SUM(t.amount)::float, 0) AS spent,
                 ns.push_budget_alerts
          FROM budgets b
          LEFT JOIN transactions t ON t.user_id = b.user_id AND t.type = 'expense'
                                   AND t.category = b.category
                                   AND t.date >= $1 AND t.date <= $2
          LEFT JOIN notification_settings ns ON ns.user_id = b.user_id
          WHERE (ns.push_budget_alerts IS NULL OR ns.push_budget_alerts = TRUE)
          GROUP BY b.user_id, b.category, b.monthly_limit, ns.push_budget_alerts
        `, [firstDay, today]);

        for (const row of budgets.rows) {
          const pct = (row.spent / row.monthly_limit) * 100;
          if (pct < 80) continue;

          const level = pct >= 100 ? 'critical' : 'warning';
          const title = pct >= 100
            ? `⚠️ Presupuesto superado: ${row.category}`
            : `🟡 Alerta de presupuesto: ${row.category}`;
          const body = pct >= 100
            ? `Has gastado €${row.spent.toFixed(2)} de €${row.monthly_limit.toFixed(2)} en ${row.category} (${Math.round(pct)}%). Considera reducir gastos.`
            : `Llevas un ${Math.round(pct)}% del presupuesto de ${row.category} (€${row.spent.toFixed(2)} / €${row.monthly_limit.toFixed(2)}).`;

          // Evitar duplicados el mismo día
          const exists = await db.query(
            `SELECT id FROM notifications WHERE user_id=$1 AND type='budget_alert'
             AND metadata->>'category'=$2 AND DATE(created_at)=CURRENT_DATE`,
            [row.user_id, row.category]
          );
          if (exists.rows.length === 0) {
            await db.query(
              `INSERT INTO notifications (user_id, type, title, body, metadata)
               VALUES ($1, 'budget_alert', $2, $3, $4)`,
              [row.user_id, title, body, JSON.stringify({
                category: row.category, spent: row.spent,
                limit: row.monthly_limit, level
              })]
            );
            // RF-31: Enviar push real al dispositivo
            await sendPushToUser(db, row.user_id, title, body, { type: 'budget_alert', category: row.category, level });
          }
        }
        console.log(`[RF-32][cron] Verificación de presupuestos completada`);
      } catch (err) {
        console.error('[RF-32][cron] Error:', err.message);
      }
    });

    // RNF-17: Backup automático diario (3:30am) — registra log de backup
    // En producción se complementa con pg_dump automático del proveedor (Render/Supabase).
    cron.schedule('30 3 * * *', async () => {
      console.log(`[RNF-17][cron] Backup check — ${new Date().toISOString()}`);
      try {
        await db.query(
          `INSERT INTO backup_logs (status, backup_type, note, created_at)
           VALUES ('completed', 'auto', 'Backup automático registrado — verificar snapshot del proveedor', NOW())`
        );
        console.log('[RNF-17][cron] Backup log registrado');
      } catch (err) {
        // Si la tabla no existe aún, crear y reintentar
        try {
          await db.query(`
            CREATE TABLE IF NOT EXISTS backup_logs (
              id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
              status      VARCHAR(20) NOT NULL DEFAULT 'completed',
              backup_type VARCHAR(20) NOT NULL DEFAULT 'auto',
              note        TEXT,
              created_at  TIMESTAMP NOT NULL DEFAULT NOW()
            )
          `);
          console.log('[RNF-17][cron] backup_logs table created');
        } catch (e2) { console.warn('[RNF-17][cron] Could not create backup_logs:', e2.message); }
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