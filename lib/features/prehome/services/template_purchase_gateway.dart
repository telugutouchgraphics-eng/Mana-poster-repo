import 'package:in_app_purchase/in_app_purchase.dart';

import 'package:mana_poster/features/image_editor/services/pro_purchase_gateway.dart';

class TemplatePurchaseGateway {
  TemplatePurchaseGateway({InAppPurchase? inAppPurchase})
    : _inAppPurchase = inAppPurchase ?? InAppPurchase.instance;

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

    return _waitForPurchaseResult(
      acceptedProductIds: targetProductIds,
      timeout: const Duration(minutes: 2),
      timeoutResult: const PurchaseFlowOutcome(
        result: PurchaseFlowResult.timedOut,
      ),
      trigger: () => _inAppPurchase.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: selectedDetails),
      ),
      acceptRestored: false,
    );
  }

  Future<Set<String>> restoreTemplateProductIds(Set<String> productIds) async {
    final available = await _inAppPurchase.isAvailable();
    if (!available || productIds.isEmpty) {
      return <String>{};
    }

    return BillingPurchaseCoordinator.instance.collectRestoredProductIds(
      trigger: () async {
        await _inAppPurchase.restorePurchases();
        return true;
      },
      acceptedProductIds: productIds,
      timeout: const Duration(seconds: 4),
    );
  }

  Future<PurchaseFlowOutcome> _waitForPurchaseResult({
    required Future<bool> Function() trigger,
    required Set<String> acceptedProductIds,
    required Duration timeout,
    required PurchaseFlowOutcome timeoutResult,
    required bool acceptRestored,
  }) async {
    return BillingPurchaseCoordinator.instance.runPurchaseFlow(
      trigger: trigger,
      acceptedProductIds: acceptedProductIds,
      timeout: timeout,
      timeoutResult: timeoutResult,
      acceptRestored: acceptRestored,
    );
  }
}
