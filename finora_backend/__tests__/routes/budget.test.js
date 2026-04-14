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
const token = createTestToken(testUserId, 'user@example.com');
const authHeader = `Bearer ${token}`;

const SAMPLE_BUDGET = {
  id: 'budget-uuid-1',
  category: 'Alimentación',
  monthly_limit: 500,
  rollover_enabled: false,
  created_at: new Date().toISOString(),
  updated_at: new Date().toISOString(),
};

describe('Budget Routes', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  // ── GET /api/v1/budget ────────────────────────────────────────────────────
  describe('GET /api/v1/budget', () => {
    it('returns 200 with budget list', async () => {
      db.query.mockResolvedValueOnce({ rows: [SAMPLE_BUDGET], rowCount: 1 });

      const res = await request(app)
        .get('/api/v1/budget')
        .set('Authorization', authHeader);

      expect(res.status).toBe(200);
      expect(res.body.budgets).toHaveLength(1);
    });

    it('returns 401 without auth', async () => {
      const res = await request(app).get('/api/v1/budget');
      expect(res.status).toBe(401);
    });

    it('returns 200 with empty array when no budgets', async () => {
      db.query.mockResolvedValueOnce({ rows: [], rowCount: 0 });

      const res = await request(app)
        .get('/api/v1/budget')
        .set('Authorization', authHeader);

      expect(res.status).toBe(200);
      expect(res.body.budgets).toHaveLength(0);
    });

    it('returns 500 on DB error', async () => {
      db.query.mockRejectedValueOnce(new Error('DB Failed'));

      const res = await request(app)
        .get('/api/v1/budget')
        .set('Authorization', authHeader);

      expect(res.status).toBe(500);
    });
  });

  // ── GET /api/v1/budget/status ─────────────────────────────────────────────
  describe('GET /api/v1/budget/status', () => {
    it('returns 200 and calculates normal, near_limit and over_budget accurately', async () => {
      db.query
        .mockResolvedValueOnce({  // query 1: spent by category
          rows: [
            { category: 'Alimentación', spent: 450 }, // near limit (90%)
            { category: 'Ocio', spent: 600 },         // over budget
            { category: 'Transporte', spent: 100 },   // ok (50%)
            { category: 'Salud', spent: 50 },         // unbudgeted
            { category: 'Cero', spent: 10 }           // division by zero edge case
          ],
          rowCount: 5,
        })
        .mockResolvedValueOnce({  // query 2: budgets
          rows: [
            { id: 'b1', category: 'Alimentación', monthly_limit: 500 },
            { id: 'b2', category: 'Ocio', monthly_limit: 500 },
            { id: 'b3', category: 'Transporte', monthly_limit: 200 },
            { id: 'b4', category: 'Cero', monthly_limit: 0 }
          ],
          rowCount: 4,
        });

      const res = await request(app)
        .get('/api/v1/budget/status')
        .set('Authorization', authHeader);

      expect(res.status).toBe(200);
      
      const alim = res.body.statuses.find(s => s.category === 'Alimentación');
      expect(alim.alert_level).toBe('warning');
      expect(alim.near_limit).toBe(true);
      expect(alim.over_budget).toBe(false);

      const ocio = res.body.statuses.find(s => s.category === 'Ocio');
      expect(ocio.alert_level).toBe('critical');
      expect(ocio.over_budget).toBe(true);

      const trans = res.body.statuses.find(s => s.category === 'Transporte');
      expect(trans.alert_level).toBe('ok');

      const cero = res.body.statuses.find(s => s.category === 'Cero');
      expect(cero.percentage).toBe(0); // Protects against NaN

      expect(res.body.unbudgeted).toHaveLength(1);
      expect(res.body.unbudgeted[0].category).toBe('Salud');
    });

    it('returns 500 on DB error', async () => {
      db.query.mockRejectedValueOnce(new Error('DB Failed'));

      const res = await request(app)
        .get('/api/v1/budget/status')
        .set('Authorization', authHeader);

      expect(res.status).toBe(500);
    });
  });

  // ── GET /api/v1/budget/history ────────────────────────────────────────────
  describe('GET /api/v1/budget/history', () => {
    it('returns 200 with historical data handling null budgets', async () => {
      db.query
        .mockResolvedValueOnce({  // query 1: history
          rows: [
            { period: '2026-02', category: 'Alimentación', spent: 300 },
            { period: '2026-02', category: 'Ocio', spent: 50 } // Has no current budget
          ],
          rowCount: 2,
        })
        .mockResolvedValueOnce({  // query 2: current budgets
          rows: [{ category: 'Alimentación', monthly_limit: 500 }],
          rowCount: 1,
        });

      const res = await request(app)
        .get('/api/v1/budget/history')
        .set('Authorization', authHeader);

      expect(res.status).toBe(200);
      expect(res.body.history).toHaveLength(2);
      
      const ocio = res.body.history.find(h => h.category === 'Ocio');
      expect(ocio.limit).toBeNull();
      expect(ocio.percentage).toBeNull();
    });

    it('returns 500 on DB error', async () => {
      db.query.mockRejectedValueOnce(new Error('DB error'));

      const res = await request(app)
        .get('/api/v1/budget/history')
        .set('Authorization', authHeader);

      expect(res.status).toBe(500);
    });
  });

  // ── POST /api/v1/budget ───────────────────────────────────────────────────
  describe('POST /api/v1/budget', () => {
    it('returns 201 when creating/upserting a budget', async () => {
      db.query.mockResolvedValueOnce({
        rows: [{ ...SAMPLE_BUDGET, id: 'new-budget-uuid' }],
        rowCount: 1,
      });

      const res = await request(app)
        .post('/api/v1/budget')
        .set('Authorization', authHeader)
        .send({ category: 'Alimentación', monthly_limit: 500 });

      expect(res.status).toBe(201);
      expect(res.body).toHaveProperty('budget');
    });

    it('returns 422 on validation failures', async () => {
      const res1 = await request(app).post('/api/v1/budget').set('Authorization', authHeader).send({ monthly_limit: 500 });
      expect(res1.status).toBe(422);

      const res2 = await request(app).post('/api/v1/budget').set('Authorization', authHeader).send({ category: 'Alimentación', monthly_limit: -100 });
      expect(res2.status).toBe(422);
    });

    it('returns 500 on DB error', async () => {
      db.query.mockRejectedValueOnce(new Error('Insert error'));

      const res = await request(app)
        .post('/api/v1/budget')
        .set('Authorization', authHeader)
        .send({ category: 'Alimentación', monthly_limit: 500 });

      expect(res.status).toBe(500);
    });
  });

  // ── DELETE /api/v1/budget/:category ───────────────────────────────────────
  describe('DELETE /api/v1/budget/:category', () => {
    it('returns 200 on successful delete', async () => {
      db.query.mockResolvedValueOnce({
        rows: [{ id: 'budget-uuid-1' }],
        rowCount: 1,
      });

      const res = await request(app)
        .delete('/api/v1/budget/Alimentaci%C3%B3n')
        .set('Authorization', authHeader);

      expect(res.status).toBe(200);
    });

    it('returns 404 when budget not found', async () => {
      db.query.mockResolvedValueOnce({ rows: [], rowCount: 0 });

      const res = await request(app)
        .delete('/api/v1/budget/NonExistentCategory')
        .set('Authorization', authHeader);

      expect(res.status).toBe(404);
    });

    it('returns 500 on DB error', async () => {
      db.query.mockRejectedValueOnce(new Error('Delete error'));

      const res = await request(app)
        .delete('/api/v1/budget/Alimentación')
        .set('Authorization', authHeader);

      expect(res.status).toBe(500);
    });
  });

  // ── GET /api/v1/budget/suggest ────────────────────────────────────────────
  describe('GET /api/v1/budget/suggest', () => {
    it('returns 200 with AI/computed suggestions', async () => {
      db.query.mockResolvedValueOnce({
        rows: [{ category: 'Alimentación', avg_monthly: 400 }], // Must match route's SQL alias
        rowCount: 1,
      });

      const res = await request(app)
        .get('/api/v1/budget/suggest')
        .set('Authorization', authHeader);

      expect(res.status).toBe(200);
      expect(res.body.suggestions).toHaveLength(1);
      expect(res.body.suggestions[0].suggested_limit).toBeGreaterThanOrEqual(440);
    });

    it('returns 500 on DB error', async () => {
      db.query.mockRejectedValueOnce(new Error('Suggest query failed'));

      const res = await request(app)
        .get('/api/v1/budget/suggest')
        .set('Authorization', authHeader);

      expect(res.status).toBe(500);
    });
  });

  // ── PATCH /api/v1/budget/:category/rollover ───────────────────────────────
  describe('PATCH /api/v1/budget/:category/rollover', () => {
    it('returns 200 when rollover updated successfully', async () => {
      db.query.mockResolvedValueOnce({
        rows: [{ id: 'b1', category: 'Alimentación', monthly_limit: 500, rollover_enabled: true }],
        rowCount: 1,
      });

      const res = await request(app)
        .patch('/api/v1/budget/Alimentaci%C3%B3n/rollover')
        .set('Authorization', authHeader)
        .send({ rollover_enabled: true });

      expect(res.status).toBe(200);
      expect(res.body.budget.rollover_enabled).toBe(true);
    });

    it('returns 422 when validation fails', async () => {
      const res = await request(app)
        .patch('/api/v1/budget/Alimentación/rollover')
        .set('Authorization', authHeader)
        .send({ rollover_enabled: 'not-a-boolean' });

      expect(res.status).toBe(422);
    });

    it('returns 404 when budget not found', async () => {
      db.query.mockResolvedValueOnce({ rows: [], rowCount: 0 });

      const res = await request(app)
        .patch('/api/v1/budget/GhostCategory/rollover')
        .set('Authorization', authHeader)
        .send({ rollover_enabled: true });

      expect(res.status).toBe(404);
    });

    it('returns 500 on DB error', async () => {
      db.query.mockRejectedValueOnce(new Error('Patch error'));

      const res = await request(app)
        .patch('/api/v1/budget/Alimentación/rollover')
        .set('Authorization', authHeader)
        .send({ rollover_enabled: true });

      expect(res.status).toBe(500);
    });
  });
});