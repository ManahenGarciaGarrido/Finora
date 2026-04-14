'use strict';

jest.mock('../../services/db', () => require('../helpers/mockDb'));
jest.mock('../../services/email', () => ({
  sendVerificationEmail: jest.fn().mockResolvedValue({ success: true }),
  verifyConnection: jest.fn().mockResolvedValue(true),
}));

// Mock the AI fetch call
global.fetch = jest.fn();

const request = require('supertest');
const app = require('../../server');
const db = require('../../services/db');
const { createTestToken } = require('../helpers/testHelpers');

const token = createTestToken(42, 'user@example.com');
const authHeader = `Bearer ${token}`;

const SAMPLE_GOAL = {
  id: 'goal-uuid-1',
  user_id: 42,
  name: 'Emergency Fund',
  target_amount: '5000.00',
  current_amount: '1000.00', // 20% (Red)
  deadline: '2026-12-31',
  status: 'active',
  created_at: new Date().toISOString(),
};

const VALID_GOAL_BODY = {
  name: 'New Car',
  target_amount: 10000,
  deadline: '2027-01-01',
  category: 'vehicle',
};

// Silenciar logs de error controlados
beforeAll(() => {
  jest.spyOn(console, 'error').mockImplementation(() => {});
  jest.spyOn(console, 'warn').mockImplementation(() => {});
});

afterAll(() => {
  console.error.mockRestore();
  console.warn.mockRestore();
});

