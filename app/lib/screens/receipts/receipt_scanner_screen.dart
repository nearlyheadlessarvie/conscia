import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/errors/app_error.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_icons.dart';
import '../../core/network/dio_client.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_layout.dart';
import '../../providers/subscription_provider.dart';
import '../../widgets/conscia_app_bar.dart';
import '../../widgets/editorial_hero_chip.dart';
import '../../widgets/hero_screen_scaffold.dart';
import '../../widgets/screen_section.dart';
import 'widgets/premium_gate.dart';

typedef ReceiptImagePicker = Future<XFile?> Function(ImageSource source);

({String filename, DioMediaType contentType}) receiptUploadMetadata(
  XFile image,
  List<int> bytes,
) {
  final detectedType = _detectReceiptUploadType(bytes) ??
      _receiptUploadTypeForMime(image.mimeType) ??
      _receiptUploadTypeForFilename(image.name);

  if (detectedType == null) {
    return (
      filename: image.name,
      contentType: DioMediaType('application', 'octet-stream'),
    );
  }

  return (
    filename: _filenameWithExtension(image.name, detectedType.extension),
    contentType: DioMediaType.parse(detectedType.mimeType),
  );
}

final receiptImagePickerProvider = Provider<ReceiptImagePicker>((ref) {
  final picker = ImagePicker();
  return (source) => picker.pickImage(
        source: source,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 85,
      );
});

class ReceiptScannerScreen extends ConsumerStatefulWidget {
  const ReceiptScannerScreen({super.key});

  @override
  ConsumerState<ReceiptScannerScreen> createState() =>
      _ReceiptScannerScreenState();
}

class _ReceiptScannerScreenState extends ConsumerState<ReceiptScannerScreen> {
  final _appBarScrollProgress = ValueNotifier<double>(0);
  bool _pickingImage = false;
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
    if (_pickingImage || _uploading) return;

    setState(() {
      _pickingImage = true;
      _error = null;
    });

    XFile? image;
    try {
      image = await ref.read(receiptImagePickerProvider)(source);
    } on PlatformException catch (e, s) {
      if (!mounted) return;
      final error = AppError.from(e, stackTrace: s);
      setState(() {
        _error = error.userMessage;
        _pickingImage = false;
      });
      return;
    } catch (e, s) {
      if (!mounted) return;
      final error = AppError.from(e, stackTrace: s);
      setState(() {
        _error = error.userMessage;
        _pickingImage = false;
      });
      return;
    }

    if (!mounted) return;
    setState(() => _pickingImage = false);
    if (image == null) return;

    setState(() {
      _uploading = true;
      _error = null;
    });

