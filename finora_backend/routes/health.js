const express = require('express');
const router = express.Router();
const db = require('../services/db');
const emailService = require('../services/email');

// Health check endpoint
router.get('/', async (req, res) => {
  try {
    // Quick database check
    const dbHealth = await db.healthCheck();

    const isHealthy = dbHealth.status === 'healthy';

    res.status(isHealthy ? 200 : 503).json({
      status: isHealthy ? 'healthy' : 'degraded',
      uptime: process.uptime(),
      timestamp: new Date().toISOString(),
      environment: process.env.NODE_ENV || 'development',
      version: '1.0.0',
      database: dbHealth.status
    });
  } catch (error) {
    res.status(503).json({
      status: 'unhealthy',
      uptime: process.uptime(),
      timestamp: new Date().toISOString(),
      error: error.message
    });
  }
});

// Detailed health check
router.get('/detailed', async (req, res) => {
  try {
    // Database health
    const dbHealth = await db.healthCheck();

    // Email service health
    let emailHealth = { status: 'unknown' };
    try {
      const emailReady = await emailService.verifyConnection();
      emailHealth = { status: emailReady ? 'healthy' : 'unhealthy' };
    } catch (e) {
      emailHealth = { status: 'unhealthy', error: e.message };
    }

    const isHealthy = dbHealth.status === 'healthy';

    res.status(isHealthy ? 200 : 503).json({
      status: isHealthy ? 'healthy' : 'degraded',
      uptime: process.uptime(),
      timestamp: new Date().toISOString(),
      environment: process.env.NODE_ENV || 'development',
      version: '1.0.0',
      services: {
        database: dbHealth,
        email: emailHealth
      },
      memory: {
        used: `${Math.round(process.memoryUsage().heapUsed / 1024 / 1024)}MB`,
        total: `${Math.round(process.memoryUsage().heapTotal / 1024 / 1024)}MB`
      },
      cpu: process.cpuUsage(),
      platform: process.platform,
      nodeVersion: process.version
    });
  } catch (error) {
    res.status(503).json({
      status: 'unhealthy',
      uptime: process.uptime(),
      timestamp: new Date().toISOString(),
      error: error.message
    });
  }
});

// Readiness check (for Kubernetes/Docker)
router.get('/ready', async (req, res) => {
  try {
    const dbHealth = await db.healthCheck();
    if (dbHealth.status === 'healthy') {
      res.status(200).json({ ready: true });
    } else {
      res.status(503).json({ ready: false, reason: 'Database not ready' });
    }
  } catch (error) {
    res.status(503).json({ ready: false, reason: error.message });
  }
});

// Liveness check (for Kubernetes/Docker)
router.get('/live', (req, res) => {
  res.status(200).json({ alive: true });
});

/**
 * GET /health/status
 * RNF-14: Endpoint de estado del sistema para monitoreo externo (UptimeRobot, etc.)
 * Devuelve métricas clave de disponibilidad y rendimiento.
 */
router.get('/status', async (req, res) => {
  try {
    const dbHealth = await db.healthCheck();
    const memUsage = process.memoryUsage();
    const memMB = Math.round(memUsage.heapUsed / 1024 / 1024);

    // RNF-09: Verificar consumo de memoria (umbral: 150MB)
    const memOk = memMB < 150;
    const isHealthy = dbHealth.status === 'healthy';

    res.status(isHealthy ? 200 : 503).json({
      status: isHealthy ? 'operational' : 'degraded',
      uptime_seconds: Math.round(process.uptime()),
      uptime_human: _formatUptime(process.uptime()),
      timestamp: new Date().toISOString(),
      version: '1.0.0',
      checks: {
        database: { status: dbHealth.status === 'healthy' ? 'pass' : 'fail' },
        memory: {
          status: memOk ? 'pass' : 'warn',
          used_mb: memMB,
          threshold_mb: 150,
        },
      },
      // RNF-14: Métricas de disponibilidad
      availability: {
        target_uptime_pct: 99,
        max_downtime_hours_per_year: 87.6,
        monitoring_url: 'https://stats.uptimerobot.com/finora',
      },
    });
  } catch (err) {
    res.status(503).json({
      status: 'critical',
      timestamp: new Date().toISOString(),
      error: err.message,
    });
  }
});

/** Formatea segundos en formato legible: "2d 3h 15m 4s" */
function _formatUptime(seconds) {
  const d = Math.floor(seconds / 86400);
  const h = Math.floor((seconds % 86400) / 3600);
  const m = Math.floor((seconds % 3600) / 60);
  const s = Math.floor(seconds % 60);
  return [d && `${d}d`, h && `${h}h`, m && `${m}m`, `${s}s`].filter(Boolean).join(' ');
}

module.exports = router;
