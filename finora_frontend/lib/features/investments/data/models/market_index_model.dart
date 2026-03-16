import '../../domain/entities/market_index_entity.dart';

class MarketIndexModel extends MarketIndexEntity {
  const MarketIndexModel({
    required super.name,
    required super.ticker,
    required super.value,
    required super.change,
    required super.currency,
  });

  factory MarketIndexModel.fromJson(Map<String, dynamic> j) => MarketIndexModel(
    name: j['name'] as String,
    ticker: j['ticker'] as String,
    value: (j['value'] as num).toDouble(),
    change: (j['change'] as num).toDouble(),
    currency: j['currency'] as String,
  );
}
