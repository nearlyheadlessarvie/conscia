import 'package:flutter/material.dart';

import '../core/constants/generated/app_constants.g.dart';
import '../screens/settings/widgets/subscription_sheet.dart';
import 'conscia_bottom_sheet.dart';

class CurrencyPickerSheet {
  CurrencyPickerSheet._();

  static Future<void> show(
    BuildContext context, {
    required String selectedCode,
    required ValueChanged<String> onSelected,
    String? priorityCode,
    bool isPremium = false,
  }) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, controller) => _CurrencyPickerBody(
          selectedCode: selectedCode,
          onSelected: onSelected,
          scrollController: controller,
          priorityCode: priorityCode,
          isPremium: isPremium,
        ),
      ),
    );
  }
}

class _CurrencyPickerBody extends StatefulWidget {
  final String selectedCode;
  final ValueChanged<String> onSelected;
  final ScrollController scrollController;
  final String? priorityCode;
  final bool isPremium;

  const _CurrencyPickerBody({
    required this.selectedCode,
    required this.onSelected,
    required this.scrollController,
    this.priorityCode,
    this.isPremium = true,
  });

  @override
  State<_CurrencyPickerBody> createState() => _CurrencyPickerBodyState();
}

class _CurrencyPickerBodyState extends State<_CurrencyPickerBody> {
  String _query = '';

  List<CurrencyInfo> get _filtered {
    final currencies =
        _prioritizedCurrencies(widget.priorityCode ?? widget.selectedCode);
    if (_query.isEmpty) return currencies;
    final q = _query.toLowerCase();
    return currencies
        .where((c) =>
            c.code.toLowerCase().contains(q) ||
            c.name.toLowerCase().contains(q))
        .toList();
  }

  List<CurrencyInfo> _prioritizedCurrencies(String? priorityCode) {
    if (priorityCode == null || priorityCode.isEmpty) {
      return supportedCurrencies;
    }

    final priorityIndex = supportedCurrencies.indexWhere(
      (currency) => currency.code == priorityCode,
    );
    if (priorityIndex <= 0) {
      return supportedCurrencies;
    }

    final prioritized = supportedCurrencies[priorityIndex];
    return [
      prioritized,
      ...supportedCurrencies.where((currency) => currency.code != priorityCode),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      children: [
        const SizedBox(height: 8),
        const ConsciaSheetHandle(),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const ConsciaSheetHeader(
                title: 'Currency',
                subtitle:
                    'Choose the currency Conscia uses for new records and summaries.',
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search currencies...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: colors.surfaceContainerHighest,
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (!widget.isPremium)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Icon(Icons.workspace_premium,
                    size: 16, color: colors.secondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Free tier: 1 currency. Upgrade to Premium for multi-currency support.',
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    SubscriptionSheet.show(context);
                  },
                  child: const Text('Upgrade'),
                ),
              ],
            ),
          ),
        Expanded(
          child: ListView.builder(
            controller: widget.scrollController,
            itemCount: _filtered.length,
            itemBuilder: (context, index) {
              final currency = _filtered[index];
              final isSelected = currency.code == widget.selectedCode;
              final isLocked = !widget.isPremium && !isSelected;

              return ListTile(
                leading:
                    Text(currency.flag, style: const TextStyle(fontSize: 24)),
                title: Text(currency.code),
                subtitle: Text(currency.name),
                trailing: isSelected
                    ? Icon(Icons.check, color: colors.primary)
                    : isLocked
                        ? Icon(Icons.lock_outline,
                            size: 18, color: colors.outline)
                        : null,
                enabled: !isLocked,
                onTap: isLocked
                    ? null
                    : () {
                        widget.onSelected(currency.code);
                        Navigator.of(context).pop();
                      },
              );
            },
          ),
        ),
      ],
    );
  }
}
