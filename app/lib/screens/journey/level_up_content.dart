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
