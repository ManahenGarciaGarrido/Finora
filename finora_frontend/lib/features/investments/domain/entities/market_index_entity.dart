class MarketIndexEntity {
  final String name;
  final String ticker;
  final double value;
  final double change;
  final String currency;

  const MarketIndexEntity({
    required this.name,
    required this.ticker,
    required this.value,
    required this.change,
    required this.currency,
  });

  bool get isPositive => change >= 0;
}
