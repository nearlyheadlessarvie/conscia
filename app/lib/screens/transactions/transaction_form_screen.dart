import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/exchange_rate_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../providers/transaction_providers.dart';
import '../../providers/user_provider.dart';
import '../../services/transaction_service.dart';
import '../../utils/utterance_parser.dart';
import '../../widgets/amount_input_field.dart';
import '../../widgets/skeleton_loader.dart';
import 'widgets/category_picker.dart';
import 'widgets/quick_preset_chips.dart';
import 'widgets/voice_input_button.dart';
import 'widgets/purchase_suggestion_chips.dart';

class TransactionFormScreen extends ConsumerStatefulWidget {
  final String? transactionId;

  const TransactionFormScreen({super.key, this.transactionId});

  @override
  ConsumerState<TransactionFormScreen> createState() =>
      _TransactionFormScreenState();
}

class _TransactionFormScreenState extends ConsumerState<TransactionFormScreen> {
  bool get _isEditing => widget.transactionId != null;

  bool _isExpense = true;
  final _amountController = TextEditingController();
  final _exchangeRateController = TextEditingController();
  String _currencyCode = 'USD';
  bool _currencyManuallyChanged = false;
  String? _selectedCategory;
  final _merchantController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _includeLocation = false;
  final _notesController = TextEditingController();
  bool _submitting = false;
  bool _prefilled = false;

