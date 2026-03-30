/// Keys for local storage (SharedPreferences, SecureStorage, etc.)
class StorageKeys {
  // Private constructor to prevent instantiation
  StorageKeys._();

  // Authentication keys (Secure Storage)
  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';
  static const String biometricToken = 'biometric_access_token';
  static const String biometricCachedUser = 'biometric_cached_user';
  static const String userId = 'user_id';
  static const String userEmail = 'user_email';
  static const String biometricEnabled = 'biometric_enabled';
  static const String twoFactorEnabled = 'two_factor_enabled';

  // User preferences (Shared Preferences)
  static const String language = 'language';
  static const String currency = 'currency';
  static const String theme = 'theme';
  static const String notifications = 'notifications_enabled';
  static const String firstLaunch = 'first_launch';
  static const String lastSyncTime = 'last_sync_time';

  // Onboarding
  static const String hasCompletedOnboarding = 'has_completed_onboarding';

  // Cache keys
  static const String cachedTransactions = 'cached_transactions';
  static const String cachedCategories = 'cached_categories';
  static const String cachedBankAccounts = 'cached_bank_accounts';
  static const String cachedDashboard = 'cached_dashboard';

  // Database
  static const String databaseName = 'finora.db';
  static const int databaseVersion = 1;

  // Offline sync
  static const String pendingTransactions = 'pending_transactions';
  static const String syncQueue = 'sync_queue';
}
