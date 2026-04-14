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

describe('Gamification Routes', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  // ── GET /api/v1/gamification/streaks ──────────────────────────────────────────
  describe('GET /api/v1/gamification/streaks', () => {
    it('returns 401 when no auth token provided', async () => {
      const res = await request(app).get('/api/v1/gamification/streaks');
      expect(res.status).toBe(401);
    });

    it('returns 200 with streaks array', async () => {
      db.query.mockResolvedValueOnce({
        rows: [
          { id: 's1', user_id: 42, streak_type: 'daily_login', current_count: 5, longest_count: 10, last_activity_date: '2026-04-10' },
        ],
        rowCount: 1,
      });

      const res = await request(app).get('/api/v1/gamification/streaks').set('Authorization', authHeader);

      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('streaks');
    });

    it('returns 500 on DB error', async () => {
      db.query.mockRejectedValueOnce(new Error('DB Failed'));
      const res = await request(app).get('/api/v1/gamification/streaks').set('Authorization', authHeader);
      expect(res.status).toBe(500);
    });
  });

  // ── POST /api/v1/gamification/streaks/record ──────────────────────────────────
  describe('POST /api/v1/gamification/streaks/record', () => {
    it('returns 400 when streak_type is missing', async () => {
      const res = await request(app).post('/api/v1/gamification/streaks/record').set('Authorization', authHeader).send({});
      expect(res.status).toBe(400);
    });

    it('returns 200 when recording a new streak type', async () => {
      db.query.mockResolvedValueOnce({ rows: [], rowCount: 0 }); // SELECT existing
      db.query.mockResolvedValueOnce({ rows: [], rowCount: 1 }); // INSERT
      db.query.mockResolvedValueOnce({ // SELECT updated
        rows: [{ id: 's1', streak_type: 'daily_login', current_count: 1, longest_count: 1 }],
        rowCount: 1,
      });

      const res = await request(app)
        .post('/api/v1/gamification/streaks/record')
        .set('Authorization', authHeader)
        .send({ streak_type: 'daily_login' });

      expect(res.status).toBe(200);
    });

    it('returns 200 and already_recorded if activity is from today', async () => {
      const todayStr = new Date().toISOString().split('T')[0];
      db.query.mockResolvedValueOnce({
        rows: [{ id: 's1', streak_type: 'daily_login', current_count: 3, longest_count: 5, last_activity_date: todayStr }],
        rowCount: 1,
      });

      const res = await request(app)
        .post('/api/v1/gamification/streaks/record')
        .set('Authorization', authHeader)
        .send({ streak_type: 'daily_login' });

      expect(res.status).toBe(200);
      expect(res.body.message).toBe('already_recorded');
    });

    it('returns 200 and increments count if activity was yesterday (consecutive)', async () => {
      const yesterday = new Date();
      yesterday.setDate(yesterday.getDate() - 1);
      
      db.query.mockResolvedValueOnce({
        rows: [{ id: 's1', streak_type: 'daily_login', current_count: 3, longest_count: 5, last_activity_date: yesterday.toISOString() }],
        rowCount: 1,
      }); // SELECT existing
      db.query.mockResolvedValueOnce({ rows: [], rowCount: 1 }); // UPDATE
      db.query.mockResolvedValueOnce({
        rows: [{ id: 's1', streak_type: 'daily_login', current_count: 4, longest_count: 5 }],
        rowCount: 1,
      }); // SELECT updated

      const res = await request(app)
        .post('/api/v1/gamification/streaks/record')
        .set('Authorization', authHeader)
        .send({ streak_type: 'daily_login' });

      expect(res.status).toBe(200);
      expect(res.body.streak.current_count).toBe(4);
    });

    it('returns 200 and resets count to 1 if streak is broken (older than yesterday)', async () => {
      const lastWeek = new Date();
      lastWeek.setDate(lastWeek.getDate() - 5);
      
      db.query.mockResolvedValueOnce({
        rows: [{ id: 's1', streak_type: 'daily_login', current_count: 3, longest_count: 5, last_activity_date: lastWeek.toISOString() }],
        rowCount: 1,
      }); // SELECT existing
      db.query.mockResolvedValueOnce({ rows: [], rowCount: 1 }); // UPDATE
      db.query.mockResolvedValueOnce({
        rows: [{ id: 's1', streak_type: 'daily_login', current_count: 1, longest_count: 5 }],
        rowCount: 1,
      }); // SELECT updated

      const res = await request(app)
        .post('/api/v1/gamification/streaks/record')
        .set('Authorization', authHeader)
        .send({ streak_type: 'daily_login' });

      expect(res.status).toBe(200);
      expect(res.body.streak.current_count).toBe(1); // Reseteado a 1
    });

    it('returns 500 on DB error', async () => {
      db.query.mockRejectedValueOnce(new Error('DB Failed'));
      const res = await request(app).post('/api/v1/gamification/streaks/record').set('Authorization', authHeader).send({ streak_type: 'login' });
      expect(res.status).toBe(500);
    });
  });

  // ── GET /api/v1/gamification/badges ───────────────────────────────────────────
  describe('GET /api/v1/gamification/badges', () => {
    it('returns 200 with badges list', async () => {
      db.query.mockResolvedValueOnce({
        rows: [{ id: 'b1', badge_key: 'first', is_earned: true }],
        rowCount: 1,
      });

      const res = await request(app).get('/api/v1/gamification/badges').set('Authorization', authHeader);
      expect(res.status).toBe(200);
    });

    it('returns 500 on DB error', async () => {
      db.query.mockRejectedValueOnce(new Error('DB Failed'));
      const res = await request(app).get('/api/v1/gamification/badges').set('Authorization', authHeader);
      expect(res.status).toBe(500);
    });
  });

  // ── POST /api/v1/gamification/badges/check ────────────────────────────────────
  describe('POST /api/v1/gamification/badges/check', () => {
    it('returns 200 and processes conditions (awarding some, skipping others)', async () => {
      db.query.mockResolvedValueOnce({ rows: [{ count: '15' }], rowCount: 1 }); // txCount
      db.query.mockResolvedValueOnce({ rows: [{ count: '2' }], rowCount: 1 }); // goalCount
      db.query.mockResolvedValueOnce({ rows: [{ max_streak: '8' }], rowCount: 1 }); // streakRow

      // first_transaction (met) -> badge lookup
      db.query.mockResolvedValueOnce({ rows: [{ id: 'b1' }], rowCount: 1 });
      db.query.mockResolvedValueOnce({ rows: [{}], rowCount: 1 }); // already earned

      // ten_transactions (met) -> badge lookup -> not earned yet -> insert
      db.query.mockResolvedValueOnce({ rows: [{ id: 'b2' }], rowCount: 1 });
      db.query.mockResolvedValueOnce({ rows: [], rowCount: 0 }); // not earned
      db.query.mockResolvedValueOnce({ rows: [], rowCount: 1 }); // INSERT

      // fifty_transactions (not met) -> skips automatically

      // first_goal_completed (met) -> badge lookup BUT badge not found in DB
      db.query.mockResolvedValueOnce({ rows: [], rowCount: 0 }); // missing badge in DB

      // three_goals_completed (not met) -> skips

      // streak_7 (met) -> badge lookup -> not earned yet -> insert
      db.query.mockResolvedValueOnce({ rows: [{ id: 'b4' }], rowCount: 1 });
      db.query.mockResolvedValueOnce({ rows: [], rowCount: 0 }); // not earned
      db.query.mockResolvedValueOnce({ rows: [], rowCount: 1 }); // INSERT

      const res = await request(app).post('/api/v1/gamification/badges/check').set('Authorization', authHeader);
      expect(res.status).toBe(200);
      expect(res.body.awarded).toContain('ten_transactions');
      expect(res.body.awarded).toContain('streak_7');
    });

    it('returns 500 on DB error', async () => {
      db.query.mockRejectedValueOnce(new Error('DB Failed'));
      const res = await request(app).post('/api/v1/gamification/badges/check').set('Authorization', authHeader);
      expect(res.status).toBe(500);
    });
  });

  // ── GET /api/v1/gamification/challenges ───────────────────────────────────────
  describe('GET /api/v1/gamification/challenges', () => {
    it('returns 200 with challenges list', async () => {
      db.query.mockResolvedValueOnce({ rows: [{ id: 'c1' }], rowCount: 1 });
      const res = await request(app).get('/api/v1/gamification/challenges').set('Authorization', authHeader);
      expect(res.status).toBe(200);
    });

    it('returns 500 on DB error', async () => {
      db.query.mockRejectedValueOnce(new Error('DB Failed'));
      const res = await request(app).get('/api/v1/gamification/challenges').set('Authorization', authHeader);
      expect(res.status).toBe(500);
    });
  });

  // ── POST /api/v1/gamification/challenges/:id/join ─────────────────────────────
  describe('POST /api/v1/gamification/challenges/:id/join', () => {
    it('returns 200 when joining', async () => {
      db.query.mockResolvedValueOnce({ rows: [], rowCount: 0 });
      db.query.mockResolvedValueOnce({ rows: [], rowCount: 1 });

      const res = await request(app).post('/api/v1/gamification/challenges/c1/join').set('Authorization', authHeader);
      expect(res.status).toBe(200);
    });

    it('returns 409 if already joined', async () => {
      db.query.mockResolvedValueOnce({ rows: [{ id: 'uc1' }], rowCount: 1 });
      const res = await request(app).post('/api/v1/gamification/challenges/c1/join').set('Authorization', authHeader);
      expect(res.status).toBe(409);
    });

    it('returns 500 on DB error', async () => {
      db.query.mockRejectedValueOnce(new Error('DB Failed'));
      const res = await request(app).post('/api/v1/gamification/challenges/c1/join').set('Authorization', authHeader);
      expect(res.status).toBe(500);
    });
  });

  // ── PATCH /api/v1/gamification/challenges/:id/progress ────────────────────────
  describe('PATCH /api/v1/gamification/challenges/:id/progress', () => {
    it('returns 200 with updated progress', async () => {
      db.query.mockResolvedValueOnce({ rows: [{ id: 'c1', target_value: 100 }], rowCount: 1 });
      db.query.mockResolvedValueOnce({ rows: [], rowCount: 1 });

      const res = await request(app).patch('/api/v1/gamification/challenges/c1/progress').set('Authorization', authHeader).send({ progress: 100 });
      expect(res.status).toBe(200);
      expect(res.body.is_completed).toBe(true);
    });

    it('returns 404 when challenge not found', async () => {
      db.query.mockResolvedValueOnce({ rows: [], rowCount: 0 });
      const res = await request(app).patch('/api/v1/gamification/challenges/c1/progress').set('Authorization', authHeader).send({ progress: 10 });
      expect(res.status).toBe(404);
    });

    it('returns 400 if progress is missing', async () => {
      const res = await request(app).patch('/api/v1/gamification/challenges/c1/progress').set('Authorization', authHeader).send({});
      expect(res.status).toBe(400);
    });

    it('returns 500 on DB error', async () => {
      db.query.mockRejectedValueOnce(new Error('DB Failed'));
      const res = await request(app).patch('/api/v1/gamification/challenges/c1/progress').set('Authorization', authHeader).send({ progress: 10 });
      expect(res.status).toBe(500);
    });
  });

  // ── GET /api/v1/gamification/health-score ─────────────────────────────────────
  describe('GET /api/v1/gamification/health-score', () => {
    it('returns 200 with excellent score (A+)', async () => {
      // Para A+ forzamos 100% en todo:
      db.query.mockResolvedValueOnce({ rows: [{ limit_amount: '500', spent: '0' }], rowCount: 1 }); // 100% budget
      db.query.mockResolvedValueOnce({ rows: [{ type: 'income', total: '5000' }, { type: 'expense', total: '0' }], rowCount: 2 }); // 100% ahorro
      db.query.mockResolvedValueOnce({ rows: [{ avg_progress: '100' }], rowCount: 1 }); // 100% goals
      db.query.mockResolvedValueOnce({ rows: [{ max: '30' }], rowCount: 1 }); // max streak (bonus +20)

      const res = await request(app).get('/api/v1/gamification/health-score').set('Authorization', authHeader);
      expect(res.status).toBe(200);
      expect(res.body.grade).toBe('A+');
    });

    it('returns 200 with fallback defaults for new users (C / D range)', async () => {
      db.query.mockResolvedValueOnce({ rows: [], rowCount: 0 }); // No budgets -> 50
      db.query.mockResolvedValueOnce({ rows: [], rowCount: 0 }); // No income -> 0
      db.query.mockResolvedValueOnce({ rows: [{ avg_progress: null }], rowCount: 1 }); // No active goals -> 50
      db.query.mockResolvedValueOnce({ rows: [{ max: '0' }], rowCount: 1 }); // ¡VITAL! Enviar '0' en vez de null para evitar NaN

      const res = await request(app).get('/api/v1/gamification/health-score').set('Authorization', authHeader);
      expect(res.status).toBe(200);
      expect(res.body.score).toBe(28);
      expect(res.body.grade).toBe('D');
    });

    it('returns 500 on DB error', async () => {
      db.query.mockRejectedValueOnce(new Error('DB Failed'));
      const res = await request(app).get('/api/v1/gamification/health-score').set('Authorization', authHeader);
      expect(res.status).toBe(500);
    });
  });
});