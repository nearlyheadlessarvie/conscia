import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/errors/app_error.dart';
import '../../core/network/dio_client.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_layout.dart';
import '../../providers/subscription_provider.dart';
import '../../widgets/conscia_app_bar.dart';
import '../../widgets/hero_screen_scaffold.dart';
import '../../widgets/screen_section.dart';
import 'widgets/premium_gate.dart';

class ReceiptScannerScreen extends ConsumerStatefulWidget {
  const ReceiptScannerScreen({super.key});

  @override
  ConsumerState<ReceiptScannerScreen> createState() =>
      _ReceiptScannerScreenState();
}

class _ReceiptScannerScreenState extends ConsumerState<ReceiptScannerScreen> {
  final _appBarScrollProgress = ValueNotifier<double>(0);
  bool _uploading = false;
  String? _error;

  @override
  void dispose() {
    _appBarScrollProgress.dispose();
    super.dispose();
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification.metrics.axis == Axis.vertical) {
      final nextProgress = (notification.metrics.pixels / 10).clamp(0.0, 1.0);
      if (_appBarScrollProgress.value != nextProgress) {
        _appBarScrollProgress.value = nextProgress;
      }
    }
    return false;
  }

  Future<void> _pickAndScan(ImageSource source) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: source,
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 85,
    );
    if (image == null) return;

    setState(() {
      _uploading = true;
      _error = null;
    });

    try {
      final dio = ref.read(dioProvider);
      final bytes = await image.readAsBytes();
      final formData = FormData.fromMap({
        'image': MultipartFile.fromBytes(
          bytes,
          filename: image.name,
        ),
      });

      final response = await dio.post('/receipts/scan', data: formData);
      final data = response.data as Map<String, dynamic>;
      final receiptId = data['id'] as String;

      if (!mounted) return;
      context.push('/receipts/$receiptId/review');
    } on DioException catch (e, s) {
      if (!mounted) return;
      final error = AppError.from(e, stackTrace: s);
      setState(() {
        _error = error.userMessage;
      });
    } catch (e, s) {
      if (!mounted) return;
      final error = AppError.from(e, stackTrace: s);
      setState(() {
        _error = error.userMessage;
      });
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final subAsync = ref.watch(subscriptionProvider);

    return subAsync.when(
      data: (status) {
        if (status.isPremium) {
          return _buildPremiumContent(context);
        }

        return HeroScreenScaffold(
          appBar: const ConsciaAppBar(title: Text('Scan Receipt')),
          padding: EdgeInsets.zero,
          bleedBehindAppBar: true,
          child: PremiumGate(
            icon: Icons.document_scanner_rounded,
            headline: 'Receipt Scanner',
            description:
                'Automatically extract transaction details from receipts '
                'using AI. Available with Conscia Premium.',
            onMaybeLater: () =>
                context.pushReplacement(AppRoutes.addTransaction),
          ),
        );
      },
      loading: () => const HeroScreenScaffold(
        appBar: ConsciaAppBar(title: Text('Scan Receipt')),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const HeroScreenScaffold(
        appBar: ConsciaAppBar(title: Text('Scan Receipt')),
        child: Center(
          child: Text('Unable to check subscription status'),
        ),
      ),
    );
  }

  Widget _buildPremiumContent(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.appColors;

    return ConsciaAppBarScrollScope(
      scrollProgress: _appBarScrollProgress,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: const ConsciaAppBar(title: Text('Scan Receipt')),
        body: NotificationListener<ScrollNotification>(
          onNotification: _handleScrollNotification,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [colors.pageTop, colors.pageBottom],
              ),
            ),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                const SliverToBoxAdapter(
                  child: _ReceiptScanHero(),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 36),
                  sliver: SliverList.list(
                    children: [
                      if (_uploading)
                        const _ReceiptScanningState()
                      else ...[
                        ScreenSection(
                          title: 'Choose a source',
                          subtitle:
                              'Use the camera for a new receipt, or import one you already saved.',
                          compact: true,
                          child: Column(
                            children: [
                              _ReceiptSourceAction(
                                key: const ValueKey(
                                  'receipt-scan-camera-action',
                                ),
                                icon: Icons.camera_alt_rounded,
                                title: 'Take photo',
                                subtitle: 'Open the camera and scan now.',
                                onTap: () => _pickAndScan(ImageSource.camera),
                              ),
                              const SizedBox(height: 12),
                              _ReceiptSourceAction(
                                key: const ValueKey(
                                  'receipt-scan-gallery-action',
                                ),
                                icon: Icons.photo_library_rounded,
                                title: 'Choose from gallery',
                                subtitle: 'Use a receipt image from photos.',
                                onTap: () => _pickAndScan(ImageSource.gallery),
                              ),
                            ],
                          ),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 18),
                          _ReceiptInlineError(message: _error!),
                        ],
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReceiptScanHero extends StatelessWidget {
  const _ReceiptScanHero();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      key: const ValueKey('receipt-scan-hero'),
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
        padding: EdgeInsets.fromLTRB(
          AppLayout.screenPadding,
          AppLayout.bleedingHeroTop(context),
          AppLayout.screenPadding,
          AppLayout.heroBottomPadding,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SCAN RECEIPT',
              style: textTheme.labelSmall?.copyWith(
                color: colors.deepNavy,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Snap it. Review it. Done.',
              style: textTheme.headlineMedium?.copyWith(
                color: colors.deepNavy,
                fontWeight: FontWeight.w800,
                height: 1.04,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Conscia extracts the merchant, total, and category so every receipt becomes a ready-to-review expense.',
              style: textTheme.bodyMedium?.copyWith(
                color: colors.ink,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 18),
            const Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ReceiptHeroChip(label: 'Merchant'),
                _ReceiptHeroChip(label: 'Total'),
                _ReceiptHeroChip(label: 'Category'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceiptHeroChip extends StatelessWidget {
  const _ReceiptHeroChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.deepNavy,
                fontWeight: FontWeight.w800,
              ),
        ),
      ),
    );
  }
}

class _ReceiptSourceAction extends StatelessWidget {
  const _ReceiptSourceAction({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: colors.surfaceRaised,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colors.navySoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: colors.deepNavy, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.titleSmall?.copyWith(
                        color: colors.ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.mutedInk,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: colors.deepNavy.withValues(alpha: 0.55),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReceiptScanningState extends StatelessWidget {
  const _ReceiptScanningState();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'Scanning receipt...',
                style: textTheme.titleSmall?.copyWith(
                  color: colors.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceiptInlineError extends StatelessWidget {
  const _ReceiptInlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.expenseSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Icon(Icons.error_outline_rounded, size: 16, color: colors.expense),
            const SizedBox(width: 8),
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
      ),
    );
  }
}
