import '../../domain/entities/market_index_entity.dart';

class MarketIndexModel extends MarketIndexEntity {
  const MarketIndexModel({
    required super.name,
    required super.ticker,
    required super.value,
    required super.change,
    required super.currency,
    super.category,
    super.spark,
    super.volume,
    super.marketCap,
    super.high24h,
    super.low24h,
  });

  factory MarketIndexModel.fromJson(Map<String, dynamic> j) => MarketIndexModel(
    name: j['name'] as String,
    ticker: j['ticker'] as String,
    value: (j['value'] as num).toDouble(),
    change: (j['change'] as num).toDouble(),
    currency: j['currency'] as String,
    category: (j['category'] as String?) ?? 'equity',
    spark:
        (j['spark'] as List?)?.map((e) => (e as num).toDouble()).toList() ?? [],
    volume: (j['volume'] as num?)?.toDouble() ?? 0.0,
    marketCap: (j['market_cap'] as num?)?.toDouble() ?? 0.0,
    high24h: (j['high_24h'] as num?)?.toDouble() ?? 0.0,
    low24h: (j['low_24h'] as num?)?.toDouble() ?? 0.0,
  );
}
