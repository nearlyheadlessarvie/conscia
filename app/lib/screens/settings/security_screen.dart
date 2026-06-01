import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

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
import '../../widgets/conscia_confirm_sheet.dart';
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
    final currentCredentialId = currentEmail == null
        ? null
        : passkeyPreference.credentialIdForEmail(currentEmail);
    final hasRegisteredCurrentPasskey =
        currentCredentialId != null && currentCredentialId.isNotEmpty;
    final canUsePasskeys = passkeysAvailable && sessionSupportsPasskeys;
    final canManagePasskeys = currentEmail != null &&
        currentEmail.trim().isNotEmpty &&
        sessionSupportsPasskeys;

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
                                ? null
                                : _registerPasskey
                            : null,
                      ),
                      if (canManagePasskeys) ...[
                        const SizedBox(height: 10),
                        _SecurityMethodRow(
                          icon: AppIconKey.passkey,
                          title: 'Manage Passkeys',
                          subtitle: 'View and remove passkeys for this account',
                          onTap: () => _showPasskeySheet(currentEmail),
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

  Future<void> _deleteCredential(
    PasskeyCredential credential, {
    required bool isThisDevice,
  }) async {
    final confirmed = await ConsciaConfirmSheet.show(
      context,
      title: isThisDevice ? 'Forget this passkey?' : 'Remove this passkey?',
      message: isThisDevice
          ? 'This removes the device passkey from your account.\n${passkeyDeviceRemovalInstructions()}'
          : 'This removes the passkey from your account.\nIf it still exists on another device, remove it from that device\'s password manager too.',
      confirmLabel: isThisDevice ? 'Forget' : 'Remove',
    );
    if (!confirmed || !mounted) return;

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
          isThisDevice ||
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
        _error = friendlyPasskeyErrorMessage(
          error,
          operation: PasskeyOperation.delete,
        );
        _deletingCredentialId = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final localCredentialId =
        ref.watch(passkeySignInPreferenceProvider).credentialIdForEmail(
              widget.email,
            );
    final thisDeviceCredentials = _credentials
        .where((credential) => credential.credentialId == localCredentialId)
        .toList(growable: false);
    final otherCredentials = _credentials
        .where((credential) => credential.credentialId != localCredentialId)
        .toList(growable: false);

    return ConsciaBottomSheetScaffold(
      title: 'Manage passkeys',
      subtitle: 'View and remove passkeys for this account',
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
            const _PasskeyEmptyState()
          else ...[
            if (thisDeviceCredentials.isNotEmpty) ...[
              const _PasskeySectionTitle('This device'),
              const SizedBox(height: 10),
              for (final credential in thisDeviceCredentials) ...[
                _PasskeyCredentialRow(
                  credential: credential,
                  actionLabel: 'Forget',
                  isDeleting: _deletingCredentialId == credential.credentialId,
                  onRemove: () => _deleteCredential(
                    credential,
                    isThisDevice: true,
                  ),
                ),
                const SizedBox(height: 10),
              ],
              if (otherCredentials.isNotEmpty) const SizedBox(height: 8),
            ],
            if (otherCredentials.isNotEmpty) ...[
              const _PasskeySectionTitle('Other account passkeys'),
              const SizedBox(height: 10),
              for (final credential in otherCredentials) ...[
                _PasskeyCredentialRow(
                  credential: credential,
                  actionLabel: 'Remove',
                  isDeleting: _deletingCredentialId == credential.credentialId,
                  onRemove: () => _deleteCredential(
                    credential,
                    isThisDevice: false,
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ],
          ],
        ],
      ),
    );
  }
}

class _PasskeySectionTitle extends StatelessWidget {
  const _PasskeySectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Theme.of(context).appColors.deepNavy,
            fontWeight: FontWeight.w800,
          ),
    );
  }
}

