import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

class PurchaseProductIds {
  const PurchaseProductIds._();

  static const String premiumMonthly149 = 'mana_poster_premium_monthly_149';
  static const String premiumMonthly149Legacy =
      'mana_poster_premium_monthly_149_legacy';
  static const String proMonthly20 = 'pro_monthly_20';
  static const String proMonthlyLegacy = 'mana_poster_pro_monthly_20';
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
  });

  final String productId;
  final String source;
  final String? serverVerificationData;
  final String? localVerificationData;
  final String? transactionId;
  final String? transactionDate;
  final String? status;
}

class PurchaseFlowOutcome {
  const PurchaseFlowOutcome({
    required this.result,
    this.evidence,
  });

  final PurchaseFlowResult result;
  final PurchaseVerificationEvidence? evidence;
}

abstract class ProPurchaseGateway {
  const ProPurchaseGateway();

  Future<PurchaseFlowOutcome> purchaseMonthlyPro();
  Future<PurchaseFlowOutcome> restorePurchases();
}

class MockProPurchaseGateway extends ProPurchaseGateway {
  const MockProPurchaseGateway({
    this.productId = PurchaseProductIds.premiumMonthly149,
  });

  final String productId;

  @override
  Future<PurchaseFlowOutcome> purchaseMonthlyPro() async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    return const PurchaseFlowOutcome(result: PurchaseFlowResult.success);
  }

  @override
  Future<PurchaseFlowOutcome> restorePurchases() async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    return const PurchaseFlowOutcome(result: PurchaseFlowResult.nothingToRestore);
  }
}

class InAppPurchaseGateway extends ProPurchaseGateway {
  InAppPurchaseGateway({
    this.productId = PurchaseProductIds.premiumMonthly149,
    List<String>? fallbackProductIds,
    InAppPurchase? inAppPurchase,
  }) : _fallbackProductIds = fallbackProductIds ?? const <String>[
         PurchaseProductIds.premiumMonthly149Legacy,
      ],
       _inAppPurchase = inAppPurchase ?? InAppPurchase.instance;

  final String productId;
  final List<String> _fallbackProductIds;
  final InAppPurchase _inAppPurchase;

  Set<String> get _allProductIds {
    const envProductId = String.fromEnvironment(
      'MANA_POSTER_PRO_PRODUCT_ID',
      defaultValue: '',
    );
    final ids = <String>{
      productId,
      ..._fallbackProductIds,
      if (envProductId.isNotEmpty) envProductId,
    };
    return ids;
  }

  @override
  Future<PurchaseFlowOutcome> purchaseMonthlyPro() async {
    final available = await _inAppPurchase.isAvailable();
    if (!available) {
      return const PurchaseFlowOutcome(
        result: PurchaseFlowResult.billingUnavailable,
      );
    }

    final targetProductIds = _allProductIds;
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
        details = query.productDetails.firstWhere(
          (item) => item.id == id,
        );
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

  @override
  Future<PurchaseFlowOutcome> restorePurchases() async {
    final available = await _inAppPurchase.isAvailable();
    if (!available) {
      return const PurchaseFlowOutcome(
        result: PurchaseFlowResult.billingUnavailable,
      );
    }

    final result = await _waitForPurchaseResult(
      acceptedProductIds: _allProductIds,
      timeout: const Duration(seconds: 45),
      timeoutResult: const PurchaseFlowOutcome(
        result: PurchaseFlowResult.nothingToRestore,
      ),
      trigger: _inAppPurchase.restorePurchases,
    );
    if (result.result == PurchaseFlowResult.cancelled ||
        result.result == PurchaseFlowResult.failed) {
      return result;
    }
    return result.result == PurchaseFlowResult.success
        ? result
        : const PurchaseFlowOutcome(result: PurchaseFlowResult.nothingToRestore);
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
