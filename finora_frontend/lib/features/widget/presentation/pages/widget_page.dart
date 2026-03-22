import 'package:flutter/material.dart' hide WidgetState;
import 'package:flutter/material.dart' as mat show WidgetState;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import 'package:finora_frontend/core/l10n/app_localizations.dart';
import '../../../../core/responsive/breakpoints.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/services/currency_service.dart';
import 'package:finora_frontend/shared/widgets/skeleton_loader.dart';
import '../bloc/widget_bloc.dart';
import '../bloc/widget_event.dart';
import '../bloc/widget_state.dart';
import '../../domain/entities/widget_data_entity.dart';
import '../../domain/entities/widget_settings_entity.dart';
import '../../services/wearable_channel_service.dart';

class WidgetPage extends StatefulWidget {
  const WidgetPage({super.key});

  @override
  State<WidgetPage> createState() => _WidgetPageState();
}

class _WidgetPageState extends State<WidgetPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  WidgetDataEntity? _data;
  WidgetSettingsEntity? _settings;
  bool _wearOsConnected = false;
  final bool _appleWatchConnected = false;
  bool _checkingWear = false;

  final _wearable = WearableChannelService();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _checkWearableConnection();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _checkWearableConnection() async {
    if (!mounted) return;
    setState(() => _checkingWear = true);
    final connected = await _wearable.isConnected();
    if (mounted) {
      setState(() {
        _wearOsConnected = connected;
        _checkingWear = false;
      });
    }
  }

  Future<void> _syncToWatch(BuildContext ctx) async {
    if (_data == null) return;
    setState(() => _checkingWear = true);
    final sent = await _wearable.pushData(_data!);
    if (mounted) {
      setState(() => _checkingWear = false);
      final s = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(sent
            ? '${s.wearableSyncBtn}: OK ✓'
            : s.wearableNotConnected),
        backgroundColor: sent ? AppColors.success : AppColors.gray600,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return BlocProvider(
      create: (ctx) => di.sl<WidgetBloc>()
        ..add(const LoadWidgetData())
        ..add(const LoadWidgetSettings()),
      child: BlocConsumer<WidgetBloc, WidgetState>(
        listener: (ctx, state) {
          if (state is WidgetDataLoaded) {
            setState(() => _data = state.data);
          } else if (state is WidgetSettingsLoaded) {
            setState(() => _settings = state.settings);
          } else if (state is WidgetSettingsSaved) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(s.widgetSettingsTitle),
              backgroundColor: AppColors.success,
            ));
          } else if (state is WidgetPushed) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(s.widgetUpdateSuccess),
              backgroundColor: AppColors.success,
            ));
          } else if (state is WidgetError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ));
          }
        },
        builder: (ctx, state) {
          return Scaffold(
            backgroundColor: AppColors.backgroundLight,
            appBar: AppBar(
              backgroundColor: AppColors.surfaceLight,
              elevation: 0,
              title: Text(s.widgetTitle, style: AppTypography.titleMedium()),
              leading: const BackButton(),
              bottom: TabBar(
                controller: _tabs,
                labelColor: AppColors.primary,
                indicatorColor: AppColors.primary,
                tabs: [
                  Tab(text: s.widgetSettingsTitle),
                  Tab(text: s.widgetWearableTitle),
                  Tab(text: s.widgetMetricsLabel),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: s.widgetUpdateSuccess,
                  onPressed: () =>
                      ctx.read<WidgetBloc>().add(const RefreshAndPushWidget()),
                ),
              ],
            ),
            body: Builder(builder: (bctx) {
              final responsive = ResponsiveUtils(bctx);
              final tabBody = state is WidgetLoading
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: SkeletonListLoader(count: 4, cardHeight: 70))
                  : TabBarView(
                      controller: _tabs,
                      children: [
                        _buildSettingsTab(ctx, s),
                        _buildWearableTab(ctx, s),
                        _buildPreviewTab(ctx, s),
                      ],
                    );
              if (responsive.isTablet) {
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: tabBody,
                  ),
                );
              }
              return tabBody;
            }),
          );
        },
      ),
    );
  }

  Widget _buildSettingsTab(BuildContext ctx, dynamic s) {
    if (_settings == null) {
      return Center(
          child: Text(s.loading,
              style: AppTypography.bodyMedium(color: AppColors.gray500)));
    }
    bool showBalance = _settings!.showBalance;
    bool showTodaySpent = _settings!.showTodaySpent;
    bool showBudgetPct = _settings!.showBudgetPct;
    String darkMode = _settings!.darkMode;

    return StatefulBuilder(builder: (_, setLocal) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(s.widgetMetricsLabel, style: AppTypography.titleSmall()),
          const SizedBox(height: 12),
          // ── Widget preview on dark bg ─────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    const Spacer(),
                    Text('Finora',
                        style:
                            AppTypography.bodySmall(color: Colors.white54)),
                  ],
                ),
                const SizedBox(height: 8),
                _widgetToggleChip(
                  icon: Icons.account_balance_wallet_rounded,
                  label: s.widgetBalance,
                  active: showBalance,
                  onTap: () => setLocal(() => showBalance = !showBalance),
                ),
                const SizedBox(height: 8),
                _widgetToggleChip(
                  icon: Icons.shopping_bag_rounded,
                  label: s.widgetTodaySpent,
                  active: showTodaySpent,
                  onTap: () =>
                      setLocal(() => showTodaySpent = !showTodaySpent),
                ),
                const SizedBox(height: 8),
                _widgetToggleChip(
                  icon: Icons.pie_chart_rounded,
                  label: s.widgetBudgetPct,
                  active: showBudgetPct,
                  onTap: () =>
                      setLocal(() => showBudgetPct = !showBudgetPct),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 4),
          Text(s.widgetDarkModeAuto, style: AppTypography.titleSmall()),
          const SizedBox(height: 12),
          // ── Theme selector with correct text color ────────────────────────
          SegmentedButton<String>(
            style: ButtonStyle(
              foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                if (states.contains(mat.WidgetState.selected)) {
                  return Colors.black87;
                }
                return AppColors.gray600;
              }),
              backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                if (states.contains(mat.WidgetState.selected)) {
                  return AppColors.primarySoft;
                }
                return Colors.transparent;
              }),
            ),
            segments: const [
              ButtonSegment(
                value: 'light',
                label: Text('Light'),
                icon: Icon(Icons.light_mode_rounded),
              ),
              ButtonSegment(
                value: 'auto',
                label: Text('Auto'),
                icon: Icon(Icons.brightness_auto_rounded),
              ),
              ButtonSegment(
                value: 'dark',
                label: Text('Dark'),
                icon: Icon(Icons.dark_mode_rounded),
              ),
            ],
            selected: {darkMode},
            onSelectionChanged: (v) => setLocal(() => darkMode = v.first),
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: () => ctx.read<WidgetBloc>().add(SaveWidgetSettings(
                    showBalance: showBalance,
                    showTodaySpent: showTodaySpent,
                    showBudgetPct: showBudgetPct,
                    darkMode: darkMode,
                  )),
              icon: const Icon(Icons.save_rounded),
              label: Text(s.save),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.gray100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              s.widgetAddInstructions,
              style: AppTypography.bodySmall(color: AppColors.gray500),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
    });
  }

  /// A dark-background toggle chip for the widget preview.
  /// Circle is always white on the dark background.
  Widget _widgetToggleChip({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: active
              ? Colors.white.withValues(alpha:0.15)
              : Colors.white.withValues(alpha:0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active
                ? Colors.white.withValues(alpha:0.6)
                : Colors.white.withValues(alpha:0.2),
          ),
        ),
        child: Row(
          children: [
            // White circle indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active ? Colors.white : Colors.white24,
              ),
              child: Icon(
                icon,
                size: 16,
                color: active ? const Color(0xFF1A1A2E) : Colors.white54,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: active ? Colors.white : Colors.white54,
                  fontSize: 13,
                  fontWeight:
                      active ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            Icon(
              active
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: active ? Colors.white : Colors.white38,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWearableTab(BuildContext ctx, dynamic s) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Connection status banner
        if (_checkingWear)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2)),
                const SizedBox(width: 12),
                Text(s.wearableConnecting,
                    style:
                        AppTypography.bodyMedium(color: AppColors.primary)),
              ],
            ),
          ),
        Text(s.widgetWearableTitle, style: AppTypography.titleSmall()),
        const SizedBox(height: 16),
        _wearableCard(
          icon: Icons.watch_rounded,
          title: s.widgetWearOS,
          connected: _wearOsConnected,
          instructions: s.wearableInstructions,
          s: s,
          onSync: () => _syncToWatch(ctx),
          onRefresh: _checkWearableConnection,
        ),
        const SizedBox(height: 12),
        _wearableCard(
          icon: Icons.watch_outlined,
          title: s.widgetAppleWatch,
          connected: _appleWatchConnected,
          instructions: s.wearableInstructions,
          s: s,
          onSync: null, // Apple Watch not supported on Android
          onRefresh: null,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.gray100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            '• Wear OS: instala la compañera Finora Wear en tu reloj desde Play Store.\n'
            '• Apple Watch: compatible vía app Finora para iOS (próximamente).\n'
            '• Los datos se sincronizan automáticamente cada vez que abres la app.',
            style: TextStyle(fontSize: 12, color: Color(0xFF888888)),
          ),
        ),
      ],
    );
  }

  Widget _wearableCard({
    required IconData icon,
    required String title,
    required bool connected,
    required String instructions,
    required dynamic s,
    required VoidCallback? onSync,
    required VoidCallback? onRefresh,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: connected ? AppColors.success.withValues(alpha:0.4) : AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: connected ? AppColors.success : AppColors.primary, size: 28),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(title, style: AppTypography.titleSmall())),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: connected
                      ? AppColors.successSoft
                      : AppColors.gray100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  connected ? s.wearableConnected : s.wearableNotConnected,
                  style: AppTypography.bodySmall(
                      color: connected
                          ? AppColors.success
                          : AppColors.gray500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(instructions,
              style: AppTypography.bodySmall(color: AppColors.gray500)),
          if (onSync != null || onRefresh != null) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                if (onRefresh != null)
                  OutlinedButton.icon(
                    onPressed: onRefresh,
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Detectar'),
                    style: OutlinedButton.styleFrom(
                        minimumSize: const Size(64, 36),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        textStyle: const TextStyle(fontSize: 12)),
                  ),
                if (onSync != null && connected)
                  FilledButton.icon(
                    onPressed: onSync,
                    icon: const Icon(Icons.sync_rounded, size: 16),
                    label: Text(s.wearableSyncBtn),
                    style: FilledButton.styleFrom(
                        minimumSize: const Size(64, 36),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        textStyle: const TextStyle(fontSize: 12)),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPreviewTab(BuildContext ctx, dynamic s) {
    final fmt = CurrencyService().format;
    if (_data == null) {
      return Center(
          child: Text(s.noData,
              style: AppTypography.bodyMedium(color: AppColors.gray500)));
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.widgetMetricsLabel, style: AppTypography.titleSmall()),
          const SizedBox(height: 16),
          // Widget preview — dark theme mockup
          SizedBox(
            width: double.infinity,
            child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha:0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Finora',
                        style: TextStyle(
                            color: Colors.white38,
                            fontSize: 11,
                            fontFamily:
                                AppTypography.bodyMedium().fontFamily)),
                    Icon(Icons.more_horiz_rounded,
                        color: Colors.white38, size: 16),
                  ],
                ),
                const SizedBox(height: 8),
                Text(fmt(_data!.balance),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Container(
                    height: 1,
                    color: Colors.white.withValues(alpha:0.1)),
                const SizedBox(height: 8),
                _previewRow(
                    s.widgetTodaySpent, fmt(_data!.todaySpent)),
                const SizedBox(height: 4),
                _previewRow(s.widgetBudgetPct,
                    '${_data!.budgetPct}%',
                    valueColor: _data!.budgetPct > 80
                        ? Colors.orangeAccent
                        : const Color(0xFF6C63FF)),
                if (_data!.activeGoal != null) ...[
                  const SizedBox(height: 4),
                  _previewRow(
                    _data!.activeGoal!.name,
                    '${_data!.activeGoal!.pct}%',
                    valueColor: Colors.greenAccent,
                  ),
                ],
                const SizedBox(height: 10),
                Text(
                  '${s.widgetLastUpdated}: ${_formatTime(_data!.updatedAt)}',
                  style: const TextStyle(color: Colors.white24, fontSize: 9),
                ),
              ],
            ),
          ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () =>
                ctx.read<WidgetBloc>().add(const RefreshAndPushWidget()),
            icon: const Icon(Icons.sync_rounded),
            label: Text(s.widgetLastUpdated),
          ),
        ],
      ),
    );
  }

  Widget _previewRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white54, fontSize: 11)),
        Text(value,
            style: TextStyle(
                color: valueColor ?? Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w600)),
      ],
    );
  }

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }
}