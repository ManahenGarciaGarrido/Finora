/**
 * Yapily Open Banking API wrapper (RF-10)
 *
 * Replaces GoCardless + Tink with Yapily — covers the top 10 Spanish banks
 * via Berlin Group NextGenPSD2 through a single aggregator.
 *
 * Mock mode (YAPILY_APPLICATION_UUID not set):
 *   All methods return demo data so the feature works without credentials.
 *
 * Real mode (credentials set):
 *   Basic Auth with YAPILY_APPLICATION_UUID:YAPILY_APPLICATION_SECRET
 *   Register free at https://dashboard.yapily.com (100 calls/month on free tier).
 *
 * Consent flow (real mode):
 *   1. POST /account-auth-requests → authorisationUrl
 *   2. User authenticates at bank portal
 *   3. Yapily redirects to callback with ?consent={consentToken}
 *   4. Use consentToken to call /accounts, /accounts/{id}/balances
 *
 * Uses Node 18+ native fetch — no extra npm packages needed.
 */

const YAPILY_BASE = 'https://api.yapily.com';

const isMockMode = () => !process.env.YAPILY_APPLICATION_UUID;

function authHeader() {
  const creds = Buffer.from(
    `${process.env.YAPILY_APPLICATION_UUID}:${process.env.YAPILY_APPLICATION_SECRET}`
  ).toString('base64');
  return `Basic ${creds}`;
}

async function yapilyFetch(path, options = {}) {
  const res = await fetch(`${YAPILY_BASE}${path}`, {
    ...options,
    headers: {
      'Authorization': authHeader(),
      'Accept': 'application/json;charset=UTF-8',
      'Content-Type': 'application/json',
      ...(options.headers || {}),
    },
  });

  if (!res.ok) {
    throw new Error(`Yapily API error ${res.status}: ${await res.text()}`);
  }

  return res.json();
}

const MOCK_INSTITUTIONS = [
  { id: 'MOCK_BBVA_ES', name: 'BBVA', countries: ['ES'], logo: 'https://placehold.co/48x48/004A9F/ffffff?text=BBVA' },
  { id: 'MOCK_SANTANDER_ES', name: 'Santander', countries: ['ES'], logo: 'https://placehold.co/48x48/EC0000/ffffff?text=SAN' },
  { id: 'MOCK_CAIXABANK_ES', name: 'CaixaBank', countries: ['ES'], logo: 'https://placehold.co/48x48/007F7F/ffffff?text=CAI' },
  { id: 'MOCK_SABADELL_ES', name: 'Banco Sabadell', countries: ['ES'], logo: 'https://placehold.co/48x48/0063B4/ffffff?text=SAB' },
  { id: 'MOCK_BANKINTER_ES', name: 'Bankinter', countries: ['ES'], logo: 'https://placehold.co/48x48/F7A400/000000?text=BKT' },
  { id: 'MOCK_ING_ES', name: 'ING España', countries: ['ES'], logo: 'https://placehold.co/48x48/FF6200/ffffff?text=ING' },
  { id: 'MOCK_UNICAJA_ES', name: 'Unicaja', countries: ['ES'], logo: 'https://placehold.co/48x48/005CA9/ffffff?text=UNI' },
  { id: 'MOCK_ABANCA_ES', name: 'Abanca', countries: ['ES'], logo: 'https://placehold.co/48x48/00B04E/ffffff?text=ABA' },
  { id: 'MOCK_KUTXABANK_ES', name: 'Kutxabank', countries: ['ES'], logo: 'https://placehold.co/48x48/E30613/ffffff?text=KBK' },
  { id: 'MOCK_OPENBANK_ES', name: 'Openbank', countries: ['ES'], logo: 'https://placehold.co/48x48/CC0000/ffffff?text=OPN' },
];

async function listInstitutions(country = 'ES') {
  if (isMockMode()) return MOCK_INSTITUTIONS;

  const { data = [] } = await yapilyFetch(`/institutions?filter[countries]=${country}`);
  return data.map(inst => ({
    id: inst.id,
    name: inst.name,
    countries: (inst.countries || []).map(c => c.countryCode || c),
    logo: inst.media?.find(m => m.type === 'icon')?.source || inst.media?.[0]?.source || null,
  }));
}

async function createRequisition(institutionId, redirectUrl) {
  if (isMockMode()) {
    return { requisitionId: `mock_req_${institutionId}_${Date.now()}`, authUrl: redirectUrl };
  }

  const { data } = await yapilyFetch('/account-auth-requests', {
    method: 'POST',
    body: JSON.stringify({
      applicationUserId: `finora_${Date.now()}`,
      institutionId,
      callback: redirectUrl,
    }),
  });

  if (!data?.authorisationUrl) throw new Error('Yapily did not return an authorisationUrl');

  return { requisitionId: `yapily_pending_${Date.now()}`, authUrl: data.authorisationUrl };
}

async function fetchAccounts(consentToken) {
  const isMock = isMockMode() || !consentToken || consentToken.startsWith('mock_req_') || consentToken.startsWith('yapily_pending_');
  
  if (isMock) {
    return [
      { externalAccountId: `mock_acc_current_${consentToken}`, iban: 'ES91 2100 0418 4502 0005 1332', name: 'Cuenta Corriente', currency: 'EUR', balanceCents: 150050 },
      { externalAccountId: `mock_acc_savings_${consentToken}`, iban: 'ES80 2310 0001 1800 0001 2345', name: 'Cuenta Ahorro', currency: 'EUR', balanceCents: 320000 },
    ];
  }

  const { data: accounts = [] } = await yapilyFetch(`/accounts?consent=${encodeURIComponent(consentToken)}`);
  
  return accounts.map(acct => ({
    externalAccountId: acct.id,
    iban: acct.accountIdentifications?.find(id => id.type === 'IBAN')?.identification || '',
    name: acct.accountNames?.[0]?.name || acct.nickname || 'Cuenta bancaria',
    currency: acct.currency || 'EUR',
    balanceCents: Math.round((acct.balance || 0) * 100),
  }));
}

module.exports = { listInstitutions, createRequisition, fetchAccounts, isMockMode };