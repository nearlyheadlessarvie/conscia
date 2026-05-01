import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../widgets/amount_input_field.dart';
import '../../screens/transactions/widgets/category_picker.dart';
import '../../screens/transactions/widgets/transaction_tile.dart';
import 'widgets/ai_message_bubble.dart';
import 'widgets/budget_context_card.dart';
import 'widgets/typing_indicator.dart';

enum _ScreenState { input, loading, response }

// Mock AI response
class _MockAiResponse {
  final String devil;
  final String angel;
  final String neutral;
  final bool hasBudget;

  const _MockAiResponse({
    required this.devil,
    required this.angel,
    required this.neutral,
    this.hasBudget = true,
  });
}

const _mockResponse = _MockAiResponse(
  devil:
      "Life's too short to overthink every purchase! If it makes you happy and you can technically afford it, just go for it. You deserve it!",
  angel:
      "Let's pause and think. This would use a significant chunk of your entertainment budget. Could you wait until next month, or find a more affordable alternative?",
  neutral:
      "Consider this: will this purchase matter to you in 30 days? If yes, it might be worth it. If you're unsure, sleeping on it rarely hurts.",
);

class PrePurchaseScreen extends ConsumerStatefulWidget {
  const PrePurchaseScreen({super.key});

  @override
  ConsumerState<PrePurchaseScreen> createState() => _PrePurchaseScreenState();
}

class _PrePurchaseScreenState extends ConsumerState<PrePurchaseScreen>
    with TickerProviderStateMixin {
  _ScreenState _state = _ScreenState.input;

  // Form
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  String _currencyCode = 'USD';
  String? _selectedCategory;

  // Animations for response bubbles
  late AnimationController _devilAnim;
  late AnimationController _angelAnim;
  late AnimationController _neutralAnim;

  @override
  void initState() {
    super.initState();
    _devilAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _angelAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _neutralAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _devilAnim.dispose();
    _angelAnim.dispose();
    _neutralAnim.dispose();
    super.dispose();
  }

  bool get _formValid {
    final amount = double.tryParse(_amountController.text);
    return _descriptionController.text.isNotEmpty &&
        amount != null &&
        amount > 0 &&
        _selectedCategory != null;
  }

  Future<void> _submit() async {
    if (!_formValid) return;
    setState(() => _state = _ScreenState.loading);

    // TODO: wire to POST /api/v1/ai/pre-purchase
    await Future<void>.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    setState(() => _state = _ScreenState.response);
    _playEntrance();
  }

  Future<void> _playEntrance() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    _devilAnim.forward();
    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    _angelAnim.forward();
    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    _neutralAnim.forward();
  }

  void _reset() {
    _devilAnim.reset();
    _angelAnim.reset();
    _neutralAnim.reset();
    _descriptionController.clear();
    _amountController.clear();
    setState(() {
      _selectedCategory = null;
      _state = _ScreenState.input;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pre-Purchase Assistant'),
      ),
      body: switch (_state) {
        _ScreenState.input => _buildInputForm(),
        _ScreenState.loading => _buildLoading(),
        _ScreenState.response => _buildResponse(),
      },
    );
  }

  // ── Input Form ──────────────────────────────────────────────────────

  Widget _buildInputForm() {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 24),
          // Illustration: overlapping circle avatars
          SizedBox(
            height: 72,
            width: 110,
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  child: CircleAvatar(
                    radius: 32,
                    backgroundColor: const Color(0xFFFFB300).withOpacity(0.2),
                    child: const Icon(
                      Icons.local_fire_department,
                      size: 28,
                      color: Color(0xFFE65100),
                    ),
                  ),
                ),
                Positioned(
                  left: 44,
                  child: CircleAvatar(
                    radius: 32,
                    backgroundColor: const Color(0xFF00BCD4).withOpacity(0.2),
                    child: const Icon(
                      Icons.shield,
                      size: 28,
                      color: Color(0xFF00838F),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Let's think this through",
            style: textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Description
          TextField(
            controller: _descriptionController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'What are you thinking of buying?',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),

          // Amount
          AmountInputField(
            controller: _amountController,
            isExpense: true,
            currencyCode: _currencyCode,
            onCurrencyChanged: (code) =>
                setState(() => _currencyCode = code),
          ),
          const SizedBox(height: 16),

          // Category dropdown
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            decoration: const InputDecoration(
              labelText: 'Category',
            ),
            items: allCategories
                .map((c) => DropdownMenuItem(
                      value: c.name,
                      child: Row(
                        children: [
                          Icon(c.icon, size: 20),
                          const SizedBox(width: 8),
                          Text(c.name),
                        ],
                      ),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _selectedCategory = v),
          ),
          const SizedBox(height: 24),

          // CTA
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _formValid ? _submit : null,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Ask My Conscience'),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── Loading ─────────────────────────────────────────────────────────

  Widget _buildLoading() {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return Column(
      children: [
        _buildSummaryCard(),
        const Spacer(),
        const TypingIndicator(),
        const SizedBox(height: 12),
        Text(
          'Your conscience is thinking...',
          style: textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        const Spacer(),
      ],
    );
  }

  // ── Response ────────────────────────────────────────────────────────

  Widget _buildResponse() {
    final amount = double.tryParse(_amountController.text) ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildSummaryCard(),
          const SizedBox(height: 16),

          // Devil bubble — slides from left
          SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(-1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: _devilAnim,
              curve: Curves.easeOutCubic,
            )),
            child: FadeTransition(
              opacity: _devilAnim,
              child: const AiMessageBubble(
                type: BubbleType.devil,
                message: _mockResponse.devil,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Angel bubble — slides from right
          SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: _angelAnim,
              curve: Curves.easeOutCubic,
            )),
            child: FadeTransition(
              opacity: _angelAnim,
              child: const AiMessageBubble(
                type: BubbleType.angel,
                message: _mockResponse.angel,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Neutral bubble — fades in
          FadeTransition(
            opacity: _neutralAnim,
            child: const AiMessageBubble(
              type: BubbleType.neutral,
              message: _mockResponse.neutral,
            ),
          ),
          const SizedBox(height: 16),

          // Budget context card (mock)
          if (_mockResponse.hasBudget && _selectedCategory != null)
            BudgetContextCard(
              category: _selectedCategory!,
              spent: 340,
              limit: 500,
              currencyCode: _currencyCode,
              projectedAmount: amount,
            ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _reset,
              child: const Text('Ask About Something Else'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ── Summary Card ────────────────────────────────────────────────────

  Widget _buildSummaryCard() {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final amountText = _amountController.text.isEmpty
        ? '0.00'
        : _amountController.text;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Card(
        color: colors.surfaceContainerHighest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _descriptionController.text,
                  style: textTheme.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '·',
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '\$$amountText $_currencyCode',
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (_selectedCategory != null) ...[
                const SizedBox(width: 8),
                Text(
                  '·',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  TransactionTile.iconFor(_selectedCategory!),
                  size: 18,
                  color: colors.onSurfaceVariant,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
