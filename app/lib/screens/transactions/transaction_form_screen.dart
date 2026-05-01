import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/amount_input_field.dart';
import 'widgets/category_picker.dart';

class TransactionFormScreen extends ConsumerStatefulWidget {
  final String? transactionId;

  const TransactionFormScreen({super.key, this.transactionId});

  @override
  ConsumerState<TransactionFormScreen> createState() =>
      _TransactionFormScreenState();
}

class _TransactionFormScreenState extends ConsumerState<TransactionFormScreen> {
  bool get _isEditing => widget.transactionId != null;

  // Form state
  bool _isExpense = true;
  final _amountController = TextEditingController();
  String _currencyCode = 'USD';
  String? _selectedCategory;
  final _merchantController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _includeLocation = false;
  final _notesController = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      // TODO: prefill from transactionDetailProvider
      _amountController.text = '45.20';
      _selectedCategory = 'Groceries';
      _merchantController.text = 'Walmart';
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _merchantController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  bool get _isValid {
    final amount = double.tryParse(_amountController.text);
    return amount != null && amount > 0 && _selectedCategory != null;
  }

  Future<void> _submit() async {
    if (!_isValid || _submitting) return;
    setState(() => _submitting = true);

    // TODO: wire to POST or PUT API
    await Future<void>.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;
    setState(() => _submitting = false);
    context.pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isEditing ? 'Transaction updated' : 'Transaction added!'),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: _isExpense ? DateTime.now() : DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

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
            // Type toggle
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
              onSelectionChanged: (v) =>
                  setState(() => _isExpense = v.first),
            ),

            const SizedBox(height: 16),

            // Amount
            AmountInputField(
              controller: _amountController,
              isExpense: _isExpense,
              currencyCode: _currencyCode,
              onCurrencyChanged: (code) =>
                  setState(() => _currencyCode = code),
            ),

            const SizedBox(height: 16),

            // Category
            CategoryPicker(
              selected: _selectedCategory,
              onSelected: (cat) =>
                  setState(() => _selectedCategory = cat),
            ),

            const SizedBox(height: 16),

            // Merchant
            TextField(
              controller: _merchantController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Merchant (optional)',
              ),
            ),

            const SizedBox(height: 16),

            // Date
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

            // Location toggle
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

            // Notes
            TextField(
              controller: _notesController,
              maxLines: 3,
              minLines: 1,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
              ),
            ),

            const SizedBox(height: 24),

            // Submit
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
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}
