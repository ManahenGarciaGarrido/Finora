/// RF-22 / HU-09: Predicción de gastos con Machine Learning
/// RF-21 / HU-08: Recomendaciones de ahorro inteligente
///
/// Página que muestra las predicciones ML del próximo mes (Ridge/RF/GBM)
/// y recomendaciones de ahorro basadas en el análisis de historial.
/// Algoritmos: rf22_prediccion_gastos_ml.ipynb + rf21_hu08_ahorro_inteligente.ipynb

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
  String? _predictionsError;
  String? _savingsError;

  ExpensePredictionResult? _predictionsResult;
  SavingsResult? _savingsResult;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
  }

  Future<void> _loadPredictions() async {
    setState(() {
      _loadingPredictions = true;
      _predictionsError = null;
    });
    try {
      final result = await _aiService.predictExpenses(months: 12);
      if (mounted)
        setState(() {
          _predictionsResult = result;
          _loadingPredictions = false;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          _predictionsError = e.toString();
          _loadingPredictions = false;
        });
    }
  }

  Future<void> _loadSavings() async {
    setState(() {
      _loadingSavings = true;
      _savingsError = null;
    });
    try {
      final result = await _aiService.getSavingsRecommendations(months: 3);
      if (mounted)
        setState(() {
          _savingsResult = result;
          _loadingSavings = false;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          _savingsError = e.toString();
          _loadingSavings = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: Text(
          'Predicciones IA',
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
          tabs: const [
            Tab(icon: Icon(Icons.trending_up_rounded), text: 'Gastos'),
            Tab(icon: Icon(Icons.savings_rounded), text: 'Ahorro'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildPredictionsTab(), _buildSavingsTab()],
      ),
    );
  }

  // ── Tab 1: Predicciones de gastos ──────────────────────────────────────────

  Widget _buildPredictionsTab() {
    if (_loadingPredictions) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_predictionsError != null) {
      return _buildError(_predictionsError!, _loadPredictions);
    }
    if (_predictionsResult == null || _predictionsResult!.predictions.isEmpty) {
      return _buildEmpty(
        icon: Icons.insights_rounded,
        title: 'Sin datos suficientes',
        subtitle:
            'Necesitas al menos 2 meses de transacciones para generar predicciones.',
      );
    }
    return RefreshIndicator(
      onRefresh: _loadPredictions,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildPredictionSummaryCard(),
          const SizedBox(height: 16),
          _buildModelInfoCard(),
          const SizedBox(height: 16),
          ...(_predictionsResult!.predictions.map(
            _buildCategoryPredictionCard,
          )),
        ],
      ),
    );
  }

  Widget _buildPredictionSummaryCard() {
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
        ? 'Tendencia al alza'
        : r.trend == 'decreasing'
        ? 'Tendencia a la baja'
        : 'Tendencia estable';

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
                  'Predicción próximo mes',
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
                        'Rango: ${r.totalPredMin.toStringAsFixed(0)} – ${r.totalPredMax.toStringAsFixed(0)} €',
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
              'Mes anterior: ${r.lastMonthTotal.toStringAsFixed(2)} €  ·  ${r.monthsOfData} meses de historial',
              style: AppTypography.bodySmall(
                color: AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModelInfoCard() {
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
                'Modelos: ${models.join(', ')}  ·  ${r.monthsOfData} meses analizados',
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
          'Predicción ${p.categoria}: ${p.prediccion.toStringAsFixed(2)} euros',
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
                      p.categoria,
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

  Widget _buildSavingsTab() {
    if (_loadingSavings) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_savingsError != null) {
      return _buildError(_savingsError!, _loadSavings);
    }
    if (_savingsResult == null) {
      return _buildEmpty(
        icon: Icons.savings_rounded,
        title: 'Sin datos',
        subtitle: 'No se pudieron calcular las recomendaciones.',
      );
    }
    return RefreshIndicator(
      onRefresh: _loadSavings,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSavingsScoreCard(),
          const SizedBox(height: 16),
          if (_savingsResult!.recommendations.isEmpty)
            _buildEmpty(
              icon: Icons.check_circle_rounded,
              title: '¡Excelente!',
              subtitle:
                  'Tu distribución de gastos es saludable. No hay áreas de mejora identificadas.',
            )
          else ...[
            Text(
              'Áreas de mejora',
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

  Widget _buildSavingsScoreCard() {
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
                  'Salud financiera',
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
                          'Ingreso prom.',
                          '${r.ingresoPromedio!.toStringAsFixed(2)} €',
                        ),
                      if (r.gastoPromedio != null)
                        _buildSummaryRow(
                          'Gasto prom.',
                          '${r.gastoPromedio!.toStringAsFixed(2)} €',
                        ),
                      if (r.savingsCapacity != null)
                        _buildSummaryRow(
                          'Capacidad ahorro',
                          '${r.savingsCapacity!.disponible.toStringAsFixed(2)} €/mes',
                          color: r.savingsCapacity!.disponible > 0
                              ? AppColors.success
                              : AppColors.error,
                        ),
                      if (r.savingsPotential > 0)
                        _buildSummaryRow(
                          'Ahorro potencial',
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
                        style: AppTypography.headlineMedium(color: scoreColor),
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
    final isHigh = rec.priority == 'high';
    final priorityColor = isHigh ? AppColors.error : AppColors.warning;

    return Semantics(
      label: 'Recomendación de ahorro en ${rec.category}: ${rec.message}',
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
                      rec.category,
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
                    'Actual',
                    '${rec.currentSpend.toStringAsFixed(0)} €',
                    AppColors.error,
                  ),
                  const SizedBox(width: 12),
                  _buildMiniStat(
                    'Sugerido',
                    '${rec.suggestedBudget.toStringAsFixed(0)} €',
                    AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  _buildMiniStat(
                    'Ahorro',
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
