'use strict';

jest.mock('../../services/db', () => require('../helpers/mockDb'));
jest.mock('../../services/email', () => ({
  sendVerificationEmail: jest.fn().mockResolvedValue({ success: true }),
  verifyConnection: jest.fn().mockResolvedValue(true),
}));
// Mock del motor de reglas para testear el fallback
jest.mock('../../services/categoryMapper', () => ({
  autoCategory: jest.fn().mockReturnValue({ category: 'Reglas Cat', confidence: 0.5 })
}));

const request = require('supertest');
const app = require('../../server');
const db = require('../../services/db');
const { autoCategory } = require('../../services/categoryMapper');
const { createTestToken } = require('../helpers/testHelpers');

const token = createTestToken(42, 'user@example.com');
const authHeader = `Bearer ${token}`;

const CAT_UUID = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';

const SAMPLE_CATEGORY = {
  id: CAT_UUID,
  name: 'Alimentación',
  type: 'expense',
  icon: 'food',
  color: '#FF5733',
  is_predefined: true,
  display_order: 1,
  created_at: new Date().toISOString(),
};

const VALID_CREATE_BODY = {
  name: 'Mi Categoría',
  type: 'expense',
  icon: 'star',
  color: '#AABBCC',
};

// Mock de fetch para el servicio AI
global.fetch = jest.fn();

// Silenciar console.error para no ensuciar el output de los tests
beforeAll(() => {
  jest.spyOn(console, 'error').mockImplementation(() => {});
});

afterAll(() => {
  console.error.mockRestore();
});

