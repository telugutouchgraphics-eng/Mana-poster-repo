import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode, kIsWeb;
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:mana_poster/app/config/subscription_plan_config.dart';
import 'package:mana_poster/features/image_editor/services/play_billing_account_binding_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PurchaseProductIds {
  const PurchaseProductIds._();

  static const String premiumMonthly149 =
      SubscriptionPlanConfig.primaryMonthlyProductId;
}

enum PurchaseFlowResult {
  success,
  pending,
  cancelled,
  failed,
  billingUnavailable,
  productNotFound,
  timedOut,
  nothingToRestore,
  purchaseInProgress,
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

class BillingPurchaseEvent {
  const BillingPurchaseEvent({
    required this.productId,
    required this.status,
    required this.evidence,
  });

  final String productId;
  final PurchaseStatus status;
  final PurchaseVerificationEvidence evidence;
}

class BillingPurchaseCoordinator {
  BillingPurchaseCoordinator._();

  static final BillingPurchaseCoordinator instance =
      BillingPurchaseCoordinator._();

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  final StreamController<BillingPurchaseEvent> _events =
      StreamController<BillingPurchaseEvent>.broadcast();

  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  Future<void>? _initializeFuture;
  bool _purchaseFlowActive = false;
  Completer<PurchaseFlowOutcome>? _activeFlowCompleter;
  StreamSubscription<BillingPurchaseEvent>? _activeFlowSubscription;

  bool get isPurchaseFlowActive => _purchaseFlowActive;

  Future<void> initialize() async {
    final existing = _initializeFuture;
    if (existing != null) {
      return existing;
    }
    final future = _initializeOnce();
    _initializeFuture = future;
    try {
      await future;
    } catch (_) {
      _initializeFuture = null;
      rethrow;
    }
  }

  Future<void> _initializeOnce() async {
    if (_purchaseSubscription != null) {
      return;
    }
    _purchaseSubscription = _inAppPurchase.purchaseStream.listen(
      (updates) {
        for (final purchase in updates) {
          _events.add(
            BillingPurchaseEvent(
              productId: purchase.productID,
              status: purchase.status,
              evidence: _buildEvidenceForPurchase(purchase),
            ),
          );
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('purchaseStream error: $error');
      },
    );
  }

  Future<PurchaseFlowOutcome> runPurchaseFlow({
    required Future<bool> Function() trigger,
    required Set<String> acceptedProductIds,
    required Duration timeout,
    required PurchaseFlowOutcome timeoutResult,
    bool acceptRestored = false,
  }) async {
    await initialize();
    if (_purchaseFlowActive) {
      return const PurchaseFlowOutcome(
        result: PurchaseFlowResult.purchaseInProgress,
      );
    }

    _purchaseFlowActive = true;
    final completer = Completer<PurchaseFlowOutcome>();
    late final StreamSubscription<BillingPurchaseEvent> subscription;
    _activeFlowCompleter = completer;

    void completeIfPending(PurchaseFlowOutcome result) {
      if (!completer.isCompleted) {
        completer.complete(result);
      }
    }

    subscription = _events.stream
        .where((event) => acceptedProductIds.contains(event.productId))
        .listen(
          (event) {
            switch (event.status) {
              case PurchaseStatus.purchased:
                completeIfPending(
                  PurchaseFlowOutcome(
                    result: PurchaseFlowResult.success,
                    evidence: event.evidence,
                  ),
                );
              case PurchaseStatus.restored:
                if (acceptRestored) {
                  completeIfPending(
                    PurchaseFlowOutcome(
                      result: PurchaseFlowResult.success,
                      evidence: event.evidence,
                    ),
                  );
                }
              case PurchaseStatus.pending:
                completeIfPending(
                  PurchaseFlowOutcome(
                    result: PurchaseFlowResult.pending,
                    evidence: event.evidence,
                  ),
                );
              case PurchaseStatus.canceled:
                completeIfPending(
                  const PurchaseFlowOutcome(
                    result: PurchaseFlowResult.cancelled,
                  ),
                );
              case PurchaseStatus.error:
                completeIfPending(
                  const PurchaseFlowOutcome(result: PurchaseFlowResult.failed),
                );
            }
          },
          onError: (_) => completeIfPending(
            const PurchaseFlowOutcome(result: PurchaseFlowResult.failed),
          ),
        );
    _activeFlowSubscription = subscription;

    try {
      final launched = await trigger();
      if (!launched) {
        completeIfPending(
          const PurchaseFlowOutcome(result: PurchaseFlowResult.failed),
        );
      }
      return await completer.future.timeout(
        timeout,
        onTimeout: () => timeoutResult,
      );
    } catch (_) {
      return const PurchaseFlowOutcome(result: PurchaseFlowResult.failed);
    } finally {
      await subscription.cancel();
      if (identical(_activeFlowSubscription, subscription)) {
        _activeFlowSubscription = null;
      }
      if (identical(_activeFlowCompleter, completer)) {
        _activeFlowCompleter = null;
      }
      _purchaseFlowActive = false;
    }
  }

  Future<void> abandonActivePurchaseFlow({
    PurchaseFlowResult result = PurchaseFlowResult.cancelled,
  }) async {
    final completer = _activeFlowCompleter;
    final subscription = _activeFlowSubscription;

    if (completer != null && !completer.isCompleted) {
      completer.complete(PurchaseFlowOutcome(result: result));
    }
    _activeFlowCompleter = null;
    _activeFlowSubscription = null;
    _purchaseFlowActive = false;

    if (subscription != null) {
      await subscription.cancel();
    }
  }

  Future<Set<String>> collectRestoredProductIds({
    required Future<bool> Function() trigger,
    required Set<String> acceptedProductIds,
    required Duration timeout,
  }) async {
    await initialize();
    if (_purchaseFlowActive) {
      return <String>{};
    }

    _purchaseFlowActive = true;
    final restored = <String>{};
    late final StreamSubscription<BillingPurchaseEvent> subscription;

    subscription = _events.stream
        .where((event) => acceptedProductIds.contains(event.productId))
        .listen((event) {
          if (event.status == PurchaseStatus.purchased ||
              event.status == PurchaseStatus.restored) {
            restored.add(event.productId);
          }
        });

    try {
      final launched = await trigger();
      if (!launched) {
        return restored;
      }
      await Future<void>.delayed(timeout);
      return restored;
    } catch (_) {
      return restored;
    } finally {
      await subscription.cancel();
      _purchaseFlowActive = false;
    }
  }

  static PurchaseVerificationEvidence _buildEvidenceForPurchase(
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
          ? () => InAppPurchase.instance.completePurchase(purchase)
          : null,
    );
  }
}

abstract class ProPurchaseGateway {
  const ProPurchaseGateway();

