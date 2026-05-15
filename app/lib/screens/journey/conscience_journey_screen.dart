import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/assets/mascot_sprite_sheet.dart';
import '../../core/theme/app_colors.dart';
import '../../models/conscience_journey.dart';
import '../../providers/conscience_journey_provider.dart';
import '../../widgets/editorial_sticky_header.dart';
import '../../widgets/feed_card.dart';
import '../../widgets/screen_section.dart';

class ConscienceJourneyScreen extends ConsumerStatefulWidget {
  const ConscienceJourneyScreen({super.key});

  @override
  ConsumerState<ConscienceJourneyScreen> createState() => _ConscienceJourneyScreenState();
}

class _ConscienceJourneyScreenState extends ConsumerState<ConscienceJourneyScreen> {
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  void _handleScroll() {
    final nextOffset = _scrollController.hasClients ? _scrollController.offset : 0.0;
    if ((nextOffset - _scrollOffset).abs() < 1) return;
    setState(() => _scrollOffset = nextOffset);
  }

  @override
  Widget build(BuildContext context) {
    final journeyAsync = ref.watch(conscienceJourneyProvider);
    final colors = Theme.of(context).appColors;
    final stickyProgress = ((_scrollOffset - 5) / 10).clamp(0.0, 1.0);
    final topPadding = MediaQuery.paddingOf(context).top;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [colors.pageTop, colors.pageBottom],
          ),
        ),
        child: Stack(
          children: [
            journeyAsync.when(
              loading: () => _buildLoading(),
              error: (_, __) => _buildError(),
              data: (summary) => _buildContent(context, summary),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: EditorialStickyHeader(
                key: const ValueKey('journey-sticky-header'),
                title: 'Journey',
                progress: stickyProgress,
                topPadding: topPadding,
                trailing: IconButton(
                  tooltip: 'Journey guide',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.help_outline_rounded),
                  onPressed: () => _showJourneyGuide(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return SingleChildScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.58,
        child: const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _buildError() {
    return SingleChildScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 96, 20, 28),
      child: const _JourneyMessageCard(
        icon: Icons.auto_awesome_rounded,
        title: 'Journey is taking a breather',
        body: 'We could not load your achievements just now.',
      ),
    );
  }

  Widget _buildContent(BuildContext context, ConscienceJourneySummary summary) {
    final topPadding = MediaQuery.paddingOf(context).top;
    return SingleChildScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      child: ConscienceJourneyContent(
        summary: summary,
        headerTopInset: topPadding + 60,
      ),
    );
  }

  void _showJourneyGuide(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => const _JourneyGuideSheet(),
    );
  }
}

class ConscienceJourneyContent extends StatelessWidget {
  const ConscienceJourneyContent({
    super.key,
    required this.summary,
    this.headerTopInset = 96,
  });

  final ConscienceJourneySummary summary;
  final double headerTopInset;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _JourneyHeroBleed(summary: summary, topInset: headerTopInset),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ScreenSection(
                title: "This week's quests",
                compact: true,
                child: Column(
                  children: [
                    for (final quest in summary.weeklyQuests)
                      _QuestCard(quest: quest),
                  ],
                ),
              ),
              _AchievementsSection(badges: summary.badges),
              if (summary.recentMascotMoment case final moment?)
                ScreenSection(
                  title: 'Mascot moment',
                  subtitle:
                      'A tiny dramatic reading from your financial conscience.',
                  child: _MascotMomentCard(moment: moment),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _AchievementsSection extends StatelessWidget {
  const _AchievementsSection({required this.badges});

  final List<ConscienceBadge> badges;

  void _showAllAchievements(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _AllAchievementsSheet(badges: badges),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final appColors = Theme.of(context).appColors;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _showAllAchievements(context),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'ACHIEVEMENTS',
                      style: textTheme.labelSmall?.copyWith(
                        color: appColors.mutedInk,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.9,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, size: 18, color: appColors.mutedInk),
                ],
              ),
            ),
          ),
          _BadgeRow(badges: badges),
        ],
      ),
    );
  }
}

