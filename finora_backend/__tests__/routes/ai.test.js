'use strict';

jest.mock('../../services/db', () => require('../helpers/mockDb'));

// Mock the global fetch used by callAiService and the Ollama chat endpoint
global.fetch = jest.fn();

const request = require('supertest');
const app = require('../../server');
const db = require('../../services/db');
const { createTestToken } = require('../helpers/testHelpers');

const testUserId = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';
const testTxId = 'b1eebc99-9c0b-4ef8-bb6d-6bb9bd380a22';
const token = createTestToken(testUserId, 'user@example.com');
const authHeader = `Bearer ${token}`;

// Helper: mock a successful AI service response
function mockAiFetch(responseBody) {
  global.fetch.mockResolvedValueOnce({
    ok: true,
    json: async () => responseBody,
    text: async () => JSON.stringify(responseBody),
    status: 200,
  });
}

// Helper: mock an AI service HTTP error (not a network crash, but a 500 from python)
function mockAiFetchHttpError(status = 500, message = 'Internal Server Error') {
  global.fetch.mockResolvedValueOnce({
    ok: false,
    text: async () => message,
    status: status,
  });
}

// Helper: mock a failed AI service (network failure / connection refused)
function mockAiFetchNetworkFail(errorCode = 'ECONNREFUSED') {
  const err = new Error('fetch failed');
  err.cause = { code: errorCode };
  global.fetch.mockRejectedValueOnce(err);
}

// Helper: mock DB transaction rows
function mockEmptyTransactions() {
  db.query.mockResolvedValueOnce({ rows: [], rowCount: 0 }); // getUserTransactions
}

function mockTransactionRows(count = 1) {
  const rows = Array(count).fill({
    id: testTxId,
    amount: 50.0,
    type: 'expense',
    category: 'Alimentación',
    description: 'Mercadona',
    date: '2026-03-15'
  });
  db.query.mockResolvedValueOnce({ rows, rowCount: count });
}

function mockIncomeAvg(value = 2000) {
  db.query.mockResolvedValueOnce({
    rows: [{ avg_income: value }],
    rowCount: 1,
  });
}

// Para limpiar la consola de errores controlados durante los tests
beforeAll(() => {
  jest.spyOn(console, 'error').mockImplementation(() => {});
  jest.spyOn(console, 'warn').mockImplementation(() => {});
});

afterAll(() => {
  console.error.mockRestore();
  console.warn.mockRestore();
});

