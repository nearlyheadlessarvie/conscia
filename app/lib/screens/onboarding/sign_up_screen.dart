import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/app_error.dart';
import '../../core/utils/email_validator.dart';
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
    final passwordError = _validatePassword(_passwordController.text);
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
    return Scaffold(
      appBar: const ConsciaAppBar(
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
              const AuthIntroPanel(
                title: 'Create Account',
                subtitle: 'Start a calmer, clearer financial journey.',
                icon: Icons.local_florist_outlined,
              ),
              const SizedBox(height: 28),
              if (_errorMessage != null) ...[
                InlineNotice(
                  message: _errorMessage!,
                  tone: InlineNoticeTone.error,
                  icon: const Icon(Icons.lock_outline_rounded),
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
                      prefix: const Icon(Icons.email_outlined),
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
                      prefix: const Icon(Icons.lock_outline),
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.next,
                      onChanged: (_) => _clearInlineErrors(),
                      errorText: _passwordFieldError,
                      enableSuggestions: false,
                      autocorrect: false,
                      trailing: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: _obscurePassword
                              ? Theme.of(context).colorScheme.onSurfaceVariant
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
                      prefix: const Icon(Icons.lock_outline),
                      obscureText: _obscureConfirm,
                      textInputAction: TextInputAction.done,
                      onChanged: (_) => _clearInlineErrors(),
                      errorText: _confirmPasswordFieldError,
                      enableSuggestions: false,
                      autocorrect: false,
                      trailing: IconButton(
                        icon: Icon(
                          _obscureConfirm
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: _obscureConfirm
                              ? Theme.of(context).colorScheme.onSurfaceVariant
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
                          child: CircularProgressIndicator(strokeWidth: 2),
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
      ),
    );
  }
}
