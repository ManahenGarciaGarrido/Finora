'use strict';

jest.mock('../../services/db', () => require('../helpers/mockDb'));
jest.mock('../../services/email', () => ({
  sendVerificationEmail: jest.fn().mockResolvedValue({ success: true }),
  verifyConnection: jest.fn().mockResolvedValue(true),
}));

global.fetch = jest.fn();

const request = require('supertest');
const app = require('../../server');
const db = require('../../services/db');
const { createTestToken } = require('../helpers/testHelpers');

const token = createTestToken(42, 'user@example.com');
const authHeader = `Bearer ${token}`;

const VALID_TX = {
  amount: 50.00,
  type: 'expense',
  category: 'Alimentación',
  description: 'Mercadona purchase',
  date: '2026-04-01',
  payment_method: 'card',
};

// UUIDs válidos para evitar errores 400 de validación en cascada
const TX_UUID = 'b1eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';
const VALID_BANK_ACC_ID = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';
const VALID_CARD_ID_1 = 'c2eebc99-9c0b-4ef8-bb6d-6bb9bd380a33';
const VALID_CARD_ID_2 = 'd3eebc99-9c0b-4ef8-bb6d-6bb9bd380a44';

function makeTransactionRow(overrides = {}) {
  return {
    id: TX_UUID,
    user_id: 42,
    amount: '50.00',
    type: 'expense',
    category: 'Alimentación',
    description: 'Mercadona purchase',
    date: '2026-04-01',
    payment_method: 'card',
    bank_account_id: null,
    card_id: null,
    created_at: new Date().toISOString(),
    _total_count: '1',
    _total_income: '0',
    _total_expense: '50',
    ...overrides,
  };
}

beforeAll(() => {
  jest.spyOn(console, 'error').mockImplementation(() => {});
  jest.spyOn(console, 'warn').mockImplementation(() => {});
});

afterAll(() => {
  console.error.mockRestore();
  console.warn.mockRestore();
});

