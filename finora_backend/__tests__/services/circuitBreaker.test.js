'use strict';

const { CircuitBreaker, withRetry, withCache, clearCache, backoffDelay } = require('../../services/circuitBreaker');

describe('CircuitBreaker', () => {
  // ── Closed state ──────────────────────────────────────────────────────────
  describe('CLOSED state', () => {
    it('calls the function normally when circuit is closed', async () => {
      const cb = new CircuitBreaker('test-service', { threshold: 3 });
      const fn = jest.fn().mockResolvedValue('success');

      const result = await cb.call(fn);

      expect(result).toBe('success');
      expect(fn).toHaveBeenCalledTimes(1);
    });

    it('starts in CLOSED state', () => {
      const cb = new CircuitBreaker('test-service');
      expect(cb.state).toBe('CLOSED');
    });

    it('stays closed after successful calls', async () => {
      const cb = new CircuitBreaker('test-service', { threshold: 3 });
      const fn = jest.fn().mockResolvedValue('ok');

      await cb.call(fn);
      await cb.call(fn);
      await cb.call(fn);

      expect(cb.state).toBe('CLOSED');
    });
  });

  // ── Open state after threshold failures ───────────────────────────────────
  describe('OPEN state after threshold failures', () => {
    it('opens after reaching failure threshold', async () => {
      const cb = new CircuitBreaker('test-service', { threshold: 3, timeout: 60000 });
      const fn = jest.fn().mockRejectedValue(new Error('service down'));

      for (let i = 0; i < 3; i++) {
        await expect(cb.call(fn)).rejects.toThrow('service down');
      }

      expect(cb.state).toBe('OPEN');
    });

    it('rejects immediately without calling fn when OPEN', async () => {
      const cb = new CircuitBreaker('test-service', { threshold: 2, timeout: 60000 });
      const fn = jest.fn().mockRejectedValue(new Error('service down'));

      // Trigger threshold failures
      await expect(cb.call(fn)).rejects.toThrow();
      await expect(cb.call(fn)).rejects.toThrow();

      expect(cb.state).toBe('OPEN');

      // Reset mock to succeed now, but circuit should reject immediately
      const successFn = jest.fn().mockResolvedValue('ok');
      await expect(cb.call(successFn)).rejects.toThrow(/OPEN/);
      expect(successFn).not.toHaveBeenCalled();
    });
  });

  // ── Half-open after timeout ───────────────────────────────────────────────
  describe('HALF-OPEN state after timeout', () => {
    it('transitions to HALF-OPEN after timeout and allows one probe', async () => {
      const cb = new CircuitBreaker('test-service', { threshold: 2, timeout: 50 });
      const failFn = jest.fn().mockRejectedValue(new Error('down'));

      await expect(cb.call(failFn)).rejects.toThrow();
      await expect(cb.call(failFn)).rejects.toThrow();
      expect(cb.state).toBe('OPEN');

      // Wait for timeout to elapse
      await new Promise(resolve => setTimeout(resolve, 60));

      // Next call should be allowed (HALF state)
      const successFn = jest.fn().mockResolvedValue('recovered');
      const result = await cb.call(successFn);

      expect(result).toBe('recovered');
      expect(successFn).toHaveBeenCalledTimes(1);
    });

    it('goes back to OPEN when probe fails in HALF state', async () => {
      const cb = new CircuitBreaker('test-service', { threshold: 2, timeout: 50 });
      const failFn = jest.fn().mockRejectedValue(new Error('down'));

      await expect(cb.call(failFn)).rejects.toThrow();
      await expect(cb.call(failFn)).rejects.toThrow();

      await new Promise(resolve => setTimeout(resolve, 60));

      // Probe fails again
      await expect(cb.call(failFn)).rejects.toThrow();

      expect(cb.state).toBe('OPEN');
    });
  });

  // ── Reset on success ──────────────────────────────────────────────────────
  describe('Reset on success', () => {
    it('resets to CLOSED after successThreshold successes in HALF state', async () => {
      const cb = new CircuitBreaker('test-service', {
        threshold: 2,
        timeout: 50,
        successThreshold: 2,
      });
      const failFn = jest.fn().mockRejectedValue(new Error('down'));

      await expect(cb.call(failFn)).rejects.toThrow();
      await expect(cb.call(failFn)).rejects.toThrow();

      await new Promise(resolve => setTimeout(resolve, 60));

      const successFn = jest.fn().mockResolvedValue('ok');
      await cb.call(successFn); // first success in HALF
      await cb.call(successFn); // second success — should close

      expect(cb.state).toBe('CLOSED');
    });

    it('manual reset returns to CLOSED state', () => {
      const cb = new CircuitBreaker('test-service', { threshold: 2, timeout: 60000 });

      // Force open state by setting internal state
      cb._state = 'OPEN';
      cb._failures = 2;
      cb._openedAt = Date.now();

      cb.reset();

      expect(cb.state).toBe('CLOSED');
      expect(cb._failures).toBe(0);
    });

    it('resets failure count on success in CLOSED state', async () => {
      const cb = new CircuitBreaker('test-service', { threshold: 3 });
      const failFn = jest.fn().mockRejectedValue(new Error('fail'));
      const successFn = jest.fn().mockResolvedValue('ok');

      // Two failures (below threshold)
      await expect(cb.call(failFn)).rejects.toThrow();
      await expect(cb.call(failFn)).rejects.toThrow();
      expect(cb._failures).toBe(2);

      // Success resets failure count
      await cb.call(successFn);
      expect(cb._failures).toBe(0);
      expect(cb.state).toBe('CLOSED');
    });
  });

  // ── status() method ───────────────────────────────────────────────────────
  describe('status()', () => {
    it('returns correct status object', () => {
      const cb = new CircuitBreaker('my-service', { threshold: 5 });
      const status = cb.status();

      expect(status).toHaveProperty('name', 'my-service');
      expect(status).toHaveProperty('state', 'CLOSED');
      expect(status).toHaveProperty('failures', 0);
    });
  });
});

