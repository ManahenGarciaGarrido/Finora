'use strict';

// 1. Mocks
jest.mock('../../services/db', () => require('../helpers/mockDb'));
jest.mock('../../services/email', () => ({
  sendVerificationEmail: jest.fn().mockResolvedValue({ success: true }),
  sendWelcomeEmail: jest.fn().mockResolvedValue({ success: true }),
  sendPasswordResetEmail: jest.fn().mockResolvedValue({ success: true }),
  verifyConnection: jest.fn().mockResolvedValue(true),
}));

// Mock de JWT para forzar errores específicos
const jwt = require('jsonwebtoken');
jest.spyOn(jwt, 'sign');
jest.spyOn(jwt, 'verify');

const request = require('supertest');
const app = require('../../server');
const db = require('../../services/db');
const bcrypt = require('bcryptjs');

const VALID_REGISTER_BODY = {
  email: 'newuser@example.com',
  password: 'StrongPass1!',
  name: 'Test User',
  termsAccepted: true,
  privacyAccepted: true,
  consents: { essential: true, marketing: false }
};

const authHeader = (token) => `Bearer ${token}`;

describe('Auth Routes', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  // ── POST /api/v1/auth/register ───────────────────────────────────────────────
  describe('POST /api/v1/auth/register', () => {
    it('returns 201 with token and user on valid registration', async () => {
      db.query
        .mockResolvedValueOnce({ rows: [], rowCount: 0 }) // check existing user
        .mockResolvedValueOnce({                          // INSERT user
          rows: [{ id: 'uuid-1', email: 'newuser@example.com', name: 'Test User', email_verified: false, created_at: new Date().toISOString(), updated_at: new Date().toISOString() }],
          rowCount: 1,
        })
        .mockResolvedValueOnce({ rows: [], rowCount: 0 }) // seed_categories_for_user
        // Consents: essential and marketing queries
        .mockResolvedValueOnce({ rows: [], rowCount: 0 }) // UPSERT essential
        .mockResolvedValueOnce({ rows: [], rowCount: 0 }) // History essential
        .mockResolvedValueOnce({ rows: [], rowCount: 0 }) // UPSERT analytics (default true)
        .mockResolvedValueOnce({ rows: [], rowCount: 0 }) // History analytics
        .mockResolvedValueOnce({ rows: [], rowCount: 0 }) // UPSERT marketing (false)
        .mockResolvedValueOnce({ rows: [], rowCount: 0 }) // History marketing
        .mockResolvedValueOnce({ rows: [], rowCount: 0 }) // UPSERT third_party
        .mockResolvedValueOnce({ rows: [], rowCount: 0 }) // History third_party
        .mockResolvedValueOnce({ rows: [], rowCount: 0 }) // UPSERT personalization
        .mockResolvedValueOnce({ rows: [], rowCount: 0 }) // History personalization
        .mockResolvedValueOnce({ rows: [], rowCount: 0 }) // UPSERT data_processing
        .mockResolvedValueOnce({ rows: [], rowCount: 0 });// History data_processing

      const res = await request(app)
        .post('/api/v1/auth/register')
        .send(VALID_REGISTER_BODY);

      expect(res.status).toBe(201);
      expect(res.body).toHaveProperty('access_token');
    });

    it('returns 201 using default consents when consents object is missing', async () => {
        db.query
          .mockResolvedValueOnce({ rows: [] }) // check existing user
          .mockResolvedValueOnce({ rows: [{ id: 'uuid-1', email: 'default@ex.com' }] }) // INSERT
          .mockResolvedValueOnce({ rows: [] }) // seed categories
          .mockResolvedValueOnce({ rows: [] });// seed default consents
  
        const { consents, ...bodyWithoutConsents } = VALID_REGISTER_BODY;
        const res = await request(app).post('/api/v1/auth/register').send(bodyWithoutConsents);
        expect(res.status).toBe(201);
    });

    it('returns 409 when email already exists', async () => {
      db.query.mockResolvedValueOnce({ rows: [{ id: 'existing-id' }], rowCount: 1 });
      const res = await request(app).post('/api/v1/auth/register').send(VALID_REGISTER_BODY);
      expect(res.status).toBe(409);
    });

    it('returns 400 when validation fails', async () => {
      const res = await request(app)
        .post('/api/v1/auth/register')
        .send({ ...VALID_REGISTER_BODY, email: 'not-an-email' });
      expect(res.status).toBe(400);
    });

    it('returns 500 on DB error', async () => {
      db.query.mockRejectedValueOnce(new Error('DB Down'));
      const res = await request(app).post('/api/v1/auth/register').send(VALID_REGISTER_BODY);
      expect(res.status).toBe(500);
    });
  });

  // ── GET & POST /verify-email & /resend-verification ──────────────────────────
  describe('Email Verification', () => {
    it('GET /verify-email successfully verifies user', async () => {
      db.query
        .mockResolvedValueOnce({ rows: [{ id: 'u1', email_verified: false, email_verification_expires: new Date(Date.now() + 100000).toISOString() }] }) // Select
        .mockResolvedValueOnce({}); // Update
        
      const res = await request(app).get('/api/v1/auth/verify-email?token=validtoken');
      expect(res.status).toBe(200);
      expect(res.text).toMatch(/Email Verificado!/);
    });

    it('GET /verify-email returns 400 for missing token', async () => {
      const res = await request(app).get('/api/v1/auth/verify-email');
      expect(res.status).toBe(400);
    });

    it('GET /verify-email returns 400 for expired token', async () => {
        db.query.mockResolvedValueOnce({ rows: [{ id: 'u1', email_verified: false, email_verification_expires: new Date(Date.now() - 100000).toISOString() }] });
        const res = await request(app).get('/api/v1/auth/verify-email?token=validtoken');
        expect(res.status).toBe(400);
    });

    it('POST /resend-verification resends email successfully', async () => {
      db.query
        .mockResolvedValueOnce({ rows: [{ id: 'u1', name: 'User', email_verified: false }] })
        .mockResolvedValueOnce({}); // Update token
      
      const res = await request(app).post('/api/v1/auth/resend-verification').send({ email: 'test@example.com' });
      expect(res.status).toBe(200);
    });
  });

  // ── POST /api/v1/auth/login ──────────────────────────────────────────────────
  describe('POST /api/v1/auth/login', () => {
    it('returns 200 with token on valid credentials', async () => {
      const hashedPassword = bcrypt.hashSync('StrongPass1!', 10);
      db.query.mockResolvedValueOnce({
        rows: [{ id: 'user-uuid', email: 'user@example.com', password: hashedPassword, email_verified: true, is_2fa_enabled: false }],
      });

      const res = await request(app)
        .post('/api/v1/auth/login')
        .send({ email: 'user@example.com', password: 'StrongPass1!' });

      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('access_token');
    });

    it('returns 403 when email is not verified', async () => {
        const hashedPassword = bcrypt.hashSync('StrongPass1!', 10);
        db.query.mockResolvedValueOnce({
          rows: [{ id: 'user-uuid', email: 'user@example.com', password: hashedPassword, email_verified: false, is_2fa_enabled: false }],
        });
  
        const res = await request(app)
          .post('/api/v1/auth/login')
          .send({ email: 'user@example.com', password: 'StrongPass1!' });
  
        expect(res.status).toBe(403);
    });

    it('returns 401 when email not found or password wrong', async () => {
      db.query.mockResolvedValueOnce({ rows: [] });
      const res = await request(app).post('/api/v1/auth/login').send({ email: 'nobody@example.com', password: 'StrongPass1!' });
      expect(res.status).toBe(401);
    });
  });

  // ── POST /logout, /refresh, /biometric-token ────────────────────────────────
  describe('Token Management', () => {
    it('POST /logout returns 200', async () => {
      const res = await request(app).post('/api/v1/auth/logout');
      expect(res.status).toBe(200);
    });

    it('POST /refresh refreshes token successfully', async () => {
      const token = jwt.sign({ userId: 'u1', email: 'a@b.com' }, 'secret');
      jwt.verify.mockReturnValueOnce({ userId: 'u1', email: 'a@b.com' });
      db.query.mockResolvedValueOnce({ rows: [{ email_verified: true }] });

      const res = await request(app).post('/api/v1/auth/refresh').set('Authorization', authHeader(token));
      expect(res.status).toBe(200);
    });

    it('POST /biometric-token generates 30d token', async () => {
      const token = jwt.sign({ userId: 'u1' }, 'secret');
      jwt.verify.mockReturnValueOnce({ userId: 'u1' });
      db.query.mockResolvedValueOnce({ rows: [{ id: 'u1', email: 'a@b.com', email_verified: true }] });

      const res = await request(app).post('/api/v1/auth/biometric-token').set('Authorization', authHeader(token));
      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('biometric_token');
    });
  });

  // ── PASSWORD RESET ────────────────────────────────────────────────────────
  describe('Password Reset', () => {
    it('POST /forgot-password sends reset link', async () => {
      db.query.mockResolvedValueOnce({ rows: [{ id: 'u1', name: 'User' }] }).mockResolvedValueOnce({});
      const res = await request(app).post('/api/v1/auth/forgot-password').send({ email: 'test@example.com' });
      expect(res.status).toBe(200);
    });

    it('GET /reset-password returns HTML form if token valid', async () => {
      db.query.mockResolvedValueOnce({ rows: [{ id: 'u1', password_reset_expires: new Date(Date.now() + 100000).toISOString() }] });
      const res = await request(app).get('/api/v1/auth/reset-password?token=valid');
      expect(res.status).toBe(200);
      expect(res.text).toMatch(/Restablecer Contraseña/);
    });

    it('POST /reset-password updates password', async () => {
      db.query
        .mockResolvedValueOnce({ rows: [{ id: 'u1', password_reset_expires: new Date(Date.now() + 100000).toISOString() }] })
        .mockResolvedValueOnce({}); // Update password
      
      const res = await request(app)
        .post('/api/v1/auth/reset-password')
        .send({ token: 'valid', password: 'NewStrongPass1!' });
      expect(res.status).toBe(200);
    });
  });

  // ── 2FA TOTP (RNF-03) ─────────────────────────────────────────────────────
  describe('2FA Management', () => {
    const validToken = jwt.sign({ userId: 'user123' }, 'secret');

    // Función auxiliar para generar un código TOTP válido en el momento del test
    function generateValidCode(secret) {
      const crypto = require('crypto');
      const CHARS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
      let bits = 0, value = 0; const bytes = [];
      for (const c of secret.toUpperCase().replace(/=+$/, '')) {
        const idx = CHARS.indexOf(c);
        if (idx === -1) continue;
        value = (value << 5) | idx; bits += 5;
        if (bits >= 8) { bytes.push((value >>> (bits - 8)) & 255); bits -= 8; }
      }
      const T = Math.floor(Date.now() / 1000 / 30);
      const buf = Buffer.alloc(8);
      buf.writeUInt32BE(Math.floor(T / 0x100000000), 0);
      buf.writeUInt32BE(T >>> 0, 4);
      const hmac = crypto.createHmac('sha1', Buffer.from(bytes)).update(buf).digest();
      const offset = hmac[hmac.length - 1] & 0xf;
      const code = (((hmac[offset] & 0x7f) << 24) | ((hmac[offset + 1] & 0xff) << 16) | ((hmac[offset + 2] & 0xff) << 8) | (hmac[offset + 3] & 0xff)) % 1000000;
      return String(code).padStart(6, '0');
    }

    it('POST /2fa/setup returns secret and uri', async () => {
      jwt.verify.mockImplementation((t, s, cb) => cb(null, { userId: 'u1' })); // Mock auth middleware
      db.query
        .mockResolvedValueOnce({ rows: [{ email: 'test@ex.com' }] })
        .mockResolvedValueOnce({}); // Update pending secret

      const res = await request(app).post('/api/v1/auth/2fa/setup').set('Authorization', authHeader(validToken));
      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('secret');
      expect(res.body).toHaveProperty('otpauth_uri');
    });

    it('POST /2fa/verify activates 2FA with valid code', async () => {
      jwt.verify.mockImplementation((t, s, cb) => cb(null, { userId: 'u1' }));
      const fakeSecret = 'JBSWY3DPEHPK3PXP';
      db.query
        .mockResolvedValueOnce({ rows: [{ totp_secret_pending: fakeSecret }] }) // SELECT pending
        .mockResolvedValueOnce({ rows: [], rowCount: 1 }); // UPDATE to activate

      // ¡Generamos el código exacto que el servidor espera AHORA MISMO!
      const correctCode = generateValidCode(fakeSecret);
      
      const res = await request(app).post('/api/v1/auth/2fa/verify').set('Authorization', authHeader(validToken)).send({ code: correctCode });
      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body).toHaveProperty('recovery_codes');
    });

    it('POST /2fa/verify returns 500 on DB error', async () => {
      jwt.verify.mockImplementation((t, s, cb) => cb(null, { userId: 'u1' }));
      db.query.mockRejectedValueOnce(new Error('DB error'));
      const res = await request(app).post('/api/v1/auth/2fa/verify').set('Authorization', authHeader(validToken)).send({ code: '111111' });
      expect(res.status).toBe(500);
    });

    it('POST /2fa/validate returns token on success (using recovery code bypass)', async () => {
      const tempToken = jwt.sign({ userId: 'u1', '2fa_pending': true }, 'secret');
      jwt.verify.mockReturnValueOnce({ userId: 'u1', '2fa_pending': true });
      
      const crypto = require('crypto');
      const hash = crypto.createHash('sha256').update('1234-5678').digest('hex');

      db.query
        .mockResolvedValueOnce({ rows: [{ id: 'u1', totp_secret: 'AAA', totp_recovery_codes: JSON.stringify([hash]) }] })
        .mockResolvedValueOnce({}); // Update recovery codes
      
      const res = await request(app).post('/api/v1/auth/2fa/validate').send({ temp_token: tempToken, code: '1234-5678' });
      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('access_token');
    });

    it('POST /2fa/validate returns 400 if token lacks 2fa_pending flag', async () => {
      const tempToken = jwt.sign({ userId: 'u1' }, 'secret'); // Missing '2fa_pending: true'
      jwt.verify.mockReturnValueOnce({ userId: 'u1' }); // Mock no devuelve el flag

      const res = await request(app).post('/api/v1/auth/2fa/validate').send({ temp_token: tempToken, code: '111111' });
      expect(res.status).toBe(400);
    });

    it('POST /2fa/validate returns 500 on DB error', async () => {
      const tempToken = jwt.sign({ userId: 'u1', '2fa_pending': true }, 'secret');
      jwt.verify.mockReturnValueOnce({ userId: 'u1', '2fa_pending': true });
      db.query.mockRejectedValueOnce(new Error('DB Error'));

      const res = await request(app).post('/api/v1/auth/2fa/validate').send({ temp_token: tempToken, code: '111111' });
      expect(res.status).toBe(500);
    });

    it('POST /2fa/disable removes 2FA with valid password', async () => {
      jwt.verify.mockImplementation((t, s, cb) => cb(null, { userId: 'u1' }));
      const hashedPassword = bcrypt.hashSync('Pass1!', 10);
      
      db.query
        .mockResolvedValueOnce({ rows: [{ password: hashedPassword, is_2fa_enabled: true }] })
        .mockResolvedValueOnce({}); // Update
      
      const res = await request(app).post('/api/v1/auth/2fa/disable').set('Authorization', authHeader(validToken)).send({ password: 'Pass1!' });
      expect(res.status).toBe(200);
    });

    it('POST /2fa/disable returns 500 on DB error', async () => {
      jwt.verify.mockImplementation((t, s, cb) => cb(null, { userId: 'u1' }));
      db.query.mockRejectedValueOnce(new Error('DB Error'));
      const res = await request(app).post('/api/v1/auth/2fa/disable').set('Authorization', authHeader(validToken)).send({ password: 'pw' });
      expect(res.status).toBe(500);
    });

    it('GET /2fa/status returns true/false', async () => {
      jwt.verify.mockImplementation((t, s, cb) => cb(null, { userId: 'u1' }));
      db.query.mockResolvedValueOnce({ rows: [{ is_2fa_enabled: true }] });
      const res = await request(app).get('/api/v1/auth/2fa/status').set('Authorization', authHeader(validToken));
      expect(res.body.is_2fa_enabled).toBe(true);
    });

    it('GET /2fa/status returns 500 on DB error', async () => {
      jwt.verify.mockImplementation((t, s, cb) => cb(null, { userId: 'u1' }));
      db.query.mockRejectedValueOnce(new Error('DB Error'));
      const res = await request(app).get('/api/v1/auth/2fa/status').set('Authorization', authHeader(validToken));
      expect(res.status).toBe(500);
    });
  });

  // ── GET /api/v1/auth/password-requirements ────────────────────────────────
  describe('GET /api/v1/auth/password-requirements', () => {
    it('returns 200 with password requirements array', async () => {
      const res = await request(app).get('/api/v1/auth/password-requirements');
      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('requirements');
      expect(Array.isArray(res.body.requirements)).toBe(true);
      expect(res.body.requirements.length).toBeGreaterThan(0);
    });
  });

  // ── Additional branch coverage tests ─────────────────────────────────────

  describe('POST /api/v1/auth/register — extra branches', () => {
    it('returns 400 when password is too weak (custom validator fires)', async () => {
      const res = await request(app)
        .post('/api/v1/auth/register')
        .send({ ...VALID_REGISTER_BODY, password: 'allowercase' }); // no number/uppercase/special
      expect(res.status).toBe(400);
    });

    it('returns 201 even when category seeding fails (non-fatal)', async () => {
      db.query
        .mockResolvedValueOnce({ rows: [] })                                           // check existing
        .mockResolvedValueOnce({ rows: [{ id: 'u1', email: 'x@x.com', name: 'X', email_verified: false, created_at: new Date().toISOString(), updated_at: new Date().toISOString() }] }) // INSERT
        .mockRejectedValueOnce(new Error('seed fail'))                                 // seed categories FAILS
        .mockResolvedValueOnce({ rows: [] });                                          // seed_default_consents

      const res = await request(app)
        .post('/api/v1/auth/register')
        .send({ ...VALID_REGISTER_BODY, email: 'seed@x.com' });
      expect(res.status).toBe(201);
    });

    it('returns 201 even when consent saving fails (non-fatal)', async () => {
      db.query
        .mockResolvedValueOnce({ rows: [] })                                           // check existing
        .mockResolvedValueOnce({ rows: [{ id: 'u1', email: 'x@x.com', name: 'X', email_verified: false, created_at: new Date().toISOString(), updated_at: new Date().toISOString() }] }) // INSERT
        .mockResolvedValueOnce({ rows: [] })                                           // seed categories OK
        .mockRejectedValueOnce(new Error('consent fail'));                             // consent INSERT fails

      const res = await request(app)
        .post('/api/v1/auth/register')
        .send({ ...VALID_REGISTER_BODY, email: 'consent@x.com', consents: { essential: true } });
      expect(res.status).toBe(201);
    });

    it('returns 201 even when verification email fails to send', async () => {
      const emailService = require('../../services/email');
      emailService.sendVerificationEmail.mockResolvedValueOnce({ success: false, error: 'SMTP down' });

      db.query
        .mockResolvedValueOnce({ rows: [] })
        .mockResolvedValueOnce({ rows: [{ id: 'u1', email: 'x@x.com', name: 'X', email_verified: false, created_at: new Date().toISOString(), updated_at: new Date().toISOString() }] })
        .mockResolvedValueOnce({ rows: [] })
        .mockResolvedValueOnce({ rows: [] });

      const res = await request(app)
        .post('/api/v1/auth/register')
        .send({ ...VALID_REGISTER_BODY, email: 'emailfail@x.com' });
      expect(res.status).toBe(201);
    });
  });

  describe('Email Verification — extra branches', () => {
    it('GET /verify-email returns 400 when token not found in DB', async () => {
      db.query.mockResolvedValueOnce({ rows: [], rowCount: 0 }); // token not found
      const res = await request(app).get('/api/v1/auth/verify-email?token=unknowntoken');
      expect(res.status).toBe(400);
    });

    it('GET /verify-email returns 400 when user already verified', async () => {
      db.query.mockResolvedValueOnce({
        rows: [{ id: 'u1', email_verified: true, email_verification_expires: new Date(Date.now() + 100000).toISOString() }],
      });
      const res = await request(app).get('/api/v1/auth/verify-email?token=alreadyverified');
      expect(res.status).toBe(400);
    });

    it('GET /verify-email returns 500 on DB error', async () => {
      db.query.mockRejectedValueOnce(new Error('DB down'));
      const res = await request(app).get('/api/v1/auth/verify-email?token=anytok');
      expect(res.status).toBe(500);
    });

    it('POST /resend-verification returns 400 when email is missing', async () => {
      const res = await request(app).post('/api/v1/auth/resend-verification').send({});
      expect(res.status).toBe(400);
    });

    it('POST /resend-verification returns 200 when user email not found (security)', async () => {
      db.query.mockResolvedValueOnce({ rows: [], rowCount: 0 }); // user not found
      const res = await request(app).post('/api/v1/auth/resend-verification').send({ email: 'nobody@x.com' });
      expect(res.status).toBe(200);
    });

    it('POST /resend-verification returns 400 when user already verified', async () => {
      db.query.mockResolvedValueOnce({ rows: [{ id: 'u1', name: 'User', email_verified: true }] });
      const res = await request(app).post('/api/v1/auth/resend-verification').send({ email: 'verified@x.com' });
      expect(res.status).toBe(400);
    });

    it('POST /resend-verification returns 200 even when email send fails', async () => {
      const emailService = require('../../services/email');
      emailService.sendVerificationEmail.mockResolvedValueOnce({ success: false, error: 'SMTP' });
      db.query
        .mockResolvedValueOnce({ rows: [{ id: 'u1', name: 'User', email_verified: false }] })
        .mockResolvedValueOnce({});
      const res = await request(app).post('/api/v1/auth/resend-verification').send({ email: 'fail@x.com' });
      expect(res.status).toBe(200);
    });

    it('POST /resend-verification returns 500 on DB error', async () => {
      db.query.mockRejectedValueOnce(new Error('DB down'));
      const res = await request(app).post('/api/v1/auth/resend-verification').send({ email: 'err@x.com' });
      expect(res.status).toBe(500);
    });
  });

  describe('POST /api/v1/auth/login — extra branches', () => {
    it('returns 400 when email is missing (validation)', async () => {
      const res = await request(app).post('/api/v1/auth/login').send({ password: 'StrongPass1!' });
      expect(res.status).toBe(400);
    });

    it('returns 401 when user found but password is wrong', async () => {
      const hashedPassword = bcrypt.hashSync('CorrectPass1!', 10);
      db.query.mockResolvedValueOnce({
        rows: [{ id: 'u1', email: 'x@x.com', password: hashedPassword, email_verified: true, is_2fa_enabled: false }],
      });
      const res = await request(app)
        .post('/api/v1/auth/login')
        .send({ email: 'x@x.com', password: 'WrongPass1!' });
      expect(res.status).toBe(401);
    });

    it('returns 500 on DB error during login', async () => {
      db.query.mockRejectedValueOnce(new Error('DB down'));
      const res = await request(app)
        .post('/api/v1/auth/login')
        .send({ email: 'x@x.com', password: 'StrongPass1!' });
      expect(res.status).toBe(500);
    });
  });

  describe('Token Management — extra branches', () => {
    it('POST /refresh returns 401 when no Authorization header', async () => {
      const res = await request(app).post('/api/v1/auth/refresh');
      expect(res.status).toBe(401);
    });

    it('POST /refresh returns 401 when user not found in DB', async () => {
      const tok = jwt.sign({ userId: 'ghost', email: 'g@g.com' }, 'secret');
      jwt.verify.mockReturnValueOnce({ userId: 'ghost', email: 'g@g.com' });
      db.query.mockResolvedValueOnce({ rows: [], rowCount: 0 }); // user not found
      const res = await request(app).post('/api/v1/auth/refresh').set('Authorization', authHeader(tok));
      expect(res.status).toBe(401);
    });

    it('POST /refresh returns 401 on JsonWebTokenError', async () => {
      const tok = jwt.sign({ userId: 'u1' }, 'secret');
      const err = new Error('bad token'); err.name = 'JsonWebTokenError';
      jwt.verify.mockImplementationOnce(() => { throw err; });
      const res = await request(app).post('/api/v1/auth/refresh').set('Authorization', authHeader(tok));
      expect(res.status).toBe(401);
    });

    it('POST /refresh returns 401 on TokenExpiredError', async () => {
      const tok = jwt.sign({ userId: 'u1' }, 'secret');
      const err = new Error('expired'); err.name = 'TokenExpiredError';
      jwt.verify.mockImplementationOnce(() => { throw err; });
      const res = await request(app).post('/api/v1/auth/refresh').set('Authorization', authHeader(tok));
      expect(res.status).toBe(401);
    });

    it('POST /biometric-token returns 401 when no auth header', async () => {
      const res = await request(app).post('/api/v1/auth/biometric-token');
      expect(res.status).toBe(401);
    });

    it('POST /biometric-token returns 401 when user not found in DB', async () => {
      const tok = jwt.sign({ userId: 'ghost' }, 'secret');
      jwt.verify.mockReturnValueOnce({ userId: 'ghost' });
      db.query.mockResolvedValueOnce({ rows: [], rowCount: 0 });
      const res = await request(app).post('/api/v1/auth/biometric-token').set('Authorization', authHeader(tok));
      expect(res.status).toBe(401);
    });

    it('POST /biometric-token returns 401 on JWT error', async () => {
      const tok = 'invalid.token';
      const err = new Error('bad'); err.name = 'JsonWebTokenError';
      jwt.verify.mockImplementationOnce(() => { throw err; });
      const res = await request(app).post('/api/v1/auth/biometric-token').set('Authorization', authHeader(tok));
      expect(res.status).toBe(401);
    });
  });

  describe('Password Reset — extra branches', () => {
    it('POST /forgot-password returns 400 when email is missing', async () => {
      const res = await request(app).post('/api/v1/auth/forgot-password').send({});
      expect(res.status).toBe(400);
    });

    it('POST /forgot-password returns 200 when email not found in DB (security)', async () => {
      db.query.mockResolvedValueOnce({ rows: [], rowCount: 0 });
      const res = await request(app).post('/api/v1/auth/forgot-password').send({ email: 'ghost@x.com' });
      expect(res.status).toBe(200);
    });

    it('POST /forgot-password returns 200 even when reset email fails', async () => {
      const emailService = require('../../services/email');
      emailService.sendPasswordResetEmail.mockResolvedValueOnce({ success: false, error: 'SMTP' });
      db.query
        .mockResolvedValueOnce({ rows: [{ id: 'u1', name: 'User' }] })
        .mockResolvedValueOnce({});
      const res = await request(app).post('/api/v1/auth/forgot-password').send({ email: 'emailfail@x.com' });
      expect(res.status).toBe(200);
    });

    it('POST /forgot-password returns 500 on DB error', async () => {
      db.query.mockRejectedValueOnce(new Error('DB down'));
      const res = await request(app).post('/api/v1/auth/forgot-password').send({ email: 'err@x.com' });
      expect(res.status).toBe(500);
    });

    it('GET /reset-password returns 400 HTML when token param is missing', async () => {
      const res = await request(app).get('/api/v1/auth/reset-password');
      expect(res.status).toBe(400);
    });

    it('GET /reset-password returns 400 when token is expired', async () => {
      db.query.mockResolvedValueOnce({
        rows: [{ id: 'u1', password_reset_expires: new Date(Date.now() - 1000).toISOString() }],
      });
      const res = await request(app).get('/api/v1/auth/reset-password?token=expiredtoken');
      expect(res.status).toBe(400);
    });

    it('GET /reset-password returns 500 on DB error', async () => {
      db.query.mockRejectedValueOnce(new Error('DB down'));
      const res = await request(app).get('/api/v1/auth/reset-password?token=anytoken');
      expect(res.status).toBe(500);
    });

    it('POST /reset-password returns 400 when token is missing', async () => {
      const res = await request(app).post('/api/v1/auth/reset-password').send({ password: 'NewStrongPass1!' });
      expect(res.status).toBe(400);
    });

    it('POST /reset-password returns 400 when new password is weak', async () => {
      const res = await request(app).post('/api/v1/auth/reset-password').send({ token: 'tok', password: 'allowercase' });
      expect(res.status).toBe(400);
    });

    it('POST /reset-password returns 400 when reset token not found in DB', async () => {
      db.query.mockResolvedValueOnce({ rows: [], rowCount: 0 });
      const res = await request(app).post('/api/v1/auth/reset-password').send({ token: 'badtoken', password: 'NewStrongPass1!' });
      expect(res.status).toBe(400);
    });

    it('POST /reset-password returns 400 when reset token is expired', async () => {
      db.query.mockResolvedValueOnce({
        rows: [{ id: 'u1', password_reset_expires: new Date(Date.now() - 1000).toISOString() }],
      });
      const res = await request(app).post('/api/v1/auth/reset-password').send({ token: 'expired', password: 'NewStrongPass1!' });
      expect(res.status).toBe(400);
    });

    it('POST /reset-password returns 500 on DB error', async () => {
      db.query.mockRejectedValueOnce(new Error('DB down'));
      const res = await request(app).post('/api/v1/auth/reset-password').send({ token: 'tok', password: 'NewStrongPass1!' });
      expect(res.status).toBe(500);
    });
  });

  describe('2FA — extra branches', () => {
    it('POST /2fa/setup returns 401 when no auth token', async () => {
      const res = await request(app).post('/api/v1/auth/2fa/setup');
      expect(res.status).toBe(401);
    });

    it('POST /2fa/setup returns 403 when token is invalid', async () => {
      jwt.verify.mockImplementationOnce((t, s, cb) => cb(new Error('bad'), null));
      const res = await request(app)
        .post('/api/v1/auth/2fa/setup')
        .set('Authorization', 'Bearer invalid.token');
      expect(res.status).toBe(403);
    });

    it('POST /2fa/verify returns 422 when code is not 6 digits', async () => {
      const validToken = jwt.sign({ userId: 'u1' }, 'secret');
      jwt.verify.mockImplementationOnce((t, s, cb) => cb(null, { userId: 'u1' }));
      const res = await request(app)
        .post('/api/v1/auth/2fa/verify')
        .set('Authorization', authHeader(validToken))
        .send({ code: 'abc' });
      expect(res.status).toBe(422);
    });

    it('POST /2fa/verify returns 400 when no pending TOTP secret', async () => {
      const validToken = jwt.sign({ userId: 'u1' }, 'secret');
      jwt.verify.mockImplementationOnce((t, s, cb) => cb(null, { userId: 'u1' }));
      db.query.mockResolvedValueOnce({ rows: [{ totp_secret_pending: null }] });
      const res = await request(app)
        .post('/api/v1/auth/2fa/verify')
        .set('Authorization', authHeader(validToken))
        .send({ code: '123456' });
      expect(res.status).toBe(400);
    });

    it('POST /2fa/verify returns 401 when TOTP code is wrong', async () => {
      const validToken = jwt.sign({ userId: 'u1' }, 'secret');
      jwt.verify.mockImplementationOnce((t, s, cb) => cb(null, { userId: 'u1' }));
      db.query.mockResolvedValueOnce({ rows: [{ totp_secret_pending: 'JBSWY3DPEHPK3PXP' }] });
      const res = await request(app)
        .post('/api/v1/auth/2fa/verify')
        .set('Authorization', authHeader(validToken))
        .send({ code: '000000' }); // almost certainly wrong
      expect(res.status).toBe(401);
    });

    it('POST /2fa/validate returns 422 when required params are missing', async () => {
      const res = await request(app).post('/api/v1/auth/2fa/validate').send({});
      expect(res.status).toBe(422);
    });

    it('POST /2fa/validate returns 401 when temp_token is invalid JWT', async () => {
      jwt.verify.mockImplementationOnce(() => { throw Object.assign(new Error('bad'), { name: 'JsonWebTokenError' }); });
      const res = await request(app).post('/api/v1/auth/2fa/validate').send({ temp_token: 'bad.tok', code: '123456' });
      expect(res.status).toBe(401);
    });

    it('POST /2fa/validate returns 401 when user has no 2FA enabled', async () => {
      const tempToken = jwt.sign({ userId: 'u1', '2fa_pending': true }, 'secret');
      jwt.verify.mockReturnValueOnce({ userId: 'u1', '2fa_pending': true });
      db.query.mockResolvedValueOnce({ rows: [], rowCount: 0 }); // user not found / 2FA not enabled
      const res = await request(app).post('/api/v1/auth/2fa/validate').send({ temp_token: tempToken, code: '123456' });
      expect(res.status).toBe(401);
    });

    it('POST /2fa/disable returns 401 when password is wrong', async () => {
      const validToken = jwt.sign({ userId: 'u1' }, 'secret');
      jwt.verify.mockImplementationOnce((t, s, cb) => cb(null, { userId: 'u1' }));
      const hashedPassword = bcrypt.hashSync('CorrectPass1!', 10);
      db.query.mockResolvedValueOnce({ rows: [{ password: hashedPassword, is_2fa_enabled: true }] });
      const res = await request(app)
        .post('/api/v1/auth/2fa/disable')
        .set('Authorization', authHeader(validToken))
        .send({ password: 'WrongPass1!' });
      expect(res.status).toBe(401);
    });
  });
});