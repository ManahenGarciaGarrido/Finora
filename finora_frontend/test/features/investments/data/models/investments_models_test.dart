import 'package:flutter_test/flutter_test.dart';
import 'package:finora_frontend/features/investments/data/models/market_index_model.dart';
import 'package:finora_frontend/features/investments/data/models/investor_profile_model.dart';
import 'package:finora_frontend/features/investments/data/models/portfolio_suggestion_model.dart';
import 'package:finora_frontend/features/investments/domain/entities/market_index_entity.dart';
import 'package:finora_frontend/features/investments/domain/entities/investor_profile_entity.dart';
import 'package:finora_frontend/features/investments/domain/entities/portfolio_suggestion_entity.dart';

void main() {
  // ── MarketIndexModel ──────────────────────────────────────────────────────
  group('MarketIndexModel.fromJson', () {
    test('mapea todos los campos correctamente', () {
      final json = <String, dynamic>{
        'name': 'IBEX 35',
        'ticker': 'IBEX',
        'value': 10250.5,
        'change': 1.23,
        'currency': 'EUR',
        'category': 'equity',
        'spark': [100.0, 101.0, 102.5],
        'volume': 500000.0,
        'market_cap': 1000000.0,
        'high_24h': 10300.0,
        'low_24h': 10100.0,
      };

      final model = MarketIndexModel.fromJson(json);

      expect(model.name, 'IBEX 35');
      expect(model.ticker, 'IBEX');
      expect(model.value, 10250.5);
      expect(model.change, 1.23);
      expect(model.currency, 'EUR');
      expect(model.category, 'equity');
      expect(model.spark, [100.0, 101.0, 102.5]);
      expect(model.volume, 500000.0);
      expect(model.marketCap, 1000000.0);
      expect(model.high24h, 10300.0);
      expect(model.low24h, 10100.0);
    });

    test('category usa "equity" por defecto cuando es null', () {
      final model = MarketIndexModel.fromJson(<String, dynamic>{
        'name': 'BTC',
        'ticker': 'BTC',
        'value': 45000.0,
        'change': -2.5,
        'currency': 'USD',
        'category': null,
      });
      expect(model.category, 'equity');
    });

    test('spark vacío cuando es null', () {
      final model = MarketIndexModel.fromJson(<String, dynamic>{
        'name': 'Test',
        'ticker': 'TST',
        'value': 100.0,
        'change': 0.0,
        'currency': 'EUR',
        'spark': null,
      });
      expect(model.spark, isEmpty);
    });

    test('campos opcionales por defecto 0.0 cuando son null', () {
      final model = MarketIndexModel.fromJson(<String, dynamic>{
        'name': 'Test',
        'ticker': 'TST',
        'value': 100.0,
        'change': 0.0,
        'currency': 'EUR',
        'volume': null,
        'market_cap': null,
        'high_24h': null,
        'low_24h': null,
      });
      expect(model.volume, 0.0);
      expect(model.marketCap, 0.0);
      expect(model.high24h, 0.0);
      expect(model.low24h, 0.0);
    });

    test('es instancia de MarketIndexEntity', () {
      final model = MarketIndexModel.fromJson(<String, dynamic>{
        'name': 'X',
        'ticker': 'X',
        'value': 1.0,
        'change': 0.0,
        'currency': 'EUR',
      });
      expect(model, isA<MarketIndexEntity>());
    });
  });

  // ── InvestorProfileModel ──────────────────────────────────────────────────
  group('InvestorProfileModel.fromJson', () {
    test('mapea todos los campos correctamente', () {
      final json = <String, dynamic>{
        'id': 'prof-1',
        'risk_tolerance': 'moderate',
        'investment_horizon': '10_years',
        'monthly_capacity': 200.0,
        'created_at': '2024-01-01T00:00:00.000Z',
        'updated_at': '2024-06-01T00:00:00.000Z',
      };

      final model = InvestorProfileModel.fromJson(json);

      expect(model.id, 'prof-1');
      expect(model.riskTolerance, 'moderate');
      expect(model.investmentHorizon, '10_years');
      expect(model.monthlyCapacity, 200.0);
      expect(model.createdAt, DateTime.parse('2024-01-01T00:00:00.000Z'));
      expect(model.updatedAt, DateTime.parse('2024-06-01T00:00:00.000Z'));
    });

    test('monthlyCapacity es null cuando no está presente', () {
      final model = InvestorProfileModel.fromJson(<String, dynamic>{
        'id': 'prof-2',
        'risk_tolerance': 'conservative',
        'investment_horizon': '5_years',
        'monthly_capacity': null,
        'created_at': '2024-01-01T00:00:00.000Z',
        'updated_at': '2024-01-01T00:00:00.000Z',
      });
      expect(model.monthlyCapacity, isNull);
    });

    test('es instancia de InvestorProfileEntity', () {
      final model = InvestorProfileModel.fromJson(<String, dynamic>{
        'id': 'x',
        'risk_tolerance': 'low',
        'investment_horizon': '1_year',
        'created_at': '2024-01-01T00:00:00.000Z',
        'updated_at': '2024-01-01T00:00:00.000Z',
      });
      expect(model, isA<InvestorProfileEntity>());
    });
  });

  // ── PortfolioSuggestionModel ──────────────────────────────────────────────
  group('PortfolioSuggestionModel.fromJson', () {
    test('mapea riskTolerance, rationale y portfolio correctamente', () {
      final json = <String, dynamic>{
        'risk_tolerance': 'moderate',
        'rationale': 'Cartera balanceada para riesgo moderado',
        'portfolio': [
          {
            'etf': 'iShares Core MSCI World',
            'ticker': 'SWDA',
            'allocation': 60,
            'category': 'global_equity',
            'reason': 'Diversificación global',
          },
          {
            'etf': 'iShares Core € Govt Bond',
            'ticker': 'IEGA',
            'allocation': 40,
            'category': 'bonds',
            'reason': 'Estabilidad',
          },
        ],
      };

      final model = PortfolioSuggestionModel.fromJson(json);

      expect(model.riskTolerance, 'moderate');
      expect(model.rationale, 'Cartera balanceada para riesgo moderado');
      expect(model.portfolio.length, 2);
      expect(model.portfolio.first.ticker, 'SWDA');
      expect(model.portfolio.first.allocation, 60);
      expect(model.portfolio.last.allocation, 40);
    });

    test('rationale usa string vacía cuando es null', () {
      final model = PortfolioSuggestionModel.fromJson(<String, dynamic>{
        'risk_tolerance': 'low',
        'rationale': null,
        'portfolio': [],
      });
      expect(model.rationale, '');
    });

    test('reason en PortfolioAllocationEntity usa string vacía cuando es null', () {
      final model = PortfolioSuggestionModel.fromJson(<String, dynamic>{
        'risk_tolerance': 'high',
        'portfolio': [
          {
            'etf': 'Tesla',
            'ticker': 'TSLA',
            'allocation': 100,
            'category': 'stocks',
            'reason': null,
          }
        ],
      });
      expect(model.portfolio.first.reason, '');
    });

    test('es instancia de PortfolioSuggestionEntity', () {
      final model = PortfolioSuggestionModel.fromJson(<String, dynamic>{
        'risk_tolerance': 'x',
        'portfolio': [],
      });
      expect(model, isA<PortfolioSuggestionEntity>());
    });
  });
}

