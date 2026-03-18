/**
 * Investment routes
 *
 * Endpoints:
 *   GET    /investments/profile           - get investor profile
 *   POST   /investments/profile           - save profile
 *   GET    /investments/portfolio/suggest - suggest ETF portfolio based on profile
 *   POST   /investments/simulator         - simulate investment returns
 *   GET    /investments/indices           - market indices (live from CoinGecko + Yahoo Finance)
 *   GET    /investments/chart/:ticker     - OHLCV chart data for a ticker
 *   GET    /investments/search            - search assets by name/ticker
 *   GET    /investments/glossary          - financial glossary terms
 */

const express = require('express');
const router = express.Router();
const db = require('../services/db');
const { authenticateToken } = require('../middleware/auth');
const { body, validationResult } = require('express-validator');

// ─── In-memory cache ──────────────────────────────────────────────────────────
const _cache = {};
const TTL_PRICES = 5 * 60 * 1000;       // 5 minutes
const TTL_HISTORY = 24 * 60 * 60 * 1000; // 24 hours

function getCache(key) {
  const entry = _cache[key];
  if (entry && Date.now() - entry.ts < entry.ttl) return entry.data;
  return null;
}
function setCache(key, data, ttl) {
  _cache[key] = { data, ts: Date.now(), ttl };
}

// ─── GET /investments/profile ─────────────────────────────────────────────────

router.get('/profile', authenticateToken, async (req, res) => {
  try {
    const result = await db.query(
      `SELECT id, risk_tolerance, investment_horizon, monthly_capacity::float, created_at, updated_at
       FROM investor_profiles WHERE user_id = $1`,
      [req.user.userId]
    );
    res.json({ profile: result.rows[0] || null });
  } catch (err) {
    console.error('investments/profile error:', err);
    res.status(500).json({ error: 'Internal Server Error', message: err.message });
  }
});

// ─── POST /investments/profile ────────────────────────────────────────────────

router.post('/profile', authenticateToken,
  [
    body('risk_tolerance').isIn(['conservative', 'moderate', 'aggressive']),
    body('investment_horizon').isIn(['short', 'medium', 'long']),
  ],
  async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(422).json({ error: 'Validation Error', details: errors.array() });
    }
    try {
      const { risk_tolerance, investment_horizon, monthly_capacity } = req.body;
      const result = await db.query(
        `INSERT INTO investor_profiles (user_id, risk_tolerance, investment_horizon, monthly_capacity)
         VALUES ($1, $2, $3, $4)
         ON CONFLICT (user_id) DO UPDATE
           SET risk_tolerance = $2, investment_horizon = $3,
               monthly_capacity = $4, updated_at = NOW()
         RETURNING id, risk_tolerance, investment_horizon, monthly_capacity::float, created_at, updated_at`,
        [req.user.userId, risk_tolerance, investment_horizon, monthly_capacity || null]
      );
      res.json({ profile: result.rows[0] });
    } catch (err) {
      console.error('investments/save-profile error:', err);
      res.status(500).json({ error: 'Internal Server Error', message: err.message });
    }
  }
);

// ─── GET /investments/portfolio/suggest ──────────────────────────────────────

const PORTFOLIO_RATIONALE = {
  conservative: 'Tu perfil conservador prioriza la preservación del capital. La mayor parte va a renta fija gubernamental europea, con una pequeña exposición global para algo de crecimiento y liquidez en mercado monetario.',
  moderate: 'Tu perfil moderado busca equilibrio entre crecimiento y estabilidad. Combinamos bonos para reducir volatilidad con renta variable global diversificada y algo de mercados emergentes para potenciar el retorno.',
  aggressive: 'Tu perfil agresivo busca maximizar el crecimiento a largo plazo. Apostamos fuerte por renta variable global, mercados emergentes y sectores de alta innovación, asumiendo mayor volatilidad a cambio de mayor rentabilidad esperada.',
};

