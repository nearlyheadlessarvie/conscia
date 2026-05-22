import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_icons.dart';
import '../../core/routing/app_router.dart';
import '../../core/errors/app_error.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_layout.dart';
import '../../models/family_member.dart';
import '../../providers/family_space_provider.dart';
import '../../widgets/conscia_app_bar.dart';
import '../../widgets/conscia_bottom_sheet.dart';
import '../../widgets/conscia_confirm_sheet.dart';
import '../../widgets/editorial_hero_chip.dart';
import '../../widgets/hero_screen_scaffold.dart';
import '../../widgets/inline_notice.dart';
import '../../widgets/screen_section.dart';
import '../../widgets/skeleton_loader.dart';

class FamilyMembersScreen extends ConsumerWidget {
  const FamilyMembersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final familySpace = ref.watch(familySpaceProvider);
    final members = ref.watch(familyMembersProvider);
    final space = familySpace.valueOrNull;
    final currentRole = space?.role.toLowerCase() ?? '';
    final canManage = currentRole == 'owner' && !(space?.isReadOnly ?? true);

    return HeroScreenScaffold(
      appBar: ConsciaAppBar(
        title: const Text('Family members'),
        alwaysShowBack: true,
        onBack: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(AppRoutes.familySpace);
          }
        },
      ),
      padding: EdgeInsets.zero,
      bleedBehindAppBar: true,
      child: members.when(
        data: (items) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _FamilyMembersHero(
              familyName: space?.name ?? 'Family Space',
              role: space?.role ?? 'Member',
              currencyCode: space?.currencyCode ?? '',
              memberCount: items.length,
              isReadOnly: space?.isReadOnly ?? false,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ScreenSection(
                    title: 'Members',
                    subtitle: canManage
                        ? 'Change access for contributors and viewers.'
                        : 'Owners manage access. You can still see who belongs here.',
                    child: _MembersLedger(
                      members: items,
                      canManage: canManage,
                    ),
                  ),
                  _LeaveFamilySection(
                    isOwner: currentRole == 'owner',
                    isReadOnly: space?.isReadOnly ?? false,
                  ),
                ],
              ),
            ),
          ],
        ),
        loading: () => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _FamilyMembersHero(
              familyName: space?.name ?? 'Family Space',
              role: space?.role ?? 'Member',
              currencyCode: space?.currencyCode ?? '',
              memberCount: 0,
              isReadOnly: space?.isReadOnly ?? false,
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 28),
              child: Column(
                children: [
                  SkeletonCard(),
                  SizedBox(height: 10),
                  SkeletonCard(),
                ],
              ),
            ),
          ],
        ),
        error: (_, __) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _FamilyMembersHero(
              familyName: space?.name ?? 'Family Space',
              role: space?.role ?? 'Member',
              currencyCode: space?.currencyCode ?? '',
              memberCount: 0,
              isReadOnly: space?.isReadOnly ?? false,
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 28),
              child: _FamilyMembersLoadErrorNotice(),
            ),
          ],
        ),
      ),
    );
  }
}

class _FamilyMembersHero extends StatelessWidget {
  const _FamilyMembersHero({
    required this.familyName,
    required this.role,
    required this.currencyCode,
    required this.memberCount,
    required this.isReadOnly,
  });

  final String familyName;
  final String role;
  final String currencyCode;
  final int memberCount;
  final bool isReadOnly;

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
              'FAMILY ACCESS',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.deepNavy,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'People in $familyName',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: colors.deepNavy,
                fontWeight: FontWeight.w800,
                height: 1.05,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Keep household access clear without exposing personal records.',
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
                EditorialHeroChip(label: _roleLabel(role)),
                if (currencyCode.isNotEmpty)
                  EditorialHeroChip(label: currencyCode),
                EditorialHeroChip(
                  label:
                      '$memberCount ${memberCount == 1 ? 'member' : 'members'}',
                ),
                if (isReadOnly) const EditorialHeroChip(label: 'View-only'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MembersLedger extends StatelessWidget {
  const _MembersLedger({
    required this.members,
    required this.canManage,
  });

  final List<FamilyMember> members;
  final bool canManage;

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) {
      return InlineNotice(
        message: 'No members are attached to this Family Space yet.',
        tone: InlineNoticeTone.neutral,
        icon: AppIcons.icon(
          AppIconKey.people,
          color: Theme.of(context).appColors.deepNavy,
          size: 16,
        ),
      );
    }

    return Column(
      children: [
        for (var index = 0; index < members.length; index++) ...[
          _MemberRow(member: members[index], canManage: canManage),
          if (index != members.length - 1)
            Divider(
              height: 20,
              thickness: 1,
              color: Theme.of(context).appColors.border,
            ),
        ],
      ],
    );
  }
}

class _MemberRow extends ConsumerStatefulWidget {
  const _MemberRow({
    required this.member,
    required this.canManage,
  });

