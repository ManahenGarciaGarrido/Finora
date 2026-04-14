import 'package:flutter_test/flutter_test.dart';
import 'package:finora_frontend/features/goals/data/models/savings_goal_model.dart';

void main() {
  // ── Fixture base ────────────────────────────────────────────────────────────
  const tJsonFull = <String, dynamic>{
    'id': 'goal-1',
    'user_id': 'user-1',
    'name': 'Vacation Fund',
    'icon': 'beach',
    'color': '#6C63FF',
    'target_amount': 5000.0,
    'current_amount': 1000.0,
    'deadline': '2025-12-31',
    'category': 'travel',
    'notes': 'Dream trip',
    'status': 'active',
    'percentage': 20,
    'percentage_decimal': 0.20,
    'remaining_amount': 4000.0,
    'progress_color': '#ef4444',
    'is_completed': false,
    'projected_completion_date': '2025-06-01',
    'monthly_target': 500.0,
    'ai_feasibility': 'viable',
    'ai_explanation': 'On track',
    'completed_at': null,
    'created_at': '2024-01-01T00:00:00.000Z',
    'updated_at': '2024-01-02T00:00:00.000Z',
    'contributions_count': 3,
  };

  // ── fromJson ────────────────────────────────────────────────────────────────
  group('SavingsGoalModel.fromJson', () {
    test('mapea todos los campos obligatorios correctamente', () {
      final model = SavingsGoalModel.fromJson(tJsonFull);

      expect(model.id, 'goal-1');
      expect(model.userId, 'user-1');
      expect(model.name, 'Vacation Fund');
      expect(model.icon, 'beach');
      expect(model.color, '#6C63FF');
      expect(model.targetAmount, 5000.0);
      expect(model.currentAmount, 1000.0);
      expect(model.status, 'active');
      expect(model.percentage, 20);
      expect(model.percentageDecimal, 0.20);
      expect(model.remainingAmount, 4000.0);
      expect(model.progressColor, '#ef4444');
      expect(model.isCompleted, false);
      expect(model.createdAt, DateTime.parse('2024-01-01T00:00:00.000Z'));
      expect(model.updatedAt, DateTime.parse('2024-01-02T00:00:00.000Z'));
    });

    test('mapea campos opcionales cuando están presentes', () {
      final model = SavingsGoalModel.fromJson(tJsonFull);

      expect(model.deadline, DateTime(2025, 12, 31));
      expect(model.category, 'travel');
      expect(model.notes, 'Dream trip');
      expect(model.projectedCompletionDate, '2025-06-01');
      expect(model.monthlyTarget, 500.0);
      expect(model.aiFeasibility, 'viable');
      expect(model.aiExplanation, 'On track');
      expect(model.contributionsCount, 3);
    });

    test('usa valores por defecto cuando los campos opcionales son null', () {
      final minimalJson = <String, dynamic>{
        'id': 'goal-2',
        'user_id': 'user-1',
        'name': 'Emergency Fund',
        'target_amount': 2000,
        'current_amount': 0,
        'status': 'active',
        'percentage': 0,
        'remaining_amount': 2000,
        'created_at': '2024-01-01T00:00:00.000Z',
        'updated_at': '2024-01-01T00:00:00.000Z',
      };

      final model = SavingsGoalModel.fromJson(minimalJson);

      expect(model.icon, 'other');           // default
      expect(model.color, '#6C63FF');        // default
      expect(model.progressColor, '#ef4444'); // default
      expect(model.isCompleted, false);       // default
      expect(model.deadline, isNull);
      expect(model.category, isNull);
      expect(model.monthlyTarget, isNull);
      expect(model.contributionsCount, isNull);
    });

    test('_toDouble convierte String numérico correctamente', () {
      final json = <String, dynamic>{
        ...tJsonFull,
        'target_amount': '3500.50',   // String en lugar de double
        'current_amount': '700',
        'remaining_amount': '2800.50',
      };

      final model = SavingsGoalModel.fromJson(json);

      expect(model.targetAmount, 3500.50);
      expect(model.currentAmount, 700.0);
      expect(model.remainingAmount, 2800.50);
    });

    test('_toInt convierte double a int correctamente', () {
      final json = <String, dynamic>{
        ...tJsonFull,
        'percentage': 75.9,           // double en lugar de int
      };

      final model = SavingsGoalModel.fromJson(json);

      expect(model.percentage, 75);
    });

    test('percentage_decimal se calcula desde percentage si no está presente', () {
      final json = <String, dynamic>{
        ...tJsonFull,
        'percentage': 50,
      }..remove('percentage_decimal');

      final model = SavingsGoalModel.fromJson(json);

      expect(model.percentageDecimal, closeTo(0.50, 0.001));
    });

    test('acepta camelCase progress_color como progressColor', () {
      final json = <String, dynamic>{
        ...tJsonFull,
      }
        ..remove('progress_color')
        ..['progressColor'] = '#22c55e';

      final model = SavingsGoalModel.fromJson(json);

      expect(model.progressColor, '#22c55e');
    });
  });

  // ── toJson ──────────────────────────────────────────────────────────────────
  group('SavingsGoalModel.toJson', () {
    test('serializa los campos esperados para el backend', () {
      final model = SavingsGoalModel.fromJson(tJsonFull);
      final json = model.toJson();

      expect(json['id'], 'goal-1');
      expect(json['user_id'], 'user-1');
      expect(json['name'], 'Vacation Fund');
      expect(json['icon'], 'beach');
      expect(json['color'], '#6C63FF');
      expect(json['target_amount'], 5000.0);
      expect(json['current_amount'], 1000.0);
      expect(json['monthly_target'], 500.0);
      expect(json['deadline'], '2025-12-31');  // solo fecha, sin hora
    });

    test('deadline es null en toJson cuando no hay fecha límite', () {
      final minimalJson = <String, dynamic>{
        'id': 'goal-3',
        'user_id': 'user-1',
        'name': 'No Deadline Goal',
        'target_amount': 1000,
        'current_amount': 0,
        'status': 'active',
        'percentage': 0,
        'remaining_amount': 1000,
        'created_at': '2024-01-01T00:00:00.000Z',
        'updated_at': '2024-01-01T00:00:00.000Z',
      };

      final json = SavingsGoalModel.fromJson(minimalJson).toJson();

      expect(json['deadline'], isNull);
    });
  });

  // ── Entity getters ───────────────────────────────────────────────────────────
  group('SavingsGoalEntity getters heredados', () {
    test('isActive retorna true cuando status es active', () {
      final model = SavingsGoalModel.fromJson(tJsonFull);
      expect(model.isActive, true);
      expect(model.isCancelled, false);
    });

    test('feasibilityLabel retorna etiqueta correcta para viable', () {
      final model = SavingsGoalModel.fromJson(tJsonFull);
      expect(model.feasibilityLabel, 'Viable');
    });

    test('feasibilityLabel retorna Difícil para difficult', () {
      final model = SavingsGoalModel.fromJson(<String, dynamic>{
        ...tJsonFull,
        'ai_feasibility': 'difficult',
      });
      expect(model.feasibilityLabel, 'Difícil');
    });

    test('feasibilityLabel retorna null cuando aiFeasibility es null', () {
      final json = <String, dynamic>{...tJsonFull}..remove('ai_feasibility');
      final model = SavingsGoalModel.fromJson(json);
      expect(model.feasibilityLabel, isNull);
    });
  });
}

