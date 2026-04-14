import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:finora_frontend/features/gamification/presentation/bloc/gamification_bloc.dart';
import 'package:finora_frontend/features/gamification/presentation/bloc/gamification_event.dart';
import 'package:finora_frontend/features/gamification/presentation/bloc/gamification_state.dart';
import 'package:finora_frontend/features/gamification/domain/repositories/gamification_repository.dart';
import 'package:finora_frontend/features/gamification/domain/entities/streak_entity.dart';
import 'package:finora_frontend/features/gamification/domain/entities/badge_entity.dart';
import 'package:finora_frontend/features/gamification/domain/entities/challenge_entity.dart';
import 'package:finora_frontend/features/gamification/domain/entities/health_score_entity.dart';

@GenerateMocks([GamificationRepository])
import 'gamification_bloc_test.mocks.dart';

void main() {
  late GamificationBloc bloc;
  late MockGamificationRepository mockRepo;

  final tStreak = StreakEntity(
    id: 'streak-1',
    streakType: 'daily_login',
    currentCount: 5,
    longestCount: 10,
    lastActivityDate: '2026-04-09',
  );

  final tBadge = BadgeEntity(
    id: 'badge-1',
    badgeKey: 'first_transaction',
    name: 'First Transaction',
    description: 'Made your first transaction',
    isEarned: true,
    earnedAt: '2026-01-01',
  );

  final tChallenge = ChallengeEntity(
    id: 'challenge-1',
    title: 'Save 100€',
    challengeType: 'savings',
    targetValue: 100.0,
    rewardPoints: 50,
    isActive: true,
    progress: 50.0,
    isCompleted: false,
    isJoined: true,
  );

  final tHealthScore = HealthScoreEntity(
    score: 75,
    grade: 'B',
    budgetAdherence: 80,
    savingsRate: 70,
    goalProgress: 60,
    streakBonus: 10,
  );

  setUp(() {
    mockRepo = MockGamificationRepository();
    bloc = GamificationBloc(mockRepo);
  });

  tearDown(() {
    bloc.close();
  });

  test('initial state is GamificationInitial', () {
    expect(bloc.state, isA<GamificationInitial>());
  });

  group('LoadGamificationData', () {
    blocTest<GamificationBloc, GamificationState>(
      'emits [GamificationLoading, GamificationLoaded] when all 4 parallel loads succeed',
      build: () {
        when(mockRepo.getStreaks()).thenAnswer((_) async => [tStreak]);
        when(mockRepo.getBadges()).thenAnswer((_) async => [tBadge]);
        when(mockRepo.getChallenges()).thenAnswer((_) async => [tChallenge]);
        when(mockRepo.getHealthScore()).thenAnswer((_) async => tHealthScore);
        return bloc;
      },
      act: (b) => b.add(const LoadGamificationData()),
      expect: () => [isA<GamificationLoading>(), isA<GamificationLoaded>()],
      verify: (_) {
        verify(mockRepo.getStreaks()).called(1);
        verify(mockRepo.getBadges()).called(1);
        verify(mockRepo.getChallenges()).called(1);
        verify(mockRepo.getHealthScore()).called(1);
      },
    );

    blocTest<GamificationBloc, GamificationState>(
      'GamificationLoaded contains correct data from all 4 loads',
      build: () {
        when(mockRepo.getStreaks()).thenAnswer((_) async => [tStreak]);
        when(mockRepo.getBadges()).thenAnswer((_) async => [tBadge]);
        when(mockRepo.getChallenges()).thenAnswer((_) async => [tChallenge]);
        when(mockRepo.getHealthScore()).thenAnswer((_) async => tHealthScore);
        return bloc;
      },
      act: (b) => b.add(const LoadGamificationData()),
      expect: () => [
        isA<GamificationLoading>(),
        predicate<GamificationState>((s) {
          if (s is GamificationLoaded) {
            return s.streaks.length == 1 &&
                s.badges.length == 1 &&
                s.challenges.length == 1 &&
                s.healthScore?.score == 75;
          }
          return false;
        }),
      ],
    );

    blocTest<GamificationBloc, GamificationState>(
      'emits [GamificationLoading, GamificationError] when any load fails',
      build: () {
        when(mockRepo.getStreaks()).thenAnswer((_) async => [tStreak]);
        when(
          mockRepo.getBadges(),
        ).thenThrow(Exception('Badge service unavailable'));
        when(mockRepo.getChallenges()).thenAnswer((_) async => [tChallenge]);
        when(mockRepo.getHealthScore()).thenAnswer((_) async => tHealthScore);
        return bloc;
      },
      act: (b) => b.add(const LoadGamificationData()),
      expect: () => [isA<GamificationLoading>(), isA<GamificationError>()],
    );

    blocTest<GamificationBloc, GamificationState>(
      'emits [GamificationLoading, GamificationError] on complete failure',
      build: () {
        when(mockRepo.getStreaks()).thenThrow(Exception('Network error'));
        when(mockRepo.getBadges()).thenThrow(Exception('Network error'));
        when(mockRepo.getChallenges()).thenThrow(Exception('Network error'));
        when(mockRepo.getHealthScore()).thenThrow(Exception('Network error'));
        return bloc;
      },
      act: (b) => b.add(const LoadGamificationData()),
      expect: () => [isA<GamificationLoading>(), isA<GamificationError>()],
    );

    blocTest<GamificationBloc, GamificationState>(
      'GamificationError strips Exception: prefix',
      build: () {
        when(mockRepo.getStreaks()).thenThrow(Exception('Network error'));
        when(mockRepo.getBadges()).thenThrow(Exception('Network error'));
        when(mockRepo.getChallenges()).thenThrow(Exception('Network error'));
        when(mockRepo.getHealthScore()).thenThrow(Exception('Network error'));
        return bloc;
      },
      act: (b) => b.add(const LoadGamificationData()),
      expect: () => [
        isA<GamificationLoading>(),
        predicate<GamificationState>((s) {
          if (s is GamificationError) {
            return !s.message.startsWith('Exception:');
          }
          return false;
        }),
      ],
    );
  });

  group('RecordStreak', () {
    blocTest<GamificationBloc, GamificationState>(
      'on success triggers LoadGamificationData reload',
      build: () {
        when(
          mockRepo.recordStreak('daily_login'),
        ).thenAnswer((_) async => tStreak);
        when(mockRepo.getStreaks()).thenAnswer((_) async => [tStreak]);
        when(mockRepo.getBadges()).thenAnswer((_) async => [tBadge]);
        when(mockRepo.getChallenges()).thenAnswer((_) async => [tChallenge]);
        when(mockRepo.getHealthScore()).thenAnswer((_) async => tHealthScore);
        return bloc;
      },
      act: (b) => b.add(const RecordStreak('daily_login')),
      expect: () => [isA<GamificationLoading>(), isA<GamificationLoaded>()],
      verify: (_) {
        verify(mockRepo.recordStreak('daily_login')).called(1);
        verify(mockRepo.getStreaks()).called(1);
      },
    );

    blocTest<GamificationBloc, GamificationState>(
      'emits [GamificationError] when recordStreak throws',
      build: () {
        when(
          mockRepo.recordStreak(any),
        ).thenThrow(Exception('Streak not found'));
        return bloc;
      },
      act: (b) => b.add(const RecordStreak('daily_login')),
      expect: () => [isA<GamificationError>()],
    );
  });

  group('CheckBadges', () {
    blocTest<GamificationBloc, GamificationState>(
      'emits [BadgesAwarded, GamificationLoading, GamificationLoaded] when badges awarded',
      build: () {
        when(
          mockRepo.checkAndAwardBadges(),
        ).thenAnswer((_) async => ['first_transaction', 'saver']);
        when(mockRepo.getStreaks()).thenAnswer((_) async => [tStreak]);
        when(mockRepo.getBadges()).thenAnswer((_) async => [tBadge]);
        when(mockRepo.getChallenges()).thenAnswer((_) async => [tChallenge]);
        when(mockRepo.getHealthScore()).thenAnswer((_) async => tHealthScore);
        return bloc;
      },
      act: (b) => b.add(const CheckBadges()),
      expect: () => [
        isA<BadgesAwarded>(),
        isA<GamificationLoading>(),
        isA<GamificationLoaded>(),
      ],
      verify: (_) {
        verify(mockRepo.checkAndAwardBadges()).called(1);
      },
    );

    blocTest<GamificationBloc, GamificationState>(
      'does not emit BadgesAwarded when no new badges awarded',
      build: () {
        when(mockRepo.checkAndAwardBadges()).thenAnswer((_) async => []);
        when(mockRepo.getStreaks()).thenAnswer((_) async => [tStreak]);
        when(mockRepo.getBadges()).thenAnswer((_) async => [tBadge]);
        when(mockRepo.getChallenges()).thenAnswer((_) async => [tChallenge]);
        when(mockRepo.getHealthScore()).thenAnswer((_) async => tHealthScore);
        return bloc;
      },
      act: (b) => b.add(const CheckBadges()),
      expect: () => [isA<GamificationLoading>(), isA<GamificationLoaded>()],
    );

    blocTest<GamificationBloc, GamificationState>(
      'emits [GamificationError] when checkAndAwardBadges throws',
      build: () {
        when(
          mockRepo.checkAndAwardBadges(),
        ).thenThrow(Exception('Badges service error'));
        return bloc;
      },
      act: (b) => b.add(const CheckBadges()),
      expect: () => [isA<GamificationError>()],
    );
  });

  group('JoinChallenge', () {
    blocTest<GamificationBloc, GamificationState>(
      'emits [ChallengeJoined, GamificationLoading, GamificationLoaded] on success',
      build: () {
        when(mockRepo.joinChallenge('challenge-1')).thenAnswer((_) async {
          return;
        });
        when(mockRepo.getStreaks()).thenAnswer((_) async => [tStreak]);
        when(mockRepo.getBadges()).thenAnswer((_) async => [tBadge]);
        when(mockRepo.getChallenges()).thenAnswer((_) async => [tChallenge]);
        when(mockRepo.getHealthScore()).thenAnswer((_) async => tHealthScore);
        return bloc;
      },
      act: (b) => b.add(const JoinChallenge('challenge-1')),
      expect: () => [
        isA<ChallengeJoined>(),
        isA<GamificationLoading>(),
        isA<GamificationLoaded>(),
      ],
      verify: (_) {
        verify(mockRepo.joinChallenge('challenge-1')).called(1);
      },
    );

    blocTest<GamificationBloc, GamificationState>(
      'emits [GamificationError] when already joined or other error',
      build: () {
        when(
          mockRepo.joinChallenge(any),
        ).thenThrow(Exception('Already joined this challenge'));
        return bloc;
      },
      act: (b) => b.add(const JoinChallenge('challenge-1')),
      expect: () => [isA<GamificationError>()],
    );

    blocTest<GamificationBloc, GamificationState>(
      'GamificationError message contains already joined info',
      build: () {
        when(
          mockRepo.joinChallenge(any),
        ).thenThrow(Exception('Already joined this challenge'));
        return bloc;
      },
      act: (b) => b.add(const JoinChallenge('challenge-1')),
      expect: () => [
        predicate<GamificationState>((s) {
          if (s is GamificationError) {
            return s.message.contains('Already joined');
          }
          return false;
        }),
      ],
    );
  });

  group('UpdateChallengeProgress', () {
    blocTest<GamificationBloc, GamificationState>(
      'on success triggers LoadGamificationData reload',
      build: () {
        when(mockRepo.updateChallengeProgress('challenge-1', 75.0)).thenAnswer((
          _,
        ) async {
          return;
        });
        when(mockRepo.getStreaks()).thenAnswer((_) async => [tStreak]);
        when(mockRepo.getBadges()).thenAnswer((_) async => [tBadge]);
        when(mockRepo.getChallenges()).thenAnswer((_) async => [tChallenge]);
        when(mockRepo.getHealthScore()).thenAnswer((_) async => tHealthScore);
        return bloc;
      },
      act: (b) => b.add(const UpdateChallengeProgress('challenge-1', 75.0)),
      expect: () => [isA<GamificationLoading>(), isA<GamificationLoaded>()],
      verify: (_) {
        verify(mockRepo.updateChallengeProgress('challenge-1', 75.0)).called(1);
      },
    );

    blocTest<GamificationBloc, GamificationState>(
      'emits [GamificationError] when updateChallengeProgress throws',
      build: () {
        when(
          mockRepo.updateChallengeProgress(any, any),
        ).thenThrow(Exception('Update failed'));
        return bloc;
      },
      act: (b) => b.add(const UpdateChallengeProgress('challenge-1', 75.0)),
      expect: () => [isA<GamificationError>()],
    );
  });
}

