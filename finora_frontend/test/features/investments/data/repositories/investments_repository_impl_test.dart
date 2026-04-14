import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:finora_frontend/features/investments/data/datasources/investments_remote_datasource.dart';
import 'package:finora_frontend/features/investments/data/models/investor_profile_model.dart';
import 'package:finora_frontend/features/investments/data/models/portfolio_suggestion_model.dart';
import 'package:finora_frontend/features/investments/data/models/market_index_model.dart';
import 'package:finora_frontend/features/investments/data/repositories/investments_repository_impl.dart';
import 'package:finora_frontend/features/investments/domain/entities/investor_profile_entity.dart';
import 'package:finora_frontend/features/investments/domain/entities/portfolio_suggestion_entity.dart';
import 'package:finora_frontend/features/investments/domain/entities/market_index_entity.dart';

// Importamos los mocks generados
import 'investments_repository_impl_test.mocks.dart';

@GenerateMocks([InvestmentsRemoteDataSource])
void main() {
  late MockInvestmentsRemoteDataSource mockDs;
  late InvestmentsRepositoryImpl repository;

  final tProfile = InvestorProfileModel.fromJson(<String, dynamic>{
    'id': 'prof-1',
    'risk_tolerance': 'moderate',
    'investment_horizon': '10_years',
    'created_at': '2024-01-01T00:00:00.000Z',
    'updated_at': '2024-06-01T00:00:00.000Z',
  });

  final tSuggestion = PortfolioSuggestionModel.fromJson(<String, dynamic>{
    'risk_tolerance': 'moderate',
    'rationale': 'Balanced',
    'portfolio': [
      <String, dynamic>{
        'etf': 'SWDA',
        'ticker': 'SWDA',
        'allocation': 60,
        'category': 'equity',
        'reason': 'Global exposure',
      },
    ],
  });

  final tIndex = MarketIndexModel.fromJson(<String, dynamic>{
    'name': 'IBEX 35',
    'ticker': 'IBEX',
    'value': 10250.0,
    'change': 1.2,
    'currency': 'EUR',
  });

  setUp(() {
    mockDs = MockInvestmentsRemoteDataSource();
    repository = InvestmentsRepositoryImpl(mockDs);
  });

  // ── getProfile ────────────────────────────────────────────────────────────
  group('getProfile', () {
    test('retorna InvestorProfileEntity cuando existe', () async {
      when(mockDs.getProfile()).thenAnswer((_) async => tProfile);

      final result = await repository.getProfile();

      expect(result, isA<InvestorProfileEntity>());
      expect(result!.riskTolerance, 'moderate');
      verify(mockDs.getProfile()).called(1);
    });

    test('retorna null cuando no hay perfil', () async {
      when(mockDs.getProfile()).thenAnswer((_) async => null);

      final result = await repository.getProfile();
      expect(result, isNull);
    });
  });

  // ── saveProfile ───────────────────────────────────────────────────────────
  group('saveProfile', () {
    test('retorna InvestorProfileEntity guardado', () async {
      final requestData = <String, dynamic>{
        'risk_tolerance': 'moderate',
        'investment_horizon': '10_years',
      };

      when(mockDs.saveProfile(requestData)).thenAnswer((_) async => tProfile);

      final result = await repository.saveProfile(requestData);

      expect(result, isA<InvestorProfileEntity>());
      verify(mockDs.saveProfile(requestData)).called(1);
    });
  });

  // ── getPortfolioSuggestion ────────────────────────────────────────────────
  group('getPortfolioSuggestion', () {
    test('retorna PortfolioSuggestionEntity', () async {
      when(
        mockDs.getPortfolioSuggestion(),
      ).thenAnswer((_) async => tSuggestion);

      final result = await repository.getPortfolioSuggestion();

      expect(result, isA<PortfolioSuggestionEntity>());
      expect(result.portfolio.first.ticker, 'SWDA');
    });
  });

  // ── simulateReturns ───────────────────────────────────────────────────────
  group('simulateReturns', () {
    test('retorna mapa de resultados', () async {
      final tResult = <String, dynamic>{
        'final_value': 45000.0,
        'total_invested': 34000.0,
      };
      final requestData = <String, dynamic>{
        'initial_amount': 10000,
        'years': 10,
      };

      when(
        mockDs.simulateReturns(requestData),
      ).thenAnswer((_) async => tResult);

      final result = await repository.simulateReturns(requestData);

      expect(result['final_value'], 45000.0);
    });
  });

  // ── getIndices ────────────────────────────────────────────────────────────
  group('getIndices', () {
    test('retorna lista de MarketIndexEntity', () async {
      when(mockDs.getIndices()).thenAnswer((_) async => [tIndex]);

      final result = await repository.getIndices();

      expect(result, isA<List<MarketIndexEntity>>());
      expect(result.first.name, 'IBEX 35');
    });
  });

  // ── getGlossary ───────────────────────────────────────────────────────────
  group('getGlossary', () {
    test('retorna lista de mapas con términos', () async {
      final tGlossary = [
        <String, String>{'term': 'ETF', 'definition': 'Exchange-Traded Fund'},
      ];
      when(mockDs.getGlossary()).thenAnswer((_) async => tGlossary);

      final result = await repository.getGlossary();

      expect(result.first['term'], 'ETF');
    });
  });

  // ── getChart ──────────────────────────────────────────────────────────────
  group('getChart', () {
    test('delega con ticker y period correctos', () async {
      final tChart = <String, dynamic>{
        'ticker': 'SWDA',
        'points': [100.0, 105.0],
      };
      when(mockDs.getChart('SWDA', '1y')).thenAnswer((_) async => tChart);

      final result = await repository.getChart('SWDA', '1y');

      expect(result['ticker'], 'SWDA');
      verify(mockDs.getChart('SWDA', '1y')).called(1);
    });
  });
}
