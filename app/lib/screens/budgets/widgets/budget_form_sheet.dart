import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/conscience_journey.dart';
import '../../../core/errors/app_error.dart';
import '../../../core/utils/localized_number_input.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/budget_providers.dart';
import '../../../providers/conscience_journey_provider.dart';
import '../../../providers/family_space_provider.dart';
import '../../../providers/subscription_provider.dart';
import '../../../services/budget_service.dart';
import '../../transactions/widgets/transaction_style_category_selector.dart';
import '../../../widgets/currency_badge.dart';
import '../../../widgets/conscia_bottom_sheet.dart';
import '../../../widgets/conscia_confirm_sheet.dart';
import '../../../widgets/floating_label_text_field.dart';
import '../../../widgets/inline_notice.dart';
import '../../../widgets/scope_pill_switch.dart';
import '../../../widgets/screen_section.dart';
import '../../../providers/user_provider.dart';

class BudgetFormSheet extends ConsumerStatefulWidget {
  final Budget? existing;
  final String? initialCategory;

  const BudgetFormSheet({super.key, this.existing, this.initialCategory});

  static Future<void> show(
    BuildContext context, {
    Budget? existing,
    String? initialCategory,
  }) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => BudgetFormSheet(
        existing: existing,
        initialCategory: initialCategory,
      ),
    );
  }

  @override
  ConsumerState<BudgetFormSheet> createState() => _BudgetFormSheetState();
}

