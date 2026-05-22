import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_icons.dart';
import '../../core/errors/app_error.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_layout.dart';
import '../../core/routing/app_router.dart';
import '../../providers/family_space_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/editorial_hero_chip.dart';
import '../../widgets/floating_label_text_field.dart';
import '../../widgets/hero_screen_scaffold.dart';
import '../../widgets/inline_notice.dart';
import '../../widgets/conscia_app_bar.dart';
import '../../widgets/screen_section.dart';

class FamilySetupScreen extends ConsumerStatefulWidget {
  const FamilySetupScreen({super.key});

  @override
  ConsumerState<FamilySetupScreen> createState() => _FamilySetupScreenState();
}

class _FamilySetupScreenState extends ConsumerState<FamilySetupScreen> {
  final _nameController = TextEditingController(text: 'My Family Space');
  bool _isSubmitting = false;
  String? _nameError;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currencyCode = ref.watch(userPreferencesProvider).currency;

    return HeroScreenScaffold(
      padding: EdgeInsets.zero,
      bleedBehindAppBar: true,
      appBar: ConsciaAppBar(
        title: const Text('Create Family Space'),
        alwaysShowBack: true,
        onBack: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(AppRoutes.familySpace);
          }
        },
      ),
      bottom: FilledButton(
        onPressed: _isSubmitting ? null : _submit,
        child: Text(_isSubmitting ? 'Creating...' : 'Create Family Space'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CreateFamilyHero(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ScreenSection(
                  title: 'Household details',
                  subtitle:
                      'Name the shared planning space. Personal records stay personal unless you mark them Family.',
                  child: Column(
                    children: [
                      FloatingLabelTextField(
                        controller: _nameController,
                        label: 'Family Space name',
                        prefix: AppIcons.icon(
                          AppIconKey.family,
                          color: Theme.of(context).appColors.deepNavy,
                          size: 20,
                        ),
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                        errorText: _nameError,
                        onChanged: (_) {
                          if (_nameError != null) {
                            setState(() => _nameError = null);
                          }
                        },
                      ),
                      const SizedBox(height: 14),
                      InlineNotice(
                        message:
                            'Shared currency follows $currencyCode from your default workspace. Records stay consistent for everyone in the household.',
                        tone: InlineNoticeTone.neutral,
                        icon: const Icon(Icons.payments_outlined),
                      ),
                    ],
                  ),
                ),
                const ScreenSection(
                  title: 'Premium',
                  subtitle: 'Host the Family Space with Premium.',
                  child: InlineNotice(
                    message:
                        'Requires Premium to create. Invited members can participate free.',
                    tone: InlineNoticeTone.neutral,
                    icon: Icon(Icons.workspace_premium_outlined),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_validate()) return;

    setState(() => _isSubmitting = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(familySpaceActionsProvider).create(
            name: _nameController.text.trim(),
            currencyCode: ref.read(userPreferencesProvider).currency,
          );
      if (!mounted) return;
      context.go(AppRoutes.familySpace);
    } catch (e, s) {
      if (!mounted) return;
      final error = AppError.from(e, stackTrace: s);
      messenger.showSnackBar(SnackBar(content: Text(error.userMessage)));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  bool _validate() {
    final nextNameError =
        _nameController.text.trim().isEmpty ? 'Name is required' : null;

    setState(() {
      _nameError = nextNameError;
    });

    return nextNameError == null;
  }
}

class _CreateFamilyHero extends StatelessWidget {
  const _CreateFamilyHero();

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
            colors.amberSoft.withValues(alpha: 0.88),
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
              'SHARED HOUSEHOLD',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.deepNavy,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Plan together without exposing private accounts',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: colors.deepNavy,
                fontWeight: FontWeight.w800,
                height: 1.05,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start clean, then share only the household spending that belongs there.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.ink,
                height: 1.32,
              ),
            ),
            const SizedBox(height: 16),
            const Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                EditorialHeroChip(label: 'Private by default'),
                EditorialHeroChip(label: 'Premium host'),
                EditorialHeroChip(label: 'Members join free'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
