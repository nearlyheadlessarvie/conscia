import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_icons.dart';
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

  bool _isLoading = false;
  String? _errorMessage;
  String? _emailFieldError;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Email is required';
    if (!isValidEmailAddress(value)) return 'Enter a valid email';
    return null;
  }

  void _clearInlineErrors() {
    if (_errorMessage != null || _emailFieldError != null) {
      setState(() {
        _errorMessage = null;
        _emailFieldError = null;
      });
    }
  }

  Future<void> _submit() async {
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
      _errorMessage = null;
      _emailFieldError = null;
    });

    try {
      await ref.read(authProvider.notifier).signUpWithManagedLogin(
            emailHint: _emailController.text.trim(),
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
                          const SizedBox(height: 14),
                          Text(
                            'We will create your account securely in your browser, where email, social sign-in, and passkeys stay on the same Cognito session.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: colors.onSurfaceVariant,
                                  height: 1.35,
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
