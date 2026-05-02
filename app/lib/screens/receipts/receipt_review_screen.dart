import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/dio_client.dart';
import '../../providers/subscription_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/amount_input_field.dart';
import '../transactions/widgets/category_picker.dart';

class ReceiptReviewScreen extends ConsumerStatefulWidget {
  final String receiptId;

  const ReceiptReviewScreen({super.key, required this.receiptId});

  @override
  ConsumerState<ReceiptReviewScreen> createState() =>
      _ReceiptReviewScreenState();
}

class _ReceiptReviewScreenState extends ConsumerState<ReceiptReviewScreen> {
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  final _merchantController = TextEditingController();
  final _amountController = TextEditingController();
  String _currencyCode = 'USD';
  String? _selectedCategory;
  DateTime _date = DateTime.now();
  double _confidence = 0.0;
  bool _needsReview = false;

  final List<_LineItem> _lineItems = [];

  @override
  void initState() {
    super.initState();
    _loadReceiptData();
  }

  @override
  void dispose() {
    _merchantController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadReceiptData() async {
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get('/receipts/${widget.receiptId}');
      final data = response.data as Map<String, dynamic>;

      if (!mounted) return;

      final extracted = data['extractedData'] as Map<String, dynamic>?;
      final items = (extracted?['items'] as List?)
              ?.map((e) => _LineItem(
                    e['name'] as String? ?? '',
                    (e['amount'] as num?)?.toDouble() ?? 0,
                  ))
              .toList() ??
          [];

      setState(() {
        _loading = false;
        _merchantController.text = extracted?['merchant'] as String? ?? '';
        final total = (extracted?['total'] as num?)?.toDouble();
        _amountController.text = total?.toStringAsFixed(2) ?? '';
        _currencyCode = extracted?['currencyCode'] as String? ??
            ref.read(userPreferencesProvider).currency;
        _selectedCategory = extracted?['category'] as String?;
        final dateStr = extracted?['date'] as String?;
        if (dateStr != null) _date = DateTime.tryParse(dateStr) ?? _date;
        _confidence = (data['ocrConfidence'] as num?)?.toDouble() ?? 0.0;
        _needsReview = data['needsReview'] as bool? ?? true;
        _lineItems.clear();
        _lineItems.addAll(items);
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error =
            e.response?.data?['error'] as String? ?? 'Failed to load receipt';
      });
    }
  }

  bool get _isValid {
    final amount = double.tryParse(_amountController.text);
    return amount != null &&
        amount > 0 &&
        _merchantController.text.isNotEmpty &&
        _selectedCategory != null;
  }

