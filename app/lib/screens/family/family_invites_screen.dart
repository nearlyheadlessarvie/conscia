import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_icons.dart';
import '../../core/errors/app_error.dart';
import '../../models/family_invite.dart';
import '../../providers/family_space_provider.dart';
import '../../widgets/feed_card.dart';
import '../../widgets/hero_screen_scaffold.dart';
import '../../widgets/skeleton_loader.dart';

class FamilyInvitesScreen extends ConsumerWidget {
  const FamilyInvitesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invites = ref.watch(familyInvitesProvider);
    final familySpace = ref.watch(familySpaceProvider);

    return HeroScreenScaffold(
      appBar: AppBar(title: const Text('Family invites')),
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
              Text(
                'Invites you received',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
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
    final theme = Theme.of(context);

    return FeedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Invite someone', style: theme.textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            'They can join once they register with the invited email.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.mail_outline),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _role,
            decoration: const InputDecoration(
              labelText: 'Role',
              prefixIcon: Icon(Icons.admin_panel_settings_outlined),
            ),
            items: const [
              DropdownMenuItem(
                value: 'Contributor',
                child: Text('Contributor'),
              ),
              DropdownMenuItem(
                value: 'Viewer',
                child: Text('Viewer'),
              ),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _role = value);
            },
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

class _OutgoingInvitesSection extends StatelessWidget {
  const _OutgoingInvitesSection({required this.invites});

  final List<FamilyInvite> invites;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Invites you sent', style: theme.textTheme.titleMedium),
        const SizedBox(height: 10),
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
    final colors = theme.colorScheme;

    return FeedCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor:
                    colors.primaryContainer.withValues(alpha: 0.48),
                child: Icon(
                  Icons.mark_email_unread_outlined,
                  size: 20,
                  color: colors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.invite.email,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _InvitePill(
                          label: widget.invite.role,
                          icon: Icons.admin_panel_settings_outlined,
                        ),
                        _InvitePill(
                          label:
                              'Expires ${_formatInviteDate(widget.invite.expiresAt)}',
                          icon: Icons.schedule_outlined,
                          quiet: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: _isSubmitting ? null : _cancel,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.close, size: 16),
              label: Text(_isSubmitting ? 'Cancelling...' : 'Cancel invite'),
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.error,
                side: BorderSide(color: colors.error.withValues(alpha: 0.34)),
                minimumSize: const Size(0, 34),
                padding: const EdgeInsets.symmetric(horizontal: 13),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
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
    required this.icon,
    this.quiet = false,
  });

  final String label;
  final IconData icon;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final Color background =
        quiet ? colors.surfaceContainerHighest : colors.primaryContainer;
    final Color foreground = quiet ? colors.onSurfaceVariant : colors.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: background.withValues(alpha: quiet ? 0.58 : 0.72),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
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

    return FeedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(child: Icon(AppIcons.family)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.invite.familySpaceName,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Join this Family Space',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Chip(label: Text(widget.invite.role)),
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