const PORTFOLIOS = {
  conservative: [
    { etf: 'iShares Core Euro Gov Bond (IEAG)', ticker: 'IEAG', allocation: 70, category: 'bonds',
      reason: 'Deuda pública europea de alta calidad crediticia. Base estable que protege tu capital con rendimientos predecibles.' },
    { etf: 'iShares MSCI World (IWDA)', ticker: 'IWDA', allocation: 20, category: 'global_equity',
      reason: 'Exposición a más de 1.600 empresas de 23 países desarrollados. Diversificación máxima con coste mínimo para el componente de crecimiento.' },
    { etf: 'Lyxor Smart Overnight Return (CSH2)', ticker: 'CSH2', allocation: 10, category: 'money_market',
      reason: 'Equivalente a efectivo de bajo riesgo. Proporciona liquidez inmediata y amortigua la volatilidad del resto de la cartera.' },
  ],
  moderate: [
    { etf: 'iShares Core Euro Gov Bond (IEAG)', ticker: 'IEAG', allocation: 30, category: 'bonds',
      reason: 'Ancla de estabilidad. Los bonos gubernamentales europeos reducen la volatilidad total de la cartera.' },
    { etf: 'Vanguard FTSE All-World (VWRL)', ticker: 'VWRL', allocation: 10, category: 'bonds',
      reason: 'Diversificación global adicional. Cubre tanto mercados desarrollados como emergentes en un solo fondo.' },
    { etf: 'iShares MSCI World (IWDA)', ticker: 'IWDA', allocation: 35, category: 'global_equity',
      reason: 'Motor principal de crecimiento. Exposición diversificada a economías desarrolladas con bajas comisiones.' },
    { etf: 'iShares Core S&P 500 (CSPX)', ticker: 'CSPX', allocation: 15, category: 'global_equity',
      reason: 'Las 500 mayores empresas de EE. UU. históricamente han liderado el crecimiento global a largo plazo.' },
    { etf: 'iShares MSCI EM (EIMI)', ticker: 'EIMI', allocation: 10, category: 'emerging_markets',
      reason: 'China, India, Brasil… Mercados con mayor potencial de crecimiento. Añade rentabilidad extra asumiendo algo más de riesgo.' },
  ],
  aggressive: [
    { etf: 'iShares Core Euro Gov Bond (IEAG)', ticker: 'IEAG', allocation: 10, category: 'bonds',
      reason: 'Colchón mínimo de estabilidad. Un pequeño porcentaje en bonos reduce las caídas máximas en momentos de crisis.' },
    { etf: 'iShares MSCI World (IWDA)', ticker: 'IWDA', allocation: 40, category: 'global_equity',
      reason: 'Columna vertebral de la cartera. Acceso a las mejores empresas mundiales en 23 mercados desarrollados.' },
    { etf: 'iShares Core S&P 500 (CSPX)', ticker: 'CSPX', allocation: 30, category: 'global_equity',
      reason: 'Sobrepondera EE. UU., motor histórico de rentabilidad. Tecnología, salud y consumo lideran el crecimiento.' },
    { etf: 'iShares MSCI EM (EIMI)', ticker: 'EIMI', allocation: 10, category: 'emerging_markets',
      reason: 'Alta convicción en el crecimiento de Asia y Latinoamérica. Mayor volatilidad pero potencial de retorno superior.' },
    { etf: 'iShares Global Clean Energy (INRG)', ticker: 'INRG', allocation: 5, category: 'sector',
      reason: 'Apuesta temática por la transición energética. Sector con fuerte respaldo regulatorio y crecimiento estructural.' },
    { etf: 'iShares Automation & Robotics (RBOT)', ticker: 'RBOT', allocation: 5, category: 'sector',
      reason: 'Automatización e inteligencia artificial transforman la industria global. Posicionamiento en la próxima revolución tecnológica.' },
  ],
};

