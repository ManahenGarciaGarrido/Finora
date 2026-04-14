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

function makeNotificationRow(overrides = {}) {
  return {
    id: 'notif-uuid-1',
    type: 'new_transaction',
    title: 'Nueva transacción',
    body: 'Se ha registrado un gasto de 50€',
    metadata: null,
    read_at: null,
    created_at: new Date().toISOString(),
    ...overrides,
  };
}

describe('Notifications Routes', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  // ── GET /api/v1/notifications ─────────────────────────────────────────────
  describe('GET /api/v1/notifications', () => {
    it('returns 401 without auth', async () => {
      const res = await request(app).get('/api/v1/notifications');
      expect(res.status).toBe(401);
    });

    it('returns 200 with paginated notifications', async () => {
      db.query
        .mockResolvedValueOnce({ rows: [makeNotificationRow()], rowCount: 1 }) // notifications list
        .mockResolvedValueOnce({ rows: [{ cnt: '3' }], rowCount: 1 }); // unread count

      const res = await request(app)
        .get('/api/v1/notifications')
        .set('Authorization', authHeader);

      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('notifications');
      expect(res.body).toHaveProperty('unread_count');
      expect(res.body).toHaveProperty('total');
      expect(Array.isArray(res.body.notifications)).toBe(true);
    });

    it('returns 200 with page=2', async () => {
      db.query
        .mockResolvedValueOnce({ rows: [makeNotificationRow()], rowCount: 1 })
        .mockResolvedValueOnce({ rows: [{ cnt: '0' }], rowCount: 1 });

      const res = await request(app)
        .get('/api/v1/notifications?page=2&limit=20')
        .set('Authorization', authHeader);

      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('notifications');
    });

    it('returns 200 with empty notifications list', async () => {
      db.query
        .mockResolvedValueOnce({ rows: [], rowCount: 0 })
        .mockResolvedValueOnce({ rows: [{ cnt: '0' }], rowCount: 1 });

      const res = await request(app)
        .get('/api/v1/notifications')
        .set('Authorization', authHeader);

      expect(res.status).toBe(200);
      expect(res.body.notifications).toHaveLength(0);
      expect(res.body.unread_count).toBe(0);
    });

    it('returns 500 on DB error', async () => {
      db.query.mockRejectedValueOnce(new Error('DB Failed'));

      const res = await request(app)
        .get('/api/v1/notifications')
        .set('Authorization', authHeader);

      expect(res.status).toBe(500);
    });
  });

  // ── PUT /api/v1/notifications/read-all ───────────────────────────────────
  describe('PUT /api/v1/notifications/read-all', () => {
    it('returns 200 and marks all as read', async () => {
      db.query.mockResolvedValueOnce({
        rows: [{ id: 'n1' }, { id: 'n2' }],
        rowCount: 2,
      });

      const res = await request(app)
        .put('/api/v1/notifications/read-all')
        .set('Authorization', authHeader);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.marked).toBe(2);
    });

    it('returns 200 even when no unread notifications', async () => {
      db.query.mockResolvedValueOnce({ rows: [], rowCount: 0 });

      const res = await request(app)
        .put('/api/v1/notifications/read-all')
        .set('Authorization', authHeader);

      expect(res.status).toBe(200);
      expect(res.body.marked).toBe(0);
    });

    it('returns 500 on DB error', async () => {
      db.query.mockRejectedValueOnce(new Error('DB Failed'));

      const res = await request(app)
        .put('/api/v1/notifications/read-all')
        .set('Authorization', authHeader);

      expect(res.status).toBe(500);
    });
  });

  // ── PUT /api/v1/notifications/:id/read ────────────────────────────────────
  describe('PUT /api/v1/notifications/:id/read', () => {
    it('returns 200 when marking a notification as read', async () => {
      db.query.mockResolvedValueOnce({ rows: [{ id: 'notif-uuid-1' }], rowCount: 1 });

      const res = await request(app)
        .put('/api/v1/notifications/notif-uuid-1/read')
        .set('Authorization', authHeader);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
    });

    it('returns 404 when notification not found', async () => {
      db.query.mockResolvedValueOnce({ rows: [], rowCount: 0 });

      const res = await request(app)
        .put('/api/v1/notifications/non-existent-id/read')
        .set('Authorization', authHeader);

      expect(res.status).toBe(404);
    });

    it('returns 500 on DB error', async () => {
      db.query.mockRejectedValueOnce(new Error('DB Failed'));

      const res = await request(app)
        .put('/api/v1/notifications/notif-uuid-1/read')
        .set('Authorization', authHeader);

      expect(res.status).toBe(500);
    });
  });

  // ── DELETE /api/v1/notifications/:id ─────────────────────────────────────
  describe('DELETE /api/v1/notifications/:id', () => {
    it('returns 200 when deleting a notification', async () => {
      db.query.mockResolvedValueOnce({ rows: [{ id: 'notif-uuid-1' }], rowCount: 1 });

      const res = await request(app)
        .delete('/api/v1/notifications/notif-uuid-1')
        .set('Authorization', authHeader);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
    });

    it('returns 404 when notification not found', async () => {
      db.query.mockResolvedValueOnce({ rows: [], rowCount: 0 });

      const res = await request(app)
        .delete('/api/v1/notifications/non-existent-id')
        .set('Authorization', authHeader);

      expect(res.status).toBe(404);
    });

    it('returns 500 on DB error', async () => {
      db.query.mockRejectedValueOnce(new Error('DB Failed'));

      const res = await request(app)
        .delete('/api/v1/notifications/notif-uuid-1')
        .set('Authorization', authHeader);

      expect(res.status).toBe(500);
    });
  });

  // ── POST /api/v1/notifications/register-token ────────────────────────────
  describe('POST /api/v1/notifications/register-token', () => {
    it('returns 200 when registering a push token', async () => {
      db.query.mockResolvedValueOnce({ rows: [], rowCount: 1 });

      const res = await request(app)
        .post('/api/v1/notifications/register-token')
        .set('Authorization', authHeader)
        .send({ token: 'fcm-device-token-abc123', platform: 'android' });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
    });

    it('returns 200 when registering a push token with unknown platform', async () => {
      db.query.mockResolvedValueOnce({ rows: [], rowCount: 1 });

      const res = await request(app)
        .post('/api/v1/notifications/register-token')
        .set('Authorization', authHeader)
        .send({ token: 'fcm-device-token-abc123' }); // missing platform falls back to unknown

      expect(res.status).toBe(200);
    });

    it('returns 422 when token is missing', async () => {
      const res = await request(app)
        .post('/api/v1/notifications/register-token')
        .set('Authorization', authHeader)
        .send({ platform: 'ios' });

      expect(res.status).toBe(422);
    });

    it('returns 500 on DB error', async () => {
      db.query.mockRejectedValueOnce(new Error('DB Failed'));

      const res = await request(app)
        .post('/api/v1/notifications/register-token')
        .set('Authorization', authHeader)
        .send({ token: 'fcm-device-token-abc123', platform: 'android' });

      expect(res.status).toBe(500);
    });
  });

  // ── GET /api/v1/notifications/settings ───────────────────────────────────
  describe('GET /api/v1/notifications/settings', () => {
    it('returns 200 with notification settings', async () => {
      db.query.mockResolvedValueOnce({
        rows: [{
          push_new_transactions: true,
          push_budget_alerts: true,
          push_goal_reminders: false,
          push_min_amount: 10,
          push_quiet_hours_enabled: true,
          push_quiet_start: '22:00',
          push_quiet_end: '08:00',
        }],
        rowCount: 1,
      });

      const res = await request(app)
        .get('/api/v1/notifications/settings')
        .set('Authorization', authHeader);

      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('push_new_transactions');
      expect(res.body).toHaveProperty('push_budget_alerts');
    });

    it('returns 200 with defaults when no settings exist', async () => {
      db.query.mockResolvedValueOnce({ rows: [], rowCount: 0 });

      const res = await request(app)
        .get('/api/v1/notifications/settings')
        .set('Authorization', authHeader);

      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('push_new_transactions', true);
    });

    it('returns 500 on DB error', async () => {
      db.query.mockRejectedValueOnce(new Error('DB Failed'));

      const res = await request(app)
        .get('/api/v1/notifications/settings')
        .set('Authorization', authHeader);

      expect(res.status).toBe(500);
    });
  });

  // ── PUT /api/v1/notifications/settings ───────────────────────────────────
  describe('PUT /api/v1/notifications/settings', () => {
    it('returns 200 when updating settings', async () => {
      db.query.mockResolvedValueOnce({ rows: [], rowCount: 1 });

      const res = await request(app)
        .put('/api/v1/notifications/settings')
        .set('Authorization', authHeader)
        .send({
          push_new_transactions: false,
          push_budget_alerts: true,
          push_min_amount: 5,
        });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
    });

    it('returns 500 on DB error', async () => {
      db.query.mockRejectedValueOnce(new Error('DB Failed'));

      const res = await request(app)
        .put('/api/v1/notifications/settings')
        .set('Authorization', authHeader)
        .send({ push_new_transactions: false });

      expect(res.status).toBe(500);
    });
  });
});