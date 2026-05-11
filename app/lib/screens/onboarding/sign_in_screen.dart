import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/network/api_exception.dart';
import '../../core/routing/app_router.dart';
import '../../core/utils/email_validator.dart';
import '../../providers/auth_provider.dart';

String friendlySignInErrorMessage(
  Object error, {
  bool isPasswordSignIn = false,
}) {
  final apiError = switch (error) {
    ApiException apiException => apiException,
    DioException dioException => ApiException.fromDioException(dioException),
    _ => null,
  };

  if (apiError != null) {
    if (isPasswordSignIn && apiError.isUnauthorized) {
      return 'Invalid username or password.';
    }
    return apiError.message;
  }

  return 'Something went wrong. Please try again.';
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
  final _localAuth = LocalAuthentication();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;
  bool _biometricsAvailable = false;
  String? _lastEmail;

  @override
  void initState() {
    super.initState();
    _initBiometrics();
  }

  Future<void> _initBiometrics() async {
    final email = await getLastEmail();
    if (email != null && email.isNotEmpty) {
      _lastEmail = email;
      if (mounted) setState(() => _emailController.text = email);
    }
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      final prefs = await SharedPreferences.getInstance();
      final biometricEnabled = prefs.getBool('biometric_enabled') ?? false;
      if (mounted) {
        setState(() => _biometricsAvailable =
            canCheck && isSupported && _lastEmail != null && biometricEnabled);
      }
      if (_biometricsAvailable) {
        _authenticateWithBiometrics();
      }
    } catch (_) {}
  }

  Future<void> _authenticateWithBiometrics() async {
    if (_lastEmail == null) return;
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Sign in to Conscia',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      if (!authenticated || !mounted) return;

      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final token =
          await ref.read(secureStorageProvider).read(key: 'access_token');
      if (token != null && token.split('.').length == 3) {
        await ref.read(authProvider.notifier).loginWithStoredToken();
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Session expired. Please sign in with your password.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = null;
      });
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
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

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
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
                'Welcome Back',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in to continue',
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
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: _validateEmail,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      validator: _validatePassword,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outlined),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
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
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Sign In'),
                ),
              ),
              if (_biometricsAvailable) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    icon: const Icon(Icons.fingerprint, size: 24),
                    label: const Text('Sign in with Biometrics'),
                    onPressed: _isLoading ? null : _authenticateWithBiometrics,
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
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                    icon: const Icon(Icons.apple, size: 24),
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
                                _errorMessage = friendlySignInErrorMessage(e);
                              });
                            } finally {
                              if (mounted) setState(() => _isLoading = false);
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
                    await ref.read(authProvider.notifier).signInWithGoogle();
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
