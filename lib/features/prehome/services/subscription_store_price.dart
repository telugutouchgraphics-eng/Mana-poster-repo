import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

/// Resolves the recurring price of a specific base plan, independent of which
/// offer Google Play returned first. Introductory phases are never renewal prices.
String subscriptionRecurringPrice({
  required ProductDetails? product,
  required String basePlanId,
  required Set<String> billingPeriods,
  required String fallback,
}) {
  if (product is! GooglePlayProductDetails) return fallback;
  final offers = product.productDetails.subscriptionOfferDetails;
  if (offers == null) return fallback;
  final matching = offers.where((offer) => offer.basePlanId == basePlanId);
  // Prefer the base plan without discounts, then an offer's renewal phase.
  for (final baseOnly in <bool>[true, false]) {
    for (final offer in matching) {
      if (baseOnly != (offer.offerId == null)) continue;
      for (final phase in offer.pricingPhases.reversed) {
        if (phase.recurrenceMode == RecurrenceMode.infiniteRecurring &&
            billingPeriods.contains(phase.billingPeriod) &&
            phase.formattedPrice.trim().isNotEmpty) {
          return phase.formattedPrice.trim();
        }
      }
    }
  }
  return fallback;
}
