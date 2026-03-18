/**
 * Circuit Breaker + Exponential Backoff — RNF-16
 *
 * Proporciona:
 *  - withRetry(fn, opts)         → Ejecuta fn con reintentos y backoff exponencial
 *  - CircuitBreaker              → Clase para proteger servicios externos (Plaid, rates, etc.)
 *  - withCache(key, fn, ttlMs)   → Envuelve fn con caché en memoria (fallback si falla)
 *
 * Uso en plaid.js, banks.js, etc.:
 *
 *   const { withRetry, CircuitBreaker, withCache } = require('./circuitBreaker');
 *
 *   // Reintentar hasta 3 veces con backoff exponencial
 *   const data = await withRetry(() => plaidPost('/accounts/get', body));
 *
 *   // Circuit breaker — abre tras 5 fallos consecutivos, espera 60s
 *   const plaidBreaker = new CircuitBreaker('plaid', { threshold: 5, timeout: 60000 });
 *   const result = await plaidBreaker.call(() => plaidPost('/accounts/get', body));
 *
 *   // Caché con TTL (con fallback al último valor si el servicio falla)
 *   const rates = await withCache('eur_usd', fetchRates, 3600000);
 */

'use strict';

// ─── Exponential backoff ───────────────────────────────────────────────────────

/**
 * Espera ms milisegundos.
 * @param {number} ms
 */
function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

/**
 * Calcula el tiempo de espera con jitter para evitar "thunder herd".
 * @param {number} attempt  Intento actual (0-based)
 * @param {number} base     Tiempo base en ms (default 500ms)
 * @param {number} max      Máximo tiempo de espera en ms (default 30s)
 */
function backoffDelay(attempt, base = 500, max = 30000) {
  const expo = Math.min(base * 2 ** attempt, max);
  // Jitter: ±20% aleatorio para evitar sincronización de reintentos
  const jitter = expo * 0.2 * (Math.random() - 0.5) * 2;
  return Math.round(expo + jitter);
}

/**
 * Ejecuta `fn` con reintentos automáticos y backoff exponencial (RNF-16).
 *
 * @param {function():Promise<any>} fn   Función a ejecutar
 * @param {object} opts
 * @param {number}  opts.maxAttempts   Número máximo de intentos (default 3)
 * @param {number}  opts.baseDelayMs   Delay base en ms (default 500)
 * @param {number}  opts.maxDelayMs    Delay máximo en ms (default 30000)
 * @param {function(Error,number):boolean} [opts.retryIf]
 *        Función que decide si reintentar dado el error y el intento actual.
 *        Por defecto reintenta en errores de red/timeout.
 * @returns {Promise<any>}
 */
async function withRetry(fn, opts = {}) {
  const {
    maxAttempts = 3,
    baseDelayMs = 500,
    maxDelayMs  = 30000,
    retryIf     = defaultShouldRetry,
  } = opts;

  let lastError;

  for (let attempt = 0; attempt < maxAttempts; attempt++) {
    try {
      return await fn();
    } catch (err) {
      lastError = err;

      const isLastAttempt = attempt === maxAttempts - 1;
      if (isLastAttempt || !retryIf(err, attempt)) {
        throw err;
      }

      const delay = backoffDelay(attempt, baseDelayMs, maxDelayMs);
      console.warn(
        `[retry] Intento ${attempt + 1}/${maxAttempts} fallido. ` +
        `Reintentando en ${delay}ms. Error: ${err.message}`
      );
      await sleep(delay);
    }
  }

  throw lastError;
}

/**
 * Decide si un error justifica un reintento.
 * Se reintenta en errores de red, timeout, y errores 5xx del servidor.
 * NO se reintenta en 4xx (errores del cliente → corrección necesaria).
 *
 * @param {Error} err
 * @param {number} attempt
 */
function defaultShouldRetry(err, attempt) {
  const msg = err.message || '';

  // Errores de red y timeout → reintentar siempre
  if (
    msg.includes('ECONNRESET') ||
    msg.includes('ECONNREFUSED') ||
    msg.includes('ETIMEDOUT') ||
    msg.includes('ENOTFOUND') ||
    msg.includes('socket hang up') ||
    msg.includes('timeout') ||
    msg.includes('network') ||
    msg.includes('fetch failed')
  ) {
    return true;
  }

  // Errores HTTP del servidor (5xx) → reintentar
  const statusMatch = msg.match(/(\d{3})/);
  if (statusMatch) {
    const status = parseInt(statusMatch[1], 10);
    if (status >= 500 && status < 600) return true;
    // 4xx → no reintentar (es error del cliente)
    if (status >= 400 && status < 500) return false;
  }

  // Por defecto: no reintentar
  return false;
}

// ─── Circuit Breaker ──────────────────────────────────────────────────────────

/**
 * Estados del Circuit Breaker:
 *  CLOSED  → Funciona con normalidad. Pasa las peticiones.
 *  OPEN    → Circuito abierto. Rechaza peticiones directamente (fast-fail).
 *  HALF    → Semi-abierto. Permite una petición de prueba para comprobar recuperación.
 */
const STATE = Object.freeze({ CLOSED: 'CLOSED', OPEN: 'OPEN', HALF: 'HALF' });

