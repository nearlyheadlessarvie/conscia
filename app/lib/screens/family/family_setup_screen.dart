import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_icons.dart';
import '../../core/errors/app_error.dart';
import '../../core/routing/app_router.dart';
import '../../providers/family_space_provider.dart';
import '../../widgets/feed_card.dart';
import '../../widgets/hero_screen_scaffold.dart';
import '../../widgets/screen_section.dart';

class FamilySetupScreen extends ConsumerStatefulWidget {
  const FamilySetupScreen({super.key});

  @override
  ConsumerState<FamilySetupScreen> createState() => _FamilySetupScreenState();
}

class _FamilySetupScreenState extends ConsumerState<FamilySetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'My Family Space');
  final _currencyController = TextEditingController(text: 'PHP');
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _currencyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return HeroScreenScaffold(
      appBar: AppBar(
        title: const Text('Create Family Space'),
      ),
      bottom: FilledButton(
        onPressed: _isSubmitting ? null : _submit,
        child: Text(_isSubmitting ? 'Creating...' : 'Create Family Space'),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Family Space shares household planning, not private accounts.',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Records stay personal unless you mark them as Family. Start clean, then share only the household spending that belongs there.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 18),
            FeedCard(
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Family Space name',
                      prefixIcon: Icon(AppIcons.family),
                    ),
                    textInputAction: TextInputAction.next,
                    validator: (value) =>
                        value == null || value.trim().isEmpty
                            ? 'Name is required'
                            : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _currencyController,
                    decoration: const InputDecoration(
                      labelText: 'Shared currency',
                      prefixIcon: Icon(Icons.payments_outlined),
                    ),
                    maxLength: 3,
                    textCapitalization: TextCapitalization.characters,
                    validator: (value) =>
                        value == null || value.trim().length != 3
                            ? 'Use a 3-letter currency code'
                            : null,
                  ),
                ],
              ),
            ),
            const ScreenSection(
              title: 'Premium',
              child: FeedCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.workspace_premium_outlined),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Requires Premium to create. Invited members can participate free.',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(familySpaceActionsProvider).create(
            name: _nameController.text.trim(),
            currencyCode: _currencyController.text.trim().toUpperCase(),
          );
      if (!mounted) return;
      context.go(AppRoutes.familySpace);
    } catch (e, s) {
      if (!mounted) return;
      final error = AppError.from(e, stackTrace: s);
      messenger.showSnackBar(SnackBar(content: Text(error.userMessage)));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
