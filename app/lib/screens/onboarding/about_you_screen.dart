import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_icons.dart';
import '../../core/routing/app_router.dart';
import '../../providers/user_provider.dart';

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
          );
      ref.invalidate(currentUserProvider);
    } catch (_) {}
    if (!mounted) return;
    await markOnboardingComplete();
    if (!mounted) return;
    context.go(AppRoutes.home);
  }

  Future<void> _skip() async {
    await markOnboardingComplete();
    if (!mounted) return;
    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('About You'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _skip,
            child: const Text('Skip'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
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
              Text(
                'Occupation',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _chip('employed', 'Employed', AppIcons.employed, true),
                  _chip(
                    'self_employed',
                    'Self-employed',
                    AppIcons.selfEmployed,
                    true,
                  ),
                  _chip('student', 'Student', AppIcons.student, true),
                  _chip('retired', 'Retired', AppIcons.retired, true),
                  _chip('other', 'Other', AppIcons.other, true),
                ],
              ),
              const SizedBox(height: 28),
              Text(
                'Household',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _chip('solo', 'Just me', AppIcons.person, false),
                  _chip('couple', 'Couple', AppIcons.couple, false),
                  _chip('family', 'Family', AppIcons.family, false),
                  _chip('shared', 'Shared', AppIcons.sharedHome, false),
                ],
              ),
              const SizedBox(height: 32),
              FilledButton(
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String value, String label, IconData icon, bool isOccupation) {
    final selected = isOccupation ? _occupation == value : _household == value;
    return ChoiceChip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        setState(() {
          if (isOccupation) {
            _occupation = selected ? null : value;
          } else {
            _household = selected ? null : value;
          }
        });
      },
    );
  }
}
