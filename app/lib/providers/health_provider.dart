import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_exception.dart';
import '../core/network/dio_client.dart';
import '../models/health_status.dart';
import '../services/health_service.dart';

class HealthState {
  final HealthStatus? status;
  final bool isLoading;
  final String? error;
  final bool isOffline;
  final DateTime? lastChecked;
  final List<bool> checkHistory;

  const HealthState({
    this.status,
    this.isLoading = false,
    this.error,
    this.isOffline = false,
    this.lastChecked,
    this.checkHistory = const [],
  });

  HealthState copyWith({
    HealthStatus? status,
    bool? isLoading,
    String? error,
    bool? isOffline,
    DateTime? lastChecked,
    List<bool>? checkHistory,
  }) {
    return HealthState(
      status: status ?? this.status,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isOffline: isOffline ?? this.isOffline,
      lastChecked: lastChecked ?? this.lastChecked,
      checkHistory: checkHistory ?? this.checkHistory,
    );
  }

  String get overallLabel {
    if (status == null) return 'Unknown';
    switch (status!.status) {
      case 'Healthy':
        return 'All Systems Operational';
      case 'Degraded':
        return 'Some Services Degraded';
      default:
        return 'System Unavailable';
    }
  }
}

class HealthStatusNotifier extends StateNotifier<HealthState> {
  final HealthService _service;
  Timer? _autoRefreshTimer;
  static const autoRetryInterval = Duration(seconds: 10);

  HealthStatusNotifier(this._service) : super(const HealthState()) {
    refresh();
    _autoRefreshTimer = Timer.periodic(
      autoRetryInterval,
      (_) => refresh(),
    );
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _service.checkHealth();
      final isHealthy = result.status == 'Healthy';
      final history = [
        ...state.checkHistory,
        isHealthy,
      ];
      if (history.length > 20) {
        history.removeRange(0, history.length - 20);
      }
      state = state.copyWith(
        status: result,
        isLoading: false,
        isOffline: false,
        lastChecked: DateTime.now(),
        checkHistory: history,
      );
    } on DioException catch (e) {
      final apiError = ApiException.fromDioException(e);
      final history = [...state.checkHistory, false];
      if (history.length > 20) {
        history.removeRange(0, history.length - 20);
      }
      state = state.copyWith(
        isLoading: false,
        error: apiError.message,
        isOffline: _isOfflineError(e),
        lastChecked: DateTime.now(),
        checkHistory: history,
      );
    } catch (e) {
      final history = [...state.checkHistory, false];
      if (history.length > 20) {
        history.removeRange(0, history.length - 20);
      }
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        isOffline: false,
        lastChecked: DateTime.now(),
        checkHistory: history,
      );
    }
  }

  bool _isOfflineError(DioException error) {
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.connectionError =>
        true,
      DioExceptionType.unknown => error.response == null,
      _ => false,
    };
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }
}

final healthStatusProvider =
    StateNotifierProvider<HealthStatusNotifier, HealthState>((ref) {
  final dio = ref.watch(dioProvider);
  return HealthStatusNotifier(HealthService(dio));
});
