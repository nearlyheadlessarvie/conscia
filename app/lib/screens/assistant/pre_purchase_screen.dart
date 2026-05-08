import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/routing/app_router.dart';
import '../../core/constants/generated/app_constants.g.dart';
import '../../core/constants/category_icons.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/voice_input_parser.dart';
import '../../providers/ai_provider.dart';
import '../../providers/category_recents_provider.dart';
import '../../providers/location_assistance_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../providers/usage_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/ai_service.dart';
import '../../widgets/amount_input_field.dart';
import '../../widgets/conscience_mark.dart';
import '../../widgets/hero_screen_scaffold.dart';
import '../../widgets/location_assistance_prompt_sheet.dart';
import '../../widgets/premium_upgrade_dialog.dart';
import '../../widgets/screen_section.dart';
import '../../widgets/smart_suggestions_card.dart';
import '../transactions/widgets/transaction_style_category_selector.dart';
import '../transactions/widgets/voice_input_button.dart';
import 'widgets/ai_message_bubble.dart';
import 'widgets/budget_context_card.dart';
import 'widgets/typing_indicator.dart';

enum _ScreenState { input, loading, response, error }

class PrePurchaseScreen extends ConsumerStatefulWidget {
  const PrePurchaseScreen({super.key});

  @override
  ConsumerState<PrePurchaseScreen> createState() => _PrePurchaseScreenState();
}

