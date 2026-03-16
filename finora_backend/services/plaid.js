/**
 * Plaid Sandbox API wrapper (RF-10, RF-11)
 *
 * Registro gratuito en https://dashboard.plaid.com
 * Crear cuenta → My Team → Keys → copiar client_id + sandbox secret.
 * No requiere empresa, licencia ni verificación bancaria.
 *
 * Mock mode (PLAID_CLIENT_ID no configurado):
 *   Todos los métodos devuelven datos demo.
 *
 * Real mode (sandbox):
 *   Flujo:
 *     1. POST /link/token/create → link_token
 *     2. Frontend abre /plaid-link?token=…&ref=… (HTML con Plaid Link JS)
 *     3. Usuario elige banco sandbox y se autentica (user_good / pass_good)
 *     4. onSuccess → public_token enviado a POST /plaid-exchange
 *     5. Backend llama POST /item/public_token/exchange → access_token
 *     6. POST /accounts/get → cuentas con saldos
 *     7. POST /transactions/get → transacciones (date range)
 *
 * Convención de signo Plaid:
 *   amount > 0 → débito (gasto, salida de dinero)
 *   amount < 0 → crédito (ingreso, entrada de dinero)
 *   (opuesto al de Salt Edge)
 *
 * Credenciales de prueba en sandbox:
 *   usuario: user_good   contraseña: pass_good
 *   (válidos para cualquier institución del sandbox de Plaid)
 *
 * RNF-16: Circuit breaker + backoff exponencial + caché
 *   - plaidBreaker protege todas las llamadas a la API de Plaid
 *   - withRetry envuelve plaidPost con hasta 3 reintentos y backoff exponencial
 *   - withCache cachea la lista de instituciones (TTL 1h) con fallback stale
 */

const { withRetry, withCache, plaidBreaker } = require('./circuitBreaker');

// Producción: usar production.plaid.com cuando PLAID_ENV=production
const PLAID_ENV  = process.env.PLAID_ENV || 'sandbox';
const PLAID_BASE = PLAID_ENV === 'production'
  ? 'https://production.plaid.com'
  : 'https://sandbox.plaid.com';

const isMockMode = () => !process.env.PLAID_CLIENT_ID;

// ─── HTTP helper con circuit breaker + retry (RNF-16) ─────────────────────────

/**
 * Realiza un POST a la API de Plaid con:
 *  - Timeout de 30s (RNF-07)
 *  - Circuit breaker (RNF-16)
 *  - Backoff exponencial en caso de error transitorio (RNF-16)
 */
async function plaidPost(path, body = {}) {
  return withRetry(
    () => plaidBreaker.call(async () => {
      // AbortController para timeout de 30s (RNF-07)
      const controller = new AbortController();
      const timer = setTimeout(() => controller.abort(), 30_000);

      try {
        const res = await fetch(`${PLAID_BASE}${path}`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          signal: controller.signal,
          body: JSON.stringify({
            client_id: process.env.PLAID_CLIENT_ID,
            secret: process.env.PLAID_SECRET,
            ...body,
          }),
        });

        if (!res.ok) {
          const text = await res.text();
          throw new Error(`Plaid API error ${res.status}: ${text}`);
        }

        return res.json();
      } finally {
        clearTimeout(timer);
      }
    }),
    { maxAttempts: 3, baseDelayMs: 500, maxDelayMs: 10_000 }
  );
}

// ─── Plaid sandbox institutions ──────────────────────────────────────────────
// Instituciones de prueba oficiales de Plaid sandbox.
// Credenciales para todas: user_good / pass_good
// Ref: https://plaid.com/docs/sandbox/institutions/

