import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_icons.dart';
import '../../core/errors/app_error.dart';
import '../../core/utils/email_validator.dart';
import '../../core/utils/password_policy.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/floating_label_text_field.dart';
import '../../widgets/conscia_app_bar.dart';
import '../../widgets/inline_notice.dart';
import 'widgets/auth_intro_panel.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _errorMessage;
  String? _emailFieldError;
  String? _passwordFieldError;
  String? _confirmPasswordFieldError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Email is required';
    if (!isValidEmailAddress(value)) return 'Enter a valid email';
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value != _passwordController.text) return 'Passwords do not match';
    return null;
  }

  void _clearInlineErrors() {
    if (_errorMessage != null ||
        _emailFieldError != null ||
        _passwordFieldError != null ||
        _confirmPasswordFieldError != null) {
      setState(() {
        _errorMessage = null;
        _emailFieldError = null;
        _passwordFieldError = null;
        _confirmPasswordFieldError = null;
      });
    }
  }

  Future<void> _submit() async {
    final emailError = _validateEmail(_emailController.text.trim());
    final passwordError = validatePasswordForCognito(
      _passwordController.text,
    );
    final confirmPasswordError =
        _validateConfirmPassword(_confirmPasswordController.text);
    if (emailError != null ||
        passwordError != null ||
        confirmPasswordError != null) {
      setState(() {
        _emailFieldError = emailError;
        _passwordFieldError = passwordError;
        _confirmPasswordFieldError = confirmPasswordError;
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _emailFieldError = null;
      _passwordFieldError = null;
      _confirmPasswordFieldError = null;
    });

    try {
      await ref.read(authProvider.notifier).register(
            _emailController.text.trim(),
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
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const ConsciaAppBar(
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
              const AuthIntroPanel(
                title: 'Start with clarity',
                subtitle:
                    'Build a calmer relationship with spending, one small check-in at a time.',
                icon: AppIconKey.sprout,
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
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          FloatingLabelTextField(
                            controller: _emailController,
                            label: 'Email',
                            prefix: AppIcons.icon(
                              AppIconKey.email,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              size: 20,
                            ),
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            onChanged: (_) => _clearInlineErrors(),
                            errorText: _emailFieldError,
                            autofillHints: const [AutofillHints.email],
                          ),
                          const SizedBox(height: 16),
                          FloatingLabelTextField(
                            controller: _passwordController,
                            label: 'Password',
                            prefix: AppIcons.icon(
                              AppIconKey.password,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
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
                                    ? Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant
                                    : Theme.of(context).colorScheme.primary,
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
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
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
                                    ? Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant
                                    : Theme.of(context).colorScheme.primary,
                              ),
                              onPressed: () => setState(
                                () => _obscureConfirm = !_obscureConfirm,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      height: 48,
                      child: FilledButton(
                        onPressed: _isLoading ? null : _submit,
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Create Account'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: TextButton(
                        onPressed: () => context.go('/onboarding/sign-in'),
                        child: const Text('Already have an account? Sign In'),
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
