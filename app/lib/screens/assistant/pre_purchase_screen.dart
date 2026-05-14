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
import '../../core/utils/localized_number_input.dart';
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
import '../../widgets/editorial_sticky_header.dart';
import '../../widgets/floating_label_text_field.dart';
import '../../widgets/hero_screen_scaffold.dart';
import '../../widgets/conscia_app_bar.dart';
import '../../widgets/thinking_cloud.dart';
import '../../widgets/location_assistance_prompt_sheet.dart';
import '../../widgets/premium_upgrade_dialog.dart';
import '../../widgets/screen_section.dart';
import '../../widgets/smart_suggestions_card.dart';
import '../transactions/widgets/transaction_style_category_selector.dart';
import '../transactions/widgets/voice_input_button.dart';
import 'widgets/budget_context_card.dart';
import '../../widgets/amount_hero_field.dart';
import '../../../widgets/scope_pill_switch.dart';

// Dock nav height (container) without system safe-area, used by HeroScreenScaffold.
const _kDockNavOffset = 72.0;

enum _ScreenState { input, error }

class PrePurchaseScreen extends ConsumerStatefulWidget {
  const PrePurchaseScreen({super.key});

  @override
  ConsumerState<PrePurchaseScreen> createState() => _PrePurchaseScreenState();
}

class _PrePurchaseScreenState extends ConsumerState<PrePurchaseScreen> {
  _ScreenState _state = _ScreenState.input;
  String? _errorMessage;
  String? _insightContext;
  bool _hasCheckedLocationPrompt = false;
  final ScrollController _inputScrollController = ScrollController();
  double _inputScrollOffset = 0;
  bool _scrollSyncScheduled = false;

  // Form
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  String _currencyCode = 'USD';
  bool _currencyManuallyChanged = false;
  String? _selectedCategory;
  String _selectedContextScope = 'personal';

