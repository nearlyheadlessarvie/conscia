import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/recurring_schedule.dart';
import '../../providers/family_space_provider.dart';
import '../../services/recurring_service.dart';
import '../../widgets/feed_card.dart';
import '../../widgets/hero_screen_scaffold.dart';
import '../../widgets/skeleton_loader.dart';

class FamilyContributionScreen extends ConsumerStatefulWidget {
  const FamilyContributionScreen({super.key});

  @override
  ConsumerState<FamilyContributionScreen> createState() =>
      _FamilyContributionScreenState();
}

class _FamilyContributionScreenState
    extends ConsumerState<FamilyContributionScreen> {
  final _amountController = TextEditingController();
  final _labelController = TextEditingController();
  String _cadence = 'Monthly';
  bool _submitting = false;

  @override
  void dispose() {
    _amountController.dispose();
    _labelController.dispose();
    super.dispose();
  }

  bool get _isValid {
    final amount = double.tryParse(_amountController.text);
    return amount != null && amount > 0;
  }

  Future<void> _submit() async {
    final familySpace = ref.read(familySpaceProvider).valueOrNull;
    if (!_isValid || familySpace == null || _submitting) return;

    setState(() => _submitting = true);
    try {
      await ref.read(recurringServiceProvider).create(
            CreateRecurringScheduleRequest(
              type: 'income',
              amount: double.parse(_amountController.text),
              currencyCode: familySpace.currencyCode,
              category: 'Family Contribution',
              counterparty: _labelController.text,
              startDate: DateTime.now(),
              cadence: _cadence,
              scope: 'family',
              familySpaceId: familySpace.id,
            ),
          );

      ref.invalidate(familyOverviewProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contribution scheduled')),
      );
      final navigator = Navigator.of(context);
      if (navigator.canPop()) {
        navigator.pop();
      } else {
        setState(() => _submitting = false);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not schedule contribution')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final familySpace = ref.watch(familySpaceProvider);
    final theme = Theme.of(context);

    return HeroScreenScaffold(
      appBar: AppBar(title: const Text('Schedule contribution')),
      child: familySpace.when(
        loading: () => const SkeletonCard(),
        error: (_, __) => const FeedCard(
          child: Text('Unable to load Family Space'),
        ),
        data: (space) {
          if (space == null) {
            return const FeedCard(
              child: Text('Create a Family Space before scheduling contributions.'),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Contribution only, hidden exact salary.',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Track what you regularly put into the household pool without exposing your full income.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 18),
              FeedCard(
                child: Column(
                  children: [
                    TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Amount',
                        prefixText: '${space.currencyCode} ',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _labelController,
                      decoration: const InputDecoration(
                        labelText: 'Contribution label',
                        hintText: 'Payroll share',
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: _cadence,
                      decoration: const InputDecoration(labelText: 'Repeats'),
                      items: const [
                        DropdownMenuItem(
                          value: 'Weekly',
                          child: Text('Weekly'),
                        ),
                        DropdownMenuItem(
                          value: 'Monthly',
                          child: Text('Monthly'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) setState(() => _cadence = value);
                      },
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed:
                            _isValid && !_submitting ? _submit : null,
                        child: Text(
                          _submitting
                              ? 'Scheduling...'
                              : 'Schedule contribution',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
