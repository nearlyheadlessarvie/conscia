import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MerchantDetailScreen extends ConsumerWidget {
  final String merchant;

  const MerchantDetailScreen({super.key, required this.merchant});

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}
