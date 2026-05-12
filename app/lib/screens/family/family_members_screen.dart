import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_icons.dart';
import '../../core/errors/app_error.dart';
import '../../models/family_member.dart';
import '../../providers/family_space_provider.dart';
import '../../widgets/feed_card.dart';
import '../../widgets/hero_screen_scaffold.dart';
import '../../widgets/skeleton_loader.dart';

class FamilyMembersScreen extends ConsumerWidget {
  const FamilyMembersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final familySpace = ref.watch(familySpaceProvider);
    final members = ref.watch(familyMembersProvider);
    final currentRole = familySpace.valueOrNull?.role.toLowerCase() ?? '';
    final canManage = currentRole == 'owner' &&
        !(familySpace.valueOrNull?.isReadOnly ?? true);

    return HeroScreenScaffold(
      appBar: AppBar(title: const Text('Family members')),
      child: members.when(
        data: (items) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'People in this Family Space',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              canManage
                  ? 'Owners can change member access or remove someone from the household.'
                  : 'You can see who belongs here. Owners manage roles and removals.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
            ),
            const SizedBox(height: 14),
            for (final member in items) ...[
              _MemberCard(member: member, canManage: canManage),
              if (member != items.last) const SizedBox(height: 10),
            ],
            const SizedBox(height: 18),
            _LeaveFamilySection(
              isOwner: currentRole == 'owner',
              isReadOnly: familySpace.valueOrNull?.isReadOnly ?? false,
            ),
          ],
        ),
        loading: () => const Column(
          children: [
            SkeletonCard(),
            SizedBox(height: 10),
            SkeletonCard(),
          ],
        ),
        error: (_, __) => FeedCard(
          child: Row(
            children: [
              const Expanded(child: Text('Unable to load family members')),
              OutlinedButton(
                onPressed: () => ref.invalidate(familyMembersProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MemberCard extends ConsumerStatefulWidget {
  const _MemberCard({
    required this.member,
    required this.canManage,
  });

  final FamilyMember member;
  final bool canManage;

  @override
  ConsumerState<_MemberCard> createState() => _MemberCardState();
}

class _MemberCardState extends ConsumerState<_MemberCard> {
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final canManageThisMember = widget.canManage &&
        !widget.member.isCurrentUser &&
        !widget.member.isOwner;
    final alternateRole =
        widget.member.role.toLowerCase() == 'viewer' ? 'Contributor' : 'Viewer';

    return FeedCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: colors.primaryContainer.withValues(alpha: 0.55),
            child: Text(
              widget.member.initials,
              style: theme.textTheme.labelLarge?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        widget.member.email,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (widget.member.isCurrentUser) const _YouPill(),
                  ],
                ),
                const SizedBox(height: 7),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _RolePill(role: widget.member.role),
                    _JoinedPill(joinedAt: widget.member.joinedAt),
                  ],
                ),
                if (canManageThisMember) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _isSubmitting
                            ? null
                            : () => _changeRole(alternateRole),
                        icon: const Icon(Icons.admin_panel_settings_outlined,
                            size: 17),
                        label: Text('Make ${alternateRole.toLowerCase()}'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 34),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: _isSubmitting ? null : _remove,
                        icon:
                            const Icon(Icons.person_remove_outlined, size: 17),
                        label: const Text('Remove'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colors.error,
                          side: BorderSide(
                            color: colors.error.withValues(alpha: 0.34),
                          ),
                          minimumSize: const Size(0, 34),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _changeRole(String role) async {
    await _run(
      () => ref.read(familySpaceActionsProvider).updateMemberRole(
            memberId: widget.member.id,
            role: role,
          ),
      'Member role updated.',
    );
  }

  Future<void> _remove() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove family member?'),
        content: Text(
          '${widget.member.email} will lose access to this Family Space. Existing shared records stay in the household history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await _run(
      () => ref.read(familySpaceActionsProvider).removeMember(widget.member.id),
      'Family member removed.',
    );
  }

  Future<void> _run(
    Future<void> Function() action,
    String successMessage,
  ) async {
    setState(() => _isSubmitting = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(successMessage)));
    } catch (e, s) {
      if (!mounted) return;
      final error = AppError.from(e, stackTrace: s);
      messenger.showSnackBar(SnackBar(content: Text(error.userMessage)));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}

class _LeaveFamilySection extends ConsumerStatefulWidget {
  const _LeaveFamilySection({
    required this.isOwner,
    required this.isReadOnly,
  });

  final bool isOwner;
  final bool isReadOnly;

  @override
  ConsumerState<_LeaveFamilySection> createState() =>
      _LeaveFamilySectionState();
}

class _LeaveFamilySectionState extends ConsumerState<_LeaveFamilySection> {
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return FeedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(AppIcons.family, color: colors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Leaving the Family Space',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      widget.isOwner
                          ? 'Owners must transfer ownership before leaving. Ownership transfer is not part of this MVP yet.'
                          : 'Your personal records remain private. Shared records you already added stay in the household history.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!widget.isOwner) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed:
                    _isSubmitting || widget.isReadOnly ? null : _leaveFamily,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.logout_outlined),
                label: Text(
                  _isSubmitting ? 'Leaving...' : 'Leave Family Space',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.error,
                  side: BorderSide(color: colors.error.withValues(alpha: 0.34)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _leaveFamily() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Family Space?'),
        content: const Text(
          'You will lose access to shared household views. Records already shared stay in the Family Space history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!mounted) return;

    setState(() => _isSubmitting = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(familySpaceActionsProvider).leaveFamilySpace();
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('You left the Family Space.')),
      );
    } catch (e, s) {
      if (!mounted) return;
      final error = AppError.from(e, stackTrace: s);
      messenger.showSnackBar(SnackBar(content: Text(error.userMessage)));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}

class _RolePill extends StatelessWidget {
  const _RolePill({required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    return _MemberPill(
      icon: Icons.admin_panel_settings_outlined,
      label: role,
      emphasized: role.toLowerCase() == 'owner',
    );
  }
}

class _JoinedPill extends StatelessWidget {
  const _JoinedPill({required this.joinedAt});

  final DateTime joinedAt;

  @override
  Widget build(BuildContext context) {
    return _MemberPill(
      icon: Icons.schedule_outlined,
      label: 'Joined ${_formatMonthDay(joinedAt)}',
      quiet: true,
    );
  }
}

class _YouPill extends StatelessWidget {
  const _YouPill();

  @override
  Widget build(BuildContext context) {
    return const _MemberPill(
      icon: Icons.person_outline,
      label: 'You',
      quiet: true,
    );
  }
}

class _MemberPill extends StatelessWidget {
  const _MemberPill({
    required this.icon,
    required this.label,
    this.emphasized = false,
    this.quiet = false,
  });

  final IconData icon;
  final String label;
  final bool emphasized;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final foreground = quiet
        ? colors.onSurfaceVariant
        : emphasized
            ? colors.primary
            : colors.secondary;
    final background = quiet
        ? colors.surfaceContainerHighest
        : emphasized
            ? colors.primaryContainer
            : colors.secondaryContainer;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: background.withValues(alpha: quiet ? 0.55 : 0.72),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: foreground),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

String _formatMonthDay(DateTime date) {
  if (date.millisecondsSinceEpoch == 0) return 'recently';
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}';
}
