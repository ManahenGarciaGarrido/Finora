'use strict';

jest.mock('../../services/db', () => require('../helpers/mockDb'));
jest.mock('../../services/email', () => ({
  sendVerificationEmail: jest.fn().mockResolvedValue({ success: true }),
  verifyConnection: jest.fn().mockResolvedValue(true),
}));

const request = require('supertest');
const app = require('../../server');
const db = require('../../services/db');
const { createTestToken } = require('../helpers/testHelpers');

const token = createTestToken(42, 'user@example.com');
const authHeader = `Bearer ${token}`;

function makePoolClient(queryImpl) {
  const client = {
    query: queryImpl || jest.fn().mockResolvedValue({ rows: [] }),
    release: jest.fn(),
  };
  return client;
}

beforeAll(() => {
  jest.spyOn(console, 'error').mockImplementation(() => {});
  jest.spyOn(console, 'log').mockImplementation(() => {});
});

afterAll(() => {
  console.error.mockRestore();
  console.log.mockRestore();
});

describe('GDPR Routes', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  // ── GET /api/v1/gdpr/privacy-policy ──────────────────────────────────────
  describe('GET /api/v1/gdpr/privacy-policy', () => {
    it('returns 200 with privacy policy (no auth required)', async () => {
      const res = await request(app).get('/api/v1/gdpr/privacy-policy');
      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('privacyPolicy');
      expect(res.body.privacyPolicy).toHaveProperty('version');
      expect(Array.isArray(res.body.privacyPolicy.sections)).toBe(true);
    });
  });

  // ── GET /api/v1/gdpr/consents ─────────────────────────────────────────────
  describe('GET /api/v1/gdpr/consents', () => {
    it('returns 200 with consent type descriptions (no auth required)', async () => {
      const res = await request(app).get('/api/v1/gdpr/consents');
      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('consentTypes');
      expect(res.body.consentTypes).toHaveProperty('essential');
      expect(res.body.consentTypes).toHaveProperty('analytics');
    });
  });

  // ── GET /api/v1/gdpr/consents/user ───────────────────────────────────────
  describe('GET /api/v1/gdpr/consents/user', () => {
    it('returns 401 without auth', async () => {
      const res = await request(app).get('/api/v1/gdpr/consents/user');
      expect(res.status).toBe(401);
    });

    it('returns 401 with invalid token', async () => {
      const res = await request(app)
        .get('/api/v1/gdpr/consents/user')
        .set('Authorization', 'Bearer invalid.token.here');
      expect(res.status).toBe(401);
    });

    it('returns 200 with consents from DB', async () => {
      db.query.mockResolvedValueOnce({
        rows: [
          { consent_type: 'essential', granted: true, updated_at: new Date().toISOString() },
          { consent_type: 'analytics', granted: false, updated_at: new Date().toISOString() },
        ],
        rowCount: 2,
      });

      const res = await request(app)
        .get('/api/v1/gdpr/consents/user')
        .set('Authorization', authHeader);

      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('consents');
      expect(res.body.consents.essential).toBe(true);
      expect(res.body.consents.analytics).toBe(false);
    });

    it('returns 200 with defaults when no consents in DB', async () => {
      db.query.mockResolvedValueOnce({ rows: [], rowCount: 0 });

      const res = await request(app)
        .get('/api/v1/gdpr/consents/user')
        .set('Authorization', authHeader);

      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('consents');
      expect(res.body.consents.essential).toBe(true);
    });

    it('returns 500 on DB error', async () => {
      db.query.mockRejectedValueOnce(new Error('DB Error'));

      const res = await request(app)
        .get('/api/v1/gdpr/consents/user')
        .set('Authorization', authHeader);

      expect(res.status).toBe(500);
    });
  });

  // ── POST /api/v1/gdpr/consents ────────────────────────────────────────────
  describe('POST /api/v1/gdpr/consents', () => {
    it('returns 401 without auth', async () => {
      const res = await request(app)
        .post('/api/v1/gdpr/consents')
        .send({ consents: { essential: true } });
      expect(res.status).toBe(401);
    });

    it('returns 400 when consents body is missing', async () => {
      const res = await request(app)
        .post('/api/v1/gdpr/consents')
        .set('Authorization', authHeader)
        .send({});
      expect(res.status).toBe(400);
    });

    it('returns 400 when consents is not an object', async () => {
      const res = await request(app)
        .post('/api/v1/gdpr/consents')
        .set('Authorization', authHeader)
        .send({ consents: 'yes' });
      expect(res.status).toBe(400);
    });

    it('returns 400 when required consent essential is false', async () => {
      const res = await request(app)
        .post('/api/v1/gdpr/consents')
        .set('Authorization', authHeader)
        .send({ consents: { essential: false, data_processing: true } });
      expect(res.status).toBe(400);
    });

    it('returns 200 when all required consents are given', async () => {
      const mockClient = makePoolClient();
      db.pool.connect.mockResolvedValueOnce(mockClient);

      const res = await request(app)
        .post('/api/v1/gdpr/consents')
        .set('Authorization', authHeader)
        .send({
          consents: {
            essential: true,
            data_processing: true,
            analytics: false,
            marketing: false,
          },
        });

      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('consents');
      expect(mockClient.release).toHaveBeenCalled();
    });

    it('returns 500 and rolls back when DB fails mid-transaction', async () => {
      const mockClient = makePoolClient(
        jest.fn()
          .mockResolvedValueOnce({})                  // BEGIN
          .mockRejectedValueOnce(new Error('DB fail')) // first insert fails
          .mockResolvedValueOnce({})                  // ROLLBACK
      );
      db.pool.connect.mockResolvedValueOnce(mockClient);

      const res = await request(app)
        .post('/api/v1/gdpr/consents')
        .set('Authorization', authHeader)
        .send({ consents: { essential: true, data_processing: true, analytics: true } });

      expect(res.status).toBe(500);
      expect(mockClient.release).toHaveBeenCalled();
    });
  });

  // ── DELETE /api/v1/gdpr/consents/:consentType ─────────────────────────────
  describe('DELETE /api/v1/gdpr/consents/:consentType', () => {
    it('returns 401 without auth', async () => {
      const res = await request(app).delete('/api/v1/gdpr/consents/analytics');
      expect(res.status).toBe(401);
    });

    it('returns 400 for invalid consent type', async () => {
      const res = await request(app)
        .delete('/api/v1/gdpr/consents/invalid-type')
        .set('Authorization', authHeader);
      expect(res.status).toBe(400);
    });

    it('returns 400 when trying to withdraw a required consent', async () => {
      const res = await request(app)
        .delete('/api/v1/gdpr/consents/essential')
        .set('Authorization', authHeader);
      expect(res.status).toBe(400);
    });

    it('returns 200 on successful consent withdrawal', async () => {
      db.query
        .mockResolvedValueOnce({ rows: [], rowCount: 0 })  // upsert current consent
        .mockResolvedValueOnce({ rows: [], rowCount: 1 }); // insert history

      const res = await request(app)
        .delete('/api/v1/gdpr/consents/analytics')
        .set('Authorization', authHeader);

      expect(res.status).toBe(200);
      expect(res.body.message).toMatch(/analytics/i);
    });

    it('returns 500 on DB error', async () => {
      db.query.mockRejectedValueOnce(new Error('DB Error'));

      const res = await request(app)
        .delete('/api/v1/gdpr/consents/analytics')
        .set('Authorization', authHeader);

      expect(res.status).toBe(500);
    });
  });

  // ── GET /api/v1/gdpr/consents/history ────────────────────────────────────
  describe('GET /api/v1/gdpr/consents/history', () => {
    it('returns 401 without auth', async () => {
      const res = await request(app).get('/api/v1/gdpr/consents/history');
      expect(res.status).toBe(401);
    });

    it('returns 200 with consent history list', async () => {
      db.query.mockResolvedValueOnce({
        rows: [
          {
            consent_type: 'analytics',
            granted: true,
            action: 'CONSENT_UPDATED',
            ip_address: '127.0.0.1',
            user_agent: 'jest',
            created_at: new Date().toISOString(),
          },
        ],
        rowCount: 1,
      });

      const res = await request(app)
        .get('/api/v1/gdpr/consents/history')
        .set('Authorization', authHeader);

      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('history');
      expect(Array.isArray(res.body.history)).toBe(true);
      expect(res.body.history[0]).toHaveProperty('consentType');
    });

    it('returns 200 with empty history', async () => {
      db.query.mockResolvedValueOnce({ rows: [], rowCount: 0 });

      const res = await request(app)
        .get('/api/v1/gdpr/consents/history')
        .set('Authorization', authHeader);

      expect(res.status).toBe(200);
      expect(res.body.history).toHaveLength(0);
    });

    it('returns 500 on DB error', async () => {
      db.query.mockRejectedValueOnce(new Error('DB Error'));

      const res = await request(app)
        .get('/api/v1/gdpr/consents/history')
        .set('Authorization', authHeader);

      expect(res.status).toBe(500);
    });
  });

  // ── GET /api/v1/gdpr/export ───────────────────────────────────────────────
  describe('GET /api/v1/gdpr/export', () => {
    it('returns 401 without auth', async () => {
      const res = await request(app).get('/api/v1/gdpr/export');
      expect(res.status).toBe(401);
    });

    it('returns 200 with complete user data export', async () => {
      const user = {
        id: 42, email: 'user@example.com', name: 'Test User',
        email_verified: true, terms_accepted: true, terms_accepted_at: null,
        privacy_accepted: true, privacy_accepted_at: null,
        created_at: new Date().toISOString(), updated_at: new Date().toISOString(),
      };

      db.query
        .mockResolvedValueOnce({ rows: [user], rowCount: 1 })   // SELECT user
        .mockResolvedValueOnce({ rows: [], rowCount: 0 })        // SELECT transactions
        .mockResolvedValueOnce({ rows: [], rowCount: 0 })        // SELECT categories
        .mockResolvedValueOnce({ rows: [], rowCount: 0 })        // SELECT consents_current
        .mockResolvedValueOnce({ rows: [], rowCount: 0 });       // SELECT consents_history

      const res = await request(app)
        .get('/api/v1/gdpr/export')
        .set('Authorization', authHeader);

      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('data');
      expect(res.body.data).toHaveProperty('personalData');
      expect(res.body.data).toHaveProperty('financialData');
      expect(res.body.data).toHaveProperty('consents');
      expect(res.body.data.exportMetadata).toHaveProperty('format', 'json');
    });

    it('returns 404 when user not found in DB', async () => {
      db.query.mockResolvedValueOnce({ rows: [], rowCount: 0 });

      const res = await request(app)
        .get('/api/v1/gdpr/export')
        .set('Authorization', authHeader);

      expect(res.status).toBe(404);
    });

    it('returns 500 on DB error', async () => {
      db.query.mockRejectedValueOnce(new Error('DB Error'));

      const res = await request(app)
        .get('/api/v1/gdpr/export')
        .set('Authorization', authHeader);

      expect(res.status).toBe(500);
    });
  });

  // ── DELETE /api/v1/gdpr/delete-account ───────────────────────────────────
  describe('DELETE /api/v1/gdpr/delete-account', () => {
    it('returns 401 without auth', async () => {
      const res = await request(app)
        .delete('/api/v1/gdpr/delete-account')
        .send({ confirmDeletion: 'DELETE_MY_ACCOUNT' });
      expect(res.status).toBe(401);
    });

    it('returns 400 when confirmDeletion phrase is wrong', async () => {
      const res = await request(app)
        .delete('/api/v1/gdpr/delete-account')
        .set('Authorization', authHeader)
        .send({ confirmDeletion: 'yes please delete' });
      expect(res.status).toBe(400);
    });

    it('returns 400 when confirmDeletion is missing', async () => {
      const res = await request(app)
        .delete('/api/v1/gdpr/delete-account')
        .set('Authorization', authHeader)
        .send({});
      expect(res.status).toBe(400);
    });

    it('returns 200 and deletes account when confirmed correctly', async () => {
      const mockClient = makePoolClient();
      db.pool.connect.mockResolvedValueOnce(mockClient);

      const res = await request(app)
        .delete('/api/v1/gdpr/delete-account')
        .set('Authorization', authHeader)
        .send({ confirmDeletion: 'DELETE_MY_ACCOUNT', reason: 'Testing deletion' });

      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('deletionReceipt');
      expect(res.body.deletionReceipt).toHaveProperty('userId');
      expect(mockClient.release).toHaveBeenCalled();
    });

    it('returns 500 and rolls back when DB fails during deletion', async () => {
      const mockClient = makePoolClient(
        jest.fn()
          .mockResolvedValueOnce({})                     // BEGIN
          .mockRejectedValueOnce(new Error('DB crash'))  // DELETE fails
          .mockResolvedValueOnce({})                     // ROLLBACK
      );
      db.pool.connect.mockResolvedValueOnce(mockClient);

      const res = await request(app)
        .delete('/api/v1/gdpr/delete-account')
        .set('Authorization', authHeader)
        .send({ confirmDeletion: 'DELETE_MY_ACCOUNT' });

      expect(res.status).toBe(500);
      expect(mockClient.release).toHaveBeenCalled();
    });
  });

  // ── GET /api/v1/gdpr/data-processing ─────────────────────────────────────
  describe('GET /api/v1/gdpr/data-processing', () => {
    it('returns 200 with data processing info (no auth required)', async () => {
      const res = await request(app).get('/api/v1/gdpr/data-processing');
      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('dataProcessing');
      expect(Array.isArray(res.body.dataProcessing.purposes)).toBe(true);
      expect(res.body.dataProcessing).toHaveProperty('thirdParties');
    });
  });

  // ── GET /api/v1/gdpr/audit/stats ─────────────────────────────────────────
  describe('GET /api/v1/gdpr/audit/stats', () => {
    it('returns 401 without auth', async () => {
      const res = await request(app).get('/api/v1/gdpr/audit/stats');
      expect(res.status).toBe(401);
    });

    it('returns 200 with audit statistics', async () => {
      const res = await request(app)
        .get('/api/v1/gdpr/audit/stats')
        .set('Authorization', authHeader);

      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('stats');
    });
  });
});
