import 'package:dio/dio.dart';
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
import '../../services/cognito_managed_login_service.dart';
import '../../services/passkey_service.dart';
import '../../widgets/conscia_loading_overlay.dart';
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
  bool _showEmailSignIn = false;
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

    _clearLoadingUnlessAuthenticated();
  }

  Future<void> _signInWithPasskey(
    String email, {
    bool preferImmediatelyAvailableCredentials = true,
  }) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final tokens = await ref.read(passkeyServiceProvider).signIn(
            email,
            preferImmediatelyAvailableCredentials:
                preferImmediatelyAvailableCredentials,
          );
      await ref
          .read(authProvider.notifier)
          .completeExternalSignIn(tokens, email: email);
    } catch (e) {
      if (!mounted) return;
      if (!isPasskeyCancellation(e)) {
        if (isPasskeyCredentialUnavailable(e)) {
          await ref
              .read(passkeySignInPreferenceProvider.notifier)
              .forgetEmail(email);
        }
        setState(() => _errorMessage = friendlyPasskeyErrorMessage(e));
      }
    } finally {
      _clearLoadingUnlessAuthenticated();
    }
  }

  Future<void> _signInWithTypedPasskey() async {
    final email = _emailController.text.trim();
    final emailError = email.isEmpty
        ? 'Enter your email to use a passkey'
        : !isValidEmailAddress(email)
            ? 'Enter a valid email to use a passkey'
            : null;
    if (emailError != null) {
      setState(() {
        _emailFieldError = emailError;
        _passwordFieldError = null;
        _errorMessage = null;
      });
      return;
    }

    _dismissKeyboard();
    await _signInWithPasskey(
      email,
      preferImmediatelyAvailableCredentials: false,
    );
  }

  void _dismissKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void _clearLoadingUnlessAuthenticated() {
    if (!mounted) return;
    if (ref.read(authProvider).isAuthenticated) return;
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final passkeyPreference = ref.watch(passkeySignInPreferenceProvider);
    final passkeysAvailable =
        ref.watch(passkeyAvailabilityProvider).valueOrNull ?? false;
    final canShowPasskeyFirst =
        passkeysAvailable && passkeyPreference.canUsePasskeyFirst;
    final showPasskeyFirst = !_showEmailSignIn && canShowPasskeyFirst;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const ConsciaAppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
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
                          if (showPasskeyFirst)
                            _PasskeyFirstSignIn(
                              emails: passkeyPreference.registeredEmails,
                              isLoading: _isLoading,
                              onPasskeySignIn: _signInWithPasskey,
                              onUseAnotherPasskey: () {
                                final emails =
                                    passkeyPreference.registeredEmails;
                                if (emails.length == 1) {
                                  _signInWithPasskey(
                                    emails.single,
                                    preferImmediatelyAvailableCredentials:
                                        false,
                                  );
                                  return;
                                }

                                setState(() {
                                  _showEmailSignIn = true;
                                  _errorMessage = null;
                                });
                              },
                              onEmailSignIn: () {
                                setState(() {
                                  _showEmailSignIn = true;
                                  _errorMessage = null;
                                });
                              },
                            )
                          else ...[
                            Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  FloatingLabelTextField(
                                    controller: _emailController,
                                    label: 'Email',
                                    prefix: AppIcons.icon(
                                      AppIconKey.email,
                                      color: colors.onSurfaceVariant,
                                      size: 20,
                                    ),
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    onChanged: (_) => _clearInlineErrors(),
                                    errorText: _emailFieldError,
                                    autofillHints: const [
                                      AutofillHints.email,
                                    ],
                                    trailing: passkeysAvailable
                                        ? IconButton(
                                            key: const ValueKey(
                                              'email-passkey-sign-in-button',
                                            ),
                                            tooltip: 'Sign in with passkey',
                                            visualDensity:
                                                VisualDensity.compact,
                                            onPressed: _isLoading
                                                ? null
                                                : _signInWithTypedPasskey,
                                            icon: AppIcons.icon(
                                              AppIconKey.passkey,
                                              color: colors.primary,
                                              size: 20,
                                            ),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(height: 16),
                                  FloatingLabelTextField(
                                    controller: _passwordController,
                                    label: 'Password',
                                    prefix: AppIcons.icon(
                                      AppIconKey.password,
                                      color: colors.onSurfaceVariant,
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
                                    autofillHints: const [
                                      AutofillHints.password,
                                    ],
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
                                        () => _obscurePassword =
                                            !_obscurePassword,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _isLoading
                                    ? null
                                    : () => context.go(
                                          AppRoutes.passwordReset,
                                        ),
                                child: const Text('Forgot password?'),
                              ),
                            ),
                            if (canShowPasskeyFirst) ...[
                              Center(
                                child: TextButton(
                                  onPressed: _isLoading
                                      ? null
                                      : () {
                                          setState(() {
                                            _showEmailSignIn = false;
                                            _errorMessage = null;
                                          });
                                        },
                                  child: const Text('Sign in with passkey'),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            const SizedBox(height: 32),
                            SizedBox(
                              height: 48,
                              child: FilledButton(
                                onPressed: _isLoading ? null : _submit,
                                child: const Text('Sign In'),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                const Expanded(child: Divider()),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
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
                                        _dismissKeyboard();
                                        setState(() {
                                          _isLoading = true;
                                          _errorMessage = null;
                                        });
                                        try {
                                          await ref
                                              .read(authProvider.notifier)
                                              .signInWithApple();
                                        } on CognitoManagedLoginCancelledException {
                                          // User intentionally closed the hosted auth sheet.
                                        } catch (e) {
                                          if (!mounted) return;
                                          setState(() {
                                            _errorMessage =
                                                friendlySignInErrorMessage(e);
                                          });
                                        } finally {
                                          _clearLoadingUnlessAuthenticated();
                                        }
                                      },
                              ),
                            ),
                            const SizedBox(height: 12),
                            _GoogleSignInButton(
                              isLoading: _isLoading,
                              onPressed: () async {
                                _dismissKeyboard();
                                setState(() {
                                  _isLoading = true;
                                  _errorMessage = null;
                                });
                                try {
                                  await ref
                                      .read(authProvider.notifier)
                                      .signInWithGoogle();
                                } on CognitoManagedLoginCancelledException {
                                  // User intentionally closed the hosted auth sheet.
                                } catch (e) {
                                  if (!mounted) return;
                                  setState(() {
                                    _errorMessage =
                                        friendlySignInErrorMessage(e);
                                  });
                                } finally {
                                  _clearLoadingUnlessAuthenticated();
                                }
                              },
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: TextButton(
                                onPressed: _isLoading
                                    ? null
                                    : () => context.go(
                                          '/onboarding/sign-up',
                                        ),
                                child: const Text(
                                  "Don't have an account? Sign Up",
                                ),
                              ),
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
          if (_isLoading) const ConsciaLoadingOverlay(opacity: 0.6),
        ],
      ),
    );
  }
}

class _PasskeyFirstSignIn extends StatelessWidget {
  const _PasskeyFirstSignIn({
    required this.emails,
    required this.isLoading,
    required this.onPasskeySignIn,
    required this.onUseAnotherPasskey,
    required this.onEmailSignIn,
  });

  final List<String> emails;
  final bool isLoading;
  final ValueChanged<String> onPasskeySignIn;
  final VoidCallback onUseAnotherPasskey;
  final VoidCallback onEmailSignIn;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final hasOneAccount = emails.length == 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasOneAccount)
          Center(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                key: const ValueKey('saved-passkey-primary'),
                borderRadius: BorderRadius.circular(28),
                onTap: isLoading ? null : () => onPasskeySignIn(emails.single),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color:
                              colors.primaryContainer.withValues(alpha: 0.52),
                          borderRadius: BorderRadius.circular(26),
                          boxShadow: [
                            BoxShadow(
                              color: colors.primary.withValues(alpha: 0.14),
                              blurRadius: 22,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: AppIcons.icon(
                            AppIconKey.fingerprint,
                            color: colors.primary,
                            size: 38,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        emails.single,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: textTheme.titleMedium?.copyWith(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
        else
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surface.withValues(alpha: 0.92),
              border: Border.all(color: colors.outlineVariant),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.primaryContainer.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: AppIcons.icon(
                          AppIconKey.passkey,
                          color: colors.primary,
                          size: 26,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Sign in with passkey',
                    style: textTheme.headlineSmall?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose an account',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 20),
                  for (final email in emails) ...[
                    _PasskeyAccountButton(
                      email: email,
                      onPressed:
                          isLoading ? null : () => onPasskeySignIn(email),
                    ),
                    if (email != emails.last) const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: isLoading ? null : onUseAnotherPasskey,
            child: const Text('Use another passkey'),
          ),
        ),
        Center(
          child: TextButton(
            onPressed: isLoading ? null : onEmailSignIn,
            child: const Text('Sign in with email'),
          ),
        ),
      ],
    );
  }
}

class _PasskeyAccountButton extends StatelessWidget {
  const _PasskeyAccountButton({
    required this.email,
    required this.onPressed,
  });

  final String email;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Row(
          children: [
            AppIcons.icon(
              AppIconKey.passkey,
              color: colors.primary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            AppIcons.icon(
              AppIconKey.chevronRight,
              color: colors.onSurfaceVariant,
              size: 18,
            ),
          ],
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
