import '../../domain/entities/widget_data_entity.dart';
import '../../domain/entities/widget_settings_entity.dart';

double _d(dynamic v, [double fallback = 0.0]) =>
    v == null ? fallback : double.tryParse(v.toString()) ?? fallback;

int _i(dynamic v, [int fallback = 0]) =>
    v == null ? fallback : int.tryParse(v.toString()) ?? fallback;

bool _b(dynamic v, [bool fallback = true]) {
  if (v == null) return fallback;
  if (v is bool) return v;
  return v.toString().toLowerCase() == 'true';
}

class WidgetActiveGoalModel extends WidgetActiveGoal {
  const WidgetActiveGoalModel({
    required super.name,
    required super.current,
    required super.target,
    required super.pct,
  });

  factory WidgetActiveGoalModel.fromJson(Map<String, dynamic> j) =>
      WidgetActiveGoalModel(
        name: j['name']?.toString() ?? '',
        current: _d(j['current']),
        target: _d(j['target']),
        pct: _i(j['pct']),
      );
}

class WidgetDataModel extends WidgetDataEntity {
  const WidgetDataModel({
    required super.balance,
    required super.todaySpent,
    required super.budgetPct,
    super.activeGoal,
    required super.updatedAt,
  });

  factory WidgetDataModel.fromJson(Map<String, dynamic> j) {
    final goalJson = j['active_goal'] as Map<String, dynamic>?;
    return WidgetDataModel(
      balance: _d(j['balance']),
      todaySpent: _d(j['today_spent']),
      budgetPct: _i(j['budget_pct']),
      activeGoal: goalJson != null
          ? WidgetActiveGoalModel.fromJson(goalJson)
          : null,
      updatedAt: j['updated_at']?.toString() ?? '',
    );
  }
}

class WidgetSettingsModel extends WidgetSettingsEntity {
  const WidgetSettingsModel({
    super.showBalance,
    super.showTodaySpent,
    super.showBudgetPct,
    super.darkMode,
  });

  factory WidgetSettingsModel.fromJson(Map<String, dynamic> j) =>
      WidgetSettingsModel(
        showBalance: _b(j['show_balance']),
        showTodaySpent: _b(j['show_today_spent']),
        showBudgetPct: _b(j['show_budget_pct']),
        darkMode: j['dark_mode']?.toString() ?? 'auto',
      );

  Map<String, dynamic> toJson() => {
    'show_balance': showBalance,
    'show_today_spent': showTodaySpent,
    'show_budget_pct': showBudgetPct,
    'dark_mode': darkMode,
  };
}
