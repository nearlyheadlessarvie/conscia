import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/errors/app_error.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_layout.dart';
import '../../core/utils/currency_formatter.dart';
import '../../providers/user_provider.dart';
import '../../services/user_service.dart';
import '../../widgets/conscia_app_bar.dart';
import '../../widgets/conscia_bottom_sheet.dart';
import '../../widgets/floating_label_text_field.dart';
import '../../widgets/single_select_list.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _appBarScrollProgress = ValueNotifier<double>(0);
  final _nameController = TextEditingController();
  bool _loaded = false;
  bool _saving = false;
  String? _spendingPersonality;
  String? _incomeRange;
  String? _occupationType;
  String? _householdSize;
  String? _profilePictureKey;

  static const _spendingOptions = [
    _ProfileOption(
      value: 'saver',
      title: 'Saver',
      subtitle: 'Careful, deliberate, goal-focused.',
    ),
    _ProfileOption(
      value: 'balanced',
      title: 'Balanced',
      subtitle: 'Mix of saving and enjoying money.',
    ),
    _ProfileOption(
      value: 'free_spender',
      title: 'Free spender',
      subtitle: 'Lives in the moment, plans after.',
    ),
  ];

  static const _occupationOptions = [
    _ProfileOption(value: 'employed', title: 'Employed'),
    _ProfileOption(value: 'self_employed', title: 'Self-employed'),
    _ProfileOption(value: 'student', title: 'Student'),
    _ProfileOption(value: 'retired', title: 'Retired'),
    _ProfileOption(value: 'other', title: 'Other'),
  ];

  static const _householdOptions = [
    _ProfileOption(value: 'solo', title: 'Just me'),
    _ProfileOption(value: 'couple', title: 'Couple'),
    _ProfileOption(value: 'family', title: 'Family'),
    _ProfileOption(value: 'shared', title: 'Shared'),
  ];

  @override
  void dispose() {
    _appBarScrollProgress.dispose();
    _nameController.dispose();
    super.dispose();
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification.metrics.axis == Axis.vertical) {
      final nextProgress = (notification.metrics.pixels / 10).clamp(0.0, 1.0);
      if (_appBarScrollProgress.value != nextProgress) {
        _appBarScrollProgress.value = nextProgress;
      }
    }
    return false;
  }

  void _loadFromProfile(UserProfile profile) {
    if (_loaded) return;
    _nameController.text = profile.displayName?.trim().isNotEmpty == true
        ? profile.displayName!.trim()
        : _nameFromEmail(profile.email);
    _spendingPersonality = profile.spendingPersonality;
    _incomeRange = profile.incomeRange;
    _occupationType = profile.occupationType;
    _householdSize = profile.householdSize;
    _profilePictureKey = profile.profilePictureKey;
    _loaded = true;
  }

  Future<void> _save({bool showSuccess = true}) async {
    setState(() => _saving = true);
    try {
      await ref.read(userServiceProvider).updateProfile(
            displayName: _nameController.text.trim(),
            profilePictureKey: _profilePictureKey,
            spendingPersonality: _spendingPersonality,
            incomeRange: _incomeRange,
            occupationType: _occupationType,
            householdSize: _householdSize,
          );
      ref.invalidate(currentUserProvider);
      if (!mounted) return;
      if (showSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile saved')),
        );
      }
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

  Future<void> _pickAndSavePhoto() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (image == null) return;

    setState(() => _saving = true);
    try {
      final contentType = image.mimeType ?? _contentTypeFromName(image.name);
      final service = ref.read(userServiceProvider);
      final upload = await service.createProfilePictureUpload(
        contentType: contentType,
      );
      final bytes = await image.readAsBytes();
      await service.uploadProfilePicture(
        uploadUrl: upload.uploadUrl,
        proxyUploadUrl: upload.proxyUploadUrl,
        bytes: bytes,
        contentType: contentType,
      );
      _profilePictureKey = upload.profilePictureKey;
      await _save(showSuccess: false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile photo updated')),
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

  Future<void> _selectOption({
    required String title,
    required List<_ProfileOption> options,
    required String? value,
    required ValueChanged<String> onChanged,
  }) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).appColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => _ProfileOptionSheet(
        title: title,
        options: options,
        value: value,
      ),
    );

    if (selected != null && mounted) {
      setState(() => onChanged(selected));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final userAsync = ref.watch(currentUserProvider);

    return ConsciaAppBarScrollScope(
      scrollProgress: _appBarScrollProgress,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        resizeToAvoidBottomInset: false,
        appBar: const ConsciaAppBar(title: Text('Profile')),
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
            child: userAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (profile) {
                _loadFromProfile(profile);
                final incomeOptions = _incomeOptions(profile);
                return Stack(
                  children: [
                    CustomScrollView(
                      key: const PageStorageKey('profile-shell-scroll'),
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(
                          child: _ProfileEditorialHero(
                            displayName: _nameController.text.trim().isEmpty
                                ? _nameFromEmail(profile.email)
                                : _nameController.text.trim(),
                            email: profile.email,
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 22, 20, 112),
                          sliver: SliverList.list(
                            children: [
                              const _ProfileSectionLabel(
                                title: 'Personal details',
                                subtitle:
                                    'The name and account identity Conscia uses.',
                              ),
                              const SizedBox(height: 10),
                              _ProfilePhotoBlock(
                                profile: profile,
                                initials: _initials(
                                  _nameController.text,
                                  profile.email,
                                ),
                                onPhotoTap: _saving ? null : _pickAndSavePhoto,
                              ),
                              const SizedBox(height: 16),
                              FloatingLabelTextField(
                                controller: _nameController,
                                label: 'Display name',
                                textInputAction: TextInputAction.done,
                                textCapitalization: TextCapitalization.words,
                                onSubmitted: (_) => _save(),
                              ),
                              const SizedBox(height: 24),
                              const _ProfileSectionLabel(
                                title: 'Money profile',
                                subtitle:
                                    'Keep guidance tuned to your real-world context.',
                              ),
                              const SizedBox(height: 10),
                              _ProfileSelectField(
                                label: 'Spending style',
                                value: _labelForOption(
                                  _spendingOptions,
                                  _spendingPersonality,
                                ),
                                onTap: () => _selectOption(
                                  title: 'Spending style',
                                  options: _spendingOptions,
                                  value: _spendingPersonality,
                                  onChanged: (value) =>
                                      _spendingPersonality = value,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _ProfileSelectField(
                                label: 'Monthly income',
                                value: _labelForOption(
                                  incomeOptions,
                                  _incomeRange,
                                ),
                                onTap: () => _selectOption(
                                  title: 'Monthly income',
                                  options: incomeOptions,
                                  value: _incomeRange,
                                  onChanged: (value) => _incomeRange = value,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _ProfileSelectField(
                                label: 'Occupation',
                                value: _labelForOption(
                                  _occupationOptions,
                                  _occupationType,
                                ),
                                onTap: () => _selectOption(
                                  title: 'Occupation',
                                  options: _occupationOptions,
                                  value: _occupationType,
                                  onChanged: (value) => _occupationType = value,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _ProfileSelectField(
                                label: 'Household',
                                value: _labelForOption(
                                  _householdOptions,
                                  _householdSize,
                                ),
                                onTap: () => _selectOption(
                                  title: 'Household',
                                  options: _householdOptions,
                                  value: _householdSize,
                                  onChanged: (value) => _householdSize = value,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    _ProfileSaveCta(
                      saving: _saving,
                      onPressed: _saving ? null : _save,
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  String _labelForOption(List<_ProfileOption> options, String? value) {
    if (value == null || value.isEmpty) return 'Not set';
    return options
        .firstWhere(
          (option) => option.value == value,
          orElse: () => _ProfileOption(value: value, title: value),
        )
        .title;
  }

  List<_ProfileOption> _incomeOptions(UserProfile profile) {
    String money(double amount) => CurrencyFormatter.formatCompact(
          amount,
          currencyCode: profile.currencyCode,
          locale: profile.locale,
        );

    return [
      _ProfileOption(value: 'low', title: 'Under ${money(20000)}'),
      _ProfileOption(value: 'mid', title: '${money(20000)} - ${money(50000)}'),
      _ProfileOption(
        value: 'high',
        title: '${money(50000)} - ${money(100000)}',
      ),
      _ProfileOption(value: 'very_high', title: 'Over ${money(100000)}'),
      const _ProfileOption(
        value: 'prefer_not_to_say',
        title: 'Prefer not to say',
      ),
    ];
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

  String _contentTypeFromName(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }
}

class _ProfileSaveCta extends StatelessWidget {
  const _ProfileSaveCta({
    required this.saving,
    required this.onPressed,
  });

  final bool saving;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: IgnorePointer(
        ignoring: onPressed == null,
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            20 + bottomInset + keyboardInset,
          ),
          child: SizedBox(
            key: const ValueKey('profile-save-cta'),
            child: FilledButton(
              onPressed: onPressed,
              child: saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Save'),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileEditorialHero extends StatelessWidget {
  const _ProfileEditorialHero({
    required this.displayName,
    required this.email,
  });

  final String displayName;
  final String email;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      key: const ValueKey('profile-editorial-hero'),
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        AppLayout.screenPadding,
        AppLayout.bleedingHeroTop(context),
        AppLayout.screenPadding,
        AppLayout.heroBottomPadding,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.navySoft, colors.amberSoft],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PROFILE HUB',
            style: textTheme.labelSmall?.copyWith(
              color: colors.deepNavy,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Keep your money profile personal',
            style: textTheme.headlineSmall?.copyWith(
              color: colors.deepNavy,
              fontWeight: FontWeight.w800,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Update how Conscia sees you without mixing this up with app preferences.',
            style: textTheme.bodyMedium?.copyWith(
              color: colors.ink,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _ProfileHeroIdentityPill(
                key: const ValueKey('profile-hero-display-name-pill'),
                icon: Icons.person_rounded,
                label: displayName,
              ),
              _ProfileHeroIdentityPill(
                key: const ValueKey('profile-hero-email-pill'),
                icon: Icons.alternate_email_rounded,
                label: email,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileHeroIdentityPill extends StatelessWidget {
  const _ProfileHeroIdentityPill({
    super.key,
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).textTheme;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 188),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surfaceRaised.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: colors.border.withValues(alpha: 0.7)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: colors.deepNavy),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelSmall?.copyWith(
                    color: colors.deepNavy,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfilePhotoBlock extends StatelessWidget {
  const _ProfilePhotoBlock({
    required this.profile,
    required this.initials,
    required this.onPhotoTap,
  });

  final UserProfile profile;
  final String initials;
  final VoidCallback? onPhotoTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          _ProfilePhoto(
            photoUrl: profile.photoUrl,
            initials: initials,
            onTap: onPhotoTap,
          ),
        ],
      ),
    );
  }
}

class _ProfileSectionLabel extends StatelessWidget {
  const _ProfileSectionLabel({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: textTheme.labelSmall?.copyWith(
            color: colors.mutedInk,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.9,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: textTheme.bodySmall?.copyWith(
            color: colors.mutedInk,
            height: 1.25,
          ),
        ),
      ],
    );
  }
}

class _ProfilePhoto extends StatelessWidget {
  const _ProfilePhoto({
    required this.photoUrl,
    required this.initials,
    required this.onTap,
  });

  final String? photoUrl;
  final String initials;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    return InkWell(
      key: const ValueKey('profile-photo-action'),
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 38,
                backgroundColor: colors.navySoft,
                backgroundImage: photoUrl == null || photoUrl!.isEmpty
                    ? null
                    : NetworkImage(photoUrl!),
                child: photoUrl == null || photoUrl!.isEmpty
                    ? Text(
                        initials,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: colors.deepNavy,
                                  fontWeight: FontWeight.w900,
                                ),
                      )
                    : null,
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.surfaceRaised,
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      Icons.camera_alt_rounded,
                      size: 15,
                      color: colors.deepNavy,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileSelectField extends StatelessWidget {
  const _ProfileSelectField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: colors.frostedFill,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.fromLTRB(14, 8, 12, 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.border, width: 1.5),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: textTheme.labelSmall?.copyWith(
                        color: colors.mutedInk,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.ink,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: colors.deepNavy.withValues(alpha: 0.55),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileOptionSheet extends StatelessWidget {
  const _ProfileOptionSheet({
    required this.title,
    required this.options,
    required this.value,
  });

  final String title;
  final List<_ProfileOption> options;
  final String? value;

  @override
  Widget build(BuildContext context) {
    _ProfileOption? selectedOption;
    for (final option in options) {
      if (option.value == value) {
        selectedOption = option;
        break;
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ConsciaSheetHandle(),
          const SizedBox(height: 18),
          ConsciaSheetHeader(
            title: title,
            subtitle: 'Choose the option that best fits your profile.',
          ),
          const SizedBox(height: 18),
          SingleSelectList<_ProfileOption>(
            options: options,
            value: selectedOption,
            titleBuilder: (option) => option.title,
            subtitleBuilder: (option) => option.subtitle,
            onChanged: (option) => Navigator.of(context).pop(option.value),
          ),
        ],
      ),
    );
  }
}

class _ProfileOption {
  const _ProfileOption({
    required this.value,
    required this.title,
    this.subtitle,
  });

  final String value;
  final String title;
  final String? subtitle;
}
