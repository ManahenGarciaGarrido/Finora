import 'package:finora_frontend/features/widget/domain/entities/widget_data_entity.dart';
import 'package:flutter/services.dart';
import '../../../../core/services/currency_service.dart';

/// Service to communicate with Wear OS devices via MethodChannel.
/// Uses Wearable Data Layer API on the Android side.
/// On non-Android platforms or devices without Wear OS, calls return false.
class WearableChannelService {
  static const _channel = MethodChannel('com.finora.watch/wearable');
  final _fmt = CurrencyService().format;

  /// Returns true if at least one Wear OS node is currently connected.
  Future<bool> isConnected() async {
    try {
      final result = await _channel.invokeMethod<bool>('checkConnection');
      return result ?? false;
    } on MissingPluginException {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Pushes financial data to all connected Wear OS nodes.
  /// Returns true if data was sent to at least one node.
  Future<bool> pushData(WidgetDataEntity data) async {
    try {
      final result = await _channel.invokeMethod<bool>('pushData', {
        'balance': _fmt(data.balance),
        'today_spent': _fmt(data.todaySpent),
        'budget_pct': data.budgetPct,
        'goal_name': data.activeGoal?.name ?? '',
        'goal_pct': data.activeGoal?.pct ?? 0,
      });
      return result ?? false;
    } on MissingPluginException {
      return false;
    } catch (_) {
      return false;
    }
  }
}
