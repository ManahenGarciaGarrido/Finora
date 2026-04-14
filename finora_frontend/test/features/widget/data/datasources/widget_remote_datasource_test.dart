import 'package:dio/dio.dart';
import 'package:finora_frontend/core/database/local_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:finora_frontend/core/network/api_client.dart';
import 'package:finora_frontend/features/widget/data/datasources/widget_remote_datasource.dart';
import 'package:finora_frontend/features/widget/data/models/widget_models.dart';

import 'widget_remote_datasource_test.mocks.dart';

@GenerateMocks([ApiClient, LocalDatabase])
void main() {
  late MockApiClient mockClient;
  late WidgetRemoteDataSourceImpl dataSource;

  setUp(() {
    mockClient = MockApiClient();
    dataSource = WidgetRemoteDataSourceImpl(mockClient);
  });

  // ── getWidgetData ─────────────────────────────────────────────────────────
  group('getWidgetData', () {
    test('retorna WidgetDataModel del servidor', () async {
      when(mockClient.get('/widget/data')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/widget/data'),
          statusCode: 200,
          data: <String, dynamic>{
            'balance': 1500.0,
            'today_spent': 45.0,
            'budget_pct': 60,
            'updated_at': '2024-06-01T10:00:00.000Z',
          },
        ),
      );

      final result = await dataSource.getWidgetData();

      expect(result, isA<WidgetDataModel>());
      expect(result.balance, 1500.0);
      expect(result.todaySpent, 45.0);
    });

    test('incluye activeGoal cuando está en la respuesta', () async {
      when(mockClient.get('/widget/data')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/widget/data'),
          statusCode: 200,
          data: <String, dynamic>{
            'balance': 2000.0,
            'today_spent': 80.0,
            'budget_pct': 75,
            'active_goal': {
              'name': 'Vacaciones',
              'current': 800.0,
              'target': 2000.0,
              'pct': 40,
            },
            'updated_at': '2024-06-01',
          },
        ),
      );

      final result = await dataSource.getWidgetData();

      expect(result.activeGoal, isNotNull);
      expect(result.activeGoal!.name, 'Vacaciones');
    });
  });

  // ── getSettings ───────────────────────────────────────────────────────────
  group('getSettings', () {
    test('retorna WidgetSettingsModel del servidor', () async {
      when(mockClient.get('/widget/settings')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/widget/settings'),
          statusCode: 200,
          data: <String, dynamic>{
            'settings': {
              'show_balance': true,
              'show_today_spent': true,
              'show_budget_pct': false,
              'dark_mode': 'auto',
            },
          },
        ),
      );

      final result = await dataSource.getSettings();

      expect(result, isA<WidgetSettingsModel>());
      expect(result.showBalance, true);
      expect(result.darkMode, 'auto');
    });

    test('usa settings vacíos cuando la clave settings es null', () async {
      when(mockClient.get('/widget/settings')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/widget/settings'),
          statusCode: 200,
          data: <String, dynamic>{'settings': null},
        ),
      );

      final result = await dataSource.getSettings();

      expect(result.showBalance, true); // fallback por defecto
    });
  });

  // ── saveSettings ──────────────────────────────────────────────────────────
  group('saveSettings', () {
    test('llama al endpoint PATCH con los settings correctos', () async {
      final settings = <String, dynamic>{
        'show_balance': false,
        'show_today_spent': true,
        'show_budget_pct': true,
        'dark_mode': 'dark',
      };

      when(
        mockClient.patch('/widget/settings', data: <String, dynamic>{'settings': settings}),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/widget/settings'),
          statusCode: 200,
          data: <String, dynamic>{},
        ),
      );

      await dataSource.saveSettings(settings);

      verify(
        mockClient.patch('/widget/settings', data: <String, dynamic>{'settings': settings}),
      ).called(1);
    });
  });
}

