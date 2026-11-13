import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'usage_provider.dart';

const _recentCategoriesKey = 'recent_categories';
const _maxRecentCategories = 10;

List<String> orderCategoriesByRecency({
  required List<String> categories,
  required List<String> recents,
}) {
  final ordered = <String>[];

  for (final category in recents) {
    if (categories.contains(category) && !ordered.contains(category)) {
      ordered.add(category);
    }
  }

  for (final category in categories) {
    if (!ordered.contains(category)) {
      ordered.add(category);
    }
  }

  return ordered;
}

class RecentCategoryNotifier extends StateNotifier<List<String>> {
  RecentCategoryNotifier(this._prefs) : super(_load(_prefs));

  final SharedPreferences _prefs;

  static List<String> _load(SharedPreferences prefs) {
    return List<String>.from(
        prefs.getStringList(_recentCategoriesKey) ?? const []);
  }

  void record(String category) {
    final normalized = category.trim();
    if (normalized.isEmpty) return;

    state = [
      normalized,
      ...state.where((existing) => existing != normalized),
    ].take(_maxRecentCategories).toList();
    _prefs.setStringList(_recentCategoriesKey, state);
  }
}

Future<void> clearRecentCategories(SharedPreferences prefs) async {
  await prefs.remove(_recentCategoriesKey);
}

final recentCategoryProvider =
    StateNotifierProvider<RecentCategoryNotifier, List<String>>(
  (ref) => RecentCategoryNotifier(ref.watch(sharedPreferencesProvider)),
);
