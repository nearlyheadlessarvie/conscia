import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_icons.dart';
import '../../core/errors/app_error.dart';
import '../../core/routing/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/conscia_app_bar.dart';
import '../../widgets/floating_label_text_field.dart';
import '../../widgets/inline_notice.dart';
import 'widgets/auth_intro_panel.dart';

class NewPasswordRequiredScreen extends ConsumerStatefulWidget {
  const NewPasswordRequiredScreen({super.key});

  @override
  ConsumerState<NewPasswordRequiredScreen> createState() =>
      _NewPasswordRequiredScreenState();
}

class _NewPasswordRequiredScreenState
    extends ConsumerState<NewPasswordRequiredScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _errorMessage;
  String? _passwordFieldError;
  String? _confirmPasswordFieldError;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
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
        _passwordFieldError != null ||
        _confirmPasswordFieldError != null) {
      setState(() {
        _errorMessage = null;
        _passwordFieldError = null;
        _confirmPasswordFieldError = null;
      });
    }
  }

  Future<void> _savePassword() async {
    final passwordError = _validatePassword(_passwordController.text);
    final confirmError =
        _validateConfirmPassword(_confirmPasswordController.text);
    if (passwordError != null || confirmError != null) {
      setState(() {
        _passwordFieldError = passwordError;
        _confirmPasswordFieldError = confirmError;
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _passwordFieldError = null;
      _confirmPasswordFieldError = null;
    });

    try {
      await ref
          .read(authProvider.notifier)
          .completePasswordChange(_passwordController.text);
    } catch (e, s) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = AppError.from(e, stackTrace: s).userMessage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final email = ref.watch(authProvider).pendingEmail;

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
          onPressed: () {
            ref.read(authProvider.notifier).cancelPendingPasswordChange();
            context.go(AppRoutes.signIn);
          },
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
                title: 'Choose a new password',
                subtitle: email == null
                    ? 'Set a new password to finish signing in.'
                    : 'Set a new password for $email to finish signing in.',
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
                    AutofillGroup(
                      child: Column(
                        children: [
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
                            autofillHints: const [AutofillHints.newPassword],
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
                            label: 'Confirm password',
                            prefix: AppIcons.icon(
                              AppIconKey.password,
                              color: colors.onSurfaceVariant,
                              size: 20,
                            ),
                            obscureText: _obscureConfirm,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) {
                              if (!_isLoading) {
                                TextInput.finishAutofillContext();
                                _savePassword();
                              }
                            },
                            onChanged: (_) => _clearInlineErrors(),
                            errorText: _confirmPasswordFieldError,
                            enableSuggestions: false,
                            autocorrect: false,
                            autofillHints: const [AutofillHints.newPassword],
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
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      height: 48,
                      child: FilledButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                TextInput.finishAutofillContext();
                                _savePassword();
                              },
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Save password'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: TextButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                ref
                                    .read(authProvider.notifier)
                                    .cancelPendingPasswordChange();
                                context.go(AppRoutes.signIn);
                              },
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
