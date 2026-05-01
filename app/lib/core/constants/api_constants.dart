class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'https://api.conscia.app/api/v1';

  // Auth
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String refreshToken = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String appleSignIn = '/auth/apple';
  static const String googleSignIn = '/auth/google';

  // User
  static const String profile = '/users/me';
  static const String preferences = '/users/me/preferences';

  // Transactions
  static const String transactions = '/transactions';
  static String transaction(String id) => '/transactions/$id';
  static const String transactionsSummary = '/transactions/summary';
  static const String scanReceipt = '/transactions/scan';

  // Budgets
  static const String budgets = '/budgets';
  static String budget(String id) => '/budgets/$id';
  static const String budgetOverview = '/budgets/overview';

  // AI Assistant
  static const String aiAdvice = '/ai/advice';
  static const String aiChat = '/ai/chat';

  // Alerts
  static const String alerts = '/alerts';
  static String alert(String id) => '/alerts/$id';
  static String alertDismiss(String id) => '/alerts/$id/dismiss';

  // Subscriptions
  static const String subscriptionStatus = '/subscriptions/status';
  static const String verifyReceipt = '/subscriptions/verify';

  // Health
  static const String health = '/health';
  static const String healthLive = '/health/live';
  static const String healthReady = '/health/ready';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 15);
}