const PLAID_SANDBOX_INSTITUTIONS = [
  { id: 'ins_109508', name: 'First Platypus Bank',        country: 'US', logo: 'https://placehold.co/48x48/00B44F/ffffff?text=FPB' },
  { id: 'ins_109509', name: 'First Gingham Credit Union', country: 'US', logo: 'https://placehold.co/48x48/0060AC/ffffff?text=FGC' },
  { id: 'ins_109510', name: 'Tattersall Federal CU',      country: 'US', logo: 'https://placehold.co/48x48/8B4513/ffffff?text=TFC' },
  { id: 'ins_109511', name: 'Tartan Bank',                country: 'US', logo: 'https://placehold.co/48x48/C41E3A/ffffff?text=TB'  },
  { id: 'ins_109512', name: 'Houndstooth Bank',           country: 'US', logo: 'https://placehold.co/48x48/4A4A4A/ffffff?text=HB'  },
];

// ─── Mock data (solo para mock mode sin credenciales) ────────────────────────
// Instituciones decorativas para el selector cuando no hay PLAID_CLIENT_ID

const MOCK_INSTITUTIONS = [
  // España
  { id: 'bbva_es',        name: 'BBVA',             country: 'ES', logo: 'https://placehold.co/48x48/004A9F/ffffff?text=BBVA' },
  { id: 'santander_es',   name: 'Santander',         country: 'ES', logo: 'https://placehold.co/48x48/EC0000/ffffff?text=SAN'  },
  { id: 'caixabank_es',   name: 'CaixaBank',         country: 'ES', logo: 'https://placehold.co/48x48/007F7F/ffffff?text=CAI'  },
  { id: 'sabadell_es',    name: 'Banco Sabadell',    country: 'ES', logo: 'https://placehold.co/48x48/0063B4/ffffff?text=SAB'  },
  { id: 'bankinter_es',   name: 'Bankinter',          country: 'ES', logo: 'https://placehold.co/48x48/F7A400/000000?text=BKT'  },
  { id: 'ing_es',         name: 'ING España',         country: 'ES', logo: 'https://placehold.co/48x48/FF6200/ffffff?text=ING'  },
  { id: 'unicaja_es',     name: 'Unicaja',            country: 'ES', logo: 'https://placehold.co/48x48/005CA9/ffffff?text=UNI'  },
  { id: 'abanca_es',      name: 'Abanca',             country: 'ES', logo: 'https://placehold.co/48x48/00B04E/ffffff?text=ABA'  },
  { id: 'kutxabank_es',   name: 'Kutxabank',          country: 'ES', logo: 'https://placehold.co/48x48/E30613/ffffff?text=KBK'  },
  { id: 'openbank_es',    name: 'Openbank',           country: 'ES', logo: 'https://placehold.co/48x48/CC0000/ffffff?text=OPN'  },
  // Europa
  { id: 'deutsche_de',    name: 'Deutsche Bank',      country: 'DE', logo: 'https://placehold.co/48x48/0018A8/ffffff?text=DB'   },
  { id: 'n26_de',         name: 'N26',                country: 'DE', logo: 'https://placehold.co/48x48/48AC98/ffffff?text=N26'  },
  { id: 'commerzbank_de', name: 'Commerzbank',         country: 'DE', logo: 'https://placehold.co/48x48/FFCC00/000000?text=CBK'  },
  { id: 'bnp_fr',         name: 'BNP Paribas',        country: 'FR', logo: 'https://placehold.co/48x48/00965E/ffffff?text=BNP'  },
  { id: 'socgen_fr',      name: 'Société Générale',   country: 'FR', logo: 'https://placehold.co/48x48/E2001A/ffffff?text=SG'   },
  { id: 'barclays_gb',    name: 'Barclays',            country: 'GB', logo: 'https://placehold.co/48x48/00AEEF/ffffff?text=BAR'  },
  { id: 'revolut_gb',     name: 'Revolut',             country: 'GB', logo: 'https://placehold.co/48x48/191C1F/ffffff?text=REV'  },
  { id: 'unicredit_it',   name: 'UniCredit',           country: 'IT', logo: 'https://placehold.co/48x48/DC0000/ffffff?text=UCR'  },
  { id: 'ing_nl',         name: 'ING Netherlands',    country: 'NL', logo: 'https://placehold.co/48x48/FF6200/ffffff?text=ING'  },
  { id: 'abnamro_nl',     name: 'ABN AMRO',           country: 'NL', logo: 'https://placehold.co/48x48/009B77/ffffff?text=ABN'  },
];

