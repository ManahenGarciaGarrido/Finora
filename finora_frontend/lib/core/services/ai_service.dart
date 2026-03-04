/// RF-22 / HU-09: Predicción de gastos ML
/// RF-21 / HU-08: Recomendaciones de ahorro inteligente
///
/// Servicio Flutter que llama a los endpoints del backend /api/v1/ai/*
/// El backend actúa como proxy hacia el microservicio finora-ai (Python Flask).
library;

import '../network/api_client.dart';
import '../constants/api_endpoints.dart';

// ── Modelos de datos ──────────────────────────────────────────────────────────

/// Predicción ML para una categoría de gastos (RF-22)
class CategoryPrediction {
  final String categoria;
  final double prediccion;
  final double predMin;
  final double predMax;
  final String modelo;
  final double precision;
  final String tendencia; // 'increasing' | 'decreasing' | 'stable'
  final bool cumpleUmbral;

  const CategoryPrediction({
    required this.categoria,
    required this.prediccion,
    required this.predMin,
    required this.predMax,
    required this.modelo,
    required this.precision,
    required this.tendencia,
    required this.cumpleUmbral,
  });

  factory CategoryPrediction.fromJson(Map<String, dynamic> json) {
    return CategoryPrediction(
      categoria: json['categoria'] as String,
      prediccion: (json['prediccion'] as num).toDouble(),
      predMin: (json['pred_min'] as num).toDouble(),
      predMax: (json['pred_max'] as num).toDouble(),
      modelo: json['modelo'] as String? ?? 'EMA',
      precision: (json['precision'] as num?)?.toDouble() ?? 0.5,
      tendencia: json['tendencia'] as String? ?? 'stable',
      cumpleUmbral: json['cumple_umbral'] as bool? ?? false,
    );
  }
}

/// Resultado completo de predicción de gastos (RF-22)
class ExpensePredictionResult {
  final List<CategoryPrediction> predictions;
  final double totalPredicted;
  final double totalPredMin;
  final double totalPredMax;
  final String trend;
  final double lastMonthTotal;
  final int monthsOfData;

  const ExpensePredictionResult({
    required this.predictions,
    required this.totalPredicted,
    required this.totalPredMin,
    required this.totalPredMax,
    required this.trend,
    required this.lastMonthTotal,
    required this.monthsOfData,
  });

  factory ExpensePredictionResult.fromJson(Map<String, dynamic> json) {
    final rawList = json['predictions'] as List<dynamic>? ?? [];
    return ExpensePredictionResult(
      predictions: rawList
          .map((e) => CategoryPrediction.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalPredicted: (json['total_predicted'] as num?)?.toDouble() ?? 0,
      totalPredMin: (json['total_pred_min'] as num?)?.toDouble() ?? 0,
      totalPredMax: (json['total_pred_max'] as num?)?.toDouble() ?? 0,
      trend: json['trend'] as String? ?? 'stable',
      lastMonthTotal: (json['last_month_total'] as num?)?.toDouble() ?? 0,
      monthsOfData: json['months_of_data'] as int? ?? 0,
    );
  }
}

/// Recomendación de ahorro individual (RF-21)
class SavingsRecommendation {
  final String category;
  final double currentSpend;
  final double suggestedBudget;
  final double potentialSaving;
  final String message;
  final String priority; // 'high' | 'medium'

  const SavingsRecommendation({
    required this.category,
    required this.currentSpend,
    required this.suggestedBudget,
    required this.potentialSaving,
    required this.message,
    required this.priority,
  });

  factory SavingsRecommendation.fromJson(Map<String, dynamic> json) {
    return SavingsRecommendation(
      category: json['category'] as String,
      currentSpend: (json['current_spend'] as num).toDouble(),
      suggestedBudget: (json['suggested_budget'] as num).toDouble(),
      potentialSaving: (json['potential_saving'] as num).toDouble(),
      message: json['message'] as String,
      priority: json['priority'] as String? ?? 'medium',
    );
  }
}

/// Capacidad de ahorro del usuario (RF-21)
class SavingsCapacity {
  final double ahorroBruto;
  final double comprometido;
  final double disponible;

  const SavingsCapacity({
    required this.ahorroBruto,
    required this.comprometido,
    required this.disponible,
  });

