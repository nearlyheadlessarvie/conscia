import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MonthlyUsage {
  final int aiAssists;
  final int reflections;
  final int month;
  final int year;

  const MonthlyUsage({
    this.aiAssists = 0,
    this.reflections = 0,
    required this.month,
    required this.year,
  });

  bool get isCurrentMonth {
    final now = DateTime.now();
    return month == now.month && year == now.year;
  }

  MonthlyUsage ensureCurrentMonth() {
    if (isCurrentMonth) return this;
    final now = DateTime.now();
    return MonthlyUsage(month: now.month, year: now.year);
  }

  MonthlyUsage incrementAiAssists() {
    final current = ensureCurrentMonth();
    return MonthlyUsage(
      aiAssists: current.aiAssists + 1,
      reflections: current.reflections,
      month: current.month,
      year: current.year,
    );
  }

  MonthlyUsage incrementReflections() {
    final current = ensureCurrentMonth();
    return MonthlyUsage(
      aiAssists: current.aiAssists,
      reflections: current.reflections + 1,
      month: current.month,
      year: current.year,
    );
  }
}

const _keyAiAssists = 'usage_ai_assists';
const _keyReflections = 'usage_reflections';
const _keyMonth = 'usage_month';
const _keyYear = 'usage_year';

class MonthlyUsageNotifier extends StateNotifier<MonthlyUsage> {
  final SharedPreferences _prefs;

  MonthlyUsageNotifier(this._prefs) : super(_loadFromPrefs(_prefs));

  static MonthlyUsage _loadFromPrefs(SharedPreferences prefs) {
    final storedMonth = prefs.getInt(_keyMonth) ?? 0;
    final storedYear = prefs.getInt(_keyYear) ?? 0;
    final now = DateTime.now();

    if (storedMonth != now.month || storedYear != now.year) {
      return MonthlyUsage(month: now.month, year: now.year);
    }

    return MonthlyUsage(
      aiAssists: prefs.getInt(_keyAiAssists) ?? 0,
      reflections: prefs.getInt(_keyReflections) ?? 0,
      month: storedMonth,
      year: storedYear,
    );
  }

  void recordAiAssist() {
    state = state.incrementAiAssists();
    _persist();
  }

  void recordReflection() {
    state = state.incrementReflections();
    _persist();
  }

  void _persist() {
    _prefs.setInt(_keyAiAssists, state.aiAssists);
    _prefs.setInt(_keyReflections, state.reflections);
    _prefs.setInt(_keyMonth, state.month);
    _prefs.setInt(_keyYear, state.year);
  }
}

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in main() with '
    'SharedPreferences.getInstance()',
  );
});

final monthlyUsageProvider =
    StateNotifierProvider<MonthlyUsageNotifier, MonthlyUsage>(
  (ref) => MonthlyUsageNotifier(ref.watch(sharedPreferencesProvider)),
);
