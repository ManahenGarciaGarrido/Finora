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

beforeAll(() => {
  jest.spyOn(console, 'error').mockImplementation(() => {});
});

afterAll(() => {
  console.error.mockRestore();
});

describe('Stats Routes', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  // ── GET /api/v1/stats/summary ─────────────────────────────────────────────
  describe('GET /api/v1/stats/summary', () => {
    it('returns 401 without auth', async () => {
      const res = await request(app).get('/api/v1/stats/summary');
      expect(res.status).toBe(401);
    });

    it('returns 200 with income, expenses, balance, savings_rate', async () => {
      db.query.mockResolvedValueOnce({
        rows: [{
          total_income: '2000.00',
          total_expenses: '1200.00',
          transaction_count: '15',
          income_count: '5',
          expense_count: '10',
        }],
        rowCount: 1,
      });

      const res = await request(app)
        .get('/api/v1/stats/summary')
        .set('Authorization', authHeader);

      expect(res.status).toBe(200);
      expect(res.body.total_income).toBe(2000);
      expect(res.body.total_expenses).toBe(1200);
      expect(res.body.net_balance).toBe(800);
      expect(res.body.savings_rate).toBe(40); // 800 / 2000 * 100
    });

    it('returns 200 with savings_rate 0 when income is 0', async () => {
      db.query.mockResolvedValueOnce({
        rows: [{ total_income: '0', total_expenses: '500.00', transaction_count: '2', income_count: '0', expense_count: '2' }],
      });

      const res = await request(app)
        .get('/api/v1/stats/summary')
        .set('Authorization', authHeader);

      expect(res.status).toBe(200);
      expect(res.body.savings_rate).toBe(0);
    });

    it('returns 200 with period=3_months', async () => {
      db.query.mockResolvedValueOnce({
        rows: [{ total_income: '6000.00', total_expenses: '4500.00', transaction_count: '45', income_count: '15', expense_count: '30' }],
      });
      const res = await request(app).get('/api/v1/stats/summary?period=3_months').set('Authorization', authHeader);
      expect(res.status).toBe(200);
      expect(res.body.period).toBe('3_months');
    });

    it('returns 200 with period=6_months', async () => {
      db.query.mockResolvedValueOnce({
        rows: [{ total_income: '12000.00', total_expenses: '9000.00', transaction_count: '90', income_count: '30', expense_count: '60' }],
      });
      const res = await request(app).get('/api/v1/stats/summary?period=6_months').set('Authorization', authHeader);
      expect(res.status).toBe(200);
    });

    it('returns 200 with period=1_year', async () => {
      db.query.mockResolvedValueOnce({
        rows: [{ total_income: '24000.00', total_expenses: '18000.00', transaction_count: '180', income_count: '60', expense_count: '120' }],
      });
      const res = await request(app).get('/api/v1/stats/summary?period=1_year').set('Authorization', authHeader);
      expect(res.status).toBe(200);
    });

    it('returns 200 with period=all', async () => {
      db.query.mockResolvedValueOnce({
        rows: [{ total_income: '50000.00', total_expenses: '40000.00', transaction_count: '300', income_count: '100', expense_count: '200' }],
      });
      const res = await request(app).get('/api/v1/stats/summary?period=all').set('Authorization', authHeader);
      expect(res.status).toBe(200);
    });

    it('returns 400 for invalid period value', async () => {
      const res = await request(app).get('/api/v1/stats/summary?period=invalid').set('Authorization', authHeader);
      expect(res.status).toBe(400);
    });

    it('returns 500 on DB error', async () => {
      db.query.mockRejectedValueOnce(new Error('DB Failed'));
      const res = await request(app).get('/api/v1/stats/summary').set('Authorization', authHeader);
      expect(res.status).toBe(500);
    });
  });

  // ── GET /api/v1/stats/by-category ────────────────────────────────────────
  describe('GET /api/v1/stats/by-category', () => {
    it('returns 200 with categories and percentages', async () => {
      db.query.mockResolvedValueOnce({
        rows: [
          { category: 'Alimentación', total: '500.00', transaction_count: '10', grand_total: '1000.00' },
          { category: 'Transporte', total: '300.00', transaction_count: '5', grand_total: '1000.00' },
        ],
        rowCount: 2,
      });

      const res = await request(app)
        .get('/api/v1/stats/by-category')
        .set('Authorization', authHeader);

      expect(res.status).toBe(200);
      expect(res.body.categories[0].percentage).toBe(50);
    });

    it('returns 200 with empty categories when no transactions', async () => {
      db.query.mockResolvedValueOnce({ rows: [], rowCount: 0 });

      const res = await request(app).get('/api/v1/stats/by-category').set('Authorization', authHeader);
      expect(res.status).toBe(200);
      expect(res.body.categories).toHaveLength(0);
      expect(res.body.total_expenses).toBe(0);
    });

    it('returns 400 for invalid type', async () => {
      const res = await request(app).get('/api/v1/stats/by-category?type=invalid').set('Authorization', authHeader);
      expect(res.status).toBe(400);
    });

    it('returns 500 on DB error', async () => {
      db.query.mockRejectedValueOnce(new Error('DB Failed'));
      const res = await request(app).get('/api/v1/stats/by-category').set('Authorization', authHeader);
      expect(res.status).toBe(500);
    });
  });

  // ── GET /api/v1/stats/monthly ─────────────────────────────────────────────
  describe('GET /api/v1/stats/monthly', () => {
    it('returns 200 with monthly array', async () => {
      db.query.mockResolvedValueOnce({
        rows: [
          { year: 2026, month: 3, income: '2000.00', expenses: '1500.00', income_count: '5', expense_count: '20' },
          { year: 2026, month: 4, income: '2100.00', expenses: '1400.00', income_count: '5', expense_count: '18' },
        ],
        rowCount: 2,
      });

      const res = await request(app).get('/api/v1/stats/monthly').set('Authorization', authHeader);

      expect(res.status).toBe(200);
      expect(res.body.months).toHaveLength(2);
      expect(res.body.months[0].month_label).toBe('Marzo 2026');
    });

    it('returns 400 on invalid period', async () => {
      const res = await request(app).get('/api/v1/stats/monthly?period=invalid').set('Authorization', authHeader);
      expect(res.status).toBe(400);
    });

    it('returns 500 on DB error', async () => {
      db.query.mockRejectedValueOnce(new Error('DB Failed'));
      const res = await request(app).get('/api/v1/stats/monthly').set('Authorization', authHeader);
      expect(res.status).toBe(500);
    });
  });

  // ── GET /api/v1/stats/trends ──────────────────────────────────────────────
  describe('GET /api/v1/stats/trends', () => {
    it('returns 200 with trend comparison data', async () => {
      db.query.mockResolvedValueOnce({
        rows: [
          { month_start: new Date(), income: '2100.00', expenses: '1400.00' },
          { month_start: new Date(Date.now() - 30 * 86400000), income: '2000.00', expenses: '1500.00' },
        ],
        rowCount: 2,
      });
      db.query.mockResolvedValueOnce({
        rows: [
          { category: 'Alimentación', current_total: '500.00', prev_total: '450.00' },
          { category: 'Ocio', current_total: '100.00', prev_total: '0' }, // Previous total 0 triggers pctChange logic
        ],
        rowCount: 2,
      });

      const res = await request(app).get('/api/v1/stats/trends').set('Authorization', authHeader);

      expect(res.status).toBe(200);
      expect(res.body.changes.income_pct).toBe(5); // (2100-2000)/2000 * 100
      expect(res.body.top_expense_categories[1].vs_last_month_pct).toBe(100); // Because prev was 0
    });

    it('returns 200 even with no historical data', async () => {
      db.query
        .mockResolvedValueOnce({ rows: [], rowCount: 0 })
        .mockResolvedValueOnce({ rows: [], rowCount: 0 });

      const res = await request(app).get('/api/v1/stats/trends').set('Authorization', authHeader);

      expect(res.status).toBe(200);
      expect(res.body.changes.income_pct).toBe(0); // If current is 0 and prev is 0
    });

    it('returns 500 on DB error', async () => {
      db.query.mockRejectedValueOnce(new Error('DB error'));
      const res = await request(app).get('/api/v1/stats/trends').set('Authorization', authHeader);
      expect(res.status).toBe(500);
    });
  });
});