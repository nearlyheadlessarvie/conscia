import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/routing/app_router.dart';
import '../../models/family_space.dart';
import '../../providers/family_space_provider.dart';
import '../../widgets/feed_card.dart';
import '../../widgets/hero_screen_scaffold.dart';
import '../../widgets/screen_section.dart';
import '../../widgets/skeleton_loader.dart';

class FamilySpaceScreen extends ConsumerWidget {
  const FamilySpaceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final familySpace = ref.watch(familySpaceProvider);

    return HeroScreenScaffold(
      appBar: AppBar(title: const Text('Shared Conscia')),
      child: familySpace.when(
        data: (space) => space == null
            ? const _NoFamilySpaceView()
            : _FamilySpaceOverview(space: space),
        loading: () => const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonCard(),
            SizedBox(height: 14),
            SkeletonCard(),
          ],
        ),
        error: (_, __) => FeedCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Unable to load Family Space'),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => ref.invalidate(familySpaceProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoFamilySpaceView extends StatelessWidget {
  const _NoFamilySpaceView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Plan together without exposing everything.',
            style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          'Create one household space, invite family members, then explicitly import the records you want to share.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 18),
        FeedCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.diversity_3_outlined, size: 36),
              const SizedBox(height: 12),
              Text(
                'Shared budgets, recurring contributions, and family-aware insights.',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: () => context.push(AppRoutes.familySetup),
                icon: const Icon(Icons.add),
                label: const Text('Create Family Space'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FamilySpaceOverview extends StatelessWidget {
  const _FamilySpaceOverview({required this.space});

  final FamilySpace space;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FeedCard(
          child: Row(
            children: [
              CircleAvatar(
                child: Text(space.name.isEmpty ? '?' : space.name[0]),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(space.name, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      '${space.role} · ${space.currencyCode}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (space.isReadOnly)
                const Tooltip(
                  message: 'Read-only while Premium is inactive',
                  child: Icon(Icons.lock_outline),
                ),
            ],
          ),
        ),
        ScreenSection(
          title: 'Next steps',
          child: FeedCard(
            child: Column(
              children: [
                _FamilyActionRow(
                  icon: Icons.person_add_alt_1_outlined,
                  title: 'Invite family',
                  subtitle: 'Send an email invite that appears when they join.',
                  onTap: () => context.push(AppRoutes.familyInvites),
                ),
                _FamilyActionRow(
                  icon: Icons.upload_file_outlined,
                  title: 'Import personal records',
                  subtitle: 'Choose exactly what becomes visible to Family.',
                  onTap: () => context.push(AppRoutes.familyImport),
                ),
                const _FamilyActionRow(
                  icon: Icons.repeat_outlined,
                  title: 'Schedule contribution',
                  subtitle:
                      'Track recurring family contributions without salary details.',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FamilyActionRow extends StatelessWidget {
  const _FamilyActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null) const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
