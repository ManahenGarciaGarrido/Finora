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

module.exports = router;
