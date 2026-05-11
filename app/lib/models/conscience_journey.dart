class ConscienceJourneySummary {
  final int xpTotal;
  final ConscienceLevel currentLevel;
  final ConscienceLevel? nextLevel;
  final int xpIntoLevel;
  final int xpToNextLevel;
  final int momentumDays;
  final int bestMomentumDays;
  final List<ConscienceQuest> weeklyQuests;
  final List<ConscienceBadge> badges;
  final ConscienceMascotMoment? recentMascotMoment;

  const ConscienceJourneySummary({
    required this.xpTotal,
    required this.currentLevel,
    required this.nextLevel,
    required this.xpIntoLevel,
    required this.xpToNextLevel,
    required this.momentumDays,
    required this.bestMomentumDays,
    required this.weeklyQuests,
    required this.badges,
    this.recentMascotMoment,
  });

  factory ConscienceJourneySummary.fromJson(Map<String, dynamic> json) {
    return ConscienceJourneySummary(
      xpTotal: json['xpTotal'] as int? ?? 0,
      currentLevel: ConscienceLevel.fromJson(
        json['currentLevel'] as Map<String, dynamic>,
      ),
      nextLevel: json['nextLevel'] == null
          ? null
          : ConscienceLevel.fromJson(
              json['nextLevel'] as Map<String, dynamic>,
            ),
      xpIntoLevel: json['xpIntoLevel'] as int? ?? 0,
      xpToNextLevel: json['xpToNextLevel'] as int? ?? 0,
      momentumDays: json['momentumDays'] as int? ?? 0,
      bestMomentumDays: json['bestMomentumDays'] as int? ?? 0,
      weeklyQuests: (json['weeklyQuests'] as List<dynamic>? ?? [])
          .map((item) => ConscienceQuest.fromJson(item as Map<String, dynamic>))
          .toList(),
      badges: (json['badges'] as List<dynamic>? ?? [])
          .map((item) => ConscienceBadge.fromJson(item as Map<String, dynamic>))
          .toList(),
      recentMascotMoment: json['recentMascotMoment'] == null
          ? null
          : ConscienceMascotMoment.fromJson(
              json['recentMascotMoment'] as Map<String, dynamic>,
            ),
    );
  }
}

class ConscienceLevel {
  final String key;
  final String title;
  final int requiredXp;

  const ConscienceLevel({
    required this.key,
    required this.title,
    required this.requiredXp,
  });

  factory ConscienceLevel.fromJson(Map<String, dynamic> json) {
    return ConscienceLevel(
      key: json['key'] as String,
      title: json['title'] as String,
      requiredXp: json['requiredXp'] as int,
    );
  }
}

class ConscienceQuest {
  final String key;
  final String title;
  final String description;
  final int progress;
  final int target;
  final int xpReward;
  final bool isCompleted;
  final DateTime? completedAt;

  const ConscienceQuest({
    required this.key,
    required this.title,
    required this.description,
    required this.progress,
    required this.target,
    required this.xpReward,
    required this.isCompleted,
    this.completedAt,
  });

  factory ConscienceQuest.fromJson(Map<String, dynamic> json) {
    return ConscienceQuest(
      key: json['key'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      progress: json['progress'] as int? ?? 0,
      target: json['target'] as int? ?? 0,
      xpReward: json['xpReward'] as int? ?? 0,
      isCompleted: json['isCompleted'] as bool? ?? false,
      completedAt: _parseDate(json['completedAt']),
    );
  }
}

class ConscienceBadge {
  final String key;
  final String title;
  final String description;
  final int progress;
  final int target;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  const ConscienceBadge({
    required this.key,
    required this.title,
    required this.description,
    required this.progress,
    required this.target,
    required this.isUnlocked,
    this.unlockedAt,
  });

  factory ConscienceBadge.fromJson(Map<String, dynamic> json) {
    return ConscienceBadge(
      key: json['key'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      progress: json['progress'] as int? ?? 0,
      target: json['target'] as int? ?? 0,
      isUnlocked: json['isUnlocked'] as bool? ?? false,
      unlockedAt: _parseDate(json['unlockedAt']),
    );
  }
}

class ConscienceMascotMoment {
  final String key;
  final String persona;
  final String title;
  final String message;
  final DateTime createdAt;

  const ConscienceMascotMoment({
    required this.key,
    required this.persona,
    required this.title,
    required this.message,
    required this.createdAt,
  });

  factory ConscienceMascotMoment.fromJson(Map<String, dynamic> json) {
    return ConscienceMascotMoment(
      key: json['key'] as String,
      persona: json['persona'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class ConscienceJourneyUpdate {
  final ConscienceJourneySummary summary;
  final int xpAwarded;
  final bool wasDuplicate;
  final bool leveledUp;
  final List<String> completedQuestKeys;
  final List<String> unlockedBadgeKeys;
  final ConscienceMascotMoment? mascotMoment;

  const ConscienceJourneyUpdate({
    required this.summary,
    required this.xpAwarded,
    required this.wasDuplicate,
    required this.leveledUp,
    required this.completedQuestKeys,
    required this.unlockedBadgeKeys,
    this.mascotMoment,
  });

  factory ConscienceJourneyUpdate.fromJson(Map<String, dynamic> json) {
    return ConscienceJourneyUpdate(
      summary: ConscienceJourneySummary.fromJson(
        json['summary'] as Map<String, dynamic>,
      ),
      xpAwarded: json['xpAwarded'] as int? ?? 0,
      wasDuplicate: json['wasDuplicate'] as bool? ?? false,
      leveledUp: json['leveledUp'] as bool? ?? false,
      completedQuestKeys:
          (json['completedQuestKeys'] as List<dynamic>? ?? []).cast<String>(),
      unlockedBadgeKeys:
          (json['unlockedBadgeKeys'] as List<dynamic>? ?? []).cast<String>(),
      mascotMoment: json['mascotMoment'] == null
          ? null
          : ConscienceMascotMoment.fromJson(
              json['mascotMoment'] as Map<String, dynamic>,
            ),
    );
  }
}

DateTime? _parseDate(dynamic value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.parse(value);
}
