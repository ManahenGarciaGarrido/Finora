import 'package:flutter_test/flutter_test.dart';
import 'package:finora_frontend/features/gamification/data/models/gamification_models.dart';
import 'package:finora_frontend/features/gamification/domain/entities/streak_entity.dart';
import 'package:finora_frontend/features/gamification/domain/entities/badge_entity.dart';
import 'package:finora_frontend/features/gamification/domain/entities/challenge_entity.dart';
import 'package:finora_frontend/features/gamification/domain/entities/health_score_entity.dart';

void main() {
  // ── StreakModel ───────────────────────────────────────────────────────────
  group('StreakModel.fromJson', () {
    test('mapea todos los campos correctamente', () {
      final json = <String, dynamic>{
        'id': 'streak-1',
        'streak_type': 'daily_login',
        'current_count': 7,
        'longest_count': 14,
        'last_activity_date': '2024-06-01',
      };

      final model = StreakModel.fromJson(json);

      expect(model.id, 'streak-1');
      expect(model.streakType, 'daily_login');
      expect(model.currentCount, 7);
      expect(model.longestCount, 14);
      expect(model.lastActivityDate, '2024-06-01');
    });

    test('usa valores por defecto con campos null', () {
      final model = StreakModel.fromJson(<String, dynamic>{
        'id': null,
        'streak_type': null,
        'current_count': null,
        'longest_count': null,
      });

      expect(model.id, '');
      expect(model.streakType, '');
      expect(model.currentCount, 0);
      expect(model.longestCount, 0);
      expect(model.lastActivityDate, isNull);
    });

    test('es instancia de StreakEntity', () {
      final model = StreakModel.fromJson(<String, dynamic>{
        'id': 'x',
        'streak_type': 'budget',
        'current_count': 1,
        'longest_count': 5,
      });
      expect(model, isA<StreakEntity>());
    });
  });

  // ── BadgeModel ────────────────────────────────────────────────────────────
  group('BadgeModel.fromJson', () {
    test('mapea correctamente todos los campos', () {
      final json = <String, dynamic>{
        'id': 'badge-1',
        'badge_key': 'first_goal',
        'name': 'Primera Meta',
        'description': 'Creaste tu primera meta',
        'icon': 'trophy',
        'category': 'goals',
        'is_earned': true,
        'earned_at': '2024-05-01',
      };

      final model = BadgeModel.fromJson(json);

      expect(model.id, 'badge-1');
      expect(model.badgeKey, 'first_goal');
      expect(model.name, 'Primera Meta');
      expect(model.isEarned, true);
      expect(model.earnedAt, '2024-05-01');
    });

    test('isEarned es false cuando no está presente', () {
      final model = BadgeModel.fromJson(<String, dynamic>{
        'id': 'b-2',
        'badge_key': 'saver',
        'name': 'Ahorrador',
        'is_earned': null,
      });
      expect(model.isEarned, false);
    });

    test('es instancia de BadgeEntity', () {
      final model = BadgeModel.fromJson(<String, dynamic>{
        'id': 'x',
        'badge_key': 'x',
        'name': 'x',
        'is_earned': false,
      });
      expect(model, isA<BadgeEntity>());
    });
  });

  // ── ChallengeModel ────────────────────────────────────────────────────────
  group('ChallengeModel.fromJson', () {
    test('mapea correctamente todos los campos', () {
      final json = <String, dynamic>{
        'id': 'ch-1',
        'title': 'Reto de ahorro',
        'description': 'Ahorra 500€ este mes',
        'challenge_type': 'savings',
        'target_value': 500.0,
        'reward_points': 100,
        'is_active': true,
        'starts_at': '2024-06-01',
        'ends_at': '2024-06-30',
        'progress': 250.0,
        'is_completed': false,
        'is_joined': true,
      };

      final model = ChallengeModel.fromJson(json);

      expect(model.id, 'ch-1');
      expect(model.title, 'Reto de ahorro');
      expect(model.targetValue, 500.0);
      expect(model.rewardPoints, 100);
      expect(model.isActive, true);
      expect(model.progress, 250.0);
      expect(model.isCompleted, false);
      expect(model.isJoined, true);
    });

    test('isActive usa true como fallback', () {
      final model = ChallengeModel.fromJson(<String, dynamic>{
        'id': 'x',
        'title': 'x',
        'challenge_type': 'x',
        'target_value': 0,
        'reward_points': 0,
        'is_active': null,
        'progress': 0,
        'is_completed': false,
        'is_joined': false,
      });
      expect(model.isActive, true);
    });

    test('es instancia de ChallengeEntity', () {
      final model = ChallengeModel.fromJson(<String, dynamic>{
        'id': 'x',
        'title': 'x',
        'challenge_type': 'x',
        'target_value': 0,
        'reward_points': 0,
        'is_active': false,
        'progress': 0,
        'is_completed': false,
        'is_joined': false,
      });
      expect(model, isA<ChallengeEntity>());
    });
  });

  // ── HealthScoreModel ──────────────────────────────────────────────────────
  group('HealthScoreModel.fromJson', () {
    test('mapea score, grade y breakdown correctamente', () {
      final json = <String, dynamic>{
        'score': 72,
        'grade': 'B',
        'breakdown': <String, dynamic>{
          'budget_adherence': 20,
          'savings_rate': 18,
          'goal_progress': 22,
          'streak_bonus': 12,
        },
        'details': <String, dynamic>{},
      };

      final model = HealthScoreModel.fromJson(json);

      expect(model.score, 72);
      expect(model.grade, 'B');
      expect(model.budgetAdherence, 20);
      expect(model.savingsRate, 18);
      expect(model.goalProgress, 22);
      expect(model.streakBonus, 12);
    });

    test('usa grade D cuando es null', () {
      final model = HealthScoreModel.fromJson(<String, dynamic>{
        'score': 40,
        'grade': null,
        'breakdown': <String, dynamic>{},
      });
      expect(model.grade, 'D');
    });

    test('breakdown ausente no lanza error', () {
      final model = HealthScoreModel.fromJson(<String, dynamic>{
        'score': 50,
        'grade': 'C',
      });
      expect(model.budgetAdherence, 0);
      expect(model.savingsRate, 0);
    });

    test('es instancia de HealthScoreEntity', () {
      final model = HealthScoreModel.fromJson(<String, dynamic>{
        'score': 50,
        'grade': 'C',
        'breakdown': <String, dynamic>{},
      });
      expect(model, isA<HealthScoreEntity>());
    });
  });
}