describe('Transactions Routes', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    global.fetch.mockReset();
  });

  // ── GET /api/v1/transactions ──────────────────────────────────────────────
  describe('GET /api/v1/transactions', () => {
    it('returns 401 without auth', async () => {
      const res = await request(app).get('/api/v1/transactions');
      expect(res.status).toBe(401);
    });

    it('returns 200 with paginated transactions', async () => {
      db.query.mockResolvedValueOnce({ rows: [makeTransactionRow()], rowCount: 1 });
      const res = await request(app).get('/api/v1/transactions').set('Authorization', authHeader);
      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('transactions');
    });

    it('returns 200 and applies all filters successfully', async () => {
      db.query.mockResolvedValueOnce({ rows: [makeTransactionRow()], rowCount: 1 });
      const res = await request(app)
        .get(`/api/v1/transactions?type=expense&categories=Alimentación,Ocio&payment_method=card&from=2026-01-01&to=2026-12-31&bank_account_id=${VALID_BANK_ACC_ID}`)
        .set('Authorization', authHeader);
      expect(res.status).toBe(200);
    });

    it('returns 200 and applies single category filter', async () => {
      db.query.mockResolvedValueOnce({ rows: [makeTransactionRow()], rowCount: 1 });
      const res = await request(app).get('/api/v1/transactions?category=Ocio').set('Authorization', authHeader);
      expect(res.status).toBe(200);
    });

    it('returns 400 on validation error', async () => {
      const res = await request(app).get('/api/v1/transactions?page=-1').set('Authorization', authHeader);
      expect(res.status).toBe(400);
    });

    it('returns 500 on DB error', async () => {
      db.query.mockRejectedValueOnce(new Error('DB Error'));
      const res = await request(app).get('/api/v1/transactions').set('Authorization', authHeader);
      expect(res.status).toBe(500);
    });
  });

  // ── POST /api/v1/transactions ─────────────────────────────────────────────
  describe('POST /api/v1/transactions', () => {
    it('returns 201, updates account balance, and runs async anomaly check', async () => {
      db.query
        .mockResolvedValueOnce({ 
          rows: [{ id: TX_UUID, type: 'expense', amount: '50', category: 'Alimentación', bank_account_id: VALID_BANK_ACC_ID, card_id: null }],
          rowCount: 1,
        })
        .mockResolvedValueOnce({ rows: [], rowCount: 1 }) // UPDATE bank_accounts
        .mockResolvedValueOnce({ rows: [{},{},{},{}], rowCount: 4 }) // Async: Anomaly history
        .mockResolvedValueOnce({ rows: [], rowCount: 1 }); // Async: INSERT notification

      global.fetch.mockResolvedValueOnce({
        ok: true,
        json: async () => ({ anomalies: [{ id: TX_UUID, message: 'Anómalo' }] }),
      });

      const res = await request(app)
        .post('/api/v1/transactions')
        .set('Authorization', authHeader)
        .send({ ...VALID_TX, bank_account_id: VALID_BANK_ACC_ID }); // UUID VÁLIDO AQUÍ

      expect(res.status).toBe(201);

      await new Promise(r => setTimeout(r, 50)); // flush promises
      expect(global.fetch).toHaveBeenCalled();
    });

    it('resolves card_id to bank_account_id and updates balance', async () => {
      db.query
        .mockResolvedValueOnce({
          rows: [{ id: TX_UUID, type: 'income', amount: '100', category: 'Salario', bank_account_id: null, card_id: VALID_CARD_ID_1 }],
          rowCount: 1,
        })
        .mockResolvedValueOnce({ rows: [{ bank_account_id: VALID_BANK_ACC_ID }], rowCount: 1 }) // SELECT card
        .mockResolvedValueOnce({ rows: [], rowCount: 1 }); // UPDATE bank_accounts

      const res = await request(app)
        .post('/api/v1/transactions')
        .set('Authorization', authHeader)
        .send({ ...VALID_TX, type: 'income', card_id: VALID_CARD_ID_1 });

      expect(res.status).toBe(201);
    });

    it('silently ignores background anomaly check errors without crashing', async () => {
      db.query.mockResolvedValueOnce({ rows: [{ id: TX_UUID, type: 'expense', amount: '50', category: 'Alimentación' }] }); 
      db.query.mockRejectedValueOnce(new Error('Async DB Crash'));

      const res = await request(app).post('/api/v1/transactions').set('Authorization', authHeader).send(VALID_TX);
      
      expect(res.status).toBe(201);
      await new Promise(r => setTimeout(r, 50));
      expect(console.warn).toHaveBeenCalled();
    });

    it('silently ignores AI fetch errors in background check', async () => {
      db.query.mockResolvedValueOnce({ rows: [{ id: TX_UUID, type: 'expense', amount: '50', category: 'Alimentación' }] });
      db.query.mockResolvedValueOnce({ rows: [{},{},{},{}], rowCount: 4 }); 
      global.fetch.mockRejectedValueOnce(new Error('Network offline'));

      const res = await request(app).post('/api/v1/transactions').set('Authorization', authHeader).send(VALID_TX);
      expect(res.status).toBe(201);
      await new Promise(r => setTimeout(r, 50));
    });

    it('returns 400 on validation failure', async () => {
      const res = await request(app).post('/api/v1/transactions').set('Authorization', authHeader).send({});
      expect(res.status).toBe(400);
    });

    it('returns 500 on DB error', async () => {
      db.query.mockRejectedValueOnce(new Error('DB Insert failed'));
      const res = await request(app).post('/api/v1/transactions').set('Authorization', authHeader).send(VALID_TX);
      expect(res.status).toBe(500);
    });
  });

  // ── GET /api/v1/transactions/analytics ────────────────────────────────────
  describe('GET /api/v1/transactions/analytics', () => {
    it('returns 200 with monthly and category analytics', async () => {
      db.query
        .mockResolvedValueOnce({ rows: [{ month: '2026-04', income: 1000, expenses: 500 }], rowCount: 1 })
        .mockResolvedValueOnce({ rows: [{ category: 'Ocio', total: 500 }], rowCount: 1 });

      const res = await request(app).get('/api/v1/transactions/analytics?months=6').set('Authorization', authHeader);
      expect(res.status).toBe(200);
    });

    it('handles months=0 (all time)', async () => {
      db.query.mockResolvedValueOnce({ rows: [] }).mockResolvedValueOnce({ rows: [] });
      const res = await request(app).get('/api/v1/transactions/analytics?months=0').set('Authorization', authHeader);
      expect(res.status).toBe(200);
    });

    it('returns 500 on DB error', async () => {
      db.query.mockRejectedValueOnce(new Error('DB Failed'));
      const res = await request(app).get('/api/v1/transactions/analytics').set('Authorization', authHeader);
      expect(res.status).toBe(500);
    });
  });

  // ── GET /api/v1/transactions/monthly-summary ─────────────────────────────
  describe('GET /api/v1/transactions/monthly-summary', () => {
    it('returns 200 with summary', async () => {
      db.query.mockResolvedValueOnce({ rows: [{ month: '2026-04', income: 1000, expenses: 500 }] });
      const res = await request(app).get('/api/v1/transactions/monthly-summary?months=6').set('Authorization', authHeader);
      expect(res.status).toBe(200);
    });

    it('returns 500 on DB error', async () => {
      db.query.mockRejectedValueOnce(new Error('DB Failed'));
      const res = await request(app).get('/api/v1/transactions/monthly-summary').set('Authorization', authHeader);
      expect(res.status).toBe(500);
    });
  });

  // ── GET /api/v1/transactions/summary/balance ──────────────────────────────
  describe('GET /api/v1/transactions/summary/balance', () => {
    it('returns 200 with balance summary', async () => {
      db.query.mockResolvedValueOnce({
        rows: [{ total_income: '2000', total_expenses: '1500', balance: '500', total_transactions: '10' }]
      });
      const res = await request(app).get('/api/v1/transactions/summary/balance').set('Authorization', authHeader);
      expect(res.status).toBe(200);
      expect(res.body.summary.balance).toBe(500);
    });

    it('returns 500 on DB error', async () => {
      db.query.mockRejectedValueOnce(new Error('DB Failed'));
      const res = await request(app).get('/api/v1/transactions/summary/balance').set('Authorization', authHeader);
      expect(res.status).toBe(500);
    });
  });

  // ── GET /api/v1/transactions/:id ──────────────────────────────────────────
  describe('GET /api/v1/transactions/:id', () => {
    it('returns 200 with transaction', async () => {
      db.query.mockResolvedValueOnce({ rows: [makeTransactionRow()], rowCount: 1 });
      const res = await request(app).get(`/api/v1/transactions/${TX_UUID}`).set('Authorization', authHeader);
      expect(res.status).toBe(200);
    });

    it('returns 404 when transaction not found', async () => {
      db.query.mockResolvedValueOnce({ rows: [], rowCount: 0 });
      const res = await request(app).get(`/api/v1/transactions/${TX_UUID}`).set('Authorization', authHeader);
      expect(res.status).toBe(404);
    });

    it('returns 400 on invalid UUID', async () => {
      const res = await request(app).get(`/api/v1/transactions/not-a-uuid`).set('Authorization', authHeader);
      expect(res.status).toBe(400);
    });

    it('returns 500 on DB error', async () => {
      db.query.mockRejectedValueOnce(new Error('DB Failed'));
      const res = await request(app).get(`/api/v1/transactions/${TX_UUID}`).set('Authorization', authHeader);
      expect(res.status).toBe(500);
    });
  });

  // ── PUT /api/v1/transactions/:id ──────────────────────────────────────────
  describe('PUT /api/v1/transactions/:id', () => {
    it('returns 200, reverts old card balance, applies new card balance', async () => {
      db.query
        .mockResolvedValueOnce({ // SELECT existing
          rows: [{ id: TX_UUID, amount: '100', type: 'income', bank_account_id: null, card_id: VALID_CARD_ID_1 }]
        })
        .mockResolvedValueOnce({ // UPDATE transaction
          rows: [{ id: TX_UUID, amount: '50', type: 'expense', bank_account_id: null, card_id: VALID_CARD_ID_2 }]
        })
        .mockResolvedValueOnce({ rows: [{ bank_account_id: VALID_BANK_ACC_ID }] }) // SELECT old card
        .mockResolvedValueOnce({ rows: [] }) // UPDATE old account
        .mockResolvedValueOnce({ rows: [{ bank_account_id: VALID_BANK_ACC_ID }] }) // SELECT new card
        .mockResolvedValueOnce({ rows: [] }); // UPDATE new account

      const res = await request(app)
        .put(`/api/v1/transactions/${TX_UUID}`)
        .set('Authorization', authHeader)
        .send({ ...VALID_TX, card_id: VALID_CARD_ID_2 });
      
      expect(res.status).toBe(200);
    });

    it('returns 404 when transaction not found', async () => {
      db.query.mockResolvedValueOnce({ rows: [], rowCount: 0 });
      const res = await request(app).put(`/api/v1/transactions/${TX_UUID}`).set('Authorization', authHeader).send(VALID_TX);
      expect(res.status).toBe(404);
    });

    it('returns 400 on validation error', async () => {
      const res = await request(app).put(`/api/v1/transactions/${TX_UUID}`).set('Authorization', authHeader).send({});
      expect(res.status).toBe(400);
    });

    it('returns 500 on DB error', async () => {
      db.query.mockRejectedValueOnce(new Error('DB Failed'));
      const res = await request(app).put(`/api/v1/transactions/${TX_UUID}`).set('Authorization', authHeader).send(VALID_TX);
      expect(res.status).toBe(500);
    });
  });

  // ── DELETE /api/v1/transactions/:id ───────────────────────────────────────
  describe('DELETE /api/v1/transactions/:id', () => {
    it('returns 200 and reverts balance', async () => {
      db.query
        .mockResolvedValueOnce({ // SELECT existing
          rows: [{ id: TX_UUID, amount: '100', type: 'income', bank_account_id: VALID_BANK_ACC_ID, card_id: null }]
        })
        .mockResolvedValueOnce({ rows: [{ id: TX_UUID }] }) // DELETE
        .mockResolvedValueOnce({ rows: [] }); // UPDATE bank_accounts (revert)

      const res = await request(app).delete(`/api/v1/transactions/${TX_UUID}`).set('Authorization', authHeader);
      expect(res.status).toBe(200);
    });

    it('returns 200 and reverts card balance', async () => {
      db.query
        .mockResolvedValueOnce({ // SELECT existing
          rows: [{ id: TX_UUID, amount: '50', type: 'expense', bank_account_id: null, card_id: VALID_CARD_ID_1 }]
        })
        .mockResolvedValueOnce({ rows: [{ id: TX_UUID }] }) // DELETE
        .mockResolvedValueOnce({ rows: [{ bank_account_id: VALID_BANK_ACC_ID }] }) // SELECT card
        .mockResolvedValueOnce({ rows: [] }); // UPDATE bank_accounts (revert)

      const res = await request(app).delete(`/api/v1/transactions/${TX_UUID}`).set('Authorization', authHeader);
      expect(res.status).toBe(200);
    });

    it('returns 404 when transaction not found', async () => {
      db.query.mockResolvedValueOnce({ rows: [], rowCount: 0 });
      const res = await request(app).delete(`/api/v1/transactions/${TX_UUID}`).set('Authorization', authHeader);
      expect(res.status).toBe(404);
    });

    it('returns 500 on DB error', async () => {
      db.query.mockRejectedValueOnce(new Error('DB Failed'));
      const res = await request(app).delete(`/api/v1/transactions/${TX_UUID}`).set('Authorization', authHeader);
      expect(res.status).toBe(500);
    });
  });

  // ── POST /api/v1/transactions/import-csv ──────────────────────────────────
  describe('POST /api/v1/transactions/import-csv', () => {
    it('returns 400 when csv text is missing or invalid', async () => {
      const res1 = await request(app).post('/api/v1/transactions/import-csv').set('Authorization', authHeader).send({});
      expect(res1.status).toBe(400);

      const res2 = await request(app).post('/api/v1/transactions/import-csv').set('Authorization', authHeader).send({ csv: '   ' });
      expect(res2.status).toBe(400);
    });

    it('returns 400 if CSV exceeds 5MB limit', async () => {
      const hugeCSV = 'a'.repeat(6 * 1024 * 1024);
      const res = await request(app).post('/api/v1/transactions/import-csv').set('Authorization', authHeader).send({ csv: hugeCSV });
      expect(res.status).toBe(400);
    });

    it('returns 422 if CSV is empty or has no data', async () => {
      const res = await request(app).post('/api/v1/transactions/import-csv').set('Authorization', authHeader).send({ csv: 'HeaderOnly\n' });
      expect(res.status).toBe(422);
    });

    it('returns 422 if required columns are missing', async () => {
      const res = await request(app).post('/api/v1/transactions/import-csv').set('Authorization', authHeader).send({ csv: 'Col1,Col2\nData1,Data2' });
      expect(res.status).toBe(422);
    });

    it('parses standard comma-separated CSV successfully and imports', async () => {
      const csvData = 'Fecha,Concepto,Importe\n01/01/2026,Compra Mercadona,-50.00\n02/01/2026,Nómina,2000.00';
      db.query
        .mockResolvedValueOnce({ rows: [{ id: 'tx1' }] }) 
        .mockResolvedValueOnce({ rows: [{ id: 'tx2' }] }); 

      const res = await request(app).post('/api/v1/transactions/import-csv').set('Authorization', authHeader).send({ csv: csvData });
      
      expect(res.status).toBe(200);
      expect(res.body.imported).toBe(2);
    });

    it('parses semicolon-separated CSV with Cargo/Abono successfully', async () => {
      const csvData = 'Fecha operacion;Concepto;Cargo;Abono\n01-01-2026;Luz;50,00;\n02-01-2026;Bizum;;15,50';
      db.query
        .mockResolvedValueOnce({ rows: [{ id: 'tx1' }] }) 
        .mockResolvedValueOnce({ rows: [] }); // DO NOTHING

      const res = await request(app).post('/api/v1/transactions/import-csv').set('Authorization', authHeader).send({ csv: csvData });
      
      expect(res.status).toBe(200);
      expect(res.body.imported).toBe(1);
    });

    it('handles tab-separated files and quoted strings', async () => {
      const csvData = 'Date\tDescription\tAmount\n2026/01/01\t"Comida, cena"\t-25.50\n';
      db.query.mockResolvedValueOnce({ rows: [{ id: 'tx1' }] });

      const res = await request(app).post('/api/v1/transactions/import-csv').set('Authorization', authHeader).send({ csv: csvData });
      
      expect(res.status).toBe(200);
      expect(res.body.imported).toBe(1);
    });

    it('returns 500 on unhandled exception during import', async () => {
      const csvData = 'Fecha,Concepto,Importe\n01/01/2026,Compra Mercadona,-50.00';
      db.query.mockRejectedValueOnce(new Error('Catastrophic DB Failure'));

      const res = await request(app).post('/api/v1/transactions/import-csv').set('Authorization', authHeader).send({ csv: csvData });
      
      expect(res.status).toBe(500);
    });
  });

  describe('POST /api/v1/transactions/import-csv (Edge cases & parsers)', () => {
    it('handles alternative spanish date formats (YYYY-MM-DD and YYYY/MM/DD)', async () => {
      const csvData = 'Fecha,Concepto,Importe\n2026/01/05,Compra,-50.00\n2026-02-10,Nómina,2000.00';
      db.query.mockResolvedValueOnce({ rows: [{ id: 'tx1' }] }).mockResolvedValueOnce({ rows: [{ id: 'tx2' }] });
      
      const res = await request(app).post('/api/v1/transactions/import-csv').set('Authorization', authHeader).send({ csv: csvData });
      expect(res.status).toBe(200);
      expect(res.body.imported).toBe(2);
    });

    it('skips rows with invalid dates', async () => {
      const csvData = 'Fecha,Concepto,Importe\nInvalidDate,Compra,-50.00';
      const res = await request(app).post('/api/v1/transactions/import-csv').set('Authorization', authHeader).send({ csv: csvData });
      expect(res.status).toBe(422); // No valid transactions found
    });

    it('handles description missing in column mapping (uses generic description)', async () => {
      // Falta la columna de Concepto, pero tiene 2 columnas para que salte el valid rows.
      // (Forzamos a que no encuentre la columna de descripcion por heuristica)
      const csvData = 'Data,Amount\n01/01/2026,-50.00';
      const res = await request(app).post('/api/v1/transactions/import-csv').set('Authorization', authHeader).send({ csv: csvData });
      expect(res.status).toBe(422); // Requerirá descripcion por diseño de parser
    });

    it('returns error if amount column is completely missing', async () => {
      const csvData = 'Fecha,Concepto,OtraCosa\n01/01/2026,Compra,Nada';
      const res = await request(app).post('/api/v1/transactions/import-csv').set('Authorization', authHeader).send({ csv: csvData });
      expect(res.status).toBe(422);
      expect(res.body.message).toContain('importe');
    });

    it('skips transactions with null or zero amount after parse', async () => {
      const csvData = 'Fecha,Concepto,Importe\n01/01/2026,Compra,-\n02/01/2026,Otra, ';
      const res = await request(app).post('/api/v1/transactions/import-csv').set('Authorization', authHeader).send({ csv: csvData });
      expect(res.status).toBe(422); // No transactions generated
    });
  });
});