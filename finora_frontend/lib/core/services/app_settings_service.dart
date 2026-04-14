import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'currency_service.dart';

/// Service for persisting and notifying app-wide settings:
/// - Locale (language)
/// - Currency and number format
class AppSettingsService {
  static const _keyLocale = 'app_locale';
  static const _keyCurrency = 'app_currency';

  static final AppSettingsService _instance = AppSettingsService._();
  factory AppSettingsService() => _instance;
  AppSettingsService._();

  /// Notifier for locale — MyApp listens to this to rebuild
  final localeNotifier = ValueNotifier<Locale>(const Locale('es'));

  /// Notifier for currency — widgets that display money listen to this
  final ValueNotifier<CurrencyConfig> currencyNotifier = ValueNotifier(
    const CurrencyConfig(code: 'EUR', symbol: '€', name: 'Euro'),
  );

  static const List<CurrencyConfig> availableCurrencies = [
    CurrencyConfig(code: 'EUR', symbol: '€', name: 'Euro'),
    CurrencyConfig(code: 'USD', symbol: '\$', name: 'Dólar estadounidense'),
    CurrencyConfig(code: 'GBP', symbol: '£', name: 'Libra esterlina'),
    CurrencyConfig(code: 'CHF', symbol: 'Fr.', name: 'Franco suizo'),
    CurrencyConfig(code: 'MXN', symbol: '\$', name: 'Peso mexicano'),
    CurrencyConfig(code: 'ARS', symbol: '\$', name: 'Peso argentino'),
    CurrencyConfig(code: 'COP', symbol: '\$', name: 'Peso colombiano'),
  ];

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final localeCode = prefs.getString(_keyLocale) ?? 'es';
    localeNotifier.value = Locale(localeCode);

    final currencyCode = prefs.getString(_keyCurrency) ?? 'EUR';
    final cfg = availableCurrencies.firstWhere(
      (c) => c.code == currencyCode,
      orElse: () => availableCurrencies.first,
    );
    currencyNotifier.value = cfg;
    // Fetch exchange rate in background (non-blocking)
    await CurrencyService().fetchRate(cfg.code);
  }

  Future<void> setLocale(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLocale, languageCode);
    localeNotifier.value = Locale(languageCode);
  }

  Future<void> setCurrency(CurrencyConfig cfg) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCurrency, cfg.code);
    currencyNotifier.value = cfg;
    // Refresh exchange rate whenever the user changes currency
    await CurrencyService().fetchRate(cfg.code);
  }

  String get currentLocaleCode => localeNotifier.value.languageCode;
  CurrencyConfig get currentCurrency => currencyNotifier.value;
}

class CurrencyConfig {
  final String code;
  final String symbol;
  final String name;

  const CurrencyConfig({
    required this.code,
    required this.symbol,
    required this.name,
  });

  @override
  String toString() => '$code - $name';
}
