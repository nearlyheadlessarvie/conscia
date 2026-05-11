import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/routing/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';

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
    _startResendCooldown();
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
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = e.toString();
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
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isResending = false;
        _errorMessage = e.toString();
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _isResending = false;
      _startResendCooldown();
      _message = 'A fresh code is on its way.';
    });
  }

  void _returnToSignIn() {
    ref.read(authProvider.notifier).cancelPendingConfirmation();
    context.go(AppRoutes.signIn);
  }

  void _startResendCooldown() {
    _resendCooldownTimer?.cancel();
    _resendCooldownSeconds = _resendCooldown.inSeconds;
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
      appBar: AppBar(
        leading: BackButton(onPressed: _returnToSignIn),
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
              const SizedBox(height: 32),
              if (_errorMessage != null) ...[
                MaterialBanner(
                  content: Text(_errorMessage!),
                  backgroundColor: colors.errorContainer,
                  leading: Icon(Icons.error, color: colors.error),
                  actions: [
                    TextButton(
                      onPressed: () => setState(() => _errorMessage = null),
                      child: const Text('Dismiss'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              if (_message != null) ...[
                MaterialBanner(
                  content: Text(_message!),
                  backgroundColor: colors.secondaryContainer,
                  leading: Icon(Icons.mark_email_read_outlined,
                      color: colors.secondary),
                  actions: [
                    TextButton(
                      onPressed: () => setState(() => _message = null),
                      child: const Text('Dismiss'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.oneTimeCode],
                maxLength: 6,
                onSubmitted: (_) => _confirm(),
                decoration: const InputDecoration(
                  labelText: 'Verification code',
                  prefixIcon: Icon(Icons.verified_user_outlined),
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
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