class _PasskeyEmptyState extends StatelessWidget {
  const _PasskeyEmptyState();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          AppIcons.icon(
            AppIconKey.passkey,
            color: colors.mutedInk,
            size: 32,
          ),
          const SizedBox(height: 10),
          Text(
            'No account passkeys',
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Set up a passkey on this device to use device unlock next time.',
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(
              color: colors.mutedInk,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _PasskeyCredentialRow extends StatefulWidget {
  const _PasskeyCredentialRow({
    required this.credential,
    required this.actionLabel,
    required this.isDeleting,
    required this.onRemove,
  });

  final PasskeyCredential credential;
  final String actionLabel;
  final bool isDeleting;
  final VoidCallback onRemove;

  @override
  State<_PasskeyCredentialRow> createState() => _PasskeyCredentialRowState();
}

class _PasskeyCredentialRowState extends State<_PasskeyCredentialRow>
    with SingleTickerProviderStateMixin {
  static const _commitThreshold = 0.58;

  late final SlidableController _controller;
  bool _handlingCommittedSwipe = false;

  @override
  void initState() {
    super.initState();
    _controller = SlidableController(this)
      ..endGesture.addListener(_handleCommittedSwipe);
  }

  @override
  void dispose() {
    _controller.endGesture.removeListener(_handleCommittedSwipe);
    _controller.dispose();
    super.dispose();
  }

  void _handleCommittedSwipe() {
    if (_handlingCommittedSwipe || _controller.ratio > -_commitThreshold) {
      return;
    }

    _handlingCommittedSwipe = true;
    _controller.close(duration: Duration.zero);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _handlingCommittedSwipe = false;
      widget.onRemove();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final radius = BorderRadius.circular(18);

    if (widget.isDeleting) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surfaceRaised,
          borderRadius: radius,
          border: Border.all(color: colors.border),
        ),
        child: _PasskeyCredentialRowContent(
          credential: widget.credential,
          trailing: const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: radius,
      child: Slidable(
        key: ValueKey('passkey-row-${widget.credential.credentialId}'),
        controller: _controller,
        groupTag: 'passkeys',
        closeOnScroll: true,
        endActionPane: ActionPane(
          motion: const BehindMotion(),
          extentRatio: 0.24,
          dismissible: _PasskeySlidablePreview(
            label: widget.actionLabel,
            icon: AppIconKey.delete,
            foregroundColor: colors.expense,
            backgroundColor: colors.expenseSoft,
            alignment: Alignment.centerRight,
          ),
          children: [
            _PasskeySlidableAction(
              label: widget.actionLabel,
              icon: AppIconKey.delete,
              foregroundColor: colors.expense,
              backgroundColor: colors.expenseSoft,
              onPressed: widget.onRemove,
            ),
          ],
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surfaceRaised,
            borderRadius: radius,
            border: Border.all(color: colors.border),
          ),
          child: _PasskeyCredentialRowContent(credential: widget.credential),
        ),
      ),
    );
  }
}

class _PasskeyCredentialRowContent extends StatelessWidget {
  const _PasskeyCredentialRowContent({
    required this.credential,
    this.trailing,
  });

  final PasskeyCredential credential;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final title = credential.friendlyName?.trim().isNotEmpty == true
        ? credential.friendlyName!.trim()
        : 'Passkey';

    return Padding(
      padding: const EdgeInsets.all(14),
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
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _PasskeySlidablePreview extends StatelessWidget {
  const _PasskeySlidablePreview({
    required this.label,
    required this.icon,
    required this.foregroundColor,
    required this.backgroundColor,
    required this.alignment,
  });

  final String label;
  final AppIconKey icon;
  final Color foregroundColor;
  final Color backgroundColor;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;

    return ColoredBox(
      color: backgroundColor.withValues(alpha: 0.38),
      child: Align(
        alignment: alignment,
        child: SizedBox(
          width: 92,
          height: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppIcons.icon(
                icon,
                color: foregroundColor,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colors.ink,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PasskeySlidableAction extends StatelessWidget {
  const _PasskeySlidableAction({
    required this.label,
    required this.icon,
    required this.foregroundColor,
    required this.backgroundColor,
    required this.onPressed,
  });

  final String label;
  final AppIconKey icon;
  final Color foregroundColor;
  final Color backgroundColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;

    return CustomSlidableAction(
      key: ValueKey('swipe-action-tile-$label'),
      backgroundColor: backgroundColor.withValues(alpha: 0.38),
      padding: EdgeInsets.zero,
      onPressed: (_) => onPressed(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppIcons.icon(
            icon,
            color: foregroundColor,
            size: 20,
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.ink,
                    fontWeight: FontWeight.w800,
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
