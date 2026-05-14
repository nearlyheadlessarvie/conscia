import 'dart:async';

import 'package:conscia_app/providers/auth_provider.dart';
import 'package:conscia_app/providers/transaction_providers.dart';
import 'package:conscia_app/services/auth_service.dart';
import 'package:conscia_app/services/transaction_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuthService extends AuthService {
  _FakeAuthService() : super(Dio());
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
  }) async =>
      null;
}

class _TestAuthNotifier extends AuthNotifier {
  _TestAuthNotifier(AuthState initialState)
      : super(_FakeAuthService(), _FakeSecureStorage()) {
    state = initialState;
  }
}

class _DeferredTransactionService extends TransactionService {
  _DeferredTransactionService() : super(Dio());

  final completer = Completer<PaginatedTransactions>();

  @override
  Future<PaginatedTransactions> list({
    int page = 1,
    int pageSize = 20,
    String? category,
    String? scope,
  }) {
    return completer.future;
  }
}

void main() {
  test('ignores an in-flight transaction load after provider disposal',
      () async {
    final service = _DeferredTransactionService();
    final container = ProviderContainer(
      overrides: [
        authProvider.overrideWith(
          (ref) => _TestAuthNotifier(
            const AuthState(
              status: AuthStatus.authenticated,
              userId: 'user-1',
            ),
          ),
        ),
        transactionServiceProvider.overrideWithValue(service),
      ],
    );

    container.read(transactionListProvider);
    container.dispose();

    service.completer.complete(
      const PaginatedTransactions(
        items: [],
        totalCount: 0,
        page: 1,
        pageSize: 20,
        hasMore: false,
      ),
    );
    await service.completer.future;
    await Future<void>.delayed(Duration.zero);
  });
}