  Future<void> _confirm() async {
    if (!_isValid || _submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final dio = ref.read(dioProvider);
      await dio.post(
        '/receipts/${widget.receiptId}/confirm',
        data: {
          'merchant': _merchantController.text,
          'amount': double.parse(_amountController.text),
          'currencyCode': _currencyCode,
          'category': _selectedCategory,
          'date': _date.toIso8601String(),
        },
      );

      if (!mounted) return;
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Receipt confirmed and transaction saved!')),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e.response?.data?['error'] as String? ??
            'Failed to confirm receipt';
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Receipt'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (!_loading)
            TextButton(
              onPressed: _isValid && !_submitting ? _confirm : null,
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Confirm'),
            ),
        ],
      ),
      body: _loading
          ? _buildLoading()
          : _error != null && _merchantController.text.isEmpty
              ? _buildError(colors, textTheme)
              : _buildContent(colors, textTheme),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Extracting receipt details...'),
        ],
      ),
    );
  }

  Widget _buildError(ColorScheme colors, TextTheme textTheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: colors.error),
            const SizedBox(height: 16),
            Text('Could not load receipt', style: textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(_error!,
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                setState(() {
                  _loading = true;
                  _error = null;
                });
                _loadReceiptData();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ColorScheme colors, TextTheme textTheme) {
    final isPremium =
        ref.watch(subscriptionProvider).valueOrNull?.isPremium ?? false;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.error.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, size: 18, color: colors.error),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(_error!,
                            style: textTheme.bodySmall
                                ?.copyWith(color: colors.error))),
                  ],
                ),
              ),
            ),

          // Confidence indicator
          _buildConfidenceBanner(colors, textTheme),
          const SizedBox(height: 20),

          // Merchant
          TextField(
            controller: _merchantController,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'Merchant',
              prefixIcon: const Icon(Icons.store),
              suffixIcon: _needsReview
                  ? Tooltip(
                      message: 'AI-extracted — please verify',
                      child: Icon(Icons.auto_fix_high,
                          size: 18, color: colors.secondary),
                    )
                  : null,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),

          // Amount
          AmountInputField(
            controller: _amountController,
            isExpense: true,
            currencyCode: _currencyCode,
            isPremium: isPremium,
            onCurrencyChanged: (code) => setState(() => _currencyCode = code),
          ),
          const SizedBox(height: 16),

          // Category
          CategoryPicker(
            selected: _selectedCategory,
            onSelected: (cat) => setState(() => _selectedCategory = cat),
          ),
          const SizedBox(height: 16),

          // Date
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: Text(_formatDate(_date)),
            trailing: const Icon(Icons.chevron_right),
            onTap: _pickDate,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: colors.outline),
            ),
          ),
          const SizedBox(height: 24),

          // Line items
          if (_lineItems.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.receipt_long,
                    size: 20, color: colors.onSurfaceVariant),
                const SizedBox(width: 8),
                Text('Extracted Items',
                    style: textTheme.titleSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    )),
                const Spacer(),
                Text('${_lineItems.length} items',
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.outline,
                    )),
              ],
            ),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  for (var i = 0; i < _lineItems.length; i++) ...[
                    _buildLineItemTile(i, colors, textTheme),
                    if (i < _lineItems.length - 1)
                      Divider(
                          height: 1,
                          indent: 16,
                          endIndent: 16,
                          color: colors.outlineVariant),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Total row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total',
                      style: textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  Text(
                    '\$${_amountController.text} $_currencyCode',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colors.error,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 32),

          // Confirm button
          FilledButton.icon(
            onPressed: _isValid && !_submitting ? _confirm : null,
            icon: const Icon(Icons.check),
            label:
                Text(_submitting ? 'Saving...' : 'Confirm & Save Transaction'),
          ),

          const SizedBox(height: 8),

          // Discard button
          OutlinedButton(
            onPressed: _submitting
                ? null
                : () {
                    context.pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Receipt discarded')),
                    );
                  },
            child: const Text('Discard'),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildConfidenceBanner(ColorScheme colors, TextTheme textTheme) {
    final percentage = (_confidence * 100).round();
    final isHigh = _confidence >= 0.9;
    final isMedium = _confidence >= 0.75 && !isHigh;

    final Color bannerColor;
    final Color textColor;
    final IconData icon;
    final String label;

    if (isHigh) {
      bannerColor = const Color(0xFF4CAF50).withAlpha(25);
      textColor = const Color(0xFF2E7D32);
      icon = Icons.verified;
      label = 'High confidence ($percentage%)';
    } else if (isMedium) {
      bannerColor = colors.secondary.withAlpha(25);
      textColor = const Color(0xFFE65100);
      icon = Icons.info_outline;
      label = 'Medium confidence ($percentage%) — please review';
    } else {
      bannerColor = colors.error.withAlpha(25);
      textColor = colors.error;
      icon = Icons.warning_amber;
      label = 'Low confidence ($percentage%) — manual review needed';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bannerColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: textColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: textTheme.labelLarge?.copyWith(color: textColor)),
                if (_needsReview)
                  Text('Fields highlighted with ✨ may need correction',
                      style: textTheme.bodySmall
                          ?.copyWith(color: textColor.withAlpha(180))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineItemTile(
      int index, ColorScheme colors, TextTheme textTheme) {
    final item = _lineItems[index];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(item.name, style: textTheme.bodyMedium),
          ),
          Text(
            '\$${item.amount.toStringAsFixed(2)}',
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
            ),
          ),
        ],
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

class _LineItem {
  final String name;
  final double amount;

  const _LineItem(this.name, this.amount);
}