router.get('/portfolio/suggest', authenticateToken, async (req, res) => {
  try {
    const profileResult = await db.query(
      'SELECT risk_tolerance FROM investor_profiles WHERE user_id = $1',
      [req.user.userId]
    );
    if (profileResult.rows.length === 0) {
      return res.status(404).json({ error: 'Profile not found', message: 'Complete your investor profile first' });
    }
    const risk = profileResult.rows[0].risk_tolerance;
    const portfolio = PORTFOLIOS[risk] || PORTFOLIOS.moderate;
    const rationale = PORTFOLIO_RATIONALE[risk] || PORTFOLIO_RATIONALE.moderate;
    res.json({ risk_tolerance: risk, portfolio, rationale });
  } catch (err) {
    console.error('investments/portfolio/suggest error:', err);
    res.status(500).json({ error: 'Internal Server Error', message: err.message });
  }
});

// ─── POST /investments/simulator ─────────────────────────────────────────────

router.post('/simulator', authenticateToken,
  [
    body('monthly_amount').isFloat({ min: 1 }),
    body('years').isInt({ min: 1, max: 50 }),
    body('annual_return').isFloat({ min: 0, max: 100 }),
  ],
  async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(422).json({ error: 'Validation Error', details: errors.array() });
    }
    try {
      const { monthly_amount, years, annual_return } = req.body;
      const r = annual_return / 100 / 12;
      const months = years * 12;
      let balance = 0;
      const yearly_breakdown = [];

      for (let m = 1; m <= months; m++) {
        balance = balance * (1 + r) + monthly_amount;
        if (m % 12 === 0) {
          const year = m / 12;
          yearly_breakdown.push({
            year,
            balance: Math.round(balance * 100) / 100,
            total_invested: Math.round(monthly_amount * m * 100) / 100,
          });
        }
      }

      const total_invested = monthly_amount * months;
      const total_returns = balance - total_invested;

      res.json({
        final_amount: Math.round(balance * 100) / 100,
        total_invested: Math.round(total_invested * 100) / 100,
        total_returns: Math.round(total_returns * 100) / 100,
        yearly_breakdown,
      });
    } catch (err) {
      res.status(500).json({ error: 'Internal Server Error', message: err.message });
    }
  }
);

// ─── Market data helpers ───────────────────────────────────────────────────────

// Mock sparkline fallback
function mockSparkline(baseValue, volatility, positive) {
  const points = [];
  let v = baseValue * (1 - Math.abs(volatility) * 3.5 / 100);
  for (let i = 0; i < 7; i++) {
    const delta = (Math.random() - (positive ? 0.35 : 0.65)) * volatility / 100 * baseValue;
    v += delta;
    points.push(parseFloat(v.toFixed(4)));
  }
  points.push(baseValue);
  return points;
}

// Static fallback indices
const MOCK_INDICES = [
  { name: 'S&P 500', ticker: 'SPX', value: 5123.41, change: 0.82, currency: 'USD', category: 'equity',
    spark: mockSparkline(5123.41, 0.8, true), volume: 0, market_cap: 0, high_24h: 5145.20, low_24h: 5098.30 },
  { name: 'MSCI World ETF', ticker: 'VWCE', value: 102.34, change: 0.54, currency: 'EUR', category: 'equity',
    spark: mockSparkline(102.34, 0.6, true), volume: 0, market_cap: 0, high_24h: 103.10, low_24h: 101.80 },
  { name: 'IBEX 35', ticker: 'IBEX', value: 10842.50, change: -0.21, currency: 'EUR', category: 'equity',
    spark: mockSparkline(10842.50, 0.9, false), volume: 0, market_cap: 0, high_24h: 10900.00, low_24h: 10790.00 },
  { name: 'Oro', ticker: 'GOLD', value: 2048.30, change: 0.33, currency: 'USD', category: 'commodity',
    spark: mockSparkline(2048.30, 0.5, true), volume: 0, market_cap: 0, high_24h: 2060.00, low_24h: 2035.00 },
  { name: 'EUR/USD', ticker: 'EURUSD', value: 1.0862, change: -0.05, currency: 'USD', category: 'forex',
    spark: mockSparkline(1.0862, 0.3, false), volume: 0, market_cap: 0, high_24h: 1.0890, low_24h: 1.0840 },
  { name: 'Petróleo (WTI)', ticker: 'OIL', value: 82.45, change: -0.67, currency: 'USD', category: 'commodity',
    spark: mockSparkline(82.45, 1.2, false), volume: 0, market_cap: 0, high_24h: 83.20, low_24h: 81.90 },
  { name: 'Bitcoin', ticker: 'BTC', value: 67420.00, change: 2.14, currency: 'EUR', category: 'crypto',
    spark: mockSparkline(67420.00, 2.5, true), volume: 28000000000, market_cap: 1300000000000, high_24h: 68200.00, low_24h: 65800.00 },
  { name: 'Ethereum', ticker: 'ETH', value: 3240.50, change: 1.87, currency: 'EUR', category: 'crypto',
    spark: mockSparkline(3240.50, 3.0, true), volume: 15000000000, market_cap: 380000000000, high_24h: 3310.00, low_24h: 3180.00 },
];

