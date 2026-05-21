import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/constants/api_constants.dart';
import 'subscription_service.dart';

const String kPremiumMonthlyId = 'conscia_premium_monthly';
const Set<String> _kProductIds = {kPremiumMonthlyId};

enum IAPState { uninitialized, available, unavailable, purchasing, error }

class IAPStatus {
  final IAPState state;
  final ProductDetails? product;
  final String? errorMessage;

  const IAPStatus({
    this.state = IAPState.uninitialized,
    this.product,
    this.errorMessage,
  });
}

class IAPService {
  final SubscriptionService _subscriptionService;
  final void Function() _onPurchaseCompleted;

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  bool _initialized = false;

  final _statusController = StreamController<IAPStatus>.broadcast();
  IAPStatus _status = const IAPStatus();

  Stream<IAPStatus> get statusStream => _statusController.stream;
  IAPStatus get status => _status;

  IAPService({
    required SubscriptionService subscriptionService,
    required void Function() onPurchaseCompleted,
  })  : _subscriptionService = subscriptionService,
        _onPurchaseCompleted = onPurchaseCompleted;

  bool get _isDevMode => ApiConstants.useMockAuth;

  void _emit(IAPStatus status) {
    _status = status;
    if (!_statusController.isClosed) {
      _statusController.add(status);
    }
  }

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    if (_isDevMode) {
      _emit(const IAPStatus(state: IAPState.unavailable));
      return;
    }

    final available = await InAppPurchase.instance.isAvailable();
    if (!available) {
      _emit(const IAPStatus(state: IAPState.unavailable));
      return;
    }

    _subscription = InAppPurchase.instance.purchaseStream.listen(
      _handlePurchaseUpdates,
      onDone: _onStreamDone,
      onError: _onStreamError,
    );

    final response =
        await InAppPurchase.instance.queryProductDetails(_kProductIds);

    if (response.productDetails.isEmpty) {
      _emit(IAPStatus(
        state: IAPState.available,
        errorMessage: response.notFoundIDs.isNotEmpty
            ? 'Product not found in store. Configure "$kPremiumMonthlyId" in App Store Connect / Play Console.'
            : null,
      ));
      return;
    }

    _emit(IAPStatus(
      state: IAPState.available,
      product: response.productDetails.first,
    ));
  }

  Future<bool> purchaseSubscription() async {
    if (_isDevMode) return false;
    if (_status.state == IAPState.purchasing) return false;

    final product = _status.product;
    if (product == null) return false;

    _emit(IAPStatus(
      state: IAPState.purchasing,
      product: product,
    ));

    final purchaseParam = PurchaseParam(productDetails: product);
    // in_app_purchase treats auto-renewable subscriptions the same as non-consumables
    return InAppPurchase.instance.buyNonConsumable(
      purchaseParam: purchaseParam,
    );
  }

  Future<void> restorePurchases() async {
    if (_isDevMode) return;

    final product = _status.product;
    _emit(IAPStatus(state: IAPState.purchasing, product: product));

    await InAppPurchase.instance.restorePurchases();

    // If no purchases are found, the stream never emits. Use a timeout
    // to reset back to available state so the UI doesn't hang on the spinner.
    Future.delayed(const Duration(seconds: 10), () {
      if (_status.state == IAPState.purchasing) {
        _emit(IAPStatus(state: IAPState.available, product: product));
      }
    });
  }

  Future<bool> openManageSubscriptions() async {
    if (_isDevMode) return false;

    final uri = _subscriptionManagementUri;
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Uri get _subscriptionManagementUri {
    if (kIsWeb) {
      return Uri.parse('https://play.google.com/store/account/subscriptions');
    }
    if (Platform.isIOS) {
      return Uri.parse('https://apps.apple.com/account/subscriptions');
    }
    return Uri.parse(
      'https://play.google.com/store/account/subscriptions?product_id=$kPremiumMonthlyId&package=com.getconscia.app.ai',
    );
  }

  void _handlePurchaseUpdates(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      _handlePurchase(purchase);
    }
  }

  Future<void> _handlePurchase(PurchaseDetails purchase) async {
    final product = _status.product;

    switch (purchase.status) {
      case PurchaseStatus.pending:
        _emit(IAPStatus(state: IAPState.purchasing, product: product));

      case PurchaseStatus.purchased:
      case PurchaseStatus.restored:
        await _verifyAndComplete(purchase);

      case PurchaseStatus.error:
        _emit(IAPStatus(
          state: IAPState.error,
          product: product,
          errorMessage:
              purchase.error?.message ?? 'Purchase failed. Please try again.',
        ));
        if (purchase.pendingCompletePurchase) {
          await InAppPurchase.instance.completePurchase(purchase);
        }

      case PurchaseStatus.canceled:
        _emit(IAPStatus(state: IAPState.available, product: product));
        if (purchase.pendingCompletePurchase) {
          await InAppPurchase.instance.completePurchase(purchase);
        }
    }
  }

  Future<void> _verifyAndComplete(PurchaseDetails purchase) async {
    final product = _status.product;

    try {
      final token = purchase.verificationData.serverVerificationData;

      if (!kIsWeb && Platform.isIOS) {
        await _subscriptionService.verifyIos(token);
      } else {
        await _subscriptionService.verifyAndroid(token);
      }

      _emit(IAPStatus(state: IAPState.available, product: product));
      _onPurchaseCompleted();
    } catch (e) {
      _emit(IAPStatus(
        state: IAPState.error,
        product: product,
        errorMessage: 'Verification failed: $e',
      ));
    } finally {
      if (purchase.pendingCompletePurchase) {
        await InAppPurchase.instance.completePurchase(purchase);
      }
    }
  }

  void _onStreamDone() {
    _subscription?.cancel();
  }

  void _onStreamError(dynamic error) {
    debugPrint('IAP stream error: $error');
  }

  void dispose() {
    _subscription?.cancel();
    _statusController.close();
  }
}
