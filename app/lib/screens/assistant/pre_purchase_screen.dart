import 'dart:async';

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
import '../../widgets/thinking_cloud.dart';
import '../../widgets/location_assistance_prompt_sheet.dart';
import '../../widgets/premium_upgrade_dialog.dart';
import '../../widgets/smart_suggestions_card.dart';
import '../transactions/widgets/transaction_style_category_selector.dart';
import '../transactions/widgets/voice_input_button.dart';
import 'widgets/budget_context_card.dart';
import '../../widgets/amount_hero_field.dart';
import '../../../widgets/scope_pill_switch.dart';

// Dock nav height (container) without system safe-area, used by HeroScreenScaffold.
const _kDockNavOffset = 72.0;

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
  String? _insightContext;
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
    if (_hasCheckedLocationPrompt || !mounted) return;
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
      setState(() => _insightContext = insightContext);

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
      _insightContext = null;
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

    return switch (_state) {
      _ScreenState.input => _buildInputForm(),
      _ScreenState.loading => _buildLoading(),
      _ScreenState.response => _buildResponse(),
      _ScreenState.error => _buildError(),
    };
  }

  // ── Input Form ──────────────────────────────────────────────────────

  Widget _buildInputForm() {
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

    final greetingName =
        ref.watch(currentUserProvider).valueOrNull?.displayName ?? '';

    return HeroScreenScaffold(
      appBar: AppBar(title: const Text('Purchase Assistant')),
      scrollViewKey: const PageStorageKey('assistant-shell-scroll'),
      // Zero horizontal padding so the bleed hero can span full width.
      // Form fields below add their own 16px horizontal padding.
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
      extraBottomPadding: _kDockNavOffset,
      bottom: FilledButton(
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
        ),
        onPressed: _formValid ? _submit : null,
        child: const Text('Ask Conscia ✦'),
      ),
      child: Column(
        children: [
          _AssistantHeroBleed(greetingName: greetingName),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
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
                      ref
                          .read(recentCategoryProvider.notifier)
                          .record(category);
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
                      ref
                          .read(recentCategoryProvider.notifier)
                          .record(category);
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
          ),
        ],
      ),
    );
  }

  // ── Loading ─────────────────────────────────────────────────────────

  Widget _buildLoading() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).appColors;

    return HeroScreenScaffold(
      appBar: AppBar(title: const Text('Conscience Check')),
      extraBottomPadding: _kDockNavOffset,
      scrollable: false,
      child: Column(
        children: [
          const SizedBox(height: 8),
          Text(
            'Reviewing your ${CurrencyFormatter.format(
              amount,
              currencyCode: _currencyCode,
            )} ${_descriptionController.text.trim()} decision...',
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(color: colors.mutedInk),
          ),
          const SizedBox(height: 12),
          const ThinkingCloudWidget(size: 210),
          const SizedBox(height: 16),
          Expanded(
            child: _InsightSlideshow(
              description: _descriptionController.text,
              amount: amount,
              currencyCode: _currencyCode,
              category: _selectedCategory ?? '',
              insightText: _insightContext,
            ),
          ),
        ],
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
      extraBottomPadding: _kDockNavOffset,
      bottom: Row(
        children: [
          Expanded(
            child: FilledButton(
              onPressed: _openExpenseConfirmation,
              child: const Text('Buy it'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton(
              onPressed: _reset,
              child: const Text('Wait 24h'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton(
              onPressed: _reset,
              child: const Text('Skip'),
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _VerdictBubble(
            tone: _VerdictTone.devil,
            message: response.impulse,
            animation: _devilAnim,
          ),
          const SizedBox(height: 12),
          _VerdictBubble(
            tone: _VerdictTone.angel,
            message: response.reason,
            animation: _angelAnim,
          ),
          const SizedBox(height: 12),
          _ConsciaTakeCard(
            message: response.neutral,
            contextLabel: _selectedContextScope == 'family'
                ? 'Family advice'
                : 'Personal advice',
            animation: _neutralAnim,
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

  Widget _buildError() {
    final colors = Theme.of(context).colorScheme;

    return HeroScreenScaffold(
      appBar: AppBar(title: const Text('Purchase Assistant')),
      extraBottomPadding: _kDockNavOffset,
      child: Center(
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

// ── Insight Slideshow (loading screen) ──────────────────────────────

class _InsightSlideshow extends StatefulWidget {
  const _InsightSlideshow({
    required this.description,
    required this.amount,
    required this.currencyCode,
    required this.category,
    this.insightText,
  });

  final String description;
  final double amount;
  final String currencyCode;
  final String category;
  final String? insightText;

  @override
  State<_InsightSlideshow> createState() => _InsightSlideshowState();
}

class _InsightSlideshowState extends State<_InsightSlideshow> {
  final _controller = PageController();
  Timer? _timer;
  int _page = 0;
  // timer tracks its own page counter to avoid stale reads from _page field
  int _timerPage = 0;
  static const _slideCount = 3;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      _timerPage = (_timerPage + 1) % _slideCount;
      _controller.animateToPage(
        _timerPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final amountFormatted = CurrencyFormatter.format(
      widget.amount,
      currencyCode: widget.currencyCode,
    );

    return Column(
      children: [
        SizedBox(
          height: 176,
          child: PageView(
            controller: _controller,
            onPageChanged: (p) => setState(() => _page = p),
            children: [
              _SlideCard(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [colors.deepNavy, colors.family],
                ),
                icon: widget.category.isNotEmpty
                    ? IconTheme(
                        data: const IconThemeData(color: Colors.white),
                        child: CategoryIcons.rawIcon(widget.category, size: 22),
                      )
                    : const Icon(Icons.shopping_bag_outlined,
                        size: 22, color: Colors.white),
                title: 'Your purchase',
                body: widget.description.isNotEmpty
                    ? '$amountFormatted · ${widget.description}'
                    : amountFormatted,
                onLight: false,
              ),
              _SlideCard(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [colors.amberSoft, colors.navySoft],
                ),
                icon: Icon(Icons.insights_rounded,
                    size: 22, color: colors.deepNavy),
                title: 'Your recent snapshot',
                body: widget.insightText ??
                    'Reviewing your spending patterns and history...',
                onLight: true,
              ),
              _SlideCard(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [colors.angelSoft, colors.devilSoft],
                ),
                icon: Icon(Icons.psychology_rounded,
                    size: 22, color: colors.deepNavy),
                title: 'Both sides are making their case',
                body:
                    'Angel and Devil are reviewing every angle of this decision.',
                onLight: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_slideCount, (i) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _page == i ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: _page == i ? colors.deepNavy : colors.border,
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _SlideCard extends StatelessWidget {
  const _SlideCard({
    required this.gradient,
    required this.icon,
    required this.title,
    required this.body,
    required this.onLight,
  });

  final LinearGradient gradient;
  final Widget icon;
  final String title;
  final String body;
  final bool onLight;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).textTheme;
    final titleColor = onLight ? colors.deepNavy : Colors.white;
    final bodyColor =
        onLight ? colors.ink : Colors.white.withValues(alpha: 0.9);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                icon,
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: textTheme.labelMedium?.copyWith(
                      color: titleColor.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Text(
                body,
                style: textTheme.bodyMedium?.copyWith(
                  color: bodyColor,
                  height: 1.4,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Verdict cards ────────────────────────────────────────────────────

enum _VerdictTone { devil, angel }

class _VerdictAvatar extends StatelessWidget {
  const _VerdictAvatar({required this.isDevil});
  final bool isDevil;

  @override
  Widget build(BuildContext context) {
    final atlas = isDevil ? devilMascotAtlas : angelMascotAtlas;
    return ClipOval(
      child: MascotSpriteFrame(
        atlas: atlas,
        frameName: '1_neutral.png',
        width: 48,
      ),
    );
  }
}

class _VerdictBubble extends StatelessWidget {
  const _VerdictBubble({
    required this.tone,
    required this.message,
    required this.animation,
  });

  final _VerdictTone tone;
  final String message;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).textTheme;
    final isDevil = tone == _VerdictTone.devil;

    final bg = isDevil ? colors.devilBg : colors.angelBg;
    final accent = isDevil ? colors.devilAccent : colors.angelAccent;
    final label = isDevil ? 'THE DEVIL SAYS' : 'THE ANGEL SAYS';

    final bubble = ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.62,
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: accent.withValues(alpha: 0.25)),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isDevil ? 4 : 16),
            bottomRight: Radius.circular(isDevil ? 16 : 4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: textTheme.labelSmall
                    ?.copyWith(color: accent, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('"$message"',
                style: textTheme.bodySmall?.copyWith(height: 1.45)),
          ],
        ),
      ),
    );

    final avatar = _VerdictAvatar(isDevil: isDevil);

    return FadeTransition(
      opacity: animation,
      child: Row(
        key: ValueKey(isDevil ? 'verdict-devil-row' : 'verdict-angel-row'),
        crossAxisAlignment: CrossAxisAlignment.end,
        children: isDevil
            ? [avatar, const SizedBox(width: 8), bubble]
            : [const Spacer(), bubble, const SizedBox(width: 8), avatar],
      ),
    );
  }
}

class _ConsciaTakeCard extends StatelessWidget {
  const _ConsciaTakeCard({
    required this.message,
    required this.contextLabel,
    required this.animation,
  });

  final String message;
  final String contextLabel;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;

    return FadeTransition(
      opacity: animation,
      child: Container(
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
                const ConscienceBrandIcon(size: 24),
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
            const SizedBox(height: 12),
            Chip(
              label: Text(contextLabel),
              avatar: const Icon(Icons.auto_awesome, size: 16),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bleed hero (input screen) ────────────────────────────────────────

class _AssistantHeroBleed extends StatelessWidget {
  const _AssistantHeroBleed({required this.greetingName});
  final String greetingName;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      key: const ValueKey('assistant-hero-bleed'),
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.navySoft, colors.amberSoft],
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(32),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
        child: Column(
          children: [
            const SizedBox(height: 18),
            // Mascot
            const ConsciaAlterEgoMotion(
              preset: ConsciaAlterEgoPreset.idle,
              size: 56,
            ),
            const SizedBox(height: 10),
            // Tagline
            Text(
              "Let's think this through",
              style: textTheme.headlineSmall?.copyWith(
                color: colors.deepNavy,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              "Conscia gives you a devil's impulse, an angel's reason, "
              'and a neutral take to help you spend more mindfully.',
              style: textTheme.bodySmall?.copyWith(
                color: colors.mutedInk,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
