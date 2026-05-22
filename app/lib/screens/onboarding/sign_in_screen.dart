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
import '../../providers/passkey_provider.dart';
import '../../services/passkey_service.dart';
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
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;
  String? _emailFieldError;
  String? _passwordFieldError;

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
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Email is required';
    if (!isValidEmailAddress(value)) return 'Enter a valid email';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    return null;
  }

  void _clearInlineErrors() {
    if (_errorMessage != null ||
        _emailFieldError != null ||
        _passwordFieldError != null) {
      setState(() {
        _errorMessage = null;
        _emailFieldError = null;
        _passwordFieldError = null;
      });
    }
  }

  Future<void> _submit() async {
    final emailError = _validateEmail(_emailController.text.trim());
    final passwordError = _validatePassword(_passwordController.text);
    if (emailError != null || passwordError != null) {
      setState(() {
        _emailFieldError = emailError;
        _passwordFieldError = passwordError;
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _emailFieldError = null;
      _passwordFieldError = null;
    });

    try {
      await ref.read(authProvider.notifier).login(
            _emailController.text.trim(),
            _passwordController.text,
          );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = friendlySignInErrorMessage(
          e,
          isPasswordSignIn: true,
        );
      });
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  Future<void> _submitPasskey() async {
    final email = _emailController.text.trim();
    final emailError = _validateEmail(email);
    if (emailError != null) {
      setState(() {
        _emailFieldError = emailError;
        _passwordFieldError = null;
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _emailFieldError = null;
      _passwordFieldError = null;
    });

    try {
      final tokens = await ref.read(passkeyServiceProvider).signIn(email);
      await ref.read(authProvider.notifier).completeExternalSignIn(
            tokens,
            email: email,
          );
    } catch (e) {
      if (!mounted) return;
      if (isPasskeyCancellation(e)) {
        setState(() => _isLoading = false);
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = friendlyPasskeyErrorMessage(e);
      });
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final passkeysAvailable =
        ref.watch(passkeyAvailabilityProvider).valueOrNull ?? false;

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
                            textInputAction: TextInputAction.done,
                            onChanged: (_) => _clearInlineErrors(),
                            onSubmitted: (_) {
                              if (!_isLoading) {
                                _submit();
                              }
                            },
                            errorText: _passwordFieldError,
                            enableSuggestions: false,
                            autocorrect: false,
                            autofillHints: const [AutofillHints.password],
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
                            : const Text('Sign In'),
                      ),
                    ),
                    if (passkeysAvailable) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 48,
                        child: OutlinedButton.icon(
                          icon: AppIcons.icon(
                            AppIconKey.passkey,
                            color: colors.primary,
                            size: 24,
                          ),
                          label: const Text('Sign in with Passkey'),
                          onPressed: _isLoading ? null : _submitPasskey,
                        ),
                      ),
                    ],
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
