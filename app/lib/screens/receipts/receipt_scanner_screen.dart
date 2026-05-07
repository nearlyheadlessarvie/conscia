import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/routing/app_router.dart';
import '../../core/network/dio_client.dart';
import '../../providers/subscription_provider.dart';
import '../../widgets/feed_card.dart';
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
  bool _uploading = false;
  String? _error;

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
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.response?.data?['error'] as String? ??
            'Failed to scan receipt';
      });
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final subAsync = ref.watch(subscriptionProvider);

    return HeroScreenScaffold(
      appBar: AppBar(title: const Text('Scan Receipt')),
      child: subAsync.when(
        data: (status) {
          if (!status.isPremium) {
            return PremiumGate(
              icon: Icons.camera_alt,
              headline: 'Receipt Scanner',
              description:
                  'Automatically extract transaction details from receipts '
                  'using AI. Available with Conscia Premium.',
              onMaybeLater: () =>
                  context.pushReplacement(AppRoutes.addTransaction),
            );
          }
          return _buildPremiumContent(context);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(
          child: Text('Unable to check subscription status'),
        ),
      ),
    );
  }

  Widget _buildPremiumContent(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ScreenSection(
          title: 'Scan the receipt, then sanity-check the details',
          subtitle:
              'Extract merchant, total, and category suggestions from a photo in a few seconds.',
          child: FeedCard(
            child: Column(
              children: [
                if (_uploading) ...[
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text('Scanning receipt...', style: theme.textTheme.bodyLarge),
                ] else ...[
                  CircleAvatar(
                    radius: 38,
                    backgroundColor: colors.primary.withValues(alpha: 0.12),
                    child: Icon(
                      Icons.receipt_long,
                      size: 38,
                      color: colors.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Turn a receipt into a ready-to-review expense.',
                    style: theme.textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Take a photo or pick from your gallery and Conscia will prefill the details for you.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colors.error.withAlpha(25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, size: 18, color: colors.error),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error!,
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: colors.error),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  FilledButton.icon(
                    onPressed: () => _pickAndScan(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Take photo'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => _pickAndScan(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Choose from gallery'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