describe('AI Routes', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    global.fetch.mockReset();
  });

  // ── Auth guard ─────────────────────────────────────────────────────────────
  describe('Authentication check', () => {
    it('returns 401 without auth token', async () => {
      const res = await request(app).get('/api/v1/ai/context');
      expect(res.status).toBe(401);
    });

    it('returns 403 with invalid token', async () => {
      const res = await request(app)
        .get('/api/v1/ai/context')
        .set('Authorization', 'Bearer invalid_token');
      expect(res.status).toBe(403);
    });
  });

  // ── POST /api/v1/ai/predict-expenses ──────────────────────────────────────
  describe('POST /api/v1/ai/predict-expenses', () => {
    it('returns 200 with predictions array', async () => {
      mockTransactionRows();
      mockAiFetch({
        predictions: [{ categoria: 'Alimentación', prediccion: 200, trend: 'stable' }],
        total_predicted: 200,
      });

      const res = await request(app)
        .post('/api/v1/ai/predict-expenses')
        .set('Authorization', authHeader);

      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('predictions');
    });

    it('returns 200 with empty predictions when no transactions', async () => {
      mockEmptyTransactions();
      const res = await request(app).post('/api/v1/ai/predict-expenses').set('Authorization', authHeader);
      expect(res.status).toBe(200);
      expect(res.body.predictions).toHaveLength(0);
    });

    it('returns 503 when AI service returns HTTP Error (!response.ok)', async () => {
      mockTransactionRows();
      mockAiFetchHttpError(500, 'Python exception');

      const res = await request(app).post('/api/v1/ai/predict-expenses').set('Authorization', authHeader);
      
      expect(res.status).toBe(503);
      expect(res.body.detail).toMatch(/AI service returned 500/);
    });
  });

  // ── POST /api/v1/ai/savings ───────────────────────────────────────────────
  describe('POST /api/v1/ai/savings', () => {
    it('returns 200 with recommendations', async () => {
      mockTransactionRows();
      mockIncomeAvg(2000);
      mockAiFetch({
        recommendations: [{ message: 'Reduce spending', saving_potential: 50 }],
        savings_potential: 50,
      });

      const res = await request(app).post('/api/v1/ai/savings').set('Authorization', authHeader).send({ months: 3 });
      expect(res.status).toBe(200);
    });

    it('returns 503 when AI service network fails', async () => {
      mockTransactionRows();
      mockIncomeAvg();
      mockAiFetchNetworkFail();

      const res = await request(app).post('/api/v1/ai/savings').set('Authorization', authHeader);
      expect(res.status).toBe(503);
    });
  });

  // ── POST /api/v1/ai/evaluate-savings-goal ────────────────────────────────
  describe('POST /api/v1/ai/evaluate-savings-goal', () => {
    it('returns 200 with es_realista field', async () => {
      mockTransactionRows();
      mockIncomeAvg(2000);
      mockAiFetch({ es_realista: true, ahorro_recomendado: 300 });

      const res = await request(app)
        .post('/api/v1/ai/evaluate-savings-goal')
        .set('Authorization', authHeader)
        .send({ goal: { monto_total: 3000, plazo_meses: 12 } });

      expect(res.status).toBe(200);
      expect(res.body.es_realista).toBe(true);
    });

    it('returns 400 when goal fields are missing', async () => {
      const res = await request(app)
        .post('/api/v1/ai/evaluate-savings-goal')
        .set('Authorization', authHeader)
        .send({ goal: { monto_total: 3000 } }); 
      expect(res.status).toBe(400);
    });

    it('returns 503 on service error', async () => {
      mockTransactionRows();
      mockIncomeAvg(2000);
      mockAiFetchNetworkFail();
      
      const res = await request(app)
        .post('/api/v1/ai/evaluate-savings-goal')
        .set('Authorization', authHeader)
        .send({ goal: { monto_total: 3000, plazo_meses: 12 } });
      
      expect(res.status).toBe(503);
    });
  });

  // ── GET /api/v1/ai/anomalies ──────────────────────────────────────────────
  describe('GET /api/v1/ai/anomalies', () => {
    it('returns 200 with anomalies', async () => {
      mockTransactionRows();
      mockAiFetch({ anomalies: [], total_anomalies: 0, categories_analyzed: 1 });

      const res = await request(app).get('/api/v1/ai/anomalies').set('Authorization', authHeader);
      expect(res.status).toBe(200);
    });

    it('returns 200 with empty anomalies when no transactions', async () => {
      mockEmptyTransactions();
      const res = await request(app).get('/api/v1/ai/anomalies').set('Authorization', authHeader);
      expect(res.status).toBe(200);
    });

    it('returns 503 when AI service fails', async () => {
      mockTransactionRows();
      mockAiFetchNetworkFail();
      const res = await request(app).get('/api/v1/ai/anomalies').set('Authorization', authHeader);
      expect(res.status).toBe(503);
    });
  });

  // ── GET /api/v1/ai/subscriptions ──────────────────────────────────────────
  describe('GET /api/v1/ai/subscriptions', () => {
    it('returns 200 with subscriptions list', async () => {
      mockTransactionRows();
      mockAiFetch({ subscriptions: [] });

      const res = await request(app).get('/api/v1/ai/subscriptions').set('Authorization', authHeader);
      expect(res.status).toBe(200);
    });

    it('returns 200 when no transactions', async () => {
      mockEmptyTransactions();
      const res = await request(app).get('/api/v1/ai/subscriptions').set('Authorization', authHeader);
      expect(res.status).toBe(200);
    });

    it('returns 503 when AI service fails', async () => {
      mockTransactionRows();
      mockAiFetchNetworkFail();
      const res = await request(app).get('/api/v1/ai/subscriptions').set('Authorization', authHeader);
      expect(res.status).toBe(503);
    });
  });

  // ── POST /api/v1/ai/chat ──────────────────────────────────────────────────
  describe('POST /api/v1/ai/chat', () => {
    const mockChatDbQueries = () => {
      db.query
        .mockResolvedValueOnce({ rows: [{ total: 1500 }] }) // balance
        .mockResolvedValueOnce({ rows: [{ income: 2000, expenses: 1200 }] }) // flow
        .mockResolvedValueOnce({ rows: [{ category: 'Alimentación', total: 300 }] }) // categories
        .mockResolvedValueOnce({ rows: [] }); // recent transactions
    };

    it('returns 200 with response string', async () => {
      mockChatDbQueries();
      global.fetch.mockResolvedValueOnce({
        ok: true,
        json: async () => ({ message: { content: 'Tu saldo es de 1500 EUR.' } }),
        status: 200,
      });

      const res = await request(app).post('/api/v1/ai/chat').set('Authorization', authHeader).send({ message: 'Hola' });
      expect(res.status).toBe(200);
      expect(res.body.response).toBe('Tu saldo es de 1500 EUR.');
    });

    it('returns 400 when message is missing', async () => {
      const res = await request(app).post('/api/v1/ai/chat').set('Authorization', authHeader).send({});
      expect(res.status).toBe(400);
    });

    it('returns 502 when Ollama returns HTTP Error (!ok)', async () => {
      mockChatDbQueries();
      global.fetch.mockResolvedValueOnce({ ok: false, text: async () => 'Model not found', status: 404 });
      
      const res = await request(app).post('/api/v1/ai/chat').set('Authorization', authHeader).send({ message: 'Hola' });
      expect(res.status).toBe(502);
    });

    it('returns 502 when Ollama response is empty/malformed', async () => {
      mockChatDbQueries();
      global.fetch.mockResolvedValueOnce({ ok: true, json: async () => ({}), status: 200 }); // missing message.content
      
      const res = await request(app).post('/api/v1/ai/chat').set('Authorization', authHeader).send({ message: 'Hola' });
      expect(res.status).toBe(502);
    });

    it('returns 503 for specific network errors (ECONNREFUSED)', async () => {
      mockChatDbQueries();
      mockAiFetchNetworkFail('ECONNREFUSED');

      const res = await request(app).post('/api/v1/ai/chat').set('Authorization', authHeader).send({ message: 'Hola' });
      expect(res.status).toBe(503);
    });

    it('returns 500 for generic unhandled errors', async () => {
      mockChatDbQueries();
      const err = new Error('Random catastrophic failure');
      err.cause = { code: 'UNKNOWN_CODE' };
      global.fetch.mockRejectedValueOnce(err);

      const res = await request(app).post('/api/v1/ai/chat').set('Authorization', authHeader).send({ message: 'Hola' });
      expect(res.status).toBe(500);
    });
  });

  // ── GET /api/v1/ai/context ────────────────────────────────────────────────
  describe('GET /api/v1/ai/context', () => {
    it('returns 200 with context data', async () => {
      db.query
        .mockResolvedValueOnce({ rows: [{ total: 1500 }] }) 
        .mockResolvedValueOnce({ rows: [{ income: 2000, expenses: 1200 }] }) 
        .mockResolvedValueOnce({ rows: [{ category: 'Alimentación', total: 300 }] }); 

      const res = await request(app).get('/api/v1/ai/context').set('Authorization', authHeader);
      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('balance_total', 1500);
    });

    it('returns 500 when DB query fails', async () => {
      db.query.mockRejectedValueOnce(new Error('DB connection lost'));
      
      const res = await request(app).get('/api/v1/ai/context').set('Authorization', authHeader);
      expect(res.status).toBe(500);
    });
  });

  // ── POST /api/v1/ai/affordability ─────────────────────────────────────────
  describe('POST /api/v1/ai/affordability', () => {
    it('returns 200 with can_afford and verdict', async () => {
      mockTransactionRows();
      mockIncomeAvg(2000);
      mockAiFetch({ can_afford: true, verdict: 'Sí' });

      const res = await request(app).post('/api/v1/ai/affordability').set('Authorization', authHeader).send({ query: 'iPhone' });
      expect(res.status).toBe(200);
    });

    it('returns 400 when query is missing', async () => {
      const res = await request(app).post('/api/v1/ai/affordability').set('Authorization', authHeader).send({});
      expect(res.status).toBe(400);
    });

    it('returns 503 when AI service fails', async () => {
      mockTransactionRows();
      mockIncomeAvg(2000);
      mockAiFetchNetworkFail();
      const res = await request(app).post('/api/v1/ai/affordability').set('Authorization', authHeader).send({ query: 'iPhone' });
      expect(res.status).toBe(503);
    });
  });

  // ── GET /api/v1/ai/recommendations ────────────────────────────────────────
  describe('GET /api/v1/ai/recommendations', () => {
    it('returns 200 with recommendations', async () => {
      mockTransactionRows();
      mockIncomeAvg(2000);
      mockAiFetch({ recommendations: [], total_saving_potential: 100 });

      const res = await request(app).get('/api/v1/ai/recommendations').set('Authorization', authHeader);
      expect(res.status).toBe(200);
    });

    it('returns 200 with empty recommendations when no transactions', async () => {
      mockEmptyTransactions();
      mockIncomeAvg(0);
      const res = await request(app).get('/api/v1/ai/recommendations').set('Authorization', authHeader);
      expect(res.status).toBe(200);
    });

    it('returns 503 when AI service fails', async () => {
      mockTransactionRows();
      mockIncomeAvg(2000);
      mockAiFetchNetworkFail();
      const res = await request(app).get('/api/v1/ai/recommendations').set('Authorization', authHeader);
      expect(res.status).toBe(503);
    });
  });

  // ── POST /api/v1/ai/check-anomaly (FIRE AND FORGET) ────────────────────────
  describe('POST /api/v1/ai/check-anomaly', () => {
    it('returns 202 immediately and logs notification if anomaly detected', async () => {
      // Necesitamos simular 6 transacciones para que pase la validación (transactions.length < 6 return)
      mockTransactionRows(6); 
      mockAiFetch({
        anomalies: [{ id: testTxId, message: 'Inusual', category: 'Ocio', amount: 100, z_score: 2.5 }]
      });
      db.query.mockResolvedValueOnce({}); // INSERT notification query

      const res = await request(app)
        .post('/api/v1/ai/check-anomaly')
        .set('Authorization', authHeader)
        .send({ transaction_id: testTxId, amount: 100, category: 'Ocio', type: 'expense' });

      // Responde 202 al instante
      expect(res.status).toBe(202);

      // Le damos un respiro al event loop para que termine la promesa flotante (background process)
      await new Promise(resolve => setTimeout(resolve, 50));

      // Verificamos que se hicieron EXACTAMENTE 2 queries (getTxs + insertNotification)
      expect(db.query).toHaveBeenCalledTimes(2);
      expect(db.query.mock.calls[1][0]).toMatch(/INSERT INTO notifications/);
    });

    it('returns 202 and does nothing if transaction is not expense', async () => {
      const res = await request(app)
        .post('/api/v1/ai/check-anomaly')
        .set('Authorization', authHeader)
        .send({ transaction_id: testTxId, amount: 100, type: 'income' });

      expect(res.status).toBe(202);
      await new Promise(resolve => setTimeout(resolve, 10));
      expect(db.query).not.toHaveBeenCalled();
    });

    it('returns 202 and stops if user history is < 6 months', async () => {
      mockTransactionRows(3); // Solo 3, se aborta

      const res = await request(app)
        .post('/api/v1/ai/check-anomaly')
        .set('Authorization', authHeader)
        .send({ transaction_id: testTxId, amount: 100, type: 'expense' });

      expect(res.status).toBe(202);
      await new Promise(resolve => setTimeout(resolve, 10));
      // Hizo el getUserTransactions pero NO el fetch ni el INSERT
      expect(db.query).toHaveBeenCalledTimes(1);
      expect(global.fetch).not.toHaveBeenCalled();
    });

    it('catches and logs errors silently in background without crashing', async () => {
      mockTransactionRows(6);
      mockAiFetchNetworkFail('ECONNREFUSED'); // Forzamos fallo de IA

      const res = await request(app)
        .post('/api/v1/ai/check-anomaly')
        .set('Authorization', authHeader)
        .send({ transaction_id: testTxId, amount: 100, type: 'expense' });

      expect(res.status).toBe(202);
      await new Promise(resolve => setTimeout(resolve, 50));
      
      // console.warn debería haber sido llamado por el catch background
      expect(console.warn).toHaveBeenCalledWith(
        expect.stringContaining('[RF-23] check-anomaly background error:'),
        expect.any(String)
      );
    });
  });
});