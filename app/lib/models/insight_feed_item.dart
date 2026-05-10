enum InsightFeedKind {
  budgetTrend,
  regretSummary,
  impulseTrend,
  weeklyMood,
  worthIt,
  merchantPattern,
}

enum InsightFeedTone {
  positive,
  caution,
  urgent,
  neutral,
}

enum InsightFeedSection {
  thisWeek,
  budgetTrends,
  regretPatterns,
  recentSignals,
}

enum InsightFeedMascot {
  none,
  angel,
  devil,
  both,
}

class InsightFeedItem {
  const InsightFeedItem({
    required this.id,
    required this.kind,
    required this.priority,
    required this.title,
    required this.body,
    required this.section,
    required this.tone,
    required this.mascot,
    this.metric,
    this.caption,
    this.route = '/insights',
    this.mascotFrame,
    this.expiresKey,
    this.dismissible = true,
    this.showOnDashboard = true,
  });

  final String id;
  final InsightFeedKind kind;
  final int priority;
  final String title;
  final String body;
  final String? metric;
  final String? caption;
  final String route;
  final InsightFeedSection section;
  final InsightFeedTone tone;
  final InsightFeedMascot mascot;
  final String? mascotFrame;
  final String? expiresKey;
  final bool dismissible;
  final bool showOnDashboard;
}
