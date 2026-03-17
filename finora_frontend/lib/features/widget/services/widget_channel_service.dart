import 'package:flutter/services.dart';
import '../domain/entities/widget_data_entity.dart';
import '../../../../core/services/currency_service.dart';

/// Service to push widget data to Android AppWidget via MethodChannel.
/// On platforms other than Android, calls are silently ignored.
class WidgetChannelService {
  static const _channel = MethodChannel('com.finora.widget/update');
  final _fmt = CurrencyService().format;

  /// Push fresh widget data to Android home screen widget.
  Future<void> pushWidgetData(WidgetDataEntity data) async {
    try {
      await _channel.invokeMethod('updateWidget', {
        'balance': _fmt(data.balance),
        'today_spent': _fmt(data.todaySpent),
        'budget_pct': data.budgetPct,
        'goal_name': data.activeGoal?.name ?? '',
        'goal_pct': data.activeGoal?.pct ?? 0,
        'updated_at': _formatUpdatedAt(data.updatedAt),
      });
    } on MissingPluginException {
      // Expected on non-Android platforms or when channel is not registered.
    } catch (_) {
      // Silently ignore widget update failures.
    }
  }

  String _formatUpdatedAt(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }
}
