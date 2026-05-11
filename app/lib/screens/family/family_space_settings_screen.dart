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

class FamilySpaceSettingsScreen extends ConsumerWidget {
  const FamilySpaceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final familySpace = ref.watch(familySpaceProvider);

    return HeroScreenScaffold(
      appBar: AppBar(title: const Text('Shared Conscia')),
      child: familySpace.when(
        data: (space) => space == null
            ? const _NoFamilySpaceSettingsView()
            : _FamilySpaceSettingsView(space: space),
        loading: () => const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonCard(),
            SizedBox(height: 14),
            SkeletonCard(),
          ],
        ),
        error: (_, __) => FeedCard(
          child: Row(
            children: [
              const Expanded(child: Text('Unable to load Shared Conscia')),
              OutlinedButton(
                onPressed: () => ref.invalidate(familySpaceProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoFamilySpaceSettingsView extends StatelessWidget {
  const _NoFamilySpaceSettingsView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Create your household space.',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Shared Conscia is where family budgets, contributions, and explicitly shared records live.',
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
              const Icon(Icons.diversity_3_outlined, size: 34),
              const SizedBox(height: 12),
              Text(
                'Start with one household space. Nothing personal is shared unless you choose it.',
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

class _FamilySpaceSettingsView extends ConsumerWidget {
  const _FamilySpaceSettingsView({required this.space});

  final FamilySpace space;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = space.role.toLowerCase();
    final canManage = role == 'owner' && !space.isReadOnly;
    final canContribute = role != 'viewer' && !space.isReadOnly;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ScreenSection(
          title: 'Household',
          subtitle: 'Identity and access for this Family Space.',
          child: FeedCard(
            child: Column(
              children: [
                _SettingsRow(
                  icon: Icons.home_outlined,
                  title: 'Household name',
                  subtitle: space.name,
                  actionLabel: canManage ? 'Edit' : null,
                  onTap: canManage
                      ? () => _RenameFamilySpaceSheet.show(
                            context,
                            initialName: space.name,
                          )
                      : null,
                ),
                const Divider(height: 24),
                _SettingsRow(
                  icon: Icons.verified_user_outlined,
                  title: 'Your access',
                  subtitle: '${space.role} · ${space.currencyCode}',
                ),
                if (space.isReadOnly) ...[
                  const Divider(height: 24),
                  const _ReadOnlyNotice(),
                ],
              ],
            ),
          ),
        ),
        ScreenSection(
          title: 'Manage',
          subtitle: 'Actions that change what belongs to the household.',
          child: FeedCard(
            child: Column(
              children: [
                _SettingsRow(
                  icon: Icons.dashboard_outlined,
                  title: 'View family overview',
                  subtitle: 'Shared budgets, recurring items, and activity.',
                  onTap: () => context.push(AppRoutes.familyOverview),
                ),
                if (canManage) ...[
                  const Divider(height: 24),
                  _SettingsRow(
                    icon: Icons.person_add_alt_1_outlined,
                    title: 'Invites',
                    subtitle: 'Invite registered family members by email.',
                    onTap: () => context.push(AppRoutes.familyInvites),
                  ),
                ],
                if (canContribute) ...[
                  const Divider(height: 24),
                  _SettingsRow(
                    icon: Icons.upload_file_outlined,
                    title: 'Import personal records',
                    subtitle: 'Choose exactly what becomes visible to Family.',
                    onTap: () => context.push(AppRoutes.familyImport),
                  ),
                  const Divider(height: 24),
                  _SettingsRow(
                    icon: Icons.repeat_outlined,
                    title: 'Schedule contribution',
                    subtitle:
                        'Track recurring household contributions without salary details.',
                    onTap: () => context.push(AppRoutes.familyContribution),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RenameFamilySpaceSheet extends ConsumerStatefulWidget {
  const _RenameFamilySpaceSheet({required this.initialName});

  final String initialName;

  static Future<void> show(
    BuildContext context, {
    required String initialName,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _RenameFamilySpaceSheet(initialName: initialName),
    );
  }

  @override
  ConsumerState<_RenameFamilySpaceSheet> createState() =>
      _RenameFamilySpaceSheetState();
}

class _RenameFamilySpaceSheetState
    extends ConsumerState<_RenameFamilySpaceSheet> {
  late final TextEditingController _controller;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          18,
          0,
          18,
          18 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Edit household name',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Household name',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: _canSubmit ? _submit : null,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Save name'),
            ),
            const SizedBox(height: 8),
            Text(
              'Only owners can edit household settings.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  bool get _canSubmit => !_isSubmitting && _controller.text.trim().isNotEmpty;

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(familySpaceActionsProvider)
          .updateName(_controller.text.trim());
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Household name updated.')),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update household name.')),
      );
    }
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: colors.primaryContainer.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: colors.primary, size: 21),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            if (actionLabel != null)
              Text(
                actionLabel!,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w900,
                ),
              )
            else if (onTap != null)
              Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _ReadOnlyNotice extends StatelessWidget {
  const _ReadOnlyNotice();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.lock_outline, color: colors.onSurfaceVariant),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Shared Conscia is read-only while Premium is inactive.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  height: 1.3,
                ),
          ),
        ),
      ],
    );
  }
}
