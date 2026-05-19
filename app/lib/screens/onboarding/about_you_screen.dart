import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_icons.dart';
import '../../core/routing/app_router.dart';
import '../../providers/user_provider.dart';
import '../../widgets/floating_label_text_field.dart';
import '../../widgets/screen_section.dart';
import '../../widgets/single_select_list.dart';
import 'widgets/onboarding_step_scaffold.dart';

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
    return OnboardingStepScaffold(
      appBarTitle: 'About You',
      stepLabel: 'Step 3 of 3',
      heroTitle: 'Make Conscia feel like yours',
      heroSubtitle:
          'Tell us what to call you, then add a little context so guidance lands closer to real life.',
      heroChips: const [
        OnboardingHeroChip(label: 'Name required', icon: Icons.person_outline),
        OnboardingHeroChip(label: 'Context optional', icon: Icons.tune_rounded),
      ],
      bottom: FilledButton(
        onPressed: _canFinish ? _finish : null,
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
        ),
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
      children: [
        ScreenSection(
          title: 'Personal details',
          subtitle: 'This is the name Conscia will use around the app.',
          child: FloatingLabelTextField(
            controller: _displayNameController,
            label: 'Display name',
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            onChanged: (_) => setState(() {}),
          ),
        ),
        ScreenSection(
          title: 'Occupation',
          subtitle: 'Pick the closest fit for how you usually earn or spend.',
          child: SingleSelectList<String>(
            options: const [
              'employed',
              'self_employed',
              'student',
              'retired',
              'other',
            ],
            value: _occupation,
            titleBuilder: _labelForValue,
            leadingBuilder: (context, value, selected) =>
                AppIcons.profileBadge(value, size: 30, selected: selected),
            onChanged: (value) => setState(() => _occupation = value),
          ),
        ),
        ScreenSection(
          title: 'Household',
          subtitle: 'This helps Conscia make guidance feel more realistic.',
          child: SingleSelectList<String>(
            options: const ['solo', 'couple', 'family', 'shared'],
            value: _household,
            titleBuilder: _labelForValue,
            leadingBuilder: (context, value, selected) =>
                AppIcons.profileBadge(value, size: 30, selected: selected),
            onChanged: (value) => setState(() => _household = value),
          ),
        ),
      ],
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
