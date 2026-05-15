import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_icons.dart';
import '../../core/routing/app_router.dart';
import '../../providers/user_provider.dart';
import '../../widgets/hero_screen_scaffold.dart';
import '../../widgets/conscia_app_bar.dart';
import '../../widgets/floating_label_text_field.dart';
import '../../widgets/screen_section.dart';
import '../../widgets/selection_chip_group.dart';

class AboutYouScreen extends ConsumerStatefulWidget {
  const AboutYouScreen({super.key});

  @override
  ConsumerState<AboutYouScreen> createState() => _AboutYouScreenState();
}

class _AboutYouScreenState extends ConsumerState<AboutYouScreen> {
  final _displayNameController = TextEditingController();
  String? _occupation;
  String? _household;
  bool _saving = false;

  bool get _canFinish =>
      !_saving && _displayNameController.text.trim().isNotEmpty;

  Future<void> _finish() async {
    setState(() => _saving = true);
    try {
      await ref.read(userServiceProvider).updateProfile(
            displayName: _displayNameController.text.trim(),
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

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return HeroScreenScaffold(
      appBar: const ConsciaAppBar(
        automaticallyImplyLeading: false,
        title: Text('About You'),
      ),
      bottom: FilledButton(
        onPressed: _canFinish ? _finish : null,
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
            'Tell us what to call you. The rest is optional and helps us personalise your experience.',
            style: textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.only(bottom: 26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What should we call you?',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'This is the name Conscia will use around the app.',
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 14),
                FloatingLabelTextField(
                  controller: _displayNameController,
                  label: 'Display name',
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
          ),
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