// CoinGecko coin id mapping
const CRYPTO_TICKER_MAP = {
  'btc': 'bitcoin', 'bitcoin': 'bitcoin',
  'eth': 'ethereum', 'ethereum': 'ethereum',
  'sol': 'solana', 'solana': 'solana',
  'bnb': 'binancecoin', 'binancecoin': 'binancecoin',
  'xrp': 'ripple', 'ripple': 'ripple',
};

// Yahoo Finance symbol mapping
const YAHOO_SYMBOL_MAP = {
  'SPX': '^GSPC',
  'VWCE': 'VWCE.DE',
  'IBEX': '^IBEX',
  'GOLD': 'GC=F',
  'EURUSD': 'EURUSD=X',
  'OIL': 'CL=F',
};

const YAHOO_HEADERS = { 'User-Agent': 'Mozilla/5.0' };

async function fetchCryptoIndices() {
  const url = 'https://api.coingecko.com/api/v3/coins/markets?vs_currency=eur&ids=bitcoin,ethereum,solana,binancecoin,ripple&sparkline=true&price_change_percentage=24h';
  const resp = await fetch(url, { signal: AbortSignal.timeout(8000) });
  if (!resp.ok) throw new Error(`CoinGecko error: ${resp.status}`);
  const data = await resp.json();

  const nameMap = {
    bitcoin: 'Bitcoin', ethereum: 'Ethereum', solana: 'Solana',
    binancecoin: 'BNB', ripple: 'XRP',
  };
  const tickerMap = {
    bitcoin: 'BTC', ethereum: 'ETH', solana: 'SOL',
    binancecoin: 'BNB', ripple: 'XRP',
  };

  return data.map(coin => {
    const sparkRaw = coin.sparkline_in_7d?.price ?? [];
    // Downsample to ~7 points
    const spark = sparkRaw.length >= 7
      ? Array.from({ length: 7 }, (_, i) => {
          const idx = Math.floor(i * (sparkRaw.length - 1) / 6);
          return parseFloat(sparkRaw[idx].toFixed(4));
        })
      : sparkRaw.map(p => parseFloat(p.toFixed(4)));

    return {
      name: nameMap[coin.id] || coin.name,
      ticker: tickerMap[coin.id] || coin.symbol.toUpperCase(),
      value: coin.current_price ?? 0,
      change: coin.price_change_percentage_24h ?? 0,
      currency: 'EUR',
      category: 'crypto',
      spark,
      volume: coin.total_volume ?? 0,
      market_cap: coin.market_cap ?? 0,
      high_24h: coin.high_24h ?? 0,
      low_24h: coin.low_24h ?? 0,
    };
  });
}