  Future<void> initialize();
  Future<PurchaseFlowOutcome> purchaseMonthlyPro();
  Future<PurchaseFlowOutcome> restorePurchases();
  Future<void> abandonPendingPurchaseFlow();
  bool get isPurchaseFlowActive;
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

  @override
  Future<void> abandonPendingPurchaseFlow() async {}

  @override
  bool get isPurchaseFlowActive => false;
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

  static const String _playStoreProActiveKey =
      'mana_poster_play_store_pro_active_v1';
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
    await BillingPurchaseCoordinator.instance.initialize();
  }

  @override
  bool get isPurchaseFlowActive =>
      BillingPurchaseCoordinator.instance.isPurchaseFlowActive;

  @override
  Future<PurchaseFlowOutcome> purchaseMonthlyPro() async {
    await initialize();
    final available = await _inAppPurchase.isAvailable();
    if (!available) {
      await PlayBillingAccountBindingService.instance
          .clearPendingSubscriptionBinding(reason: 'billing_unavailable');
      return const PurchaseFlowOutcome(
        result: PurchaseFlowResult.billingUnavailable,
      );
    }

    final targetProductIds = _allProductIds;
    var query = await _inAppPurchase.queryProductDetails(targetProductIds);
    if (query.error != null) {
      await PlayBillingAccountBindingService.instance
          .clearPendingSubscriptionBinding(reason: 'product_query_failed');
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
      await PlayBillingAccountBindingService.instance
          .clearPendingSubscriptionBinding(reason: 'product_not_found');
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
    if (details == null) {
      await PlayBillingAccountBindingService.instance
          .clearPendingSubscriptionBinding(reason: 'target_product_not_found');
      return const PurchaseFlowOutcome(
        result: PurchaseFlowResult.productNotFound,
      );
    }
    final selectedDetails = details;
    if (!_canLaunchPurchaseForProduct(selectedDetails)) {
      await PlayBillingAccountBindingService.instance
          .clearPendingSubscriptionBinding(
            reason: 'unsupported_purchase_product_details',
          );
      return const PurchaseFlowOutcome(result: PurchaseFlowResult.failed);
    }
    _logSelectedProductForPurchase(selectedDetails);
    final binding = await PlayBillingAccountBindingService.instance
        .bindSubscriptionPurchaseToUid(productId: selectedDetails.id);
    if (binding == null) {
      return const PurchaseFlowOutcome(result: PurchaseFlowResult.failed);
    }
    final purchaseParam = _buildPurchaseParam(selectedDetails);
    if (purchaseParam == null) {
      await PlayBillingAccountBindingService.instance
          .clearPendingSubscriptionBinding(
            reason: 'invalid_subscription_offer_token',
          );
      return const PurchaseFlowOutcome(result: PurchaseFlowResult.failed);
    }

    final outcome = await _waitForPurchaseResult(
      acceptedProductIds: targetProductIds,
      timeout: const Duration(minutes: 5),
      timeoutResult: const PurchaseFlowOutcome(
        result: PurchaseFlowResult.timedOut,
      ),
      trigger: () =>
          _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam),
      acceptRestored: false,
    );
    if (outcome.result == PurchaseFlowResult.cancelled ||
        outcome.result == PurchaseFlowResult.failed ||
        outcome.result == PurchaseFlowResult.productNotFound ||
        outcome.result == PurchaseFlowResult.billingUnavailable) {
      await PlayBillingAccountBindingService.instance
          .clearPendingSubscriptionBinding(
            reason: 'purchase_flow_${outcome.result.name}',
          );
    }
    return outcome;
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
    if (localActivePurchase != null &&
        await _canCurrentUserClaimUnverifiedPurchase(
          localActivePurchase,
          trigger: 'local_query_past_purchases',
        )) {
      return PurchaseFlowOutcome(
        result: PurchaseFlowResult.success,
        evidence: localActivePurchase,
      );
    }

    final restoreResult = await _waitForPurchaseResult(
      acceptedProductIds: _allProductIds,
      timeout: const Duration(seconds: 90),
      timeoutResult: const PurchaseFlowOutcome(
        result: PurchaseFlowResult.nothingToRestore,
      ),
      trigger: () async {
        await _inAppPurchase.restorePurchases();
        return true;
      },
      acceptRestored: true,
    );
    if (restoreResult.result == PurchaseFlowResult.success &&
        restoreResult.evidence != null &&
        await _canCurrentUserClaimUnverifiedPurchase(
          restoreResult.evidence!,
          trigger: 'restore_purchases',
        )) {
      return restoreResult;
    }

    final fallbackPurchase = await _findExistingPurchaseLocally();
    if (fallbackPurchase != null &&
        await _canCurrentUserClaimUnverifiedPurchase(
          fallbackPurchase,
          trigger: 'restore_query_past_purchases',
        )) {
      return PurchaseFlowOutcome(
        result: PurchaseFlowResult.success,
        evidence: fallbackPurchase,
      );
    }

    return const PurchaseFlowOutcome(
      result: PurchaseFlowResult.nothingToRestore,
    );
  }