describe('Goals Routes', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    global.fetch.mockReset();
  });

  // ── GET /api/v1/goals ─────────────────────────────────────────────────────
  describe('GET /api/v1/goals', () => {
    it('returns 200 with goals list, projecting completion date if monthly rate exists', async () => {
      db.query
        .mockResolvedValueOnce({ rows: [SAMPLE_GOAL], rowCount: 1 })   // list goals
        .mockResolvedValueOnce({ rows: [{ total: '1500' }], rowCount: 1 }); // monthly rate (500/mo)

      const res = await request(app).get('/api/v1/goals').set('Authorization', authHeader);

      expect(res.status).toBe(200);
      expect(res.body.goals[0].progressColor).toBe('#ef4444'); // < 30%
      expect(res.body.goals[0].projectedCompletionDate).toBeDefined();
    });

    it('handles green progress (>70%) without deadline projection', async () => {
      const greenGoal = { ...SAMPLE_GOAL, current_amount: '4000.00' }; // 80%
      db.query
        .mockResolvedValueOnce({ rows: [greenGoal], rowCount: 1 })
        .mockResolvedValueOnce({ rows: [{ total: '0' }], rowCount: 1 }); // 0 rate

      const res = await request(app).get('/api/v1/goals').set('Authorization', authHeader);
      
      expect(res.status).toBe(200);
      expect(res.body.goals[0].progressColor).toBe('#22c55e'); // >= 70%
    });

    it('handles yellow progress (30-70%)', async () => {
      const yellowGoal = { ...SAMPLE_GOAL, current_amount: '2500.00' }; // 50%
      db.query
        .mockResolvedValueOnce({ rows: [yellowGoal], rowCount: 1 })
        .mockResolvedValueOnce({ rows: [{ total: '0' }], rowCount: 1 });

      const res = await request(app).get('/api/v1/goals').set('Authorization', authHeader);
      expect(res.body.goals[0].progressColor).toBe('#f59e0b'); // 30-70%
    });

    it('returns 401 without auth', async () => {
      const res = await request(app).get('/api/v1/goals');
      expect(res.status).toBe(401);
    });

    it('returns 500 on DB error', async () => {
      db.query.mockRejectedValueOnce(new Error('DB Failed'));
      const res = await request(app).get('/api/v1/goals').set('Authorization', authHeader);
      expect(res.status).toBe(500);
    });
  });

  // ── POST /api/v1/goals ────────────────────────────────────────────────────
  describe('POST /api/v1/goals', () => {
    it('returns 201 on successful goal creation with AI evaluation', async () => {
      db.query.mockResolvedValueOnce({ rows: [], rowCount: 0 }); // eval: tx history
      global.fetch.mockResolvedValueOnce({
        ok: true,
        json: async () => ({ feasibility: 'High', monthly_savings: 500, explanation: 'Good' })
      });
      db.query.mockResolvedValueOnce({ // INSERT savings_goal
        rows: [{ ...SAMPLE_GOAL, id: 'new-goal-uuid', current_amount: 0 }],
        rowCount: 1,
      });

      const res = await request(app).post('/api/v1/goals').set('Authorization', authHeader).send(VALID_GOAL_BODY);

      expect(res.status).toBe(201);
      expect(res.body).toHaveProperty('ai_analysis');
    });

    it('returns 201 even if AI service fails (fallback to manual create)', async () => {
      db.query.mockResolvedValueOnce({ rows: [], rowCount: 0 }); 
      global.fetch.mockRejectedValueOnce(new Error('AI Down')); // AI fails
      db.query.mockResolvedValueOnce({ 
        rows: [{ ...SAMPLE_GOAL, current_amount: 0 }],
        rowCount: 1,
      });

      const res = await request(app).post('/api/v1/goals').set('Authorization', authHeader).send({ ...VALID_GOAL_BODY, monthly_target: 200 });

      expect(res.status).toBe(201);
      expect(res.body.ai_analysis).toBeNull();
    });

    it('returns 400 when missing required fields or target <= 0', async () => {
      const res1 = await request(app).post('/api/v1/goals').set('Authorization', authHeader).send({ target_amount: 1000 });
      expect(res1.status).toBe(400);

      const res2 = await request(app).post('/api/v1/goals').set('Authorization', authHeader).send({ name: 'A', target_amount: -100 });
      expect(res2.status).toBe(400);
    });

    it('returns 500 on DB error', async () => {
      db.query.mockRejectedValueOnce(new Error('DB error'));
      const res = await request(app).post('/api/v1/goals').set('Authorization', authHeader).send(VALID_GOAL_BODY);
      expect(res.status).toBe(500);
    });
  });

  // ── GET /api/v1/goals/recommendations ───────────────────────────────────────
  describe('GET /api/v1/goals/recommendations', () => {
    it('returns recommendations using AI when user has tx history', async () => {
      db.query
        .mockResolvedValueOnce({ rows: [{ amount: 100 }], rowCount: 1 }) // txs
        .mockResolvedValueOnce({ rows: [{ committed_monthly: '200' }], rowCount: 1 }); // committed

      global.fetch.mockResolvedValueOnce({ ok: true, json: async () => ({ recommendations: [] }) });

      const res = await request(app).get('/api/v1/goals/recommendations').set('Authorization', authHeader);

      expect(res.status).toBe(200);
      expect(res.body.has_data).toBe(true);
    });

    it('returns has_data: false when no transaction history', async () => {
      db.query
        .mockResolvedValueOnce({ rows: [], rowCount: 0 }) 
        .mockResolvedValueOnce({ rows: [{ committed_monthly: '0' }], rowCount: 1 });

      const res = await request(app).get('/api/v1/goals/recommendations').set('Authorization', authHeader);

      expect(res.status).toBe(200);
      expect(res.body.has_data).toBe(false);
    });

    it('returns 502 when AI service fails (!ok)', async () => {
      db.query
        .mockResolvedValueOnce({ rows: [{ amount: 100 }], rowCount: 1 })
        .mockResolvedValueOnce({ rows: [{ committed_monthly: '0' }], rowCount: 1 });

      global.fetch.mockResolvedValueOnce({ ok: false });

      const res = await request(app).get('/api/v1/goals/recommendations').set('Authorization', authHeader);

      expect(res.status).toBe(502);
    });

    it('returns 500 on DB error', async () => {
      db.query.mockRejectedValueOnce(new Error('DB Failed'));
      const res = await request(app).get('/api/v1/goals/recommendations').set('Authorization', authHeader);
      expect(res.status).toBe(500);
    });
  });

  // ── GET /api/v1/goals/:id ─────────────────────────────────────────────────
  describe('GET /api/v1/goals/:id', () => {
    it('returns 200 with goal detail', async () => {
      db.query
        .mockResolvedValueOnce({ rows: [SAMPLE_GOAL], rowCount: 1 })       // find goal
        .mockResolvedValueOnce({ rows: [{ total: '0' }], rowCount: 1 });   // getMonthlyRate

      const res = await request(app).get('/api/v1/goals/goal-uuid-1').set('Authorization', authHeader);
      expect(res.status).toBe(200);
    });

    it('returns 404 when goal not found', async () => {
      db.query.mockResolvedValueOnce({ rows: [], rowCount: 0 });
      const res = await request(app).get('/api/v1/goals/non-existent').set('Authorization', authHeader);
      expect(res.status).toBe(404);
    });

    it('returns 500 on DB error', async () => {
      db.query.mockRejectedValueOnce(new Error('DB error'));
      const res = await request(app).get('/api/v1/goals/g-1').set('Authorization', authHeader);
      expect(res.status).toBe(500);
    });
  });

  // ── PUT /api/v1/goals/:id ─────────────────────────────────────────────────
  describe('PUT /api/v1/goals/:id', () => {
    it('returns 200 on successful update (marking as completed)', async () => {
      db.query
        .mockResolvedValueOnce({ rows: [SAMPLE_GOAL], rowCount: 1 })  // find goal
        .mockResolvedValueOnce({                                      // update
          rows: [{ ...SAMPLE_GOAL, status: 'completed' }],
          rowCount: 1,
        })
        .mockResolvedValueOnce({ rows: [{ total: '0' }], rowCount: 1 }); // getMonthlyRate

      const res = await request(app)
        .put('/api/v1/goals/goal-uuid-1')
        .set('Authorization', authHeader)
        .send({ status: 'completed' });

      expect(res.status).toBe(200);
      expect(res.body.goal.status).toBe('completed');
    });

    it('returns 404 when goal not found', async () => {
      db.query.mockResolvedValueOnce({ rows: [], rowCount: 0 });
      const res = await request(app).put('/api/v1/goals/non-existent').set('Authorization', authHeader).send({ name: 'U' });
      expect(res.status).toBe(404);
    });

    it('returns 500 on DB error', async () => {
      db.query.mockRejectedValueOnce(new Error('DB Failed'));
      const res = await request(app).put('/api/v1/goals/g1').set('Authorization', authHeader).send({ name: 'U' });
      expect(res.status).toBe(500);
    });
  });

  // ── DELETE /api/v1/goals/:id ──────────────────────────────────────────────
  describe('DELETE /api/v1/goals/:id', () => {
    it('returns 200 on successful delete/cancel', async () => {
      db.query.mockResolvedValueOnce({ rows: [{ id: 'g1' }], rowCount: 1 });
      const res = await request(app).delete('/api/v1/goals/goal-uuid-1').set('Authorization', authHeader);
      expect(res.status).toBe(200);
    });

    it('returns 404 when goal not found', async () => {
      db.query.mockResolvedValueOnce({ rows: [], rowCount: 0 });
      const res = await request(app).delete('/api/v1/goals/non-existent').set('Authorization', authHeader);
      expect(res.status).toBe(404);
    });

    it('returns 500 on DB error', async () => {
      db.query.mockRejectedValueOnce(new Error('DB Failed'));
      const res = await request(app).delete('/api/v1/goals/g1').set('Authorization', authHeader);
      expect(res.status).toBe(500);
    });
  });

  // ── GET /api/v1/goals/:id/progress ───────────────────────────────────────
  describe('GET /api/v1/goals/:id/progress', () => {
    it('returns 200 with progress data with deadline', async () => {
      db.query
        .mockResolvedValueOnce({ rows: [SAMPLE_GOAL], rowCount: 1 })     // find goal
        .mockResolvedValueOnce({ rows: [], rowCount: 0 })                // monthly_evolution
        .mockResolvedValueOnce({ rows: [{ total: '0' }], rowCount: 1 })  // allContribsResult
        .mockResolvedValueOnce({ rows: [{ total: '0' }], rowCount: 1 }); // getMonthlyRate

      const res = await request(app).get('/api/v1/goals/goal-uuid-1/progress').set('Authorization', authHeader);
      expect(res.status).toBe(200);
      expect(res.body.days_remaining).toBeGreaterThan(0);
    });

    it('returns 200 with progress data without deadline', async () => {
      db.query
        .mockResolvedValueOnce({ rows: [{ ...SAMPLE_GOAL, deadline: null }], rowCount: 1 }) 
        .mockResolvedValueOnce({ rows: [], rowCount: 0 })               
        .mockResolvedValueOnce({ rows: [{ total: '0' }], rowCount: 1 })  
        .mockResolvedValueOnce({ rows: [{ total: '0' }], rowCount: 1 }); 

      const res = await request(app).get('/api/v1/goals/goal-uuid-1/progress').set('Authorization', authHeader);
      expect(res.status).toBe(200);
      expect(res.body.days_remaining).toBeNull();
    });

    it('returns 404 when goal not found', async () => {
      db.query.mockResolvedValueOnce({ rows: [], rowCount: 0 });
      const res = await request(app).get('/api/v1/goals/non-existent/progress').set('Authorization', authHeader);
      expect(res.status).toBe(404);
    });

    it('returns 500 on DB error', async () => {
      db.query.mockRejectedValueOnce(new Error('DB Error'));
      const res = await request(app).get('/api/v1/goals/g1/progress').set('Authorization', authHeader);
      expect(res.status).toBe(500);
    });
  });

  // ── POST /api/v1/goals/:id/contributions ─────────────────────────────────
  describe('POST /api/v1/goals/:id/contributions', () => {
    it('returns 201, completes goal, and updates bank account', async () => {
      db.query
        .mockResolvedValueOnce({ rows: [{ ...SAMPLE_GOAL, target_amount: 1100, current_amount: 1000 }], rowCount: 1 })  // find
        .mockResolvedValueOnce({ rows: [{ id: 'c1' }], rowCount: 1 }) // INSERT contribution
        .mockResolvedValueOnce({ rows: [], rowCount: 1 }) // UPDATE goal current_amount
        .mockResolvedValueOnce({ rows: [], rowCount: 1 }) // INSERT transactions
        .mockResolvedValueOnce({ rows: [], rowCount: 1 }) // UPDATE bank_accounts
        .mockResolvedValueOnce({ rows: [], rowCount: 1 }) // INSERT notification (completed)
        .mockResolvedValueOnce({ rows: [{ total: '100' }], rowCount: 1 }); // getMonthlyRate

      const res = await request(app)
        .post('/api/v1/goals/goal-uuid-1/contributions')
        .set('Authorization', authHeader)
        .send({ amount: 100, bank_account_id: 'bank-1' });

      expect(res.status).toBe(201);
      expect(res.body.goal_completed).toBe(true);
    });

    it('returns 400 when amount is missing or invalid', async () => {
      const res = await request(app).post('/api/v1/goals/goal-uuid-1/contributions').set('Authorization', authHeader).send({});
      expect(res.status).toBe(400);
    });

    it('returns 404 when goal not found', async () => {
      db.query.mockResolvedValueOnce({ rows: [], rowCount: 0 });
      const res = await request(app).post('/api/v1/goals/non-existent/contributions').set('Authorization', authHeader).send({ amount: 100 });
      expect(res.status).toBe(404);
    });

    it('returns 500 on major DB error', async () => {
      db.query.mockRejectedValueOnce(new Error('DB Failed'));
      const res = await request(app).post('/api/v1/goals/g1/contributions').set('Authorization', authHeader).send({ amount: 100 });
      expect(res.status).toBe(500);
    });
  });

  // ── GET /api/v1/goals/:id/contributions ──────────────────────────────────
  describe('GET /api/v1/goals/:id/contributions', () => {
    it('returns 200 with contributions', async () => {
      db.query
        .mockResolvedValueOnce({ rows: [{ id: 'g1' }], rowCount: 1 })  // check
        .mockResolvedValueOnce({ rows: [{ id: 'c1' }], rowCount: 1 })  // list
        .mockResolvedValueOnce({ rows: [{ count: '1' }], rowCount: 1 }); // count

      const res = await request(app).get('/api/v1/goals/g1/contributions').set('Authorization', authHeader);
      expect(res.status).toBe(200);
    });

    it('returns 404 when goal not found', async () => {
      db.query.mockResolvedValueOnce({ rows: [], rowCount: 0 });
      const res = await request(app).get('/api/v1/goals/g1/contributions').set('Authorization', authHeader);
      expect(res.status).toBe(404);
    });

    it('returns 500 on DB error', async () => {
      db.query.mockRejectedValueOnce(new Error('DB Failed'));
      const res = await request(app).get('/api/v1/goals/g1/contributions').set('Authorization', authHeader);
      expect(res.status).toBe(500);
    });
  });

  // ── PUT /api/v1/goals/:id/contributions/:cid ─────────────────────────────────
  describe('PUT /api/v1/goals/:id/contributions/:cid', () => {
    it('returns 200 when updating contribution without explicit amount (uses old amount)', async () => {
      db.query
        .mockResolvedValueOnce({ rows: [{ id: 'c1', amount: '50' }], rowCount: 1 })
        .mockResolvedValueOnce({ rows: [{ id: 'c1', amount: '50' }], rowCount: 1 })
        .mockResolvedValueOnce({ rows: [], rowCount: 1 });

      const res = await request(app)
        .put('/api/v1/goals/g1/contributions/c1')
        .set('Authorization', authHeader)
        .send({ note: 'Updated note' });

      expect(res.status).toBe(200);
    });

    it('returns 404 if contribution missing', async () => {
      db.query.mockResolvedValueOnce({ rows: [], rowCount: 0 });
      const res = await request(app).put('/api/v1/goals/g1/contributions/c1').set('Authorization', authHeader).send({ amount: 100 });
      expect(res.status).toBe(404);
    });

    it('returns 500 on DB error', async () => {
      db.query.mockRejectedValueOnce(new Error('DB Error'));
      const res = await request(app).put('/api/v1/goals/g1/contributions/c1').set('Authorization', authHeader).send({ amount: 100 });
      expect(res.status).toBe(500);
    });
  });

  // ── DELETE /api/v1/goals/:id/contributions/:cid ───────────────────────────
  describe('DELETE /api/v1/goals/:id/contributions/:cid', () => {
    it('returns 200 and recalculates status correctly', async () => {
      db.query
        .mockResolvedValueOnce({ rows: [{ amount: '100' }], rowCount: 1 }) // check
        .mockResolvedValueOnce({ rows: [], rowCount: 1 }) // delete
        .mockResolvedValueOnce({ rows: [], rowCount: 1 }); // update goal

      const res = await request(app).delete('/api/v1/goals/g1/contributions/c1').set('Authorization', authHeader);
      expect(res.status).toBe(200);
    });

    it('returns 404 when contribution not found', async () => {
      db.query.mockResolvedValueOnce({ rows: [], rowCount: 0 });
      const res = await request(app).delete('/api/v1/goals/g1/contributions/c1').set('Authorization', authHeader);
      expect(res.status).toBe(404);
    });

    it('returns 500 on DB error', async () => {
      db.query.mockRejectedValueOnce(new Error('DB Error'));
      const res = await request(app).delete('/api/v1/goals/g1/contributions/c1').set('Authorization', authHeader);
      expect(res.status).toBe(500);
    });
  });

  // ── POST /api/v1/goals/:id/advice ──────────────────────────────────────────
  describe('POST /api/v1/goals/:id/advice', () => {
    it('returns 400 for invalid amount', async () => {
      const res = await request(app).post('/api/v1/goals/g1/advice').set('Authorization', authHeader).send({ proposed_amount: 0 });
      expect(res.status).toBe(400);
    });

    it('returns 404 if goal not found', async () => {
      db.query.mockResolvedValueOnce({ rows: [], rowCount: 0 });
      const res = await request(app).post('/api/v1/goals/g1/advice').set('Authorization', authHeader).send({ proposed_amount: 100 });
      expect(res.status).toBe(404);
    });

    it('suggests "increase" if AI determines needed amount is high', async () => {
      db.query
        .mockResolvedValueOnce({ rows: [{ ...SAMPLE_GOAL, target_amount: 1000, current_amount: 0 }], rowCount: 1 })
        .mockResolvedValueOnce({ rows: [], rowCount: 0 }); // txs
        
      global.fetch.mockResolvedValueOnce({
        ok: true,
        json: async () => ({ ahorro_necesario: 500, capacidad: { disponible: 1000 } })
      });

      const res = await request(app).post('/api/v1/goals/g1/advice').set('Authorization', authHeader).send({ proposed_amount: 100 });
      
      expect(res.status).toBe(200);
      expect(res.body.suggestion).toBe('increase');
    });

    it('suggests "decrease" if proposed is too high for capacity', async () => {
      db.query
        .mockResolvedValueOnce({ rows: [SAMPLE_GOAL], rowCount: 1 })
        .mockResolvedValueOnce({ rows: [], rowCount: 0 }); // txs
        
      global.fetch.mockResolvedValueOnce({
        ok: true,
        json: async () => ({ ahorro_necesario: 100, capacidad: { disponible: 200 } })
      });

      const res = await request(app).post('/api/v1/goals/g1/advice').set('Authorization', authHeader).send({ proposed_amount: 300 }); // 300 > 90% of 200
      
      expect(res.status).toBe(200);
      expect(res.body.suggestion).toBe('decrease');
    });

    it('suggests "correct" via AI', async () => {
      db.query
        .mockResolvedValueOnce({ rows: [SAMPLE_GOAL], rowCount: 1 })
        .mockResolvedValueOnce({ rows: [], rowCount: 0 }); // txs
        
      global.fetch.mockResolvedValueOnce({
        ok: true,
        json: async () => ({ ahorro_necesario: 100, capacidad: { disponible: 1000 } })
      });

      const res = await request(app).post('/api/v1/goals/g1/advice').set('Authorization', authHeader).send({ proposed_amount: 150 });
      expect(res.status).toBe(200);
      expect(res.body.suggestion).toBe('correct');
    });

    it('falls back to math logic if AI fetch rejects (suggesting increase)', async () => {
      db.query
        .mockResolvedValueOnce({ rows: [{ ...SAMPLE_GOAL, deadline: null, target_amount: 1200, current_amount: 0 }], rowCount: 1 })
        .mockResolvedValueOnce({ rows: [], rowCount: 0 }); // txs
      
      global.fetch.mockRejectedValueOnce(new Error('AI offline'));

      // without deadline it defaults to 12 months. 1200/12 = 100 needed. 50 is < 70
      const res = await request(app).post('/api/v1/goals/g1/advice').set('Authorization', authHeader).send({ proposed_amount: 50 });
      
      expect(res.status).toBe(200);
      expect(res.body.suggestion).toBe('increase');
    });

    it('falls back to math logic if AI fetch rejects (suggesting correct)', async () => {
      db.query
        .mockResolvedValueOnce({ rows: [{ ...SAMPLE_GOAL, deadline: null, target_amount: 1200, current_amount: 0 }], rowCount: 1 })
        .mockResolvedValueOnce({ rows: [], rowCount: 0 }); 
      
      global.fetch.mockRejectedValueOnce(new Error('AI offline'));

      const res = await request(app).post('/api/v1/goals/g1/advice').set('Authorization', authHeader).send({ proposed_amount: 100 });
      
      expect(res.status).toBe(200);
      expect(res.body.suggestion).toBe('correct');
    });

    it('returns 500 on DB Error', async () => {
      db.query.mockRejectedValueOnce(new Error('DB down'));
      const res = await request(app).post('/api/v1/goals/g1/advice').set('Authorization', authHeader).send({ proposed_amount: 100 });
      expect(res.status).toBe(500);
    });
  });

  // ── Extra coverage: uncovered callbacks and branches ──────────────────────

  it('returns 403 for goals routes when JWT token is invalid', async () => {
    const res = await request(app)
      .get('/api/v1/goals')
      .set('Authorization', 'Bearer invalid.token.here');
    expect(res.status).toBe(403);
  });

  it('GET /:id/progress returns monthly_evolution data when contributions exist', async () => {
    db.query
      .mockResolvedValueOnce({ rows: [SAMPLE_GOAL], rowCount: 1 })
      .mockResolvedValueOnce({
        rows: [
          { month: '2026-01', total: '200', count: '3' },
          { month: '2026-02', total: '150', count: '2' },
        ],
        rowCount: 2,
      })
      .mockResolvedValueOnce({ rows: [{ total: '350' }], rowCount: 1 })
      .mockResolvedValueOnce({ rows: [{ total: '175' }], rowCount: 1 });

    const res = await request(app).get('/api/v1/goals/goal-uuid-1/progress').set('Authorization', authHeader);
    expect(res.status).toBe(200);
    expect(Array.isArray(res.body.monthly_evolution)).toBe(true);
    expect(res.body.monthly_evolution.length).toBe(2);
  });

  it('POST contributions: suppresses transaction insert error without crashing (covers catch callback)', async () => {
    db.query
      .mockResolvedValueOnce({ rows: [SAMPLE_GOAL], rowCount: 1 })         // find goal
      .mockResolvedValueOnce({ rows: [{ id: 'c1' }], rowCount: 1 })        // INSERT contribution
      .mockResolvedValueOnce({ rows: [], rowCount: 1 })                     // UPDATE goal amount
      .mockRejectedValueOnce(new Error('tx insert fail'))                   // INSERT transaction FAILS → caught
      .mockResolvedValueOnce({ rows: [{ total: '100' }], rowCount: 1 });   // getMonthlyRate

    const res = await request(app)
      .post('/api/v1/goals/goal-uuid-1/contributions')
      .set('Authorization', authHeader)
      .send({ amount: 100 });

    expect(res.status).toBe(201);
    expect(console.error).toHaveBeenCalledWith(
      expect.stringContaining('[goals] Warning'),
      expect.any(String)
    );
  });

  it('POST contributions: bank_account update failure is silenced (covers catch at line 536)', async () => {
    db.query
      .mockResolvedValueOnce({ rows: [SAMPLE_GOAL], rowCount: 1 })        // find goal
      .mockResolvedValueOnce({ rows: [{ id: 'c1' }], rowCount: 1 })       // INSERT contribution
      .mockResolvedValueOnce({ rows: [], rowCount: 1 })                    // UPDATE goal amount
      .mockResolvedValueOnce({ rows: [], rowCount: 1 })                    // INSERT transactions (success)
      .mockRejectedValueOnce(new Error('bank update fail'))                // UPDATE bank_accounts FAILS → catch()
      .mockResolvedValueOnce({ rows: [{ total: '100' }], rowCount: 1 });  // getMonthlyRate

    const res = await request(app)
      .post('/api/v1/goals/goal-uuid-1/contributions')
      .set('Authorization', authHeader)
      .send({ amount: 100, bank_account_id: 'bank-1' });

    expect(res.status).toBe(201);
  });

  it('POST contributions: notification insert failure is silenced when goal completes (covers catch at line 550)', async () => {
    const nearlyCompleteGoal = { ...SAMPLE_GOAL, target_amount: '1100.00', current_amount: '1000.00' };
    db.query
      .mockResolvedValueOnce({ rows: [nearlyCompleteGoal], rowCount: 1 }) // find goal
      .mockResolvedValueOnce({ rows: [{ id: 'c1' }], rowCount: 1 })       // INSERT contribution
      .mockResolvedValueOnce({ rows: [], rowCount: 1 })                    // UPDATE goal (completed)
      .mockResolvedValueOnce({ rows: [], rowCount: 1 })                    // INSERT transactions (success)
      .mockRejectedValueOnce(new Error('notifications table missing'))     // INSERT notifications FAILS → catch()
      .mockResolvedValueOnce({ rows: [{ total: '100' }], rowCount: 1 });  // getMonthlyRate

    const res = await request(app)
      .post('/api/v1/goals/goal-uuid-1/contributions')
      .set('Authorization', authHeader)
      .send({ amount: 100 }); // no bank_account_id so bank update is skipped

    expect(res.status).toBe(201);
    expect(res.body.goal_completed).toBe(true);
  });
});