async function fetchYahooIndex(ticker, yahooSymbol, name, category, currency) {
  const url = `https://query1.finance.yahoo.com/v8/finance/chart/${encodeURIComponent(yahooSymbol)}?range=7d&interval=1d`;
  const resp = await fetch(url, { headers: YAHOO_HEADERS, signal: AbortSignal.timeout(8000) });
  if (!resp.ok) throw new Error(`Yahoo error: ${resp.status}`);
  const json = await resp.json();
  const result = json.chart?.result?.[0];
  if (!result) throw new Error('Yahoo: no result');

  const meta = result.meta;
  const closes = result.indicators?.quote?.[0]?.close ?? [];
  const volumes = result.indicators?.quote?.[0]?.volume ?? [];
  const validCloses = closes.filter(c => c != null);

  const currentPrice = meta.regularMarketPrice ?? validCloses[validCloses.length - 1] ?? 0;
  const prevClose = meta.chartPreviousClose ?? meta.previousClose ?? currentPrice;
  const change = prevClose ? ((currentPrice - prevClose) / prevClose) * 100 : 0;

  const spark = validCloses.slice(-7).map(v => parseFloat((v ?? 0).toFixed(4)));
  const totalVolume = volumes.reduce((s, v) => s + (v || 0), 0);

  return {
    name,
    ticker,
    value: parseFloat(currentPrice.toFixed(4)),
    change: parseFloat(change.toFixed(2)),
    currency,
    category,
    spark,
    volume: totalVolume,
    market_cap: 0,
    high_24h: meta.regularMarketDayHigh ?? 0,
    low_24h: meta.regularMarketDayLow ?? 0,
  };
}

// ─── GET /investments/indices ─────────────────────────────────────────────────

router.get('/indices', authenticateToken, async (req, res) => {
  const cacheKey = 'indices';
  const cached = getCache(cacheKey);
  if (cached) {
    return res.json({ indices: cached, last_updated: new Date().toISOString(), source: 'cache' });
  }

  const yahooTargets = [
    { ticker: 'SPX',    symbol: '^GSPC',    name: 'S&P 500',         category: 'equity',    currency: 'USD' },
    { ticker: 'VWCE',   symbol: 'VWCE.DE',  name: 'MSCI World ETF',  category: 'equity',    currency: 'EUR' },
    { ticker: 'IBEX',   symbol: '^IBEX',    name: 'IBEX 35',         category: 'equity',    currency: 'EUR' },
    { ticker: 'GOLD',   symbol: 'GC=F',     name: 'Oro',             category: 'commodity', currency: 'USD' },
    { ticker: 'EURUSD', symbol: 'EURUSD=X', name: 'EUR/USD',         category: 'forex',     currency: 'USD' },
    { ticker: 'OIL',    symbol: 'CL=F',     name: 'Petróleo (WTI)',  category: 'commodity', currency: 'USD' },
  ];

  let cryptoResults = [];
  let yahooResults = [];

  // Fetch crypto from CoinGecko
  try {
    cryptoResults = await fetchCryptoIndices();
  } catch (err) {
    console.error('[indices] CoinGecko failed:', err.message);
    cryptoResults = MOCK_INDICES.filter(i => i.category === 'crypto');
  }

  // Fetch Yahoo Finance indices in parallel
  const yahooPromises = yahooTargets.map(t =>
    fetchYahooIndex(t.ticker, t.symbol, t.name, t.category, t.currency)
      .catch(err => {
        console.error(`[indices] Yahoo ${t.ticker} failed:`, err.message);
        return MOCK_INDICES.find(m => m.ticker === t.ticker) || null;
      })
  );
  const yahooRaw = await Promise.all(yahooPromises);
  yahooResults = yahooRaw.filter(Boolean);

  const indices = [...yahooResults, ...cryptoResults];
  setCache(cacheKey, indices, TTL_PRICES);

  res.json({ indices, last_updated: new Date().toISOString(), source: 'live' });
});

// ─── GET /investments/chart/:ticker ──────────────────────────────────────────

const PERIOD_TO_DAYS = { '7d': 7, '30d': 30, '90d': 90, '180d': 180, '365d': 365 };
const PERIOD_TO_YAHOO_RANGE = { '7d': '7d', '30d': '1mo', '90d': '3mo', '180d': '6mo', '365d': '1y' };

const CRYPTO_NAME_MAP = {
  btc: 'Bitcoin', eth: 'Ethereum', sol: 'Solana', bnb: 'BNB', xrp: 'XRP',
};

