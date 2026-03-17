abstract class WidgetEvent {
  const WidgetEvent();
}

class LoadWidgetData extends WidgetEvent {
  const LoadWidgetData();
}

class LoadWidgetSettings extends WidgetEvent {
  const LoadWidgetSettings();
}

class SaveWidgetSettings extends WidgetEvent {
  final bool showBalance;
  final bool showTodaySpent;
  final bool showBudgetPct;
  final String darkMode;

  const SaveWidgetSettings({
    required this.showBalance,
    required this.showTodaySpent,
    required this.showBudgetPct,
    required this.darkMode,
  });
}

class RefreshAndPushWidget extends WidgetEvent {
  const RefreshAndPushWidget();
}
