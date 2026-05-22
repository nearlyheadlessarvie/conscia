import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_icons.dart';
import '../../core/routing/app_router.dart';
import '../../core/errors/app_error.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_layout.dart';
import '../../models/family_invite.dart';
import '../../providers/family_space_provider.dart';
import '../../widgets/conscia_button_row.dart';
import '../../widgets/editorial_hero_chip.dart';
import '../../widgets/editorial_section_header.dart';
import '../../widgets/floating_label_text_field.dart';
import '../../widgets/hero_screen_scaffold.dart';
import '../../widgets/inline_notice.dart';
import '../../widgets/conscia_app_bar.dart';
import '../../widgets/skeleton_loader.dart';
import '../../widgets/segmented_switch.dart';

class FamilyInvitesScreen extends ConsumerWidget {
  const FamilyInvitesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invites = ref.watch(familyInvitesProvider);
    final familySpace = ref.watch(familySpaceProvider);

    return HeroScreenScaffold(
      padding: EdgeInsets.zero,
      bleedBehindAppBar: true,
      appBar: ConsciaAppBar(
        title: const Text('Invites'),
        alwaysShowBack: true,
        onBack: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(AppRoutes.familySpace);
          }
        },
      ),
      child: invites.when(
        data: (items) {
          final canInvite = familySpace.valueOrNull?.role == 'Owner';
          final outgoingInvites =
              canInvite ? ref.watch(familyOutgoingInvitesProvider) : null;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _InvitesHero(
                canInvite: canInvite,
                pendingCount: items.length,
                sentCount: outgoingInvites?.valueOrNull?.length,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (canInvite) ...[
                      const _InviteComposer(),
                      const SizedBox(height: 24),
                      outgoingInvites!.when(
                        data: (items) =>
                            _OutgoingInvitesSection(invites: items),
                        loading: () => const SkeletonCard(),
                        error: (_, __) => _InviteErrorCard(
                          message: 'Unable to load sent invites',
                          onRetry: () =>
                              ref.invalidate(familyOutgoingInvitesProvider),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    const _SectionHeading(
                      title: 'Invites you received',
                      subtitle:
                          'Accept only household spaces you recognize and trust.',
                    ),
                    const SizedBox(height: 12),
                    if (items.isEmpty)
                      const _EmptyInvites()
                    else
                      _FlatInviteList(
                        children: [
                          for (final invite in items)
                            _InviteCard(invite: invite),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Padding(
          padding: EdgeInsets.fromLTRB(20, 96, 20, 24),
          child: Column(
            children: [
              SkeletonCard(),
              SizedBox(height: 12),
              SkeletonCard(),
            ],
          ),
        ),
        error: (_, __) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 96, 20, 24),
          child: _InviteErrorCard(
            message: 'Unable to load family invites',
            onRetry: () => ref.invalidate(familyInvitesProvider),
          ),
        ),
      ),
    );
  }
}

class _InvitesHero extends StatelessWidget {
  const _InvitesHero({
    required this.canInvite,
    required this.pendingCount,
    this.sentCount,
  });

  final bool canInvite;
  final int pendingCount;
  final int? sentCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.appColors;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.familySoft,
            colors.paper,
            colors.amberSoft.withValues(alpha: 0.86),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppLayout.screenPadding,
          AppLayout.bleedingHeroTop(context),
          AppLayout.screenPadding,
          AppLayout.heroBottomPadding,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'FAMILY INVITES',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.deepNavy,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              canInvite ? 'Bring the right people in' : 'Review your invites',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: colors.deepNavy,
                fontWeight: FontWeight.w800,
                height: 1.05,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              canInvite
                  ? 'Invite family members by email and choose what they can do in the household.'
                  : 'Join a household only when you recognize the sender and purpose.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.ink,
                height: 1.32,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                EditorialHeroChip(label: '$pendingCount received'),
                if (sentCount != null)
                  EditorialHeroChip(label: '$sentCount sent'),
                const EditorialHeroChip(label: 'Roles stay editable'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return EditorialSectionHeader(
      title: title,
      subtitle: subtitle,
    );
  }
}

class _FlatInviteList extends StatelessWidget {
  const _FlatInviteList({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < children.length; index++) ...[
          children[index],
          if (index != children.length - 1)
            Divider(
              height: 24,
              color: Theme.of(context).appColors.border,
            ),
        ],
      ],
    );
  }
}

class _InviteComposer extends ConsumerStatefulWidget {
  const _InviteComposer();

  @override
  ConsumerState<_InviteComposer> createState() => _InviteComposerState();
}

class _InviteComposerState extends ConsumerState<_InviteComposer> {
  final _emailController = TextEditingController();
  var _role = 'Contributor';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeading(
          title: 'Invite a family member',
          subtitle:
              'Send access by email. You can change roles later from Members.',
        ),
        const SizedBox(height: 8),
        FloatingLabelTextField(
          controller: _emailController,
          label: 'Email address',
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) {
            if (!_isSubmitting) _submit();
          },
        ),
        const SizedBox(height: 14),
        Text(
          'Role',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.mutedInk,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 6),
        SegmentedSwitch(
          items: const ['Contributor', 'Viewer'],
          selectedItem: _role,
          selectedColor: colors.deepNavy,
          normalized: false,
          onChanged: (value) => setState(() => _role = value),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _isSubmitting ? null : _submit,
            child: Text(_isSubmitting ? 'Sending...' : 'Send invite'),
          ),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;

    setState(() => _isSubmitting = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(familySpaceActionsProvider).invite(
            email: email,
            role: _role,
          );
      if (!mounted) return;
      _emailController.clear();
      messenger.showSnackBar(
        const SnackBar(content: Text('Family invite sent.')),
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

class _OutgoingInvitesSection extends StatelessWidget {
  const _OutgoingInvitesSection({required this.invites});

  final List<FamilyInvite> invites;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeading(
          title: 'Sent',
          subtitle: 'Pending invitations you can still cancel.',
        ),
        const SizedBox(height: 12),
        if (invites.isEmpty)
          const _CompactInviteEmptyState(
            icon: AppIconKey.email,
            message: 'No sent invites right now.',
          )
        else
          _FlatInviteList(
            children: [
              for (final invite in invites) _OutgoingInviteCard(invite: invite),
            ],
          ),
      ],
    );
  }
}