// Plaid sign convention: positive = expense (débito), negative = income (crédito)
const MOCK_TRANSACTIONS = [
  { id: 'mock_tx_1',  amount: 42.50,    description: 'Mercadona',          date: '2026-02-18' },
  { id: 'mock_tx_2',  amount: 9.99,     description: 'Netflix',             date: '2026-02-17' },
  { id: 'mock_tx_3',  amount: -1500.00, description: 'Nómina febrero',     date: '2026-02-14' },
  { id: 'mock_tx_4',  amount: 35.00,    description: 'Gasolina Repsol',    date: '2026-02-13' },
  { id: 'mock_tx_5',  amount: 120.00,   description: 'Zara',               date: '2026-02-10' },
  { id: 'mock_tx_6',  amount: 8.50,     description: 'Café y desayuno',    date: '2026-02-09' },
  { id: 'mock_tx_7',  amount: 55.00,    description: 'Farmacia',            date: '2026-02-07' },
  { id: 'mock_tx_8',  amount: 200.00,   description: 'Alquiler cuota',     date: '2026-02-05' },
  { id: 'mock_tx_9',  amount: -250.00,  description: 'Freelance cliente',  date: '2026-02-03' },
  { id: 'mock_tx_10', amount: 22.80,    description: 'Spotify + Amazon',   date: '2026-02-01' },
];

// ─── Public API ───────────────────────────────────────────────────────────────

/**
 * Lista de instituciones para el selector de la app.
 * - Real mode: devuelve las instituciones sandbox de Plaid (IDs ins_*)
 * - Mock mode: devuelve los bancos decorativos españoles/europeos
 *
 * RNF-07: La lista se cachea 1 hora para evitar peticiones repetidas.
 * RNF-16: Si el servicio falla, se devuelven los datos en caché (stale fallback).
 */
async function listInstitutions(country = null) {
  const cacheKey = `institutions_${country || 'all'}`;

  return withCache(
    cacheKey,
    async () => {
      if (!isMockMode()) {
        return PLAID_SANDBOX_INSTITUTIONS;
      }
      return country
        ? MOCK_INSTITUTIONS.filter(i => i.country === country.toUpperCase())
        : MOCK_INSTITUTIONS;
    },
    60 * 60 * 1000, // TTL: 1 hora (RNF-07: reduce peticiones repetidas)
    { allowStale: true }  // RNF-16: fallback a datos obsoletos si falla
  );
}

/**
 * Crear un link_token de Plaid para iniciar el flujo de consentimiento.
 * @param {string} userId UUID del usuario
 * @returns {string} link_token
 */
async function createLinkToken(userId) {
  if (isMockMode()) {
    return `mock_link_token_${Date.now()}`;
  }

  const res = await plaidPost('/link/token/create', {
    user: { client_user_id: String(userId) },
    client_name: 'Finora',
    products: ['transactions'],
    country_codes: ['US'],
    language: 'en',
  });

  return res.link_token;
}

/**
 * Canjear un public_token por un access_token persistente.
 * @param {string} publicToken Token recibido de Plaid Link onSuccess
 * @returns {{ access_token: string, item_id: string }}
 */
async function exchangePublicToken(publicToken) {
  if (isMockMode() || publicToken.startsWith('mock_')) {
    return {
      access_token: `mock_access_${Date.now()}`,
      item_id: `mock_item_${Date.now()}`,
    };
  }

  const res = await plaidPost('/item/public_token/exchange', {
    public_token: publicToken,
  });

  return { access_token: res.access_token, item_id: res.item_id };
}

