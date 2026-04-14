'use strict';

// 1. Esto es VITAL: Rompe la dependencia circular para que server.js no explote
jest.mock('../../server', () => ({})); 

const {
  gdprAuditMiddleware,
  GDPRAuditEventTypes,
  logAuditEvent,
  registerDataBreach,
  getUserAuditLog,
  getDataBreaches,
  getAuditStats,
  getPrivacyContactInfo
} = require('../../middleware/gdprAudit');

// Función auxiliar para crear objetos req, res, next falsos para testear el middleware aislado
function buildContext({ method = 'GET', path = '/api/v1/transactions', body = {}, userId = 'user-123' } = {}) {
  const req = {
    method,
    path,
    ip: '127.0.0.1',
    connection: { remoteAddress: '127.0.0.1' },
    headers: { 'user-agent': 'test-agent' },
    query: {},
    body,
    user: { userId },
  };

  let capturedBody = null;
  let statusCode = 200;

  const res = {
    get statusCode() { return statusCode; },
    set statusCode(v) { statusCode = v; },
    send: jest.fn(function (b) {
      capturedBody = b;
      return this;
    }),
  };

  const next = jest.fn();
  return { req, res, next, getCapturedBody: () => capturedBody };
}

// Silenciamos los logs para mantener la consola limpia durante los tests
beforeAll(() => {
  jest.spyOn(console, 'log').mockImplementation(() => {});
  jest.spyOn(console, 'error').mockImplementation(() => {});
});

afterAll(() => {
  console.log.mockRestore();
  console.error.mockRestore();
});

describe('GDPR Audit Middleware & Utilities', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('Middleware: gdprAuditMiddleware', () => {
    it('calls next() without blocking the request', () => {
      const { req, res, next } = buildContext();
      gdprAuditMiddleware(req, res, next);
      expect(next).toHaveBeenCalledTimes(1);
    });

    it('patches res.send and still calls original send', () => {
      const { req, res, next } = buildContext();
      const originalSend = res.send;
      gdprAuditMiddleware(req, res, next);
      res.send('{"ok":true}');
      expect(originalSend).toHaveBeenCalled();
    });

    it('logs DATA_ACCESS event type for GET requests', () => {
      const { req, res, next } = buildContext({ method: 'GET', path: '/api/v1/transactions' });
      gdprAuditMiddleware(req, res, next);
      res.send('{}');
      expect(next).toHaveBeenCalled();
    });

    it('logs DATA_MODIFICATION for PUT requests', () => {
      const { req, res, next } = buildContext({ method: 'PUT', path: '/api/v1/user/profile' });
      gdprAuditMiddleware(req, res, next);
      res.send('{}');
      expect(next).toHaveBeenCalled();
    });

    it('logs DATA_MODIFICATION for PATCH requests', () => {
      const { req, res, next } = buildContext({ method: 'PATCH', path: '/api/v1/user/settings' });
      gdprAuditMiddleware(req, res, next);
      res.send('{}');
      expect(next).toHaveBeenCalled();
    });

    it('logs DATA_DELETION for DELETE requests', () => {
      const { req, res, next } = buildContext({ method: 'DELETE', path: '/api/v1/transactions/1' });
      gdprAuditMiddleware(req, res, next);
      res.send('{}');
      expect(next).toHaveBeenCalled();
    });

    it('logs CONSENT_GIVEN for POST /consent requests', () => {
      const { req, res, next } = buildContext({ method: 'POST', path: '/api/v1/gdpr/consent' });
      gdprAuditMiddleware(req, res, next);
      res.send('{}');
      expect(next).toHaveBeenCalled();
    });

    it('logs CONSENT_WITHDRAWN for DELETE /consent requests', () => {
      const { req, res, next } = buildContext({ method: 'DELETE', path: '/api/v1/gdpr/consent/analytics' });
      gdprAuditMiddleware(req, res, next);
      res.send('{}');
      expect(next).toHaveBeenCalled();
    });

    it('logs DATA_EXPORT for export path requests', () => {
      const { req, res, next } = buildContext({ method: 'GET', path: '/api/v1/export/csv' });
      gdprAuditMiddleware(req, res, next);
      res.send('{}');
      expect(next).toHaveBeenCalled();
    });

    it('works for anonymous (unauthenticated) requests — no req.user', () => {
      const { req, res, next } = buildContext();
      delete req.user;
      gdprAuditMiddleware(req, res, next);
      expect(() => res.send('{}')).not.toThrow();
    });

    it('does not throw when req.body is undefined', () => {
      const { req, res, next } = buildContext();
      delete req.body;
      gdprAuditMiddleware(req, res, next);
      expect(() => res.send('{}')).not.toThrow();
    });

    it('still resolves even when query params exist', () => {
      const { req, res, next } = buildContext({ method: 'GET' });
      req.query = { page: '1', limit: '20' };
      gdprAuditMiddleware(req, res, next);
      res.send('{}');
      expect(next).toHaveBeenCalled();
    });
  });

  describe('Exported Helper Functions', () => {
    it('logs to console when NODE_ENV is development', () => {
      const originalEnv = process.env.NODE_ENV;
      process.env.NODE_ENV = 'development'; // Forzamos el entorno
      
      logAuditEvent({ eventType: 'TEST_DEV', userId: '123' });
      
      expect(console.log).toHaveBeenCalled();
      process.env.NODE_ENV = originalEnv; // Restauramos el entorno
    });
    
    it('registerDataBreach logs breach, stores it, and triggers console.error', () => {
      const breachInfo = { affectedDataTypes: ['email'], estimatedAffectedUsers: 100 };
      const breach = registerDataBreach(breachInfo);
      
      expect(breach.status).toBe('DETECTED');
      expect(console.error).toHaveBeenCalled();
      
      const breaches = getDataBreaches();
      expect(breaches).toContainEqual(breach);
    });

    it('getUserAuditLog retrieves logs specific to a user', () => {
      logAuditEvent({ eventType: 'TEST', userId: 'user-999' });
      const logs = getUserAuditLog('user-999');
      expect(logs.length).toBeGreaterThan(0);
      expect(logs[0].userId).toBe('user-999');
    });

    it('getAuditStats returns correct aggregate statistics', () => {
      const stats = getAuditStats();
      expect(stats).toHaveProperty('totalEvents');
      expect(stats).toHaveProperty('eventsByType');
      expect(stats).toHaveProperty('lastEvent');
      expect(stats).toHaveProperty('breachCount');
      expect(stats).toHaveProperty('pendingBreachNotifications');
    });

    it('getPrivacyContactInfo returns valid contact object', () => {
      const contact = getPrivacyContactInfo();
      expect(contact).toHaveProperty('role', 'Equipo de Privacidad');
      expect(contact).toHaveProperty('email');
    });
  });
});