  factory SavingsCapacity.fromJson(Map<String, dynamic> json) {
    return SavingsCapacity(
      ahorroBruto: (json['ahorro_bruto'] as num?)?.toDouble() ?? 0,
      comprometido: (json['comprometido'] as num?)?.toDouble() ?? 0,
      disponible: (json['disponible'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Resultado completo de recomendaciones de ahorro (RF-21)
class SavingsResult {
  final List<SavingsRecommendation> recommendations;
  final double savingsPotential;
  final int score;
  final SavingsCapacity? savingsCapacity;
  final double? ingresoPromedio;
  final double? gastoPromedio;

  const SavingsResult({
    required this.recommendations,
    required this.savingsPotential,
    required this.score,
    this.savingsCapacity,
    this.ingresoPromedio,
    this.gastoPromedio,
  });

  factory SavingsResult.fromJson(Map<String, dynamic> json) {
    final rawRecs = json['recommendations'] as List<dynamic>? ?? [];
    final capJson = json['savings_capacity'] as Map<String, dynamic>?;
    final summaryJson = json['monthly_summary'] as Map<String, dynamic>?;
    return SavingsResult(
      recommendations: rawRecs
          .map((e) => SavingsRecommendation.fromJson(e as Map<String, dynamic>))
          .toList(),
      savingsPotential: (json['savings_potential'] as num?)?.toDouble() ?? 0,
      score: json['score'] as int? ?? 50,
      savingsCapacity: capJson != null
          ? SavingsCapacity.fromJson(capJson)
          : null,
      ingresoPromedio: (summaryJson?['ingreso_promedio'] as num?)?.toDouble(),
      gastoPromedio: (summaryJson?['gasto_promedio'] as num?)?.toDouble(),
    );
  }
}

// ── AiService ─────────────────────────────────────────────────────────────────

class AiService {
  final ApiClient _apiClient;

  AiService({required ApiClient apiClient}) : _apiClient = apiClient;

  /// RF-22 / HU-09: Predicción ML de gastos del próximo mes.
  ///
  /// El backend obtiene las transacciones de la BD y llama al servicio AI.
  /// El algoritmo selecciona Ridge/RandomForest/GradientBoosting según los meses de historial.
  Future<ExpensePredictionResult> predictExpenses({int months = 12}) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.predictExpenses,
        queryParameters: {'months': months.toString()},
        data: {},
      );
      return ExpensePredictionResult.fromJson(
        response.data as Map<String, dynamic>,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// RF-21 / HU-08: Recomendaciones de ahorro inteligente.
  ///
  /// El backend obtiene las transacciones + ingreso promedio y llama al servicio AI.
  Future<SavingsResult> getSavingsRecommendations({int months = 3}) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.aiSavings,
        data: {'months': months},
      );
      return SavingsResult.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  /// RF-23 / HU-10: Detectar gastos anómalos del historial.
  ///
  /// Analiza los últimos [months] meses de gastos y devuelve los que superan
  /// 2 desviaciones estándar respecto a la media de su categoría.
  Future<AnomaliesResult> detectAnomalies({int months = 6}) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.detectAnomalies,
        queryParameters: {'months': months.toString()},
      );
      return AnomaliesResult.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  /// RF-24 / HU-11: Detectar suscripciones y pagos recurrentes automáticamente.
  ///
  /// Analiza los últimos [months] meses y detecta pagos periódicos (semanal,
  /// mensual, trimestral, anual) con importe estable (variación < 10%).
  Future<SubscriptionsResult> detectSubscriptions({int months = 6}) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.detectSubscriptions,
        queryParameters: {'months': months.toString()},
      );
      return SubscriptionsResult.fromJson(
        response.data as Map<String, dynamic>,
      );
    } catch (e) {
      rethrow;
    }
  }
}

// ── Modelos RF-23 / HU-10 ────────────────────────────────────────────────────

/// Gasto anómalo detectado (Z-score > 2σ respecto a la media de la categoría)
class AnomalyItem {
  final String id;
  final String date;
  final String category;
  final double amount;
  final double meanAmount;
  final double zScore;
  final double percentAboveAvg;
  final String severity; // 'medium' | 'high'
  final String description;
  final String message;

