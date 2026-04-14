// ignore_for_file: subtype_of_sealed_class
//
// PREREQUISITO: ejecutar code generation antes de correr los tests:
//   flutter pub run build_runner build --delete-conflicting-outputs
//
// Esto genera el fichero .mocks.dart con MockApiClient.

import 'package:dio/dio.dart';
import 'package:finora_frontend/core/database/local_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:finora_frontend/core/network/api_client.dart';
import 'package:finora_frontend/features/goals/data/datasources/goals_remote_datasource.dart';
import 'package:finora_frontend/features/goals/data/models/savings_goal_model.dart';
import 'package:finora_frontend/features/goals/data/models/goal_contribution_model.dart';

import 'goals_remote_data_source_test.mocks.dart';

@GenerateMocks([ApiClient, LocalDatabase])
void main() {
  late MockApiClient mockApiClient;
  late GoalsRemoteDataSourceImpl dataSource;

  // ── Fixtures ─────────────────────────────────────────────────────────────────
  const tGoalJson = <String, dynamic>{
    'id': 'goal-1',
    'user_id': 'user-1',
    'name': 'Vacation Fund',
    'icon': 'beach',
    'color': '#6C63FF',
    'target_amount': 5000.0,
    'current_amount': 1000.0,
    'status': 'active',
    'percentage': 20,
    'percentage_decimal': 0.20,
    'remaining_amount': 4000.0,
    'progress_color': '#ef4444',
    'is_completed': false,
    'created_at': '2024-01-01T00:00:00.000Z',
    'updated_at': '2024-01-02T00:00:00.000Z',
  };

  const tContributionJson = <String, dynamic>{
    'id': 'contrib-1',
    'goal_id': 'goal-1',
    'user_id': 'user-1',
    'amount': 200.0,
    'date': '2024-03-15',
    'note': 'Monthly saving',
    'created_at': '2024-03-15T10:00:00.000Z',
    'updated_at': '2024-03-15T10:00:00.000Z',
  };

  Response<dynamic> fakeResponse(dynamic data, {int statusCode = 200}) =>
      Response(
        requestOptions: RequestOptions(path: ''),
        data: data,
        statusCode: statusCode,
      );

  setUp(() {
    mockApiClient = MockApiClient();
    dataSource = GoalsRemoteDataSourceImpl(mockApiClient);
  });

  // ── getGoals ─────────────────────────────────────────────────────────────────
  group('getGoals', () {
    test(
      'retorna lista de SavingsGoalModel cuando la respuesta es exitosa',
      () async {
        when(mockApiClient.get(any)).thenAnswer(
          (_) async => fakeResponse({
            'goals': [tGoalJson],
          }),
        );

        final result = await dataSource.getGoals();

        expect(result, isA<List<SavingsGoalModel>>());
        expect(result.length, 1);
        expect(result.first.id, 'goal-1');
        expect(result.first.name, 'Vacation Fund');
        verify(mockApiClient.get(any)).called(1);
      },
    );

    test('retorna lista vacía cuando goals es []', () async {
      when(
        mockApiClient.get(any),
      ).thenAnswer((_) async => fakeResponse({'goals': <dynamic>[]}));

      final result = await dataSource.getGoals();

      expect(result, isEmpty);
    });

    test('propaga la excepción del ApiClient', () async {
      when(mockApiClient.get(any)).thenThrow(Exception('Network error'));

      expect(dataSource.getGoals(), throwsException);
    });
  });

  // ── getGoal ──────────────────────────────────────────────────────────────────
  group('getGoal', () {
    test('retorna SavingsGoalModel con el id correcto', () async {
      when(
        mockApiClient.get(any),
      ).thenAnswer((_) async => fakeResponse({'goal': tGoalJson}));

      final result = await dataSource.getGoal('goal-1');

      expect(result, isA<SavingsGoalModel>());
      expect(result.id, 'goal-1');
    });
  });

  // ── createGoal ───────────────────────────────────────────────────────────────
  group('createGoal', () {
    test('llama a POST y retorna el modelo creado', () async {
      when(mockApiClient.post(any, data: anyNamed('data'))).thenAnswer(
        (_) async => fakeResponse({'goal': tGoalJson}, statusCode: 201),
      );

      final result = await dataSource.createGoal({'name': 'Vacation Fund'});

      expect(result.name, 'Vacation Fund');
      verify(mockApiClient.post(any, data: anyNamed('data'))).called(1);
    });
  });

  // ── updateGoal ───────────────────────────────────────────────────────────────
  group('updateGoal', () {
    test('llama a PUT y retorna el modelo actualizado', () async {
      when(mockApiClient.put(any, data: anyNamed('data'))).thenAnswer(
        (_) async => fakeResponse({
          'goal': {...tGoalJson, 'name': 'Updated Goal'},
        }),
      );

      final result = await dataSource.updateGoal('goal-1', {
        'name': 'Updated Goal',
      });

      expect(result.name, 'Updated Goal');
      verify(mockApiClient.put(any, data: anyNamed('data'))).called(1);
    });
  });

  // ── deleteGoal ───────────────────────────────────────────────────────────────
  group('deleteGoal', () {
    test('llama a DELETE y completa sin error', () async {
      when(
        mockApiClient.delete(any),
      ).thenAnswer((_) async => fakeResponse(null, statusCode: 204));

      await expectLater(dataSource.deleteGoal('goal-1'), completes);
      verify(mockApiClient.delete(any)).called(1);
    });
  });

  // ── addContribution ──────────────────────────────────────────────────────────
  group('addContribution', () {
    test('retorna GoalContributionModel al añadir aportación', () async {
      when(mockApiClient.post(any, data: anyNamed('data'))).thenAnswer(
        (_) async =>
            fakeResponse({'contribution': tContributionJson}, statusCode: 201),
      );

      final result = await dataSource.addContribution('goal-1', {
        'amount': 200.0,
      });

      expect(result, isA<GoalContributionModel>());
      expect(result.id, 'contrib-1');
      expect(result.amount, 200.0);
    });
  });

  // ── getContributions ─────────────────────────────────────────────────────────
  group('getContributions', () {
    test('retorna lista de GoalContributionModel', () async {
      when(mockApiClient.get(any)).thenAnswer(
        (_) async => fakeResponse({
          'contributions': [tContributionJson],
        }),
      );

      final result = await dataSource.getContributions('goal-1');

      expect(result, isA<List<GoalContributionModel>>());
      expect(result.length, 1);
      expect(result.first.goalId, 'goal-1');
    });
  });

  // ── getRecommendations ───────────────────────────────────────────────────────
  group('getRecommendations', () {
    test('retorna el mapa de recomendaciones IA', () async {
      final tRec = <String, dynamic>{'recommendation': 'Increase monthly savings by 10%'};
      when(mockApiClient.get(any)).thenAnswer((_) async => fakeResponse(tRec));

      final result = await dataSource.getRecommendations();

      expect(result, tRec);
    });
  });
}

