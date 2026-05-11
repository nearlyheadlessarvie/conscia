import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_icons.dart';
import '../../core/errors/app_error.dart';
import '../../providers/user_provider.dart';
import '../../services/user_service.dart';
import '../../widgets/hero_screen_scaffold.dart';
import '../../widgets/screen_section.dart';
import '../../widgets/selection_chip_group.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  String? _personality;
  String? _incomeRange;
  String? _occupation;
  String? _household;
  bool _loaded = false;
  bool _saving = false;

  void _loadFromProfile(UserProfile profile) {
    if (_loaded) return;
    _personality = profile.spendingPersonality;
    _incomeRange = profile.incomeRange;
    _occupation = profile.occupationType;
    _household = profile.householdSize;
    _loaded = true;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(userServiceProvider).updateProfile(
            spendingPersonality: _personality,
            incomeRange: _incomeRange,
            occupationType: _occupation,
            householdSize: _household,
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
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final userAsync = ref.watch(currentUserProvider);

    return HeroScreenScaffold(
      appBar: AppBar(title: const Text('My Profile')),
      bottom: FilledButton(
        onPressed: _saving ? null : _save,
        child: _saving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text('Save Changes'),
      ),
      child: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (profile) {
          _loadFromProfile(profile);
          final currencyCode = profile.currencyCode;
          final locale = profile.locale;
          final formatter = NumberFormat.currency(
            locale: locale.replaceAll('_', '-'),
            symbol: '$currencyCode ',
            decimalDigits: 0,
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  child: Text(
                    profile.email.isNotEmpty
                        ? profile.email[0].toUpperCase()
                        : '?',
                  ),
                ),
                title: Text(profile.email),
                subtitle: Text(
                  'Member since ${DateFormat('MMM yyyy').format(profile.createdAt)}',
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
              const Divider(height: 32),
              ScreenSection(
                title: 'Spending Style',
                subtitle:
                    'Keep this aligned with how you naturally make tradeoffs.',
                child: Row(
                  children: [
                    _personalityCard(
                      colors,
                      textTheme,
                      'saver',
                      'Saver',
                    ),
                    const SizedBox(width: 8),
                    _personalityCard(
                      colors,
                      textTheme,
                      'balanced',
                      'Balanced',
                    ),
                    const SizedBox(width: 8),
                    _personalityCard(
                      colors,
                      textTheme,
                      'free_spender',
                      'Free spender',
                    ),
                  ],
                ),
              ),
              ScreenSection(
                title: 'Monthly Income',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: _incomeOptions
                      .map(
                        (option) => _incomeRow(
                          colors,
                          textTheme,
                          option.$1,
                          _incomeLabel(option.$1, formatter),
                        ),
                      )
                      .toList(),
                ),
              ),
              ScreenSection(
                title: 'Occupation',
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
                compact: true,
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
          );
        },
      ),
    );
  }

  static const _incomeOptions = [
    ('low',),
    ('mid',),
    ('high',),
    ('very_high',),
    ('prefer_not_to_say',),
  ];

  String _incomeLabel(String value, NumberFormat formatter) {
    return switch (value) {
      'low' => 'Under ${formatter.format(20000)}',
      'mid' => '${formatter.format(20000)} - ${formatter.format(50000)}',
      'high' => '${formatter.format(50000)} - ${formatter.format(100000)}',
      'very_high' => 'Over ${formatter.format(100000)}',
      _ => 'Prefer not to say',
    };
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

  Widget _personalityCard(
    ColorScheme colors,
    TextTheme textTheme,
    String value,
    String label,
  ) {
    final selected = _personality == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _personality = selected ? null : value;
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? colors.primary : colors.outlineVariant,
              width: selected ? 2 : 1,
            ),
            color: selected ? colors.primaryContainer : colors.surface,
          ),
          child: Column(
            children: [
              AppIcons.spendingStyleBadge(
                value,
                size: 24,
                selected: selected,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: textTheme.labelSmall?.copyWith(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _incomeRow(
    ColorScheme colors,
    TextTheme textTheme,
    String value,
    String label,
  ) {
    final selected = _incomeRange == value;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => setState(() => _incomeRange = selected ? null : value),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? colors.primary : colors.outlineVariant,
              width: selected ? 2 : 1,
            ),
            color: selected ? colors.primaryContainer : colors.surface,
          ),
          child: Row(
            children: [
              Expanded(child: Text(label, style: textTheme.bodyMedium)),
              if (selected)
                Icon(AppIcons.check, size: 18, color: colors.primary),
            ],
          ),
        ),
      ),
    );
  }
}
