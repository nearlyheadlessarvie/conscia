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
import '../../providers/sign_in_preference_provider.dart';
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
  bool _showPasswordSignIn = false;
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

  Future<void> _submit({String? emailOverride}) async {
    final email = (emailOverride ?? _emailController.text).trim();
    final emailError = emailOverride == null ? _validateEmail(email) : null;
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
            email,
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

  Future<void> _signInWithApple() async {
    _dismissKeyboard();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await ref.read(authProvider.notifier).signInWithApple();
    } on CognitoManagedLoginCancelledException {
      // User intentionally closed the hosted auth sheet.
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = friendlySignInErrorMessage(e);
      });
    } finally {
      _clearLoadingUnlessAuthenticated();
    }
  }

  Future<void> _signInWithGoogle() async {
    _dismissKeyboard();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await ref.read(authProvider.notifier).signInWithGoogle();
    } on CognitoManagedLoginCancelledException {
      // User intentionally closed the hosted auth sheet.
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = friendlySignInErrorMessage(e);
      });
    } finally {
      _clearLoadingUnlessAuthenticated();
    }
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
    final rememberedSignIn = ref.watch(rememberedSignInPreferenceProvider);
    final passkeysAvailable =
        ref.watch(passkeyAvailabilityProvider).valueOrNull ?? false;
    final rememberedEmail = rememberedSignIn.email;
    final hasReturningIdentity = rememberedSignIn.hasRememberedIdentity &&
        !rememberedSignIn.showInitialSignIn &&
        rememberedEmail != null;
    final rememberedHasLocalPasskey = rememberedEmail != null &&
        passkeyPreference.hasRegisteredEmail(rememberedEmail);
    final canUseRememberedPasskey =
        passkeysAvailable && rememberedHasLocalPasskey;
    final showPasskeyPriority =
        hasReturningIdentity && canUseRememberedPasskey && !_showPasswordSignIn;
    final showReturningPassword = hasReturningIdentity && !showPasskeyPriority;

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
                          if (showPasskeyPriority || showReturningPassword)
                            _ReturningSignIn(
                              displayName: rememberedSignIn.displayNameOrEmail,
                              email: rememberedEmail,
                              passwordController: _passwordController,
                              obscurePassword: _obscurePassword,
                              passwordError: _passwordFieldError,
                              isLoading: _isLoading,
                              showPasskeyPriority: showPasskeyPriority,
                              canUsePasskey: canUseRememberedPasskey,
                              onNotYou: () async {
                                await ref
                                    .read(
                                      rememberedSignInPreferenceProvider
                                          .notifier,
                                    )
                                    .showInitialSignIn();
                                if (!mounted) return;
                                setState(() {
                                  _showPasswordSignIn = false;
                                  _errorMessage = null;
                                  _emailFieldError = null;
                                  _passwordFieldError = null;
                                });
                              },
                              onPasskeySignIn: () =>
                                  _signInWithPasskey(rememberedEmail),
                              onPasswordSignIn: () {
                                setState(() {
                                  _showPasswordSignIn = true;
                                  _errorMessage = null;
                                });
                              },
                              onPasswordVisibilityChanged: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                              onPasswordChanged: (_) => _clearInlineErrors(),
                              onSubmitPassword: () => _submit(
                                emailOverride: rememberedEmail,
                              ),
                              onForgotPassword: () =>
                                  context.go(AppRoutes.passwordReset),
                            )
                          else ...[
                            _InitialEmailPasswordSignIn(
                              formKey: _formKey,
                              emailController: _emailController,
                              passwordController: _passwordController,
                              obscurePassword: _obscurePassword,
                              emailError: _emailFieldError,
                              passwordError: _passwordFieldError,
                              passkeysAvailable: passkeysAvailable,
                              isLoading: _isLoading,
                              onEmailChanged: (_) => _clearInlineErrors(),
                              onPasswordChanged: (_) => _clearInlineErrors(),
                              onPasswordVisibilityChanged: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                              onTypedPasskey: _signInWithTypedPasskey,
                              onForgotPassword: () =>
                                  context.go(AppRoutes.passwordReset),
                              onSubmit: _submit,
                            ),
                            const SizedBox(height: 24),
                            const _SocialSignInDivider(),
                            const SizedBox(height: 24),
                            _SocialSignInButtons(
                              isLoading: _isLoading,
                              onApple: _signInWithApple,
                              onGoogle: _signInWithGoogle,
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: TextButton(
                                onPressed: _isLoading
                                    ? null
                                    : () => context.go('/onboarding/sign-up'),
                                child: const Text(
                                  "Don't have an account? Sign Up",
                                ),
                              ),
                            ),
                          ],
                          if (showPasskeyPriority || showReturningPassword) ...[
                            const SizedBox(height: 24),
                            const _SocialSignInDivider(),
                            const SizedBox(height: 24),
                            _SocialSignInButtons(
                              isLoading: _isLoading,
                              onApple: _signInWithApple,
                              onGoogle: _signInWithGoogle,
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

class _InitialEmailPasswordSignIn extends StatelessWidget {
  const _InitialEmailPasswordSignIn({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.emailError,
    required this.passwordError,
    required this.passkeysAvailable,
    required this.isLoading,
    required this.onEmailChanged,
    required this.onPasswordChanged,
    required this.onPasswordVisibilityChanged,
    required this.onTypedPasskey,
    required this.onForgotPassword,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final String? emailError;
  final String? passwordError;
  final bool passkeysAvailable;
  final bool isLoading;
  final ValueChanged<String> onEmailChanged;
  final ValueChanged<String> onPasswordChanged;
  final VoidCallback onPasswordVisibilityChanged;
  final VoidCallback onTypedPasskey;
  final VoidCallback onForgotPassword;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Form(
          key: formKey,
          child: Column(
            children: [
              FloatingLabelTextField(
                controller: emailController,
                label: 'Email',
                prefix: AppIcons.icon(
                  AppIconKey.email,
                  color: colors.onSurfaceVariant,
                  size: 20,
                ),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                onChanged: onEmailChanged,
                errorText: emailError,
                autofillHints: const [AutofillHints.email],
              ),
              const SizedBox(height: 16),
              FloatingLabelTextField(
                controller: passwordController,
                label: 'Password',
                prefix: AppIcons.icon(
                  AppIconKey.password,
                  color: colors.onSurfaceVariant,
                  size: 20,
                ),
                obscureText: obscurePassword,
                textInputAction: TextInputAction.done,
                onChanged: onPasswordChanged,
                onSubmitted: (_) {
                  if (!isLoading) onSubmit();
                },
                errorText: passwordError,
                enableSuggestions: false,
                autocorrect: false,
                autofillHints: const [AutofillHints.password],
                trailing: IconButton(
                  icon: AppIcons.icon(
                    obscurePassword
                        ? AppIconKey.visibility
                        : AppIconKey.visibilityOff,
                    color: obscurePassword
                        ? colors.onSurfaceVariant
                        : colors.primary,
                  ),
                  onPressed: onPasswordVisibilityChanged,
                ),
              ),
            ],
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: isLoading ? null : onForgotPassword,
            child: const Text('Forgot password?'),
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          height: 48,
          child: FilledButton(
            onPressed: isLoading ? null : onSubmit,
            child: const Text('Sign In'),
          ),
        ),
        if (passkeysAvailable) ...[
          const SizedBox(height: 12),
          Center(
            child: TextButton.icon(
              onPressed: isLoading ? null : onTypedPasskey,
              icon: AppIcons.icon(
                AppIconKey.passkey,
                color: colors.primary,
                size: 18,
              ),
              label: const Text('Sign in with passkey'),
            ),
          ),
        ],
      ],
    );
  }
}

class _ReturningSignIn extends StatelessWidget {
  const _ReturningSignIn({
    required this.displayName,
    required this.email,
    required this.passwordController,
    required this.obscurePassword,
    required this.passwordError,
    required this.isLoading,
    required this.showPasskeyPriority,
    required this.canUsePasskey,
    required this.onNotYou,
    required this.onPasskeySignIn,
    required this.onPasswordSignIn,
    required this.onPasswordVisibilityChanged,
    required this.onPasswordChanged,
    required this.onSubmitPassword,
    required this.onForgotPassword,
  });

  final String displayName;
  final String email;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final String? passwordError;
  final bool isLoading;
  final bool showPasskeyPriority;
  final bool canUsePasskey;
  final VoidCallback onNotYou;
  final VoidCallback onPasskeySignIn;
  final VoidCallback onPasswordSignIn;
  final VoidCallback onPasswordVisibilityChanged;
  final ValueChanged<String> onPasswordChanged;
  final VoidCallback onSubmitPassword;
  final VoidCallback onForgotPassword;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _RememberedIdentityHeader(
          displayName: displayName,
          onNotYou: onNotYou,
        ),
        if (showPasskeyPriority)
          _PasskeyPrioritySignIn(
            email: email,
            isLoading: isLoading,
            onPasskeySignIn: onPasskeySignIn,
            onPasswordSignIn: onPasswordSignIn,
          )
        else
          _ReturningPasswordSignIn(
            passwordController: passwordController,
            obscurePassword: obscurePassword,
            passwordError: passwordError,
            isLoading: isLoading,
            canUsePasskey: canUsePasskey,
            onPasswordVisibilityChanged: onPasswordVisibilityChanged,
            onPasswordChanged: onPasswordChanged,
            onSubmit: onSubmitPassword,
            onForgotPassword: onForgotPassword,
            onPasskeySignIn: onPasskeySignIn,
          ),
      ],
    );
  }
}

