import 'dart:async';
import 'dart:convert';

import 'package:conscia_app/core/network/dio_client.dart';
import 'package:conscia_app/providers/auth_provider.dart';
import 'package:conscia_app/providers/budget_providers.dart';
import 'package:conscia_app/providers/family_space_provider.dart';
import 'package:conscia_app/providers/transaction_providers.dart';
import 'package:conscia_app/services/auth_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  test('family space provider treats empty 204 responses as no household', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://test.local/api/'))
      ..httpClientAdapter = _NoFamilySpaceAdapter();

    final container = ProviderContainer(
      overrides: [
        dioProvider.overrideWithValue(dio),
        authProvider.overrideWith(
          (ref) => _TestAuthNotifier(
            const AuthState(
              status: AuthStatus.authenticated,
              userId: 'user-1',
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    final familySpace = await container.read(familySpaceProvider.future);

    expect(familySpace, isNull);
  });

  test('family membership changes refresh family-scoped money data', () async {
    final adapter = _FamilyCacheAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'http://test.local/api/'))
      ..httpClientAdapter = adapter;

    final container = ProviderContainer(
      overrides: [
        dioProvider.overrideWithValue(dio),
        authProvider.overrideWith(
          (ref) => _TestAuthNotifier(
            const AuthState(
              status: AuthStatus.authenticated,
              userId: 'user-1',
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await _waitForBudgets(container);
    await _waitForTransactions(container);

    expect(container.read(budgetListProvider).budgets.single.category, 'Dining');
    expect(
      container.read(transactionListProvider).transactions.single.description,
      'Old family dinner',
    );

    await container.read(familySpaceActionsProvider).leaveFamilySpace();
    await container.read(familySpaceActionsProvider).create(
          name: 'New Household',
          currencyCode: 'PHP',
        );

    await _waitForBudgets(container);
    await _waitForTransactions(container);

    expect(adapter.budgetGetCount, greaterThanOrEqualTo(2));
    expect(adapter.transactionGetCount, greaterThanOrEqualTo(2));
    expect(container.read(selectedScopeProvider), 'personal');
    expect(
      container.read(budgetListProvider).budgets.single.category,
      'Groceries',
    );
    expect(
      container.read(transactionListProvider).transactions.single.description,
      'New household groceries',
    );
  });
}

Future<void> _waitForBudgets(ProviderContainer container) async {
  for (var i = 0; i < 20; i++) {
    final state = container.read(budgetListProvider);
    if (!state.isLoading && state.budgets.isNotEmpty) return;
    await Future<void>.delayed(Duration.zero);
  }
  throw StateError('Budgets did not load.');
}

Future<void> _waitForTransactions(ProviderContainer container) async {
  for (var i = 0; i < 20; i++) {
    final state = container.read(transactionListProvider);
    if (!state.isLoading && state.transactions.isNotEmpty) return;
    await Future<void>.delayed(Duration.zero);
  }
  throw StateError('Transactions did not load.');
}

class _FamilyCacheAdapter implements HttpClientAdapter {
  int budgetGetCount = 0;
  int transactionGetCount = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final path = options.path;
    if (options.method == 'GET' && path.endsWith('budgets')) {
      budgetGetCount++;
      return _jsonResponse(
        budgetGetCount == 1
            ? [
                {
                  'id': 'old-budget',
                  'category': 'Dining',
                  'monthlyLimit': 4000,
                  'currentSpend': 1200,
                  'currencyCode': 'PHP',
                  'percentUsed': 30,
                  'scope': 'Family',
                  'familySpaceId': 'old-family',
                }
              ]
            : [
                {
                  'id': 'new-budget',
                  'category': 'Groceries',
                  'monthlyLimit': 8000,
                  'currentSpend': 640,
                  'currencyCode': 'PHP',
                  'percentUsed': 8,
                  'scope': 'Family',
                  'familySpaceId': 'new-family',
                }
              ],
      );
    }

    if (options.method == 'GET' && path.endsWith('transactions')) {
      transactionGetCount++;
      return _jsonResponse({
        'items': transactionGetCount == 1
            ? [
                {
                  'id': 'old-tx',
                  'amount': 1200,
                  'currencyCode': 'PHP',
                  'category': 'Dining',
                  'counterparty': 'Old family dinner',
                  'type': 'Expense',
                  'date': '2026-05-01T00:00:00Z',
                  'scope': 'Family',
                  'familySpaceId': 'old-family',
                }
              ]
            : [
                {
                  'id': 'new-tx',
                  'amount': 640,
                  'currencyCode': 'PHP',
                  'category': 'Groceries',
                  'counterparty': 'New household groceries',
                  'type': 'Expense',
                  'date': '2026-05-02T00:00:00Z',
                  'scope': 'Family',
                  'familySpaceId': 'new-family',
                }
              ],
        'totalCount': 1,
        'page': 1,
        'pageSize': 20,
        'hasMore': false,
      });
    }

    if (options.method == 'POST' && path.endsWith('family-space/leave')) {
      return _jsonResponse(null, statusCode: 204);
    }

    if (options.method == 'POST' && path.endsWith('family-space')) {
      return _jsonResponse({
        'id': 'new-family',
        'name': 'New Household',
        'currencyCode': 'PHP',
        'role': 'Owner',
        'isReadOnly': false,
      });
    }

    return _jsonResponse({'error': 'Unhandled ${options.method} $path'},
        statusCode: 404);
  }

  ResponseBody _jsonResponse(Object? body, {int statusCode = 200}) {
    return ResponseBody.fromString(
      body == null ? '' : _jsonEncode(body),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  String _jsonEncode(Object body) => jsonEncode(body);

  @override
  void close({bool force = false}) {}
}

class _NoFamilySpaceAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.method == 'GET' && options.path.endsWith('family-space')) {
      return ResponseBody.fromString(
        '',
        204,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }

    return ResponseBody.fromString(
      jsonEncode({'error': 'Unhandled ${options.method} ${options.path}'}),
      404,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _TestAuthNotifier extends AuthNotifier {
  _TestAuthNotifier(AuthState initialState)
      : super(AuthService(Dio()), _FakeSecureStorage()) {
    state = initialState;
  }
}

class _FakeSecureStorage extends FlutterSecureStorage {
  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    WindowsOptions? wOptions,
    AppleOptions? mOptions,
  }) async {
    return null;
  }
}
