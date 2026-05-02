import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'providers/iap_provider.dart';

class ConsciaApp extends ConsumerWidget {
  const ConsciaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    // Eagerly initialize IAP so the purchase stream listener catches
    // deferred/pending purchases from interrupted flows.
    ref.watch(iapStatusProvider);

    return MaterialApp.router(
      title: 'Conscia',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