class _RememberedIdentityHeader extends StatelessWidget {
  const _RememberedIdentityHeader({
    required this.displayName,
    required this.onNotYou,
  });

  final String displayName;
  final VoidCallback onNotYou;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome back,',
          style: textTheme.titleMedium?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                displayName,
                style: textTheme.headlineSmall?.copyWith(
                  color: colors.onSurface,
                  height: 1.12,
                ),
              ),
            ),
            TextButton(
              onPressed: onNotYou,
              child: const Text('Not you?'),
            ),
          ],
        ),
      ],
    );
  }
}

class _PasskeyPrioritySignIn extends StatelessWidget {
  const _PasskeyPrioritySignIn({
    required this.email,
    required this.isLoading,
    required this.onPasskeySignIn,
    required this.onPasswordSignIn,
  });

  final String email;
  final bool isLoading;
  final VoidCallback onPasskeySignIn;
  final VoidCallback onPasswordSignIn;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 32),
        Material(
          color: Colors.transparent,
          child: InkWell(
            key: const ValueKey('saved-passkey-primary'),
            borderRadius: BorderRadius.circular(28),
            onTap: isLoading ? null : onPasskeySignIn,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.primaryContainer.withValues(alpha: 0.52),
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
                  const SizedBox(height: 12),
                  Text(
                    email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: isLoading ? null : onPasswordSignIn,
          child: const Text('Sign in with password'),
        ),
      ],
    );
  }
}

