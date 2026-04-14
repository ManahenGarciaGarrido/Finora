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

const testUserId = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';
const testMemberId = 'b1eebc99-9c0b-4ef8-bb6d-6bb9bd380a22';
const token = createTestToken(testUserId, 'user@example.com');
const authHeader = `Bearer ${token}`;

const HOUSEHOLD_ROW = {
  id: 'hh-uuid-1',
  name: 'Family Home',
  owner_id: testUserId,
  invite_code: 'ABC12',
  created_at: new Date().toISOString(),
};

describe('Household Routes', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  // ── GET /api/v1/household ─────────────────────────────────────────────────
  describe('GET /api/v1/household', () => {
    it('returns 401 without auth', async () => {
      const res = await request(app).get('/api/v1/household');
      expect(res.status).toBe(401);
    });

    it('returns 200 with household when user is a member', async () => {
      db.query.mockResolvedValueOnce({ rows: [HOUSEHOLD_ROW], rowCount: 1 });

      const res = await request(app)
        .get('/api/v1/household')
        .set('Authorization', authHeader);

      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('household');
      expect(res.body.household).toHaveProperty('name', 'Family Home');
    });

    it('returns 200 with null household when user has no household', async () => {
      db.query.mockResolvedValueOnce({ rows: [], rowCount: 0 });

      const res = await request(app)
        .get('/api/v1/household')
        .set('Authorization', authHeader);

      expect(res.status).toBe(200);
      expect(res.body.household).toBeNull();
    });

    it('returns 500 on DB error', async () => {
      db.query.mockRejectedValueOnce(new Error('DB Failed'));

      const res = await request(app).get('/api/v1/household').set('Authorization', authHeader);
      expect(res.status).toBe(500);
    });
  });

  // ── POST /api/v1/household ────────────────────────────────────────────────
  describe('POST /api/v1/household', () => {
    it('returns 201 when creating a new household', async () => {
      db.query
        .mockResolvedValueOnce({ rows: [HOUSEHOLD_ROW], rowCount: 1 }) // INSERT household
        .mockResolvedValueOnce({ rows: [], rowCount: 1 }); // INSERT owner member

      const res = await request(app)
        .post('/api/v1/household')
        .set('Authorization', authHeader)
        .send({ name: 'Family Home' });

      expect(res.status).toBe(201);
      expect(res.body).toHaveProperty('household');
      expect(res.body.household).toHaveProperty('name', 'Family Home');
    });

    it('returns 422 when name is missing or empty', async () => {
      const res1 = await request(app).post('/api/v1/household').set('Authorization', authHeader).send({});
      expect(res1.status).toBe(422);

      const res2 = await request(app).post('/api/v1/household').set('Authorization', authHeader).send({ name: ' ' });
      expect(res2.status).toBe(422);
    });

    it('returns 500 on DB error', async () => {
      db.query.mockRejectedValueOnce(new Error('DB Failed'));

      const res = await request(app)
        .post('/api/v1/household')
        .set('Authorization', authHeader)
        .send({ name: 'Family Home' });

      expect(res.status).toBe(500);
    });
  });

  // ── DELETE /api/v1/household ──────────────────────────────────────────────
  describe('DELETE /api/v1/household', () => {
    it('returns 200 when owner deletes household', async () => {
      db.query.mockResolvedValueOnce({ rows: [{ id: 'hh-uuid-1' }], rowCount: 1 });

      const res = await request(app)
        .delete('/api/v1/household')
        .set('Authorization', authHeader);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
    });

    it('returns 403 when user is not the owner (no rows deleted)', async () => {
      db.query.mockResolvedValueOnce({ rows: [], rowCount: 0 });

      const res = await request(app)
        .delete('/api/v1/household')
        .set('Authorization', authHeader);

      expect(res.status).toBe(403);
    });

    it('returns 500 on DB error', async () => {
      db.query.mockRejectedValueOnce(new Error('DB Failed'));

      const res = await request(app)
        .delete('/api/v1/household')
        .set('Authorization', authHeader);

      expect(res.status).toBe(500);
    });
  });

  // ── POST /api/v1/household/invite ─────────────────────────────────────────
  describe('POST /api/v1/household/invite', () => {
    it('returns 200 when successfully inviting a member', async () => {
      db.query
        .mockResolvedValueOnce({ rows: [HOUSEHOLD_ROW], rowCount: 1 }) // getUserHousehold
        .mockResolvedValueOnce({ rows: [{ id: testMemberId }], rowCount: 1 }) // find user by email
        .mockResolvedValueOnce({ rows: [], rowCount: 1 }); // INSERT member

      const res = await request(app)
        .post('/api/v1/household/invite')
        .set('Authorization', authHeader)
        .send({ email: 'friend@example.com' });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
    });

    it('returns 422 when email is missing or invalid', async () => {
      const res1 = await request(app).post('/api/v1/household/invite').set('Authorization', authHeader).send({});
      expect(res1.status).toBe(422);

      const res2 = await request(app).post('/api/v1/household/invite').set('Authorization', authHeader).send({ email: 'not-an-email' });
      expect(res2.status).toBe(422);
    });

    it('returns 404 when user has no household', async () => {
      db.query.mockResolvedValueOnce({ rows: [], rowCount: 0 }); // getUserHousehold returns null

      const res = await request(app)
        .post('/api/v1/household/invite')
        .set('Authorization', authHeader)
        .send({ email: 'friend@example.com' });

      expect(res.status).toBe(404);
    });

    it('returns 404 when invited user email is not found', async () => {
      db.query
        .mockResolvedValueOnce({ rows: [HOUSEHOLD_ROW], rowCount: 1 }) // getUserHousehold
        .mockResolvedValueOnce({ rows: [], rowCount: 0 }); // email not found

      const res = await request(app)
        .post('/api/v1/household/invite')
        .set('Authorization', authHeader)
        .send({ email: 'ghost@example.com' });

      expect(res.status).toBe(404);
    });

    it('returns 500 on DB error', async () => {
      db.query.mockRejectedValueOnce(new Error('DB Failed'));

      const res = await request(app)
        .post('/api/v1/household/invite')
        .set('Authorization', authHeader)
        .send({ email: 'friend@example.com' });

      expect(res.status).toBe(500);
    });
  });

  // ── DELETE /api/v1/household/members/:userId ──────────────────────────────
  describe('DELETE /api/v1/household/members/:userId', () => {
    it('returns 200 when owner removes a member', async () => {
      db.query
        .mockResolvedValueOnce({ rows: [HOUSEHOLD_ROW], rowCount: 1 }) // getUserHousehold (owner)
        .mockResolvedValueOnce({ rows: [], rowCount: 1 }); // DELETE

      const res = await request(app)
        .delete(`/api/v1/household/members/${testMemberId}`)
        .set('Authorization', authHeader);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
    });

    it('returns 403 when user has no household or is not the owner', async () => {
      // Not owner (owner_id is different from token user id)
      db.query.mockResolvedValueOnce({
        rows: [{ ...HOUSEHOLD_ROW, owner_id: 'c2eebc99-9c0b-4ef8-bb6d-6bb9bd380a33' }],
        rowCount: 1,
      });

      const res1 = await request(app).delete(`/api/v1/household/members/${testMemberId}`).set('Authorization', authHeader);
      expect(res1.status).toBe(403);

      // No household
      db.query.mockResolvedValueOnce({ rows: [], rowCount: 0 });
      const res2 = await request(app).delete(`/api/v1/household/members/${testMemberId}`).set('Authorization', authHeader);
      expect(res2.status).toBe(403);
    });

    it('returns 500 on DB error', async () => {
      db.query.mockRejectedValueOnce(new Error('DB Failed'));

      const res = await request(app).delete(`/api/v1/household/members/${testMemberId}`).set('Authorization', authHeader);
      expect(res.status).toBe(500);
    });
  });

  // ── GET /api/v1/household/members ─────────────────────────────────────────
  describe('GET /api/v1/household/members', () => {
    it('returns 200 with members list', async () => {
      db.query
        .mockResolvedValueOnce({ rows: [HOUSEHOLD_ROW], rowCount: 1 }) // getUserHousehold
        .mockResolvedValueOnce({
          rows: [
            { id: 'm1', user_id: testUserId, role: 'owner', name: 'Test User', email: 'user@example.com', joined_at: new Date().toISOString() },
          ],
          rowCount: 1,
        });

      const res = await request(app)
        .get('/api/v1/household/members')
        .set('Authorization', authHeader);

      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('members');
    });

    it('returns 404 when user has no household', async () => {
      db.query.mockResolvedValueOnce({ rows: [], rowCount: 0 });

      const res = await request(app)
        .get('/api/v1/household/members')
        .set('Authorization', authHeader);

      expect(res.status).toBe(404);
    });

    it('returns 500 on DB error', async () => {
      db.query.mockRejectedValueOnce(new Error('DB error'));

      const res = await request(app).get('/api/v1/household/members').set('Authorization', authHeader);
      expect(res.status).toBe(500);
    });
  });

  // ── POST /api/v1/household/transactions ───────────────────────────────────
  describe('POST /api/v1/household/transactions', () => {
    it('returns 201 when creating a shared transaction', async () => {
      db.query
        .mockResolvedValueOnce({ rows: [HOUSEHOLD_ROW], rowCount: 1 }) // getUserHousehold
        .mockResolvedValueOnce({ rows: [{ id: 'st-uuid-1' }], rowCount: 1 }) // INSERT shared_transaction
        .mockResolvedValueOnce({ rows: [], rowCount: 1 }) // INSERT split 1
        .mockResolvedValueOnce({ rows: [], rowCount: 1 }); // INSERT split 2

      const res = await request(app)
        .post('/api/v1/household/transactions')
        .set('Authorization', authHeader)
        .send({
          amount: 100,
          description: 'Groceries',
          splits: [
            { user_id: testUserId, percentage: 50 },
            { user_id: testMemberId, percentage: 50 },
          ],
        });

      expect(res.status).toBe(201);
      expect(res.body.success).toBe(true);
    });

    it('returns 422 when amount is missing or invalid', async () => {
      const res = await request(app)
        .post('/api/v1/household/transactions')
        .set('Authorization', authHeader)
        .send({ description: 'Groceries', splits: [{ user_id: testUserId, percentage: 100 }] });

      expect(res.status).toBe(422);
    });

    it('returns 404 when user has no household', async () => {
      db.query.mockResolvedValueOnce({ rows: [], rowCount: 0 });

      const res = await request(app)
        .post('/api/v1/household/transactions')
        .set('Authorization', authHeader)
        .send({ amount: 100, description: 'Groceries', splits: [{ user_id: testUserId, percentage: 100 }] });

      expect(res.status).toBe(404);
    });

    it('returns 500 on DB error', async () => {
      db.query.mockRejectedValueOnce(new Error('DB Failed'));

      const res = await request(app)
        .post('/api/v1/household/transactions')
        .set('Authorization', authHeader)
        .send({ amount: 100, description: 'Groceries', splits: [{ user_id: testUserId, percentage: 100 }] });

      expect(res.status).toBe(500);
    });
  });

  // ── GET /api/v1/household/transactions ───────────────────────────────────
  describe('GET /api/v1/household/transactions', () => {
    it('returns 200 with transactions list', async () => {
      db.query
        .mockResolvedValueOnce({ rows: [HOUSEHOLD_ROW], rowCount: 1 }) // getUserHousehold
        .mockResolvedValueOnce({
          rows: [
            { id: 'st-1', amount: 100, description: 'Groceries', created_by_name: 'Test User', created_at: new Date().toISOString(), splits: [] },
          ],
          rowCount: 1,
        });

      const res = await request(app)
        .get('/api/v1/household/transactions')
        .set('Authorization', authHeader);

      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('transactions');
    });

    it('returns 404 when user has no household', async () => {
      db.query.mockResolvedValueOnce({ rows: [], rowCount: 0 });

      const res = await request(app).get('/api/v1/household/transactions').set('Authorization', authHeader);
      expect(res.status).toBe(404);
    });

    it('returns 500 on DB error', async () => {
      db.query.mockRejectedValueOnce(new Error('DB Failed'));
      const res = await request(app).get('/api/v1/household/transactions').set('Authorization', authHeader);
      expect(res.status).toBe(500);
    });
  });

  // ── GET /api/v1/household/balances ────────────────────────────────────────
  describe('GET /api/v1/household/balances', () => {
    it('returns 200 with balances', async () => {
      db.query
        .mockResolvedValueOnce({ rows: [HOUSEHOLD_ROW], rowCount: 1 }) // getUserHousehold
        .mockResolvedValueOnce({
          rows: [{ payer_id: testUserId, ower_id: testMemberId, amount: 50 }],
          rowCount: 1,
        });

      const res = await request(app).get('/api/v1/household/balances').set('Authorization', authHeader);

      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('balances');
    });

    it('returns 404 when user has no household', async () => {
      db.query.mockResolvedValueOnce({ rows: [], rowCount: 0 });
      const res = await request(app).get('/api/v1/household/balances').set('Authorization', authHeader);
      expect(res.status).toBe(404);
    });

    it('returns 500 on DB error', async () => {
      db.query.mockRejectedValueOnce(new Error('DB Error'));
      const res = await request(app).get('/api/v1/household/balances').set('Authorization', authHeader);
      expect(res.status).toBe(500);
    });
  });

  // ── POST /api/v1/household/settle ─────────────────────────────────────────
  describe('POST /api/v1/household/settle', () => {
    it('returns 200 when settling balances', async () => {
      db.query
        .mockResolvedValueOnce({ rows: [HOUSEHOLD_ROW], rowCount: 1 }) // getUserHousehold
        .mockResolvedValueOnce({ rows: [], rowCount: 2 }); // UPDATE splits

      const res = await request(app)
        .post('/api/v1/household/settle')
        .set('Authorization', authHeader)
        .send({ with_user_id: testMemberId });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
    });

    it('returns 422 when with_user_id is invalid', async () => {
      const res = await request(app)
        .post('/api/v1/household/settle')
        .set('Authorization', authHeader)
        .send({ with_user_id: 'not-a-uuid' });

      expect(res.status).toBe(422);
    });

    it('returns 404 when user has no household', async () => {
      db.query.mockResolvedValueOnce({ rows: [], rowCount: 0 });

      const res = await request(app)
        .post('/api/v1/household/settle')
        .set('Authorization', authHeader)
        .send({ with_user_id: testMemberId });

      expect(res.status).toBe(404);
    });

    it('returns 500 on DB error', async () => {
      db.query.mockRejectedValueOnce(new Error('DB Failed'));

      const res = await request(app)
        .post('/api/v1/household/settle')
        .set('Authorization', authHeader)
        .send({ with_user_id: testMemberId });

      expect(res.status).toBe(500);
    });
  });
});