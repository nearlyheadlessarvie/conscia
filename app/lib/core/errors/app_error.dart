import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../network/api_exception.dart';

typedef AppErrorLogger = void Function(AppError error);
typedef ReferenceIdFactory = String Function();

class AppError {
  AppError({
    required this.referenceId,
    required this.message,
    required this.originalError,
    this.stackTrace,
  });

  factory AppError.from(
    Object error, {
    StackTrace? stackTrace,
    String? fallbackMessage,
    String? referenceId,
    bool log = true,
  }) {
    if (error is AppError) {
      return error;
    }

    final appError = AppError(
      referenceId: referenceId ?? _referenceIdFactory(),
      message: _friendlyMessage(error, fallbackMessage),
      originalError: error,
      stackTrace: stackTrace,
    );

    if (log) {
      _logger(appError);
    }

    return appError;
  }

  static AppErrorLogger _logger = _defaultLogger;
  static ReferenceIdFactory _referenceIdFactory = _defaultReferenceId;
  static final math.Random _random = math.Random.secure();

  final String referenceId;
  final String message;
  final Object originalError;
  final StackTrace? stackTrace;

  String get userMessage => '$message Reference: $referenceId';

  static void configure({
    AppErrorLogger? logger,
    ReferenceIdFactory? referenceIdFactory,
  }) {
    if (logger != null) {
      _logger = logger;
    }
    if (referenceIdFactory != null) {
      _referenceIdFactory = referenceIdFactory;
    }
  }

  static void resetForTests() {
    _logger = _defaultLogger;
    _referenceIdFactory = _defaultReferenceId;
  }

  static String _friendlyMessage(Object error, String? fallbackMessage) {
    if (fallbackMessage != null && fallbackMessage.trim().isNotEmpty) {
      return fallbackMessage;
    }

    final apiError = switch (error) {
      ApiException apiException => apiException,
      DioException dioException => ApiException.fromDioException(dioException),
      _ => null,
    };

    if (apiError != null) {
      if (apiError.isUnauthorized) {
        return 'Please sign in again to continue.';
      }
      if (apiError.isForbidden) {
        return apiError.message;
      }
      if (apiError.isNotFound) {
        return 'We could not find that item. Please refresh and try again.';
      }
      if (apiError.isServerError) {
        return 'Conscia is having trouble right now. Please try again.';
      }
      return apiError.message;
    }

    return 'Something went wrong. Please try again.';
  }

  static String _defaultReferenceId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final entropy = _random.nextInt(0xFFFFFF);
    final value = (timestamp ^ entropy).toRadixString(36).toUpperCase();
    return value.length <= 8
        ? value.padLeft(8, '0')
        : value.substring(value.length - 8);
  }

  static void _defaultLogger(AppError error) {
    FlutterError.dumpErrorToConsole(
      FlutterErrorDetails(
        exception: error.originalError,
        stack: error.stackTrace,
        library: 'conscia',
        context: ErrorDescription('App error ${error.referenceId}'),
        informationCollector: () sync* {
          yield ErrorDescription('User message: ${error.userMessage}');
        },
      ),
    );
    debugPrint(
      '[ConsciaError:${error.referenceId}] ${error.originalError}',
    );
  }
}
