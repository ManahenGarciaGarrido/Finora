/// Página de Configuración de Notificaciones — RF-31 + RF-32 + RF-33
///
/// RF-31: Notificaciones push de nuevas transacciones
/// RF-32: Alertas de exceso de presupuesto (configuración)
/// RF-33: Recordatorios semanales de progreso de objetivos
///  - Toggle por tipo de notificación
///  - Filtro de importe mínimo para transacciones
///  - Modo silencioso por horario nocturno
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/di/injection_container.dart' as di;
import 'package:finora_frontend/core/l10n/app_localizations.dart';
import '../../../../core/responsive/breakpoints.dart';

/// RF-31/RF-32/RF-33: Configuración granular de notificaciones push.
class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  final _apiClient = di.sl<ApiClient>();

  bool _loading = true;
  bool _saving = false;

  // Preferencias
  bool _pushTransactions = true;
  bool _pushBudgetAlerts = true;
  bool _pushGoalReminders = true;
  double _minAmount = 0;
  bool _quietHours = false;
  TimeOfDay _quietStart = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _quietEnd = const TimeOfDay(hour: 8, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _loading = true);
    try {
      final res = await _apiClient.get('/notifications/settings');
      final d = res.data as Map<String, dynamic>;

      setState(() {
        _pushTransactions = d['push_new_transactions'] as bool? ?? true;
        _pushBudgetAlerts = d['push_budget_alerts'] as bool? ?? true;
        _pushGoalReminders = d['push_goal_reminders'] as bool? ?? true;
        _minAmount = (d['push_min_amount'] as num?)?.toDouble() ?? 0;
        _quietHours = d['push_quiet_hours_enabled'] as bool? ?? false;

        final startStr = d['push_quiet_start'] as String? ?? '22:00';
        final endStr = d['push_quiet_end'] as String? ?? '08:00';
        _quietStart = _parseTime(startStr);
        _quietEnd = _parseTime(endStr);
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  TimeOfDay _parseTime(String s) {
    final parts = s.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _save() async {
    final s = AppLocalizations.of(context);
    setState(() => _saving = true);
    try {
      await _apiClient.put(
        '/notifications/settings',
        data: {
          'push_new_transactions': _pushTransactions,
          'push_budget_alerts': _pushBudgetAlerts,
          'push_goal_reminders': _pushGoalReminders,
          'push_min_amount': _minAmount,
          'push_quiet_hours_enabled': _quietHours,
          'push_quiet_start': _formatTime(_quietStart),
          'push_quiet_end': _formatTime(_quietEnd),
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s.settingsSavedMsg),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s.errorSavingSettingsMsg(e.toString())),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final responsive = ResponsiveUtils(context);
    Widget buildBody() => _loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
                _buildInfoBanner(s),
                const SizedBox(height: 16),
                _buildSection(
                  title: s.notificationTypesSection,
                  children: [
                    _buildToggle(
                      s,
                      icon: Icons.receipt_long_rounded,
                      iconColor: AppColors.info,
                      title: s.newTransactionsTitle,
                      subtitle: s.newTransactionsSubtitle,
                      value: _pushTransactions,
                      onChanged: (v) => setState(() => _pushTransactions = v),
                    ),
                    _buildDivider(),
                    _buildToggle(
                      s,
                      icon: Icons.account_balance_wallet_rounded,
                      iconColor: AppColors.warning,
                      title: s.budgetAlertsTitle,
                      subtitle: s.budgetAlertsSubtitle,
                      value: _pushBudgetAlerts,
                      onChanged: (v) => setState(() => _pushBudgetAlerts = v),
                    ),
                    _buildDivider(),
                    _buildToggle(
                      s,
                      icon: Icons.savings_rounded,
                      iconColor: AppColors.savings,
                      title: s.goalProgressTitle,
                      subtitle: s.goalProgressSubtitle,
                      value: _pushGoalReminders,
                      onChanged: (v) => setState(() => _pushGoalReminders = v),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_pushTransactions) ...[
                  _buildSection(
                    title: s.filtersSection,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        s.minAmountTitle,
                                        style: AppTypography.bodyMedium(),
                                      ),
                                      Text(
                                        s.minAmountSubtitle,
                                        style: AppTypography.bodySmall(
                                          color: AppColors.gray500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  _minAmount == 0
                                      ? s.noLimitLabel
                                      : '€${_minAmount.toStringAsFixed(0)}',
                                  style: AppTypography.titleSmall(
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Slider(
                              value: _minAmount,
                              min: 0,
                              max: 200,
                              divisions: 20,
                              onChanged: (v) => setState(() => _minAmount = v),
                              activeColor: AppColors.primary,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  s.noLimitLabel,
                                  style: AppTypography.labelSmall(
                                    color: AppColors.gray400,
                                  ),
                                ),
                                Text(
                                  '€200+',
                                  style: AppTypography.labelSmall(
                                    color: AppColors.gray400,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                _buildSection(
                  title: s.quietHoursSection,
                  children: [
                    _buildToggle(
                      s,
                      icon: Icons.bedtime_rounded,
                      iconColor: AppColors.gray500,
                      title: s.quietHoursTitle,
                      subtitle: s.quietHoursSubtitle,
                      value: _quietHours,
                      onChanged: (v) => setState(() => _quietHours = v),
                    ),
                    if (_quietHours) ...[
                      _buildDivider(),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _timeButton(
                                s.startLabel,
                                _quietStart,
                                (t) => setState(() => _quietStart = t),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _timeButton(
                                s.endLabel,
                                _quietEnd,
                                (t) => setState(() => _quietEnd = t),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            );
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        title: Text(s.notificationsTitle, style: AppTypography.titleMedium()),
        leading: const BackButton(),
        actions: [
          if (!_loading)
            TextButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(s.save),
            ),
        ],
      ),
      body: responsive.isTablet
          ? Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: buildBody(),
              ),
            )
          : buildBody(),
    );
  }

  Widget _buildInfoBanner(AppLocalizations s) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.infoSoft,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: AppColors.info, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              s.notificationsPermissionInfo,
              style: AppTypography.bodySmall(color: AppColors.infoDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: AppTypography.labelSmall(color: AppColors.gray500),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.gray200),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildToggle(
    AppLocalizations s, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Semantics(
      label: s.toggleStatusSemantics(title, value),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        activeTrackColor: AppColors.primary,
        activeThumbColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        secondary: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        title: Text(title, style: AppTypography.bodyMedium()),
        subtitle: Text(
          subtitle,
          style: AppTypography.bodySmall(color: AppColors.gray500),
        ),
      ),
    );
  }

  Widget _buildDivider() =>
      Divider(height: 1, indent: 14, color: AppColors.gray100);

  Widget _timeButton(
    String label,
    TimeOfDay time,
    ValueChanged<TimeOfDay> onChanged,
  ) {
    return OutlinedButton(
      onPressed: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: time,
        );
        if (picked != null) onChanged(picked);
      },
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        side: BorderSide(color: AppColors.gray300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTypography.labelSmall(color: AppColors.gray500),
          ),
          Text(time.format(context), style: AppTypography.bodyMedium()),
        ],
      ),
    );
  }
}