  final FamilyMember member;
  final bool canManage;

  @override
  ConsumerState<_MemberRow> createState() => _MemberRowState();
}

class _MemberRowState extends ConsumerState<_MemberRow> {
  bool _isSubmitting = false;
  String? _errorText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.appColors;
    final canManageThisMember = widget.canManage &&
        !widget.member.isCurrentUser &&
        !widget.member.isOwner;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _MemberAvatar(member: widget.member),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.member.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colors.ink,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${_roleLabel(widget.member.role)} · Joined ${_formatMonthDay(widget.member.joinedAt)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.mutedInk,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (widget.member.isCurrentUser)
              const _YouPill()
            else if (canManageThisMember)
              _ManageMemberButton(
                isBusy: _isSubmitting,
                onPressed: _showMemberActions,
              ),
          ],
        ),
        if (_errorText != null) ...[
          const SizedBox(height: 10),
          InlineNotice(
            message: _errorText!,
            tone: InlineNoticeTone.error,
            icon: AppIcons.icon(
              AppIconKey.error,
              color: colors.expense,
              size: 16,
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _showMemberActions() async {
    final alternateRole =
        widget.member.role.toLowerCase() == 'viewer' ? 'Contributor' : 'Viewer';
    final action = await showModalBottomSheet<_MemberAction>(
      context: context,
      builder: (context) => _MemberActionsSheet(
        member: widget.member,
        alternateRole: alternateRole,
      ),
    );

    if (action == null || !mounted) return;
    switch (action) {
      case _MemberAction.changeRole:
        await _changeRole(alternateRole);
      case _MemberAction.transferOwnership:
        await _transferOwnership();
      case _MemberAction.remove:
        await _remove();
    }
  }

  Future<void> _changeRole(String role) async {
    await _run(
      () => ref.read(familySpaceActionsProvider).updateMemberRole(
            memberId: widget.member.id,
            role: role,
          ),
    );
  }

  Future<void> _transferOwnership() async {
    final confirmed = await ConsciaConfirmSheet.show(
      context,
      title: 'Transfer ownership?',
      message:
          '${widget.member.email} will become the Family Space owner. Your access will change to Contributor.',
      confirmLabel: 'Transfer ownership',
      destructive: false,
    );
    if (!confirmed || !mounted) return;

    await _run(
      () => ref
          .read(familySpaceActionsProvider)
          .transferOwnership(widget.member.id),
      successMessage: 'Family ownership transferred.',
    );
  }

  Future<void> _remove() async {
    final confirmed = await ConsciaConfirmSheet.show(
      context,
      title: 'Remove family member?',
      message:
          '${widget.member.email} will lose access. Existing shared records stay in household history.',
      confirmLabel: 'Remove member',
    );
    if (!confirmed) return;

    await _run(
      () => ref.read(familySpaceActionsProvider).removeMember(widget.member.id),
      successMessage: 'Family member removed.',
    );
  }

  Future<void> _run(
    Future<void> Function() action, {
    String? successMessage,
  }) async {
    setState(() {
      _errorText = null;
      _isSubmitting = true;
    });
    try {
      await action();
      if (!mounted) return;
      if (successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(successMessage)),
        );
      }
    } catch (e, s) {
      if (!mounted) return;
      final error = AppError.from(e, stackTrace: s, log: false);
      setState(() => _errorText = error.userMessage);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}

class _MemberActionsSheet extends StatelessWidget {
  const _MemberActionsSheet({
    required this.member,
    required this.alternateRole,
  });

  final FamilyMember member;
  final String alternateRole;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ConsciaSheetHandle(),
          const SizedBox(height: 18),
          ConsciaSheetHeader(
            title: member.email,
            subtitle:
                'Choose what access this person should have in the household.',
          ),
          const SizedBox(height: 18),
          _SheetActionRow(
            icon: AppIconKey.ownerAccess,
            title: 'Make ${alternateRole.toLowerCase()}',
            subtitle: alternateRole.toLowerCase() == 'viewer'
                ? 'Can view shared household history.'
                : 'Can add and manage Family records.',
            onTap: () => Navigator.of(context).pop(_MemberAction.changeRole),
          ),
          _SheetActionRow(
            icon: AppIconKey.premium,
            title: 'Transfer ownership',
            subtitle: 'Make this person the household owner.',
            onTap: () =>
                Navigator.of(context).pop(_MemberAction.transferOwnership),
          ),
          _SheetActionRow(
            icon: AppIconKey.delete,
            title: 'Remove from household',
            subtitle: 'Existing shared records stay in Family history.',
            destructive: true,
            onTap: () => Navigator.of(context).pop(_MemberAction.remove),
          ),
        ],
      ),
    );
  }
}

