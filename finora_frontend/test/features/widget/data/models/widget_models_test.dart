import 'package:flutter_test/flutter_test.dart';
import 'package:finora_frontend/features/widget/data/models/widget_models.dart';
import 'package:finora_frontend/features/widget/domain/entities/widget_data_entity.dart';
import 'package:finora_frontend/features/widget/domain/entities/widget_settings_entity.dart';

void main() {
  // ── WidgetActiveGoalModel ─────────────────────────────────────────────────
  group('WidgetActiveGoalModel.fromJson', () {
    test('mapea todos los campos correctamente', () {
      final json = <String, dynamic>{
        'name': 'Vacaciones',
        'current': 800.0,
        'target': 2000.0,
        'pct': 40,
      };

      final model = WidgetActiveGoalModel.fromJson(json);

      expect(model.name, 'Vacaciones');
      expect(model.current, 800.0);
      expect(model.target, 2000.0);
      expect(model.pct, 40);
    });

    test('usa valores por defecto cuando son null', () {
      final model = WidgetActiveGoalModel.fromJson(<String, dynamic>{
        'name': null,
        'current': null,
        'target': null,
        'pct': null,
      });

      expect(model.name, '');
      expect(model.current, 0.0);
      expect(model.target, 0.0);
      expect(model.pct, 0);
    });

    test('convierte valores numéricos desde String', () {
      final model = WidgetActiveGoalModel.fromJson(<String, dynamic>{
        'name': 'Meta',
        'current': '500.0',
        'target': '1000.0',
        'pct': '50',
      });

      expect(model.current, 500.0);
      expect(model.target, 1000.0);
      expect(model.pct, 50);
    });
  });

  // ── WidgetDataModel ───────────────────────────────────────────────────────
  group('WidgetDataModel.fromJson', () {
    test('mapea todos los campos incluyendo activeGoal', () {
      final json = <String, dynamic>{
        'balance': 1500.0,
        'today_spent': 45.0,
        'budget_pct': 60,
        'active_goal': {
          'name': 'Vacaciones',
          'current': 800.0,
          'target': 2000.0,
          'pct': 40,
        },
        'updated_at': '2024-06-01T10:00:00.000Z',
      };

      final model = WidgetDataModel.fromJson(json);

      expect(model.balance, 1500.0);
      expect(model.todaySpent, 45.0);
      expect(model.budgetPct, 60);
      expect(model.activeGoal, isNotNull);
      expect(model.activeGoal!.name, 'Vacaciones');
      expect(model.updatedAt, '2024-06-01T10:00:00.000Z');
    });

    test('activeGoal es null cuando no está en el JSON', () {
      final model = WidgetDataModel.fromJson(<String, dynamic>{
        'balance': 1000.0,
        'today_spent': 0.0,
        'budget_pct': 0,
        'active_goal': null,
        'updated_at': '2024-06-01',
      });

      expect(model.activeGoal, isNull);
    });

    test('usa valores por defecto cuando son null', () {
      final model = WidgetDataModel.fromJson(<String, dynamic>{
        'balance': null,
        'today_spent': null,
        'budget_pct': null,
        'updated_at': null,
      });

      expect(model.balance, 0.0);
      expect(model.todaySpent, 0.0);
      expect(model.budgetPct, 0);
      expect(model.updatedAt, '');
    });

    test('es instancia de WidgetDataEntity', () {
      final model = WidgetDataModel.fromJson(<String, dynamic>{
        'balance': 0.0,
        'today_spent': 0.0,
        'budget_pct': 0,
        'updated_at': '2024-01-01',
      });
      expect(model, isA<WidgetDataEntity>());
    });
  });

  // ── WidgetSettingsModel ───────────────────────────────────────────────────
  group('WidgetSettingsModel.fromJson', () {
    test('mapea todos los campos correctamente', () {
      final json = <String, dynamic>{
        'show_balance': true,
        'show_today_spent': false,
        'show_budget_pct': true,
        'dark_mode': 'dark',
      };

      final model = WidgetSettingsModel.fromJson(json);

      expect(model.showBalance, true);
      expect(model.showTodaySpent, false);
      expect(model.showBudgetPct, true);
      expect(model.darkMode, 'dark');
    });

    test('campos booleanos usan true por defecto cuando son null', () {
      final model = WidgetSettingsModel.fromJson(<String, dynamic>{
        'show_balance': null,
        'show_today_spent': null,
        'show_budget_pct': null,
        'dark_mode': null,
      });

      expect(model.showBalance, true);
      expect(model.showTodaySpent, true);
      expect(model.showBudgetPct, true);
      expect(model.darkMode, 'auto');
    });

    test('acepta booleanos desde String "true"/"false"', () {
      final model = WidgetSettingsModel.fromJson(<String, dynamic>{
        'show_balance': 'false',
        'show_today_spent': 'true',
        'show_budget_pct': 'false',
        'dark_mode': 'light',
      });

      expect(model.showBalance, false);
      expect(model.showTodaySpent, true);
    });

    test('es instancia de WidgetSettingsEntity', () {
      final model = WidgetSettingsModel.fromJson(<String, dynamic>{
        'dark_mode': 'auto',
      });
      expect(model, isA<WidgetSettingsEntity>());
    });
  });

  // ── WidgetSettingsModel.toJson ────────────────────────────────────────────
  group('WidgetSettingsModel.toJson', () {
    test('serializa correctamente', () {
      const model = WidgetSettingsModel(
        showBalance: true,
        showTodaySpent: false,
        showBudgetPct: true,
        darkMode: 'light',
      );

      final json = model.toJson();

      expect(json['show_balance'], true);
      expect(json['show_today_spent'], false);
      expect(json['show_budget_pct'], true);
      expect(json['dark_mode'], 'light');
    });
  });
}

