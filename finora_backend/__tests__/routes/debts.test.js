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

const VALID_DEBT = {
  name: 'Car Loan',
  type: 'own',
  amount: 10000,
  remaining_amount: 8000,
  creditor_name: 'Bank ABC',
  interest_rate: 5.5,
  monthly_payment: 200,
  due_date: '2026-12-01',
  notes: 'Pay fast'
};

function makeDebtRow(overrides = {}) {
  return {
    id: 'debt-uuid-1',
    name: 'Car Loan',
    type: 'own',
    creditor_name: 'Bank ABC',
    amount: 10000,
    remaining_amount: 8000,
    interest_rate: 5.5,
    due_date: null,
    monthly_payment: 200,
    notes: null,
    is_active: true,
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString(),
    ...overrides,
  };
}

describe('Debts Routes', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  // ── GET /api/v1/debts ─────────────────────────────────────────────────────────
  describe('GET /api/v1/debts', () => {
    it('returns 401 when no auth token provided', async () => {
      const res = await request(app).get('/api/v1/debts');
      expect(res.status).toBe(401);
    });

    it('returns 200 with debts list', async () => {
      db.query.mockResolvedValueOnce({ rows: [makeDebtRow()], rowCount: 1 });

      const res = await request(app)
        .get('/api/v1/debts')
        .set('Authorization', authHeader);

      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('debts');
    });

    it('returns 200 with empty array when no debts', async () => {
      db.query.mockResolvedValueOnce({ rows: [], rowCount: 0 });

      const res = await request(app)
        .get('/api/v1/debts')
        .set('Authorization', authHeader);

      expect(res.status).toBe(200);
      expect(res.body.debts).toHaveLength(0);
    });

    it('returns 500 on DB error', async () => {
      db.query.mockRejectedValueOnce(new Error('DB Query Failed'));
      const res = await request(app).get('/api/v1/debts').set('Authorization', authHeader);
      expect(res.status).toBe(500);
    });
  });

  // ── POST /api/v1/debts ────────────────────────────────────────────────────────
  describe('POST /api/v1/debts', () => {
    it('returns 201 with valid data (including all optional fields)', async () => {
      db.query.mockResolvedValueOnce({ rows: [makeDebtRow()], rowCount: 1 });

      const res = await request(app)
        .post('/api/v1/debts')
        .set('Authorization', authHeader)
        .send(VALID_DEBT);

      expect(res.status).toBe(201);
    });

    it('returns 201 with minimal valid data (filling defaults)', async () => {
      db.query.mockResolvedValueOnce({ rows: [makeDebtRow()], rowCount: 1 });

      const res = await request(app)
        .post('/api/v1/debts')
        .set('Authorization', authHeader)
        .send({
          name: 'Minimal Debt',
          type: 'owed',
          amount: 50,
          remaining_amount: 50
        });

      expect(res.status).toBe(201);
    });

    it('returns 422 on validation failures', async () => {
      const res1 = await request(app).post('/api/v1/debts').set('Authorization', authHeader).send({ name: '' });
      expect(res1.status).toBe(422);

      const res2 = await request(app).post('/api/v1/debts').set('Authorization', authHeader).send({ ...VALID_DEBT, type: 'invalid' });
      expect(res2.status).toBe(422);

      const res3 = await request(app).post('/api/v1/debts').set('Authorization', authHeader).send({ ...VALID_DEBT, amount: 0 });
      expect(res3.status).toBe(422);
    });

    it('returns 500 on DB error', async () => {
      db.query.mockRejectedValueOnce(new Error('Insert Failed'));
      const res = await request(app).post('/api/v1/debts').set('Authorization', authHeader).send(VALID_DEBT);
      expect(res.status).toBe(500);
    });
  });

  // ── PUT /api/v1/debts/:id ─────────────────────────────────────────────────────
  describe('PUT /api/v1/debts/:id', () => {
    it('returns 200 on successful update', async () => {
      db.query.mockResolvedValueOnce({ rows: [makeDebtRow({ remaining_amount: 7500 })], rowCount: 1 });

      const res = await request(app)
        .put('/api/v1/debts/debt-uuid-1')
        .set('Authorization', authHeader)
        .send({ remaining_amount: 7500, creditor_name: 'New Bank' });

      expect(res.status).toBe(200);
    });

    it('returns 404 when debt not found', async () => {
      db.query.mockResolvedValueOnce({ rows: [], rowCount: 0 });

      const res = await request(app)
        .put('/api/v1/debts/non-existent-id')
        .set('Authorization', authHeader)
        .send({ remaining_amount: 7500 });

      expect(res.status).toBe(404);
    });

    it('returns 500 on DB error', async () => {
      db.query.mockRejectedValueOnce(new Error('Update Failed'));
      const res = await request(app).put('/api/v1/debts/debt-uuid-1').set('Authorization', authHeader).send({ amount: 100 });
      expect(res.status).toBe(500);
    });
  });

  // ── DELETE /api/v1/debts/:id ──────────────────────────────────────────────────
  describe('DELETE /api/v1/debts/:id', () => {
    it('returns 200 on successful delete', async () => {
      db.query.mockResolvedValueOnce({ rows: [{ id: 'debt-uuid-1' }], rowCount: 1 });

      const res = await request(app)
        .delete('/api/v1/debts/debt-uuid-1')
        .set('Authorization', authHeader);

      expect(res.status).toBe(200);
    });

    it('returns 404 when debt not found', async () => {
      db.query.mockResolvedValueOnce({ rows: [], rowCount: 0 });

      const res = await request(app)
        .delete('/api/v1/debts/non-existent-id')
        .set('Authorization', authHeader);

      expect(res.status).toBe(404);
    });

    it('returns 500 on DB error', async () => {
      db.query.mockRejectedValueOnce(new Error('Delete Failed'));
      const res = await request(app).delete('/api/v1/debts/debt-uuid-1').set('Authorization', authHeader);
      expect(res.status).toBe(500);
    });
  });

  // ── POST /api/v1/debts/calculate/loan ─────────────────────────────────────────
  describe('POST /api/v1/debts/calculate/loan', () => {
    it('returns 200 with calculations', async () => {
      const res = await request(app)
        .post('/api/v1/debts/calculate/loan')
        .set('Authorization', authHeader)
        .send({ principal: 10000, annual_rate: 5.5, months: 60 });

      expect(res.status).toBe(200);
    });

    it('returns 422 when required fields are missing', async () => {
      const res = await request(app).post('/api/v1/debts/calculate/loan').set('Authorization', authHeader).send({ principal: 10000 });
      expect(res.status).toBe(422);
    });

    it('handles zero interest rate', async () => {
      const res = await request(app)
        .post('/api/v1/debts/calculate/loan')
        .set('Authorization', authHeader)
        .send({ principal: 12000, annual_rate: 0, months: 12 });

      expect(res.status).toBe(200);
      expect(res.body.monthly_payment).toBe(1000);
    });

    it('returns 500 on internal math exception', async () => {
      // Forzamos un error destruyendo la request antes del cálculo
      const reqProto = Object.getPrototypeOf(request(app).post('/'));
      jest.spyOn(Math, 'pow').mockImplementationOnce(() => { throw new Error('Math Error'); });

      const res = await request(app)
        .post('/api/v1/debts/calculate/loan')
        .set('Authorization', authHeader)
        .send({ principal: 10000, annual_rate: 5.5, months: 60 });

      expect(res.status).toBe(500);
      Math.pow.mockRestore();
    });
  });

  // ── POST /api/v1/debts/calculate/mortgage ─────────────────────────────────────
  describe('POST /api/v1/debts/calculate/mortgage', () => {
    it('returns 200 with payment details without early payment', async () => {
      const res = await request(app)
        .post('/api/v1/debts/calculate/mortgage')
        .set('Authorization', authHeader)
        .send({ principal: 200000, annual_rate: 3.5, months: 360 });

      expect(res.status).toBe(200);
      expect(res.body.savings_with_early).toBeUndefined();
    });

    it('handles zero interest rate', async () => {
      const res = await request(app)
        .post('/api/v1/debts/calculate/mortgage')
        .set('Authorization', authHeader)
        .send({ principal: 360000, annual_rate: 0, months: 360 });

      expect(res.status).toBe(200);
      expect(res.body.monthly_payment).toBe(1000);
    });

    it('returns savings_with_early when early_payment provided', async () => {
      const res = await request(app)
        .post('/api/v1/debts/calculate/mortgage')
        .set('Authorization', authHeader)
        .send({ principal: 200000, annual_rate: 3.5, months: 360, early_payment: 100 });

      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('savings_with_early');
    });

    it('handles extreme early payments that pay off balance immediately (break condition)', async () => {
      const res = await request(app)
        .post('/api/v1/debts/calculate/mortgage')
        .set('Authorization', authHeader)
        .send({ principal: 10000, annual_rate: 5.0, months: 12, early_payment: 20000 });

      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('savings_with_early');
    });

    it('returns 422 on validation failure', async () => {
      const res = await request(app).post('/api/v1/debts/calculate/mortgage').set('Authorization', authHeader).send({});
      expect(res.status).toBe(422);
    });

    it('returns 500 on internal math exception', async () => {
      jest.spyOn(Math, 'pow').mockImplementationOnce(() => { throw new Error('Math Error'); });

      const res = await request(app)
        .post('/api/v1/debts/calculate/mortgage')
        .set('Authorization', authHeader)
        .send({ principal: 10000, annual_rate: 5.5, months: 60 });

      expect(res.status).toBe(500);
      Math.pow.mockRestore();
    });
  });

  // ── GET /api/v1/debts/strategies ──────────────────────────────────────────────
  describe('GET /api/v1/debts/strategies', () => {
    it('returns 200 with snowball and avalanche comparison', async () => {
      db.query.mockResolvedValueOnce({
        rows: [
          // Debt with defined payment
          { id: 'd1', name: 'Credit Card', remaining_amount: 3000, interest_rate: 20, monthly_payment: 150 },
          // Debt with undefined payment (forces fallback to 100)
          { id: 'd2', name: 'Car Loan', remaining_amount: 8000, interest_rate: 5, monthly_payment: null },
          // Zero balance debt (to test continue condition)
          { id: 'd3', name: 'Paid Off', remaining_amount: 0, interest_rate: 10, monthly_payment: 50 },
        ],
        rowCount: 3,
      });

      const res = await request(app)
        .get('/api/v1/debts/strategies')
        .set('Authorization', authHeader);

      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('snowball');
      expect(res.body).toHaveProperty('avalanche');
    });

    it('returns null strategies when no debts', async () => {
      db.query.mockResolvedValueOnce({ rows: [], rowCount: 0 });

      const res = await request(app)
        .get('/api/v1/debts/strategies')
        .set('Authorization', authHeader);

      expect(res.status).toBe(200);
      expect(res.body.snowball).toBeNull();
    });

    it('returns 500 on DB error', async () => {
      db.query.mockRejectedValueOnce(new Error('DB Error'));

      const res = await request(app)
        .get('/api/v1/debts/strategies')
        .set('Authorization', authHeader);

      expect(res.status).toBe(500);
    });
  });
});