import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../screens/assistant/widgets/ai_message_bubble.dart';
import 'widgets/transaction_tile.dart';

// ── Mock data ───────────────────────────────────────────────────────────

class _MockLocation {
  final String? merchantName;
  final double lat;
  final double lon;
  const _MockLocation(this.merchantName, this.lat, this.lon);
}

final _mockDetail = (
  id: '1',
  isIncome: false,
  amount: 45.20,
  currencyCode: 'USD',
  category: 'Groceries',
  merchant: 'Walmart',
  date: DateTime.now(),
  regretLevel: 1 as int?,
  location: const _MockLocation('Walmart Supercenter', 34.0522, -118.2437)
      as _MockLocation?,
);

class TransactionDetailScreen extends ConsumerStatefulWidget {
  final String transactionId;

  const TransactionDetailScreen({
    super.key,
    required this.transactionId,
  });

  @override
  ConsumerState<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState
    extends ConsumerState<TransactionDetailScreen> {
  int? _regretLevel;
  bool _loadingReflection = false;

  @override
  void initState() {
    super.initState();
    _regretLevel = _mockDetail.regretLevel;
  }

  Color _amountColor(ColorScheme colors) {
    if (!_mockDetail.isIncome) {
      return colors.brightness == Brightness.light
          ? const Color(0xFFE53935)
          : const Color(0xFFEF9A9A);
    }
    return colors.brightness == Brightness.light
        ? const Color(0xFF4CAF50)
        : const Color(0xFF81C784);
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this transaction?'),
        content: const Text("This can't be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              // TODO: DELETE API call
              context.pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Transaction deleted')),
              );
            },
            child: Text(
              'Delete',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  void _askAiReflection() async {
    setState(() => _loadingReflection = true);

    // TODO: wire to POST /api/v1/transactions/:id/reflect
    await Future<void>.delayed(const Duration(seconds: 1));

    if (!mounted) return;
    setState(() => _loadingReflection = false);
    _showReflectionSheet();
  }

  void _showReflectionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, scrollController) => _ReflectionSheet(
          scrollController: scrollController,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final prefix = _mockDetail.isIncome ? '+' : '-';
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                context.push('/transactions/${widget.transactionId}/edit');
              } else if (value == 'delete') {
                _confirmDelete();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            const SizedBox(height: 16),

            // Hero Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: colors.primaryContainer,
                      child: Icon(
                        TransactionTile.iconFor(_mockDetail.category),
                        size: 32,
                        color: colors.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _mockDetail.merchant ?? 'Unknown',
                      style: textTheme.headlineLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$prefix${formatter.format(_mockDetail.amount)} ${_mockDetail.currencyCode}',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: _amountColor(colors),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_mockDetail.isIncome ? "Income" : "Expense"} · ${_mockDetail.category}',
                      style: textTheme.bodyLarge?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat.yMMMd()
                              .add_jm()
                              .format(_mockDetail.date),
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Location Card
            if (_mockDetail.location != null) ...[
              Card(
                color: colors.surfaceContainerHighest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.location_on, size: 20, color: colors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _mockDetail.location!.merchantName ?? 'Location',
                              style: textTheme.titleSmall,
                            ),
                            Text(
                              '${_mockDetail.location!.lat.toStringAsFixed(4)}\u00B0 N, '
                              '${_mockDetail.location!.lon.abs().toStringAsFixed(4)}\u00B0 W',
                              style: textTheme.bodySmall?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Regret Level
            _buildRegretSection(colors, textTheme),

            const SizedBox(height: 24),

            // AI Reflection Button
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonal(
                onPressed: _loadingReflection ? null : _askAiReflection,
                child: _loadingReflection
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome, size: 20),
                          SizedBox(width: 8),
                          Text('Ask AI to Reflect'),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildRegretSection(ColorScheme colors, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('How did this purchase feel?', style: textTheme.titleMedium),
        const SizedBox(height: 12),
        if (_regretLevel != null)
          _buildRegretChip(colors)
        else
          _buildRegretPicker(colors),
      ],
    );
  }

  Widget _buildRegretChip(ColorScheme colors) {
    final (icon, label, color) = _regretData(_regretLevel!);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Chip(
          avatar: Icon(icon, color: color, size: 18),
          label: Text(label),
          backgroundColor: color.withOpacity(0.15),
          side: BorderSide.none,
        ),
        TextButton(
          onPressed: () => setState(() => _regretLevel = null),
          child: const Text('Change'),
        ),
      ],
    );
  }

  Widget _buildRegretPicker(ColorScheme colors) {
    const greenColor = Color(0xFF4CAF50);
    const amberColor = Color(0xFFFFC107);
    const redColor = Color(0xFFE53935);

    return Row(
      children: [
        Expanded(
          child: FilledButton.tonal(
            onPressed: () => setState(() => _regretLevel = 1),
            style: FilledButton.styleFrom(
              backgroundColor: greenColor.withOpacity(0.15),
              foregroundColor: greenColor,
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sentiment_satisfied_alt, size: 18),
                SizedBox(width: 4),
                Text('Worth It'),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: FilledButton.tonal(
            onPressed: () => setState(() => _regretLevel = 2),
            style: FilledButton.styleFrom(
              backgroundColor: amberColor.withOpacity(0.15),
              foregroundColor: amberColor,
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sentiment_neutral, size: 18),
                SizedBox(width: 4),
                Text('Not Sure'),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: FilledButton.tonal(
            onPressed: () => setState(() => _regretLevel = 3),
            style: FilledButton.styleFrom(
              backgroundColor: redColor.withOpacity(0.15),
              foregroundColor: redColor,
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sentiment_dissatisfied, size: 18),
                SizedBox(width: 4),
                Text('Regret'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  (IconData, String, Color) _regretData(int level) {
    if (level <= 1) {
      return (Icons.sentiment_satisfied_alt, 'Worth It', const Color(0xFF4CAF50));
    }
    if (level == 2) {
      return (Icons.sentiment_neutral, 'Not Sure', const Color(0xFFFFC107));
    }
    return (Icons.sentiment_dissatisfied, 'Regret', const Color(0xFFE53935));
  }
}

// ── AI Reflection Bottom Sheet ──────────────────────────────────────────

class _ReflectionSheet extends StatelessWidget {
  final ScrollController scrollController;

  const _ReflectionSheet({required this.scrollController});

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
        Expanded(
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            children: const [
              SizedBox(height: 8),
              AiMessageBubble(
                type: BubbleType.devil,
                message:
                    "Come on, that purchase was totally worth it. You work hard and deserve nice things!",
              ),
              SizedBox(height: 12),
              AiMessageBubble(
                type: BubbleType.angel,
                message:
                    "Let's look at the numbers. This category is trending 15% above your monthly average. Consider whether this aligns with your financial goals.",
              ),
              SizedBox(height: 12),
              AiMessageBubble(
                type: BubbleType.neutral,
                message:
                    "What would change if you waited 24 hours before making similar purchases? Sometimes a cooling-off period reveals whether it's a need or a want.",
              ),
            ],
          ),
        ),
      ],
    );
  }
}
