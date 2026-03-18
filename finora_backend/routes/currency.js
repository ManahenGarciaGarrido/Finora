/**
 * Currency exchange rate endpoint
 *
 * GET /api/v1/currency/rates?base=EUR
 *   Returns live exchange rates from Frankfurter (ECB data, free, no key needed).
 *   Caches results for 1 hour in memory; serves stale data on failure.
 */

const express = require('express');
const router = express.Router();
const { authenticateToken } = require('../middleware/auth');

// In-memory cache: { [base]: { ts: number, data: object } }
const _cache = {};

router.get('/rates', authenticateToken, async (req, res) => {
  const base = (req.query.base || 'EUR').toUpperCase();
  const now = Date.now();

  if (_cache[base] && now - _cache[base].ts < 3_600_000) {
    return res.json(_cache[base].data);
  }

  try {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 8000);
    const resp = await fetch(
      `https://api.frankfurter.app/latest?from=${base}`,
      { signal: controller.signal },
    );
    clearTimeout(timeout);

    if (!resp.ok) throw new Error(`Frankfurter ${resp.status}`);
    const data = await resp.json();
    _cache[base] = { ts: now, data };
    return res.json(data);
  } catch (e) {
    if (_cache[base]) {
      // Serve stale on network failure
      return res.json(_cache[base].data);
    }
    return res.status(503).json({ error: 'Exchange rates unavailable' });
  }
});

module.exports = router;
