import 'package:flutter/material.dart';

class CurrencyPickerSheet extends StatefulWidget {
  final String selectedCode;
  final ValueChanged<String> onSelected;

  const CurrencyPickerSheet({
    super.key,
    required this.selectedCode,
    required this.onSelected,
  });

  static Future<void> show(
    BuildContext context, {
    required String selectedCode,
    required ValueChanged<String> onSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, controller) => CurrencyPickerSheet._internal(
          selectedCode: selectedCode,
          onSelected: onSelected,
          scrollController: controller,
        ),
      ),
    );
  }

  static Widget _internal({
    required String selectedCode,
    required ValueChanged<String> onSelected,
    required ScrollController scrollController,
  }) {
    return _CurrencyPickerBody(
      selectedCode: selectedCode,
      onSelected: onSelected,
      scrollController: scrollController,
    );
  }

  @override
  State<CurrencyPickerSheet> createState() => _CurrencyPickerSheetState();
}

class _CurrencyPickerSheetState extends State<CurrencyPickerSheet> {
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _CurrencyPickerBody extends StatefulWidget {
  final String selectedCode;
  final ValueChanged<String> onSelected;
  final ScrollController scrollController;

  const _CurrencyPickerBody({
    required this.selectedCode,
    required this.onSelected,
    required this.scrollController,
  });

  @override
  State<_CurrencyPickerBody> createState() => _CurrencyPickerBodyState();
}

class _CurrencyPickerBodyState extends State<_CurrencyPickerBody> {
  String _query = '';

  static const _currencies = [
    ('USD', '\$', '🇺🇸', 'US Dollar'),
    ('EUR', '€', '🇪🇺', 'Euro'),
    ('GBP', '£', '🇬🇧', 'British Pound'),
    ('JPY', '¥', '🇯🇵', 'Japanese Yen'),
    ('MXN', '\$', '🇲🇽', 'Mexican Peso'),
    ('CAD', '\$', '🇨🇦', 'Canadian Dollar'),
    ('AUD', '\$', '🇦🇺', 'Australian Dollar'),
    ('CHF', 'Fr', '🇨🇭', 'Swiss Franc'),
    ('CNY', '¥', '🇨🇳', 'Chinese Yuan'),
    ('INR', '₹', '🇮🇳', 'Indian Rupee'),
    ('BRL', 'R\$', '🇧🇷', 'Brazilian Real'),
    ('KRW', '₩', '🇰🇷', 'South Korean Won'),
    ('SGD', '\$', '🇸🇬', 'Singapore Dollar'),
    ('HKD', '\$', '🇭🇰', 'Hong Kong Dollar'),
    ('SEK', 'kr', '🇸🇪', 'Swedish Krona'),
    ('NOK', 'kr', '🇳🇴', 'Norwegian Krone'),
    ('DKK', 'kr', '🇩🇰', 'Danish Krone'),
    ('NZD', '\$', '🇳🇿', 'New Zealand Dollar'),
    ('ZAR', 'R', '🇿🇦', 'South African Rand'),
    ('COP', '\$', '🇨🇴', 'Colombian Peso'),
    ('ARS', '\$', '🇦🇷', 'Argentine Peso'),
    ('CLP', '\$', '🇨🇱', 'Chilean Peso'),
    ('PEN', 'S/', '🇵🇪', 'Peruvian Sol'),
  ];

  List<(String, String, String, String)> get _filtered {
    if (_query.isEmpty) return _currencies;
    final q = _query.toLowerCase();
    return _currencies
        .where((c) =>
            c.$1.toLowerCase().contains(q) ||
            c.$4.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      children: [
        const SizedBox(height: 8),
        Container(
          width: 32,
          height: 4,
          decoration: BoxDecoration(
            color: colors.outlineVariant,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
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
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            controller: widget.scrollController,
            itemCount: _filtered.length,
            itemBuilder: (context, index) {
              final currency = _filtered[index];
              final isSelected = currency.$1 == widget.selectedCode;

              return ListTile(
                leading: Text(currency.$3, style: const TextStyle(fontSize: 24)),
                title: Text(currency.$1),
                subtitle: Text(currency.$4),
                trailing: isSelected
                    ? Icon(Icons.check, color: colors.primary)
                    : null,
                onTap: () {
                  widget.onSelected(currency.$1);
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
