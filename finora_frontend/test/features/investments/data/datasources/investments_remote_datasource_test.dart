import 'package:dio/dio.dart';
import 'package:finora_frontend/core/database/local_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:finora_frontend/core/network/api_client.dart';
import 'package:finora_frontend/features/investments/data/datasources/investments_remote_datasource.dart';
import 'package:finora_frontend/features/investments/data/models/investor_profile_model.dart';
import 'package:finora_frontend/features/investments/data/models/portfolio_suggestion_model.dart';
import 'package:finora_frontend/features/investments/data/models/market_index_model.dart';

import 'investments_remote_datasource_test.mocks.dart';

@GenerateMocks([ApiClient, LocalDatabase])
void main() {
  late MockApiClient mockClient;
  late InvestmentsRemoteDataSourceImpl dataSource;

  setUp(() {
    mockClient = MockApiClient();
    dataSource = InvestmentsRemoteDataSourceImpl(mockClient);
  });

  // ── getProfile ────────────────────────────────────────────────────────────
  group('getProfile', () {
    test('retorna InvestorProfileModel cuando existe', () async {
      when(mockClient.get('/investments/profile')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 200,
          data: <String, dynamic>{
            'profile': {
              'id': 'prof-1',
              'risk_tolerance': 'moderate',
              'investment_horizon': '10_years',
              'created_at': '2024-01-01T00:00:00.000Z',
              'updated_at': '2024-06-01T00:00:00.000Z',
            },
          },
        ),
      );

      final result = await dataSource.getProfile();

      expect(result, isA<InvestorProfileModel>());
      expect(result!.riskTolerance, 'moderate');
    });

    test('retorna null cuando profile es null', () async {
      when(mockClient.get('/investments/profile')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 200,
          data: <String, dynamic>{'profile': null},
        ),
      );

      final result = await dataSource.getProfile();
      expect(result, isNull);
    });
  });

  // ── saveProfile ───────────────────────────────────────────────────────────
  group('saveProfile', () {
    test('retorna InvestorProfileModel guardado', () async {
      final data = <String, dynamic>{
        'risk_tolerance': 'aggressive',
        'investment_horizon': '20_years',
      };
      when(
        mockClient.post('/investments/profile', data: anyNamed('data')),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 200,
          data: <String, dynamic>{
            'profile': {
              'id': 'prof-2',
              'risk_tolerance': 'aggressive',
              'investment_horizon': '20_years',
              'created_at': '2024-06-01T00:00:00.000Z',
              'updated_at': '2024-06-01T00:00:00.000Z',
            },
          },
        ),
      );

      final result = await dataSource.saveProfile(data);

      expect(result.riskTolerance, 'aggressive');
      verify(mockClient.post('/investments/profile', data: data)).called(1);
    });
  });

  // ── getPortfolioSuggestion ────────────────────────────────────────────────
  group('getPortfolioSuggestion', () {
    test('retorna PortfolioSuggestionModel', () async {
      when(mockClient.get('/investments/portfolio/suggest')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 200,
          data: <String, dynamic>{
            'risk_tolerance': 'moderate',
            'rationale': 'Cartera equilibrada',
            'portfolio': [
              {
                'etf': 'SWDA',
                'ticker': 'SWDA',
                'allocation': 60,
                'category': 'equity',
                'reason': 'Diversificación',
              },
            ],
          },
        ),
      );

      final result = await dataSource.getPortfolioSuggestion();

      expect(result, isA<PortfolioSuggestionModel>());
      expect(result.portfolio.first.ticker, 'SWDA');
    });
  });

  // ── simulateReturns ───────────────────────────────────────────────────────
  group('simulateReturns', () {
    test('retorna mapa con resultados de simulación', () async {
      final input = <String, dynamic>{'initial_amount': 10000, 'monthly': 200, 'years': 10};
      when(
        mockClient.post('/investments/simulator', data: anyNamed('data')),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 200,
          data: <String, dynamic>{
            'final_value': 45000.0,
            'total_invested': 34000.0,
            'returns': 11000.0,
          },
        ),
      );

      final result = await dataSource.simulateReturns(input);

      expect(result['final_value'], 45000.0);
      verify(mockClient.post('/investments/simulator', data: input)).called(1);
    });
  });

  // ── getIndices ────────────────────────────────────────────────────────────
  group('getIndices', () {
    test('retorna lista de MarketIndexModel', () async {
      when(mockClient.get('/investments/indices')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 200,
          data: <String, dynamic>{
            'indices': [
              {
                'name': 'IBEX 35',
                'ticker': 'IBEX',
                'value': 10250.0,
                'change': 1.2,
                'currency': 'EUR',
              },
            ],
          },
        ),
      );

      final result = await dataSource.getIndices();

      expect(result, isA<List<MarketIndexModel>>());
      expect(result.first.name, 'IBEX 35');
    });
  });

  // ── getGlossary ───────────────────────────────────────────────────────────
  group('getGlossary', () {
    test('retorna lista de mapas con términos', () async {
      when(mockClient.get('/investments/glossary')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 200,
          data: <String, dynamic>{
            'glossary': [
              {'term': 'ETF', 'definition': 'Exchange-Traded Fund'},
            ],
          },
        ),
      );

      final result = await dataSource.getGlossary();

      expect(result, isA<List<Map<String, dynamic>>>());
      expect(result.first['term'], 'ETF');
    });
  });

  // ── getChart ──────────────────────────────────────────────────────────────
  group('getChart', () {
    test('retorna mapa con datos del gráfico', () async {
      when(mockClient.get('/investments/chart/SWDA?period=1y')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 200,
          data: <String, dynamic>{
            'ticker': 'SWDA',
            'period': '1y',
            'points': [100.0, 102.0, 105.0],
          },
        ),
      );

      final result = await dataSource.getChart('SWDA', '1y');

      expect(result['ticker'], 'SWDA');
      verify(mockClient.get('/investments/chart/SWDA?period=1y')).called(1);
    });
  });
}