/**
 * Obtener cuentas bancarias de un Item de Plaid.
 * @param {string} accessToken
 * @returns {Array<{ externalAccountId, iban, name, currency, balanceCents }>}
 */
async function fetchAccounts(accessToken) {
  if (isMockMode() || !accessToken || accessToken.startsWith('mock_')) {
    return [
      {
        externalAccountId: `mock_acc_current_${accessToken}`,
        iban: 'ES91 2100 0418 4502 0005 1332',
        name: 'Cuenta Corriente',
        currency: 'EUR',
        balanceCents: 150050,
      },
      {
        externalAccountId: `mock_acc_savings_${accessToken}`,
        iban: 'ES80 2310 0001 1800 0001 2345',
        name: 'Cuenta Ahorro',
        currency: 'EUR',
        balanceCents: 320000,
      },
    ];
  }

  const res = await plaidPost('/accounts/get', { access_token: accessToken });

  return (res.accounts || []).map(acct => ({
    externalAccountId: acct.account_id,
    iban: null, // Plaid (US) no proporciona IBAN
    name: acct.official_name || acct.name || 'Bank Account',
    currency: (acct.balances?.iso_currency_code || 'USD').toUpperCase(),
    balanceCents: Math.round((acct.balances?.current || 0) * 100),
  }));
}

/**
 * Obtener transacciones de un Item de Plaid.
 *
 * Nota: Plaid usa la convención opuesta a la de la app:
 *   amount > 0 → débito (gasto)   amount < 0 → crédito (ingreso)
 * La conversión se realiza en banks.js al importar.
 *
 * @param {string} accessToken
 * @param {string|null} fromDate YYYY-MM-DD
 * @returns {Array<{ id, amount, description, date }>}
 */
async function fetchTransactions(accessToken, fromDate) {
  if (isMockMode() || !accessToken || accessToken.startsWith('mock_') || PLAID_ENV !== 'production') {
    // El historial de transacciones ya fue generado por generateRandomTransactions()
    // en el flujo de import-accounts. En sandbox/mock devolvemos [] para evitar
    // que el cron y import-transactions inserten transacciones Plaid falsas que
    // rompen el balance y duplican datos sobre las transacciones generadas por IA.
    return [];
  }

  const endDate = new Date().toISOString().split('T')[0];
  const startDate = fromDate || (() => {
    const d = new Date();
    d.setDate(d.getDate() - 90);
    return d.toISOString().split('T')[0];
  })();

  const res = await plaidPost('/transactions/get', {
    access_token: accessToken,
    start_date: startDate,
    end_date: endDate,
  });

  return (res.transactions || []).map(tx => ({
    id: tx.transaction_id,
    amount: tx.amount, // Plaid: positivo = gasto, negativo = ingreso
    description: tx.name || tx.merchant_name || 'Bank transaction',
    date: tx.date,
    currency: tx.iso_currency_code || 'USD',
  }));
}

/**
 * Crear un public_token de sandbox sin necesidad del SDK de Plaid Link.
 * Evita el flujo de redirección completa que rompe el WebView de Android.
 *
 * @param {string} institutionId  ID de institución de Plaid (ins_*)
 * @returns {string} public_token listo para intercambiar
 */
async function createSandboxPublicToken(institutionId = 'ins_109508') {
  if (isMockMode()) {
    return `mock_public_token_${Date.now()}`;
  }

  // Usar primer institución sandbox si el ID no es de Plaid (e.g. venía de mock)
  const plaidId = institutionId.startsWith('ins_') ? institutionId : 'ins_109508';

  const res = await plaidPost('/sandbox/public_token/create', {
    institution_id: plaidId,
    initial_products: ['transactions'],
  });

  return res.public_token;
}

module.exports = {
  listInstitutions,
  createLinkToken,
  createSandboxPublicToken,
  exchangePublicToken,
  fetchAccounts,
  fetchTransactions,
  isMockMode,
};