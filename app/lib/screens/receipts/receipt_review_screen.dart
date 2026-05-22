import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_error.dart';
import '../../core/constants/app_icons.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_layout.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/localized_number_input.dart';
import '../../providers/budget_providers.dart';
import '../../providers/insight_feed_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../providers/transaction_providers.dart';
import '../../providers/user_provider.dart';
import '../../widgets/amount_hero_field.dart';
import '../../widgets/conscia_app_bar.dart';
import '../../widgets/editorial_hero_chip.dart';
import '../../widgets/floating_label_text_field.dart';
import '../../widgets/hero_screen_scaffold.dart';
import '../../widgets/screen_section.dart';
import '../transactions/widgets/transaction_style_category_selector.dart';

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
  final _amountFocusNode = FocusNode();
  String _currencyCode = '';
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
    _amountFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadReceiptData() async {
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get(ApiConstants.receipt(widget.receiptId));
      final data = response.data as Map<String, dynamic>;

      if (!mounted) return;

      final extracted = data['extractedData'] as Map<String, dynamic>?;
      final items = (extracted?['items'] as List?)
              ?.map(
                (e) => _LineItem(
                  e['name'] as String? ?? '',
                  (e['amount'] as num?)?.toDouble() ?? 0,
                ),
              )
              .toList() ??
          [];

      setState(() {
        _loading = false;
        _merchantController.text = extracted?['merchant'] as String? ?? '';
        final total = (extracted?['total'] as num?)?.toDouble();
        _amountController.text = total == null
            ? ''
            : LocalizedNumberInput.formatForInput(
                total,
                locale: ref.read(userPreferencesProvider).locale,
              );
        _currencyCode = _resolveCurrencyCode(extracted?['currencyCode']);
        _selectedCategory = extracted?['category'] as String?;
        final dateStr = extracted?['date'] as String?;
        if (dateStr != null) _date = DateTime.tryParse(dateStr) ?? _date;
        _confidence = (data['ocrConfidence'] as num?)?.toDouble() ?? 0.0;
        _needsReview = data['needsReview'] as bool? ?? true;
        _lineItems
          ..clear()
          ..addAll(items);
      });
    } on DioException catch (e, s) {
      if (!mounted) return;
      final error = AppError.from(e, stackTrace: s);
      setState(() {
        _loading = false;
        _error = error.userMessage;
      });
    }
  }

  bool get _isValid {
    final amount = LocalizedNumberInput.parseAmount(
      _amountController.text,
      locale: ref.read(userPreferencesProvider).locale,
    );
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
      final amount = LocalizedNumberInput.parseAmount(
        _amountController.text,
        locale: ref.read(userPreferencesProvider).locale,
      )!;
      final dio = ref.read(dioProvider);
      await dio.post(
        ApiConstants.receiptConfirm(widget.receiptId),
        data: {
          'merchant': _merchantController.text,
          'amount': amount,
          'currencyCode': _currencyCode,
          'category': _selectedCategory,
          'date': _date.toIso8601String(),
        },
      );

      ref.invalidate(transactionListProvider);
      ref.invalidate(budgetListProvider);
      ref.invalidate(dashboardInsightFeedProvider);
      ref.invalidate(dashboardInsightSummaryProvider);

      if (!mounted) return;
      Navigator.of(context).maybePop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Receipt confirmed and transaction saved!'),
        ),
      );
    } on DioException catch (e, s) {
      if (!mounted) return;
      final error = AppError.from(e, stackTrace: s);
      setState(() {
        _submitting = false;
        _error = error.userMessage;
      });
    } catch (e, s) {
      if (!mounted) return;
      final error = AppError.from(e, stackTrace: s);
      setState(() {
        _submitting = false;
        _error = error.userMessage;
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
    final textTheme = Theme.of(context).textTheme;
    final hasFatalLoadError =
        _error != null && _merchantController.text.isEmpty;

    return HeroScreenScaffold(
      bleedBehindAppBar: true,
      padding: EdgeInsets.zero,
      appBar: ConsciaAppBar(
        title: const Text('Review Receipt'),
        leading: IconButton(
          icon: AppIcons.icon(
            AppIconKey.chevronLeft,
            color: Theme.of(context).colorScheme.onSurface,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      bottom: !_loading && !hasFatalLoadError ? _buildConfirmDock() : null,
      child: _loading
          ? _buildLoading()
          : hasFatalLoadError
              ? _buildError(textTheme)
              : _buildContent(textTheme),
    );
  }

  Widget _buildConfirmDock() {
    return SizedBox(
      key: const ValueKey('receipt-review-confirm-dock'),
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: _isValid && !_submitting ? _confirm : null,
        icon: AppIcons.icon(
          AppIconKey.check,
          color: Theme.of(context).colorScheme.onPrimary,
          size: 18,
        ),
        label: Text(_submitting ? 'Saving...' : 'Confirm and save'),
      ),
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

  Widget _buildError(TextTheme textTheme) {
    final colors = Theme.of(context).appColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.paper,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcons.icon(
                AppIconKey.error,
                size: 44,
                color: colors.expense,
              ),
              const SizedBox(height: 16),
              Text('Could not load receipt', style: textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.mutedInk,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  setState(() {
                    _loading = true;
                    _error = null;
                  });
                  _loadReceiptData();
                },
                icon: AppIcons.icon(
                  AppIconKey.refresh,
                  color: Theme.of(context).colorScheme.onPrimary,
                  size: 18,
                ),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(TextTheme textTheme) {
    final colors = Theme.of(context).appColors;
    final isPremium =
        ref.watch(subscriptionProvider).valueOrNull?.isPremium ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ReceiptReviewHero(
          confidence: _confidence,
          needsReview: _needsReview,
          merchant: _merchantController.text,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error != null) ...[
                _InlineErrorNote(message: _error!),
                const SizedBox(height: 16),
              ],
              ScreenSection(
                title: 'AI read quality',
                subtitle:
                    'Check how confident the scan was before you save it.',
                compact: true,
                child: _buildConfidenceBanner(textTheme),
              ),
              ScreenSection(
                title: 'Transaction details',
                subtitle:
                    'Sanity-check the merchant, amount, category, and date.',
                compact: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FloatingLabelTextField(
                      controller: _merchantController,
                      label: 'Merchant',
                      textCapitalization: TextCapitalization.words,
                      prefix: AppIcons.icon(
                        AppIconKey.merchant,
                        color: colors.deepNavy,
                        size: 18,
                      ),
                      trailing: _needsReview
                          ? AppIcons.icon(
                              AppIconKey.sparkleGuidance,
                              color: colors.amber,
                              size: 18,
                            )
                          : null,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    AmountHeroField(
                      controller: _amountController,
                      focusNode: _amountFocusNode,
                      isExpense: true,
                      currencyCode: _currencyCode,
                      locale: ref.watch(userPreferencesProvider).locale,
                      isPremium: isPremium,
                      onChanged: (_) => setState(() {}),
                      onCurrencyChanged: (code) =>
                          setState(() => _currencyCode = code),
                    ),
                    const SizedBox(height: 14),
                    TransactionStyleCategorySelector(
                      selectedCategory: _selectedCategory,
                      isExpense: true,
                      isPremium: isPremium,
                      showHeader: false,
                      onCategorySelected: (cat) =>
                          setState(() => _selectedCategory = cat),
                    ),
                    const SizedBox(height: 14),
                    _ReceiptDateButton(
                      dateLabel: _formatDate(_date),
                      onPressed: _pickDate,
                    ),
                  ],
                ),
              ),
              if (_lineItems.isNotEmpty)
                ScreenSection(
                  title: 'Extracted items',
                  subtitle:
                      'Review the line items the scan picked up from the receipt.',
                  compact: true,
                  trailing: Text(
                    '${_lineItems.length} items',
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.softInk,
                    ),
                  ),
                  child: _buildLineItems(textTheme),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConfidenceBanner(TextTheme textTheme) {
    final colors = Theme.of(context).appColors;
    final percentage = (_confidence * 100).round();
    final isHigh = _confidence >= 0.9;
    final isMedium = _confidence >= 0.75 && !isHigh;

    final Color bannerColor;
    final Color textColor;
    final AppIconKey icon;
    final String label;

    if (isHigh) {
      bannerColor = colors.incomeSoft;
      textColor = colors.income;
      icon = AppIconKey.verified;
      label = 'High confidence ($percentage%)';
    } else if (isMedium) {
      bannerColor = colors.amberSoft;
      textColor = colors.devilAccent;
      icon = AppIconKey.info;
      label = 'Medium confidence ($percentage%) - please review';
    } else {
      bannerColor = colors.expenseSoft;
      textColor = colors.expense;
      icon = AppIconKey.warning;
      label = 'Low confidence ($percentage%) - manual review needed';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bannerColor,
        borderRadius: BorderRadius.circular(16),
      ),
        child: Row(
          children: [
          AppIcons.icon(
            icon,
            size: 20,
            color: textColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: textTheme.bodyMedium?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (_needsReview)
                  Text(
                    'Highlighted fields may need correction.',
                    style: textTheme.bodySmall?.copyWith(
                      color: textColor.withAlpha(190),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineItems(TextTheme textTheme) {
    final colors = Theme.of(context).appColors;
    return Column(
      children: [
        for (var i = 0; i < _lineItems.length; i++) ...[
          _buildLineItemTile(i, textTheme),
          Divider(height: 1, color: colors.border),
        ],
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colors.ink,
                ),
              ),
              Text(
                CurrencyFormatter.format(
                  LocalizedNumberInput.parseAmount(
                        _amountController.text,
                        locale: ref.read(userPreferencesProvider).locale,
                      ) ??
                      0,
                  currencyCode: _currencyCode,
                  locale: ref.watch(userPreferencesProvider).locale,
                ),
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colors.expense,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLineItemTile(
    int index,
    TextTheme textTheme,
  ) {
    final colors = Theme.of(context).appColors;
    final item = _lineItems[index];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              item.name,
              style: textTheme.bodyMedium?.copyWith(color: colors.ink),
            ),
          ),
          Text(
            CurrencyFormatter.format(
              item.amount,
              currencyCode: _currencyCode,
              locale: ref.watch(userPreferencesProvider).locale,
            ),
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: colors.ink,
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

  String _resolveCurrencyCode(Object? rawCurrencyCode) {
    final scanned = rawCurrencyCode is String ? rawCurrencyCode.trim() : '';
    if (scanned.isNotEmpty) return scanned.toUpperCase();
    return ref.read(userPreferencesProvider).currency;
  }
}

class _ReceiptReviewHero extends StatelessWidget {
  const _ReceiptReviewHero({
    required this.confidence,
    required this.needsReview,
    required this.merchant,
  });

  final double confidence;
  final bool needsReview;
  final String merchant;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).textTheme;
    final percentage = (confidence * 100).round();
    final merchantText = merchant.trim().isEmpty ? 'receipt' : merchant.trim();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        AppLayout.screenPadding,
        AppLayout.bleedingHeroTop(context),
        AppLayout.screenPadding,
        AppLayout.heroBottomPadding,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.navySoft.withAlpha(150),
            colors.paper,
            colors.amberSoft,
          ],
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'REVIEW SCAN',
            style: textTheme.labelSmall?.copyWith(
              color: colors.deepNavy,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Sanity-check what Conscia read.',
            style: textTheme.headlineSmall?.copyWith(
              color: colors.deepNavy,
              fontWeight: FontWeight.w800,
              height: 1.08,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Confirm the details from $merchantText before this becomes a transaction.',
            style: textTheme.bodyMedium?.copyWith(
              color: colors.ink,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              EditorialHeroChip(label: '$percentage% confidence'),
              EditorialHeroChip(
                label: needsReview ? 'Needs review' : 'Looks ready',
              ),
              const EditorialHeroChip(label: 'Editable'),
            ],
          ),
        ],
      ),
    );
  }
}

class _InlineErrorNote extends StatelessWidget {
  const _InlineErrorNote({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: colors.expenseSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          AppIcons.icon(
            AppIconKey.error,
            size: 17,
            color: colors.expense,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.expense,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptDateButton extends StatelessWidget {
  const _ReceiptDateButton({
    required this.dateLabel,
    required this.onPressed,
  });

  final String dateLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    return Material(
      color: colors.paper,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onPressed,
        child: Container(
          constraints: const BoxConstraints(minHeight: 54),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              AppIcons.icon(
                AppIconKey.calendar,
                size: 20,
                color: colors.deepNavy,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  dateLabel,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.ink,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
              AppIcons.icon(
                AppIconKey.chevronRight,
                color: colors.softInk,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LineItem {
  final String name;
  final double amount;

  const _LineItem(this.name, this.amount);
}
