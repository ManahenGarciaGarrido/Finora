'use strict';

const jwt = require('jsonwebtoken');
const { authenticateToken } = require('../../middleware/auth');

const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-change-in-production';

function buildReqRes(authHeader) {
  const req = {
    headers: authHeader !== undefined ? { authorization: authHeader } : {},
  };
  const res = {
    status: jest.fn().mockReturnThis(),
    json: jest.fn().mockReturnThis(),
  };
  const next = jest.fn();
  return { req, res, next };
}

describe('authenticateToken middleware', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('missing / malformed Authorization header', () => {
    it('returns 401 when Authorization header is absent', () => {
      const { req, res, next } = buildReqRes(undefined);
      authenticateToken(req, res, next);
      expect(res.status).toHaveBeenCalledWith(401);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({ message: 'No token provided' }),
      );
      expect(next).not.toHaveBeenCalled();
    });

    it('returns 401 when Authorization header does not start with "Bearer "', () => {
      const { req, res, next } = buildReqRes('Basic sometoken');
      authenticateToken(req, res, next);
      expect(res.status).toHaveBeenCalledWith(401);
      expect(next).not.toHaveBeenCalled();
    });

    it('returns 401 when Authorization header is an empty string', () => {
      const { req, res, next } = buildReqRes('');
      authenticateToken(req, res, next);
      expect(res.status).toHaveBeenCalledWith(401);
      expect(next).not.toHaveBeenCalled();
    });
  });

  describe('invalid token', () => {
    it('returns 401 when token has wrong signature (JsonWebTokenError)', () => {
      const badToken = jwt.sign({ userId: 1 }, 'wrong-secret');
      const { req, res, next } = buildReqRes(`Bearer ${badToken}`);
      authenticateToken(req, res, next);
      expect(res.status).toHaveBeenCalledWith(401);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({ message: 'Invalid token' }),
      );
      expect(next).not.toHaveBeenCalled();
    });

    it('returns 401 when token is completely malformed', () => {
      const { req, res, next } = buildReqRes('Bearer this.is.garbage');
      authenticateToken(req, res, next);
      expect(res.status).toHaveBeenCalledWith(401);
      expect(next).not.toHaveBeenCalled();
    });
  });

  describe('expired token', () => {
    it('returns 401 when token is expired (TokenExpiredError)', () => {
      const expired = jwt.sign({ userId: 1, email: 'a@b.com' }, JWT_SECRET, { expiresIn: '-1s' });
      const { req, res, next } = buildReqRes(`Bearer ${expired}`);
      authenticateToken(req, res, next);
      expect(res.status).toHaveBeenCalledWith(401);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({ message: 'Token expired' }),
      );
      expect(next).not.toHaveBeenCalled();
    });
  });

  describe('generic verification error', () => {
    it('returns 401 generic Authentication failed for unknown errors', () => {
      // Forzamos un error que NO sea ni JsonWebTokenError ni TokenExpiredError
      jest.spyOn(jwt, 'verify').mockImplementationOnce(() => {
        throw new Error('Database down or catastrophic failure');
      });

      const { req, res, next } = buildReqRes('Bearer some.validlooking.token');
      authenticateToken(req, res, next);
      
      expect(res.status).toHaveBeenCalledWith(401);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({ message: 'Authentication failed' }),
      );
      expect(next).not.toHaveBeenCalled();
      
      jwt.verify.mockRestore(); // Limpiamos el mock para no afectar a otros tests
    });
  });

  describe('valid token', () => {
    it('calls next() and sets req.user when token is valid', () => {
      const payload = { userId: 42, email: 'user@example.com' };
      const token = jwt.sign(payload, JWT_SECRET, { expiresIn: '1h' });
      const { req, res, next } = buildReqRes(`Bearer ${token}`);
      authenticateToken(req, res, next);
      expect(next).toHaveBeenCalledTimes(1);
      expect(req.user).toBeDefined();
      expect(req.user.userId).toBe(42);
      expect(req.user.email).toBe('user@example.com');
      expect(res.status).not.toHaveBeenCalled();
    });
  });
});