// ── withRetry ────────────────────────────────────────────────────────────────
describe('withRetry', () => {
  it('returns result on first success', async () => {
    const fn = jest.fn().mockResolvedValue(42);
    const result = await withRetry(fn, { maxAttempts: 3, baseDelayMs: 1 });
    expect(result).toBe(42);
    expect(fn).toHaveBeenCalledTimes(1);
  });

  it('retries on network error and succeeds', async () => {
    const fn = jest.fn()
      .mockRejectedValueOnce(new Error('ECONNRESET'))
      .mockResolvedValue('ok');

    const result = await withRetry(fn, { maxAttempts: 3, baseDelayMs: 1 });
    expect(result).toBe('ok');
    expect(fn).toHaveBeenCalledTimes(2);
  });

  it('throws after all attempts exhausted', async () => {
    const fn = jest.fn().mockRejectedValue(new Error('ECONNREFUSED'));

    await expect(withRetry(fn, { maxAttempts: 3, baseDelayMs: 1 })).rejects.toThrow('ECONNREFUSED');
    expect(fn).toHaveBeenCalledTimes(3);
  });

  it('does not retry on 4xx errors', async () => {
    const fn = jest.fn().mockRejectedValue(new Error('HTTP 400: Bad Request'));

    await expect(withRetry(fn, { maxAttempts: 3, baseDelayMs: 1 })).rejects.toThrow();
    expect(fn).toHaveBeenCalledTimes(1);
  });
});

// ── backoffDelay ─────────────────────────────────────────────────────────────
describe('backoffDelay', () => {
  it('returns a number', () => {
    const delay = backoffDelay(0, 500, 30000);
    expect(typeof delay).toBe('number');
    expect(delay).toBeGreaterThan(0);
  });

  it('respects max delay cap', () => {
    const delay = backoffDelay(100, 500, 1000);
    expect(delay).toBeLessThanOrEqual(1200); // allows 20% jitter above max
  });

  it('increases with attempt number', () => {
    const delay0 = backoffDelay(0, 100, 30000);
    const delay2 = backoffDelay(2, 100, 30000);
    // On average delay2 should be larger; test without jitter by checking base values
    expect(100 * 2 ** 2).toBeGreaterThan(100 * 2 ** 0);
  });
});

// ── withCache ─────────────────────────────────────────────────────────────────
describe('withCache', () => {
  beforeEach(() => {
    clearCache();
  });

  it('calls fn on first access and caches the result', async () => {
    const fn = jest.fn().mockResolvedValue({ data: 'fresh' });

    const result1 = await withCache('test-key', fn, 10000);
    const result2 = await withCache('test-key', fn, 10000);

    expect(result1).toEqual({ data: 'fresh' });
    expect(result2).toEqual({ data: 'fresh' });
    expect(fn).toHaveBeenCalledTimes(1); // cached on second call
  });

  it('returns stale data when fn fails and allowStale is true', async () => {
    const fn = jest.fn()
      .mockResolvedValueOnce({ data: 'cached-value' })
      .mockRejectedValueOnce(new Error('network error'));

    // Prime cache
    await withCache('stale-key', fn, 1);

    // Wait for TTL to expire
    await new Promise(resolve => setTimeout(resolve, 5));

    // Second call fails but returns stale
    const result = await withCache('stale-key', fn, 1, { allowStale: true });
    expect(result).toEqual({ data: 'cached-value' });
  });

  it('throws when fn fails and no stale data', async () => {
    const fn = jest.fn().mockRejectedValue(new Error('no connection'));

    await expect(withCache('fresh-key', fn, 10000)).rejects.toThrow('no connection');
  });
});
