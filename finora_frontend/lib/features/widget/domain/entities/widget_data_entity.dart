class WidgetActiveGoal {
  final String name;
  final double current;
  final double target;
  final int pct;

  const WidgetActiveGoal({
    required this.name,
    required this.current,
    required this.target,
    required this.pct,
  });
}

class WidgetDataEntity {
  final double balance;
  final double todaySpent;
  final int budgetPct;
  final WidgetActiveGoal? activeGoal;
  final String updatedAt;

  const WidgetDataEntity({
    required this.balance,
    required this.todaySpent,
    required this.budgetPct,
    this.activeGoal,
    required this.updatedAt,
  });
}
