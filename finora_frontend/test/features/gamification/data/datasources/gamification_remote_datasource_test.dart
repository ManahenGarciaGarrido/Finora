import 'package:dio/dio.dart'; // ¡Importación clave!
import 'package:finora_frontend/core/database/local_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:finora_frontend/core/network/api_client.dart';
import 'package:finora_frontend/features/gamification/data/datasources/gamification_remote_datasource.dart';
import 'package:finora_frontend/features/gamification/data/models/gamification_models.dart';

import 'gamification_remote_datasource_test.mocks.dart';

@GenerateMocks([ApiClient, LocalDatabase])
void main() {
  late MockApiClient mockClient;
  late GamificationRemoteDataSourceImpl dataSource;

  setUp(() {
    mockClient = MockApiClient();
    dataSource = GamificationRemoteDataSourceImpl(mockClient);
  });

  // ── getStreaks ────────────────────────────────────────────────────────────
  group('getStreaks', () {
    test('retorna lista de StreakModel', () async {
      when(mockClient.get('/gamification/streaks')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 200,
          data: <String, dynamic>{
            'streaks': [
              {
                'id': 'str-1',
                'streak_type': 'daily_login',
                'current_count': 5,
                'longest_count': 10,
              },
            ],
          },
        ),
      );

      final result = await dataSource.getStreaks();

      expect(result, isA<List<StreakModel>>());
      expect(result.first.streakType, 'daily_login');
    });

    test('retorna lista vacía cuando streaks es null', () async {
      when(mockClient.get('/gamification/streaks')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 200,
          data: <String, dynamic>{'streaks': null},
        ),
      );

      final result = await dataSource.getStreaks();
      expect(result, isEmpty);
    });
  });

  // ── recordStreak ──────────────────────────────────────────────────────────
  group('recordStreak', () {
    test('retorna StreakModel actualizado', () async {
      when(
        mockClient.post('/gamification/streaks/record', data: anyNamed('data')),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 200,
          data: <String, dynamic>{
            'streak': {
              'id': 'str-1',
              'streak_type': 'daily_login',
              'current_count': 6,
              'longest_count': 10,
            },
          },
        ),
      );

      final result = await dataSource.recordStreak('daily_login');

      expect(result.currentCount, 6);
      verify(
        mockClient.post(
          '/gamification/streaks/record',
          data: <String, dynamic>{'streak_type': 'daily_login'},
        ),
      ).called(1);
    });
  });

  // ── getBadges ─────────────────────────────────────────────────────────────
  group('getBadges', () {
    test('retorna lista de BadgeModel', () async {
      when(mockClient.get('/gamification/badges')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 200,
          data: <String, dynamic>{
            'badges': [
              {
                'id': 'b-1',
                'badge_key': 'first_goal',
                'name': 'Primera Meta',
                'is_earned': true,
              },
            ],
          },
        ),
      );

      final result = await dataSource.getBadges();

      expect(result, isA<List<BadgeModel>>());
      expect(result.first.badgeKey, 'first_goal');
    });
  });

  // ── checkAndAwardBadges ───────────────────────────────────────────────────
  group('checkAndAwardBadges', () {
    test('retorna lista de badge keys otorgados', () async {
      when(
        mockClient.post('/gamification/badges/check', data: anyNamed('data')),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 200,
          data: <String, dynamic>{
            'awarded': ['first_goal', 'saver'],
          },
        ),
      );

      final result = await dataSource.checkAndAwardBadges();

      expect(result, ['first_goal', 'saver']);
    });

    test('retorna lista vacía cuando awarded es null', () async {
      when(
        mockClient.post('/gamification/badges/check', data: anyNamed('data')),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 200,
          data: <String, dynamic>{'awarded': null},
        ),
      );

      final result = await dataSource.checkAndAwardBadges();
      expect(result, isEmpty);
    });
  });

  // ── getChallenges ─────────────────────────────────────────────────────────
  group('getChallenges', () {
    test('retorna lista de ChallengeModel', () async {
      when(mockClient.get('/gamification/challenges')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 200,
          data: <String, dynamic>{
            'challenges': [
              {
                'id': 'ch-1',
                'title': 'Reto de ahorro',
                'challenge_type': 'savings',
                'target_value': 500.0,
                'reward_points': 100,
                'is_active': true,
                'progress': 0.0,
                'is_completed': false,
                'is_joined': false,
              },
            ],
          },
        ),
      );

      final result = await dataSource.getChallenges();

      expect(result, isA<List<ChallengeModel>>());
      expect(result.first.title, 'Reto de ahorro');
    });
  });

  // ── joinChallenge ─────────────────────────────────────────────────────────
  group('joinChallenge', () {
    test('llama al endpoint correcto', () async {
      when(
        mockClient.post(
          '/gamification/challenges/ch-1/join',
          data: anyNamed('data'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 200,
          data: <String, dynamic>{},
        ),
      );

      await dataSource.joinChallenge('ch-1');

      verify(
        mockClient.post('/gamification/challenges/ch-1/join', data: <String, dynamic>{}),
      ).called(1);
    });
  });

  // ── updateChallengeProgress ───────────────────────────────────────────────
  group('updateChallengeProgress', () {
    test('llama al endpoint PATCH con el progreso correcto', () async {
      when(
        mockClient.patch(
          '/gamification/challenges/ch-1/progress',
          data: anyNamed('data'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 200,
          data: <String, dynamic>{},
        ),
      );

      await dataSource.updateChallengeProgress('ch-1', 75.0);

      verify(
        mockClient.patch(
          '/gamification/challenges/ch-1/progress',
          data: <String, dynamic>{'progress': 75.0},
        ),
      ).called(1);
    });
  });

  // ── getHealthScore ────────────────────────────────────────────────────────
  group('getHealthScore', () {
    test('retorna HealthScoreModel del servidor', () async {
      when(mockClient.get('/gamification/health-score')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 200,
          data: <String, dynamic>{
            'score': 80,
            'grade': 'A',
            'breakdown': {
              'budget_adherence': 25,
              'savings_rate': 20,
              'goal_progress': 20,
              'streak_bonus': 15,
            },
          },
        ),
      );

      final result = await dataSource.getHealthScore();

      expect(result, isA<HealthScoreModel>());
      expect(result.score, 80);
      expect(result.grade, 'A');
    });
  });
}

