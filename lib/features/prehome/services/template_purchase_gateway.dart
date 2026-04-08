import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

import 'package:mana_poster/features/image_editor/services/pro_purchase_gateway.dart';

class TemplatePurchaseGateway {
  TemplatePurchaseGateway({
    InAppPurchase? inAppPurchase,
  }) : _inAppPurchase = inAppPurchase ?? InAppPurchase.instance;

  final InAppPurchase _inAppPurchase;

  Future<PurchaseFlowOutcome> purchaseTemplate({
    required String productId,
    List<String> fallbackProductIds = const <String>[],
  }) async {
    final available = await _inAppPurchase.isAvailable();
    if (!available) {
      return const PurchaseFlowOutcome(
        result: PurchaseFlowResult.billingUnavailable,
      );
    }

    final targetProductIds = <String>{productId, ...fallbackProductIds};
    final query = await _inAppPurchase.queryProductDetails(targetProductIds);
    if (query.error != null) {
      return const PurchaseFlowOutcome(result: PurchaseFlowResult.failed);
    }
    if (query.productDetails.isEmpty) {
      return const PurchaseFlowOutcome(result: PurchaseFlowResult.productNotFound);
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

    return _waitForPurchaseResult(
      acceptedProductIds: targetProductIds,
      timeout: const Duration(minutes: 2),
      timeoutResult: const PurchaseFlowOutcome(
        result: PurchaseFlowResult.timedOut,
      ),
      trigger: () => _inAppPurchase.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: selectedDetails),
      ),
    );
  }

  Future<Set<String>> restoreTemplateProductIds(Set<String> productIds) async {
    final available = await _inAppPurchase.isAvailable();
    if (!available || productIds.isEmpty) {
      return <String>{};
    }

    final restored = <String>{};
    final completer = Completer<void>();
    late final StreamSubscription<List<PurchaseDetails>> subscription;

    subscription = _inAppPurchase.purchaseStream.listen(
      (updates) async {
        for (final purchase in updates) {
          if (!productIds.contains(purchase.productID)) {
            continue;
          }
          if (purchase.pendingCompletePurchase) {
            await _inAppPurchase.completePurchase(purchase);
          }
          if (purchase.status == PurchaseStatus.purchased ||
              purchase.status == PurchaseStatus.restored) {
            restored.add(purchase.productID);
          }
        }
      },
      onError: (_) {},
      onDone: () {
        if (!completer.isCompleted) {
          completer.complete();
        }
      },
    );

    try {
      await _inAppPurchase.restorePurchases();
      await Future<void>.delayed(const Duration(seconds: 4));
    } finally {
      if (!completer.isCompleted) {
        completer.complete();
      }
      await subscription.cancel();
    }

    return restored;
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
          if (purchase.pendingCompletePurchase) {
            await _inAppPurchase.completePurchase(purchase);
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
