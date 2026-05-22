import '../../models/conscience_journey.dart';

class LevelUpContent {
  const LevelUpContent({
    required this.eyebrow,
    required this.payoff,
    required this.body,
  });

  final String eyebrow;
  final String payoff;
  final String body;
}

const List<ConscienceLevel> _journeyLevels = [
  ConscienceLevel(
    key: 'awakening',
    title: 'Awakening',
    requiredXp: 0,
  ),
  ConscienceLevel(
    key: 'impulse_spotter',
    title: 'Impulse Spotter',
    requiredXp: 120,
  ),
  ConscienceLevel(
    key: 'budget_guardian',
    title: 'Budget Guardian',
    requiredXp: 400,
  ),
  ConscienceLevel(
    key: 'conscience_captain',
    title: 'Conscience Captain',
    requiredXp: 1000,
  ),
  ConscienceLevel(
    key: 'money_monk',
    title: 'Money Monk',
    requiredXp: 2200,
  ),
];

const _previewXpIntoLevel = <String, int>{
  'awakening': 52,
  'impulse_spotter': 55,
  'budget_guardian': 85,
  'conscience_captain': 160,
  'money_monk': 240,
};

const _previewMomentumDays = <String, int>{
  'awakening': 1,
  'impulse_spotter': 2,
  'budget_guardian': 6,
  'conscience_captain': 11,
  'money_monk': 18,
};

const _contentByLevel = <String, LevelUpContent>{
  'awakening': LevelUpContent(
    eyebrow: 'Level up',
    payoff: 'You are paying attention sooner.',
    body:
        'You are beginning to notice the small money moments that shape your days.',
  ),
  'impulse_spotter': LevelUpContent(
    eyebrow: 'Level up',
    payoff: 'Your money rhythm is getting steadier.',
    body:
        'You are catching impulses earlier and giving yourself more room to choose.',
  ),
  'budget_guardian': LevelUpContent(
    eyebrow: 'Level up',
    payoff: 'Your boundaries are starting to hold.',
    body:
        'You are building steadier money boundaries without turning every choice into pressure.',
  ),
  'conscience_captain': LevelUpContent(
    eyebrow: 'Level up',
    payoff: 'Your decisions feel more directed now.',
    body:
        'You are steering with more clarity, using signals from your own habits instead of noise.',
  ),
  'money_monk': LevelUpContent(
    eyebrow: 'Level up',
    payoff: 'Calm is becoming part of your pattern.',
    body:
        'You are finding a calmer rhythm with money, one considered moment at a time.',
  ),
};

LevelUpContent resolveLevelUpContent(String levelKey) {
  final normalized = normalizeJourneyKey(levelKey);
  return _contentByLevel[normalized] ??
      const LevelUpContent(
        eyebrow: 'Level up',
        payoff: 'You are settling into a steadier rhythm.',
        body:
            'This level marks a quieter kind of progress: more awareness, more steadiness, and more trust in your rhythm.',
      );
}

ConscienceJourneySummary buildLevelUpPreviewSummary(String levelKey) {
  final normalized = normalizeJourneyKey(levelKey);
  final currentLevel = resolveJourneyLevel(normalized) ?? _journeyLevels.first;
  final currentIndex = _journeyLevels.indexOf(currentLevel);
  final nextLevel = currentIndex >= 0 && currentIndex < _journeyLevels.length - 1
      ? _journeyLevels[currentIndex + 1]
      : null;
  final xpIntoLevel = _previewXpIntoLevel[normalized] ?? 48;
  final momentumDays = _previewMomentumDays[normalized] ?? 3;
  final xpTotal = currentLevel.requiredXp + xpIntoLevel;

  return ConscienceJourneySummary(
    xpTotal: xpTotal,
    currentLevel: currentLevel,
    nextLevel: nextLevel,
    xpIntoLevel: xpIntoLevel,
    xpToNextLevel: nextLevel == null
        ? 0
        : (nextLevel.requiredXp - currentLevel.requiredXp) - xpIntoLevel,
    momentumDays: momentumDays,
    bestMomentumDays: momentumDays + 4,
    weeklyQuests: _previewQuests(normalized),
    badges: _previewBadges(normalized),
  );
}

ConscienceLevel? resolveJourneyLevel(String levelKey) {
  final normalized = normalizeJourneyKey(levelKey);
  for (final level in _journeyLevels) {
    if (level.key == normalized) {
      return level;
    }
  }

  return null;
}

String normalizeJourneyKey(String key) =>
    key.trim().toLowerCase().replaceAll('-', '_');

List<ConscienceQuest> _previewQuests(String levelKey) {
  return [
    ConscienceQuest(
      key: 'reflect_three_purchases',
      title: 'Reflect on 3 purchases',
      description: 'Turn recent decisions into useful signal.',
      progress: levelKey == 'awakening' ? 1 : 3,
      target: 3,
      xpReward: 15,
      isCompleted: levelKey != 'awakening',
      completedAt:
          levelKey == 'awakening' ? null : DateTime.utc(2026, 5, 22, 9, 0),
    ),
  ];
}

List<ConscienceBadge> _previewBadges(String levelKey) {
  return [
    ConscienceBadge(
      key: 'first_reflection',
      title: 'First Reflection',
      description: 'Reflected on your first purchase.',
      progress: 1,
      target: 1,
      isUnlocked: true,
      unlockedAt: DateTime.utc(2026, 5, 18, 8, 0),
    ),
    ConscienceBadge(
      key: 'budget_rescuer',
      title: 'Budget Rescuer',
      description: 'Created a budget from a nudge.',
      progress: levelKey == 'awakening' ? 0 : 1,
      target: 1,
      isUnlocked: levelKey != 'awakening',
      unlockedAt:
          levelKey == 'awakening' ? null : DateTime.utc(2026, 5, 20, 10, 0),
    ),
  ];
}