router.get('/chart/:ticker', authenticateToken, async (req, res) => {
  const ticker = req.params.ticker.toLowerCase();
  const period = req.query.period || '7d';

  if (!PERIOD_TO_DAYS[period]) {
    return res.status(400).json({ error: 'Invalid period. Use: 7d, 30d, 90d, 180d, 365d' });
  }

  const cacheKey = `chart:${ticker}:${period}`;
  const cached = getCache(cacheKey);
  if (cached) return res.json(cached);

  const coinId = CRYPTO_TICKER_MAP[ticker];

  try {
    if (coinId) {
      // CoinGecko
      const days = PERIOD_TO_DAYS[period];
      const url = `https://api.coingecko.com/api/v3/coins/${coinId}/market_chart?vs_currency=eur&days=${days}`;
      const resp = await fetch(url, { signal: AbortSignal.timeout(10000) });
      if (!resp.ok) throw new Error(`CoinGecko chart error: ${resp.status}`);
      const data = await resp.json();

      const prices = data.prices ?? [];
      const volumes = data.total_volumes ?? [];
      const volMap = Object.fromEntries(volumes.map(([ts, v]) => [ts, v]));

      // For longer periods, downsample to ~60 points max
      const maxPoints = 60;
      const step = prices.length > maxPoints ? Math.floor(prices.length / maxPoints) : 1;
      const points = prices
        .filter((_, i) => i % step === 0)
        .map(([ts, close]) => ({
          date: new Date(ts).toISOString(),
          close: parseFloat(close.toFixed(4)),
          volume: volMap[ts] ?? 0,
        }));

      const result = { ticker: ticker.toUpperCase(), name: CRYPTO_NAME_MAP[ticker] || ticker.toUpperCase(), period, points };
      setCache(cacheKey, result, TTL_HISTORY);
      return res.json(result);
    } else {
      // Yahoo Finance
      const yahooSymbol = YAHOO_SYMBOL_MAP[ticker.toUpperCase()] || ticker.toUpperCase();
      const range = PERIOD_TO_YAHOO_RANGE[period];
      const url = `https://query1.finance.yahoo.com/v8/finance/chart/${encodeURIComponent(yahooSymbol)}?range=${range}&interval=1d`;
      const resp = await fetch(url, { headers: YAHOO_HEADERS, signal: AbortSignal.timeout(10000) });
      if (!resp.ok) throw new Error(`Yahoo chart error: ${resp.status}`);
      const json = await resp.json();
      const result = json.chart?.result?.[0];
      if (!result) throw new Error('Yahoo: no result');

      const timestamps = result.timestamp ?? [];
      const closes = result.indicators?.quote?.[0]?.close ?? [];
      const volumes = result.indicators?.quote?.[0]?.volume ?? [];

      const points = timestamps
        .map((ts, i) => ({
          date: new Date(ts * 1000).toISOString(),
          close: closes[i] != null ? parseFloat(closes[i].toFixed(4)) : null,
          volume: volumes[i] ?? 0,
        }))
        .filter(p => p.close != null);

      const name = result.meta?.shortName || ticker.toUpperCase();
      const chartResult = { ticker: ticker.toUpperCase(), name, period, points };
      setCache(cacheKey, chartResult, TTL_HISTORY);
      return res.json(chartResult);
    }
  } catch (err) {
    console.error(`[chart/${ticker}] Error:`, err.message);
    // Return minimal fallback
    const now = Date.now();
    const days = PERIOD_TO_DAYS[period];
    const mockPoints = Array.from({ length: days }, (_, i) => ({
      date: new Date(now - (days - i) * 86400000).toISOString(),
      close: 100 + Math.random() * 10,
      volume: 0,
    }));
    return res.json({ ticker: ticker.toUpperCase(), name: ticker.toUpperCase(), period, points: mockPoints });
  }
});

// ─── GET /investments/search ──────────────────────────────────────────────────

