import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// API endpoints for backend communication
class ApiEndpoints {
  // Private constructor to prevent instantiation
  ApiEndpoints._();

  // Base URL - configured for local Docker backend
  // Android emulator uses 10.0.2.2, iOS simulator and desktop use localhost
  static String get baseUrl {
    const envUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (envUrl.isNotEmpty) return envUrl;

    // Web platform
    if (kIsWeb) {
      return 'http://68.221.27.85:3000/api/v1';
    }

    // For local development with Docker
    if (Platform.isAndroid) {
      return 'http://68.221.27.85:3000/api/v1';
    }

    // iOS, Windows, macOS, Linux
    return 'http://68.221.27.85:3000/api/v1';
  }

  // Authentication endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String verifyEmail = '/auth/verify-email';
  static const String resendVerification = '/auth/resend-verification';
  static const String enable2FA = '/auth/2fa/enable';
  static const String verify2FA = '/auth/2fa/verify';
  static const String disable2FA = '/auth/2fa/disable';

  // User endpoints
  static const String userProfile = '/user/profile';
  static const String updateProfile = '/user/profile';
  static const String changePassword = '/user/change-password';
  static const String deleteAccount = '/user/delete';
  static const String exportUserData = '/user/export';

  // Transactions endpoints
  static const String transactions = '/transactions';
  static String transactionById(String id) => '/transactions/$id';
  static const String searchTransactions = '/transactions/search';
  static const String monthlySummary = '/transactions/monthly-summary';
  static const String transactionAnalytics = '/transactions/analytics';
  static const String filterTransactions = '/transactions/filter';
  static const String syncOfflineTransactions = '/transactions/sync';

  // Bank sync endpoints
  static const String bankInstitutions = '/banks/institutions';
  static const String connectBank = '/banks/connect';
  static const String bankAccounts = '/banks/accounts';
  static const String bankAccountSetup = '/banks/accounts/setup';
  static const String bankCards = '/banks/cards';
  static String bankAccountCards(String id) => '/banks/accounts/$id/cards';
  static String bankCardById(String id) => '/banks/cards/$id';
  static String bankAccountImportCsv(String id) =>
      '/banks/accounts/$id/import-csv';
  static String disconnectBank(String id) => '/banks/$id/disconnect';
  static String syncBank(String id) => '/banks/$id/sync';
  static String bankSyncStatus(String id) => '/banks/$id/sync-status';
  // RF-11: importar transacciones desde Salt Edge
  static String importBankTransactions(String id) =>
      '/banks/$id/import-transactions';
  // RF-10: intercambiar public_token de Plaid Link por access_token
  static const String plaidExchange = '/banks/plaid-exchange';
  // RF-10: importar cuentas seleccionadas tras pantalla de selección
  static String importBankAccounts(String id) => '/banks/$id/import-accounts';
  // RNF-05: PSD2 consent management
  static const String bankConsents = '/banks/consents';
  static String renewBankConsent(String id) => '/banks/$id/consent/renew';
  static String revokeBankConsent(String id) => '/banks/$id/consent';
  // RNF-07: Historial de sincronizaciones (sync logs)
  static const String bankSyncLogs = '/banks/sync-logs';
  // RNF-16: Circuit breaker health check
  static const String bankCircuitBreakerHealth =
      '/banks/health/circuit-breaker';

  // Categories endpoints
  static const String categories = '/categories';
  static String categoryById(String id) => '/categories/$id';
  static const String autoCategorize = '/categories/auto-categorize';
  static const String recategorize = '/categories/recategorize';
  static const String categoryFeedback = '/categories/feedback';

  // RF-12: Bank accounts consolidated summary
  static const String bankAccountsSummary = '/banks/accounts/summary';

  // Savings goals endpoints
  static const String savingsGoals = '/goals';
  static String goalById(String id) => '/goals/$id';
  static String addContribution(String goalId) =>
      '/goals/$goalId/contributions';
  static String goalProgress(String goalId) => '/goals/$goalId/progress';
  static String goalContributionAdvice(String goalId) =>
      '/goals/$goalId/advice';
  static const String goalRecommendations = '/goals/recommendations';

  // RF-22 / HU-09: Predicción de gastos ML (backend → finora-ai)
  static const String predictExpenses = '/ai/predict-expenses';
  // RF-21 / HU-08: Recomendaciones de ahorro (backend → finora-ai)
  static const String aiSavings = '/ai/savings';
  static const String evaluateSavingsGoal = '/ai/evaluate-savings-goal';

  // RF-23 / HU-10: Detección de anomalías en gastos
  static const String detectAnomalies = '/ai/anomalies';
  // RF-24 / HU-11: Detección automática de suscripciones
  static const String detectSubscriptions = '/ai/subscriptions';
  // RF-25 / HU-12 / CU-04: Asistente conversacional IA
  static const String aiChat = '/ai/chat';
  // Snapshot financiero para contexto Gemini
  static const String aiContext = '/ai/context';
  // RF-26 / HU-13: Análisis de affordability "¿Puedo permitírmelo?"
  static const String aiAffordability = '/ai/affordability';
  // RF-27 / HU-14: Recomendaciones de optimización financiera
  static const String aiRecommendations = '/ai/recommendations';

  // RF-29 / RF-30: Statistics endpoints (backend /api/v1/stats/*)
  static const String statsSummary = '/stats/summary';
  static const String statsByCategory = '/stats/by-category';
  static const String statsMonthly = '/stats/monthly';
  static const String statsTrends = '/stats/trends';

  // Visualization endpoints (legacy — mantener compatibilidad)
  static const String dashboard = '/analytics/dashboard';
  static const String categorySpending = '/analytics/category-spending';
  static const String timeSeries = '/analytics/time-series';
  static const String financialSummary = '/analytics/summary';

  // Notifications endpoints (HU-06)
  static const String notifications = '/notifications';
  static String markAsRead(String id) => '/notifications/$id/read';
  static const String markAllNotificationsRead = '/notifications/read-all';
  static const String notificationSettings = '/notifications/settings';
  static const String registerPushToken = '/notifications/register-token';

  // Export endpoints
  static const String exportCsv = '/export/csv';
  static const String exportPdf = '/export/pdf';
  static const String shareExport = '/export/share';

  // Currency exchange rates
  static const String currencyRates = '/currency/rates';

  // Settings endpoints
  static const String settings = '/settings';
  static const String updateSettings = '/settings';
  static const String privacySettings = '/settings/privacy';

  // GDPR Compliance endpoints (RNF-04)
  static const String gdprPrivacyPolicy = '/gdpr/privacy-policy';
  static const String gdprDataProcessing = '/gdpr/data-processing';
  // DPO removed - not applicable
  static const String gdprConsents = '/gdpr/consents';
  static const String gdprUserConsents = '/gdpr/consents/user';
  static const String gdprConsentHistory = '/gdpr/consents/history';
  static const String gdprExport = '/gdpr/export';
  static const String gdprDeleteAccount = '/gdpr/delete-account';
  static String gdprWithdrawConsent(String consentType) =>
      '/gdpr/consents/$consentType';
}
