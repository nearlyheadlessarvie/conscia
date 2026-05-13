import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_error.dart';
import '../../core/theme/app_colors.dart';
import '../../models/family_invite.dart';
import '../../providers/family_space_provider.dart';
import '../../widgets/feed_card.dart';
import '../../widgets/floating_label_text_field.dart';
import '../../widgets/hero_screen_scaffold.dart';
import '../../widgets/skeleton_loader.dart';

class FamilyInvitesScreen extends ConsumerWidget {
  const FamilyInvitesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invites = ref.watch(familyInvitesProvider);
    final familySpace = ref.watch(familySpaceProvider);

    return HeroScreenScaffold(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      appBar: AppBar(title: const Text('Invites')),
      child: invites.when(
        data: (items) {
          final canInvite = familySpace.valueOrNull?.role == 'Owner';
          final outgoingInvites =
              canInvite ? ref.watch(familyOutgoingInvitesProvider) : null;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (canInvite) ...[
                const _InviteComposer(),
                const SizedBox(height: 16),
                outgoingInvites!.when(
                  data: (items) => _OutgoingInvitesSection(invites: items),
                  loading: () => const SkeletonCard(),
                  error: (_, __) => _InviteErrorCard(
                    message: 'Unable to load sent invites',
                    onRetry: () =>
                        ref.invalidate(familyOutgoingInvitesProvider),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              const _SectionLabel('INVITES YOU RECEIVED'),
              const SizedBox(height: 8),
              if (items.isEmpty)
                const _EmptyInvites()
              else
                ...items.map((invite) => _InviteCard(invite: invite)),
            ],
          );
        },
        loading: () => const Column(
          children: [
            SkeletonCard(),
            SizedBox(height: 12),
            SkeletonCard(),
          ],
        ),
        error: (_, __) => _InviteErrorCard(
          message: 'Unable to load family invites',
          onRetry: () => ref.invalidate(familyInvitesProvider),
        ),
      ),
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

    return FeedCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Invite a family member',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colors.ink,
                ),
          ),
          const SizedBox(height: 12),
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
          _RoleSegmentedControl(
            value: _role,
            onChanged: (value) => setState(() => _role = value),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: colors.deepNavy,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
              ),
              child: Text(_isSubmitting ? 'Sending...' : 'Send invite'),
            ),
          ),
        ],
      ),
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

class _RoleSegmentedControl extends StatelessWidget {
  const _RoleSegmentedControl({
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.navySoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Row(
          children: [
            _RoleSegment(
              label: 'Contributor',
              selected: value == 'Contributor',
              onTap: () => onChanged('Contributor'),
            ),
            _RoleSegment(
              label: 'Viewer',
              selected: value == 'Viewer',
              onTap: () => onChanged('Viewer'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleSegment extends StatelessWidget {
  const _RoleSegment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? colors.surfaceRaised : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: selected ? colors.deepNavy : colors.softInk,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
      ),
    );
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
        const _SectionLabel('SENT'),
        const SizedBox(height: 8),
        if (invites.isEmpty)
          const _CompactInviteEmptyState(
            icon: Icons.outgoing_mail,
            message: 'No sent invites right now.',
          )
        else
          for (final invite in invites) ...[
            _OutgoingInviteCard(invite: invite),
            if (invite != invites.last) const SizedBox(height: 10),
          ],
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

    return FeedCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
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
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _InvitePill(
                      label: widget.invite.role,
                      color: colors.angelAccent,
                      background: colors.angelSoft,
                    ),
                    Text(
                      'Expires ${_formatInviteDate(widget.invite.expiresAt)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.mutedInk,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _isSubmitting ? null : _cancel,
            style: TextButton.styleFrom(
              foregroundColor: colors.expense,
              minimumSize: const Size(0, 32),
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: Text(_isSubmitting ? 'Cancelling...' : 'Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _cancel() async {
    setState(() => _isSubmitting = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(familySpaceActionsProvider).cancelInvite(widget.invite.id);
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Family invite cancelled.')),
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

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colors.onSurfaceVariant),
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
        icon: Icons.mark_email_read_outlined,
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
    return FeedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
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

    return FeedCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
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
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSubmitting ? null : () => _decline(context),
                  child: const Text('Decline'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: _isSubmitting ? null : () => _accept(context),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: const StadiumBorder(),
                  ),
                  child: Text(_isSubmitting ? 'Saving...' : 'Accept'),
                ),
              ),
            ],
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    return Text(
      label,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: colors.mutedInk,
            letterSpacing: 0.8,
            fontWeight: FontWeight.w700,
          ),
    );
  }
}
