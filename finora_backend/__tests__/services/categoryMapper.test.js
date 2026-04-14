'use strict';

const { autoCategory, autoCategorySimple } = require('../../services/categoryMapper');

describe('categoryMapper — autoCategory(description, type)', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  // ── Alimentación ──────────────────────────────────────────────────────────
  describe('Alimentación', () => {
    it('maps "MERCADONA compra semana" to Alimentación (expense)', () => {
      const result = autoCategory('MERCADONA compra semana', 'expense');
      expect(result.category).toBe('Alimentación');
      expect(result.confidence).toBeGreaterThan(50);
      expect(result.isFallback).toBe(false);
    });

    it('maps "supermercado carrefour" to Alimentación', () => {
      const result = autoCategory('supermercado carrefour', 'expense');
      expect(result.category).toBe('Alimentación');
    });

    it('maps "LIDL S.A." to Alimentación (case insensitive)', () => {
      const result = autoCategory('LIDL S.A.', 'expense');
      expect(result.category).toBe('Alimentación');
    });

    it('maps "Fruteria local" to Alimentación', () => {
      const result = autoCategory('Fruteria local', 'expense');
      expect(result.category).toBe('Alimentación');
    });
  });

  // ── Transporte ────────────────────────────────────────────────────────────
  describe('Transporte', () => {
    it('maps "REPSOL gasolinera autopista" to Transporte', () => {
      const result = autoCategory('REPSOL gasolinera autopista', 'expense');
      expect(result.category).toBe('Transporte');
      expect(result.isFallback).toBe(false);
    });

    it('maps "BP GASOLINERA Madrid" to Transporte', () => {
      const result = autoCategory('BP GASOLINERA Madrid', 'expense');
      expect(result.category).toBe('Transporte');
    });

    it('maps "UBER viaje" to Transporte', () => {
      const result = autoCategory('UBER viaje', 'expense');
      expect(result.category).toBe('Transporte');
    });

    it('maps "RENFE billete AVE" to Transporte', () => {
      const result = autoCategory('RENFE billete AVE', 'expense');
      expect(result.category).toBe('Transporte');
    });

    it('maps "RYANAIR vuelo Malaga" to Transporte', () => {
      const result = autoCategory('RYANAIR vuelo Malaga', 'expense');
      expect(result.category).toBe('Transporte');
    });
  });

  // ── Ocio ──────────────────────────────────────────────────────────────────
  describe('Ocio', () => {
    it('maps "NETFLIX subscription" to Ocio', () => {
      const result = autoCategory('NETFLIX subscription', 'expense');
      expect(result.category).toBe('Ocio');
      expect(result.isFallback).toBe(false);
    });

    it('maps "SPOTIFY premium" to Ocio', () => {
      const result = autoCategory('SPOTIFY premium', 'expense');
      expect(result.category).toBe('Ocio');
    });

    it('maps "AMAZON PRIME suscripcion" to Ocio', () => {
      const result = autoCategory('AMAZON PRIME suscripcion', 'expense');
      expect(result.category).toBe('Ocio');
    });

    it('maps "cine entrada pelicula" to Ocio', () => {
      const result = autoCategory('cine entrada pelicula', 'expense');
      expect(result.category).toBe('Ocio');
    });
  });

  // ── Salario / Ingresos ────────────────────────────────────────────────────
  describe('Salario (income)', () => {
    it('maps "NOMINA EMPRESA ABC" to Salario when type=income', () => {
      const result = autoCategory('NOMINA EMPRESA ABC', 'income');
      expect(result.category).toBe('Salario');
      expect(result.isFallback).toBe(false);
    });

    it('maps "SALARIO MENSUAL" to Salario when type=income', () => {
      const result = autoCategory('SALARIO MENSUAL', 'income');
      expect(result.category).toBe('Salario');
    });

    it('maps "PAYROLL March 2026" to Salario when type=income', () => {
      const result = autoCategory('PAYROLL March 2026', 'income');
      expect(result.category).toBe('Salario');
    });

    it('does NOT match Salario when type=expense (income rule excluded)', () => {
      const result = autoCategory('NOMINA EMPRESA', 'expense');
      // Should NOT be Salario because income-only rule is excluded
      expect(result.category).not.toBe('Salario');
    });
  });

  // ── Salud ─────────────────────────────────────────────────────────────────
  describe('Salud', () => {
    it('maps "FARMACIA Sanitas" to Salud', () => {
      const result = autoCategory('FARMACIA Sanitas', 'expense');
      expect(result.category).toBe('Salud');
    });

    it('maps "CLINICA DENTAL consulta" to Salud', () => {
      const result = autoCategory('CLINICA DENTAL consulta', 'expense');
      expect(result.category).toBe('Salud');
    });
  });

  // ── Vivienda ──────────────────────────────────────────────────────────────
  describe('Vivienda', () => {
    it('maps "IBERDROLA electricidad factura" to Vivienda', () => {
      const result = autoCategory('IBERDROLA electricidad factura', 'expense');
      expect(result.category).toBe('Vivienda');
    });

    it('maps "ALQUILER PISO ENERO" to Vivienda', () => {
      const result = autoCategory('ALQUILER PISO ENERO', 'expense');
      expect(result.category).toBe('Vivienda');
    });
  });

  // ── Servicios ─────────────────────────────────────────────────────────────
  describe('Servicios', () => {
    it('maps "VODAFONE factura movil" to Servicios', () => {
      const result = autoCategory('VODAFONE factura movil', 'expense');
      expect(result.category).toBe('Servicios');
    });

    it('maps "MOVISTAR fibra internet" to Servicios', () => {
      const result = autoCategory('MOVISTAR fibra internet', 'expense');
      expect(result.category).toBe('Servicios');
    });
  });

  // ── Ropa ──────────────────────────────────────────────────────────────────
  describe('Ropa', () => {
    it('maps "ZARA ropa nueva" to Ropa', () => {
      const result = autoCategory('ZARA ropa nueva', 'expense');
      expect(result.category).toBe('Ropa');
    });

    it('maps "PRIMARK compra ropa" to Ropa', () => {
      const result = autoCategory('PRIMARK compra ropa', 'expense');
      expect(result.category).toBe('Ropa');
    });
  });

  // ── Fallback ──────────────────────────────────────────────────────────────
  describe('Fallback to Otros', () => {
    it('returns "Otros" for unknown expense description', () => {
      const result = autoCategory('XYZ CORP 12345 UNKNOWN', 'expense');
      expect(result.category).toBe('Otros');
      expect(result.isFallback).toBe(true);
    });

    it('returns "Otros ingresos" for unknown income description', () => {
      const result = autoCategory('RANDOM TRANSFER 99999', 'income');
      expect(result.category).toBe('Otros ingresos');
      expect(result.isFallback).toBe(true);
    });

    it('returns confidence=0 when no keywords match at all', () => {
      const result = autoCategory('', 'expense');
      expect(result.confidence).toBe(0);
      expect(result.isFallback).toBe(true);
    });
  });

  // ── Case insensitivity ─────────────────────────────────────────────────────
  describe('Case insensitivity', () => {
    it('matches lowercase "mercadona"', () => {
      const result = autoCategory('mercadona', 'expense');
      expect(result.category).toBe('Alimentación');
    });

    it('matches mixed case "MeRcAdOnA"', () => {
      const result = autoCategory('MeRcAdOnA', 'expense');
      expect(result.category).toBe('Alimentación');
    });

    it('matches accented characters normalized "farmácia"', () => {
      const result = autoCategory('farmácia local', 'expense');
      expect(result.category).toBe('Salud');
    });
  });

  // ── autoCategorySimple ────────────────────────────────────────────────────
  describe('autoCategorySimple compatibility wrapper', () => {
    it('returns only the category string', () => {
      const category = autoCategorySimple('MERCADONA', 'expense');
      expect(typeof category).toBe('string');
      expect(category).toBe('Alimentación');
    });

    it('returns "Otros" for unknown input', () => {
      const category = autoCategorySimple('UNKNOWN STORE 9999', 'expense');
      expect(category).toBe('Otros');
    });
  });

  // ── Confidence range ──────────────────────────────────────────────────────
  describe('Confidence value constraints', () => {
    it('confidence is between 0 and 100 for known categories', () => {
      const { confidence } = autoCategory('MERCADONA supermercado', 'expense');
      expect(confidence).toBeGreaterThanOrEqual(0);
      expect(confidence).toBeLessThanOrEqual(100);
    });
  });
});