class CircuitBreaker {
  /**
   * @param {string} name    Nombre del servicio (para logs)
   * @param {object} opts
   * @param {number} opts.threshold    Fallos consecutivos para abrir el circuito (default 5)
   * @param {number} opts.timeout      Ms en estado OPEN antes de pasar a HALF (default 60000 = 1 min)
   * @param {number} opts.successThreshold  Éxitos consecutivos en HALF para cerrar (default 2)
   */
  constructor(name, opts = {}) {
    this.name = name;
    this.threshold         = opts.threshold         ?? 5;
    this.timeout           = opts.timeout           ?? 60_000;
    this.successThreshold  = opts.successThreshold  ?? 2;

    this._state       = STATE.CLOSED;
    this._failures    = 0;
    this._successes   = 0;
    this._openedAt    = null;
  }

  get state() { return this._state; }

  /**
   * Ejecuta `fn` a través del circuit breaker.
   * - CLOSED → pasa directo
   * - OPEN   → lanza error inmediato sin llamar a fn
   * - HALF   → permite una llamada de prueba
   *
   * @param {function():Promise<any>} fn
   * @returns {Promise<any>}
   */
  async call(fn) {
    if (this._state === STATE.OPEN) {
      const elapsed = Date.now() - this._openedAt;
      if (elapsed >= this.timeout) {
        console.info(`[circuit-breaker][${this.name}] OPEN → HALF (${elapsed}ms elapsed)`);
        this._state = STATE.HALF;
      } else {
        throw new Error(
          `[CircuitBreaker] ${this.name} está OPEN. ` +
          `Reintenta en ${Math.ceil((this.timeout - elapsed) / 1000)}s.`
        );
      }
    }

    try {
      const result = await fn();
      this._onSuccess();
      return result;
    } catch (err) {
      this._onFailure(err);
      throw err;
    }
  }

  _onSuccess() {
    this._failures = 0;

    if (this._state === STATE.HALF) {
      this._successes++;
      if (this._successes >= this.successThreshold) {
        console.info(`[circuit-breaker][${this.name}] HALF → CLOSED`);
        this._state    = STATE.CLOSED;
        this._successes = 0;
        this._openedAt  = null;
      }
    }
  }

  _onFailure(err) {
    this._successes = 0;

    if (this._state === STATE.HALF) {
      console.warn(`[circuit-breaker][${this.name}] HALF → OPEN (fallo en prueba): ${err.message}`);
      this._state    = STATE.OPEN;
      this._openedAt = Date.now();
      this._failures  = this.threshold;
      return;
    }

    this._failures++;
    if (this._failures >= this.threshold) {
      console.error(
        `[circuit-breaker][${this.name}] CLOSED → OPEN ` +
        `(${this._failures} fallos consecutivos). Error: ${err.message}`
      );
      this._state    = STATE.OPEN;
      this._openedAt = Date.now();
    }
  }

  /** Restablecer manualmente el circuito (útil en tests o recuperación manual) */
  reset() {
    this._state    = STATE.CLOSED;
    this._failures  = 0;
    this._successes = 0;
    this._openedAt  = null;
    console.info(`[circuit-breaker][${this.name}] Reset manual → CLOSED`);
  }

  /** Estado legible para monitorización */
  status() {
    return {
      name:    this.name,
      state:   this._state,
      failures: this._failures,
      openedAt: this._openedAt ? new Date(this._openedAt).toISOString() : null,
    };
  }
}

// ─── Cache en memoria con TTL y fallback (RNF-16) ─────────────────────────────

/**
 * Mapa global de caché: key → { value, expiresAt, stale }
 * "stale" guarda el último valor conocido para usarlo como fallback si el servicio falla.
 */
const _cache = new Map();

/**
 * Envuelve `fn` con caché en memoria con TTL (RNF-16: fallback a datos en caché si falla API).
 *
 * @param {string}   key    Clave de caché
 * @param {function():Promise<any>} fn   Función que obtiene datos frescos
 * @param {number}   ttlMs  Tiempo de vida en ms (default 3600000 = 1h)
 * @param {object}   opts
 * @param {boolean}  opts.allowStale   Si true, retorna datos obsoletos si fn falla (default true)
 * @returns {Promise<any>}
 */
async function withCache(key, fn, ttlMs = 3_600_000, opts = {}) {
  const { allowStale = true } = opts;

  const cached = _cache.get(key);
  if (cached && Date.now() < cached.expiresAt) {
    return cached.value;
  }

  try {
    const value = await fn();
    _cache.set(key, {
      value,
      expiresAt: Date.now() + ttlMs,
      stale: value, // guardar como "último valor conocido"
    });
    return value;
  } catch (err) {
    // Si hay un valor obsoleto (stale) y allowStale está activo → usarlo como fallback
    if (allowStale && cached?.stale !== undefined) {
      console.warn(
        `[cache][${key}] Error al actualizar (${err.message}). ` +
        `Usando valor en caché obsoleto como fallback.`
      );
      return cached.stale;
    }
    throw err;
  }
}

/**
 * Invalida una entrada de caché manualmente.
 * @param {string} key
 */
function invalidateCache(key) {
  _cache.delete(key);
}

/**
 * Limpia toda la caché.
 */
function clearCache() {
  _cache.clear();
}

// ─── Instancias globales de circuit breakers ──────────────────────────────────

/** Circuit breaker para la API de Plaid */
const plaidBreaker = new CircuitBreaker('plaid', {
  threshold: 5,
  timeout:   60_000,
});

/** Circuit breaker para la API de tasas de cambio (frankfurter.app) */
const ratesBreaker = new CircuitBreaker('exchange-rates', {
  threshold: 3,
  timeout:   30_000,
});

module.exports = {
  // Funciones de utilidad
  withRetry,
  withCache,
  invalidateCache,
  clearCache,
  backoffDelay,
  sleep,

  // Clase
  CircuitBreaker,

  // Instancias globales
  plaidBreaker,
  ratesBreaker,
};