  Future<PurchaseVerificationEvidence?> recoverUnfinishedPurchase() async {
    await initialize();
    final evidence = await _findExistingPurchaseLocallyInternal(
      onlyPendingCompletion: true,
    );
    if (evidence == null) {
      return null;
    }
    final canClaim = await _canCurrentUserClaimUnverifiedPurchase(
      evidence,
      trigger: 'recover_pending_purchase',
    );
    return canClaim ? evidence : null;
  }

  Future<PurchaseVerificationEvidence?> _findExistingPurchaseLocally() async {
    return _findExistingPurchaseLocallyInternal(onlyPendingCompletion: false);
  }

  Future<PurchaseVerificationEvidence?> _findExistingPurchaseLocallyInternal({
    required bool onlyPendingCompletion,
  }) async {
    if (kIsWeb) {
      return null;
    }
    try {
      if (Platform.isIOS || Platform.isMacOS) {
        if (onlyPendingCompletion) {
          return null;
        }
        final addition = _inAppPurchase
            .getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
        final receipt = await addition.refreshPurchaseVerificationData();
        if (receipt == null || receipt.serverVerificationData.trim().isEmpty) {
          return null;
        }
        return PurchaseVerificationEvidence(
          productId: productId,
          source: receipt.source,
          serverVerificationData: receipt.serverVerificationData,
          localVerificationData: receipt.localVerificationData,
          status: PurchaseStatus.restored.name,
        );
      }
      if (!Platform.isAndroid) {
        return null;
      }
      final addition = _inAppPurchase
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
        if (onlyPendingCompletion && !purchase.pendingCompletePurchase) {
          continue;
        }
        return _buildEvidenceForPurchase(purchase);
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

  PurchaseParam? _buildPurchaseParam(ProductDetails productDetails) {
    if (!kIsWeb &&
        Platform.isAndroid &&
        productDetails is GooglePlayProductDetails) {
      final productType = productDetails.productDetails.productType;
      final subscriptionOffers =
          productDetails.productDetails.subscriptionOfferDetails;
      if (productType == ProductType.subs &&
          (subscriptionOffers == null || subscriptionOffers.isEmpty)) {
        _debugLog(
          'Blocked subscription purchase: no subscription offers returned.',
        );
        return null;
      }
      final selectedOffer = _selectSubscriptionOffer(subscriptionOffers);
      final offerToken =
          selectedOffer?.offerIdToken ?? productDetails.offerToken;
      if (offerToken != null && offerToken.isNotEmpty) {
        return GooglePlayPurchaseParam(
          productDetails: productDetails,
          offerToken: offerToken,
        );
      }
      if (productType == ProductType.subs) {
        _debugLog(
          'Blocked subscription purchase: selected offer token is empty.',
        );
        return null;
      }
    }
    return PurchaseParam(productDetails: productDetails);
  }

  bool _canLaunchPurchaseForProduct(ProductDetails productDetails) {
    if (kIsWeb || !Platform.isAndroid) {
      return true;
    }
    if (productDetails is! GooglePlayProductDetails) {
      return false;
    }
    if (productDetails.id.trim().isEmpty) {
      return false;
    }
    final wrappedDetails = productDetails.productDetails;
    if (wrappedDetails.productId.trim().isEmpty) {
      return false;
    }
    if (wrappedDetails.productType == ProductType.subs) {
      final offers = wrappedDetails.subscriptionOfferDetails;
      if (offers == null || offers.isEmpty) {
        return false;
      }
      final selectedOffer = _selectSubscriptionOffer(offers);
      final offerToken =
          selectedOffer?.offerIdToken ?? productDetails.offerToken;
      return offerToken != null && offerToken.trim().isNotEmpty;
    }
    return true;
  }

  SubscriptionOfferDetailsWrapper? _selectSubscriptionOffer(
    List<SubscriptionOfferDetailsWrapper>? offers,
  ) {
    if (offers == null || offers.isEmpty) {
      return null;
    }
    final preferredBasePlanId = SubscriptionPlanConfig.primaryMonthlyBasePlanId;
    final preferredOfferId = SubscriptionPlanConfig.primaryTrialOfferId;

    for (final offer in offers) {
      if (offer.basePlanId == preferredBasePlanId &&
          offer.offerId == preferredOfferId) {
        return offer;
      }
    }
    for (final offer in offers) {
      if (offer.basePlanId == preferredBasePlanId && offer.offerId == null) {
        return offer;
      }
    }
    return offers.first;
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
        final selectedOffer = _selectSubscriptionOffer(offers);
        _debugLog('basePlanId=${selectedOffer?.basePlanId}');
        _debugLog('offerId=${selectedOffer?.offerId}');
        _debugLog('offerToken=${selectedOffer?.offerIdToken}');
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
    required Future<bool> Function() trigger,
    required Set<String> acceptedProductIds,
    required Duration timeout,
    required PurchaseFlowOutcome timeoutResult,
    bool acceptRestored = false,
  }) async {
    return BillingPurchaseCoordinator.instance.runPurchaseFlow(
      trigger: trigger,
      acceptedProductIds: acceptedProductIds,
      timeout: timeout,
      timeoutResult: timeoutResult,
      acceptRestored: acceptRestored,
    );
  }

  Future<bool> _canCurrentUserClaimUnverifiedPurchase(
    PurchaseVerificationEvidence evidence, {
    required String trigger,
  }) async {
    final check = await PlayBillingAccountBindingService.instance
        .ensureCurrentUserCanClaimPendingSubscription(
          productId: evidence.productId,
          trigger: trigger,
        );
    if (check.isAllowed) {
      final binding = check.binding;
      if (binding != null) {
        final purchaseTime = _parsePurchaseTime(evidence.transactionDate);
        final earliestAllowedTime = binding.startedAt.subtract(
          const Duration(minutes: 5),
        );
        if (purchaseTime == null ||
            purchaseTime.isBefore(earliestAllowedTime)) {
          _debugLog(
            'Blocked stale Play purchase claim'
            ' trigger=$trigger'
            ' currentUid=${FirebaseAuth.instance.currentUser?.uid}'
            ' productId=${evidence.productId}'
            ' sessionId=${binding.sessionId}'
            ' purchaseTime=${evidence.transactionDate}'
            ' bindingStartedAt=${binding.startedAt.toIso8601String()}',
          );
          return false;
        }
      }
      return true;
    }
    _debugLog(
      'Blocked unverified Play purchase claim'
      ' trigger=$trigger'
      ' currentUid=${FirebaseAuth.instance.currentUser?.uid}'
      ' productId=${evidence.productId}'
      ' decision=${check.decision.name}',
    );
    return false;
  }

  DateTime? _parsePurchaseTime(String? rawValue) {
    final raw = rawValue?.trim() ?? '';
    if (raw.isEmpty) {
      return null;
    }
    final millis = int.tryParse(raw);
    if (millis != null) {
      return DateTime.fromMillisecondsSinceEpoch(millis);
    }
    return DateTime.tryParse(raw);
  }

  @override
  Future<void> abandonPendingPurchaseFlow() async {
    await BillingPurchaseCoordinator.instance.abandonActivePurchaseFlow();
  }
}
