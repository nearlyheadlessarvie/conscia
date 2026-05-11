import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/errors/app_error.dart';
import 'providers/usage_provider.dart';

Future<void> main() async {
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    final prefs = await SharedPreferences.getInstance();

    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      AppError.from(
        details.exception,
        stackTrace: details.stack,
        fallbackMessage: 'Something went wrong in the app.',
      );
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      AppError.from(error, stackTrace: stack);
      return true;
    };

    runApp(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const ConsciaApp(),
      ),
    );
  }, (error, stack) {
    AppError.from(error, stackTrace: stack);
  });
}
