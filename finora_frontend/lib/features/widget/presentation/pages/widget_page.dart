import 'package:flutter/material.dart' hide WidgetState;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/services/currency_service.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import '../bloc/widget_bloc.dart';
import '../bloc/widget_event.dart';
import '../bloc/widget_state.dart';
import '../../domain/entities/widget_data_entity.dart';
import '../../domain/entities/widget_settings_entity.dart';

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

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(s.widgetSettingsTitle),
                backgroundColor: AppColors.success,
              ),
            );
          } else if (state is WidgetPushed) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(s.widgetLastUpdated),
                backgroundColor: AppColors.success,
              ),
            );
          } else if (state is WidgetError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
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
                  onPressed: () =>
                      ctx.read<WidgetBloc>().add(const RefreshAndPushWidget()),
                ),
              ],
            ),
            body: state is WidgetLoading
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: SkeletonListLoader(count: 4, cardHeight: 70),
                  )
                : TabBarView(
                    controller: _tabs,
                    children: [
                      _buildSettingsTab(ctx, s),
                      _buildWearableTab(ctx, s),
                      _buildPreviewTab(ctx, s),
                    ],
                  ),
          );
        },
      ),
    );
  }

  Widget _buildSettingsTab(BuildContext ctx, dynamic s) {
    if (_settings == null) {
      return Center(
        child: Text(
          s.loading,
          style: AppTypography.bodyMedium(color: AppColors.gray500),
        ),
      );
    }
    bool showBalance = _settings!.showBalance;
    bool showTodaySpent = _settings!.showTodaySpent;
    bool showBudgetPct = _settings!.showBudgetPct;
    String darkMode = _settings!.darkMode;

    return StatefulBuilder(
      builder: (_, setLocal) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(s.widgetSettingsTitle, style: AppTypography.titleSmall()),
            const SizedBox(height: 12),
            SwitchListTile(
              title: Text(s.widgetBalance),
              value: showBalance,
              onChanged: (v) => setLocal(() => showBalance = v),
              activeThumbColor: AppColors.primary,
            ),
            SwitchListTile(
              title: Text(s.widgetTodaySpent),
              value: showTodaySpent,
              onChanged: (v) => setLocal(() => showTodaySpent = v),
              activeThumbColor: AppColors.primary,
            ),
            SwitchListTile(
              title: Text(s.widgetBudgetPct),
              value: showBudgetPct,
              onChanged: (v) => setLocal(() => showBudgetPct = v),
              activeThumbColor: AppColors.primary,
            ),
            const Divider(),
            Text(s.widgetDarkModeAuto, style: AppTypography.titleSmall()),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'light', label: Text('Light')),
                ButtonSegment(value: 'auto', label: Text('Auto')),
                ButtonSegment(value: 'dark', label: Text('Dark')),
              ],
              selected: {darkMode},
              onSelectionChanged: (v) => setLocal(() => darkMode = v.first),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => ctx.read<WidgetBloc>().add(
                SaveWidgetSettings(
                  showBalance: showBalance,
                  showTodaySpent: showTodaySpent,
                  showBudgetPct: showBudgetPct,
                  darkMode: darkMode,
                ),
              ),
              child: Text(s.save),
            ),
            const SizedBox(height: 12),
            Text(
              s.widgetAddInstructions,
              style: AppTypography.bodySmall(color: AppColors.gray500),
              textAlign: TextAlign.center,
            ),
          ],
        );
      },
    );
  }

  Widget _buildWearableTab(BuildContext ctx, dynamic s) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(s.widgetWearableTitle, style: AppTypography.titleSmall()),
        const SizedBox(height: 16),
        _wearableCard(
          icon: Icons.watch_rounded,
          title: s.widgetWearOS,
          connected: false,
          instructions: s.wearableInstructions,
          s: s,
        ),
        const SizedBox(height: 12),
        _wearableCard(
          icon: Icons.watch_outlined,
          title: s.widgetAppleWatch,
          connected: false,
          instructions: s.wearableInstructions,
          s: s,
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
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 28),
              const SizedBox(width: 12),
              Expanded(child: Text(title, style: AppTypography.titleSmall())),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: connected ? AppColors.successSoft : AppColors.gray100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  connected ? s.wearableConnected : s.wearableNotConnected,
                  style: AppTypography.bodySmall(
                    color: connected ? AppColors.success : AppColors.gray500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            instructions,
            style: AppTypography.bodySmall(color: AppColors.gray500),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewTab(BuildContext ctx, dynamic s) {
    final fmt = CurrencyService().format;
    if (_data == null) {
      return Center(
        child: Text(
          s.noData,
          style: AppTypography.bodyMedium(color: AppColors.gray500),
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(s.widgetMetricsLabel, style: AppTypography.titleSmall()),
          const SizedBox(height: 16),
          // Widget preview mockup
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary, width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Finora',
                  style: AppTypography.bodySmall(color: AppColors.gray500),
                ),
                const SizedBox(height: 4),
                Text(fmt(_data!.balance), style: AppTypography.displaySmall()),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      s.widgetTodaySpent,
                      style: AppTypography.bodySmall(color: AppColors.gray500),
                    ),
                    Text(
                      fmt(_data!.todaySpent),
                      style: AppTypography.bodySmall(),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      s.widgetBudgetPct,
                      style: AppTypography.bodySmall(color: AppColors.gray500),
                    ),
                    Text(
                      '${_data!.budgetPct}%',
                      style: AppTypography.bodySmall(color: AppColors.primary),
                    ),
                  ],
                ),
                if (_data!.activeGoal != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _data!.activeGoal!.name,
                          style: AppTypography.bodySmall(
                            color: AppColors.gray500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${_data!.activeGoal!.pct}%',
                        style: AppTypography.bodySmall(
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  '${s.widgetLastUpdated}: ${_formatTime(_data!.updatedAt)}',
                  style: AppTypography.bodySmall(color: AppColors.gray400),
                ),
              ],
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

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }
}