class _SheetActionRow extends StatelessWidget {
  const _SheetActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
  });

  final AppIconKey icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final accent = destructive ? colors.expense : colors.deepNavy;
    final bg = destructive ? colors.expenseSoft : colors.navySoft;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            _IconBubble(icon: icon, background: bg, foreground: accent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.mutedInk,
                          height: 1.3,
                        ),
                  ),
                ],
              ),
            ),
            AppIcons.icon(
              AppIconKey.chevronRight,
              color: colors.softInk,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

enum _MemberAction { changeRole, transferOwnership, remove }

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
  String? _errorText;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final isActionable =
        !widget.isOwner && !widget.isReadOnly && !_isSubmitting;

    return ScreenSection(
      title: 'Leaving',
      subtitle: 'What happens if someone steps out of the household.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: isActionable ? _leaveFamily : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _IconBubble(
                    icon: widget.isOwner
                        ? AppIconKey.lock
                        : AppIconKey.logout,
                    background:
                        widget.isOwner ? colors.navySoft : colors.expenseSoft,
                    foreground:
                        widget.isOwner ? colors.deepNavy : colors.expense,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.isOwner
                              ? 'Transfer ownership before leaving'
                              : 'Leave Family Space',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.isOwner
                              ? 'Pick another member as owner first. Then you can leave without stranding the household.'
                              : 'Your personal records remain private. Shared records you already added stay in household history.',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colors.mutedInk,
                                    height: 1.35,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  if (!widget.isOwner) ...[
                    const SizedBox(width: 8),
                    if (_isSubmitting)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      AppIcons.icon(
                        AppIconKey.chevronRight,
                        color:
                            widget.isReadOnly ? colors.border : colors.softInk,
                        size: 18,
                      ),
                  ],
                ],
              ),
            ),
          ),
          if (_errorText != null) ...[
            const SizedBox(height: 12),
            InlineNotice(
              message: _errorText!,
              tone: InlineNoticeTone.error,
              icon: AppIcons.icon(
                AppIconKey.error,
                color: colors.expense,
                size: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _leaveFamily() async {
    final confirmed = await ConsciaConfirmSheet.show(
      context,
      title: 'Leave Family Space?',
      message:
          'You will lose access to shared household views. Records already shared stay in Family history.',
      confirmLabel: 'Leave Family Space',
    );
    if (!confirmed) return;
    if (!mounted) return;

    setState(() {
      _errorText = null;
      _isSubmitting = true;
    });
    try {
      await ref.read(familySpaceActionsProvider).leaveFamilySpace();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Left Family Space.')),
      );
      final router = GoRouter.maybeOf(context);
      if (router != null) {
        context.go(AppRoutes.familySpace);
      } else {
        Navigator.of(context).maybePop();
      }
    } catch (e, s) {
      if (!mounted) return;
      final error = AppError.from(e, stackTrace: s, log: false);
      setState(() => _errorText = error.userMessage);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}

class _MemberAvatar extends StatelessWidget {
  const _MemberAvatar({required this.member});

  final FamilyMember member;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    return Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.navySoft,
        shape: BoxShape.circle,
      ),
      child: Text(
        member.initials,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: colors.deepNavy,
              fontWeight: FontWeight.w900,
            ),
      ),
    );
  }
}

class _ManageMemberButton extends StatelessWidget {
  const _ManageMemberButton({
    required this.isBusy,
    required this.onPressed,
  });

  final bool isBusy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;

    return IconButton(
      onPressed: isBusy ? null : onPressed,
      icon: isBusy
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : AppIcons.icon(
              AppIconKey.more,
              color: colors.deepNavy,
              size: 20,
            ),
      color: colors.deepNavy,
      tooltip: 'More member actions',
      visualDensity: VisualDensity.compact,
    );
  }
}

class _YouPill extends StatelessWidget {
  const _YouPill();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    return _MemberPill(
      icon: AppIconKey.person,
      label: 'You',
      background: colors.surfaceMuted,
      foreground: colors.mutedInk,
    );
  }
}

class _MemberPill extends StatelessWidget {
  const _MemberPill({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
  });

  final AppIconKey icon;
  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcons.icon(
              icon,
              size: 13,
              color: foreground,
            ),
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
      ),
    );
  }
}

class _IconBubble extends StatelessWidget {
  const _IconBubble({
    required this.icon,
    required this.background,
    required this.foreground,
  });

  final AppIconKey icon;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppLayout.listIconSize,
      height: AppLayout.listIconSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: AppIcons.icon(
          icon,
          size: 18,
          color: foreground,
        ),
      ),
    );
  }
}

class _FamilyMembersLoadErrorNotice extends StatelessWidget {
  const _FamilyMembersLoadErrorNotice();

  @override
  Widget build(BuildContext context) {
    return InlineNotice(
      message: 'Unable to load family members.',
      tone: InlineNoticeTone.error,
      icon: AppIcons.icon(
        AppIconKey.error,
        color: Theme.of(context).appColors.expense,
        size: 16,
      ),
    );
  }
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
