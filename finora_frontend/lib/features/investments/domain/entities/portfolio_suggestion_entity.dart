class PortfolioAllocationEntity {
  final String etf;
  final String ticker;
  final int allocation;
  final String category;

  const PortfolioAllocationEntity({
    required this.etf,
    required this.ticker,
    required this.allocation,
    required this.category,
  });
}

class PortfolioSuggestionEntity {
  final String riskTolerance;
  final List<PortfolioAllocationEntity> portfolio;

  const PortfolioSuggestionEntity({
    required this.riskTolerance,
    required this.portfolio,
  });
}
