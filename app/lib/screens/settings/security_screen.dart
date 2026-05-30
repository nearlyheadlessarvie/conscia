import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_icons.dart';
import '../../core/errors/app_error.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_layout.dart';
import '../../core/utils/password_policy.dart';
import '../../providers/auth_provider.dart';
import '../../providers/passkey_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/passkey_service.dart';
import '../../widgets/conscia_app_bar.dart';
import '../../widgets/conscia_bottom_sheet.dart';
import '../../widgets/editorial_section_header.dart';
import '../../widgets/floating_label_text_field.dart';

class SecurityScreen extends ConsumerStatefulWidget {
  const SecurityScreen({super.key});

  @override
  ConsumerState<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends ConsumerState<SecurityScreen> {
  final _appBarScrollProgress = ValueNotifier<double>(0);

  bool _isRegisteringPasskey = false;

  @override
  void dispose() {
    _appBarScrollProgress.dispose();
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

  Future<void> _showPasswordSheet(bool hasPassword) async {
    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).appColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => _PasswordSheet(hasPassword: hasPassword),
    );

    if (updated == true && mounted) {
      ref.invalidate(currentUserProvider);
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text('Password updated. You can now sign in with email.'),
          ),
        );
    }
  }

  Future<void> _registerPasskey() async {
    if (_isRegisteringPasskey) return;

    setState(() => _isRegisteringPasskey = true);
    try {
      await ref.read(passkeyServiceProvider).registerCurrentUserPasskey();
      final email = ref.read(currentUserProvider).valueOrNull?.email;
      if (email != null && email.trim().isNotEmpty) {
        final notifier = ref.read(passkeySignInPreferenceProvider.notifier);
        await notifier.registerEmail(email);
        await notifier.setPasskeyFirstEnabled(true);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(content: Text('Passkey ready on this device.')),
        );
    } catch (error) {
      if (!mounted) return;
      if (!isPasskeyCancellation(error)) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(content: Text(friendlyPasskeyErrorMessage(error))),
          );
      }
    } finally {
      if (mounted) {
        setState(() => _isRegisteringPasskey = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.appColors;
    final passkeysAvailable =
        ref.watch(passkeyAvailabilityProvider).valueOrNull ?? false;
    final sessionSupportsPasskeys =
        ref.watch(currentSessionSupportsPasskeysProvider);
    final passkeyPreference = ref.watch(passkeySignInPreferenceProvider);
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final currentEmail = currentUser?.email;
    final hasPassword = currentUser?.hasPassword ?? false;
    final hasRegisteredCurrentPasskey = currentEmail != null &&
        passkeyPreference.hasRegisteredEmail(currentEmail);
    final canUsePasskeys = passkeysAvailable && sessionSupportsPasskeys;

    return ConsciaAppBarScrollScope(
      scrollProgress: _appBarScrollProgress,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: const ConsciaAppBar(title: Text('Security')),
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
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                const SliverToBoxAdapter(child: _SecurityHero()),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 36),
                  sliver: SliverList.list(
                    children: [
                      const EditorialSectionHeader(
                        title: 'Password',
                        subtitle:
                            'Control email password sign-in for this account.',
                      ),
                      const SizedBox(height: 10),
                      _SecurityMethodRow(
                        icon: AppIconKey.password,
                        title: hasPassword ? 'Change Password' : 'Add Password',
                        subtitle: hasPassword
                            ? 'Update the password used for email sign-in'
                            : 'Add email password sign-in to this account',
                        onTap: () => _showPasswordSheet(hasPassword),
                      ),
                      const SizedBox(height: 28),
                      const EditorialSectionHeader(
                        title: 'Passkeys',
                        subtitle:
                            'Use device unlock for faster sign-in when Cognito supports this session.',
                      ),
                      const SizedBox(height: 10),
                      _SecurityMethodRow(
                        icon: AppIconKey.fingerprint,
                        title: _isRegisteringPasskey
                            ? 'Setting Up Passkey...'
                            : hasRegisteredCurrentPasskey
                                ? 'Passkey Ready'
                                : 'Set Up Passkey',
                        subtitle: canUsePasskeys
                            ? hasRegisteredCurrentPasskey
                                ? 'Registered for this account on this device'
                                : 'Use Face ID, fingerprint, or device unlock next time'
                            : 'Passkeys are unavailable for this sign-in session',
                        onTap: canUsePasskeys && !_isRegisteringPasskey
                            ? _registerPasskey
                            : null,
                      ),
                      if (passkeyPreference.registeredEmails.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _SecuritySwitchRow(
                          icon: AppIconKey.passkey,
                          title: 'Passkey First Sign-In',
                          subtitle:
                              'Show saved passkey accounts before email sign-in',
                          value: passkeyPreference.isPasskeyFirstEnabled,
                          onChanged: (value) {
                            unawaited(
                              ref
                                  .read(
                                    passkeySignInPreferenceProvider.notifier,
                                  )
                                  .setPasskeyFirstEnabled(value),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SecurityHero extends StatelessWidget {
  const _SecurityHero();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).textTheme;

    return Container(
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
            'SECURITY',
            style: textTheme.labelSmall?.copyWith(
              color: colors.deepNavy,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Keep sign-in yours',
            style: textTheme.headlineSmall?.copyWith(
              color: colors.deepNavy,
              fontWeight: FontWeight.w800,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Manage the password and device passkeys that can bring you back into Conscia.',
            style: textTheme.bodyMedium?.copyWith(
              color: colors.ink,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _PasswordSheet extends ConsumerStatefulWidget {
  const _PasswordSheet({required this.hasPassword});

  final bool hasPassword;

  @override
  ConsumerState<_PasswordSheet> createState() => _PasswordSheetState();
}

class _PasswordSheetState extends ConsumerState<_PasswordSheet> {
  final _currentPasswordController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isSaving = false;
  String? _currentPasswordError;
  String? _passwordError;
  String? _confirmPasswordError;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateConfirmPassword(String value) {
    if (value != _passwordController.text) return 'Passwords do not match';
    return null;
  }

  void _clearErrors() {
    if (_currentPasswordError != null ||
        _passwordError != null ||
        _confirmPasswordError != null) {
      setState(() {
        _currentPasswordError = null;
        _passwordError = null;
        _confirmPasswordError = null;
      });
    }
  }

  Future<void> _savePassword() async {
    final currentPasswordError =
        widget.hasPassword && _currentPasswordController.text.isEmpty
            ? 'Current password is required'
            : null;
    final passwordError = validatePasswordForCognito(
      _passwordController.text,
    );
    final confirmError =
        _validateConfirmPassword(_confirmPasswordController.text);
    if (currentPasswordError != null ||
        passwordError != null ||
        confirmError != null) {
      setState(() {
        _currentPasswordError = currentPasswordError;
        _passwordError = passwordError;
        _confirmPasswordError = confirmError;
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _currentPasswordError = null;
      _passwordError = null;
      _confirmPasswordError = null;
    });

    try {
      await ref.read(authServiceProvider).setPassword(
            _passwordController.text,
            currentPassword:
                widget.hasPassword ? _currentPasswordController.text : null,
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e, s) {
      if (!mounted) return;
      final error = AppError.from(e, stackTrace: s);
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(error.userMessage)));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;

    return ConsciaBottomSheetScaffold(
      title: widget.hasPassword ? 'Change password' : 'Add password',
      subtitle: widget.hasPassword
          ? 'Enter your current password, then choose a new one.'
          : 'Choose the password this signed-in account should use for email sign-in.',
      footer: SizedBox(
        height: 48,
        child: FilledButton(
          onPressed: _isSaving ? null : _savePassword,
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save password'),
        ),
      ),
      child: Column(
        children: [
          if (widget.hasPassword) ...[
            FloatingLabelTextField(
              controller: _currentPasswordController,
              label: 'Current password',
              prefix: AppIcons.icon(
                AppIconKey.password,
                color: colors.mutedInk,
                size: 20,
              ),
              obscureText: _obscureCurrent,
              textInputAction: TextInputAction.next,
              onChanged: (_) => _clearErrors(),
              errorText: _currentPasswordError,
              enableSuggestions: false,
              autocorrect: false,
              trailing: IconButton(
                icon: AppIcons.icon(
                  _obscureCurrent
                      ? AppIconKey.visibility
                      : AppIconKey.visibilityOff,
                  color: _obscureCurrent ? colors.mutedInk : colors.deepNavy,
                ),
                onPressed: () => setState(
                  () => _obscureCurrent = !_obscureCurrent,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          FloatingLabelTextField(
            controller: _passwordController,
            label: 'New password',
            prefix: AppIcons.icon(
              AppIconKey.password,
              color: colors.mutedInk,
              size: 20,
            ),
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.next,
            onChanged: (_) => _clearErrors(),
            errorText: _passwordError,
            enableSuggestions: false,
            autocorrect: false,
            trailing: IconButton(
              icon: AppIcons.icon(
                _obscurePassword
                    ? AppIconKey.visibility
                    : AppIconKey.visibilityOff,
                color: _obscurePassword ? colors.mutedInk : colors.deepNavy,
              ),
              onPressed: () => setState(
                () => _obscurePassword = !_obscurePassword,
              ),
            ),
          ),
          const SizedBox(height: 12),
          FloatingLabelTextField(
            controller: _confirmPasswordController,
            label: 'Confirm password',
            prefix: AppIcons.icon(
              AppIconKey.password,
              color: colors.mutedInk,
              size: 20,
            ),
            obscureText: _obscureConfirm,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _savePassword(),
            onChanged: (_) => _clearErrors(),
            errorText: _confirmPasswordError,
            enableSuggestions: false,
            autocorrect: false,
            trailing: IconButton(
              icon: AppIcons.icon(
                _obscureConfirm
                    ? AppIconKey.visibility
                    : AppIconKey.visibilityOff,
                color: _obscureConfirm ? colors.mutedInk : colors.deepNavy,
              ),
              onPressed: () => setState(
                () => _obscureConfirm = !_obscureConfirm,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SecurityMethodRow extends StatelessWidget {
  const _SecurityMethodRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final AppIconKey icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.surfaceRaised,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              _SecurityIconBox(icon: icon),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.mutedInk,
                            height: 1.25,
                          ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                AppIcons.icon(
                  AppIconKey.chevronRight,
                  color: colors.border,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecuritySwitchRow extends StatelessWidget {
  const _SecuritySwitchRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final AppIconKey icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          _SecurityIconBox(icon: icon),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.mutedInk,
                        height: 1.25,
                      ),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _SecurityIconBox extends StatelessWidget {
  const _SecurityIconBox({required this.icon});

  final AppIconKey icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.navySoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: SizedBox(
        width: 46,
        height: 46,
        child: Center(
          child: AppIcons.icon(
            icon,
            color: colors.deepNavy,
            size: 24,
          ),
        ),
      ),
    );
  }
}
