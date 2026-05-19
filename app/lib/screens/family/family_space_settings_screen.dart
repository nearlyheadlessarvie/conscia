import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_icons.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_layout.dart';
import '../../models/family_space.dart';
import '../../providers/app_availability_provider.dart';
import '../../providers/family_space_provider.dart';
import '../../widgets/conscia_bottom_sheet.dart';
import '../../widgets/floating_label_text_field.dart';
import '../../widgets/conscia_app_bar.dart';
import '../../widgets/screen_section.dart';
import '../../widgets/skeleton_loader.dart';

class FamilySpaceSettingsScreen extends ConsumerStatefulWidget {
  const FamilySpaceSettingsScreen({super.key});

  @override
  ConsumerState<FamilySpaceSettingsScreen> createState() =>
      _FamilySpaceSettingsScreenState();
}

class _FamilySpaceSettingsScreenState
    extends ConsumerState<FamilySpaceSettingsScreen> {
  final _scrollProgress = ValueNotifier<double>(0);

  @override
  void dispose() {
    _scrollProgress.dispose();
    super.dispose();
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;
    final nextProgress = (notification.metrics.pixels / 10).clamp(0.0, 1.0);
    if (_scrollProgress.value != nextProgress) {
      _scrollProgress.value = nextProgress;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final familySpace = ref.watch(familySpaceProvider);
    final colors = Theme.of(context).appColors;

    return ConsciaAppBarScrollScope(
      scrollProgress: _scrollProgress,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: ConsciaAppBar(
          title: const Text('Shared Conscia'),
          alwaysShowBack: true,
          onBack: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.settings);
            }
          },
        ),
        body: NotificationListener<ScrollNotification>(
          onNotification: _handleScrollNotification,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [colors.pageTop, colors.pageBottom],
              ),
            ),
            child: familySpace.when(
              data: (space) => _SharedConsciaScrollView(
                child: space == null
                    ? const _NoFamilySpaceSettingsView()
                    : _FamilySpaceSettingsView(space: space),
              ),
              loading: () => const _SharedConsciaScrollView(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 96, 20, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonCard(),
                      SizedBox(height: 14),
                      SkeletonCard(),
                    ],
                  ),
                ),
              ),
              error: (_, __) {
                final isBlocked = ref.watch(
                  appAvailabilityProvider.select((state) => state.isBlocked),
                );

                if (isBlocked) {
                  return const _SharedConsciaScrollView(
                    child: SizedBox.shrink(),
                  );
                }

                return _SharedConsciaScrollView(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 96, 20, 28),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text('Unable to load Shared Conscia'),
                        ),
                        OutlinedButton(
                          onPressed: () => ref.invalidate(familySpaceProvider),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _SharedConsciaScrollView extends StatelessWidget {
  const _SharedConsciaScrollView({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: child,
      ),
    );
  }
}