class _JourneyHeroBleed extends StatelessWidget {
  const _JourneyHeroBleed({required this.summary, this.topInset = 96});

  final ConscienceJourneySummary summary;
  final double topInset;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).textTheme;
    final nextLevel = summary.nextLevel;
    final levelSpan = nextLevel == null
        ? 1
        : (nextLevel.requiredXp - summary.currentLevel.requiredXp);
    final progress = levelSpan <= 0
        ? 1.0
        : (summary.xpIntoLevel / levelSpan).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, topInset + 12, 20, 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.navySoft, colors.amberSoft],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(
            width: 220,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  left: 16,
                  top: 0,
                  child: MascotSpriteFrame(
                    atlas: angelMascotAtlas,
                    frameName: '4_win.png',
                    width: 74,
                  ),
                ),
                Positioned(
                  child: Text('⚔️', style: TextStyle(fontSize: 56)),
                ),
                Positioned(
                  right: 16,
                  top: 0,
                  child: MascotSpriteFrame(
                    atlas: devilMascotAtlas,
                    frameName: '5_win.png',
                    width: 74,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Level ${_levelNumber(summary.currentLevel)}',
            style: textTheme.labelLarge?.copyWith(
              color: colors.deepNavy,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            summary.currentLevel.title,
            style:
                textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            nextLevel == null
                ? '${summary.xpTotal} XP · Top level reached'
                : '${summary.xpIntoLevel} / ${nextLevel.requiredXp - summary.currentLevel.requiredXp} XP to ${nextLevel.title}',
            style: textTheme.bodySmall
                ?.copyWith(color: colors.ink.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: progress,
              backgroundColor: colors.deepNavy.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(
                colors.deepNavy.withValues(alpha: 0.55),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.local_fire_department_rounded,
                size: 15,
                color: colors.deepNavy.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 5),
              Text(
                '${summary.momentumDays}-day streak',
                style: textTheme.labelMedium?.copyWith(
                  color: colors.deepNavy,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (summary.bestMomentumDays > summary.momentumDays) ...[
                Text(
                  '  ·  best ${summary.bestMomentumDays}',
                  style: textTheme.labelSmall?.copyWith(
                    color: colors.deepNavy.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  int _levelNumber(ConscienceLevel level) {
    const order = [
      'awakening',
      'impulse_spotter',
      'budget_guardian',
      'conscience_captain',
      'money_monk',
    ];
    final index = order.indexOf(level.key);
    return index < 0 ? 1 : index + 1;
  }
}

class _QuestCard extends StatelessWidget {
  const _QuestCard({required this.quest});

  final ConscienceQuest quest;

  static IconData _iconFor(String key) {
    return switch (key) {
      'reflect_three_purchases' => Icons.auto_stories_rounded,
      'check_before_purchase' => Icons.psychology_rounded,
      'review_regret_pattern' => Icons.loop_rounded,
      'send_family_invite' => Icons.group_add_rounded,
      'add_family_expense' => Icons.receipt_long_rounded,
      _ => Icons.flag_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final appColors = Theme.of(context).appColors;
    final iconColor = quest.isCompleted ? colors.primary : colors.tertiary;
    final isBinary = quest.target == 1;
    final progress =
        isBinary ? 0.0 : (quest.progress / quest.target).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: FeedCard(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Row(
          children: [
            _IconBadge(
              icon: quest.isCompleted ? Icons.check_rounded : _iconFor(quest.key),
              color: iconColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    quest.title,
                    style: textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    quest.description,
                    style: textTheme.bodySmall
                        ?.copyWith(color: colors.onSurfaceVariant),
                  ),
                  if (!isBinary) ...[
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        minHeight: 7,
                        value: progress,
                        backgroundColor: colors.surfaceContainerHighest,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      quest.isCompleted
                          ? '✓ Complete!'
                          : '${quest.progress} / ${quest.target} completed',
                      style: textTheme.labelSmall?.copyWith(
                        color: quest.isCompleted
                            ? appColors.income
                            : colors.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ] else if (quest.isCompleted) ...[
                    const SizedBox(height: 4),
                    Text(
                      '✓ Complete!',
                      style: textTheme.labelSmall?.copyWith(
                        color: appColors.income,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            _XpPill(label: '+${quest.xpReward} XP'),
          ],
        ),
      ),
    );
  }
}

class _BadgeRow extends StatelessWidget {
  const _BadgeRow({required this.badges});

  final List<ConscienceBadge> badges;

  @override
  Widget build(BuildContext context) {
    if (badges.isEmpty) {
      return const _JourneyMessageCard(
        icon: Icons.workspace_premium_rounded,
        title: 'No badges yet',
        body: 'A first reflection or pre-purchase check will start the shelf.',
      );
    }

    return SizedBox(
      height: 104,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: badges.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) => _BadgeTile(badge: badges[index]),
      ),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({required this.badge});

  final ConscienceBadge badge;

  static IconData _iconFor(String key) {
    return switch (key) {
      'first_reflection' => Icons.auto_stories_rounded,
      'pause_before_purchase' => Icons.pause_circle_outline_rounded,
      'budget_rescuer' => Icons.savings_rounded,
      'regret_pattern_spotted' => Icons.loop_rounded,
      'worth_it_week' => Icons.emoji_events_rounded,
      'family_founder' => Icons.group_add_rounded,
      'family_planner' => Icons.receipt_long_rounded,
      'insight_reader' => Icons.lightbulb_outline_rounded,
      'deep_thinker' => Icons.psychology_rounded,
      'pre_purchase_habit' => Icons.check_circle_outline_rounded,
      'reflection_habit' => Icons.local_fire_department_rounded,
      'family_connector' => Icons.handshake_rounded,
      'family_budget_tracker' => Icons.account_balance_wallet_rounded,
      'budget_builder' => Icons.construction_rounded,
      _ => Icons.workspace_premium_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      width: 72,
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: badge.isUnlocked
                  ? Theme.of(context).appColors.angelSoft
                  : colors.surfaceContainerHighest.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(16),
              border: badge.isUnlocked
                  ? Border.all(
                      color: Theme.of(context).appColors.angelAccent,
                      width: 2,
                    )
                  : null,
            ),
            child: Icon(
              badge.isUnlocked ? _iconFor(badge.key) : Icons.lock_outline_rounded,
              color: badge.isUnlocked
                  ? Theme.of(context).appColors.angelAccent
                  : colors.outline,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            badge.isUnlocked ? badge.title : '???',
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelSmall?.copyWith(
              color: badge.isUnlocked ? colors.onSurface : colors.outline,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _AllAchievementsSheet extends StatelessWidget {
  const _AllAchievementsSheet({required this.badges});

  final List<ConscienceBadge> badges;

  static IconData _iconFor(String key) {
    return switch (key) {
      'first_reflection' => Icons.auto_stories_rounded,
      'pause_before_purchase' => Icons.pause_circle_outline_rounded,
      'budget_rescuer' => Icons.savings_rounded,
      'regret_pattern_spotted' => Icons.loop_rounded,
      'worth_it_week' => Icons.emoji_events_rounded,
      'family_founder' => Icons.group_add_rounded,
      'family_planner' => Icons.receipt_long_rounded,
      'insight_reader' => Icons.lightbulb_outline_rounded,
      'deep_thinker' => Icons.psychology_rounded,
      'pre_purchase_habit' => Icons.check_circle_outline_rounded,
      'reflection_habit' => Icons.local_fire_department_rounded,
      'family_connector' => Icons.handshake_rounded,
      'family_budget_tracker' => Icons.account_balance_wallet_rounded,
      'budget_builder' => Icons.construction_rounded,
      _ => Icons.workspace_premium_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'All Achievements',
              style:
                  textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              '${badges.where((b) => b.isUnlocked).length} of ${badges.length} unlocked',
              style: textTheme.bodySmall
                  ?.copyWith(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    for (final badge in badges)
                      _AchievementSheetRow(
                          badge: badge, icon: _iconFor(badge.key)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AchievementSheetRow extends StatelessWidget {
  const _AchievementSheetRow({required this.badge, required this.icon});

  final ConscienceBadge badge;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final appColors = Theme.of(context).appColors;
    final iconColor =
        badge.isUnlocked ? appColors.angelAccent : colors.outline;
    final bgColor = badge.isUnlocked
        ? appColors.angelSoft
        : colors.surfaceContainerHighest.withValues(alpha: 0.5);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(14),
              border: badge.isUnlocked
                  ? Border.all(color: appColors.angelAccent, width: 1.5)
                  : null,
            ),
            child: Icon(
              badge.isUnlocked ? icon : Icons.lock_outline_rounded,
              color: iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  badge.isUnlocked ? badge.title : '???',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: badge.isUnlocked ? colors.onSurface : colors.outline,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  badge.isUnlocked
                      ? badge.description
                      : 'Keep using Conscia to unlock this.',
                  style: textTheme.bodySmall
                      ?.copyWith(color: colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          if (badge.isUnlocked)
            Icon(Icons.check_circle_rounded, color: appColors.angelAccent, size: 18),
        ],
      ),
    );
  }
}

class _MascotMomentCard extends StatelessWidget {
  const _MascotMomentCard({required this.moment});

  final ConscienceMascotMoment moment;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return FeedCard(
      child: Row(
        children: [
          _JourneyMascot(persona: moment.persona, width: 86),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  moment.title,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  moment.message,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _JourneyMascot extends StatelessWidget {
  const _JourneyMascot({
    required this.persona,
    required this.width,
  });

  final String persona;
  final double width;

  @override
  Widget build(BuildContext context) {
    if (persona == 'both') {
      return SizedBox(
        width: width,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: width * 0.34,
              child: MascotSpriteFrame(
                atlas: angelMascotAtlas,
                frameName: '4_win.png',
                width: width * 0.7,
              ),
            ),
            MascotSpriteFrame(
              atlas: devilMascotAtlas,
              frameName: '9_coin.png',
              width: width * 0.7,
            ),
          ],
        ),
      );
    }

    final isAngel = persona == 'angel';
    return MascotSpriteFrame(
      atlas: isAngel ? angelMascotAtlas : devilMascotAtlas,
      frameName: isAngel ? '4_win.png' : '5_win.png',
      width: width,
    );
  }
}

class _JourneyGuideSheet extends StatelessWidget {
  const _JourneyGuideSheet();

  static const _levels = [
    _GuideLevel(
        'Awakening', '0 XP', 'The first step into your conscience path.'),
    _GuideLevel(
        'Impulse Spotter', '120 XP', 'Early awareness starts to stick.'),
    _GuideLevel(
        'Budget Guardian', '400 XP', 'You are protecting money with intent.'),
    _GuideLevel(
        'Conscience Captain', '1000 XP', 'Consistency is becoming identity.'),
    _GuideLevel('Money Monk', '2200 XP', 'The current top of the path.'),
  ];

  static const _achievementHints = [
    'Reflected on your first purchase.',
    'Checked with Conscia before buying.',
    'Created a budget from a nudge.',
    'Reviewed a regret pattern before it repeated.',
    'Built a week of reflective spending awareness.',
    'Invited someone into a family space.',
  ];

  static const _questHints = [
    _GuideQuest(
      'Reflect on recent purchases.',
      'Counts reflections that turn spending into signal.',
    ),
    _GuideQuest(
      'Check with Conscia before buying.',
      'Rewards pausing before the money leaves.',
    ),
    _GuideQuest(
      'Review regret patterns.',
      'Builds awareness around repeat spending traps.',
    ),
    _GuideQuest(
      'Create a budget from a nudge.',
      'Turns a warning into a protective guardrail.',
    ),
    _GuideQuest(
      'Visit insights when new signals appear.',
      'Keeps your bigger money story visible.',
    ),
    _GuideQuest(
      'Keep your momentum alive.',
      'Celebrates consistency without punishing missed days.',
    ),
    _GuideQuest(
      'Invite a family member.',
      'Helps a household coordinate without mixing up identities.',
    ),
    _GuideQuest(
      'Check a family purchase first.',
      'Rewards pausing when a purchase affects shared budgets.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          18,
          0,
          18,
          18 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _JourneyMascot(persona: 'both', width: 86),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'How Journey works',
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Small money decisions become XP, levels, quests, achievements, and mascot moments.',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _GuideSection(
              icon: Icons.stairs_rounded,
              title: 'Levels',
              child: Column(
                children: [
                  for (final level in _levels)
                    _GuideRow(
                      icon: Icons.circle_rounded,
                      title: level.title,
                      trailing: level.requiredXp,
                      subtitle: level.description,
                    ),
                  const SizedBox(height: 8),
                  Text(
                    'More levels can arrive in future updates.',
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _GuideSection(
              icon: Icons.workspace_premium_rounded,
              title: 'Mystery achievements',
              child: Column(
                children: [
                  for (final hint in _achievementHints)
                    _GuideRow(
                      icon: Icons.lock_outline_rounded,
                      title: '????',
                      subtitle: hint,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _GuideSection(
              icon: Icons.flag_rounded,
              title: 'Weekly quests',
              trailing: 'Only 3 quests show up each week.',
              child: Column(
                children: [
                  for (final hint in _questHints)
                    _GuideRow(
                      icon: Icons.auto_awesome_rounded,
                      title: hint.title,
                      subtitle: hint.description,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const _GuideSection(
              icon: Icons.theater_comedy_rounded,
              title: 'Mascot moments',
              child: Column(
                children: [
                  _GuideRow(
                    icon: Icons.wb_sunny_rounded,
                    title: 'Reason moments',
                    subtitle: 'Angel-flavored nudges for thoughtful wins.',
                  ),
                  _GuideRow(
                    icon: Icons.local_fire_department_rounded,
                    title: 'Impulse moments',
                    subtitle: 'Devil-flavored drama when patterns get spicy.',
                  ),
                  _GuideRow(
                    icon: Icons.bolt_rounded,
                    title: 'Battle moments',
                    subtitle:
                        'Both mascots show up when choices feel contested.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuideLevel {
  const _GuideLevel(this.title, this.requiredXp, this.description);

  final String title;
  final String requiredXp;
  final String description;
}

class _GuideQuest {
  const _GuideQuest(this.title, this.description);

  final String title;
  final String description;
}

class _GuideSection extends StatelessWidget {
  const _GuideSection({
    required this.icon,
    required this.title,
    required this.child,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return FeedCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: colors.primary, size: 19),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          if (trailing != null) ...[
            const SizedBox(height: 6),
            Text(
              trailing!,
              style: textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _GuideRow extends StatelessWidget {
  const _GuideRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: colors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (trailing case final trailing?)
                      Text(
                        trailing,
                        style: textTheme.labelMedium?.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({
    required this.icon,
    required this.color,
  });

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}

class _XpPill extends StatelessWidget {
  const _XpPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colors.tertiaryContainer.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colors.onTertiaryContainer,
              fontWeight: FontWeight.w900,
            ),
      ),
    );
  }
}

class _JourneyMessageCard extends StatelessWidget {
  const _JourneyMessageCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return FeedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colors.primary),
          const SizedBox(height: 12),
          Text(
            title,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

