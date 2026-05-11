import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/assets/mascot_sprite_sheet.dart';
import '../../models/conscience_journey.dart';
import '../../providers/conscience_journey_provider.dart';
import '../../widgets/feed_card.dart';
import '../../widgets/hero_screen_scaffold.dart';
import '../../widgets/screen_section.dart';

class ConscienceJourneyScreen extends ConsumerWidget {
  const ConscienceJourneyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journeyAsync = ref.watch(conscienceJourneyProvider);

    return HeroScreenScaffold(
      appBar: AppBar(
        title: const Text('Conscience Journey'),
        actions: [
          IconButton(
            tooltip: 'Journey guide',
            icon: const Icon(Icons.help_outline_rounded),
            onPressed: () => _showJourneyGuide(context),
          ),
        ],
      ),
      child: journeyAsync.when(
        loading: () => const _CenteredState(child: CircularProgressIndicator()),
        error: (_, __) => const _JourneyMessageCard(
          icon: Icons.auto_awesome_rounded,
          title: 'Journey is taking a breather',
          body: 'We could not load your achievements just now.',
        ),
        data: (summary) => ConscienceJourneyContent(summary: summary),
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
  });

  final ConscienceJourneySummary summary;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _JourneyHeroCard(summary: summary),
        const SizedBox(height: 26),
        ScreenSection(
          title: 'Weekly quests',
          subtitle: 'Small reps that keep your money conscience sharp.',
          child: Column(
            children: [
              for (final quest in summary.weeklyQuests) ...[
                _QuestTile(quest: quest),
                if (quest != summary.weeklyQuests.last)
                  const SizedBox(height: 10),
              ],
            ],
          ),
        ),
        ScreenSection(
          title: 'Achievements',
          subtitle: 'Badges earned by pausing, reflecting, and rescuing money.',
          child: _BadgeGrid(badges: summary.badges),
        ),
        if (summary.recentMascotMoment case final moment?)
          ScreenSection(
            title: 'Mascot moment',
            subtitle: 'A tiny dramatic reading from your financial conscience.',
            child: _MascotMomentCard(moment: moment),
          ),
      ],
    );
  }
}

class _JourneyHeroCard extends StatelessWidget {
  const _JourneyHeroCard({required this.summary});

  final ConscienceJourneySummary summary;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final nextLevel = summary.nextLevel;
    final progress = _levelProgress(summary);

    return FeedCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _JourneyMascot(persona: 'both', width: 74),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Level',
                      style: textTheme.labelLarge?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      summary.currentLevel.title,
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      nextLevel == null
                          ? 'Top level reached. The mascots are taking notes.'
                          : '${summary.xpToNextLevel} XP to ${nextLevel.title}',
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              _XpPill(label: '${summary.xpTotal} XP'),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: progress,
              backgroundColor: colors.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatPill(
                  icon: Icons.local_fire_department_rounded,
                  label: '${summary.momentumDays}-day momentum',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatPill(
                  icon: Icons.emoji_events_rounded,
                  label: '${summary.bestMomentumDays}-day best',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  double _levelProgress(ConscienceJourneySummary summary) {
    final next = summary.nextLevel;
    if (next == null) return 1;

    final levelSpan = next.requiredXp - summary.currentLevel.requiredXp;
    if (levelSpan <= 0) return 0;

    return (summary.xpIntoLevel / levelSpan).clamp(0, 1).toDouble();
  }
}

class _QuestTile extends StatelessWidget {
  const _QuestTile({required this.quest});

  final ConscienceQuest quest;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final progress = quest.target == 0
        ? 0.0
        : (quest.progress / quest.target).clamp(0, 1).toDouble();

    return FeedCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _IconBadge(
            icon: quest.isCompleted ? Icons.check_rounded : Icons.flag_rounded,
            color: quest.isCompleted ? colors.primary : colors.tertiary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quest.title,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  quest.description,
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 7,
                    value: progress,
                    backgroundColor: colors.surfaceContainerHighest,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _XpPill(label: '+${quest.xpReward} XP'),
        ],
      ),
    );
  }
}

class _BadgeGrid extends StatelessWidget {
  const _BadgeGrid({required this.badges});

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

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 520;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final badge in badges)
              SizedBox(
                width: isWide
                    ? (constraints.maxWidth - 10) / 2
                    : constraints.maxWidth,
                child: _BadgeTile(badge: badge),
              ),
          ],
        );
      },
    );
  }
}

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({required this.badge});

  final ConscienceBadge badge;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final progress = badge.target == 0
        ? 0.0
        : (badge.progress / badge.target).clamp(0, 1).toDouble();

    return FeedCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _IconBadge(
            icon: badge.isUnlocked
                ? Icons.workspace_premium_rounded
                : Icons.lock_outline_rounded,
            color: badge.isUnlocked ? colors.primary : colors.outline,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  badge.title,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: badge.isUnlocked
                        ? colors.onSurface
                        : colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  badge.description,
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  badge.isUnlocked
                      ? 'Unlocked'
                      : '${badge.progress}/${badge.target}',
                  style: textTheme.labelSmall?.copyWith(
                    color: badge.isUnlocked ? colors.primary : colors.outline,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (!badge.isUnlocked) ...[
                  const SizedBox(height: 6),
                  LinearProgressIndicator(value: progress, minHeight: 5),
                ],
              ],
            ),
          ),
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

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: colors.primary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: textTheme.labelMedium?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
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

class _CenteredState extends StatelessWidget {
  const _CenteredState({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.58,
      child: Center(child: child),
    );
  }
}
