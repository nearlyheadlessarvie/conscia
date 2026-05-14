import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/api_constants.dart';
import '../../core/constants/app_icons.dart';
import '../../core/errors/app_error.dart';
import '../../core/routing/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/floating_label_text_field.dart';
import '../../widgets/conscia_app_bar.dart';
import '../../widgets/inline_notice.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  static const _resendCooldown = Duration(minutes: 1);

  final _codeController = TextEditingController();
  bool _isSubmitting = false;
  bool _isResending = false;
  int _resendCooldownSeconds = 0;
  Timer? _resendCooldownTimer;
  String? _message;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startInitialResendCooldown();
  }

  @override
  void dispose() {
    _resendCooldownTimer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() => _errorMessage = 'Enter the verification code');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
      _message = null;
    });

    try {
      await ref.read(authProvider.notifier).confirmRegistration(code);
      final defaults = deviceDefaults();
      try {
        await ref.read(userServiceProvider).updateProfile(
              preferredCurrency: defaults.currency,
              locale: defaults.locale,
            );
      } catch (_) {}
    } catch (e, s) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = AppError.from(e, stackTrace: s).userMessage;
      });
      return;
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);
    context.go(AppRoutes.setup);
  }

  Future<void> _resend() async {
    if (_isResending || _resendCooldownSeconds > 0) return;

    setState(() {
      _isResending = true;
      _errorMessage = null;
      _message = null;
    });

    try {
      await ref.read(authProvider.notifier).resendConfirmation();
    } catch (e, s) {
      if (!mounted) return;
      setState(() {
        _isResending = false;
        _errorMessage = AppError.from(e, stackTrace: s).userMessage;
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _isResending = false;
      _startResendCooldown(_resendCooldown);
      _message = 'A fresh code is on its way.';
    });
  }

  void _returnToSignIn() {
    ref.read(authProvider.notifier).cancelPendingConfirmation();
    context.go(AppRoutes.signIn);
  }

  Future<void> _startInitialResendCooldown() async {
    final remaining = await ref
        .read(authProvider.notifier)
        .confirmationResendCooldownRemaining();
    if (!mounted) return;
    setState(() {
      _startResendCooldown(
        remaining > Duration.zero ? remaining : _resendCooldown,
      );
    });
  }

  void _startResendCooldown(Duration cooldown) {
    _resendCooldownTimer?.cancel();
    _resendCooldownSeconds = cooldown.inSeconds.clamp(
      0,
      _resendCooldown.inSeconds,
    );
    _resendCooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _resendCooldownSeconds -= 1;
        if (_resendCooldownSeconds <= 0) {
          _resendCooldownSeconds = 0;
          timer.cancel();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final pendingEmail = ref.watch(authProvider).pendingEmail ?? 'your email';

    return Scaffold(
      appBar: ConsciaAppBar(
        leading: IconButton(
          tooltip: 'Back',
          icon: Icon(AppIcons.chevronLeft),
          onPressed: _returnToSignIn,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Text(
                'Verify your email',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'We sent a confirmation code to $pendingEmail.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
              ),
              if (ApiConstants.useMockAuth) ...[
                const SizedBox(height: 12),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.secondaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.code,
                          size: 18,
                          color: colors.onSecondaryContainer,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Local dev: no email was sent. Enter any code to continue.',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: colors.onSecondaryContainer,
                                      fontWeight: FontWeight.w600,
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 32),
              if (_errorMessage != null) ...[
                InlineNotice(
                  message: _errorMessage!,
                  tone: InlineNoticeTone.error,
                  icon: const Icon(Icons.lock_outline_rounded),
                ),
                const SizedBox(height: 16),
              ],
              if (_message != null) ...[
                InlineNotice(
                  message: _message!,
                  tone: InlineNoticeTone.info,
                  icon: const Icon(Icons.mark_email_read_outlined),
                ),
                const SizedBox(height: 16),
              ],
              FloatingLabelTextField(
                controller: _codeController,
                label: 'Verification code',
                prefix: const Icon(Icons.verified_user_outlined),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.oneTimeCode],
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                counterText: '',
                onChanged: (_) {
                  if (_errorMessage != null) {
                    setState(() => _errorMessage = null);
                  }
                },
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 48,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  onPressed: _isSubmitting ? null : _confirm,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Verify and continue'),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed:
                    _isResending || _resendCooldownSeconds > 0 ? null : _resend,
                child: Text(
                  _resendButtonLabel,
                ),
              ),
              TextButton(
                onPressed: _returnToSignIn,
                child: const Text('Back to sign in'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _resendButtonLabel {
    if (_isResending) return 'Sending...';
    if (_resendCooldownSeconds > 0) {
      return 'Resend in ${_resendCooldownSeconds}s';
    }
    return 'Resend code';
  }
}
