/**
 * Salt Edge API v6 wrapper (RF-10)
 *
 * Reemplaza Yapily con Salt Edge Community — plan gratuito para uso no comercial
 * que usa screen scraping. No requiere eIDAS ni licencia TPP.
 *
 * Registro en https://www.saltedge.com/create_account
 * Documentación: https://docs.saltedge.com/account_information/v6/
 *
 * Mock mode (SALTEDGE_APP_ID no configurado):
 *   Todos los métodos devuelven datos demo.
 *
 * Real mode (credenciales configuradas):
 *   Autenticación: cabeceras App-id + Secret
 *   Flujo de consentimiento:
 *     1. POST /customers → customer_id (una vez por usuario)
 *     2. POST /connect_sessions/create → redirect_url
 *     3. Usuario se autentica en el portal del banco
 *     4. Salt Edge redirige a nuestro callback con ?connection_id={id}
 *     5. GET /accounts?connection_id={id} → cuentas con saldos
 *     6. GET /transactions?account_id={id} → transacciones reales
 *
 * Usa fetch nativo de Node 18+ — sin paquetes npm adicionales.
 */

const SALTEDGE_BASE = 'https://www.saltedge.com/api/v6';

const isMockMode = () => !process.env.SALTEDGE_APP_ID;

// ============================================
// HTTP HELPER
// ============================================

function saltEdgeHeaders() {
  return {
    'App-id': process.env.SALTEDGE_APP_ID,
    'Secret': process.env.SALTEDGE_SECRET,
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };
}

async function saltEdgeFetch(path, options = {}) {
  const res = await fetch(`${SALTEDGE_BASE}${path}`, {
    ...options,
    headers: {
      ...saltEdgeHeaders(),
      ...(options.headers || {}),
    },
  });

  if (!res.ok) {
    const err = await res.text();
    throw new Error(`Salt Edge API error ${res.status}: ${err}`);
  }

  return res.json();
}

// ============================================
// MOCK DATA — top 10 bancos españoles + top 10 europeos
// Cada entrada incluye `country` (ISO 3166-1 alpha-2) para identificar país
// ============================================

const MOCK_INSTITUTIONS = [
  // ── España ───────────────────────────────────────────────────────────────
  { id: 'bbva_es',       name: 'BBVA',            country: 'ES', logo: 'https://placehold.co/48x48/004A9F/ffffff?text=BBVA' },
  { id: 'santander_es',  name: 'Santander',        country: 'ES', logo: 'https://placehold.co/48x48/EC0000/ffffff?text=SAN'  },
  { id: 'caixabank_es',  name: 'CaixaBank',        country: 'ES', logo: 'https://placehold.co/48x48/007F7F/ffffff?text=CAI'  },
  { id: 'sabadell_es',   name: 'Banco Sabadell',   country: 'ES', logo: 'https://placehold.co/48x48/0063B4/ffffff?text=SAB'  },
  { id: 'bankinter_es',  name: 'Bankinter',         country: 'ES', logo: 'https://placehold.co/48x48/F7A400/000000?text=BKT'  },
  { id: 'ing_es',        name: 'ING España',        country: 'ES', logo: 'https://placehold.co/48x48/FF6200/ffffff?text=ING'  },
  { id: 'unicaja_es',    name: 'Unicaja',           country: 'ES', logo: 'https://placehold.co/48x48/005CA9/ffffff?text=UNI'  },
  { id: 'abanca_es',     name: 'Abanca',            country: 'ES', logo: 'https://placehold.co/48x48/00B04E/ffffff?text=ABA'  },
  { id: 'kutxabank_es',  name: 'Kutxabank',         country: 'ES', logo: 'https://placehold.co/48x48/E30613/ffffff?text=KBK'  },
  { id: 'openbank_es',   name: 'Openbank',          country: 'ES', logo: 'https://placehold.co/48x48/CC0000/ffffff?text=OPN'  },

  // ── Europa ────────────────────────────────────────────────────────────────
  { id: 'deutsche_de',   name: 'Deutsche Bank',     country: 'DE', logo: 'https://placehold.co/48x48/0018A8/ffffff?text=DB'   },
  { id: 'n26_de',        name: 'N26',               country: 'DE', logo: 'https://placehold.co/48x48/48AC98/ffffff?text=N26'  },
  { id: 'commerzbank_de',name: 'Commerzbank',        country: 'DE', logo: 'https://placehold.co/48x48/FFCC00/000000?text=CBK'  },
  { id: 'bnp_fr',        name: 'BNP Paribas',       country: 'FR', logo: 'https://placehold.co/48x48/00965E/ffffff?text=BNP'  },
  { id: 'socgen_fr',     name: 'Société Générale',  country: 'FR', logo: 'https://placehold.co/48x48/E2001A/ffffff?text=SG'   },
  { id: 'barclays_gb',   name: 'Barclays',          country: 'GB', logo: 'https://placehold.co/48x48/00AEEF/ffffff?text=BAR'  },
  { id: 'revolut_gb',    name: 'Revolut',           country: 'GB', logo: 'https://placehold.co/48x48/191C1F/ffffff?text=REV'  },
  { id: 'unicredit_it',  name: 'UniCredit',         country: 'IT', logo: 'https://placehold.co/48x48/DC0000/ffffff?text=UCR'  },
  { id: 'ing_nl',        name: 'ING Netherlands',   country: 'NL', logo: 'https://placehold.co/48x48/FF6200/ffffff?text=ING'  },
  { id: 'abnamro_nl',    name: 'ABN AMRO',          country: 'NL', logo: 'https://placehold.co/48x48/009B77/ffffff?text=ABN'  },
];