class _PrePurchaseScreenState extends ConsumerState<PrePurchaseScreen>
    with TickerProviderStateMixin {
  _ScreenState _state = _ScreenState.input;
  AIResponse? _aiResponse;
  String? _errorMessage;
  bool _hasCheckedLocationPrompt = false;

  // Form
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  String _currencyCode = 'USD';
  bool _currencyManuallyChanged = false;
  String? _selectedCategory;

  // Animations for response bubbles
  late AnimationController _devilAnim;
  late AnimationController _angelAnim;
  late AnimationController _neutralAnim;

  @override
  void initState() {
    super.initState();
    _currencyCode = ref.read(userPreferencesProvider).currency;
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybePromptForLocationAssistance();
    });
  }

  Future<void> _maybePromptForLocationAssistance() async {
    if (_hasCheckedLocationPrompt || !mounted) {
      return;
    }
    _hasCheckedLocationPrompt = true;

    final state = ref.read(locationAssistanceProvider);
    if (!state.shouldPromptOnFeatureOpen) return;

    final accepted = await LocationAssistancePromptSheet.show(context);

    if (!mounted) return;

    final notifier = ref.read(locationAssistanceProvider.notifier);
    if (accepted ?? false) {
      await notifier.enableFromPrompt();
    } else {
      await notifier.declinePrompt();
    }
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

  void _applyVoiceTranscript(String transcript) {
    final parsed = VoiceInputParser.parse(
      transcript,
      categories: expenseCategories,
    );

    setState(() {
      if (parsed.counterparty case final description?
          when description.trim().isNotEmpty) {
        _descriptionController.text = description;
      }
      if (parsed.amount != null) {
        _amountController.text = parsed.amount!.toStringAsFixed(0);
      }
      if (parsed.category != null) {
        _selectedCategory = parsed.category;
      }
    });

    if (parsed.category != null) {
      ref.read(recentCategoryProvider.notifier).record(parsed.category!);
    }

    if (!mounted) return;
    final detected = [
      if (parsed.amount != null) 'amount',
      if (parsed.category != null) 'category',
      if (parsed.counterparty != null) 'details',
    ];
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          detected.isEmpty
              ? 'Voice note captured. You can edit the fields manually.'
              : 'Filled ${detected.join(', ')} from voice.',
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formValid) return;

    final isPremium =
        ref.read(subscriptionProvider).valueOrNull?.isPremium ?? false;
    final usage = ref.read(monthlyUsageProvider);
    if (!isPremium && usage.aiAssists >= FreemiumLimits.freeAiAssistsPerMonth) {
      PremiumUpgradeDialog.show(
        context,
        feature:
            'You\'ve used all ${FreemiumLimits.freeAiAssistsPerMonth} free AI assists this month.',
      );
      return;
    }

    setState(() {
      _state = _ScreenState.loading;
      _errorMessage = null;
    });

    try {
      final aiService = ref.read(aiServiceProvider);
      final response = await aiService.prePurchase(
        description: _descriptionController.text,
        amount: double.parse(_amountController.text),
        currencyCode: _currencyCode,
        category: _selectedCategory!,
      );

      if (!mounted) return;
      ref.read(monthlyUsageProvider.notifier).recordAiAssist();
      _aiResponse = response;
      setState(() => _state = _ScreenState.response);
      _playEntrance();
    } on DioException catch (e) {
      if (!mounted) return;
      if (e.response?.statusCode == 403) {
        setState(() => _state = _ScreenState.input);
        final data = e.response?.data as Map<String, dynamic>?;
        PremiumUpgradeDialog.show(
          context,
          feature: data?['error'] as String? ??
              'You\'ve reached the free tier limit for AI assists.',
        );
        return;
      }
      setState(() {
        _state = _ScreenState.error;
        _errorMessage = e.response?.data?['error'] as String? ?? e.toString();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _state = _ScreenState.error;
        _errorMessage = e.toString();
      });
    }
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
      _currencyManuallyChanged = false;
      _currencyCode = ref.read(userPreferencesProvider).currency;
      _selectedCategory = null;
      _aiResponse = null;
      _errorMessage = null;
      _state = _ScreenState.input;
    });
  }

  Future<void> _openExpenseConfirmation() async {
    final suggestions = ref.read(locationAssistanceSuggestionsProvider);
    final inferredCounterparty = suggestions.nearbyMerchants.isNotEmpty
        ? suggestions.nearbyMerchants.first
        : null;

    await context.push(
      AppRoutes.addTransaction,
      extra: <String, String?>{
        'amount': _amountController.text,
        'currencyCode': _currencyCode,
        'category': _selectedCategory,
        'counterparty': inferredCounterparty,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final preferredCurrency = ref.watch(userPreferencesProvider).currency;

    if (!_currencyManuallyChanged && _currencyCode != preferredCurrency) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _currencyManuallyChanged) return;
        setState(() => _currencyCode = preferredCurrency);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pre-Purchase Assistant'),
      ),
      body: switch (_state) {
        _ScreenState.input => _buildInputForm(),
        _ScreenState.loading => _buildLoading(),
        _ScreenState.response => _buildResponse(),
        _ScreenState.error => _buildError(),
      },
    );
  }

  // ── Input Form ──────────────────────────────────────────────────────

  Widget _buildInputForm() {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final isPremium =
        ref.watch(subscriptionProvider).valueOrNull?.isPremium ?? false;
    final locationAssistance = ref.watch(locationAssistanceProvider);
    final suggestions = ref.watch(locationAssistanceSuggestionsProvider);
    final hasSuggestions = suggestions.nearbyMerchants.isNotEmpty ||
        suggestions.likelyCategories.isNotEmpty;

    return HeroScreenScaffold(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      bottom: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: _formValid ? _submit : null,
          icon: const Icon(Icons.auto_awesome),
          label: const Text('Ask Conscia'),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          const ConsciaAlterEgoMotion(
            preset: ConsciaAlterEgoPreset.idle,
            size: 110,
          ),
          const SizedBox(height: 18),
          Text(
            "Let's think this through",
            style: textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'A little impulse. A little reason. A clearer next move.',
            style: textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),

          // Description
          TextField(
            controller: _descriptionController,
            maxLines: 1,
            decoration: InputDecoration(
              labelText: 'What are you thinking of buying?',
              suffixIcon: VoiceInputButton(
                onTranscriptReady: _applyVoiceTranscript,
              ),
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
            onChanged: (_) => setState(() {}),
            onCurrencyChanged: (code) => setState(() {
              _currencyManuallyChanged = true;
              _currencyCode = code;
            }),
          ),
          const SizedBox(height: 16),

          ScreenSection(
            title: 'Category',
            subtitle:
                'Give Conscia a category so the tradeoff can stay grounded in your real spending.',
            compact: true,
            child: TransactionStyleCategorySelector(
              selectedCategory: _selectedCategory,
              isExpense: true,
              isPremium: isPremium,
              showHeader: false,
              onCategorySelected: (category) {
                setState(() => _selectedCategory = category);
                if (category != null) {
                  ref.read(recentCategoryProvider.notifier).record(category);
                }
              },
            ),
          ),
          if (locationAssistance.isEnabled && hasSuggestions) ...[
            SmartSuggestionsCard(
              suggestions: suggestions,
              subtitle:
                  'Need a nudge? Try a nearby merchant or likely category, then edit anything you want.',
              onMerchantSelected: (merchant) {
                setState(() {
                  _descriptionController.text = merchant;
                });
              },
              onCategorySelected: (category) {
                setState(() {
                  _selectedCategory = category;
                });
                ref.read(recentCategoryProvider.notifier).record(category);
              },
              categoryAvatarBuilder: (category) => CategoryIcons.badge(
                category,
                size: 14,
              ),
            ),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ── Loading ─────────────────────────────────────────────────────────

  Widget _buildLoading() {
    return Column(
      children: [
        _buildSummaryCard(),
        const Spacer(),
        const TypingIndicator(
          label: 'Your conscience is weighing both sides...',
        ),
        const Spacer(),
      ],
    );
  }

  // ── Response ────────────────────────────────────────────────────────

  Widget _buildResponse() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    final response = _aiResponse!;
    final locale = ref.watch(userPreferencesProvider).locale;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildSummaryCard(),
          const SizedBox(height: 16),
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
              child: AiMessageBubble(
                type: BubbleType.devil,
                message: response.impulse,
              ),
            ),
          ),
          const SizedBox(height: 12),
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
              child: AiMessageBubble(
                type: BubbleType.angel,
                message: response.reason,
              ),
            ),
          ),
          const SizedBox(height: 12),
          FadeTransition(
            opacity: _neutralAnim,
            child: AiMessageBubble(
              type: BubbleType.neutral,
              message: response.neutral,
            ),
          ),
          const SizedBox(height: 16),
          if (_selectedCategory != null && response.budget != null)
            BudgetContextCard(
              category: _selectedCategory!,
              spent: response.budget!.currentSpend,
              limit: response.budget!.monthlyLimit,
              currencyCode: _currencyCode,
              locale: locale,
              projectedAmount: amount,
            ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _openExpenseConfirmation,
              child: const Text('Bought it anyway'),
            ),
          ),
          const SizedBox(height: 12),
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

  Widget _buildError() {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: colors.error),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Please try again.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _reset,
              child: const Text('Start Over'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Summary Card ────────────────────────────────────────────────────

  Widget _buildSummaryCard() {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final locale = ref.watch(userPreferencesProvider).locale;
    final amount = double.tryParse(_amountController.text) ?? 0;
    final amountText = CurrencyFormatter.format(
      amount,
      currencyCode: _currencyCode,
      locale: locale,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Card(
        color: colors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: colors.outlineVariant.withValues(alpha: 0.8),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
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
                amountText,
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
                CategoryIcons.badge(
                  _selectedCategory!,
                  size: 14,
                  filled: false,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
