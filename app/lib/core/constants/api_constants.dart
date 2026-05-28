class ApiConstants {
  ApiConstants._();

  static const bool useMockAuth = bool.fromEnvironment(
    'MOCK_AUTH',
    defaultValue: true,
  );

  static const bool pushNotificationsEnabled = bool.fromEnvironment(
    'PUSH_NOTIFICATIONS_ENABLED',
    defaultValue: false,
  );

  static const String cognitoClientId = String.fromEnvironment(
    'COGNITO_CLIENT_ID',
    defaultValue: '',
  );

  static const String cognitoLoginDomain = String.fromEnvironment(
    'COGNITO_LOGIN_DOMAIN',
    defaultValue: 'https://login.getconscia.com',
  );

  static const String cognitoRedirectUri = String.fromEnvironment(
    'COGNITO_REDIRECT_URI',
    defaultValue: 'conscia://auth/callback',
  );

  static const String cognitoAppRedirectUri = 'conscia://auth/callback';

  static const String cognitoLogoutUri = String.fromEnvironment(
    'COGNITO_LOGOUT_URI',
    defaultValue: 'conscia://auth/logout',
  );

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:5248/api/',
  );

  // Auth
  static const String register = 'auth/register';
  static const String confirmRegistration = 'auth/confirm';
  static const String resendConfirmation = 'auth/resend-confirmation';
  static const String login = 'auth/login';
  static const String refreshToken = 'auth/refresh';
  static const String logout = 'auth/logout';
  static const String passkeyRegisterStart = 'auth/passkeys/register/start';
  static const String passkeyRegisterComplete =
      'auth/passkeys/register/complete';
  static const String passkeyLoginStart = 'auth/passkeys/login/start';
  static const String passkeyLoginComplete = 'auth/passkeys/login/complete';

  // User
  static const String profile = 'users/me';
  static const String profilePictureUpload =
      'users/me/profile-picture-upload-url';
  static const String preferences = 'users/me/preferences';
  static const String profileExport = 'users/me/export';

  // Transactions
  static const String transactions = 'transactions';
  static String transaction(String id) => 'transactions/$id';
  static const String transactionsSummary = 'transactions/summary';
  static const String scanReceipt = 'receipts/scan';
  static String receipt(String id) => 'receipts/$id';
  static String receiptConfirm(String id) => 'receipts/$id/confirm';
  static const String recurring = 'recurring';

  // Insights
  static const String behavioralInsights = 'insights/behavioral';

  // Regret Memory Insights
  static const String insightsSummary = 'insights/summary';
  static const String insightsCategories = 'insights/categories';
  static String insightsCategoryDetail(String category) =>
      'insights/categories/$category';
  static const String insightsMerchants = 'insights/merchants';
  static String insightsMerchantDetail(String merchant) =>
      'insights/merchants/$merchant';

  // Conscience Journey
  static const String conscienceJourney = 'conscience-journey';
  static const String conscienceJourneyEvents = 'conscience-journey/events';

  // Suggestions
  static const String purchaseSuggestions = 'suggestions/purchases';

  // Utterance parse (premium)
  static const String parseUtterance = 'transactions/parse-utterance';

  // Budgets
  static const String budgets = 'budgets';
  static String budget(String id) => 'budgets/$id';
  static const String budgetOverview = 'budgets/overview';

  // Categories
  static const String categories = 'categories';
  static String category(String id) => 'categories/$id';

  // Shared Conscia
  static const String familySpace = 'family-space';
  static const String familyOverview = 'family-space/overview';
  static const String familyMembers = 'family-space/members';
  static String familyMember(String id) => 'family-space/members/$id';
  static String familyMemberRole(String id) => 'family-space/members/$id/role';
  static String familyTransferOwnership(String id) =>
      'family-space/members/$id/transfer-ownership';
  static const String familyLeave = 'family-space/leave';
  static const String familyInvites = 'family-space/invites';
  static const String familyOutgoingInvites = 'family-space/invites/outgoing';
  static String familyInvite(String id) => 'family-space/invites/$id';
  static String familyInviteAccept(String id) =>
      'family-space/invites/$id/accept';
  static String familyInviteDecline(String id) =>
      'family-space/invites/$id/decline';

  // AI Assistant
  static const String aiAdvice = 'ai/pre-purchase';
  static const String aiReflection = 'ai/reflection';
  static const String aiChat = 'ai/chat';

  // Alerts
  static const String alerts = 'alerts';
  static String alert(String id) => 'alerts/$id';
  static String alertDismiss(String id) => 'alerts/$id/dismiss';

  // Device push notifications
  static const String pushDeviceTokens = 'push/device-tokens';

  // Subscriptions
  static const String subscriptionStatus = 'subscriptions/status';
  static const String verifyReceipt = 'subscriptions/verify';

  // Health (root-level, not under /api)
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
  static const Duration aiReceiveTimeout = Duration(seconds: 45);
}