class _BudgetFormSheetState extends ConsumerState<BudgetFormSheet> {
  late final TextEditingController _amountController;
  String? _selectedCategory;
  String? _errorText;
  bool _submitting = false;
  String _scope = 'personal';
  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.existing == null
          ? ''
          : LocalizedNumberInput.formatForInput(
              widget.existing!.monthlyLimit,
              locale: ref.read(userPreferencesProvider).locale,
            ),
    );
    _selectedCategory = widget.existing?.category ?? widget.initialCategory;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  bool get _isValid {
    final amount = LocalizedNumberInput.parseAmount(
      _amountController.text,
      locale: ref.read(userPreferencesProvider).locale,
    );
    return amount != null && amount > 0 && _selectedCategory != null;
  }

  Future<void> _submit() async {
    if (!_isValid || _submitting) return;
    setState(() {
      _errorText = null;
      _submitting = true;
    });

    final amount = LocalizedNumberInput.parseAmount(
      _amountController.text,
      locale: ref.read(userPreferencesProvider).locale,
    );
    if (_selectedCategory == null || amount == null || amount <= 0) {
      if (mounted) setState(() => _submitting = false);
      return;
    }
    final user = ref.read(currentSessionUserProvider);
    final currency =
        widget.existing?.currencyCode ?? user?.currencyCode ?? 'USD';
    final familySpace = ref.read(familySpaceProvider).valueOrNull;
    final isFamilyScope =
        !_isEditing && _scope == 'family' && familySpace != null;
    final dto = CreateBudgetDto(
      category: _selectedCategory!,
      monthlyLimit: amount,
      currencyCode: currency,
      scope: isFamilyScope ? 'family' : 'personal',
      familySpaceId: isFamilyScope ? familySpace.id : null,
    );

    final notifier = ref.read(budgetListProvider.notifier);
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (_isEditing) {
        await notifier.update(widget.existing!.id, dto);
        messenger.showSnackBar(
          const SnackBar(content: Text('Budget updated.')),
        );
      } else {
        await notifier.create(dto);
        if (widget.initialCategory != null) {
          _recordJourneyEvent(
            eventType: ConscienceJourneyEvents.budgetCreatedFromNudge,
            sourceId:
                'budget-nudge:${widget.initialCategory}:${DateTime.now().millisecondsSinceEpoch}',
          );
        }
        messenger.showSnackBar(
          const SnackBar(content: Text('Budget created.')),
        );
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e, s) {
      final error = AppError.from(e, stackTrace: s, log: false);
      if (!mounted) return;
      setState(() => _errorText = error.userMessage);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _recordJourneyEvent({
    required String eventType,
    required String sourceId,
  }) {
    if (!ref.read(authProvider).isAuthenticated) return;
    unawaited(
      () async {
        try {
          await ref
              .read(conscienceJourneyProvider.notifier)
              .recordEvent(eventType: eventType, sourceId: sourceId);
        } catch (_) {
          // Budget creation should remain usable even if Journey sync is offline.
        }
      }(),
    );
  }

  Future<void> _confirmDelete() async {
    final confirmed = await ConsciaConfirmSheet.show(
      context,
      title: 'Delete ${widget.existing!.category} budget?',
      message: "This can't be undone.",
      confirmLabel: 'Delete budget',
    );

    if (confirmed && mounted) {
      final messenger = ScaffoldMessenger.of(context);
      await ref.read(budgetListProvider.notifier).delete(widget.existing!.id);
      messenger.showSnackBar(
        const SnackBar(content: Text('Budget deleted.')),
      );
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final user = ref.read(currentSessionUserProvider);
    final currency =
        widget.existing?.currencyCode ?? user?.currencyCode ?? 'USD';
    final isPremium =
        ref.watch(subscriptionProvider).valueOrNull?.isPremium ?? false;
    final familySpace = ref.watch(familySpaceProvider).valueOrNull;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SizedBox(
        height: 540,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(
                child: ConsciaSheetHandle(),
              ),
              const SizedBox(height: 16),
              ConsciaSheetHeader(
                title: _isEditing ? 'Edit Budget' : 'New Budget',
                subtitle: _isEditing
                    ? 'Tune the monthly cap Conscia tracks for this category.'
                    : 'Create a spending ceiling for a category and scope.',
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  children: [
                    ScreenSection(
                      title: 'Category',
                      subtitle: _isEditing
                          ? 'Category cannot be changed once the budget exists.'
                          : 'Choose which spending category this budget should watch.',
                      compact: true,
                      child: TransactionStyleCategorySelector(
                        selectedCategory: _selectedCategory,
                        isExpense: true,
                        isPremium: isPremium,
                        allowAllCategories: true,
                        showHeader: false,
                        onCategorySelected: _isEditing
                            ? (_) {}
                            : (value) => setState(() {
                                  _errorText = null;
                                  _selectedCategory = value;
                                }),
                      ),
                    ),
                    ScreenSection(
                      title: 'Monthly cap',
                      subtitle:
                          'Set the spending ceiling you want Conscia to track.',
                      compact: true,
                      child: FloatingLabelTextField(
                        controller: _amountController,
                        label: 'Monthly limit',
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          LocalizedNumberInput.formatter(
                            ref.watch(userPreferencesProvider).locale,
                          ),
                        ],
                        onChanged: (_) => setState(() => _errorText = null),
                        prefixLabelInset: 78,
                        prefix: Padding(
                          padding: const EdgeInsets.only(right: 2),
                          child: CurrencyBadge(
                            currencyCode: currency,
                          ),
                        ),
                      ),
                    ),
                    if (!_isEditing && familySpace != null)
                      ScreenSection(
                        title: 'Scope',
                        subtitle:
                            'Choose whether this budget stays personal or appears in ${familySpace.name}.',
                        compact: true,
                        child: ScopePillSwitch(
                          value: _scope,
                          familyEnabled: true,
                          onChanged: (value) => setState(() {
                            _errorText = null;
                            _scope = value;
                          }),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (_errorText != null) ...[
                InlineNotice(
                  message: _errorText!,
                  tone: InlineNoticeTone.error,
                  icon: AppIcons.icon(
                    AppIconKey.error,
                    color: Theme.of(context).colorScheme.error,
                    size: 20,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              FilledButton(
                onPressed: _isValid && !_submitting ? _submit : null,
                child: _submitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _isEditing ? 'Save Changes' : 'Create Budget',
                      ),
              ),
              if (_isEditing) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _confirmDelete,
                  child: const Text(
                    'Delete Budget',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
