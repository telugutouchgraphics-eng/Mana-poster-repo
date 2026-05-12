import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show debugPrint, kDebugMode, kIsWeb;
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:mana_poster/app/config/subscription_plan_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PurchaseProductIds {
  const PurchaseProductIds._();

  static const String premiumMonthly149 =
      SubscriptionPlanConfig.primaryMonthlyProductId;
}

enum PurchaseFlowResult {
  success,
  cancelled,
  failed,
  billingUnavailable,
  productNotFound,
  timedOut,
  nothingToRestore,
}

class PurchaseVerificationEvidence {
  const PurchaseVerificationEvidence({
    required this.productId,
    required this.source,
    this.serverVerificationData,
    this.localVerificationData,
    this.transactionId,
    this.transactionDate,
    this.status,
    this.completePurchase,
  });

  final String productId;
  final String source;
  final String? serverVerificationData;
  final String? localVerificationData;
  final String? transactionId;
  final String? transactionDate;
  final String? status;
  final Future<void> Function()? completePurchase;

  Future<void> completeStorePurchase() async {
    final completion = completePurchase;
    if (completion != null) {
      await completion();
    }
  }
}

class PurchaseFlowOutcome {
  const PurchaseFlowOutcome({required this.result, this.evidence});

  final PurchaseFlowResult result;
  final PurchaseVerificationEvidence? evidence;
}

abstract class ProPurchaseGateway {
  const ProPurchaseGateway();

  Future<void> initialize();
  Future<PurchaseFlowOutcome> purchaseMonthlyPro();
  Future<PurchaseFlowOutcome> restorePurchases();
}

class MockProPurchaseGateway extends ProPurchaseGateway {
  const MockProPurchaseGateway({
    this.productId = PurchaseProductIds.premiumMonthly149,
  });

  final String productId;

  @override
  Future<void> initialize() async {}

  @override
  Future<PurchaseFlowOutcome> purchaseMonthlyPro() async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    return const PurchaseFlowOutcome(result: PurchaseFlowResult.success);
  }

  @override
  Future<PurchaseFlowOutcome> restorePurchases() async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    return const PurchaseFlowOutcome(
      result: PurchaseFlowResult.nothingToRestore,
    );
  }
}

class InAppPurchaseGateway extends ProPurchaseGateway {
  InAppPurchaseGateway({
    this.productId = SubscriptionPlanConfig.primaryMonthlyProductId,
    List<String>? fallbackProductIds,
    InAppPurchase? inAppPurchase,
  }) : _fallbackProductIds =
           fallbackProductIds ??
           SubscriptionPlanConfig.resolvedPremiumProductIds().toList(),
       _inAppPurchase = inAppPurchase ?? InAppPurchase.instance;

  static StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  static final StreamController<PurchaseVerificationEvidence>
  _purchaseEvidenceController =
      StreamController<PurchaseVerificationEvidence>.broadcast();
  static const String _playStoreProActiveKey =
      'mana_poster_play_store_pro_active_v1';
  static PurchaseVerificationEvidence? _lastObservedEvidence;
  static Set<String> get _trackedSubscriptionProductIds =>
      SubscriptionPlanConfig.resolvedPremiumProductIds();
  static bool _playStoreProActive = false;

  final String productId;
  final List<String> _fallbackProductIds;
  final InAppPurchase _inAppPurchase;

  void _debugLog(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }

  static bool get playStoreProActive => _playStoreProActive;

  static Future<void> syncBackendEntitlement(bool isPro) async {
    await _setPlayStoreProActive(isPro);
  }

  Set<String> get _allProductIds {
    final ids = <String>{
      ...SubscriptionPlanConfig.resolvedPremiumProductIds(),
      productId,
      ..._fallbackProductIds,
    };
    ids.removeWhere((id) => id.trim().isEmpty);
    return ids;
  }

  @override
  Future<void> initialize() async {
    await _restoreCachedPlayStoreProState();
    if (_purchaseSubscription != null) {
      return;
    }
    _purchaseSubscription = _inAppPurchase.purchaseStream.listen(
      (updates) async {
        for (final purchase in updates) {
          final isAcknowledged = _isAcknowledgedForPurchase(purchase);
          _debugLog('purchase.status=${purchase.status.name}');
          _debugLog('productId=${purchase.productID}');
          _debugLog('isAcknowledged=$isAcknowledged');
          if (!_trackedSubscriptionProductIds.contains(purchase.productID)) {
            continue;
          }
          if (purchase.status != PurchaseStatus.purchased &&
              purchase.status != PurchaseStatus.restored) {
            continue;
          }
          final evidence = _buildEvidenceForPurchase(purchase);
          _lastObservedEvidence = evidence;
          _purchaseEvidenceController.add(evidence);
          await evidence.completeStorePurchase();
        }
      },
    );
  }

