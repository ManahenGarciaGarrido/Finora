'use strict';

jest.mock('../../services/db', () => require('../helpers/mockDb'));
jest.mock('../../services/email', () => ({
  verifyConnection: jest.fn().mockResolvedValue(true),
  sendVerificationEmail: jest.fn().mockResolvedValue({ success: true }),
}));

const request = require('supertest');
const app = require('../../server');
const db = require('../../services/db');
const emailService = require('../../services/email');

describe('GET /health', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('GET /health', () => {
    it('returns 200 with status healthy when DB is up', async () => {
      db.healthCheck.mockResolvedValueOnce({ status: 'healthy', timestamp: new Date() });

      const res = await request(app).get('/health');
      expect(res.status).toBe(200);
      expect(res.body.status).toBe('healthy');
      expect(res.body).toHaveProperty('uptime');
      expect(res.body).toHaveProperty('version');
      expect(res.body.database).toBe('healthy');
    });

    it('returns 503 with status degraded when DB is down', async () => {
      db.healthCheck.mockResolvedValueOnce({ status: 'unhealthy', error: 'connection refused' });

      const res = await request(app).get('/health');
      expect(res.status).toBe(503);
      expect(res.body.status).toBe('degraded');
    });

    it('returns 503 when healthCheck throws', async () => {
      db.healthCheck.mockRejectedValueOnce(new Error('DB timeout'));

      const res = await request(app).get('/health');
      expect(res.status).toBe(503);
      expect(res.body.status).toBe('unhealthy');
    });
  });

  describe('GET /health/detailed', () => {
    it('returns 200 with services info when DB is up', async () => {
      db.healthCheck.mockResolvedValueOnce({ status: 'healthy', timestamp: new Date() });

      const res = await request(app).get('/health/detailed');
      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('services');
      expect(res.body.services).toHaveProperty('database');
      expect(res.body.services).toHaveProperty('email');
      expect(res.body.services.email.status).toBe('healthy');
      expect(res.body).toHaveProperty('memory');
      expect(res.body).toHaveProperty('nodeVersion');
    });

    it('returns 200 but email status unhealthy if email service resolves false', async () => {
      db.healthCheck.mockResolvedValueOnce({ status: 'healthy', timestamp: new Date() });
      emailService.verifyConnection.mockResolvedValueOnce(false);

      const res = await request(app).get('/health/detailed');
      expect(res.status).toBe(200);
      expect(res.body.services.email.status).toBe('unhealthy');
    });

    it('returns 200 but email status unhealthy if email service throws', async () => {
      db.healthCheck.mockResolvedValueOnce({ status: 'healthy', timestamp: new Date() });
      emailService.verifyConnection.mockRejectedValueOnce(new Error('SMTP down'));

      const res = await request(app).get('/health/detailed');
      expect(res.status).toBe(200);
      expect(res.body.services.email.status).toBe('unhealthy');
      expect(res.body.services.email.error).toBe('SMTP down');
    });

    it('returns 503 when DB is down in detailed check', async () => {
      db.healthCheck.mockResolvedValueOnce({ status: 'unhealthy', error: 'no connection' });

      const res = await request(app).get('/health/detailed');
      expect(res.status).toBe(503);
      expect(res.body.status).toBe('degraded');
    });

    it('returns 503 when db.healthCheck throws critically', async () => {
      db.healthCheck.mockRejectedValueOnce(new Error('Critical crash'));

      const res = await request(app).get('/health/detailed');
      expect(res.status).toBe(503);
      expect(res.body.status).toBe('unhealthy');
      expect(res.body.error).toBe('Critical crash');
    });
  });

  describe('GET /health/ready', () => {
    it('returns 200 with ready: true when DB is healthy', async () => {
      db.healthCheck.mockResolvedValueOnce({ status: 'healthy', timestamp: new Date() });

      const res = await request(app).get('/health/ready');
      expect(res.status).toBe(200);
      expect(res.body.ready).toBe(true);
    });

    it('returns 503 with ready: false when DB is not healthy', async () => {
      db.healthCheck.mockResolvedValueOnce({ status: 'unhealthy', error: 'down' });

      const res = await request(app).get('/health/ready');
      expect(res.status).toBe(503);
      expect(res.body.ready).toBe(false);
      expect(res.body.reason).toBe('Database not ready');
    });

    it('returns 503 with ready: false when DB check throws', async () => {
      db.healthCheck.mockRejectedValueOnce(new Error('Timeout'));

      const res = await request(app).get('/health/ready');
      expect(res.status).toBe(503);
      expect(res.body.ready).toBe(false);
      expect(res.body.reason).toBe('Timeout');
    });
  });

  describe('GET /health/live', () => {
    it('returns 200 with alive: true (no DB check)', async () => {
      const res = await request(app).get('/health/live');
      expect(res.status).toBe(200);
      expect(res.body.alive).toBe(true);
    });
  });

  describe('GET /health/status', () => {
    it('returns 200 with operational status when DB is up and memory is fine', async () => {
      db.healthCheck.mockResolvedValueOnce({ status: 'healthy', timestamp: new Date() });
      
      // Mockear la memoria para que sea baja (< 150MB)
      jest.spyOn(process, 'memoryUsage').mockReturnValueOnce({ heapUsed: 50 * 1024 * 1024 });

      const res = await request(app).get('/health/status');
      expect(res.status).toBe(200);
      expect(res.body.status).toBe('operational');
      expect(res.body.checks.database.status).toBe('pass');
      expect(res.body.checks.memory.status).toBe('pass');
      expect(res.body.uptime_human).toBeDefined();
    });

    it('returns 200 but memory status warn when memory > 150MB', async () => {
      db.healthCheck.mockResolvedValueOnce({ status: 'healthy', timestamp: new Date() });
      
      // Mockear la memoria para que sea alta (200MB)
      jest.spyOn(process, 'memoryUsage').mockReturnValueOnce({ heapUsed: 200 * 1024 * 1024 });

      const res = await request(app).get('/health/status');
      expect(res.status).toBe(200);
      expect(res.body.checks.memory.status).toBe('warn');
    });

    it('returns 503 degraded when DB is down', async () => {
      db.healthCheck.mockResolvedValueOnce({ status: 'unhealthy', timestamp: new Date() });
      
      const res = await request(app).get('/health/status');
      expect(res.status).toBe(503);
      expect(res.body.status).toBe('degraded');
      expect(res.body.checks.database.status).toBe('fail');
    });

    it('returns 503 critical when healthCheck throws', async () => {
      db.healthCheck.mockRejectedValueOnce(new Error('Crash'));
      
      const res = await request(app).get('/health/status');
      expect(res.status).toBe(503);
      expect(res.body.status).toBe('critical');
      expect(res.body.error).toBe('Crash');
    });

    it('formats uptime correctly for long durations (more than a day)', async () => {
      db.healthCheck.mockResolvedValueOnce({ status: 'healthy', timestamp: new Date() });
      
      // 1 day + 2 hours + 3 mins + 4 seconds = 86400 + 7200 + 180 + 4 = 93784
      jest.spyOn(process, 'uptime').mockReturnValue(93784);

      const res = await request(app).get('/health/status');
      expect(res.status).toBe(200);
      expect(res.body.uptime_human).toBe('1d 2h 3m 4s');

      process.uptime.mockRestore();
    });
  });
});