class WidgetSettingsEntity {
  final bool showBalance;
  final bool showTodaySpent;
  final bool showBudgetPct;
  final String darkMode; // 'auto', 'light', 'dark'

  const WidgetSettingsEntity({
    this.showBalance = true,
    this.showTodaySpent = true,
    this.showBudgetPct = true,
    this.darkMode = 'auto',
  });
}
