import '../../domain/entities/portfolio_suggestion_entity.dart';

class PortfolioSuggestionModel extends PortfolioSuggestionEntity {
  const PortfolioSuggestionModel({
    required super.riskTolerance,
    required super.portfolio,
  });

  factory PortfolioSuggestionModel.fromJson(Map<String, dynamic> j) =>
      PortfolioSuggestionModel(
        riskTolerance: j['risk_tolerance'] as String,
        portfolio: (j['portfolio'] as List)
            .map(
              (e) => PortfolioAllocationEntity(
                etf: e['etf'] as String,
                ticker: e['ticker'] as String,
                allocation: (e['allocation'] as num).toInt(),
                category: e['category'] as String,
              ),
            )
            .toList(),
      );
}
