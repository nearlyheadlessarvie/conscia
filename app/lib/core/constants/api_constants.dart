class ApiConstants {
  ApiConstants._();

  static const bool useMockAuth = bool.fromEnvironment(
    'MOCK_AUTH',
    defaultValue: true,
  );

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:5248/api/v1/',
  );

  // Auth
  static const String register = 'auth/register';
  static const String login = 'auth/login';
  static const String refreshToken = 'auth/refresh';
  static const String logout = 'auth/logout';
  static const String appleSignIn = 'auth/apple';
  static const String googleSignIn = 'auth/google';

  // User
  static const String profile = 'users/me';
  static const String preferences = 'users/me/preferences';
  static const String profileExport = 'users/me/export';

  // Transactions
  static const String transactions = 'transactions';
  static String transaction(String id) => 'transactions/$id';
  static const String transactionsSummary = 'transactions/summary';
  static const String scanReceipt = 'transactions/scan';

  // Insights
  static const String behavioralInsights = 'insights/behavioral';

  // Suggestions
  static const String purchaseSuggestions = 'suggestions/purchases';

  // Utterance parse (premium)
  static const String parseUtterance = 'transactions/parse-utterance';

  // Budgets
  static const String budgets = 'budgets';
  static String budget(String id) => 'budgets/$id';
  static const String budgetOverview = 'budgets/overview';

  // AI Assistant
  static const String aiAdvice = 'ai/pre-purchase';
  static const String aiReflection = 'ai/reflection';
  static const String aiChat = 'ai/chat';

  // Alerts
  static const String alerts = 'alerts';
  static String alert(String id) => 'alerts/$id';
  static String alertDismiss(String id) => 'alerts/$id/dismiss';

  // Subscriptions
  static const String subscriptionStatus = 'subscriptions/status';
  static const String verifyReceipt = 'subscriptions/verify';

  // Health (root-level, not under /api/v1)
  static String get health => '$_hostUrl/health';
  static String get healthLive => '$_hostUrl/health/live';
  static String get healthReady => '$_hostUrl/health/ready';

  static String get _hostUrl {
    final uri = Uri.parse(baseUrl);
    return '${uri.scheme}://${uri.host}:${uri.port}';
  }

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 15);
}