    try {
      final dio = ref.read(dioProvider);
      final bytes = await image.readAsBytes();
      final metadata = receiptUploadMetadata(image, bytes);
      final formData = FormData.fromMap({
        'image': MultipartFile.fromBytes(
          bytes,
          filename: metadata.filename,
          contentType: metadata.contentType,
        ),
      });

      final response = await dio.post(ApiConstants.scanReceipt, data: formData);
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
            icon: AppIconKey.receiptScan,
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
    final actionsDisabled = _pickingImage || _uploading;

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
                                icon: AppIconKey.camera,
                                title: 'Take photo',
                                subtitle: 'Open the camera and scan now.',
                                enabled: !actionsDisabled,
                                onTap: () => _pickAndScan(ImageSource.camera),
                              ),
                              const SizedBox(height: 12),
                              _ReceiptSourceAction(
                                key: const ValueKey(
                                  'receipt-scan-gallery-action',
                                ),
                                icon: AppIconKey.photoLibrary,
                                title: 'Choose from gallery',
                                subtitle: 'Use a receipt image from photos.',
                                enabled: !actionsDisabled,
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

class _ReceiptUploadType {
  const _ReceiptUploadType(this.mimeType, this.extension);

  final String mimeType;
  final String extension;
}

const _jpegReceiptUploadType = _ReceiptUploadType('image/jpeg', 'jpg');
const _pngReceiptUploadType = _ReceiptUploadType('image/png', 'png');
const _pdfReceiptUploadType = _ReceiptUploadType('application/pdf', 'pdf');
const _tiffReceiptUploadType = _ReceiptUploadType('image/tiff', 'tif');
const _heicReceiptUploadType = _ReceiptUploadType('image/heic', 'heic');

_ReceiptUploadType? _detectReceiptUploadType(List<int> bytes) {
  if (bytes.length >= 3 &&
      bytes[0] == 0xFF &&
      bytes[1] == 0xD8 &&
      bytes[2] == 0xFF) {
    return _jpegReceiptUploadType;
  }

  if (bytes.length >= 8 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4E &&
      bytes[3] == 0x47 &&
      bytes[4] == 0x0D &&
      bytes[5] == 0x0A &&
      bytes[6] == 0x1A &&
      bytes[7] == 0x0A) {
    return _pngReceiptUploadType;
  }

  if (bytes.length >= 4 &&
      bytes[0] == 0x25 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x44 &&
      bytes[3] == 0x46) {
    return _pdfReceiptUploadType;
  }

  if (bytes.length >= 4 &&
      ((bytes[0] == 0x49 &&
              bytes[1] == 0x49 &&
              bytes[2] == 0x2A &&
              bytes[3] == 0x00) ||
          (bytes[0] == 0x4D &&
              bytes[1] == 0x4D &&
              bytes[2] == 0x00 &&
              bytes[3] == 0x2A))) {
    return _tiffReceiptUploadType;
  }

  if (bytes.length >= 12 &&
      bytes[4] == 0x66 &&
      bytes[5] == 0x74 &&
      bytes[6] == 0x79 &&
      bytes[7] == 0x70) {
    final brand = String.fromCharCodes(bytes.sublist(8, 12)).toLowerCase();
    if (brand == 'heic' ||
        brand == 'heix' ||
        brand == 'hevc' ||
        brand == 'hevx' ||
        brand == 'heif' ||
        brand == 'mif1') {
      return _heicReceiptUploadType;
    }
  }

  return null;
}

_ReceiptUploadType? _receiptUploadTypeForMime(String? mimeType) {
  switch (mimeType?.toLowerCase()) {
    case 'image/jpeg':
    case 'image/jpg':
      return _jpegReceiptUploadType;
    case 'image/png':
      return _pngReceiptUploadType;
    case 'application/pdf':
      return _pdfReceiptUploadType;
    case 'image/tiff':
    case 'image/tif':
      return _tiffReceiptUploadType;
    case 'image/heic':
    case 'image/heif':
      return _heicReceiptUploadType;
    default:
      return null;
  }
}

_ReceiptUploadType? _receiptUploadTypeForFilename(String filename) {
  final lower = filename.toLowerCase();
  if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
    return _jpegReceiptUploadType;
  }
  if (lower.endsWith('.png')) {
    return _pngReceiptUploadType;
  }
  if (lower.endsWith('.pdf')) {
    return _pdfReceiptUploadType;
  }
  if (lower.endsWith('.tif') || lower.endsWith('.tiff')) {
    return _tiffReceiptUploadType;
  }
  if (lower.endsWith('.heic') || lower.endsWith('.heif')) {
    return _heicReceiptUploadType;
  }

  return null;
}

String _filenameWithExtension(String filename, String extension) {
  final trimmed = filename.trim();
  if (trimmed.isEmpty) return 'receipt.$extension';

  final slashIndex = trimmed.lastIndexOf('/');
  final backslashIndex = trimmed.lastIndexOf(r'\');
  final separatorIndex =
      slashIndex > backslashIndex ? slashIndex : backslashIndex;
  final basename =
      separatorIndex >= 0 ? trimmed.substring(separatorIndex + 1) : trimmed;
  final dotIndex = basename.lastIndexOf('.');

  if (dotIndex <= 0) {
    return '$basename.$extension';
  }

  return '${basename.substring(0, dotIndex)}.$extension';
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
                EditorialHeroChip(label: 'Merchant'),
                EditorialHeroChip(label: 'Total'),
                EditorialHeroChip(label: 'Category'),
              ],
            ),
          ],
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
    required this.enabled,
    required this.onTap,
  });

  final AppIconKey icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: enabled
          ? colors.surfaceRaised
          : colors.surfaceRaised.withValues(alpha: 0.7),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: enabled
                      ? colors.navySoft
                      : colors.navySoft.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: AppIcons.icon(
                    icon,
                    color: enabled
                        ? colors.deepNavy
                        : colors.deepNavy.withValues(alpha: 0.55),
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.titleSmall?.copyWith(
                        color: enabled
                            ? colors.ink
                            : colors.ink.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: enabled
                            ? colors.mutedInk
                            : colors.mutedInk.withValues(alpha: 0.75),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AppIcons.icon(
                AppIconKey.chevronRight,
                color: enabled
                    ? colors.deepNavy.withValues(alpha: 0.55)
                    : colors.deepNavy.withValues(alpha: 0.28),
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
            AppIcons.icon(
              AppIconKey.error,
              size: 16,
              color: colors.expense,
            ),
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