const MOCK_TRANSACTIONS = [
  { id: 'mock_tx_1', amount: -42.50, description: 'Mercadona', date: '2026-02-18', currency: 'EUR' },
  { id: 'mock_tx_2', amount: -9.99, description: 'Netflix', date: '2026-02-17', currency: 'EUR' },
  { id: 'mock_tx_3', amount: 1500.00, description: 'Nómina febrero', date: '2026-02-14', currency: 'EUR' },
  { id: 'mock_tx_4', amount: -35.00, description: 'Gasolina Repsol', date: '2026-02-13', currency: 'EUR' },
  { id: 'mock_tx_5', amount: -120.00, description: 'Zara', date: '2026-02-10', currency: 'EUR' },
  { id: 'mock_tx_6', amount: -8.50, description: 'Café y desayuno', date: '2026-02-09', currency: 'EUR' },
  { id: 'mock_tx_7', amount: -55.00, description: 'Farmacia', date: '2026-02-07', currency: 'EUR' },
  { id: 'mock_tx_8', amount: -200.00, description: 'Alquiler cuota', date: '2026-02-05', currency: 'EUR' },
  { id: 'mock_tx_9', amount: 250.00, description: 'Freelance cliente', date: '2026-02-03', currency: 'EUR' },
  { id: 'mock_tx_10', amount: -22.80, description: 'Spotify + Amazon Prime', date: '2026-02-01', currency: 'EUR' },
];

// ============================================
// PUBLIC API
// ============================================

/**
 * Listar proveedores (bancos) soportados para un país.
 * @param {string} country Código ISO 3166-1 alpha-2 (por defecto 'ES')
 * @returns {Array<{ id, name, countries, logo }>}
 */
async function listInstitutions(country = null) {
  if (isMockMode()) {
    // Sin filtro → todos los 20 bancos; con filtro → solo los de ese país
    return country
      ? MOCK_INSTITUTIONS.filter(i => i.country === country.toUpperCase())
      : MOCK_INSTITUTIONS;
  }

  // Salt Edge: GET /providers?country_code=ES
  const data = await saltEdgeFetch(`/providers?country_code=${country}&include_fake_providers=false`);
  return (data.data || []).map(p => ({
    id: p.code,
    name: p.name,
    country: p.country_code,
    logo: p.logo_url || null,
  }));
}

/**
 * Obtener o crear un Customer de Salt Edge para un usuario.
 * Salt Edge requiere un Customer por usuario para el consentimiento.
 * Usa el UUID del usuario como identifier único.
 *
 * @param {string} userId UUID del usuario en nuestra BD
 * @returns {string} Salt Edge customer ID
 */
async function getOrCreateCustomer(userId) {
  if (isMockMode()) {
    return `mock_customer_${userId}`;
  }

  // Intentar crear el customer
  try {
    const res = await saltEdgeFetch('/customers', {
      method: 'POST',
      body: JSON.stringify({ data: { identifier: userId } }),
    });
    return res.data.id;
  } catch (err) {
    // Si ya existe (CustomerDuplicated / 422), buscarlo por identifier
    if (err.message.includes('422') || err.message.toLowerCase().includes('duplicate')) {
      const listRes = await saltEdgeFetch(`/customers?identifier=${encodeURIComponent(userId)}`);
      const customers = listRes.data || [];
      if (customers.length > 0) {
        return customers[0].id;
      }
    }
    throw err;
  }
}

