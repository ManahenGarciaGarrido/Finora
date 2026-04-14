'use strict';

/**
 * Configurable DB mock for per-test setup.
 *
 * Usage in test files:
 *   jest.mock('../../services/db', () => require('../helpers/mockDb'));
 *
 * Then per test:
 *   const db = require('../../services/db');
 *   db.query.mockResolvedValueOnce({ rows: [...], rowCount: 1 });
 */

const db = {
  query: jest.fn().mockResolvedValue({ rows: [], rowCount: 0 }),
  getClient: jest.fn().mockResolvedValue({
    query: jest.fn(),
    release: jest.fn(),
  }),
  healthCheck: jest.fn().mockResolvedValue({ status: 'healthy', timestamp: new Date() }),
  pool: {
    query: jest.fn(),
    connect: jest.fn(),
    end: jest.fn(),
  },
};

module.exports = db;
