/// CurrencyService — live EUR→X conversion using backend exchange rates.
///
/// All backend amounts are stored and returned in EUR. This service converts
/// them to the user's selected currency for display. Rates are cached in memory
/// for the session and refreshed whenever the user changes currency.
library;

import '../constants/api_endpoints.dart';
import '../di/injection_container.dart';
import '../network/api_client.dart';
import 'app_settings_service.dart';

class CurrencyService {
  static final CurrencyService _instance = CurrencyService._();
  factory CurrencyService() => _instance;
  CurrencyService._();

  double _rate = 1.0;

  double get rate => _rate;

  /// Fetches the EUR→[currencyCode] exchange rate from the backend.
  /// No-op for EUR (rate stays 1.0). Silently keeps previous rate on failure.
  Future<void> fetchRate(String currencyCode) async {
    if (currencyCode == 'EUR') {
      _rate = 1.0;
      return;
    }
    try {
      final client = sl<ApiClient>();
      final resp = await client.get(
        ApiEndpoints.currencyRates,
        queryParameters: {'base': 'EUR'},
      );
      final rates = resp.data['rates'] as Map<String, dynamic>?;
      if (rates != null && rates.containsKey(currencyCode)) {
        _rate = (rates[currencyCode] as num).toDouble();
      }
    } catch (_) {
      // Keep previous rate as fallback — avoids blank screens on network error.
    }
  }

  /// Converts [eurAmount] to the currently selected currency.
  double convert(double eurAmount) => eurAmount * _rate;

  /// Converts [eurAmount] and formats as a localized currency string.
  /// Uses Spanish decimal format (comma separator, dot thousands).
  String format(double eurAmount, {int decimals = 2}) {
    final converted = convert(eurAmount);
    final symbol = AppSettingsService().currentCurrency.symbol;
    final isNeg = converted < 0;
    final abs = converted.abs();
    final fixed = abs.toStringAsFixed(decimals);
    final parts = fixed.split('.');
    final intPart = parts[0];
    final decPart = parts.length > 1 ? parts[1] : '';
    final buffer = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) buffer.write('.');
      buffer.write(intPart[i]);
    }
    final body = decPart.isEmpty ? buffer.toString() : '$buffer,$decPart';
    return '${isNeg ? '-' : ''}$body $symbol';
  }

  /// Compact format for charts: 1.5k$, 2.3M€, etc.
  String formatCompact(double eurAmount) {
    final converted = convert(eurAmount).abs();
    final symbol = AppSettingsService().currentCurrency.symbol;
    if (converted >= 1_000_000) {
      return '${(converted / 1_000_000).toStringAsFixed(1)}M$symbol';
    }
    if (converted >= 1_000) {
      return '${(converted / 1_000).toStringAsFixed(1)}k$symbol';
    }
    return '${converted.toStringAsFixed(0)}$symbol';
  }
}