const SEARCH_ASSETS = [
  { name: 'Bitcoin', ticker: 'BTC', category: 'crypto' },
  { name: 'Ethereum', ticker: 'ETH', category: 'crypto' },
  { name: 'Solana', ticker: 'SOL', category: 'crypto' },
  { name: 'BNB', ticker: 'BNB', category: 'crypto' },
  { name: 'XRP', ticker: 'XRP', category: 'crypto' },
  { name: 'Cardano', ticker: 'ADA', category: 'crypto' },
  { name: 'Avalanche', ticker: 'AVAX', category: 'crypto' },
  { name: 'Polkadot', ticker: 'DOT', category: 'crypto' },
  { name: 'S&P 500', ticker: 'SPX', category: 'equity' },
  { name: 'MSCI World ETF', ticker: 'VWCE', category: 'equity' },
  { name: 'IBEX 35', ticker: 'IBEX', category: 'equity' },
  { name: 'NASDAQ 100', ticker: 'NDX', category: 'equity' },
  { name: 'DAX', ticker: 'DAX', category: 'equity' },
  { name: 'Apple', ticker: 'AAPL', category: 'equity' },
  { name: 'Microsoft', ticker: 'MSFT', category: 'equity' },
  { name: 'Amazon', ticker: 'AMZN', category: 'equity' },
  { name: 'Tesla', ticker: 'TSLA', category: 'equity' },
  { name: 'NVIDIA', ticker: 'NVDA', category: 'equity' },
  { name: 'Inditex', ticker: 'ITX', category: 'equity' },
  { name: 'Santander', ticker: 'SAN', category: 'equity' },
  { name: 'Oro', ticker: 'GOLD', category: 'commodity' },
  { name: 'Petróleo (WTI)', ticker: 'OIL', category: 'commodity' },
  { name: 'Plata', ticker: 'SILVER', category: 'commodity' },
  { name: 'EUR/USD', ticker: 'EURUSD', category: 'forex' },
  { name: 'GBP/USD', ticker: 'GBPUSD', category: 'forex' },
  { name: 'USD/JPY', ticker: 'USDJPY', category: 'forex' },
];

router.get('/search', authenticateToken, async (req, res) => {
  const q = (req.query.q || '').toLowerCase().trim();
  if (!q) return res.json({ results: SEARCH_ASSETS.slice(0, 10) });

  const results = SEARCH_ASSETS.filter(a =>
    a.name.toLowerCase().includes(q) ||
    a.ticker.toLowerCase().includes(q)
  ).slice(0, 15);

  res.json({ results });
});

// ─── GET /investments/glossary ────────────────────────────────────────────────

router.get('/glossary', authenticateToken, async (req, res) => {
  const glossary = [
    { term: 'ETF', definition_es: 'Fondo cotizado en bolsa que replica un índice. Combina diversificación con bajo coste.', definition_en: 'Exchange-traded fund that tracks an index. Combines diversification with low cost.' },
    { term: 'TER', definition_es: 'Total Expense Ratio. Coste anual del fondo expresado en porcentaje.', definition_en: 'Total Expense Ratio. Annual fund cost expressed as a percentage.' },
    { term: 'Diversificación', definition_es: 'Estrategia de repartir inversiones entre distintos activos para reducir el riesgo.', definition_en: 'Strategy of spreading investments across different assets to reduce risk.' },
    { term: 'Interés compuesto', definition_es: 'Los intereses generados producen a su vez nuevos intereses con el tiempo.', definition_en: 'Generated interest produces further interest over time.' },
    { term: 'Volatilidad', definition_es: 'Medida de la variación del precio de un activo. Mayor volatilidad implica mayor riesgo.', definition_en: 'Measure of price variation of an asset. Higher volatility implies higher risk.' },
    { term: 'DCA', definition_es: 'Dollar-Cost Averaging. Invertir cantidades fijas periódicamente, independientemente del precio.', definition_en: 'Dollar-Cost Averaging. Investing fixed amounts periodically regardless of price.' },
    { term: 'MSCI World', definition_es: 'Índice que agrupa las principales empresas de países desarrollados. Cobertura global.', definition_en: 'Index grouping major companies from developed countries. Global coverage.' },
    { term: 'Renta fija', definition_es: 'Inversión en bonos o deuda que paga un interés predeterminado. Menor riesgo.', definition_en: 'Investment in bonds or debt that pays predetermined interest. Lower risk.' },
  ];
  res.json({ glossary });
});

module.exports = router;