  @override
  void initState() {
    super.initState();
    _currencyCode = ref.read(userPreferencesProvider).currency;
    if (_isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadEditData();
      });
    }
  }

  Future<void> _loadEditData() async {
    try {
      final service = ref.read(transactionServiceProvider);
      final tx = await service.getById(widget.transactionId!);
      if (!mounted) return;
      setState(() {
        _prefilled = true;
        _isExpense = tx.type != 'income';
        _amountController.text = tx.amount.toStringAsFixed(2);
        _currencyCode = tx.currencyCode;
        _currencyManuallyChanged = true;
        _selectedCategory = tx.category;
        _merchantController.text = tx.description;
        _selectedDate = tx.date;
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _amountController.dispose();
    _exchangeRateController.dispose();
    _merchantController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  bool get _isValid {
    final amount = double.tryParse(_amountController.text);
    return amount != null && amount > 0 && _selectedCategory != null;
  }

  void _onTranscriptReady(String transcript) {
    final result = UtteranceParser.parse(transcript);
    setState(() {
      if (result.description.isNotEmpty) {
        _merchantController.text = result.description;
      }
      if (result.amount != null) {
        _amountController.text = result.amount!.toStringAsFixed(2);
      }
      if (result.category != null) {
        _selectedCategory = result.category;
      }
    });
  }

  Future<void> _submit() async {
    if (!_isValid || _submitting) return;
    setState(() => _submitting = true);

    final userCurrency = ref.read(userPreferencesProvider).currency;
    final rateOverride = double.tryParse(_exchangeRateController.text);

    final dto = CreateTransactionDto(
      amount: double.parse(_amountController.text),
      currencyCode: _currencyCode,
      category: _selectedCategory!,
      merchant: _merchantController.text,
      type: _isExpense ? 'expense' : 'income',
      date: _selectedDate,
      baseCurrencyCode: userCurrency,
      exchangeRateOverride: rateOverride,
    );

    try {
      final service = ref.read(transactionServiceProvider);
      if (_isEditing) {
        await service.update(widget.transactionId!, dto);
      } else {
        await service.create(dto);
      }

      if (!mounted) return;
      ref.invalidate(transactionListProvider);
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(_isEditing ? 'Transaction updated' : 'Transaction added!'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: _isExpense
          ? DateTime.now()
          : DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final preferredCurrency = ref.watch(userPreferencesProvider).currency;

    if (!_isEditing &&
        !_currencyManuallyChanged &&
        _currencyCode != preferredCurrency) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _currencyManuallyChanged) return;
        setState(() => _currencyCode = preferredCurrency);
      });
    }

    if (_isEditing && !_prefilled) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Transaction')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            SkeletonLoader(height: 48),
            SizedBox(height: 16),
            SkeletonLoader(height: 48),
            SizedBox(height: 16),
            SkeletonLoader(height: 48),
            SizedBox(height: 16),
            SkeletonLoader(height: 48),
            SizedBox(height: 16),
            SkeletonLoader(height: 48),
          ],
        ),
      );
    }

    return _buildForm(colors, textTheme);
  }

  Widget _buildForm(ColorScheme colors, TextTheme textTheme) {
    final isPremium =
        ref.watch(subscriptionProvider).valueOrNull?.isPremium ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Transaction' : 'Add Transaction'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(
                  value: true,
                  label: const Text('Expense'),
                  icon: Icon(
                    Icons.arrow_downward,
                    color: _isExpense
                        ? (colors.brightness == Brightness.light
                            ? const Color(0xFFE53935)
                            : const Color(0xFFEF9A9A))
                        : null,
                  ),
                ),
                ButtonSegment(
                  value: false,
                  label: const Text('Income'),
                  icon: Icon(
                    Icons.arrow_upward,
                    color: !_isExpense
                        ? (colors.brightness == Brightness.light
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFF81C784))
                        : null,
                  ),
                ),
              ],
              selected: {_isExpense},
              onSelectionChanged: (v) => setState(() {
                _isExpense = v.first;
                _selectedCategory = null;
              }),
            ),
            const SizedBox(height: 16),
            AmountInputField(
              controller: _amountController,
              isExpense: _isExpense,
              currencyCode: _currencyCode,
              isPremium: isPremium,
              onChanged: (_) => setState(() {}),
              onCurrencyChanged: (code) => setState(() {
                _currencyManuallyChanged = true;
                _currencyCode = code;
              }),
            ),
            const SizedBox(height: 16),
            Consumer(
              builder: (context, ref, _) {
                final userCurrency = ref.watch(userPreferencesProvider).currency;
                if (_currencyCode == userCurrency) return const SizedBox.shrink();

                final rateAsync = ref.watch(
                  exchangeRateProvider((_currencyCode, userCurrency)),
                );

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: rateAsync.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (liveRate) => TextField(
                      controller: _exchangeRateController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Exchange rate (optional)',
                        hintText: liveRate != null
                            ? liveRate.toStringAsFixed(4)
                            : 'Enter rate manually',
                        helperText: liveRate != null
                            ? 'Leave blank to use live rate (1 $_currencyCode = ${liveRate.toStringAsFixed(4)} $userCurrency)'
                            : 'Live rate unavailable — enter manually or leave blank',
                      ),
                    ),
                  ),
                );
              },
            ),
            if (!_isEditing) ...[
              PurchaseSuggestionChips(
                onSuggestionSelected: (desc, amount, cat) {
                  setState(() {
                    _merchantController.text = desc;
                    _amountController.text = amount.toStringAsFixed(2);
                    _selectedCategory = cat;
                  });
                },
              ),
              const SizedBox(height: 8),
              Text(
                'Quick add',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 6),
              QuickPresetChips(
                selectedCategory: _selectedCategory,
                onCategorySelected: (cat) {
                  setState(() => _selectedCategory = cat);
                },
              ),
              const SizedBox(height: 16),
            ],
            CategoryPicker(
              selected: _selectedCategory,
              onSelected: (cat) => setState(() => _selectedCategory = cat),
              isExpense: _isExpense,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _merchantController,
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Merchant (optional)',
                suffixIcon: VoiceInputButton(
                  onTranscriptReady: _onTranscriptReady,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text(_formatDate(_selectedDate)),
              trailing: const Icon(Icons.chevron_right),
              onTap: _pickDate,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: colors.outline),
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: Text('Include Location', style: textTheme.titleSmall),
              subtitle: Text(
                'Attach GPS coordinates',
                style: textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              value: _includeLocation,
              onChanged: (v) => setState(() => _includeLocation = v),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: colors.outline),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              maxLines: 3,
              minLines: 1,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
              ),
            ),
            const SizedBox(height: 24),
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
                      _isEditing ? 'Update Transaction' : 'Save Transaction',
                    ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}
