'use strict';

/**
 * RF-11 — Categorización automática de transacciones bancarias importadas.
 *
 * Cada regla evalúa el texto normalizado de la descripción y, cuando hay
 * coincidencia, devuelve la categoría correspondiente de Finora.
 * Las reglas de ingresos se comprueban antes de las de gastos para evitar
 * falsos positivos (p.ej. "salario" en descripción de gasto).
 */

const RULES = [
  // ── Ingresos ────────────────────────────────────────────────────────────
  {
    type: 'income',
    category: 'Salario',
    keywords: ['nomina', 'salario', 'sueldo', 'payroll', 'salary', 'remuneracion', 'mensualidad empresa'],
  },
  {
    type: 'income',
    category: 'Freelance',
    keywords: ['factura', 'honorarios', 'freelance', 'consulting', 'comision', 'liquidacion', 'prestacion servicios'],
  },

  // ── Gastos ──────────────────────────────────────────────────────────────
  {
    type: 'expense',
    category: 'Alimentación',
    keywords: [
      'supermercado', 'mercadona', 'carrefour', 'lidl', 'aldi', 'dia ', 'eroski',
      'alcampo', 'hipercor', 'consum', 'ahorramas', 'maxi', 'grocery', 'alimentacion',
      'fruteria', 'panaderia', 'carniceria', 'pescaderia', 'verduleria',
    ],
  },
  {
    type: 'expense',
    category: 'Transporte',
    keywords: [
      'gasolina', 'gasolinera', 'repsol', 'bp ', 'cepsa', 'galp', 'combustible',
      'parking', 'parquing', 'autopista', 'peaje', 'taxi', 'uber', 'cabify', 'bolt',
      'renfe', 'metro', 'autobus', 'emt ', 'tmb', 'bus ', 'cercanias', 'ave ', 'tren',
      'bicicleta', 'scooter', 'blablacar', 'aena', 'vueling', 'iberia', 'ryanair',
      'easyjet', 'transporte',
    ],
  },
  {
    type: 'expense',
    category: 'Ocio',
    keywords: [
      'netflix', 'spotify', 'amazon prime', 'disney', 'hbo', 'apple tv', 'youtube premium',
      'twitch', 'steam', 'playstation', 'xbox', 'nintendo',
      'cine', 'cinema', 'teatro', 'museo', 'concierto', 'evento', 'entrada',
      'restaurante', 'bar ', 'cafeteria', 'cafe ', 'heladeria', 'pizzeria',
      'pub ', 'discoteca', 'ocio', 'leisure',
    ],
  },
  {
    type: 'expense',
    category: 'Salud',
    keywords: [
      'farmacia', 'parafarmacia', 'medico', 'hospital', 'clinica', 'dentista',
      'fisioterapia', 'seguro medico', 'sanitas', 'adeslas', 'asisa', 'muface',
      'salud', 'health', 'consulta medica', 'laboratorio', 'analisis',
    ],
  },
  {
    type: 'expense',
    category: 'Vivienda',
    keywords: [
      'alquiler', 'renta mensual', 'hipoteca', 'comunidad propietarios',
      'gas natural', 'iberdrola', 'endesa', 'naturgy', 'r com', 'electricidad',
      'agua ', 'canal de isabel', 'agbar', 'luz ', 'vivienda', 'inmobiliaria',
      'arrendamiento',
    ],
  },
  {
    type: 'expense',
    category: 'Servicios',
    keywords: [
      'vodafone', 'movistar', 'orange', 'masmovil', 'pepephone', 'telefono', 'movil',
      'internet ', 'fibra', 'jazztel', 'yoigo', 'claro', 'seguro', 'mutua',
      'mapfre', 'axa ', 'zurich', 'allianz', 'linea directa', 'berkley',
      'amazon web', 'google workspace', 'microsoft 365', 'dropbox',
      'servicios', 'suscripcion', 'cuota',
    ],
  },
  {
    type: 'expense',
    category: 'Educación',
    keywords: [
      'universidad', 'colegio', 'escuela', 'instituto', 'academia', 'curso',
      'formacion', 'educacion', 'libro', 'libreria', 'udemy', 'coursera',
      'uned ', 'fnac', 'el corte ingles libros', 'master',
    ],
  },
  {
    type: 'expense',
    category: 'Ropa',
    keywords: [
      'zara', 'h&m', 'hm ', 'mango', 'primark', 'pull&bear', 'bershka',
      'stradivarius', 'massimo dutti', 'el corte ingles moda', 'ropa', 'calzado',
      'zapatos', 'sneakers', 'fashion', 'clothing', 'nike', 'adidas', 'puma',
    ],
  },
];

/**
 * Normaliza texto: minúsculas, sin tildes, sin dobles espacios.
 * @param {string} text
 * @returns {string}
 */
function normalize(text) {
  return (text || '')
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/\s+/g, ' ')
    .trim();
}

/**
 * Devuelve la categoría más probable para una transacción bancaria.
 *
 * @param {string} description   Descripción del movimiento bancario
 * @param {'income'|'expense'} txType  Tipo de transacción
 * @returns {string} Nombre de categoría de Finora
 */
function autoCategory(description, txType) {
  const desc = normalize(description);

  for (const rule of RULES) {
    // Filtrar por tipo cuando la regla lo especifica
    if (rule.type && rule.type !== txType) continue;

    if (rule.keywords.some((kw) => desc.includes(normalize(kw)))) {
      return rule.category;
    }
  }

  return txType === 'expense' ? 'Otros' : 'Otros ingresos';
}

module.exports = { autoCategory };
