class MarketIndexEntity {
  final String name;
  final String ticker;
  final double value;
  final double change;
  final String currency;
  final String category;
  final List<double> spark;
  final double volume;
  final double marketCap;
  final double high24h;
  final double low24h;

  const MarketIndexEntity({
    required this.name,
    required this.ticker,
    required this.value,
    required this.change,
    required this.currency,
    this.category = 'equity',
    this.spark = const [],
    this.volume = 0.0,
    this.marketCap = 0.0,
    this.high24h = 0.0,
    this.low24h = 0.0,
  });

  bool get isPositive => change >= 0;
}
