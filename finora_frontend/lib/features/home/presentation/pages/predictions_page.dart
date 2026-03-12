/// RF-22 / HU-09: Predicción de gastos con Machine Learning
/// RF-21 / HU-08: Recomendaciones de ahorro inteligente
/// RF-23 / HU-10: Detección de anomalías en gastos
/// RF-24 / HU-11: Identificación automática de suscripciones
/// CU-05: Visualizar predicción de gastos futuros
library;

import 'package:finora_frontend/core/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/ai_service.dart';

class PredictionsPage extends StatefulWidget {
  const PredictionsPage({super.key});

  @override
  State<PredictionsPage> createState() => _PredictionsPageState();
}

class _PredictionsPageState extends State<PredictionsPage>
    with SingleTickerProviderStateMixin {
  final AiService _aiService = sl<AiService>();

  late TabController _tabController;

  bool _loadingPredictions = true;
  bool _loadingSavings = true;
  bool _loadingAnomalies = true;
  bool _loadingSubscriptions = true;

  String? _predictionsError;
  String? _savingsError;
  String? _anomaliesError;
  String? _subscriptionsError;

  ExpensePredictionResult? _predictionsResult;
  SavingsResult? _savingsResult;
  AnomaliesResult? _anomaliesResult;
  SubscriptionsResult? _subscriptionsResult;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    _loadPredictions();
    _loadSavings();
    _loadAnomalies();
    _loadSubscriptions();
  }

  Future<void> _loadPredictions() async {
    setState(() {
      _loadingPredictions = true;
      _predictionsError = null;
    });
    try {
      final result = await _aiService.predictExpenses(months: 12);
      if (mounted) {
        setState(() {
          _predictionsResult = result;
          _loadingPredictions = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _predictionsError = e.toString();
          _loadingPredictions = false;
        });
      }
    }
  }

  Future<void> _loadSavings() async {
    setState(() {
      _loadingSavings = true;
      _savingsError = null;
    });
    try {
      final result = await _aiService.getSavingsRecommendations(months: 3);
      if (mounted) {
        setState(() {
          _savingsResult = result;
          _loadingSavings = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _savingsError = e.toString();
          _loadingSavings = false;
        });
      }
    }
  }

  String _getTranslatedCategory(BuildContext context, String categoryKey) {
    final s = AppLocalizations.of(context);

    // Normalizamos el string para que coincida sin importar mayúsculas o espacios
    final key = categoryKey.toLowerCase().trim();

    switch (key) {
      // Gastos
      case 'alimentación':
      case 'food':
        return s.nutrition; // Asegúrate de tener s.food o similar en AppStrings
      case 'transporte':
      case 'transport':
        return s.transport; // Usa s.transport
      case 'ocio':
      case 'leisure':
        return s.leisure; // Usa s.leisure
      case 'salud':
      case 'health':
        return s.health; // Usa s.health
      case 'vivienda':
      case 'housing':
        return s.housing; // Usa s.housing
      case 'servicios':
      case 'services':
        return s.services; // Usa s.services
      case 'educación':
      case 'education':
        return s.education; // Usa s.education
      case 'ropa':
      case 'clothing':
        return s.clothing; // Usa s.clothing

      // Ingresos
      case 'salario':
      case 'salary':
        return s.category; // Usa s.salary
      case 'freelance':
        return 'Freelance'; // Suele ser igual en ambos
      case 'otros ingresos':
      case 'other income':
        return s.other; // Usa s.otherIncome

      // General
      case 'otros':
      case 'others':
        return s.other;
      case 'ahorro':
      case 'saving':
        return s.saving;

      default:
        // Si no hay match, devolvemos la original capitalizada
        if (categoryKey.isEmpty) return '';
        return categoryKey[0].toUpperCase() + categoryKey.substring(1);
    }
  }

  String _getPeriodicityLabel(BuildContext context, String period) {
    final s = AppLocalizations.of(context);

    final p = period.toLowerCase().trim();

    switch (p) {
      case 'weekly':
      case 'semanal':
        return s.aiPeriodWeekly;
      case 'monthly':
      case 'mensual':
        return s.aiPeriodMonthly;
      case 'quarterly':
      case 'trimestral':
        return s.aiPeriodQuarterly;
      case 'annual':
      case 'anual':
        return s.aiPeriodAnnual;
      default:
        // Fallback por si llega un valor crudo o nulo
        return period.isNotEmpty ? period : s.unknownError;
    }
  }

  Future<void> _loadAnomalies() async {
    setState(() {
      _loadingAnomalies = true;
      _anomaliesError = null;
    });
    try {
      final result = await _aiService.detectAnomalies(months: 6);
      if (mounted) {
        setState(() {
          _anomaliesResult = result;
          _loadingAnomalies = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _anomaliesError = e.toString();
          _loadingAnomalies = false;
        });
      }
    }
  }

  Future<void> _loadSubscriptions() async {
    setState(() {
      _loadingSubscriptions = true;
      _subscriptionsError = null;
    });
    try {
      final result = await _aiService.detectSubscriptions(months: 6);
      if (mounted) {
        setState(() {
          _subscriptionsResult = result;
          _loadingSubscriptions = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _subscriptionsError = e.toString();
          _loadingSubscriptions = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: Text(
          s.aiPredictionsTitle,
          style: AppTypography.titleMedium(color: AppColors.textPrimaryLight),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.textPrimaryLight,
          ),
          tooltip: 'Volver',
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            tooltip: 'Actualizar predicciones',
            onPressed: _loadData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.gray400,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            Tab(icon: Icon(Icons.trending_up_rounded), text: s.tabPrediction),
            Tab(icon: Icon(Icons.savings_rounded), text: s.tabSavings),
            Tab(icon: Icon(Icons.warning_amber_rounded), text: s.tabAnomalies),
            Tab(icon: Icon(Icons.repeat_rounded), text: s.tabSubscriptions),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPredictionsTab(context),
          _buildSavingsTab(context),
          _buildAnomaliesTab(context),
          _buildSubscriptionsTab(context),
        ],
      ),
    );
  }

  // ── Tab 1: Predicciones de gastos ──────────────────────────────────────────

  Widget _buildPredictionsTab(BuildContext context) {
    final s = AppLocalizations.of(context);
    if (_loadingPredictions) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_predictionsError != null) {
      return _buildError(_predictionsError!, _loadPredictions);
    }
    if (_predictionsResult == null || _predictionsResult!.predictions.isEmpty) {
      return _buildEmpty(
        icon: Icons.insights_rounded,
        title: s.aiEmptyDataTitle,
        subtitle: s.aiEmptyDataSubtitle,
      );
    }
    return RefreshIndicator(
      onRefresh: _loadPredictions,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildPredictionSummaryCard(context),
          const SizedBox(height: 16),
          _buildModelInfoCard(context),
          const SizedBox(height: 16),
          // CU-05 / HU-09: Gráfico visual predicción vs último mes
          _buildPredictionComparisonChart(context),
          const SizedBox(height: 16),
          ...(_predictionsResult!.predictions.map(
            _buildCategoryPredictionCard,
          )),
        ],
      ),
    );
  }

  /// CU-05 / HU-09: Gráfico comparativo predicción vs mes anterior por categoría
  Widget _buildPredictionComparisonChart(BuildContext context) {
    final s = AppLocalizations.of(context);
    final r = _predictionsResult!;
    final topCats = r.predictions.take(5).toList();
    if (topCats.isEmpty) return const SizedBox.shrink();

    // Max valor para escalar las barras
    topCats.fold(
      0.0,
      (m, p) =>
          m > p.prediccion ? m : (m > r.lastMonthTotal ? m : p.prediccion),
    );

    return Card(
      elevation: 0,
      color: AppColors.gray50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.gray200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.bar_chart_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    s.aiPredictionVsLastMonth,
                    style: AppTypography.labelMedium(
                      color: AppColors.textPrimaryLight,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _buildChartLegend(AppColors.primary, s.tabPrediction),
                const SizedBox(width: 8),
                _buildChartLegend(AppColors.gray400, s.aiPreviousMonth),
              ],
            ),
            const SizedBox(height: 16),
            ...topCats.map((p) {
              // Estimación de gasto último mes por categoría (proporción sobre total)
              final lastMonthEst = r.lastMonthTotal > 0 && r.totalPredicted > 0
                  ? r.lastMonthTotal * (p.prediccion / r.totalPredicted)
                  : 0.0;
              final maxCatVal = [
                p.prediccion,
                lastMonthEst,
                1.0,
              ].reduce((a, b) => a > b ? a : b);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _getTranslatedCategory(context, p.categoria),
                          style: AppTypography.bodySmall(
                            color: AppColors.textPrimaryLight,
                          ),
                        ),
                        Text(
                          '${p.prediccion.toStringAsFixed(0)} €',
                          style: AppTypography.labelSmall(
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Barra predicción
                    TweenAnimationBuilder<double>(
                      tween: Tween(
                        begin: 0,
                        end: maxCatVal > 0 ? p.prediccion / maxCatVal : 0,
                      ),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOut,
                      builder: (_, value, __) => ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: value,
                          minHeight: 7,
                          backgroundColor: AppColors.gray200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    // Barra mes anterior
                    TweenAnimationBuilder<double>(
                      tween: Tween(
                        begin: 0,
                        end: maxCatVal > 0 ? lastMonthEst / maxCatVal : 0,
                      ),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOut,
                      builder: (_, value, __) => ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: value,
                          minHeight: 5,
                          backgroundColor: AppColors.gray100,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.gray400,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildChartLegend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTypography.badge(color: AppColors.textTertiaryLight),
        ),
      ],
    );
  }

  Widget _buildPredictionSummaryCard(BuildContext context) {
    final s = AppLocalizations.of(context);
    final r = _predictionsResult!;
    final trendColor = r.trend == 'increasing'
        ? AppColors.error
        : r.trend == 'decreasing'
        ? AppColors.success
        : AppColors.primary;
    final trendIcon = r.trend == 'increasing'
        ? Icons.trending_up_rounded
        : r.trend == 'decreasing'
        ? Icons.trending_down_rounded
        : Icons.trending_flat_rounded;
    final trendLabel = r.trend == 'increasing'
        ? s.aiTrendIncreasing
        : r.trend == 'decreasing'
        ? s.aiTrendDecreasing
        : s.aiTrendStable;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.psychology_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  s.aiNextMonthPrediction,
                  style: AppTypography.labelMedium(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${r.totalPredicted.toStringAsFixed(2)} €',
                        style: AppTypography.headlineLarge(
                          color: AppColors.textPrimaryLight,
                        ),
                      ),
                      Text(
                        s.aiRangeLabel(
                          r.totalPredMin.toStringAsFixed(0),
                          r.totalPredMax.toStringAsFixed(0),
                        ),
                        style: AppTypography.bodySmall(
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                Chip(
                  avatar: Icon(trendIcon, color: trendColor, size: 16),
                  label: Text(
                    trendLabel,
                    style: AppTypography.labelSmall(color: trendColor),
                  ),
                  backgroundColor: trendColor.withValues(alpha: 0.1),
                  side: BorderSide.none,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${s.aiPreviousMonthLabel(r.lastMonthTotal.toStringAsFixed(2))} ·  ${s.aiAnalyzedMonths(r.monthsOfData)}',
              style: AppTypography.bodySmall(
                color: AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModelInfoCard(BuildContext context) {
    final s = AppLocalizations.of(context);
    final r = _predictionsResult!;
    final models = r.predictions.map((p) => p.modelo).toSet().toList();
    return Card(
      elevation: 0,
      color: AppColors.primary.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(
              Icons.model_training_rounded,
              color: AppColors.primary,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${s.aiModelsLabel(models.join(', '))} . ${s.aiAnalyzedMonths(r.monthsOfData)}',
                style: AppTypography.bodySmall(color: AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryPredictionCard(CategoryPrediction p) {
    final trendColor = p.tendencia == 'increasing'
        ? AppColors.error
        : p.tendencia == 'decreasing'
        ? AppColors.success
        : AppColors.textSecondaryLight;
    final trendIcon = p.tendencia == 'increasing'
        ? Icons.arrow_upward_rounded
        : p.tendencia == 'decreasing'
        ? Icons.arrow_downward_rounded
        : Icons.remove_rounded;

    return Semantics(
      label:
          'Predicción ${_getTranslatedCategory(context, p.categoria)}: ${p.prediccion.toStringAsFixed(2)} euros',
      child: Card(
        elevation: 1,
        margin: const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getTranslatedCategory(context, p.categoria),
                      style: AppTypography.bodyMedium(
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${p.predMin.toStringAsFixed(0)} – ${p.predMax.toStringAsFixed(0)} €',
                      style: AppTypography.bodySmall(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Barra de confianza del modelo
                    LinearProgressIndicator(
                      value: p.precision.clamp(0.0, 1.0),
                      backgroundColor: AppColors.gray200,
                      color: p.cumpleUmbral
                          ? AppColors.success
                          : AppColors.warning,
                      minHeight: 3,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${p.prediccion.toStringAsFixed(2)} €',
                    style: AppTypography.titleMedium(
                      color: AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(trendIcon, size: 14, color: trendColor),
                      const SizedBox(width: 2),
                      Text(
                        p.modelo,
                        style: AppTypography.labelSmall(
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Tab 2: Recomendaciones de ahorro ───────────────────────────────────────

  Widget _buildSavingsTab(BuildContext context) {
    final s = AppLocalizations.of(context);
    if (_loadingSavings) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_savingsError != null) {
      return _buildError(_savingsError!, _loadSavings);
    }
    if (_savingsResult == null) {
      return _buildEmpty(
        icon: Icons.savings_rounded,
        title: s.aiEmptyDataTitle,
        subtitle: s.aiSavingsNoData,
      );
    }
    return RefreshIndicator(
      onRefresh: _loadSavings,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSavingsScoreCard(context),
          const SizedBox(height: 16),
          if (_savingsResult!.recommendations.isEmpty)
            _buildEmpty(
              icon: Icons.check_circle_rounded,
              title: s.aiSavingsExcellentTitle,
              subtitle: s.aiSavingsExcellentSubtitle,
            )
          else ...[
            Text(
              s.aiImprovementAreas,
              style: AppTypography.titleSmall(
                color: AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 8),
            ...(_savingsResult!.recommendations.map(
              _buildSavingsRecommendationCard,
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildSavingsScoreCard(BuildContext context) {
    final s = AppLocalizations.of(context);
    final r = _savingsResult!;
    final scoreColor = r.score >= 70
        ? AppColors.success
        : r.score >= 40
        ? AppColors.warning
        : AppColors.error;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.favorite_rounded,
                  color: AppColors.error,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  s.aiFinancialHealth,
                  style: AppTypography.labelMedium(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (r.ingresoPromedio != null)
                        _buildSummaryRow(
                          s.aiAvgIncome,
                          '${r.ingresoPromedio!.toStringAsFixed(2)} €',
                        ),
                      if (r.gastoPromedio != null)
                        _buildSummaryRow(
                          s.aiAvgExpense,
                          '${r.gastoPromedio!.toStringAsFixed(2)} €',
                        ),
                      if (r.savingsCapacity != null)
                        _buildSummaryRow(
                          s.aiSavingsCapacity,
                          '${r.savingsCapacity!.disponible.toStringAsFixed(2)} €/${s.monthPeriod}',
                          color: r.savingsCapacity!.disponible > 0
                              ? AppColors.success
                              : AppColors.error,
                        ),
                      if (r.savingsPotential > 0)
                        _buildSummaryRow(
                          s.aiSavingsPotential,
                          '${r.savingsPotential.toStringAsFixed(2)} €',
                          color: AppColors.success,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 80,
                  height: 80,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: r.score / 100,
                        strokeWidth: 8,
                        backgroundColor: AppColors.gray200,
                        color: scoreColor,
                      ),
                      Text(
                        '${r.score}',
                        style: AppTypography.titleMedium(color: scoreColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodySmall(color: AppColors.textSecondaryLight),
          ),
          Text(
            value,
            style: AppTypography.bodySmall(
              color: color ?? AppColors.textPrimaryLight,
            ).copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildSavingsRecommendationCard(SavingsRecommendation rec) {
    final s = AppLocalizations.of(context);
    final isHigh = rec.priority == 'high';
    final priorityColor = isHigh ? AppColors.error : AppColors.warning;

    final translatedCategory = _getTranslatedCategory(context, rec.category);

    return Semantics(
      label: s.aiRecommendationSemantics(translatedCategory, rec.message),
      child: Card(
        elevation: 1,
        margin: const EdgeInsets.only(bottom: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: priorityColor.withValues(alpha: 0.3)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: priorityColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      translatedCategory,
                      style: AppTypography.labelSmall(color: priorityColor),
                    ),
                  ),
                  const Spacer(),
                  if (isHigh)
                    const Icon(
                      Icons.priority_high_rounded,
                      color: AppColors.error,
                      size: 16,
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                rec.message,
                style: AppTypography.bodySmall(
                  color: AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildMiniStat(
                    s.aiCurrentLabel,
                    '${rec.currentSpend.toStringAsFixed(0)} €',
                    AppColors.error,
                  ),
                  const SizedBox(width: 12),
                  _buildMiniStat(
                    s.aiSuggestedLabel,
                    '${rec.suggestedBudget.toStringAsFixed(0)} €',
                    AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  _buildMiniStat(
                    s.saving,
                    '${rec.potentialSaving.toStringAsFixed(0)} €',
                    AppColors.success,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.labelSmall(color: AppColors.textSecondaryLight),
        ),
        Text(
          value,
          style: AppTypography.bodySmall(
            color: color,
          ).copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  // ── Tab 3: Anomalías (RF-23 / HU-10) ─────────────────────────────────────

  Widget _buildAnomaliesTab(BuildContext context) {
    final s = AppLocalizations.of(context);
    if (_loadingAnomalies) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_anomaliesError != null) {
      return _buildError(_anomaliesError!, _loadAnomalies);
    }
    final result = _anomaliesResult;
    if (result == null || result.anomalies.isEmpty) {
      return _buildEmpty(
        icon: Icons.check_circle_outline_rounded,
        title: s.aiNoAnomaliesTitle,
        subtitle: s.aiNoAnomaliesSubtitle,
      );
    }
    return RefreshIndicator(
      onRefresh: _loadAnomalies,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildAnomaliesSummaryCard(result, context),
          const SizedBox(height: 16),
          Text(
            s.aiUnusualExpensesDetected,
            style: AppTypography.titleSmall(color: AppColors.textPrimaryLight),
          ),
          const SizedBox(height: 8),
          ...result.anomalies.map((a) => _buildAnomalyCard(a, context)),
        ],
      ),
    );
  }

  Widget _buildAnomaliesSummaryCard(AnomaliesResult r, BuildContext context) {
    final s = AppLocalizations.of(context);
    final highCount = r.anomalies.where((a) => a.severity == 'high').length;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.insights_rounded,
                  color: AppColors.warning,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  s.aiAnomaliesSummary,
                  style: AppTypography.labelMedium(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildAnomalyStat(
                    '${r.totalAnomalies}',
                    s.aiUnusualExpensesDetected,
                    AppColors.warning,
                  ),
                ),
                Expanded(
                  child: _buildAnomalyStat(
                    '$highCount',
                    s.aiHighSeverity,
                    AppColors.error,
                  ),
                ),
                Expanded(
                  child: _buildAnomalyStat(
                    '${r.categoriesAnalyzed}',
                    s.aiAnalyzedCategories,
                    AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.warningSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                s.aiAnomalyExplanation,
                style: AppTypography.bodySmall(color: AppColors.warningDark),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnomalyStat(String value, String label, Color color) {
    return Column(
      children: [
        Text(value, style: AppTypography.headlineSmall(color: color)),
        Text(
          label,
          style: AppTypography.bodySmall(color: AppColors.textSecondaryLight),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildAnomalyCard(AnomalyItem a, BuildContext context) {
    final s = AppLocalizations.of(context);
    final isHigh = a.severity == 'high';
    final color = isHigh ? AppColors.error : AppColors.warning;
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.30)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _getTranslatedCategory(context, a.category),
                    style: AppTypography.labelSmall(color: color),
                  ),
                ),
                const Spacer(),
                Text(
                  a.date,
                  style: AppTypography.bodySmall(
                    color: AppColors.textTertiaryLight,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  isHigh
                      ? Icons.priority_high_rounded
                      : Icons.warning_amber_rounded,
                  color: color,
                  size: 16,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a.description.isNotEmpty ? a.description : a.category,
                      style: AppTypography.bodyMedium(
                        color: AppColors.textPrimaryLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      s.aiNormalAverage(a.meanAmount.toStringAsFixed(2)),
                      style: AppTypography.bodySmall(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${a.amount.toStringAsFixed(2)} €',
                  style: AppTypography.titleMedium(color: color),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.gray50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 14,
                    color: AppColors.textTertiaryLight,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      a.message,
                      style: AppTypography.bodySmall(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Tab 4: Suscripciones (RF-24 / HU-11) ─────────────────────────────────

  Widget _buildSubscriptionsTab(BuildContext context) {
    final s = AppLocalizations.of(context);
    if (_loadingSubscriptions) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_subscriptionsError != null) {
      return _buildError(_subscriptionsError!, _loadSubscriptions);
    }
    final result = _subscriptionsResult;
    if (result == null || result.subscriptions.isEmpty) {
      return _buildEmpty(
        icon: Icons.repeat_rounded,
        title: s.aiNoSubscriptionsTitle,
        subtitle: s.aiNoSubscriptionsSubtitle,
      );
    }
    return RefreshIndicator(
      onRefresh: _loadSubscriptions,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSubscriptionsSummaryCard(result, context),
          const SizedBox(height: 16),
          // Próximos cargos (si los hay)
          if (result.subscriptions.any((s) => s.isUpcoming)) ...[
            _buildUpcomingBanner(
              result.subscriptions.where((s) => s.isUpcoming).toList(),
              context,
            ),
            const SizedBox(height: 16),
          ],
          Text(
            s.aiActiveSubscriptions,
            style: AppTypography.titleSmall(color: AppColors.textPrimaryLight),
          ),
          const SizedBox(height: 8),
          ...result.subscriptions.map(
            (a) => (_buildSubscriptionCard(a, context)),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionsSummaryCard(
    SubscriptionsResult r,
    BuildContext context,
  ) {
    final s = AppLocalizations.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.repeat_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  s.aiRecurringExpensesDetected,
                  style: AppTypography.labelMedium(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${r.totalMonthlyCost.toStringAsFixed(2)} €/${s.monthPeriod}',
                        style: AppTypography.headlineLarge(
                          color: AppColors.textPrimaryLight,
                        ),
                      ),
                      Text(
                        s.aiAnnualCost(r.totalAnnualCost.toStringAsFixed(0)),
                        style: AppTypography.bodySmall(
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    s.aiDetectedCount(r.totalSubscriptions),
                    style: AppTypography.labelMedium(color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingBanner(
    List<SubscriptionItem> upcoming,
    BuildContext context,
  ) {
    final ss = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warningSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.notifications_active_rounded,
                color: AppColors.warning,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                ss.aiUpcomingCharges,
                style: AppTypography.labelMedium(color: AppColors.warningDark),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...upcoming.map(
            (s) => Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Text(
                    s.daysUntilNext == 0
                        ? ss.today
                        : s.daysUntilNext == 1
                        ? ss.tomorrow
                        : '${ss.inDays} ${s.daysUntilNext} ${ss.days}',
                    style: AppTypography.labelSmall(
                      color: AppColors.warningDark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      s.name,
                      style: AppTypography.bodySmall(
                        color: AppColors.textPrimaryLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${s.amount.toStringAsFixed(2)} €',
                    style: AppTypography.labelSmall(
                      color: AppColors.warningDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionCard(SubscriptionItem s, BuildContext context) {
    final ss = AppLocalizations.of(context);
    final periodColor = s.periodicity == 'annual'
        ? AppColors.accent
        : s.periodicity == 'quarterly'
        ? AppColors.secondary
        : AppColors.primary;

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: periodColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  _periodicityEmoji(s.periodicity),
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.name,
                    style: AppTypography.bodyMedium(
                      color: AppColors.textPrimaryLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${_getTranslatedCategory(context, s.category)} · ${_getPeriodicityLabel(context, s.periodicityLabel)} · ${ss.aiOccurrences(s.occurrences)}',
                    style: AppTypography.bodySmall(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                  Text(
                    '${ss.aiNextCharge}: ${s.nextCharge}',
                    style: AppTypography.badge(
                      color: s.isUpcoming
                          ? AppColors.warning
                          : AppColors.textTertiaryLight,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${s.amount.toStringAsFixed(2)} €',
                  style: AppTypography.titleMedium(
                    color: AppColors.textPrimaryLight,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: periodColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${s.monthlyCost.toStringAsFixed(0)} €/${ss.monthPeriod}',
                    style: AppTypography.badge(color: periodColor),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _periodicityEmoji(String periodicity) {
    switch (periodicity) {
      case 'weekly':
        return '📅';
      case 'monthly':
        return '🔄';
      case 'quarterly':
        return '📆';
      case 'annual':
        return '🗓️';
      default:
        return '🔁';
    }
  }

  // ── Widgets auxiliares ─────────────────────────────────────────────────────

  Widget _buildError(String error, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 64,
              color: AppColors.gray300,
            ),
            const SizedBox(height: 16),
            Text(
              'Error al cargar datos',
              style: AppTypography.titleSmall(
                color: AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'El servicio de IA no está disponible temporalmente.',
              style: AppTypography.bodySmall(
                color: AppColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: AppColors.gray300),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppTypography.titleSmall(
                color: AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: AppTypography.bodySmall(
                color: AppColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
