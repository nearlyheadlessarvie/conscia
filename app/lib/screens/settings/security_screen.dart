import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_icons.dart';
import '../../core/errors/app_error.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_layout.dart';
import '../../core/utils/password_policy.dart';
import '../../providers/passkey_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/account_password_service.dart';
import '../../services/passkey_service.dart';
import '../../widgets/conscia_app_bar.dart';
import '../../widgets/conscia_bottom_sheet.dart';
import '../../widgets/editorial_section_header.dart';
import '../../widgets/floating_label_text_field.dart';
import '../../widgets/inline_notice.dart';

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
      await Future<void>.delayed(const Duration(milliseconds: 250));
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text('Password updated.'),
          ),
        );
    }
  }

  Future<void> _registerPasskey() async {
    if (_isRegisteringPasskey) return;

    setState(() => _isRegisteringPasskey = true);
    try {
      final credentialId =
          await ref.read(passkeyServiceProvider).registerCurrentUserPasskey();
      final email = ref.read(currentSessionUserProvider)?.email;
      if (email != null && email.trim().isNotEmpty) {
        final notifier = ref.read(passkeySignInPreferenceProvider.notifier);
        await notifier.registerCredential(email, credentialId);
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
            SnackBar(
              content: Text(
                friendlyPasskeyErrorMessage(
                  error,
                  operation: PasskeyOperation.register,
                ),
              ),
            ),
          );
      }
    } finally {
      if (mounted) {
        setState(() => _isRegisteringPasskey = false);
      }
    }
  }

  Future<void> _showPasskeySheet(String email) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).appColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => _PasskeyManagementSheet(email: email),
    );
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
    final currentUser = ref.watch(currentSessionUserProvider);
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
                            'Use device unlock for faster sign-in when this session supports passkeys.',
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
                            ? hasRegisteredCurrentPasskey
                                ? () => _showPasskeySheet(currentEmail)
                                : _registerPasskey
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
  String? _formError;

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
        _confirmPasswordError != null ||
        _formError != null) {
      setState(() {
        _currentPasswordError = null;
        _passwordError = null;
        _confirmPasswordError = null;
        _formError = null;
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
      _formError = null;
    });

    try {
      await ref.read(accountPasswordServiceProvider).setPassword(
            _passwordController.text,
            currentPassword:
                widget.hasPassword ? _currentPasswordController.text : null,
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e, s) {
      if (!mounted) return;
      final error = AppError.from(e, stackTrace: s);
      setState(() => _formError = error.userMessage);
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
          if (_formError != null) ...[
            InlineNotice(
              message: _formError!,
              tone: InlineNoticeTone.error,
              icon: AppIcons.icon(
                AppIconKey.lock,
                color: Theme.of(context).colorScheme.error,
                size: 16,
              ),
            ),
            const SizedBox(height: 12),
          ],
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

class _PasskeyManagementSheet extends ConsumerStatefulWidget {
  const _PasskeyManagementSheet({required this.email});

  final String email;

  @override
  ConsumerState<_PasskeyManagementSheet> createState() =>
      _PasskeyManagementSheetState();
}

class _PasskeyManagementSheetState
    extends ConsumerState<_PasskeyManagementSheet> {
  bool _isLoading = true;
  String? _deletingCredentialId;
  bool _isForgettingThisDevice = false;
  String? _error;
  List<PasskeyCredential> _credentials = const [];

  @override
  void initState() {
    super.initState();
    unawaited(_loadCredentials());
  }

  Future<void> _loadCredentials() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final credentials =
          await ref.read(passkeyServiceProvider).listCurrentUserPasskeys();
      if (!mounted) return;
      setState(() {
        _credentials = credentials;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = AppError.from(error, log: false).userMessage;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteCredential(PasskeyCredential credential) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove this passkey?'),
        content: const Text(
          'This removes the selected passkey from your Conscia account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _deletingCredentialId = credential.credentialId;
      _error = null;
    });

    try {
      await ref
          .read(passkeyServiceProvider)
          .deleteCurrentUserPasskey(credential.credentialId);
      final nextCredentials =
          await ref.read(passkeyServiceProvider).listCurrentUserPasskeys();
      final localCredentialId = ref
          .read(passkeySignInPreferenceProvider)
          .credentialIdForEmail(widget.email);
      if (nextCredentials.isEmpty ||
          localCredentialId == credential.credentialId) {
        await ref
            .read(passkeySignInPreferenceProvider.notifier)
            .forgetEmail(widget.email);
      }
      if (!mounted) return;
      setState(() {
        _credentials = nextCredentials;
        _deletingCredentialId = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = AppError.from(error, log: false).userMessage;
        _deletingCredentialId = null;
      });
    }
  }

  Future<void> _forgetThisDevice() async {
    final credentialId = ref
        .read(passkeySignInPreferenceProvider)
        .credentialIdForEmail(widget.email);
    if (credentialId == null || credentialId.isEmpty) {
      setState(() {
        _error =
            'This app cannot match the saved passkey for this device yet. Remove the matching account passkey above, then remove the saved passkey from this device.';
      });
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Forget this device?'),
        content: const Text(
          'This removes this device passkey from your Conscia account and clears passkey-first sign-in here. You still need to remove the saved passkey from this device too.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Forget device'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _isForgettingThisDevice = true;
      _deletingCredentialId = credentialId;
      _error = null;
    });

    try {
      await ref
          .read(passkeyServiceProvider)
          .deleteCurrentUserPasskey(credentialId);
      final nextCredentials =
          await ref.read(passkeyServiceProvider).listCurrentUserPasskeys();
      await ref
          .read(passkeySignInPreferenceProvider.notifier)
          .forgetEmail(widget.email);
      if (!mounted) return;
      setState(() {
        _credentials = nextCredentials;
        _isForgettingThisDevice = false;
        _deletingCredentialId = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = AppError.from(error, log: false).userMessage;
        _isForgettingThisDevice = false;
        _deletingCredentialId = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConsciaBottomSheetScaffold(
      title: 'Manage passkeys',
      subtitle:
          'Remove account passkeys, then clear the matching saved passkey from your device too.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_error != null) ...[
            InlineNotice(
              message: _error!,
              tone: InlineNoticeTone.error,
              icon: AppIcons.icon(
                AppIconKey.lock,
                color: Theme.of(context).colorScheme.error,
                size: 16,
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_credentials.isEmpty)
            Text(
              'No account passkeys are registered for this account.',
              style: Theme.of(context).textTheme.bodyMedium,
            )
          else ...[
            for (final credential in _credentials) ...[
              _PasskeyCredentialRow(
                credential: credential,
                isDeleting: _isForgettingThisDevice ||
                    _deletingCredentialId == credential.credentialId,
                onRemove: () => _deleteCredential(credential),
              ),
              const SizedBox(height: 10),
            ],
          ],
          InlineNotice(
            message: passkeyDeviceRemovalInstructions(),
            tone: InlineNoticeTone.info,
            icon: AppIcons.icon(
              AppIconKey.passkey,
              color: Theme.of(context).appColors.angelAccent,
              size: 16,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _isForgettingThisDevice ? null : _forgetThisDevice,
            child: Text(
              _isForgettingThisDevice
                  ? 'Forgetting this device...'
                  : 'Forget this device',
            ),
          ),
        ],
      ),
    );
  }
}

class _PasskeyCredentialRow extends StatelessWidget {
  const _PasskeyCredentialRow({
    required this.credential,
    required this.isDeleting,
    required this.onRemove,
  });

  final PasskeyCredential credential;
  final bool isDeleting;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final title = credential.friendlyName?.trim().isNotEmpty == true
        ? credential.friendlyName!.trim()
        : 'Passkey';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          const _SecurityIconBox(icon: AppIconKey.passkey),
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
                if (credential.relyingPartyId != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    credential.relyingPartyId!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.mutedInk,
                        ),
                  ),
                ],
              ],
            ),
          ),
          TextButton(
            onPressed: isDeleting ? null : onRemove,
            child: Text(isDeleting ? 'Removing...' : 'Remove'),
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