  @override
  void initState() {
    super.initState();
    _currencyCode = ref.read(userPreferencesProvider).currency;
    _inputScrollController.addListener(_handleInputScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybePromptForLocationAssistance();
    });
  }

  void _handleInputScroll() {
    _syncInputScrollOffset();
  }

  void _syncInputScrollOffset() {
    final nextOffset =
        _inputScrollController.hasClients ? _inputScrollController.offset : 0.0;
    if ((nextOffset - _inputScrollOffset).abs() < 1) return;
    setState(() => _inputScrollOffset = nextOffset);
  }

  void _scheduleInputScrollSync() {
    if (_scrollSyncScheduled) return;
    _scrollSyncScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollSyncScheduled = false;
      if (!mounted) return;
      _syncInputScrollOffset();
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
    _inputScrollController
      ..removeListener(_handleInputScroll)
      ..dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  bool get _formValid {
    final prefs = ref.read(userPreferencesProvider);
    final amount = LocalizedNumberInput.parseAmount(
      _amountController.text,
      locale: prefs.locale,
    );
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
        _amountController.text = LocalizedNumberInput.formatForInput(
          parsed.amount!,
          locale: ref.read(userPreferencesProvider).locale,
          decimalDigits: 0,
        );
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

    await _showConscienceCheckSheet();
  }

  Future<AIResponse> _requestPrePurchaseVerdict() async {
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
        amount: LocalizedNumberInput.parseAmount(
          _amountController.text,
          locale: ref.read(userPreferencesProvider).locale,
        )!,
        currencyCode: _currencyCode,
        category: _selectedCategory!,
        insightContext: insightContext,
        contextScope: _selectedContextScope,
      );

      ref.read(monthlyUsageProvider.notifier).recordAiAssist();
      return response;
    } on DioException catch (e, s) {
      if (e.response?.statusCode == 403) {
        throw AppError.from(e, stackTrace: s).userMessage;
      }
      throw AppError.from(e, stackTrace: s).userMessage;
    } catch (e, s) {
      throw AppError.from(e, stackTrace: s).userMessage;
    }
  }

  Future<void> _showConscienceCheckSheet() async {
    final amount = LocalizedNumberInput.parseAmount(
          _amountController.text,
          locale: ref.read(userPreferencesProvider).locale,
        ) ??
        0;
    final responseFuture = _requestPrePurchaseVerdict();

    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.82,
          minChildSize: 0.42,
          maxChildSize: 0.94,
          builder: (context, scrollController) {
            return FutureBuilder<AIResponse>(
              future: responseFuture,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _ConscienceSheetError(
                    scrollController: scrollController,
                    message: snapshot.error.toString(),
                    onClose: () => Navigator.of(sheetContext).pop(),
                  );
                }

                if (!snapshot.hasData) {
                  return _ConscienceCheckSheetContent(
                    scrollController: scrollController,
                    description: _descriptionController.text,
                    amount: amount,
                    currencyCode: _currencyCode,
                    category: _selectedCategory ?? '',
                    insightText: _insightContext,
                  );
                }

                final locale = ref.watch(userPreferencesProvider).locale;
                return _VerdictSheetContent(
                  scrollController: scrollController,
                  response: snapshot.data!,
                  contextLabel: _selectedContextScope == 'family'
                      ? 'Family advice'
                      : 'Personal advice',
                  selectedCategory: _selectedCategory,
                  amount: amount,
                  currencyCode: _currencyCode,
                  locale: locale,
                  onBuy: () async {
                    Navigator.of(sheetContext).pop();
                    await _openExpenseConfirmation();
                  },
                  onSkip: () {
                    Navigator.of(sheetContext).pop();
                    _reset();
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  void _reset() {
    _descriptionController.clear();
    _amountController.clear();
    setState(() {
      _currencyManuallyChanged = false;
      _currencyCode = ref.read(userPreferencesProvider).currency;
      _selectedCategory = null;
      _selectedContextScope = 'personal';
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

    final colors = Theme.of(context).appColors;
    final stickyProgress = ((_inputScrollOffset - 5) / 10).clamp(0.0, 1.0);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    _scheduleInputScrollSync();

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [colors.pageTop, colors.pageBottom],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    key: const PageStorageKey('assistant-shell-scroll'),
                    controller: _inputScrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      children: [
                        const _AssistantHeroBleed(),
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ScreenSection(
                                title: 'Decision details',
                                subtitle:
                                    "Tell Conscia what you're considering so it can weigh both sides.",
                                compact: true,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    FloatingLabelTextField(
                                      controller: _descriptionController,
                                      label: 'What are you thinking of buying?',
                                      textInputAction: TextInputAction.next,
                                      textCapitalization:
                                          TextCapitalization.sentences,
                                      trailing: VoiceInputButton(
                                        onTranscriptReady:
                                            _applyVoiceTranscript,
                                      ),
                                      onChanged: (_) => setState(() {}),
                                    ),
                                    const SizedBox(height: 18),
                                    AmountHeroField(
                                      controller: _amountController,
                                      currencyCode: _currencyCode,
                                      locale: ref
                                          .watch(userPreferencesProvider)
                                          .locale,
                                      isExpense: true,
                                      isPremium: isPremium,
                                      onChanged: (_) => setState(() {}),
                                      onCurrencyChanged: (code) => setState(() {
                                        _currencyManuallyChanged = true;
                                        _currencyCode = code;
                                      }),
                                    ),
                                  ],
                                ),
                              ),
                              if (familySpace != null)
                                ScreenSection(
                                  title: 'Classify',
                                  subtitle:
                                      'Where should this live in your money story?',
                                  compact: true,
                                  child: ScopePillSwitch(
                                    value: _selectedContextScope,
                                    familyEnabled: true,
                                    onChanged: (scope) => setState(
                                      () => _selectedContextScope =
                                          scope.toLowerCase(),
                                    ),
                                  ),
                                ),
                              ScreenSection(
                                title: 'Category',
                                subtitle:
                                    'Where do you think this belongs so we can give you better insights?',
                                compact: true,
                                child: TransactionStyleCategorySelector(
                                  selectedCategory: _selectedCategory,
                                  isExpense: true,
                                  isPremium: isPremium,
                                  showHeader: false,
                                  onCategorySelected: (category) {
                                    setState(
                                        () => _selectedCategory = category);
                                    if (category != null) {
                                      ref
                                          .read(recentCategoryProvider.notifier)
                                          .record(category);
                                    }
                                  },
                                ),
                              ),
                              if (locationAssistance.isEnabled &&
                                  hasSuggestions) ...[
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
                                  categoryAvatarBuilder: (category) =>
                                      CategoryIcons.badge(
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
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: EditorialStickyHeader(
                      title: 'Purchase Assistant',
                      progress: stickyProgress,
                      topPadding: MediaQuery.paddingOf(context).top,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedPadding(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.fromLTRB(
                16,
                0,
                16,
                28 + _kDockNavOffset + bottomInset + keyboardInset,
              ),
              child: FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                ),
                onPressed: _formValid ? _submit : null,
                child: const Text('Ask Conscia ✦'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    final colors = Theme.of(context).colorScheme;

    return HeroScreenScaffold(
      appBar: const ConsciaAppBar(title: Text('Purchase Assistant')),
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

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;

    return Center(
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: colors.border,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _ConscienceCheckSheetContent extends StatelessWidget {
  const _ConscienceCheckSheetContent({
    required this.scrollController,
    required this.description,
    required this.amount,
    required this.currencyCode,
    required this.category,
    this.insightText,
  });

  final ScrollController scrollController;
  final String description;
  final double amount;
  final String currencyCode;
  final String category;
  final String? insightText;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        const _SheetHandle(),
        const SizedBox(height: 18),
        Text(
          'Conscience Check',
          textAlign: TextAlign.center,
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 28),
        Text(
          'Reviewing your ${CurrencyFormatter.format(
            amount,
            currencyCode: currencyCode,
          )} ${description.trim()} decision...',
          textAlign: TextAlign.center,
          style: textTheme.bodySmall?.copyWith(color: colors.mutedInk),
        ),
        const SizedBox(height: 14),
        const Center(child: ThinkingCloudWidget(size: 224)),
        const SizedBox(height: 18),
        _InsightSlideshow(
          description: description,
          amount: amount,
          currencyCode: currencyCode,
          category: category,
          insightText: insightText,
        ),
      ],
    );
  }
}

class _ConscienceSheetError extends StatelessWidget {
  const _ConscienceSheetError({
    required this.scrollController,
    required this.message,
    required this.onClose,
  });

  final ScrollController scrollController;
  final String message;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        const _SheetHandle(),
        const SizedBox(height: 36),
        Icon(Icons.error_outline_rounded, color: colors.expense, size: 42),
        const SizedBox(height: 16),
        Text(
          'Conscia needs another try',
          textAlign: TextAlign.center,
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(color: colors.mutedInk),
        ),
        const SizedBox(height: 22),
        FilledButton(
          onPressed: onClose,
          child: const Text('Back to purchase'),
        ),
      ],
    );
  }
}

class _VerdictSheetContent extends StatelessWidget {
  const _VerdictSheetContent({
    required this.scrollController,
    required this.response,
    required this.contextLabel,
    required this.amount,
    required this.currencyCode,
    required this.locale,
    required this.onBuy,
    required this.onSkip,
    this.selectedCategory,
  });

  final ScrollController scrollController;
  final AIResponse response;
  final String contextLabel;
  final double amount;
  final String currencyCode;
  final String? locale;
  final String? selectedCategory;
  final Future<void> Function() onBuy;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Column(
              children: [
                const _SheetHandle(),
                const SizedBox(height: 18),
                Text(
                  'The verdict',
                  textAlign: TextAlign.center,
                  style: textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 22),
                _VerdictBubble(
                  tone: _VerdictTone.devil,
                  message: response.impulse,
                ),
                const SizedBox(height: 12),
                _VerdictBubble(
                  tone: _VerdictTone.angel,
                  message: response.reason,
                ),
                const SizedBox(height: 12),
                _ConsciaTakeCard(
                  message: response.neutral,
                  contextLabel: contextLabel,
                ),
                const SizedBox(height: 16),
                if (selectedCategory != null && response.budget != null)
                  BudgetContextCard(
                    category: selectedCategory!,
                    spent: response.budget!.currentSpend,
                    limit: response.budget!.monthlyLimit,
                    currencyCode: currencyCode,
                    locale: locale,
                    projectedAmount: amount,
                  ),
              ],
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      shape: const StadiumBorder(),
                      backgroundColor: colors.deepNavy,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => unawaited(onBuy()),
                    child: const Text('Buy it'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      shape: const StadiumBorder(),
                      foregroundColor: colors.deepNavy,
                      backgroundColor: colors.navySoft.withValues(alpha: 0.34),
                      side: BorderSide(
                        color: colors.deepNavy.withValues(alpha: 0.24),
                      ),
                    ),
                    onPressed: onSkip,
                    child: const Text('Skip'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
  });

  final _VerdictTone tone;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).textTheme;
    final isDevil = tone == _VerdictTone.devil;

    final bg = isDevil ? colors.devilBg : colors.angelBg;
    final accent = isDevil ? colors.devilAccent : colors.angelAccent;
    final label = isDevil ? 'THE DEVIL SAYS' : 'THE ANGEL SAYS';

    return Container(
      key: ValueKey(isDevil ? 'verdict-devil-card' : 'verdict-angel-card'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: accent.withValues(alpha: 0.38)),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _VerdictAvatar(isDevil: isDevil),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: textTheme.labelSmall?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.7,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.ink,
                    height: 1.42,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConsciaTakeCard extends StatelessWidget {
  const _ConsciaTakeCard({
    required this.message,
    required this.contextLabel,
  });

  final String message;
  final String contextLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.amberSoft, colors.navySoft],
        ),
        border: Border.all(color: colors.amber.withValues(alpha: 0.55)),
        borderRadius: BorderRadius.circular(24),
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
    );
  }
}

// ── Bleed hero (input screen) ────────────────────────────────────────

class _AssistantHeroBleed extends StatelessWidget {
  const _AssistantHeroBleed();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).textTheme;
    final topInset = MediaQuery.paddingOf(context).top;

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
        padding: EdgeInsets.fromLTRB(20, topInset + 68, 20, 24),
        child: Column(
          children: [
            const ThinkingCloudWidget(size: 124),
            const SizedBox(height: 12),
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
              'Conscia helps you pause before you spend.',
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
