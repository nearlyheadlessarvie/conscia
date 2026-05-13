import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/routing/app_router.dart';
import '../../core/assets/mascot_sprite_sheet.dart';
import '../../core/constants/generated/app_constants.g.dart';
import '../../core/constants/category_icons.dart';
import '../../core/errors/app_error.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/voice_input_parser.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/ai_provider.dart';
import '../../providers/family_space_provider.dart';
import '../../providers/insight_feed_provider.dart';
import '../../providers/category_recents_provider.dart';
import '../../providers/location_assistance_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../providers/usage_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/ai_service.dart';
import '../../widgets/conscience_mark.dart';
import '../../widgets/hero_screen_scaffold.dart';
import '../../widgets/location_assistance_prompt_sheet.dart';
import '../../widgets/premium_upgrade_dialog.dart';
import '../../widgets/smart_suggestions_card.dart';
import '../transactions/widgets/transaction_style_category_selector.dart';
import '../transactions/widgets/voice_input_button.dart';
import 'widgets/budget_context_card.dart';
import '../../widgets/amount_hero_field.dart';
import '../../../widgets/scope_pill_switch.dart';

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
  String _selectedContextScope = 'personal';

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
      String? insightContext;
      try {
        insightContext =
            (await ref.read(dashboardInsightSummaryProvider.future))?.text;
      } catch (_) {
        insightContext = null;
      }
      final response = await aiService.prePurchase(
        description: _descriptionController.text,
        amount: double.parse(_amountController.text),
        currencyCode: _currencyCode,
        category: _selectedCategory!,
        insightContext: insightContext,
        contextScope: _selectedContextScope,
      );

      if (!mounted) return;
      ref.read(monthlyUsageProvider.notifier).recordAiAssist();
      _aiResponse = response;
      setState(() => _state = _ScreenState.response);
      _playEntrance();
    } on DioException catch (e, s) {
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
        _errorMessage = AppError.from(e, stackTrace: s).userMessage;
      });
    } catch (e, s) {
      if (!mounted) return;
      setState(() {
        _state = _ScreenState.error;
        _errorMessage = AppError.from(e, stackTrace: s).userMessage;
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
      _selectedContextScope = 'personal';
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
        title: const Text('Purchase Assistant'),
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
    final colors = Theme.of(context).appColors;
    final isPremium =
        ref.watch(subscriptionProvider).valueOrNull?.isPremium ?? false;
    final locationAssistance = ref.watch(locationAssistanceProvider);
    final suggestions = ref.watch(locationAssistanceSuggestionsProvider);
    final familySpace = ref.watch(familySpaceProvider).valueOrNull;
    final hasSuggestions = suggestions.nearbyMerchants.isNotEmpty ||
        suggestions.likelyCategories.isNotEmpty;

    if (familySpace == null && _selectedContextScope != 'personal') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedContextScope = 'personal');
      });
    }

    return HeroScreenScaffold(
      scrollViewKey: const PageStorageKey('assistant-shell-scroll'),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      bottom: FilledButton(
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
        ),
        onPressed: _formValid ? _submit : null,
        child: const Text('Ask Conscia '),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colors.deepNavy,
                  colors.family,
                ],
              ),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              children: [
                const ConsciaAlterEgoMotion(
                  preset: ConsciaAlterEgoPreset.idle,
                  size: 64,
                ),
                const SizedBox(height: 5),
                Text(
                  "Let's think this through",
                  style: textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Conscia will give you a devil\'s impulse, an angel\'s reason, and a neutral take to help you make smarter purchase decisions.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.86),
                    height: 1.35,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          if (familySpace != null) ...[
            const SizedBox(height: 8),
            ScopePillSwitch(
              value: _selectedContextScope,
              familyEnabled: true,
              onChanged: (scope) =>
                  setState(() => _selectedContextScope = scope),
            ),
            const SizedBox(height: 18),
          ],
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
          const SizedBox(height: 18),
          AmountHeroField(
            controller: _amountController,
            currencyCode: _currencyCode,
            isExpense: true,
            isPremium: isPremium,
            onChanged: (_) => setState(() {}),
            onCurrencyChanged: (code) => setState(() {
              _currencyManuallyChanged = true;
              _currencyCode = code;
            }),
          ),
          const SizedBox(height: 18),

          TransactionStyleCategorySelector(
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
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).textTheme;
    return HeroScreenScaffold(
      appBar: AppBar(title: const Text('Conscience Check')),
      child: Padding(
        padding: const EdgeInsets.only(top: 24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 236,
                height: 126,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      left: 18,
                      top: 6,
                      child: MascotSpriteFrame(
                        atlas: angelMascotAtlas,
                        frameName: '4_win.png',
                        width: 76,
                      ),
                    ),
                    Positioned(
                      top: 34,
                      child: Text('⚔️', style: TextStyle(fontSize: 58)),
                    ),
                    Positioned(
                      right: 18,
                      top: 6,
                      child: MascotSpriteFrame(
                        atlas: devilMascotAtlas,
                        frameName: '5_win.png',
                        width: 76,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      child: Text('💰', style: TextStyle(fontSize: 36)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),
              Text(
                'Letting both sides make their case...',
                textAlign: TextAlign.center,
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Angel and Devil are reviewing your ${CurrencyFormatter.format(double.tryParse(_amountController.text) ?? 0, currencyCode: _currencyCode)} ${_descriptionController.text.trim()} decision.',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.mutedInk,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 22),
              const ConscienceLoader(
                size: 48,
                preset: ConscienceLoaderPreset.assistant,
                label: 'Your conscience is weighing both sides...',
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Response ────────────────────────────────────────────────────────

  Widget _buildResponse() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    final response = _aiResponse!;
    final locale = ref.watch(userPreferencesProvider).locale;

    return HeroScreenScaffold(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      appBar: AppBar(title: const Text('The verdict')),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _VerdictCard(
            tone: _VerdictTone.devil,
            title: 'The Devil says',
            message: response.impulse,
            animation: _devilAnim,
          ),
          const SizedBox(height: 12),
          _VerdictCard(
            tone: _VerdictTone.angel,
            title: 'The Angel says',
            message: response.reason,
            animation: _angelAnim,
          ),
          const SizedBox(height: 12),
          _ConsciaTakeCard(
            message: response.neutral,
            contextLabel: _selectedContextScope == 'family'
                ? 'Family advice'
                : 'Personal advice',
            amount: amount,
            currencyCode: _currencyCode,
            onBuy: _openExpenseConfirmation,
            onWait: _reset,
            onSkip: _reset,
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
        ],
      ),
    );
  }

/*
enum _VerdictTone { devil, angel }

class _VerdictCard extends StatelessWidget {
  const _VerdictCard({
    required this.tone,
    required this.title,
    required this.message,
    required this.animation,
  });

  final _VerdictTone tone;
  final String title;
  final String message;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final isDevil = tone == _VerdictTone.devil;
    final bg = isDevil ? colors.devilSoft : colors.angelSoft;
    final accent = isDevil ? colors.devilAccent : colors.angelAccent;
    final atlas = isDevil ? devilMascotAtlas : angelMascotAtlas;
    final frame = isDevil ? '5_win.png' : '4_win.png';

    return FadeTransition(
      opacity: animation,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: accent.withValues(alpha: 0.34)),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                MascotSpriteFrame(
                  atlas: atlas,
                  frameName: frame,
                  width: 38,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '"$message"',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.45,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConsciaTakeCard extends StatelessWidget {
  const _ConsciaTakeCard({
    required this.message,
    required this.contextLabel,
    required this.amount,
    required this.currencyCode,
    required this.onBuy,
    required this.onWait,
    required this.onSkip,
  });

  final String message;
  final String contextLabel;
  final double amount;
  final String currencyCode;
  final VoidCallback onBuy;
  final VoidCallback onWait;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.amberSoft,
        border: Border.all(color: colors.amber.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '✦',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: colors.ink,
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Conscia's take",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colors.deepNavy,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.45,
                ),
          ),
          const SizedBox(height: 16),
          Chip(
            label: Text(contextLabel),
            avatar: const Icon(Icons.auto_awesome, size: 16),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: onBuy,
                  child: const Text('Buy it ✓'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: onWait,
                  child: const Text('Wait 24h'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: onSkip,
                  child: const Text('Skip'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

*/
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
}

enum _VerdictTone { devil, angel }

class _VerdictCard extends StatelessWidget {
  const _VerdictCard({
    required this.tone,
    required this.title,
    required this.message,
    required this.animation,
  });

  final _VerdictTone tone;
  final String title;
  final String message;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final isDevil = tone == _VerdictTone.devil;
    final bg = isDevil ? colors.devilSoft : colors.angelSoft;
    final accent = isDevil ? colors.devilAccent : colors.angelAccent;
    final atlas = isDevil ? devilMascotAtlas : angelMascotAtlas;
    final frame = isDevil ? '5_win.png' : '4_win.png';

    return FadeTransition(
      opacity: animation,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: accent.withValues(alpha: 0.34)),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                MascotSpriteFrame(
                  atlas: atlas,
                  frameName: frame,
                  width: 38,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '"$message"',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.45,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConsciaTakeCard extends StatelessWidget {
  const _ConsciaTakeCard({
    required this.message,
    required this.contextLabel,
    required this.amount,
    required this.currencyCode,
    required this.onBuy,
    required this.onWait,
    required this.onSkip,
  });

  final String message;
  final String contextLabel;
  final double amount;
  final String currencyCode;
  final VoidCallback onBuy;
  final VoidCallback onWait;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.amberSoft,
        border: Border.all(color: colors.amber.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '*',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: colors.ink,
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Conscia's take",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colors.deepNavy,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.45,
                ),
          ),
          const SizedBox(height: 16),
          Chip(
            label: Text(contextLabel),
            avatar: const Icon(Icons.auto_awesome, size: 16),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: onBuy,
                  child: const Text('Buy it'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: onWait,
                  child: const Text('Wait 24h'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: onSkip,
                  child: const Text('Skip'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