class _ReturningPasswordSignIn extends StatelessWidget {
  const _ReturningPasswordSignIn({
    required this.passwordController,
    required this.obscurePassword,
    required this.passwordError,
    required this.isLoading,
    required this.canUsePasskey,
    required this.onPasswordVisibilityChanged,
    required this.onPasswordChanged,
    required this.onSubmit,
    required this.onForgotPassword,
    required this.onPasskeySignIn,
  });

  final TextEditingController passwordController;
  final bool obscurePassword;
  final String? passwordError;
  final bool isLoading;
  final bool canUsePasskey;
  final VoidCallback onPasswordVisibilityChanged;
  final ValueChanged<String> onPasswordChanged;
  final VoidCallback onSubmit;
  final VoidCallback onForgotPassword;
  final VoidCallback onPasskeySignIn;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        FloatingLabelTextField(
          controller: passwordController,
          label: 'Password',
          prefix: AppIcons.icon(
            AppIconKey.password,
            color: colors.onSurfaceVariant,
            size: 20,
          ),
          obscureText: obscurePassword,
          textInputAction: TextInputAction.done,
          onChanged: onPasswordChanged,
          onSubmitted: (_) {
            if (!isLoading) onSubmit();
          },
          errorText: passwordError,
          enableSuggestions: false,
          autocorrect: false,
          autofillHints: const [AutofillHints.password],
          trailing: IconButton(
            icon: AppIcons.icon(
              obscurePassword
                  ? AppIconKey.visibility
                  : AppIconKey.visibilityOff,
              color: obscurePassword ? colors.onSurfaceVariant : colors.primary,
            ),
            onPressed: onPasswordVisibilityChanged,
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: isLoading ? null : onForgotPassword,
            child: const Text('Forgot password?'),
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          height: 48,
          child: FilledButton(
            onPressed: isLoading ? null : onSubmit,
            child: const Text('Sign In'),
          ),
        ),
        if (canUsePasskey) ...[
          const SizedBox(height: 12),
          Center(
            child: TextButton.icon(
              onPressed: isLoading ? null : onPasskeySignIn,
              icon: AppIcons.icon(
                AppIconKey.passkey,
                color: colors.primary,
                size: 18,
              ),
              label: const Text('Sign in with passkey'),
            ),
          ),
        ],
      ],
    );
  }
}

class _SocialSignInDivider extends StatelessWidget {
  const _SocialSignInDivider();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'or',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}

class _SocialSignInButtons extends StatelessWidget {
  const _SocialSignInButtons({
    required this.isLoading,
    required this.onApple,
    required this.onGoogle,
  });

  final bool isLoading;
  final VoidCallback onApple;
  final VoidCallback onGoogle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
            onPressed: isLoading ? null : onApple,
          ),
        ),
        const SizedBox(height: 12),
        _GoogleSignInButton(
          isLoading: isLoading,
          onPressed: onGoogle,
        ),
      ],
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
