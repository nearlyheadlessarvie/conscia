import 'conscia_glyph_kind.dart';

class ConsciaGlyphMapper {
  ConsciaGlyphMapper._();

  static final RegExp _slugPattern = RegExp(r'[^a-z0-9]+');

  static ConsciaGlyphKind category(String category) {
    final normalized = _normalize(category);
    return switch (normalized) {
      'dining' || 'restaurants' || 'food' || 'takeout' => ConsciaGlyphKind.dining,
      'coffee' || 'cafe' || 'tea' => ConsciaGlyphKind.coffee,
      'groceries' || 'grocery' || 'supermarket' || 'market' =>
        ConsciaGlyphKind.groceries,
      'transport' || 'fuel' || 'parking' || 'taxi' || 'rideshare' =>
        ConsciaGlyphKind.transport,
      'entertainment' || 'events' || 'movies' => ConsciaGlyphKind.entertainment,
      'gaming' || 'games' => ConsciaGlyphKind.gaming,
      'shopping' || 'clothing' || 'beauty' || 'retail' =>
        ConsciaGlyphKind.shopping,
      'health' || 'pharmacy' || 'fitness' || 'medical' =>
        ConsciaGlyphKind.health,
      'bills' || 'taxes' || 'utilities' || 'phone' || 'internet' =>
        ConsciaGlyphKind.bills,
      'education' || 'books' || 'school' => ConsciaGlyphKind.education,
      'travel' || 'flights' || 'hotel' => ConsciaGlyphKind.travel,
      'subscriptions' || 'subscription' || 'recurring' =>
        ConsciaGlyphKind.subscription,
      'salary' || 'payroll' || 'paycheck' => ConsciaGlyphKind.salary,
      'freelance' || 'contract' || 'client' => ConsciaGlyphKind.freelance,
      'business' || 'store' || 'sales' => ConsciaGlyphKind.business,
      'investment' || 'stocks' || 'crypto' => ConsciaGlyphKind.investment,
      'rental-income' || 'rental' || 'rental-property' =>
        ConsciaGlyphKind.rentalIncome,
      'bonus' || 'reward' => ConsciaGlyphKind.bonus,
      'income' => ConsciaGlyphKind.income,
      'home' || 'repairs' || 'maintenance' => ConsciaGlyphKind.home,
      'gift' || 'charity' || 'pets' || 'childcare' => ConsciaGlyphKind.gift,
      'insurance' => ConsciaGlyphKind.shield,
      'bank' || 'banking' => ConsciaGlyphKind.bank,
      'cash' || 'atm' || 'withdrawal' => ConsciaGlyphKind.cash,
      'card' || 'credit-card' || 'debit-card' => ConsciaGlyphKind.card,
      'transfer' || 'transfers' => ConsciaGlyphKind.transfer,
      'refund' || 'return' => ConsciaGlyphKind.refund,
      'debt' || 'loan' || 'credit' => ConsciaGlyphKind.debt,
      'save' || 'saving' || 'savings' => ConsciaGlyphKind.savings,
      'calendar' || 'reminder' => ConsciaGlyphKind.calendar,
      'alert' || 'warning' => ConsciaGlyphKind.signal,
      'bank-fees' || 'fee' || 'fees' || 'charges' => ConsciaGlyphKind.wallet,
      'paper-trail-item' || 'record' || 'item' => ConsciaGlyphKind.receipt,
      'other' => ConsciaGlyphKind.more,
      _ => _semanticCategoryFallback(normalized),
    };
  }

  static ConsciaGlyphKind quest(String key) {
    return switch (_normalize(key)) {
      'reflect-three-purchases' => ConsciaGlyphKind.reflect,
      'check-before-purchase' => ConsciaGlyphKind.pause,
      'review-regret-pattern' => ConsciaGlyphKind.recurring,
      'read-two-insights' => ConsciaGlyphKind.insight,
      'create-budget-guardrail' => ConsciaGlyphKind.shield,
      'send-family-invite' => ConsciaGlyphKind.family,
      'add-family-expense' => ConsciaGlyphKind.receipt,
      _ => ConsciaGlyphKind.trail,
    };
  }

  static ConsciaGlyphKind milestone(String key) {
    return switch (_normalize(key)) {
      'first-reflection' => ConsciaGlyphKind.reflect,
      'pause-before-purchase' || 'pre-purchase-habit' => ConsciaGlyphKind.pause,
      'budget-rescuer' => ConsciaGlyphKind.shield,
      'regret-pattern-spotted' || 'reflection-streak' => ConsciaGlyphKind.signal,
      'worth-it-week' => ConsciaGlyphKind.trophy,
      'family-founder' || 'family-planner' => ConsciaGlyphKind.family,
      'insight-reader' || 'deep-thinker' => ConsciaGlyphKind.insight,
      _ => ConsciaGlyphKind.trophy,
    };
  }

  static ConsciaGlyphKind level(String key) {
    return switch (_normalize(key)) {
      'awakening' => ConsciaGlyphKind.sprout,
      'impulse-spotter' => ConsciaGlyphKind.signal,
      'budget-guardian' => ConsciaGlyphKind.shield,
      'conscience-captain' => ConsciaGlyphKind.compass,
      'money-monk' => ConsciaGlyphKind.monk,
      _ => ConsciaGlyphKind.crown,
    };
  }

  static String normalize(String value) => _normalize(value);

  static String _normalize(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll(_slugPattern, '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');

  static ConsciaGlyphKind _semanticCategoryFallback(String normalized) {
    if (normalized.contains('fee') ||
        normalized.contains('money') ||
        normalized.contains('finance')) {
      return ConsciaGlyphKind.wallet;
    }
    if (normalized.contains('alert') || normalized.contains('warn')) {
      return ConsciaGlyphKind.signal;
    }
    if (normalized.contains('receipt') ||
        normalized.contains('record') ||
        normalized.contains('invoice')) {
      return ConsciaGlyphKind.receipt;
    }
    if (normalized.contains('journey') ||
        normalized.contains('progress') ||
        normalized.contains('path')) {
      return ConsciaGlyphKind.trail;
    }
    return ConsciaGlyphKind.more;
  }
}
