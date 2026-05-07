import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_icons.dart';
import '../../providers/user_provider.dart';
import '../../services/user_service.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  String _personality = 'balanced';
  String? _incomeRange;
  String? _occupation;
  String? _household;
  bool _loaded = false;
  bool _saving = false;

  void _loadFromProfile(UserProfile profile) {
    if (_loaded) return;
    _personality = profile.spendingPersonality ?? 'balanced';
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
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e')),
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

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (profile) {
          _loadFromProfile(profile);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
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
                _sectionHeader(textTheme, 'Spending Style'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _personalityCard(
                      colors,
                      textTheme,
                      'saver',
                      'Saver',
                      AppIcons.saver,
                    ),
                    const SizedBox(width: 8),
                    _personalityCard(
                      colors,
                      textTheme,
                      'balanced',
                      'Balanced',
                      AppIcons.balanced,
                    ),
                    const SizedBox(width: 8),
                    _personalityCard(
                      colors,
                      textTheme,
                      'free_spender',
                      'Free spender',
                      AppIcons.freeSpender,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _sectionHeader(textTheme, 'Monthly Income'),
                const SizedBox(height: 12),
                ..._incomeOptions.map(
                  (option) =>
                      _incomeRow(colors, textTheme, option.$1, option.$2),
                ),
                const SizedBox(height: 24),
                _sectionHeader(textTheme, 'Occupation'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _choiceChip('employed', 'Employed', AppIcons.employed, true),
                    _choiceChip(
                      'self_employed',
                      'Self-employed',
                      AppIcons.selfEmployed,
                      true,
                    ),
                    _choiceChip('student', 'Student', AppIcons.student, true),
                    _choiceChip('retired', 'Retired', AppIcons.retired, true),
                    _choiceChip('other', 'Other', AppIcons.other, true),
                  ],
                ),
                const SizedBox(height: 24),
                _sectionHeader(textTheme, 'Household'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _choiceChip('solo', 'Just me', AppIcons.person, false),
                    _choiceChip('couple', 'Couple', AppIcons.couple, false),
                    _choiceChip('family', 'Family', AppIcons.family, false),
                    _choiceChip('shared', 'Shared', AppIcons.sharedHome, false),
                  ],
                ),
                const SizedBox(height: 32),
                FilledButton(
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
              ],
            ),
          );
        },
      ),
    );
  }

  static const _incomeOptions = [
    ('low', 'Lower income'),
    ('mid', 'Mid income'),
    ('high', 'Higher income'),
    ('very_high', 'Very high income'),
    ('prefer_not_to_say', 'Prefer not to say'),
  ];

  Widget _sectionHeader(TextTheme textTheme, String title) {
    return Text(
      title,
      style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
    );
  }

  Widget _personalityCard(
    ColorScheme colors,
    TextTheme textTheme,
    String value,
    String label,
    IconData icon,
  ) {
    final selected = _personality == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _personality = value),
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
              Icon(icon),
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
        onTap: () => setState(() => _incomeRange = value),
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

  Widget _choiceChip(
    String value,
    String label,
    IconData icon,
    bool isOccupation,
  ) {
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