/**
 * Crear una sesión de conexión de Salt Edge (inicia el flujo de consentimiento).
 *
 * @param {string} customerId      Salt Edge customer ID
 * @param {string} redirectUrl     URL de callback con ?ref={connectionId}
 * @param {string|null} providerCode  Código del proveedor Salt Edge (opcional)
 * @returns {{ requisitionId: string, authUrl: string }}
 */
async function createRequisition(customerId, redirectUrl, providerCode = null) {
  if (isMockMode()) {
    // En mock mode redirigimos a nuestra propia página mock-auth
    return {
      requisitionId: `mock_req_${Date.now()}`,
      authUrl: redirectUrl,
    };
  }

  // 1 año de historial de transacciones
  const fromDate = new Date();
  fromDate.setFullYear(fromDate.getFullYear() - 1);

  const sessionData = {
    customer_id: customerId,
    consent: {
      scopes: ['account_details', 'transactions_details'],
      from_date: fromDate.toISOString().split('T')[0],
    },
    attempt: {
      return_to: redirectUrl,
    },
  };

  if (providerCode) {
    sessionData.provider_code = providerCode;
  }

  const res = await saltEdgeFetch('/connect_sessions/create', {
    method: 'POST',
    body: JSON.stringify({ data: sessionData }),
  });

  const authUrl = res.data?.redirect_url;
  if (!authUrl) {
    throw new Error('Salt Edge no devolvió un redirect_url');
  }

  return {
    requisitionId: `saltedge_pending_${Date.now()}`,
    authUrl,
  };
}

/**
 * Obtener cuentas bancarias de una conexión Salt Edge.
 * El connection_id llega en el callback como ?connection_id={id}.
 *
 * @param {string} connectionId Salt Edge connection ID
 * @returns {Array<{ externalAccountId, iban, name, currency, balanceCents }>}
 */
async function fetchAccounts(connectionId) {
  if (isMockMode() || !connectionId || connectionId.startsWith('mock_') || connectionId.startsWith('saltedge_pending_')) {
    return [
      {
        externalAccountId: `mock_acc_current_${connectionId}`,
        iban: 'ES91 2100 0418 4502 0005 1332',
        name: 'Cuenta Corriente',
        currency: 'EUR',
        balanceCents: 150050,
      },
      {
        externalAccountId: `mock_acc_savings_${connectionId}`,
        iban: 'ES80 2310 0001 1800 0001 2345',
        name: 'Cuenta Ahorro',
        currency: 'EUR',
        balanceCents: 320000,
      },
    ];
  }

  const data = await saltEdgeFetch(`/accounts?connection_id=${encodeURIComponent(connectionId)}`);
  return (data.data || []).map(acct => ({
    externalAccountId: acct.id,
    iban: acct.extra?.iban || '',
    name: acct.name || acct.nature || 'Cuenta bancaria',
    currency: acct.currency_code || 'EUR',
    balanceCents: Math.round((acct.balance || 0) * 100),
  }));
}

/**
 * Obtener transacciones de una cuenta Salt Edge.
 *
 * @param {string} accountId  Salt Edge account ID (external_account_id en nuestra BD)
 * @param {string} fromDate   Fecha ISO (YYYY-MM-DD) desde la que obtener transacciones
 * @returns {Array<{ id, amount, description, date, currency }>}
 */
async function fetchTransactions(accountId, fromDate) {
  if (isMockMode() || !accountId || accountId.startsWith('mock_acc_')) {
    return MOCK_TRANSACTIONS;
  }

  const params = new URLSearchParams({ account_id: accountId });
  if (fromDate) {
    params.set('from_date', fromDate);
  }

  const data = await saltEdgeFetch(`/transactions?${params.toString()}`);
  return (data.data || []).map(tx => ({
    id: tx.id,
    amount: tx.amount, // puede ser negativo (gastos) o positivo (ingresos)
    description: tx.description || tx.extra?.payee || 'Transacción bancaria',
    date: tx.made_on,
    currency: tx.currency_code || 'EUR',
  }));
}

module.exports = { listInstitutions, getOrCreateCustomer, createRequisition, fetchAccounts, fetchTransactions, isMockMode };
