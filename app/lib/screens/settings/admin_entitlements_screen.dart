import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_error.dart';
import '../../providers/admin_entitlement_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/conscia_app_bar.dart';
import '../../widgets/feed_card.dart';
import '../../widgets/hero_screen_scaffold.dart';
import '../../widgets/screen_section.dart';

class AdminEntitlementsScreen extends ConsumerStatefulWidget {
  const AdminEntitlementsScreen({super.key});

  @override
  ConsumerState<AdminEntitlementsScreen> createState() =>
      _AdminEntitlementsScreenState();
}

class _AdminEntitlementsScreenState
    extends ConsumerState<AdminEntitlementsScreen> {
  final _lookupEmailController = TextEditingController();
  final _targetUserIdController = TextEditingController();
  final _noteController = TextEditingController(
    text: 'internal lifetime premium',
  );
  final _reviewerEmailController = TextEditingController(
    text: 'reviewer@getconscia.com',
  );
  final _reviewerPasswordController = TextEditingController(
    text: 'ConsciaTemp123!',
  );

  String _result = '';
  bool _busy = false;
  bool _grantReviewerLifetime = true;

  @override
  void dispose() {
    _lookupEmailController.dispose();
    _targetUserIdController.dispose();
    _noteController.dispose();
    _reviewerEmailController.dispose();
    _reviewerPasswordController.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;

    setState(() => _busy = true);
    try {
      await action();
    } on DioException catch (error, stackTrace) {
      final appError = AppError.from(error, stackTrace: stackTrace, log: false);
      setState(() => _result = appError.userMessage);
    } catch (error, stackTrace) {
      final appError = AppError.from(error, stackTrace: stackTrace, log: false);
      setState(() => _result = appError.userMessage);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final service = ref.watch(adminEntitlementServiceProvider);

    return HeroScreenScaffold(
      appBar: const ConsciaAppBar(title: Text('Admin Entitlements')),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ScreenSection(
            title: 'Operator Access',
            subtitle:
                'This screen uses your normal signed-in session. Backend authorization decides who can actually grant or revoke premium.',
            compact: true,
            child: FeedCard(
              child: Text(
                authState.isAuthenticated
                    ? 'Signed in. If this account is not an admin, the backend will return a permission error.'
                    : 'Sign in first to use admin entitlement tools.',
              ),
            ),
          ),
          ScreenSection(
            title: 'Lookup and Access',
            subtitle:
                'Resolve a target user by email, then grant or revoke the lifetime premium override by user ID.',
            compact: true,
            child: FeedCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    key: const ValueKey('admin-entitlements-lookup-email'),
                    controller: _lookupEmailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Lookup by email',
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _busy || !authState.isAuthenticated
                          ? null
                          : () => _run(() async {
                                final lookup = await service.lookupByEmail(
                                  _lookupEmailController.text.trim(),
                                );
                                _targetUserIdController.text = lookup.userId;
                                setState(() {
                                  _result =
                                      '${lookup.email}\n${lookup.userId}\n${lookup.source}\nactive=${lookup.isActive}';
                                });
                              }),
                      child: const Text('Lookup user'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    key: const ValueKey('admin-entitlements-target-user-id'),
                    controller: _targetUserIdController,
                    decoration: const InputDecoration(
                      labelText: 'Target user ID',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const ValueKey('admin-entitlements-note'),
                    controller: _noteController,
                    decoration: const InputDecoration(
                      labelText: 'Grant note',
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _busy || !authState.isAuthenticated
                          ? null
                          : () => _run(() async {
                                final result =
                                    await service.grantLifetimePremium(
                                  _targetUserIdController.text.trim(),
                                  _noteController.text.trim(),
                                );
                                setState(() {
                                  _result =
                                      'Granted ${result.email} (${result.userId}) source=${result.source}';
                                });
                              }),
                      child: const Text('Grant lifetime premium'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _busy || !authState.isAuthenticated
                          ? null
                          : () => _run(() async {
                                final result =
                                    await service.revokeLifetimePremium(
                                  _targetUserIdController.text.trim(),
                                );
                                setState(() {
                                  _result =
                                      'Revoked ${result.email} (${result.userId}) source=${result.source}';
                                });
                              }),
                      child: const Text('Revoke lifetime premium'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          ScreenSection(
            title: 'Reviewer Provisioning',
            subtitle:
                'Create a narrow reviewer or demo account, with optional lifetime premium at provisioning time.',
            compact: true,
            child: FeedCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _reviewerEmailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Reviewer or demo email',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _reviewerPasswordController,
                    decoration: const InputDecoration(
                      labelText: 'Temporary password',
                    ),
                  ),
                  const SizedBox(height: 4),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _grantReviewerLifetime,
                    onChanged: _busy || !authState.isAuthenticated
                        ? null
                        : (value) {
                            setState(() => _grantReviewerLifetime = value);
                          },
                    title: const Text('Grant lifetime premium'),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _busy || !authState.isAuthenticated
                          ? null
                          : () => _run(() async {
                                final result = await service.provisionReviewer(
                                  email: _reviewerEmailController.text.trim(),
                                  temporaryPassword:
                                      _reviewerPasswordController.text,
                                  grantLifetimePremium: _grantReviewerLifetime,
                                  note: 'reviewer/demo provision',
                                );
                                _targetUserIdController.text = result.userId;
                                setState(() {
                                  _result =
                                      'Provisioned ${result.email} (${result.userId}) source=${result.source}';
                                });
                              }),
                      child: const Text('Provision reviewer/demo account'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_result.isNotEmpty)
            ScreenSection(
              title: 'Result',
              subtitle: 'Latest backend response',
              compact: true,
              child: FeedCard(
                child: SelectableText(_result),
              ),
            ),
        ],
      ),
    );
  }
}
