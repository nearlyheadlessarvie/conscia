import 'package:shared_preferences/shared_preferences.dart';

import '../services/location_assistance_service.dart';
import 'category_recents_provider.dart';
import 'insight_feed_provider.dart';
import 'sign_in_preference_provider.dart';
import 'usage_provider.dart';

Future<void> clearDeletedAccountLocalData(SharedPreferences prefs) async {
  await clearRememberedSignInIdentity(prefs);
  await clearMonthlyUsage(prefs);
  await clearRecentCategories(prefs);
  await clearLocationAssistanceHistory(prefs);
  await clearInsightDismissals(prefs);
}
