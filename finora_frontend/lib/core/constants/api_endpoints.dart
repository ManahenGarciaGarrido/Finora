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
      return 'http://localhost:3000/api/v1';
    }

    // For local development with Docker
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000/api/v1';
    }

    // iOS, Windows, macOS, Linux
    return 'http://localhost:3000/api/v1';
  }

  // Authentication endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String verifyEmail = '/auth/verify-email';
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
  static const String filterTransactions = '/transactions/filter';
  static const String syncOfflineTransactions = '/transactions/sync';

  // Bank sync endpoints
  static const String bankInstitutions = '/banks/institutions';
  static const String connectBank = '/banks/connect';
  static const String bankAccounts = '/banks/accounts';
  static String disconnectBank(String id) => '/banks/$id/disconnect';
  static String syncBank(String id) => '/banks/$id/sync';
  static String bankSyncStatus(String id) => '/banks/$id/sync-status';

  // Categories endpoints
  static const String categories = '/categories';
  static String categoryById(String id) => '/categories/$id';
  static const String autoCategorize = '/categories/auto-categorize';
  static const String recategorize = '/categories/recategorize';

  // Savings goals endpoints
  static const String savingsGoals = '/goals';
  static String goalById(String id) => '/goals/$id';
  static String addContribution(String goalId) => '/goals/$goalId/contributions';
  static String goalProgress(String goalId) => '/goals/$goalId/progress';
  static const String goalRecommendations = '/goals/recommendations';

  // Predictions endpoints
  static const String predictExpenses = '/predictions/expenses';
  static const String detectAnomalies = '/predictions/anomalies';
  static const String detectSubscriptions = '/predictions/subscriptions';
  static const String recurringExpenses = '/predictions/recurring';
  static const String predictionInsights = '/predictions/insights';

  // AI Assistant endpoints
  static const String aiChat = '/ai/chat';
  static const String affordability = '/ai/affordability';
  static const String recommendations = '/ai/recommendations';
  static const String conversationHistory = '/ai/conversation-history';
  static String clearConversation(String conversationId) => '/ai/conversation/$conversationId/clear';

  // Visualization endpoints
  static const String dashboard = '/analytics/dashboard';
  static const String categorySpending = '/analytics/category-spending';
  static const String timeSeries = '/analytics/time-series';
  static const String financialSummary = '/analytics/summary';

  // Notifications endpoints
  static const String notifications = '/notifications';
  static String markAsRead(String id) => '/notifications/$id/read';
  static const String notificationSettings = '/notifications/settings';
  static const String registerPushToken = '/notifications/register-token';

  // Export endpoints
  static const String exportCsv = '/export/csv';
  static const String exportPdf = '/export/pdf';
  static const String shareExport = '/export/share';

  // Settings endpoints
  static const String settings = '/settings';
  static const String updateSettings = '/settings';
  static const String privacySettings = '/settings/privacy';

  // GDPR Compliance endpoints (RNF-04)
  static const String gdprPrivacyPolicy = '/gdpr/privacy-policy';
  static const String gdprDataProcessing = '/gdpr/data-processing';
  static const String gdprDPO = '/gdpr/dpo';
  static const String gdprConsents = '/gdpr/consents';
  static const String gdprUserConsents = '/gdpr/consents/user';
  static const String gdprConsentHistory = '/gdpr/consents/history';
  static const String gdprExport = '/gdpr/export';
  static const String gdprDeleteAccount = '/gdpr/delete-account';
  static String gdprWithdrawConsent(String consentType) => '/gdpr/consents/$consentType';
}