describe('Categories Routes', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    global.fetch.mockReset();
  });

  // ── GET /api/v1/categories ────────────────────────────────────────────────
  describe('GET /api/v1/categories', () => {
    it('returns 200 with list of categories', async () => {
      db.query.mockResolvedValueOnce({ rows: [SAMPLE_CATEGORY], rowCount: 1 });

      const res = await request(app)
        .get('/api/v1/categories')
        .set('Authorization', authHeader);

      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('categories');
    });

    it('returns 401 without auth token', async () => {
      const res = await request(app).get('/api/v1/categories');
      expect(res.status).toBe(401);
    });

    it('returns 500 on DB error', async () => {
      db.query.mockRejectedValueOnce(new Error('DB Error'));
      const res = await request(app).get('/api/v1/categories').set('Authorization', authHeader);
      expect(res.status).toBe(500);
    });
  });

  // ── GET /api/v1/categories/type/:type ─────────────────────────────────────
  describe('GET /api/v1/categories/type/:type', () => {
    it('returns 200 with filtered categories', async () => {
      db.query.mockResolvedValueOnce({ rows: [SAMPLE_CATEGORY], rowCount: 1 });
      const res = await request(app)
        .get('/api/v1/categories/type/expense')
        .set('Authorization', authHeader);
      expect(res.status).toBe(200);
    });

    it('returns 400 for invalid type', async () => {
      const res = await request(app)
        .get('/api/v1/categories/type/invalid')
        .set('Authorization', authHeader);
      expect(res.status).toBe(400);
    });

    it('returns 500 on DB error', async () => {
      db.query.mockRejectedValueOnce(new Error('DB Error'));
      const res = await request(app).get('/api/v1/categories/type/expense').set('Authorization', authHeader);
      expect(res.status).toBe(500);
    });
  });

  // ── POST /api/v1/categories ───────────────────────────────────────────────
  describe('POST /api/v1/categories', () => {
    it('returns 201 on successful creation', async () => {
      db.query
        .mockResolvedValueOnce({ rows: [], rowCount: 0 }) 
        .mockResolvedValueOnce({ rows: [{ next_order: 5 }], rowCount: 1 }) 
        .mockResolvedValueOnce({ 
          rows: [{ ...VALID_CREATE_BODY, id: 'new-cat-uuid', is_predefined: false, display_order: 5 }],
          rowCount: 1,
        });

      const res = await request(app)
        .post('/api/v1/categories')
        .set('Authorization', authHeader)
        .send(VALID_CREATE_BODY);

      expect(res.status).toBe(201);
    });

    it('returns 400 on validation errors', async () => {
      const res = await request(app)
        .post('/api/v1/categories')
        .set('Authorization', authHeader)
        .send({ ...VALID_CREATE_BODY, color: 'not-a-color' });
      expect(res.status).toBe(400);
    });

    it('returns 409 when category name already exists', async () => {
      db.query.mockResolvedValueOnce({ rows: [{ id: 'existing' }], rowCount: 1 });
      const res = await request(app)
        .post('/api/v1/categories')
        .set('Authorization', authHeader)
        .send(VALID_CREATE_BODY);
      expect(res.status).toBe(409);
    });

    it('returns 500 on DB error', async () => {
      db.query.mockRejectedValueOnce(new Error('DB Error'));
      const res = await request(app).post('/api/v1/categories').set('Authorization', authHeader).send(VALID_CREATE_BODY);
      expect(res.status).toBe(500);
    });
  });

  // ── PUT /api/v1/categories/:id ────────────────────────────────────────────
  describe('PUT /api/v1/categories/:id', () => {
    it('returns 200 on successful update of custom category', async () => {
      db.query
        .mockResolvedValueOnce({ rows: [{ ...SAMPLE_CATEGORY, is_predefined: false, id: CAT_UUID }] }) // check exists
        .mockResolvedValueOnce({ rows: [] }) // duplicate name check
        .mockResolvedValueOnce({ rows: [{ ...SAMPLE_CATEGORY, name: 'Updated Name', is_predefined: false }] }); // update

      const res = await request(app)
        .put(`/api/v1/categories/${CAT_UUID}`)
        .set('Authorization', authHeader)
        .send({ name: 'Updated Name' });

      expect(res.status).toBe(200);
    });

    it('returns 400 on validation errors', async () => {
      const res = await request(app)
        .put(`/api/v1/categories/${CAT_UUID}`)
        .set('Authorization', authHeader)
        .send({ color: 'invalid-hex' });
      expect(res.status).toBe(400);
    });

    it('returns 403 when trying to edit a predefined category', async () => {
      db.query.mockResolvedValueOnce({ rows: [{ ...SAMPLE_CATEGORY, is_predefined: true }] });
      const res = await request(app).put(`/api/v1/categories/${CAT_UUID}`).set('Authorization', authHeader).send({ name: 'Hacked' });
      expect(res.status).toBe(403);
    });

    it('returns 404 when category not found', async () => {
      db.query.mockResolvedValueOnce({ rows: [] });
      const res = await request(app).put(`/api/v1/categories/${CAT_UUID}`).set('Authorization', authHeader).send({ name: 'Name' });
      expect(res.status).toBe(404);
    });

    it('returns 409 when new name conflicts with existing one', async () => {
      db.query
        .mockResolvedValueOnce({ rows: [{ ...SAMPLE_CATEGORY, name: 'Old Name', is_predefined: false }] }) // exists
        .mockResolvedValueOnce({ rows: [{ id: 'conflict-id' }] }); // duplicate check finds conflict

      const res = await request(app)
        .put(`/api/v1/categories/${CAT_UUID}`)
        .set('Authorization', authHeader)
        .send({ name: 'Duplicate Name' });

      expect(res.status).toBe(409);
    });

    it('returns 500 on DB error', async () => {
      db.query.mockRejectedValueOnce(new Error('DB Error'));
      const res = await request(app).put(`/api/v1/categories/${CAT_UUID}`).set('Authorization', authHeader).send({ name: 'Name' });
      expect(res.status).toBe(500);
    });
  });

  // ── DELETE /api/v1/categories/:id ─────────────────────────────────────────
  describe('DELETE /api/v1/categories/:id', () => {
    it('returns 200 on successful delete', async () => {
      db.query
        .mockResolvedValueOnce({ rows: [{ ...SAMPLE_CATEGORY, is_predefined: false }] })
        .mockResolvedValueOnce({ rows: [{ cnt: '0' }] }) 
        .mockResolvedValueOnce({ rows: [] }); 

      const res = await request(app).delete(`/api/v1/categories/${CAT_UUID}`).set('Authorization', authHeader);
      expect(res.status).toBe(200);
    });

    it('returns 400 on validation error (invalid UUID)', async () => {
      const res = await request(app).delete(`/api/v1/categories/invalid-uuid`).set('Authorization', authHeader);
      expect(res.status).toBe(400);
    });

    it('returns 404 when category not found', async () => {
      db.query.mockResolvedValueOnce({ rows: [] });
      const res = await request(app).delete(`/api/v1/categories/${CAT_UUID}`).set('Authorization', authHeader);
      expect(res.status).toBe(404);
    });

    it('returns 403 when trying to delete predefined category', async () => {
      db.query.mockResolvedValueOnce({ rows: [{ ...SAMPLE_CATEGORY, is_predefined: true }] });
      const res = await request(app).delete(`/api/v1/categories/${CAT_UUID}`).set('Authorization', authHeader);
      expect(res.status).toBe(403);
    });

    it('returns 409 when category has associated transactions', async () => {
      db.query
        .mockResolvedValueOnce({ rows: [{ ...SAMPLE_CATEGORY, is_predefined: false }] })
        .mockResolvedValueOnce({ rows: [{ cnt: '5' }] });
      const res = await request(app).delete(`/api/v1/categories/${CAT_UUID}`).set('Authorization', authHeader);
      expect(res.status).toBe(409);
    });

    it('returns 500 on DB error', async () => {
      db.query.mockRejectedValueOnce(new Error('DB Error'));
      const res = await request(app).delete(`/api/v1/categories/${CAT_UUID}`).set('Authorization', authHeader);
      expect(res.status).toBe(500);
    });
  });

  // ── POST /api/v1/categories/auto-categorize ───────────────────────────────
  describe('POST /api/v1/categories/auto-categorize', () => {
    it('returns 200 using AI service on success', async () => {
      global.fetch.mockResolvedValueOnce({
        ok: true,
        json: async () => ({ category: 'AI Cat', confidence: 0.95, is_fallback: false })
      });

      const res = await request(app)
        .post('/api/v1/categories/auto-categorize')
        .set('Authorization', authHeader)
        .send({ description: 'Amazon', type: 'expense' });

      expect(res.status).toBe(200);
      expect(res.body.category).toBe('AI Cat');
      expect(res.body.method).toBe('ai');
    });

    it('returns 200 using fallback rule engine if AI fetch fails', async () => {
      global.fetch.mockRejectedValueOnce(new Error('Network Down')); // Fuerza el catch de autoCategoryWithAI

      const res = await request(app)
        .post('/api/v1/categories/auto-categorize')
        .set('Authorization', authHeader)
        .send({ description: 'Amazon', type: 'expense' });

      expect(res.status).toBe(200);
      expect(res.body.category).toBe('Reglas Cat'); // Viene del mock de categoryMapper
      expect(res.body.method).toBe('rules');
    });

    it('returns 400 when validation fails', async () => {
      const res = await request(app)
        .post('/api/v1/categories/auto-categorize')
        .set('Authorization', authHeader)
        .send({ type: 'expense' }); // falta description
      expect(res.status).toBe(400);
    });

    it('returns 500 on catastrophic internal error', async () => {
      // Hacemos que el fallback explote para forzar el catch() del router
      global.fetch.mockRejectedValueOnce(new Error('Network Down'));
      autoCategory.mockImplementationOnce(() => { throw new Error('Catastrophic Failure'); });

      const res = await request(app)
        .post('/api/v1/categories/auto-categorize')
        .set('Authorization', authHeader)
        .send({ description: 'Amazon', type: 'expense' });

      expect(res.status).toBe(500);
    });
  });

  // ── POST /api/v1/categories/feedback ──────────────────────────────────────
  describe('POST /api/v1/categories/feedback', () => {
    it('returns 200 on feedback submission', async () => {
      db.query.mockResolvedValueOnce({}); 
      const res = await request(app)
        .post('/api/v1/categories/feedback')
        .set('Authorization', authHeader)
        .send({ description: 'Repsol', type: 'expense', corrected_category: 'Transporte' });

      expect(res.status).toBe(200);
    });

    it('returns 400 on validation error', async () => {
      const res = await request(app)
        .post('/api/v1/categories/feedback')
        .set('Authorization', authHeader)
        .send({ type: 'expense' }); // faltan campos
      expect(res.status).toBe(400);
    });

    it('returns 500 if DB throws a synchronous exception', async () => {
      // Como el .catch() silencia rechazos asíncronos, forzamos un error sincrónico para testear la ruta del 500
      db.query.mockImplementationOnce(() => { throw new Error('Sync Error'); });

      const res = await request(app)
        .post('/api/v1/categories/feedback')
        .set('Authorization', authHeader)
        .send({ description: 'Repsol', type: 'expense', corrected_category: 'Transporte' });

      expect(res.status).toBe(500);
    });

    it('returns 200 when feedback INSERT rejects asynchronously (catch callback silences it)', async () => {
      db.query.mockRejectedValueOnce(new Error('table not found yet'));

      const res = await request(app)
        .post('/api/v1/categories/feedback')
        .set('Authorization', authHeader)
        .send({ description: 'Repsol', type: 'expense', corrected_category: 'Transporte' });

      expect(res.status).toBe(200);
    });
  });

  // ── POST /api/v1/categories/recategorize ─────────────────────────────────
  describe('POST /api/v1/categories/recategorize', () => {
    it('returns 200 with updated count and successfully logs feedback', async () => {
      db.query
        .mockResolvedValueOnce({ rows: [{ id: 'tx-1' }, { id: 'tx-2' }] }) // UPDATE transactions
        .mockResolvedValueOnce({}); // INSERT feedback (no devuelve nada importante)

      const res = await request(app)
        .post('/api/v1/categories/recategorize')
        .set('Authorization', authHeader)
        .send({ description: 'Mercadona', new_category: 'Supermercado', type: 'expense' });

      expect(res.status).toBe(200);
      expect(res.body.updated_count).toBe(2);
    });

    it('returns 400 on validation error', async () => {
      const res = await request(app).post('/api/v1/categories/recategorize').set('Authorization', authHeader).send({});
      expect(res.status).toBe(400);
    });

    it('returns 500 on DB error updating transactions', async () => {
      db.query.mockRejectedValueOnce(new Error('Update Failed'));

      const res = await request(app)
        .post('/api/v1/categories/recategorize')
        .set('Authorization', authHeader)
        .send({ description: 'Mercadona', new_category: 'Supermercado', type: 'expense' });

      expect(res.status).toBe(500);
    });

    it('returns 200 when recategorize feedback INSERT rejects (catch callback silences it)', async () => {
      db.query
        .mockResolvedValueOnce({ rows: [{ id: 'tx-1' }], rowCount: 1 }) // UPDATE transactions (1 row affected)
        .mockRejectedValueOnce(new Error('table not found yet'));         // INSERT feedback rejects → catch

      const res = await request(app)
        .post('/api/v1/categories/recategorize')
        .set('Authorization', authHeader)
        .send({ description: 'Mercadona', new_category: 'Supermercado', type: 'expense' });

      expect(res.status).toBe(200);
    });
  });

  // ── JWT error branches in authenticateToken ───────────────────────────────
  describe('Invalid token handling', () => {
    it('returns 401 with JsonWebTokenError when token is malformed', async () => {
      const res = await request(app)
        .get('/api/v1/categories')
        .set('Authorization', 'Bearer invalid.token.here');
      expect(res.status).toBe(401);
    });
  });
});