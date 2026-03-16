/// Application-wide constants
class AppConstants {
  // Private constructor to prevent instantiation
  AppConstants._();

  // App Information
  static const String appName = 'Finora';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Personal Finance Manager with AI';

  // Timeouts
  static const int connectionTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000; // 30 seconds
  // Timeout extendido para operaciones largas (import de cuentas bancarias con IA)
  static const int bankImportReceiveTimeout = 180000; // 3 minutos

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Cache
  static const int cacheValidityDuration = 3600; // 1 hour in seconds
  static const int maxCacheSize = 50; // MB

  // Date Formats
  static const String dateFormat = 'dd/MM/yyyy';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm';
  static const String timeFormat = 'HH:mm';

  // Currency
  static const String defaultCurrency = 'EUR';
  static const String currencySymbol = '€';

  // Validation
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 128;
  static const int minUsernameLength = 3;
  static const int maxUsernameLength = 50;

  // Biometric
  static const String biometricLocalizedReason =
      'Authenticate to access your financial data';
}
