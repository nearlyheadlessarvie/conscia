import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_icons.dart';
import '../../core/routing/app_router.dart';
import '../../providers/user_provider.dart';
import '../../widgets/hero_screen_scaffold.dart';
import '../../widgets/conscia_app_bar.dart';
import '../../widgets/screen_section.dart';
import '../../widgets/selection_chip_group.dart';

class AboutYouScreen extends ConsumerStatefulWidget {
  const AboutYouScreen({super.key});

  @override
  ConsumerState<AboutYouScreen> createState() => _AboutYouScreenState();
}

class _AboutYouScreenState extends ConsumerState<AboutYouScreen> {
  String? _occupation;
  String? _household;
  bool _saving = false;

  Future<void> _finish() async {
    setState(() => _saving = true);
    try {
      await ref.read(userServiceProvider).updateProfile(
            occupationType: _occupation,
            householdSize: _household,
            hasCompletedOnboarding: true,
          );
      ref.invalidate(currentUserProvider);
    } catch (_) {}
    if (!mounted) return;
    await markOnboardingComplete();
    if (!mounted) return;
    context.go(AppRoutes.home);
  }

  Future<void> _skip() async {
    try {
      await ref.read(userServiceProvider).updateProfile(
            hasCompletedOnboarding: true,
          );
      ref.invalidate(currentUserProvider);
    } catch (_) {}
    await markOnboardingComplete();
    if (!mounted) return;
    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return HeroScreenScaffold(
      appBar: ConsciaAppBar(
        automaticallyImplyLeading: false,
        title: const Text('About You'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _skip,
            child: const Text('Skip'),
          ),
        ],
      ),
      bottom: FilledButton(
        onPressed: _saving ? null : _finish,
        child: _saving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text('Go to dashboard'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Step 3 of 3',
            style: textTheme.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Text('A bit more about you', style: textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(
            'All optional. Helps us personalise your experience.',
            style: textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 28),
          ScreenSection(
            title: 'Occupation',
            subtitle: 'Pick the closest fit for how you usually earn or spend.',
            child: SelectionChipGroup(
              options: const [
                'employed',
                'self_employed',
                'student',
                'retired',
                'other',
              ],
              value: _occupation,
              labelBuilder: _labelForValue,
              avatarBuilder: (value, selected) =>
                  AppIcons.profileBadge(value, selected: selected),
              showTrailingCheck: true,
              onSelected: (value) {
                setState(() {
                  _occupation = _occupation == value ? null : value;
                });
              },
            ),
          ),
          ScreenSection(
            title: 'Household',
            subtitle: 'This helps Conscia make guidance feel more realistic.',
            child: SelectionChipGroup(
              options: const ['solo', 'couple', 'family', 'shared'],
              value: _household,
              labelBuilder: _labelForValue,
              avatarBuilder: (value, selected) =>
                  AppIcons.profileBadge(value, selected: selected),
              showTrailingCheck: true,
              onSelected: (value) {
                setState(() {
                  _household = _household == value ? null : value;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  String _labelForValue(String value) {
    return switch (value) {
      'self_employed' => 'Self-employed',
      'solo' => 'Just me',
      'couple' => 'Couple',
      'family' => 'Family',
      'shared' => 'Shared',
      'student' => 'Student',
      'retired' => 'Retired',
      'other' => 'Other',
      _ => 'Employed',
    };
  }
}