  const AnomalyItem({
    required this.id,
    required this.date,
    required this.category,
    required this.amount,
    required this.meanAmount,
    required this.zScore,
    required this.percentAboveAvg,
    required this.severity,
    required this.description,
    required this.message,
  });

  factory AnomalyItem.fromJson(Map<String, dynamic> json) {
    return AnomalyItem(
      id: json['id'] as String? ?? '',
      date: json['date'] as String? ?? '',
      category: json['category'] as String? ?? 'Otros',
      amount: (json['amount'] as num).toDouble(),
      meanAmount: (json['mean_amount'] as num).toDouble(),
      zScore: (json['z_score'] as num).toDouble(),
      percentAboveAvg: (json['percent_above_avg'] as num).toDouble(),
      severity: json['severity'] as String? ?? 'medium',
      description: json['description'] as String? ?? '',
      message: json['message'] as String? ?? '',
    );
  }
}

/// Resultado completo de detección de anomalías
class AnomaliesResult {
  final List<AnomalyItem> anomalies;
  final int totalAnomalies;
  final int categoriesAnalyzed;

  const AnomaliesResult({
    required this.anomalies,
    required this.totalAnomalies,
    required this.categoriesAnalyzed,
  });

  factory AnomaliesResult.fromJson(Map<String, dynamic> json) {
    final raw = json['anomalies'] as List<dynamic>? ?? [];
    return AnomaliesResult(
      anomalies: raw
          .map((e) => AnomalyItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalAnomalies: json['total_anomalies'] as int? ?? 0,
      categoriesAnalyzed: json['categories_analyzed'] as int? ?? 0,
    );
  }
}

// ── Modelos RF-24 / HU-11 ────────────────────────────────────────────────────

/// Suscripción o gasto recurrente detectado automáticamente
class SubscriptionItem {
  final String name;
  final String category;
  final double amount;
  final double monthlyCost;
  final String periodicity; // 'weekly' | 'monthly' | 'quarterly' | 'annual'
  final String
  periodicityLabel; // 'Semanal' | 'Mensual' | 'Trimestral' | 'Anual'
  final int occurrences;
  final String lastCharge;
  final String nextCharge;
  final int daysUntilNext;
  final double amountVariation; // % de variación del importe

  const SubscriptionItem({
    required this.name,
    required this.category,
    required this.amount,
    required this.monthlyCost,
    required this.periodicity,
    required this.periodicityLabel,
    required this.occurrences,
    required this.lastCharge,
    required this.nextCharge,
    required this.daysUntilNext,
    required this.amountVariation,
  });

  factory SubscriptionItem.fromJson(Map<String, dynamic> json) {
    return SubscriptionItem(
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? 'Otros',
      amount: (json['amount'] as num).toDouble(),
      monthlyCost: (json['monthly_cost'] as num).toDouble(),
      periodicity: json['periodicity'] as String? ?? 'monthly',
      periodicityLabel: json['periodicity_label'] as String? ?? 'Mensual',
      occurrences: json['occurrences'] as int? ?? 0,
      lastCharge: json['last_charge'] as String? ?? '',
      nextCharge: json['next_charge'] as String? ?? '',
      daysUntilNext: json['days_until_next'] as int? ?? 0,
      amountVariation: (json['amount_variation'] as num?)?.toDouble() ?? 0,
    );
  }

  bool get isUpcoming => daysUntilNext >= 0 && daysUntilNext <= 7;
}

/// Resultado completo de detección de suscripciones
class SubscriptionsResult {
  final List<SubscriptionItem> subscriptions;
  final int totalSubscriptions;
  final double totalMonthlyCost;
  final double totalAnnualCost;

  const SubscriptionsResult({
    required this.subscriptions,
    required this.totalSubscriptions,
    required this.totalMonthlyCost,
    required this.totalAnnualCost,
  });

  factory SubscriptionsResult.fromJson(Map<String, dynamic> json) {
    final raw = json['subscriptions'] as List<dynamic>? ?? [];
    return SubscriptionsResult(
      subscriptions: raw
          .map((e) => SubscriptionItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalSubscriptions: json['total_subscriptions'] as int? ?? 0,
      totalMonthlyCost: (json['total_monthly_cost'] as num?)?.toDouble() ?? 0,
      totalAnnualCost: (json['total_annual_cost'] as num?)?.toDouble() ?? 0,
    );
  }
}
