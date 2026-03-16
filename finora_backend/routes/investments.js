/**
 * Investment routes
 *
 * Endpoints:
 *   GET    /investments/profile           - get investor profile
 *   POST   /investments/profile           - save profile
 *   GET    /investments/portfolio/suggest - suggest ETF portfolio based on profile
 *   POST   /investments/simulator         - simulate investment returns
 *   GET    /investments/indices           - market indices (static/mock data)
 *   GET    /investments/glossary          - financial glossary terms
 */

const express = require('express');
const router = express.Router();
const db = require('../services/db');
const { authenticateToken } = require('../middleware/auth');
const { body, validationResult } = require('express-validator');

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

const PORTFOLIOS = {
  conservative: [
    { etf: 'iShares Core Euro Gov Bond (IEAG)', ticker: 'IEAG', allocation: 70, category: 'bonds' },
    { etf: 'iShares MSCI World (IWDA)', ticker: 'IWDA', allocation: 20, category: 'global_equity' },
    { etf: 'Lyxor Smart Overnight Return (CSH2)', ticker: 'CSH2', allocation: 10, category: 'money_market' },
  ],
  moderate: [
    { etf: 'iShares Core Euro Gov Bond (IEAG)', ticker: 'IEAG', allocation: 30, category: 'bonds' },
    { etf: 'Vanguard FTSE All-World (VWRL)', ticker: 'VWRL', allocation: 10, category: 'bonds' },
    { etf: 'iShares MSCI World (IWDA)', ticker: 'IWDA', allocation: 35, category: 'global_equity' },
    { etf: 'iShares Core S&P 500 (CSPX)', ticker: 'CSPX', allocation: 15, category: 'global_equity' },
    { etf: 'iShares MSCI EM (EIMI)', ticker: 'EIMI', allocation: 10, category: 'emerging_markets' },
  ],
  aggressive: [
    { etf: 'iShares Core Euro Gov Bond (IEAG)', ticker: 'IEAG', allocation: 10, category: 'bonds' },
    { etf: 'iShares MSCI World (IWDA)', ticker: 'IWDA', allocation: 40, category: 'global_equity' },
    { etf: 'iShares Core S&P 500 (CSPX)', ticker: 'CSPX', allocation: 30, category: 'global_equity' },
    { etf: 'iShares MSCI EM (EIMI)', ticker: 'EIMI', allocation: 10, category: 'emerging_markets' },
    { etf: 'iShares Global Clean Energy (INRG)', ticker: 'INRG', allocation: 5, category: 'sector' },
    { etf: 'iShares Automation & Robotics (RBOT)', ticker: 'RBOT', allocation: 5, category: 'sector' },
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
    res.json({ risk_tolerance: risk, portfolio });
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

// ─── GET /investments/indices ─────────────────────────────────────────────────
// NOTE: In production this would fetch live data from Alpha Vantage or Yahoo Finance API.
// These are static/mock values with realistic data for demonstration.

router.get('/indices', authenticateToken, async (req, res) => {
  const indices = [
    { name: 'S&P 500', ticker: 'SPX', value: 5123.41, change: 0.82, currency: 'USD' },
    { name: 'MSCI World', ticker: 'IWDA', value: 102.34, change: 0.54, currency: 'USD' },
    { name: 'IBEX 35', ticker: 'IBEX', value: 10842.50, change: -0.21, currency: 'EUR' },
    { name: 'Gold', ticker: 'GOLD', value: 2048.30, change: 0.33, currency: 'USD' },
    { name: 'EUR/USD', ticker: 'EURUSD', value: 1.0862, change: -0.05, currency: 'USD' },
    { name: 'Bitcoin', ticker: 'BTC', value: 67420.00, change: 2.14, currency: 'USD' },
  ];
  res.json({ indices, last_updated: new Date().toISOString() });
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