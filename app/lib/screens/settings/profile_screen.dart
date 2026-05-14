import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/app_error.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/user_service.dart';
import '../../widgets/floating_label_text_field.dart';
import '../../widgets/hero_screen_scaffold.dart';
import '../../widgets/conscia_app_bar.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameController = TextEditingController();
  bool _loaded = false;
  bool _saving = false;
  String _aiIntensity = 'balanced';

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _loadFromProfile(UserProfile profile) {
    if (_loaded) return;
    _nameController.text = profile.displayName?.trim().isNotEmpty == true
        ? profile.displayName!.trim()
        : _nameFromEmail(profile.email);
    _aiIntensity = profile.aiPersonalityIntensity;
    _loaded = true;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(userServiceProvider).updateProfile(
            displayName: _nameController.text.trim(),
            aiPersonalityIntensity: _aiIntensity,
          );
      ref.invalidate(currentUserProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved')),
      );
    } catch (e, s) {
      if (!mounted) return;
      final error = AppError.from(e, stackTrace: s);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.userMessage)),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return HeroScreenScaffold(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      appBar: ConsciaAppBar(
        centerTitle: true,
        title: const Text('Profile'),
        leading: IconButton(
          icon: const Text('‹', style: TextStyle(fontSize: 28)),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      child: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (profile) {
          _loadFromProfile(profile);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ProfilePhoto(
                photoUrl: profile.photoUrl,
                initials: _initials(_nameController.text, profile.email),
              ),
              const SizedBox(height: 22),
              FloatingLabelTextField(
                controller: _nameController,
                label: 'Display name',
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _save(),
              ),
              const SizedBox(height: 12),
              FloatingLabelTextField(
                controller: TextEditingController(text: profile.email),
                label: 'Email',
                enabled: false,
              ),
              const SizedBox(height: 12),
              FloatingLabelTextField(
                controller: TextEditingController(
                  text:
                      '${profile.currencyCode} — ${_currencyName(profile.currencyCode)}',
                ),
                label: 'Currency',
                readOnly: true,
              ),
              const SizedBox(height: 12),
              FloatingLabelTextField(
                controller: TextEditingController(
                  text: _spendingStyleLabel(profile.spendingPersonality),
                ),
                label: 'Spending style',
                readOnly: true,
              ),
              const SizedBox(height: 16),
              Text(
                'AI Personality Intensity',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).appColors.mutedInk,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              _IntensitySelector(
                value: _aiIntensity,
                onChanged: (value) => setState(() => _aiIntensity = value),
              ),
              const SizedBox(height: 16),
              Divider(color: Theme.of(context).appColors.border),
              const SizedBox(height: 18),
              Center(
                child: TextButton(
                  onPressed: () => ref.read(authProvider.notifier).logout(),
                  child: Text(
                    'Sign out',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Theme.of(context).appColors.expense,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _nameFromEmail(String email) {
    final local = email.split('@').first;
    if (local.isEmpty) return 'Conscia member';
    return local
        .split(RegExp(r'[._-]+'))
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  String _initials(String name, String email) {
    final source = name.trim().isNotEmpty ? name.trim() : email;
    final parts = source.split(RegExp(r'\s+|@')).where((p) => p.isNotEmpty);
    final initials = parts.take(2).map((p) => p[0].toUpperCase()).join();
    return initials.isEmpty ? '?' : initials;
  }

  String _currencyName(String code) {
    return switch (code.toUpperCase()) {
      'PHP' => 'Philippine Peso',
      'USD' => 'US Dollar',
      'EUR' => 'Euro',
      _ => code.toUpperCase(),
    };
  }

  String _spendingStyleLabel(String? value) {
    return switch (value) {
      'saver' => '🏦  Saver',
      'balanced' => '⚖️  Balanced',
      'free_spender' => '🎉  Free Spender',
      _ => 'Not set',
    };
  }
}

class _ProfilePhoto extends StatelessWidget {
  const _ProfilePhoto({
    required this.photoUrl,
    required this.initials,
  });

  final String? photoUrl;
  final String initials;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    return Column(
      children: [
        CircleAvatar(
          radius: 36,
          backgroundColor: colors.navySoft,
          backgroundImage: photoUrl == null || photoUrl!.isEmpty
              ? null
              : NetworkImage(photoUrl!),
          child: photoUrl == null || photoUrl!.isEmpty
              ? Text(
                  initials,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colors.deepNavy,
                        fontWeight: FontWeight.w900,
                      ),
                )
              : null,
        ),
        const SizedBox(height: 10),
        Text(
          'Change photo',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: colors.deepNavy,
                fontWeight: FontWeight.w800,
              ),
        ),
      ],
    );
  }
}

class _IntensitySelector extends StatelessWidget {
  const _IntensitySelector({
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    return Container(
      height: 40,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colors.border.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          for (final option in const ['mild', 'balanced', 'intense'])
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => onChanged(option),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: value == option
                        ? colors.surfaceRaised
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _label(option),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: value == option
                              ? colors.deepNavy
                              : colors.softInk,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _label(String value) {
    return switch (value) {
      'mild' => 'Mild',
      'intense' => 'Intense',
      _ => 'Balanced',
    };
  }
}