  @override
  Future<PurchaseFlowOutcome> purchaseMonthlyPro() async {
    await initialize();
    final available = await _inAppPurchase.isAvailable();
    if (!available) {
      return const PurchaseFlowOutcome(
        result: PurchaseFlowResult.billingUnavailable,
      );
    }

    final targetProductIds = _allProductIds;
    var query = await _inAppPurchase.queryProductDetails(targetProductIds);
    if (query.error != null) {
      return const PurchaseFlowOutcome(result: PurchaseFlowResult.failed);
    }
    if (query.productDetails.isEmpty) {
      for (final id in targetProductIds) {
        final retry = await _inAppPurchase.queryProductDetails(<String>{id});
        if (retry.error == null && retry.productDetails.isNotEmpty) {
          query = retry;
          break;
        }
      }
    }
    if (query.productDetails.isEmpty) {
      return const PurchaseFlowOutcome(
        result: PurchaseFlowResult.productNotFound,
      );
    }

    ProductDetails? details;
    for (final id in targetProductIds) {
      try {
        details = query.productDetails.firstWhere((item) => item.id == id);
        break;
      } catch (_) {
        continue;
      }
    }
    final selectedDetails = details ?? query.productDetails.first;
    _logSelectedProductForPurchase(selectedDetails);
    final purchaseParam = _buildPurchaseParam(selectedDetails);

    return _waitForPurchaseResult(
      acceptedProductIds: targetProductIds,
      timeout: const Duration(minutes: 5),
      timeoutResult: const PurchaseFlowOutcome(
        result: PurchaseFlowResult.timedOut,
      ),
      trigger: () => _inAppPurchase.buyNonConsumable(
        purchaseParam: purchaseParam,
      ),
    );
  }

  @override
  Future<PurchaseFlowOutcome> restorePurchases() async {
    await initialize();
    final available = await _inAppPurchase.isAvailable();
    if (!available) {
      return const PurchaseFlowOutcome(
        result: PurchaseFlowResult.billingUnavailable,
      );
    }

    final localActivePurchase = await _findExistingPurchaseLocally();
    if (localActivePurchase != null) {
      return PurchaseFlowOutcome(
        result: PurchaseFlowResult.success,
        evidence: localActivePurchase,
      );
    }

    final matchingEvidenceFuture = _purchaseEvidenceController.stream
        .firstWhere((evidence) => _allProductIds.contains(evidence.productId));
    await _inAppPurchase.restorePurchases();
    try {
      final matchedEvidence = await matchingEvidenceFuture.timeout(
        const Duration(seconds: 90),
      );
      return PurchaseFlowOutcome(
        result: PurchaseFlowResult.success,
        evidence: matchedEvidence,
      );
    } on TimeoutException {
      final lastObservedEvidence = _lastObservedEvidence;
      if (lastObservedEvidence != null &&
          _allProductIds.contains(lastObservedEvidence.productId)) {
        return PurchaseFlowOutcome(
          result: PurchaseFlowResult.success,
          evidence: lastObservedEvidence,
        );
      }
    }

    final fallbackPurchase = await _findExistingPurchaseLocally();
    if (fallbackPurchase != null) {
      return PurchaseFlowOutcome(
        result: PurchaseFlowResult.success,
        evidence: fallbackPurchase,
      );
    }

    return const PurchaseFlowOutcome(result: PurchaseFlowResult.nothingToRestore);
  }