class _NoFamilySpaceSettingsView extends StatelessWidget {
  const _NoFamilySpaceSettingsView();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SharedConsciaHero(
          eyebrow: 'SHARED HOUSEHOLD',
          title: 'Create your household space',
          body:
              'Plan together without exposing everything personal. Family records only appear when you mark them as Family.',
          pills: const ['Private by default', 'Family only'],
          shortcuts: [
            _HeroShortcutData(
              icon: AppIcons.family,
              title: 'Create space',
              subtitle: 'Start sharing safely',
              onTap: () => context.push(AppRoutes.familySetup),
            ),
          ],
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 24, 20, 28),
          child: ScreenSection(
            title: 'What gets shared',
            subtitle: 'Shared Conscia keeps personal records out by default.',
            child: _SettingsGroup(
              rows: [
                _SettingsRowData(
                  icon: Icons.lock_outline_rounded,
                  title: 'Personal stays personal',
                  subtitle: 'Only Family-marked records enter the household.',
                ),
                _SettingsRowData(
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'Shared planning',
                  subtitle: 'Family budgets and household activity live here.',
                ),
              ],
            ),
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
    final canInvite = role == 'owner' && !space.isReadOnly;
    final inviteStatus = space.isReadOnly
        ? 'Premium inactive'
        : role == 'owner'
            ? 'Owner access'
            : 'Owner only';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SharedConsciaHero(
          eyebrow: 'SHARED HOUSEHOLD',
          title: space.name,
          body: 'Plan together without exposing everything personal.',
          pills: [
            space.isReadOnly ? 'View-only' : _roleLabel(space.role),
            space.currencyCode,
            if (space.isReadOnly) 'Premium inactive',
          ],
          shortcuts: [
            _HeroShortcutData(
              icon: AppIcons.family,
              title: 'Members',
              subtitle: 'Roles & access',
              onTap: () => context.push(AppRoutes.familyMembers),
            ),
            if (role == 'owner')
              _HeroShortcutData(
                icon: Icons.person_add_alt_1_outlined,
                title: 'Invite family',
                subtitle: space.isReadOnly ? 'Premium inactive' : 'Owner tool',
                onTap: canInvite
                    ? () => context.push(AppRoutes.familyInvites)
                    : null,
              ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ScreenSection(
                title: 'Household',
                subtitle: 'Identity and access for this Family Space.',
                child: _SettingsGroup(
                  rows: [
                    _SettingsRowData(
                      icon: Icons.home_outlined,
                      title: 'Household name',
                      subtitle: space.name,
                      onTap: canManage
                          ? () => _RenameFamilySpaceSheet.show(
                                context,
                                initialName: space.name,
                              )
                          : null,
                    ),
                    _SettingsRowData(
                      icon: Icons.verified_user_outlined,
                      title: 'Your access',
                      subtitle: '${space.role} · ${space.currencyCode}',
                    ),
                    const _SettingsRowData(
                      icon: Icons.lock_outline_rounded,
                      title: 'Privacy boundary',
                      subtitle: 'Only records marked Family are shared here.',
                    ),
                    if (space.isReadOnly)
                      const _SettingsRowData(
                        icon: Icons.lock_outline_rounded,
                        title: 'Premium lock',
                        subtitle:
                            'Shared Conscia is view-only while Premium is inactive.',
                      ),
                  ],
                ),
              ),
              ScreenSection(
                title: 'Manage',
                subtitle: 'Actions that change what belongs to the household.',
                child: _SettingsGroup(
                  rows: [
                    _SettingsRowData(
                      icon: AppIcons.family,
                      title: 'Members',
                      subtitle: 'View access, roles, and leaving rules.',
                      onTap: () => context.push(AppRoutes.familyMembers),
                    ),
                    _SettingsRowData(
                      icon: Icons.person_add_alt_1_outlined,
                      title: 'Invites',
                      subtitle: canInvite
                          ? 'Invite registered family members by email.'
                          : 'Only owners can invite registered family members.',
                      status: inviteStatus,
                      onTap: canInvite
                          ? () => context.push(AppRoutes.familyInvites)
                          : null,
                    ),
                  ],
                ),
              ),
            ],
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
          20,
          8,
          20,
          18 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ConsciaSheetHandle(),
            const SizedBox(height: 18),
            const ConsciaSheetHeader(
              title: 'Edit household name',
              subtitle: 'This is how the shared space appears to members.',
            ),
            const SizedBox(height: 12),
            FloatingLabelTextField(
              controller: _controller,
              label: 'Household name',
              autofocus: true,
              textCapitalization: TextCapitalization.words,
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

class _HeroShortcutData {
  const _HeroShortcutData({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
}

class _SharedConsciaHero extends StatelessWidget {
  const _SharedConsciaHero({
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.pills,
    required this.shortcuts,
  });

  final String eyebrow;
  final String title;
  final String body;
  final List<String> pills;
  final List<_HeroShortcutData> shortcuts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.appColors;

    return Container(
      key: const ValueKey('shared-conscia-hero'),
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
            eyebrow,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.deepNavy,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: colors.deepNavy,
              fontWeight: FontWeight.w800,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
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
              for (final pill in pills) _HeroPill(label: pill),
            ],
          ),
          if (shortcuts.isNotEmpty) ...[
            const SizedBox(height: 16),
            _HeroShortcutGrid(shortcuts: shortcuts),
          ],
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceRaised.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.deepNavy,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
        ),
      ),
    );
  }
}

class _HeroShortcutGrid extends StatelessWidget {
  const _HeroShortcutGrid({required this.shortcuts});

  final List<_HeroShortcutData> shortcuts;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final shortcut in shortcuts)
          SizedBox(
            width: shortcuts.length == 1
                ? double.infinity
                : (MediaQuery.sizeOf(context).width - 52) / 2,
            child: _HeroShortcutCard(shortcut: shortcut),
          ),
      ],
    );
  }
}

class _HeroShortcutCard extends StatelessWidget {
  const _HeroShortcutCard({required this.shortcut});

  final _HeroShortcutData shortcut;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final enabled = shortcut.onTap != null;

    return Material(
      color: colors.surfaceRaised.withValues(alpha: enabled ? 0.9 : 0.52),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: shortcut.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Icon(
                shortcut.icon,
                size: 18,
                color: enabled ? colors.deepNavy : colors.softInk,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shortcut.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: enabled ? colors.deepNavy : colors.mutedInk,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      shortcut.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: colors.mutedInk,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: enabled ? colors.softInk : Colors.transparent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.rows});

  final List<_SettingsRowData> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < rows.length; index++) ...[
          _SettingsRow(data: rows[index]),
          if (index != rows.length - 1)
            Divider(
              height: 1,
              thickness: 1,
              indent: 58,
              color: Theme.of(context).appColors.border,
            ),
        ],
      ],
    );
  }
}

class _SettingsRowData {
  const _SettingsRowData({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.status,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? status;
  final VoidCallback? onTap;
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({required this.data});

  final _SettingsRowData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.appColors;
    final enabled = data.onTap != null;

    return InkWell(
      onTap: data.onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: colors.familySoft,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(data.icon, color: colors.family, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colors.ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    data.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.mutedInk,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            if (data.status != null) ...[
              const SizedBox(width: 8),
              _RowStatusPill(label: data.status!),
              Icon(
                Icons.chevron_right_rounded,
                color: colors.softInk,
              ),
            ] else if (enabled)
              Icon(
                Icons.chevron_right_rounded,
                color: colors.softInk,
              ),
          ],
        ),
      ),
    );
  }
}

class _RowStatusPill extends StatelessWidget {
  const _RowStatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.navySoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.deepNavy,
                fontWeight: FontWeight.w800,
              ),
        ),
      ),
    );
  }
}

String _roleLabel(String role) {
  final normalized = role.trim();
  if (normalized.isEmpty) return 'Viewer';
  return normalized[0].toUpperCase() + normalized.substring(1).toLowerCase();
}
