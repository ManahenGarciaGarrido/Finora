'use strict';

const jwt = require('jsonwebtoken');

const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-change-in-production';

/**
 * Creates a signed JWT token for use in test Authorization headers.
 */
const createTestToken = (userId = 1, email = 'test@test.com') => {
  return jwt.sign({ userId, email }, JWT_SECRET, { expiresIn: '1h' });
};

/**
 * Creates an expired JWT token for testing token expiry behavior.
 */
const createExpiredToken = (userId = 1, email = 'test@test.com') => {
  return jwt.sign({ userId, email }, JWT_SECRET, { expiresIn: '-1s' });
};

/**
 * Creates a malformed (invalid signature) token.
 */
const createInvalidToken = () => {
  return 'Bearer invalid.token.here';
};

/**
 * Standard mock DB object — wire up per-test via mockResolvedValueOnce.
 */
const mockDb = {
  query: jest.fn(),
  getClient: jest.fn().mockResolvedValue({
    query: jest.fn(),
    release: jest.fn(),
  }),
  healthCheck: jest.fn().mockResolvedValue({ status: 'healthy', timestamp: new Date() }),
};

module.exports = { createTestToken, createExpiredToken, createInvalidToken, mockDb };
