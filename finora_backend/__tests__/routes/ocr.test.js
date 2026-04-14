'use strict';

jest.mock('../../services/db', () => require('../helpers/mockDb'));
jest.mock('../../services/email', () => ({
  sendVerificationEmail: jest.fn().mockResolvedValue({ success: true }),
  verifyConnection: jest.fn().mockResolvedValue(true),
}));

// Mock the pdf-parse library BEFORE requiring the app
jest.mock('pdf-parse', () => {
  return jest.fn().mockResolvedValue({
    text: "F. valor: 01/01/2026\n15 mar 2026\nCOMPRA TARJETA AMAZON\n-25,50\n20/03/2026\nNÓMINA\n2.000,00"
  });
});

const request = require('supertest');
const app = require('../../server');
const db = require('../../services/db');
const { createTestToken } = require('../helpers/testHelpers');

const token = createTestToken(42, 'user@example.com');
const authHeader = `Bearer ${token}`;

beforeAll(() => {
  jest.spyOn(console, 'error').mockImplementation(() => {});
  jest.spyOn(console, 'log').mockImplementation(() => {});
});

afterAll(() => {
  console.error.mockRestore();
  console.log.mockRestore();
});

describe('OCR Routes', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  // ── POST /api/v1/ocr/extract ──────────────────────────────────────────────
  describe('POST /api/v1/ocr/extract', () => {
    it('returns 401 without auth', async () => {
      const res = await request(app).post('/api/v1/ocr/extract').send({ raw_text: 'TOTAL 25.50' });
      expect(res.status).toBe(401);
    });

    it('returns 400 when raw_text is missing', async () => {
      const res = await request(app).post('/api/v1/ocr/extract').set('Authorization', authHeader).send({});
      expect(res.status).toBe(400);
    });

    it('returns 200 with amount and date using TOTAL keyword', async () => {
      const res = await request(app)
        .post('/api/v1/ocr/extract')
        .set('Authorization', authHeader)
        .send({
          raw_text: 'MERCADONA\nC/ Gran Via 1\n28001 Madrid\nFecha: 01/04/2026\nPan        1.50\nLeche      0.99\nTOTAL:    25.50\nGracias',
        });

      expect(res.status).toBe(200);
      expect(res.body.amount).toBe(25.5);
      expect(res.body.suggested_category).toBe('Alimentación');
      expect(res.body.date).toBe('2026-04-01');
    });

    it('returns 200 extracting the largest amount when TOTAL keyword is missing', async () => {
      const res = await request(app)
        .post('/api/v1/ocr/extract')
        .set('Authorization', authHeader)
        .send({ raw_text: 'CAFE BAR\n15/03/2026\nCafe 1.50\nBocadillo 3.50\nSuma 5.00' }); // "Suma" isn't a keyword, so it grabs max (5.00)

      expect(res.status).toBe(200);
      expect(res.body.amount).toBe(5);
      expect(res.body.suggested_category).toBe('Restaurantes');
    });

    it('identifies various categories based on heuristics', async () => {
      const checkCat = async (text, expected) => {
        const res = await request(app).post('/api/v1/ocr/extract').set('Authorization', authHeader).send({ raw_text: text });
        expect(res.body.suggested_category).toBe(expected);
      };

      await checkCat('FARMACIA GLOBO\nTotal 10.00', 'Salud');
      await checkCat('GASOLINERA REPSOL\nTotal 50.00', 'Transporte');
      await checkCat('ZARA MADRID\nTotal 30.00', 'Ropa');
      await checkCat('AMAZON EU\nTotal 15.00', 'Tecnología');
      await checkCat('LIBRERIA\nTotal 10.00', 'Otros');
    });

    it('returns 500 on internal exception', async () => {
      // Forcing error by sending a non-string object that fails `.split()`
      const res = await request(app).post('/api/v1/ocr/extract').set('Authorization', authHeader).send({ raw_text: { unexpected: true } });
      expect(res.status).toBe(500);
    });
  });

  // ── POST /api/v1/ocr/import-receipt ──────────────────────────────────────
  describe('POST /api/v1/ocr/import-receipt', () => {
    it('returns 201 when importing a valid receipt', async () => {
      db.query.mockResolvedValueOnce({
        rows: [{ id: 'tx-new-1', amount: 25.5, description: 'Mercadona' }],
        rowCount: 1,
      });

      const res = await request(app)
        .post('/api/v1/ocr/import-receipt')
        .set('Authorization', authHeader)
        .send({ amount: 25.5, description: 'Mercadona', date: '2026-04-01', category: 'Alimentación' });

      expect(res.status).toBe(201);
    });

    it('returns 400 when amount or description are missing', async () => {
      const res1 = await request(app).post('/api/v1/ocr/import-receipt').set('Authorization', authHeader).send({ description: 'M' });
      expect(res1.status).toBe(400);

      const res2 = await request(app).post('/api/v1/ocr/import-receipt').set('Authorization', authHeader).send({ amount: 10 });
      expect(res2.status).toBe(400);
    });

    it('returns 500 on DB error', async () => {
      db.query.mockRejectedValueOnce(new Error('DB Failed'));
      const res = await request(app).post('/api/v1/ocr/import-receipt').set('Authorization', authHeader).send({ amount: 10, description: 'M' });
      expect(res.status).toBe(500);
    });
  });

  // ── POST /api/v1/ocr/parse-csv ────────────────────────────────────────────
  describe('POST /api/v1/ocr/parse-csv', () => {
    it('returns 400 when csv_content is missing or empty', async () => {
      const res1 = await request(app).post('/api/v1/ocr/parse-csv').set('Authorization', authHeader).send({});
      expect(res1.status).toBe(400);

      const res2 = await request(app).post('/api/v1/ocr/parse-csv').set('Authorization', authHeader).send({ csv_content: 'Cabecera sola' });
      expect(res2.status).toBe(400);
    });

    it('parses comma-separated CSV with standard formats and unicode minus', async () => {
      // Usamos el signo menos unicode (\u2212) para asegurar que el parser lo limpia bien
      const csvContent = 'Fecha,Concepto,Importe\n"01/04/2026","Compra, Supermercado",\u221225.50\n02/04/2026,Salario,"2.000,00"';
      const res = await request(app).post('/api/v1/ocr/parse-csv').set('Authorization', authHeader).send({ csv_content: csvContent });

      expect(res.status).toBe(200);
      expect(res.body.rows.length).toBe(2);
      expect(res.body.rows[0].description).toBe('Compra, Supermercado');
      expect(res.body.rows[0].amount).toBe(25.5);
      expect(res.body.rows[1].amount).toBe(2000);
    });

    it('parses tab-separated CSV with Cargo/Abono split columns', async () => {
      // En columnas divididas, los bancos exportan el cargo en positivo
      const csvContent = 'Fecha\tConcepto\tCargo\tAbono\n01/04/2026\tNetflix\t15,99\t\n02/04/2026\tBizum\t\t50,00';
      const res = await request(app).post('/api/v1/ocr/parse-csv').set('Authorization', authHeader).send({ csv_content: csvContent });

      expect(res.status).toBe(200);
      expect(res.body.rows.length).toBe(2);
      expect(res.body.rows[0].amount).toBe(15.99);
      expect(res.body.rows[0].type).toBe('expense');
      expect(res.body.rows[1].amount).toBe(50);
      expect(res.body.rows[1].type).toBe('income');
    });

    it('falls back to heuristic header search if no text keywords match', async () => {
      const csvContent = '2026-04-01;Mercadona;-25.50\n2026-04-02;Salario;2000.00';
      const res = await request(app).post('/api/v1/ocr/parse-csv').set('Authorization', authHeader).send({ csv_content: csvContent, header_map: { date: 0, description: 1, amount: 2 } });

      expect(res.status).toBe(200);
      expect(res.body.rows.length).toBe(1); // La línea 0 se asume como cabecera por el fallback
      expect(res.body.rows[0].amount).toBe(2000);
    });

    it('strips BOM character from first line', async () => {
      const csvContent = '\uFEFFFecha,Concepto,Importe\n01/04/2026,Mercadona,-25.50';
      const res = await request(app).post('/api/v1/ocr/parse-csv').set('Authorization', authHeader).send({ csv_content: csvContent });
      expect(res.status).toBe(200);
    });

    it('parses English-format thousand-separated amounts (1,234.56)', async () => {
      const csvContent = 'Fecha,Concepto,Importe\n01/04/2026,Salary,"1,234.56"';
      const res = await request(app)
        .post('/api/v1/ocr/parse-csv')
        .set('Authorization', authHeader)
        .send({ csv_content: csvContent });
      expect(res.status).toBe(200);
      expect(res.body.rows[0].amount).toBe(1234.56);
    });

    it('returns empty rows and logs warning when no valid amounts can be parsed', async () => {
      const csvContent = 'Fecha,Concepto,Importe\n01/04/2026,Test,\n02/04/2026,Test2,';
      const res = await request(app)
        .post('/api/v1/ocr/parse-csv')
        .set('Authorization', authHeader)
        .send({ csv_content: csvContent });
      expect(res.status).toBe(200);
      expect(res.body.rows.length).toBe(0);
      expect(console.log).toHaveBeenCalledWith(
        expect.stringContaining('[CSV] WARN'),
        expect.anything()
      );
    });

    it('returns null date for unrecognizable date formats', async () => {
      const csvContent = 'Fecha;Concepto;Importe\nnot-a-date;Mercadona;25.50';
      const res = await request(app)
        .post('/api/v1/ocr/parse-csv')
        .set('Authorization', authHeader)
        .send({ csv_content: csvContent });
      expect(res.status).toBe(200);
      expect(res.body.rows[0].date).toBeNull();
      expect(res.body.rows[0].amount).toBe(25.5);
    });

    it('returns 500 on internal parsing error', async () => {
      const res = await request(app).post('/api/v1/ocr/parse-csv').set('Authorization', authHeader).send({ csv_content: { not: 'a string' } });
      expect(res.status).toBe(500);
    });
  });

  // ── POST /api/v1/ocr/import-csv ──────────────────────────────────────────
  describe('POST /api/v1/ocr/import-csv', () => {
    it('returns 400 when rows are missing', async () => {
      const res = await request(app).post('/api/v1/ocr/import-csv').set('Authorization', authHeader).send({ rows: [] });
      expect(res.status).toBe(400);
    });

    it('imports rows, skipping duplicates and handling DB errors', async () => {
      db.query
        .mockResolvedValueOnce({ rows: [{ id: 'dup' }], rowCount: 1 }) // Row 1: Duplicate check finds it -> skip
        .mockResolvedValueOnce({ rows: [], rowCount: 0 }) // Row 2: Duplicate check clear
        .mockResolvedValueOnce({}) // Row 2: INSERT success
        .mockResolvedValueOnce({ rows: [], rowCount: 0 }) // Row 3: Duplicate check clear
        .mockRejectedValueOnce(new Error('Insert Fail')); // Row 3: INSERT throws error

      const res = await request(app)
        .post('/api/v1/ocr/import-csv')
        .set('Authorization', authHeader)
        .send({
          skip_duplicates: true,
          rows: [
            { amount: 10, description: 'SkipMe', date: '2026-04-01' },
            { amount: 20, description: 'InsertMe', date: '2026-04-02', type: 'income', category: 'Ingresos' },
            { amount: 30, description: 'ErrorMe', date: '2026-04-03' },
          ],
        });

      expect(res.status).toBe(200);
      expect(res.body.skipped).toBe(1);
      expect(res.body.imported).toBe(1);
      expect(res.body.errors.length).toBe(1);
      expect(res.body.errors[0].error).toBe('Insert Fail');
    });

    it('imports rows without checking duplicates if skip_duplicates=false', async () => {
      db.query.mockResolvedValueOnce({}); // Only INSERT, no SELECT

      const res = await request(app)
        .post('/api/v1/ocr/import-csv')
        .set('Authorization', authHeader)
        .send({ skip_duplicates: false, rows: [{ amount: 10, description: 'A', date: '2026-04-01' }] });

      expect(res.status).toBe(200);
      expect(res.body.imported).toBe(1);
      expect(res.body.skipped).toBe(0);
    });
  });

  // ── POST /api/v1/ocr/parse-pdf ───────────────────────────────────────────
  describe('POST /api/v1/ocr/parse-pdf', () => {
    it('returns 400 when pdf_base64 is missing', async () => {
      const res = await request(app).post('/api/v1/ocr/parse-pdf').set('Authorization', authHeader).send({});
      expect(res.status).toBe(400);
    });

    it('extracts transactions using pdf-parse mock logic including multi-line', async () => {
      // Sobrescribimos el mock global solo para este test con un PDF súper complejo
      const pdfParse = require('pdf-parse');
      pdfParse.mockResolvedValueOnce({
        text: `F. valor: 01/01/2026
15 mar 2026
COMPRA TARJETA
AMAZON
-25,50
20/03/2026 NÓMINA 2.000,00 3.000,00
10/01/2026
LINEA SUELTA
OTRA LINEA SUELTA
MAS DE 5 LINEAS
CUATRO
CINCO
SEIS
-10.00`
      });

      const res = await request(app)
        .post('/api/v1/ocr/parse-pdf')
        .set('Authorization', authHeader)
        .send({ pdf_base64: 'JVBERi0xLjQKJcOkw7zDts...' }); // fake base64

      expect(res.status).toBe(200);
      
      // Transaction 1 (Spanish date, multi-line)
      expect(res.body.rows[0].date).toBe('2026-03-15');
      expect(res.body.rows[0].amount).toBe(25.5);
      expect(res.body.rows[0].description.includes('AMAZON')).toBe(true);

      // Transaction 2 (Numeric date, single line with 2 amounts: takes the first one as amount and second as balance)
      expect(res.body.rows[1].date).toBe('2026-03-20');
      expect(res.body.rows[1].amount).toBe(2000);
      expect(res.body.rows[1].type).toBe('income');
    });

    it('handles empty pdf extraction gracefully', async () => {
      const pdfParse = require('pdf-parse');
      pdfParse.mockResolvedValueOnce({ text: '' }); // PDF vacío

      const res = await request(app)
        .post('/api/v1/ocr/parse-pdf')
        .set('Authorization', authHeader)
        .send({ pdf_base64: 'fake-base64' });

      expect(res.status).toBe(200);
      expect(res.body.rows.length).toBe(0);
    });

    it('returns 500 on internal parsing crash', async () => {
      const pdfParse = require('pdf-parse');
      pdfParse.mockRejectedValueOnce(new Error('Corrupted PDF'));

      const res = await request(app)
        .post('/api/v1/ocr/parse-pdf')
        .set('Authorization', authHeader)
        .send({ pdf_base64: 'bad-base64' });

      expect(res.status).toBe(500);
    });

    it('handles English-format amounts and empty desc in flushPending', async () => {
      const pdfParse = require('pdf-parse');
      // Spanish text date immediately followed by an amount+text line (no desc lines between)
      // This covers: parseAmount English format (dot last) and flushPending empty-desc branch
      pdfParse.mockResolvedValueOnce({
        text: '15 mar 2026\nAMAZON 1,234.56'
      });

      const res = await request(app)
        .post('/api/v1/ocr/parse-pdf')
        .set('Authorization', authHeader)
        .send({ pdf_base64: 'fake-base64' });

      expect(res.status).toBe(200);
      expect(res.body.rows[0].amount).toBe(1234.56);
      expect(res.body.rows[0].description).toContain('AMAZON');
    });
  });
});