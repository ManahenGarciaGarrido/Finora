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
  bool _pushTransactions = true; // RF-31
  bool _pushBudgetAlerts = true; // RF-32
  bool _pushGoalReminders = true; // RF-33
  double _minAmount = 0; // RF-31: filtro importe mínimo
  bool _quietHours = false;
  TimeOfDay _quietStart = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _quietEnd = const TimeOfDay(hour: 8, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _loading = true;
    });
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
      setState(() {
        _loading = false;
      });
    }
  }

  TimeOfDay _parseTime(String s) {
    final parts = s.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _save() async {
    setState(() {
      _saving = true;
    });
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
          const SnackBar(
            content: Text('Configuración guardada'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── UI ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        title: Text('Notificaciones', style: AppTypography.titleMedium()),
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
                  : const Text('Guardar'),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildInfoBanner(),
                const SizedBox(height: 16),
                _buildSection(
                  title: 'Tipos de notificación',
                  children: [
                    _buildToggle(
                      icon: Icons.receipt_long_rounded,
                      iconColor: AppColors.info,
                      title: 'Nuevas transacciones',
                      subtitle:
                          'Notificación al detectar una nueva transacción bancaria',
                      value: _pushTransactions,
                      onChanged: (v) => setState(() => _pushTransactions = v),
                    ),
                    _buildDivider(),
                    _buildToggle(
                      icon: Icons.account_balance_wallet_rounded,
                      iconColor: AppColors.warning,
                      title: 'Alertas de presupuesto',
                      subtitle:
                          'Aviso al superar el 80% y 100% de un presupuesto',
                      value: _pushBudgetAlerts,
                      onChanged: (v) => setState(() => _pushBudgetAlerts = v),
                    ),
                    _buildDivider(),
                    _buildToggle(
                      icon: Icons.savings_rounded,
                      iconColor: AppColors.savings,
                      title: 'Progreso de objetivos',
                      subtitle:
                          'Recordatorio semanal del avance de tus metas de ahorro',
                      value: _pushGoalReminders,
                      onChanged: (v) => setState(() => _pushGoalReminders = v),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_pushTransactions) ...[
                  _buildSection(
                    title: 'Filtros',
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
                                        'Importe mínimo',
                                        style: AppTypography.bodyMedium(),
                                      ),
                                      Text(
                                        'No notificar transacciones por debajo de este importe',
                                        style: AppTypography.bodySmall(
                                          color: AppColors.gray500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  _minAmount == 0
                                      ? 'Sin límite'
                                      : '€${_minAmount.toStringAsFixed(0)}',
                                  style: AppTypography.titleSmall(
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Semantics(
                              label:
                                  'Importe mínimo para notificaciones: ${_minAmount.toStringAsFixed(0)} euros',
                              child: Slider(
                                value: _minAmount,
                                min: 0,
                                max: 200,
                                divisions: 20,
                                label: _minAmount == 0
                                    ? 'Sin límite'
                                    : '€${_minAmount.toStringAsFixed(0)}',
                                onChanged: (v) =>
                                    setState(() => _minAmount = v),
                                activeColor: AppColors.primary,
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Sin límite',
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
                  title: 'Horario silencioso',
                  children: [
                    _buildToggle(
                      icon: Icons.bedtime_rounded,
                      iconColor: AppColors.gray500,
                      title: 'Horas de silencio',
                      subtitle:
                          'No recibir notificaciones durante este horario',
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
                                'Inicio',
                                _quietStart,
                                (t) => setState(() => _quietStart = t),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _timeButton(
                                'Fin',
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
            ),
    );
  }

  Widget _buildInfoBanner() {
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
              'Las notificaciones requieren permisos en tu dispositivo. Asegúrate de haberlos concedido en Ajustes del sistema.',
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

  Widget _buildToggle({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Semantics(
      label: '$title: ${value ? "activado" : "desactivado"}',
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
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
