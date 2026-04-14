'use strict';

jest.mock('../../services/db', () => require('../helpers/mockDb'));
jest.mock('../../services/email', () => ({
  sendVerificationEmail: jest.fn().mockResolvedValue({ success: true }),
  verifyConnection: jest.fn().mockResolvedValue(true),
}));

const bcrypt = require('bcryptjs');
const request = require('supertest');
const app = require('../../server');
const db = require('../../services/db');
const { createTestToken } = require('../helpers/testHelpers');

const token = createTestToken(42, 'user@example.com');
const authHeader = `Bearer ${token}`;

beforeAll(() => {
  jest.spyOn(console, 'error').mockImplementation(() => {});
});

afterAll(() => {
  console.error.mockRestore();
});

describe('User Routes', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  // ── GET /api/v1/user/profile ──────────────────────────────────────────────
  describe('GET /api/v1/user/profile', () => {
    it('returns 401 without auth', async () => {
      const res = await request(app).get('/api/v1/user/profile');
      expect(res.status).toBe(401);
    });

    it('returns 200 with user data', async () => {
      db.query.mockResolvedValueOnce({
        rows: [{
          id: 42,
          email: 'user@example.com',
          name: 'Test User',
          photo_base64: null,
          created_at: new Date().toISOString(),
        }],
        rowCount: 1,
      });

      const res = await request(app)
        .get('/api/v1/user/profile')
        .set('Authorization', authHeader);

      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('user');
      expect(res.body.user).toHaveProperty('email', 'user@example.com');
      expect(res.body.user).toHaveProperty('name', 'Test User');
    });

    it('returns 404 when user not found in DB', async () => {
      db.query.mockResolvedValueOnce({ rows: [], rowCount: 0 });

      const res = await request(app)
        .get('/api/v1/user/profile')
        .set('Authorization', authHeader);

      expect(res.status).toBe(404);
    });

    it('returns 500 on DB error', async () => {
      db.query.mockRejectedValueOnce(new Error('DB Failed'));
      const res = await request(app).get('/api/v1/user/profile').set('Authorization', authHeader);
      expect(res.status).toBe(500);
    });
  });

  // ── PUT /api/v1/user/profile ──────────────────────────────────────────────
  describe('PUT /api/v1/user/profile', () => {
    it('returns 200 when updating name', async () => {
      db.query.mockResolvedValueOnce({
        rows: [{
          id: 42,
          email: 'user@example.com',
          name: 'Updated Name',
        }],
        rowCount: 1,
      });

      const res = await request(app)
        .put('/api/v1/user/profile')
        .set('Authorization', authHeader)
        .send({ name: 'Updated Name' });

      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('user');
      expect(res.body.user.name).toBe('Updated Name');
    });

    it('returns 404 when user not found during update', async () => {
      db.query.mockResolvedValueOnce({ rows: [], rowCount: 0 }); // UPDATE returns 0 rows

      const res = await request(app)
        .put('/api/v1/user/profile')
        .set('Authorization', authHeader)
        .send({ name: 'Updated Name' });

      expect(res.status).toBe(404);
    });

    it('returns 400 when name is empty or missing', async () => {
      const res1 = await request(app).put('/api/v1/user/profile').set('Authorization', authHeader).send({ name: '' });
      expect(res1.status).toBe(400);

      const res2 = await request(app).put('/api/v1/user/profile').set('Authorization', authHeader).send({});
      expect(res2.status).toBe(400);
    });

    it('returns 400 when name is too long', async () => {
      const res = await request(app)
        .put('/api/v1/user/profile')
        .set('Authorization', authHeader)
        .send({ name: 'A'.repeat(256) });
      expect(res.status).toBe(400);
    });

    it('returns 500 on DB error', async () => {
      db.query.mockRejectedValueOnce(new Error('DB Failed'));
      const res = await request(app).put('/api/v1/user/profile').set('Authorization', authHeader).send({ name: 'Test' });
      expect(res.status).toBe(500);
    });
  });

  // ── POST /api/v1/user/profile/photo ───────────────────────────────────────
  describe('POST /api/v1/user/profile/photo', () => {
    it('returns 200 and strips data URI prefix', async () => {
      db.query.mockResolvedValueOnce({ rows: [], rowCount: 1 }); // UPDATE successful

      const res = await request(app)
        .post('/api/v1/user/profile/photo')
        .set('Authorization', authHeader)
        .send({ photo_base64: 'data:image/png;base64,iVBORw0KGgo=' });

      expect(res.status).toBe(200);
      expect(db.query.mock.calls[0][1][0]).toBe('iVBORw0KGgo='); // Check prefix is removed
    });

    it('returns 200 with raw base64 string', async () => {
      db.query.mockResolvedValueOnce({ rows: [], rowCount: 1 });

      const res = await request(app)
        .post('/api/v1/user/profile/photo')
        .set('Authorization', authHeader)
        .send({ photo_base64: 'iVBORw0KGgo=' });

      expect(res.status).toBe(200);
      expect(db.query.mock.calls[0][1][0]).toBe('iVBORw0KGgo=');
    });

    it('returns 400 when photo_base64 is invalid', async () => {
      const res = await request(app)
        .post('/api/v1/user/profile/photo')
        .set('Authorization', authHeader)
        .send({ photo_base64: 'not-a-valid-base64-string!@#' });

      expect(res.status).toBe(400);
    });

    it('returns 400 when photo_base64 is missing', async () => {
      const res = await request(app).post('/api/v1/user/profile/photo').set('Authorization', authHeader).send({});
      expect(res.status).toBe(400);
    });

    it('returns 500 on DB error', async () => {
      db.query.mockRejectedValueOnce(new Error('DB Failed'));
      const res = await request(app).post('/api/v1/user/profile/photo').set('Authorization', authHeader).send({ photo_base64: 'iVBORw0KGgo=' });
      expect(res.status).toBe(500);
    });
  });

  // ── PUT /api/v1/user/change-password ──────────────────────────────────────
  describe('PUT /api/v1/user/change-password', () => {
    it('returns 200 on successful password change', async () => {
      db.query
        .mockResolvedValueOnce({ rows: [{ id: 42, password: 'old-hashed-password' }], rowCount: 1 }) // SELECT user
        .mockResolvedValueOnce({ rows: [], rowCount: 1 }); // UPDATE password

      jest.spyOn(bcrypt, 'compare').mockResolvedValueOnce(true); // Password matches
      jest.spyOn(bcrypt, 'hash').mockResolvedValueOnce('new-hashed-password');

      const res = await request(app)
        .put('/api/v1/user/change-password')
        .set('Authorization', authHeader)
        .send({ currentPassword: 'OldPassword1!', newPassword: 'NewStrongPassword1!' });

      expect(res.status).toBe(200);
      expect(bcrypt.compare).toHaveBeenCalled();
      expect(bcrypt.hash).toHaveBeenCalled();

      bcrypt.compare.mockRestore();
      bcrypt.hash.mockRestore();
    });

    it('returns 401 when current password is wrong', async () => {
      db.query.mockResolvedValueOnce({ rows: [{ id: 42, password: 'old-hashed-password' }], rowCount: 1 });
      jest.spyOn(bcrypt, 'compare').mockResolvedValueOnce(false); // Password wrong

      const res = await request(app)
        .put('/api/v1/user/change-password')
        .set('Authorization', authHeader)
        .send({ currentPassword: 'WrongPassword!', newPassword: 'NewStrongPassword1!' });

      expect(res.status).toBe(401);
      bcrypt.compare.mockRestore();
    });

    it('returns 404 when user not found', async () => {
      db.query.mockResolvedValueOnce({ rows: [], rowCount: 0 });

      const res = await request(app)
        .put('/api/v1/user/change-password')
        .set('Authorization', authHeader)
        .send({ currentPassword: 'OldPassword1!', newPassword: 'NewStrongPassword1!' });

      expect(res.status).toBe(404);
    });

    it('returns 400 when validation fails', async () => {
      const res1 = await request(app).put('/api/v1/user/change-password').set('Authorization', authHeader).send({});
      expect(res1.status).toBe(400);

      const res2 = await request(app).put('/api/v1/user/change-password').set('Authorization', authHeader).send({ currentPassword: 'old', newPassword: 'short' });
      expect(res2.status).toBe(400);
    });

    it('returns 500 on DB error', async () => {
      db.query.mockRejectedValueOnce(new Error('DB Failed'));
      const res = await request(app).put('/api/v1/user/change-password').set('Authorization', authHeader).send({ currentPassword: 'old', newPassword: 'NewStrongPassword1!' });
      expect(res.status).toBe(500);
    });
  });

  // ── DELETE /api/v1/user/delete ────────────────────────────────────────────
  describe('DELETE /api/v1/user/delete (cascading delete)', () => {
    it('returns 200 and deletes account', async () => {
      db.query.mockResolvedValueOnce({ rows: [], rowCount: 1 }); // DELETE user

      const res = await request(app)
        .delete('/api/v1/user/delete')
        .set('Authorization', authHeader);

      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('message');
    });

    it('returns 500 on DB error', async () => {
      db.query.mockRejectedValueOnce(new Error('DB Failed'));
      const res = await request(app).delete('/api/v1/user/delete').set('Authorization', authHeader);
      expect(res.status).toBe(500);
    });
  });

  // ── JWT error branches in authenticateToken ───────────────────────────────
  describe('Invalid token handling', () => {
    it('returns 401 with JsonWebTokenError when token is malformed', async () => {
      const res = await request(app)
        .get('/api/v1/user/profile')
        .set('Authorization', 'Bearer invalid.token.here');
      expect(res.status).toBe(401);
    });
  });
});

// ── Module-level ALTER TABLE error handling ───────────────────────────────────
// Covers the two empty catch callbacks at module load time (lines 11-12 in user.js)
describe('User module initialization error handling', () => {
  it('catches ALTER TABLE query rejections at module load without crashing', async () => {
    jest.resetModules();
    const rejectingQuery = jest.fn().mockRejectedValue(new Error('column already exists'));
    jest.doMock('../../services/db', () => ({
      query: rejectingQuery,
      pool: { connect: jest.fn(), end: jest.fn(), query: jest.fn() },
      getClient: jest.fn().mockResolvedValue({ query: jest.fn(), release: jest.fn() }),
      healthCheck: jest.fn().mockResolvedValue({}),
    }));
    require('../../routes/user');
    // Allow promise microtasks (the catch callbacks) to run
    await new Promise(r => setImmediate(r));
    expect(rejectingQuery).toHaveBeenCalledTimes(2);
  });
});