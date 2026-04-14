import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:finora_frontend/features/gamification/data/datasources/gamification_remote_datasource.dart';
import 'package:finora_frontend/features/gamification/data/models/gamification_models.dart';
import 'package:finora_frontend/features/gamification/data/repositories/gamification_repository_impl.dart';

import 'gamification_repository_impl_test.mocks.dart';

@GenerateMocks([GamificationRemoteDataSource])
void main() {
  late MockGamificationRemoteDataSource mockDs;
  late GamificationRepositoryImpl repository;

  final tStreak = StreakModel.fromJson(const {
    'id': 'str-1',
    'streak_type': 'daily_login',
    'current_count': 7,
    'longest_count': 14,
  });

  setUp(() {
    mockDs = MockGamificationRemoteDataSource();
    repository = GamificationRepositoryImpl(mockDs);
  });

  test('getStreaks retorna lista de StreakEntity', () async {
    when(mockDs.getStreaks()).thenAnswer((_) async => [tStreak]);

    final result = await repository.getStreaks();

    expect(result.first.id, 'str-1');
    verify(mockDs.getStreaks()).called(1);
  });

  test('recordStreak delega correctamente', () async {
    when(mockDs.recordStreak(any)).thenAnswer((_) async => tStreak);

    final result = await repository.recordStreak('daily_login');

    expect(result.streakType, 'daily_login');
    verify(mockDs.recordStreak('daily_login')).called(1);
  });
}