class _OutgoingInviteCard extends ConsumerStatefulWidget {
  const _OutgoingInviteCard({required this.invite});

  final FamilyInvite invite;

  @override
  ConsumerState<_OutgoingInviteCard> createState() =>
      _OutgoingInviteCardState();
}

class _OutgoingInviteCardState extends ConsumerState<_OutgoingInviteCard> {
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.appColors;

    return Dismissible(
      key: ValueKey('outgoing-invite-${widget.invite.id}'),
      direction:
          _isSubmitting ? DismissDirection.none : DismissDirection.endToStart,
      confirmDismiss: (_) => _cancel(),
      background: Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: colors.expenseSoft,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcons.icon(
                AppIconKey.close,
                color: colors.expense,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                _isSubmitting ? 'Cancelling' : 'Cancel',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.expense,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
      child: ColoredBox(
        color: colors.paper,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: colors.angelSoft,
                child: Text(
                  _initials(widget.invite.email),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colors.angelAccent,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.invite.email,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colors.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${_roleLabel(widget.invite.role)} · Expires ${_formatInviteDate(widget.invite.expiresAt)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.mutedInk,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _cancel() async {
    setState(() => _isSubmitting = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(familySpaceActionsProvider).cancelInvite(widget.invite.id);
      if (!mounted) return false;
      messenger.showSnackBar(
        const SnackBar(content: Text('Family invite cancelled.')),
      );
      return false;
    } catch (e, s) {
      if (!mounted) return false;
      final error = AppError.from(e, stackTrace: s);
      messenger.showSnackBar(SnackBar(content: Text(error.userMessage)));
      return false;
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}

class _InvitePill extends StatelessWidget {
  const _InvitePill({
    required this.label,
    required this.color,
    required this.background,
  });

  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

class _CompactInviteEmptyState extends StatelessWidget {
  const _CompactInviteEmptyState({
    required this.icon,
    required this.message,
  });

  final AppIconKey icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          children: [
          AppIcons.icon(
            icon,
            size: 18,
            color: colors.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyInvites extends StatelessWidget {
  const _EmptyInvites();

  @override
  Widget build(BuildContext context) => const _CompactInviteEmptyState(
        icon: AppIconKey.verified,
        message: 'No pending invites right now.',
      );
}

class _InviteErrorCard extends StatelessWidget {
  const _InviteErrorCard({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InlineNotice(
          message: message,
          tone: InlineNoticeTone.error,
          icon: AppIcons.icon(
            AppIconKey.error,
            color: Theme.of(context).appColors.expense,
            size: 16,
          ),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: onRetry,
          icon: AppIcons.icon(
            AppIconKey.refresh,
            color: Theme.of(context).appColors.deepNavy,
            size: 18,
          ),
          label: const Text('Retry'),
        ),
      ],
    );
  }
}

class _InviteCard extends ConsumerStatefulWidget {
  const _InviteCard({required this.invite});

  final FamilyInvite invite;

  @override
  ConsumerState<_InviteCard> createState() => _InviteCardState();
}

class _InviteCardState extends ConsumerState<_InviteCard> {
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.appColors;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: colors.amberSoft,
                child: Text(
                  _initials(widget.invite.email),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colors.devilAccent,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.invite.familySpaceName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Join this Family Space',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _InvitePill(
                      label: widget.invite.role,
                      color: colors.deepNavy,
                      background: colors.navySoft,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ConsciaButtonRow(
            secondaryLabel: 'Decline',
            onSecondaryPressed: _isSubmitting ? null : () => _decline(context),
            primaryLabel: _isSubmitting ? 'Saving...' : 'Accept',
            onPrimaryPressed: _isSubmitting ? null : () => _accept(context),
            gap: 10,
          ),
        ],
      ),
    );
  }

  Future<void> _accept(BuildContext context) async {
    await _run(
      context,
      () => ref.read(familySpaceActionsProvider).acceptInvite(widget.invite.id),
      'Family Space joined.',
    );
  }

  Future<void> _decline(BuildContext context) async {
    await _run(
      context,
      () =>
          ref.read(familySpaceActionsProvider).declineInvite(widget.invite.id),
      'Invite declined.',
    );
  }

  Future<void> _run(
    BuildContext context,
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

String _formatInviteDate(DateTime date) {
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

String _roleLabel(String role) {
  final normalized = role.trim().toLowerCase();
  return switch (normalized) {
    'owner' => 'Owner',
    'contributor' => 'Contributor',
    'viewer' => 'Viewer',
    _ => role.trim().isEmpty ? 'Member' : role.trim(),
  };
}

String _initials(String email) {
  final local = email.split('@').first.trim();
  if (local.isEmpty) return '?';
  final parts = local
      .split(RegExp(r'[._\-\s]+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.length >= 2) {
    return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
  }
  return local.substring(0, local.length >= 2 ? 2 : 1).toUpperCase();
}
