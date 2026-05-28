import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_icons.dart';
import '../../core/errors/app_error.dart';
import '../../core/network/api_exception.dart';
import '../../core/routing/app_router.dart';
import '../../core/utils/email_validator.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/floating_label_text_field.dart';
import '../../widgets/conscia_app_bar.dart';
import '../../widgets/inline_notice.dart';
import 'widgets/auth_intro_panel.dart';

String friendlySignInErrorMessage(
  Object error, {
  bool isPasswordSignIn = false,
}) {
  final appError = AppError.from(error);
  final originalError = error is AppError ? error.originalError : error;
  final apiError = switch (originalError) {
    ApiException apiException => apiException,
    DioException dioException => ApiException.fromDioException(dioException),
    _ => null,
  };

  if (apiError != null) {
    if (isPasswordSignIn && apiError.isUnauthorized) {
      return 'Invalid username or password.';
    }
    return appError.userMessage;
  }

  return appError.userMessage;
}

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  String? _emailFieldError;

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
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return null;
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
    final email = _emailController.text.trim();
    final emailError = _validateEmail(email);
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
      await ref.read(authProvider.notifier).continueWithManagedLogin(
            emailHint: email.isEmpty ? null : email,
          );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = friendlySignInErrorMessage(
          e,
        );
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
                title: 'Welcome back',
                subtitle:
                    'Return to your money rhythm with a little more calm.',
                icon: AppIconKey.sparkleGuidance,
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
                            label: 'Email (optional)',
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
                            'We will finish email, password, and passkey sign-in securely in your browser.',
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
                            : const Text('Continue with Email or Passkey'),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'or',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 24),
                    if (defaultTargetPlatform == TargetPlatform.iOS) ...[
                      SizedBox(
                        height: 48,
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          icon: AppIcons.icon(
                            AppIconKey.appleBrand,
                            color: Colors.white,
                            size: 24,
                          ),
                          label: const Text('Sign in with Apple'),
                          onPressed: _isLoading
                              ? null
                              : () async {
                                  setState(() {
                                    _isLoading = true;
                                    _errorMessage = null;
                                  });
                                  try {
                                    await ref
                                        .read(authProvider.notifier)
                                        .signInWithApple();
                                  } catch (e) {
                                    if (!mounted) return;
                                    setState(() {
                                      _errorMessage =
                                          friendlySignInErrorMessage(e);
                                    });
                                  } finally {
                                    if (mounted) {
                                      setState(() => _isLoading = false);
                                    }
                                  }
                                },
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    _GoogleSignInButton(
                      isLoading: _isLoading,
                      onPressed: () async {
                        setState(() {
                          _isLoading = true;
                          _errorMessage = null;
                        });
                        try {
                          await ref
                              .read(authProvider.notifier)
                              .signInWithGoogle();
                        } catch (e) {
                          if (!mounted) return;
                          setState(() {
                            _errorMessage = friendlySignInErrorMessage(e);
                          });
                        } finally {
                          if (mounted) setState(() => _isLoading = false);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: TextButton(
                        onPressed: () => context.go('/onboarding/sign-up'),
                        child: const Text("Don't have an account? Sign Up"),
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

class _GoogleSignInButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;

  const _GoogleSignInButton({required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1F1F1F),
          side: const BorderSide(color: Color(0xFFDDDDDD)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        onPressed: isLoading ? null : onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/images/google_logo.svg',
              width: 20,
              height: 20,
            ),
            const SizedBox(width: 12),
            const Text('Sign in with Google'),
          ],
        ),
      ),
    );
  }
}
