import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_icons.dart';
import '../../core/errors/app_error.dart';
import '../../core/routing/app_router.dart';
import '../../core/utils/email_validator.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/conscia_app_bar.dart';
import '../../widgets/floating_label_text_field.dart';
import '../../widgets/inline_notice.dart';
import 'widgets/auth_intro_panel.dart';

class PasswordResetScreen extends ConsumerStatefulWidget {
  const PasswordResetScreen({super.key});

  @override
  ConsumerState<PasswordResetScreen> createState() =>
      _PasswordResetScreenState();
}

class _PasswordResetScreenState extends ConsumerState<PasswordResetScreen> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _codeSent = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _message;
  String? _errorMessage;
  String? _emailFieldError;
  String? _codeFieldError;
  String? _passwordFieldError;
  String? _confirmPasswordFieldError;

  @override
  void initState() {
    super.initState();
    _loadLastEmail();
  }

  Future<void> _loadLastEmail() async {
    final email = await getLastEmail();
    if (email != null && email.isNotEmpty && mounted) {
      setState(() => _emailController.text = email);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Email is required';
    if (!isValidEmailAddress(value)) return 'Enter a valid email';
    return null;
  }

  String? _validateCode(String? value) {
    if (value == null || value.isEmpty) return 'Code is required';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'At least 8 characters';
    if (!RegExp(r'[A-Z]').hasMatch(value)) return 'Include 1 uppercase letter';
    if (!RegExp(r'[0-9]').hasMatch(value)) return 'Include 1 number';
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value != _passwordController.text) return 'Passwords do not match';
    return null;
  }

  void _clearInlineErrors() {
    if (_errorMessage != null ||
        _emailFieldError != null ||
        _codeFieldError != null ||
        _passwordFieldError != null ||
        _confirmPasswordFieldError != null) {
      setState(() {
        _errorMessage = null;
        _emailFieldError = null;
        _codeFieldError = null;
        _passwordFieldError = null;
        _confirmPasswordFieldError = null;
      });
    }
  }

  Future<void> _sendCode() async {
    final emailError = _validateEmail(_emailController.text.trim());
    if (emailError != null) {
      setState(() {
        _emailFieldError = emailError;
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _message = null;
      _errorMessage = null;
      _emailFieldError = null;
    });

    try {
      await ref
          .read(authProvider.notifier)
          .startPasswordReset(_emailController.text.trim());
    } catch (e, s) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = AppError.from(e, stackTrace: s).userMessage;
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _codeSent = true;
      _message = 'A reset code is on its way.';
    });
  }

  Future<void> _resetPassword() async {
    final codeError = _validateCode(_codeController.text.trim());
    final passwordError = _validatePassword(_passwordController.text);
    final confirmError =
        _validateConfirmPassword(_confirmPasswordController.text);
    if (codeError != null || passwordError != null || confirmError != null) {
      setState(() {
        _codeFieldError = codeError;
        _passwordFieldError = passwordError;
        _confirmPasswordFieldError = confirmError;
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _message = null;
      _errorMessage = null;
      _codeFieldError = null;
      _passwordFieldError = null;
      _confirmPasswordFieldError = null;
    });

    try {
      await ref.read(authProvider.notifier).confirmPasswordReset(
            _emailController.text.trim(),
            _codeController.text.trim(),
            _passwordController.text,
          );
    } catch (e, s) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = AppError.from(e, stackTrace: s).userMessage;
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _message = 'Password reset. Signing you in...';
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: ConsciaAppBar(
        leading: IconButton(
          tooltip: 'Back',
          icon: AppIcons.icon(
            AppIconKey.chevronLeft,
            color: colors.onSurface,
            size: 20,
          ),
          onPressed: () => context.go(AppRoutes.signIn),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colors.primaryContainer.withValues(alpha: 0.18),
              colors.surface,
            ],
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthIntroPanel(
                title: 'Reset your password',
                subtitle: _codeSent
                    ? 'Enter the code we sent and choose a fresh password.'
                    : 'We will send a short reset code to your email.',
                icon: AppIconKey.lock,
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  28,
                  20,
                  32 + MediaQuery.paddingOf(context).bottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_errorMessage != null) ...[
                      InlineNotice(
                        message: _errorMessage!,
                        tone: InlineNoticeTone.error,
                        icon: AppIcons.icon(
                          AppIconKey.lock,
                          color: colors.error,
                          size: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (_message != null) ...[
                      InlineNotice(
                        message: _message!,
                        tone: InlineNoticeTone.info,
                        icon: AppIcons.icon(
                          AppIconKey.email,
                          color: colors.primary,
                          size: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (!_codeSent) ...[
                      FloatingLabelTextField(
                        controller: _emailController,
                        label: 'Email',
                        prefix: AppIcons.icon(
                          AppIconKey.email,
                          color: colors.onSurfaceVariant,
                          size: 20,
                        ),
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                        onChanged: (_) => _clearInlineErrors(),
                        errorText: _emailFieldError,
                        autofillHints: const [AutofillHints.email],
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        height: 48,
                        child: FilledButton(
                          onPressed: _isLoading ? null : _sendCode,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Send reset code'),
                        ),
                      ),
                    ] else ...[
                      FloatingLabelTextField(
                        controller: _codeController,
                        label: 'Verification code',
                        prefix: AppIcons.icon(
                          AppIconKey.verified,
                          color: colors.onSurfaceVariant,
                          size: 20,
                        ),
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        maxLength: 6,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        counterText: '',
                        onChanged: (_) => _clearInlineErrors(),
                        errorText: _codeFieldError,
                        autofillHints: const [AutofillHints.oneTimeCode],
                      ),
                      const SizedBox(height: 16),
                      FloatingLabelTextField(
                        controller: _passwordController,
                        label: 'New password',
                        prefix: AppIcons.icon(
                          AppIconKey.password,
                          color: colors.onSurfaceVariant,
                          size: 20,
                        ),
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.next,
                        onChanged: (_) => _clearInlineErrors(),
                        errorText: _passwordFieldError,
                        enableSuggestions: false,
                        autocorrect: false,
                        trailing: IconButton(
                          icon: AppIcons.icon(
                            _obscurePassword
                                ? AppIconKey.visibility
                                : AppIconKey.visibilityOff,
                            color: _obscurePassword
                                ? colors.onSurfaceVariant
                                : colors.primary,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      FloatingLabelTextField(
                        controller: _confirmPasswordController,
                        label: 'Confirm Password',
                        prefix: AppIcons.icon(
                          AppIconKey.password,
                          color: colors.onSurfaceVariant,
                          size: 20,
                        ),
                        obscureText: _obscureConfirm,
                        textInputAction: TextInputAction.done,
                        onChanged: (_) => _clearInlineErrors(),
                        errorText: _confirmPasswordFieldError,
                        enableSuggestions: false,
                        autocorrect: false,
                        trailing: IconButton(
                          icon: AppIcons.icon(
                            _obscureConfirm
                                ? AppIconKey.visibility
                                : AppIconKey.visibilityOff,
                            color: _obscureConfirm
                                ? colors.onSurfaceVariant
                                : colors.primary,
                          ),
                          onPressed: () => setState(
                            () => _obscureConfirm = !_obscureConfirm,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        height: 48,
                        child: FilledButton(
                          onPressed: _isLoading ? null : _resetPassword,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Reset password'),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Center(
                      child: TextButton(
                        onPressed: _isLoading
                            ? null
                            : () => context.go(AppRoutes.signIn),
                        child: const Text('Back to sign in'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
