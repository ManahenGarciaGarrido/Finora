'use strict';

/**
 * RF-11 / RF-14 — Categorización automática de transacciones bancarias.
 *
 * Motor de categorización basado en NLP con:
 * - Reglas por palabras clave (ingresos primero para evitar falsos positivos)
 * - Cálculo de nivel de confianza (0–100%)
 * - Fallback a "Otros" si confianza < 50% (RF-14)
 * - Exporta también autoCategorySimple() para compatibilidad
 */

const RULES = [
  // Ingresos
  {
    type: 'income',
    category: 'Salario',
    weight: 1.0,
    keywords: ['nomina', 'salario', 'sueldo', 'payroll', 'salary', 'remuneracion', 'mensualidad empresa'],
  },
  {
    type: 'income',
    category: 'Freelance',
    weight: 0.9,
    keywords: ['factura', 'honorarios', 'freelance', 'consulting', 'comision', 'liquidacion', 'prestacion servicios'],
  },
  // Gastos
  {
    type: 'expense',
    category: 'Alimentación',
    weight: 1.0,
    keywords: [
      'supermercado', 'mercadona', 'carrefour', 'lidl', 'aldi', 'dia ', 'eroski',
      'alcampo', 'hipercor', 'consum', 'ahorramas', 'maxi', 'grocery', 'alimentacion',
      'fruteria', 'panaderia', 'carniceria', 'pescaderia', 'verduleria',
    ],
  },
  {
    type: 'expense',
    category: 'Transporte',
    weight: 0.95,
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
    weight: 0.9,
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
    weight: 0.95,
    keywords: [
      'farmacia', 'parafarmacia', 'medico', 'hospital', 'clinica', 'dentista',
      'fisioterapia', 'seguro medico', 'sanitas', 'adeslas', 'asisa', 'muface',
      'salud', 'health', 'consulta medica', 'laboratorio', 'analisis',
    ],
  },
  {
    type: 'expense',
    category: 'Vivienda',
    weight: 0.95,
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
    weight: 0.85,
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
    weight: 0.9,
    keywords: [
      'universidad', 'colegio', 'escuela', 'instituto', 'academia', 'curso',
      'formacion', 'educacion', 'libro', 'libreria', 'udemy', 'coursera',
      'uned ', 'fnac', 'el corte ingles libros', 'master',
    ],
  },
  {
    type: 'expense',
    category: 'Ropa',
    weight: 0.9,
    keywords: [
      'zara', 'h&m', 'hm ', 'mango', 'primark', 'pull&bear', 'bershka',
      'stradivarius', 'massimo dutti', 'el corte ingles moda', 'ropa', 'calzado',
      'zapatos', 'sneakers', 'fashion', 'clothing', 'nike', 'adidas', 'puma',
    ],
  },
];

function normalize(text) {
  return (text || '')
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/\s+/g, ' ')
    .trim();
}

function calculateConfidence(desc, rule, matchedKw) {
  const normalizedKw = normalize(matchedKw);
  let confidence = rule.weight * 80;

  if (desc === normalizedKw) {
    confidence = rule.weight * 100;
  } else if (desc.startsWith(normalizedKw) || desc.endsWith(normalizedKw)) {
    confidence = rule.weight * 92;
  } else if (normalizedKw.length >= 5) {
    confidence = rule.weight * 85;
  }

  const matchCount = rule.keywords.filter(kw => desc.includes(normalize(kw))).length;
  if (matchCount > 1) {
    confidence = Math.min(100, confidence + matchCount * 3);
  }

  return Math.round(Math.min(100, Math.max(0, confidence)));
}

/**
 * RF-14: Devuelve categoría + nivel de confianza para una descripción.
 *
 * @param {string} description
 * @param {'income'|'expense'} txType
 * @returns {{ category: string, confidence: number, isFallback: boolean }}
 */
function autoCategory(description, txType) {
  const desc = normalize(description);
  let bestCategory = null;
  let bestConfidence = 0;

  for (const rule of RULES) {
    if (rule.type && rule.type !== txType) continue;
    for (const kw of rule.keywords) {
      if (desc.includes(normalize(kw))) {
        const confidence = calculateConfidence(desc, rule, kw);
        if (confidence > bestConfidence) {
          bestConfidence = confidence;
          bestCategory = rule.category;
        }
      }
    }
  }

  // RF-14: Fallback a "Otros" si confianza < 50%
  const CONFIDENCE_THRESHOLD = 50;
  const isFallback = bestConfidence < CONFIDENCE_THRESHOLD || bestCategory === null;

  if (isFallback) {
    return {
      category: txType === 'expense' ? 'Otros' : 'Otros ingresos',
      confidence: bestCategory !== null ? bestConfidence : 0,
      isFallback: true,
    };
  }

  return { category: bestCategory, confidence: bestConfidence, isFallback: false };
}

/** Compatibilidad con código antiguo — sólo devuelve el nombre de categoría */
function autoCategorySimple(description, txType) {
  return autoCategory(description, txType).category;
}

module.exports = { autoCategory, autoCategorySimple };