class PortfolioAllocationEntity {
  final String etf;
  final String ticker;
  final int allocation;
  final String category;
  final String reason;

  const PortfolioAllocationEntity({
    required this.etf,
    required this.ticker,
    required this.allocation,
    required this.category,
    this.reason = '',
  });
}

class PortfolioSuggestionEntity {
  final String riskTolerance;
  final List<PortfolioAllocationEntity> portfolio;
  final String rationale;

  const PortfolioSuggestionEntity({
    required this.riskTolerance,
    required this.portfolio,
    this.rationale = '',
  });
}
