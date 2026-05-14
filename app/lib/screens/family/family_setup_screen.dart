import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_icons.dart';
import '../../core/errors/app_error.dart';
import '../../core/routing/app_router.dart';
import '../../providers/family_space_provider.dart';
import '../../widgets/feed_card.dart';
import '../../widgets/floating_label_text_field.dart';
import '../../widgets/hero_screen_scaffold.dart';
import '../../widgets/screen_section.dart';

class FamilySetupScreen extends ConsumerStatefulWidget {
  const FamilySetupScreen({super.key});

  @override
  ConsumerState<FamilySetupScreen> createState() => _FamilySetupScreenState();
}

class _FamilySetupScreenState extends ConsumerState<FamilySetupScreen> {
  final _nameController = TextEditingController(text: 'My Family Space');
  final _currencyController = TextEditingController(text: 'PHP');
  bool _isSubmitting = false;
  String? _nameError;
  String? _currencyError;

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
                FloatingLabelTextField(
                  controller: _nameController,
                  label: 'Family Space name',
                  prefix: Icon(AppIcons.family),
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  errorText: _nameError,
                  onChanged: (_) {
                    if (_nameError != null) {
                      setState(() => _nameError = null);
                    }
                  },
                ),
                const SizedBox(height: 14),
                FloatingLabelTextField(
                  controller: _currencyController,
                  label: 'Shared currency',
                  prefix: const Icon(Icons.payments_outlined),
                  maxLength: 3,
                  counterText: '',
                  textCapitalization: TextCapitalization.characters,
                  errorText: _currencyError,
                  onChanged: (_) {
                    if (_currencyError != null) {
                      setState(() => _currencyError = null);
                    }
                  },
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
    );
  }

  Future<void> _submit() async {
    if (!_validate()) return;

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

  bool _validate() {
    final nextNameError =
        _nameController.text.trim().isEmpty ? 'Name is required' : null;
    final nextCurrencyError = _currencyController.text.trim().length != 3
        ? 'Use a 3-letter currency code'
        : null;

    setState(() {
      _nameError = nextNameError;
      _currencyError = nextCurrencyError;
    });

    return nextNameError == null && nextCurrencyError == null;
  }
}