  Future<PurchaseVerificationEvidence?> _findExistingPurchaseLocally() async {
    if (kIsWeb || !Platform.isAndroid) {
      return null;
    }
    try {
      final addition =
          _inAppPurchase
              .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
      final response = await addition.queryPastPurchases();
      if (response.error != null) {
        return null;
      }
      for (final purchase in response.pastPurchases) {
        final isAcknowledged = _isAcknowledgedForPurchase(purchase);
        _debugLog('purchase.status=${purchase.status.name}');
        _debugLog('productId=${purchase.productID}');
        _debugLog('isAcknowledged=$isAcknowledged');
        if (!_allProductIds.contains(purchase.productID)) {
          continue;
        }
        if (purchase.status != PurchaseStatus.purchased &&
            purchase.status != PurchaseStatus.restored) {
          continue;
        }
        final evidence = _buildEvidenceForPurchase(purchase);
        await evidence.completeStorePurchase();
        return evidence;
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  bool _isAcknowledgedForPurchase(PurchaseDetails purchase) {
    if (purchase is GooglePlayPurchaseDetails) {
      return purchase.billingClientPurchase.isAcknowledged;
    }
    return !purchase.pendingCompletePurchase;
  }

  PurchaseVerificationEvidence _buildEvidenceForPurchase(
    PurchaseDetails purchase,
  ) {
    return PurchaseVerificationEvidence(
      productId: purchase.productID,
      source: purchase.verificationData.source,
      serverVerificationData: purchase.verificationData.serverVerificationData,
      localVerificationData: purchase.verificationData.localVerificationData,
      transactionId: purchase.purchaseID,
      transactionDate: purchase.transactionDate,
      status: purchase.status.name,
      completePurchase: purchase.pendingCompletePurchase
          ? () => _inAppPurchase.completePurchase(purchase)
          : null,
    );
  }

  PurchaseParam _buildPurchaseParam(ProductDetails productDetails) {
    if (!kIsWeb && Platform.isAndroid && productDetails is GooglePlayProductDetails) {
      final subscriptionOffers = productDetails.productDetails.subscriptionOfferDetails;
      final offerToken =
          subscriptionOffers != null && subscriptionOffers.isNotEmpty
          ? subscriptionOffers.first.offerIdToken
          : productDetails.offerToken;
      if (offerToken != null && offerToken.isNotEmpty) {
        return GooglePlayPurchaseParam(
          productDetails: productDetails,
          offerToken: offerToken,
        );
      }
    }
    return PurchaseParam(productDetails: productDetails);
  }

  void _logSelectedProductForPurchase(ProductDetails selectedDetails) {
    _debugLog('productId=${selectedDetails.id}');
    _debugLog(
      'isGooglePlayProduct=${selectedDetails is GooglePlayProductDetails}',
    );
    if (!kIsWeb &&
        Platform.isAndroid &&
        selectedDetails is GooglePlayProductDetails) {
      final offers = selectedDetails.productDetails.subscriptionOfferDetails;
      _debugLog('offersCount=${offers?.length ?? 0}');
      if (offers != null && offers.isNotEmpty) {
        _debugLog('offerToken=${offers.first.offerIdToken}');
      }
    }
  }

  static Future<void> _restoreCachedPlayStoreProState() async {
    final prefs = await SharedPreferences.getInstance();
    _playStoreProActive = prefs.getBool(_playStoreProActiveKey) ?? false;
  }

  static Future<void> _setPlayStoreProActive(bool value) async {
    if (_playStoreProActive == value) {
      return;
    }
    _playStoreProActive = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_playStoreProActiveKey, value);
  }

  Future<PurchaseFlowOutcome> _waitForPurchaseResult({
    required Future<void> Function() trigger,
    required Set<String> acceptedProductIds,
    required Duration timeout,
    required PurchaseFlowOutcome timeoutResult,
  }) async {
    final completer = Completer<PurchaseFlowOutcome>();
    late final StreamSubscription<List<PurchaseDetails>> subscription;

    void completeIfPending(PurchaseFlowOutcome result) {
      if (!completer.isCompleted) {
        completer.complete(result);
      }
    }

    subscription = _inAppPurchase.purchaseStream.listen(
      (updates) async {
        for (final purchase in updates) {
          if (!acceptedProductIds.contains(purchase.productID)) {
            continue;
          }
          switch (purchase.status) {
            case PurchaseStatus.purchased:
            case PurchaseStatus.restored:
              completeIfPending(
                PurchaseFlowOutcome(
                  result: PurchaseFlowResult.success,
                  evidence: PurchaseVerificationEvidence(
                    productId: purchase.productID,
                    source: purchase.verificationData.source,
                    serverVerificationData:
                        purchase.verificationData.serverVerificationData,
                    localVerificationData:
                        purchase.verificationData.localVerificationData,
                    transactionId: purchase.purchaseID,
                    transactionDate: purchase.transactionDate,
                    status: purchase.status.name,
                    completePurchase: purchase.pendingCompletePurchase
                        ? () => _inAppPurchase.completePurchase(purchase)
                        : null,
                  ),
                ),
              );
            case PurchaseStatus.canceled:
              completeIfPending(
                const PurchaseFlowOutcome(result: PurchaseFlowResult.cancelled),
              );
            case PurchaseStatus.error:
              completeIfPending(
                const PurchaseFlowOutcome(result: PurchaseFlowResult.failed),
              );
            case PurchaseStatus.pending:
              break;
          }
        }
      },
      onError: (_) => completeIfPending(
        const PurchaseFlowOutcome(result: PurchaseFlowResult.failed),
      ),
    );

    try {
      await trigger();
      return await completer.future.timeout(
        timeout,
        onTimeout: () => timeoutResult,
      );
    } catch (_) {
      return const PurchaseFlowOutcome(result: PurchaseFlowResult.failed);
    } finally {
      await subscription.cancel();
    }
  }
}
