import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:mana_poster/app/config/subscription_plan_config.dart';
import 'package:mana_poster/features/prehome/services/subscription_store_price.dart';

PricingPhaseWrapper phase(
  String price,
  String period, {
  bool recurring = true,
}) {
  return PricingPhaseWrapper(
    billingCycleCount: recurring ? 0 : 1,
    billingPeriod: period,
    formattedPrice: price,
    priceAmountMicros: 0,
    priceCurrencyCode: 'INR',
    recurrenceMode: recurring
        ? RecurrenceMode.infiniteRecurring
        : RecurrenceMode.finiteRecurring,
  );
}

SubscriptionOfferDetailsWrapper offer(
  String basePlan,
  List<PricingPhaseWrapper> phases, {
  String? offerId,
}) => SubscriptionOfferDetailsWrapper(
  basePlanId: basePlan,
  offerId: offerId,
  offerTags: const <String>[],
  offerIdToken: 'test-token',
  pricingPhases: phases,
);

GooglePlayProductDetails product(
  List<SubscriptionOfferDetailsWrapper> offers,
) => GooglePlayProductDetails.fromProductDetails(
  ProductDetailsWrapper(
    description: 'Test subscription',
    name: 'Premium',
    productId: SubscriptionPlanConfig.primaryMonthlyProductId,
    productType: ProductType.subs,
    subscriptionOfferDetails: offers,
    title: 'Premium',
  ),
).first;

String monthly(GooglePlayProductDetails? details) => subscriptionRecurringPrice(
  product: details,
  basePlanId: SubscriptionPlanConfig.primaryMonthlyBasePlanId,
  billingPeriods: const <String>{'P1M'},
  fallback: SubscriptionPlanConfig.monthlyPriceDisplay,
);

String yearly(GooglePlayProductDetails? details) => subscriptionRecurringPrice(
  product: details,
  basePlanId: SubscriptionPlanConfig.primaryYearlyBasePlanId,
  billingPeriods: const <String>{'P1Y', 'P12M'},
  fallback: SubscriptionPlanConfig.yearlyPriceDisplay,
);

void main() {
  test('yearly-first store response cannot become the monthly price', () {
    final details = product(<SubscriptionOfferDetailsWrapper>[
      offer('yearly-699', <PricingPhaseWrapper>[phase('₹699.00', 'P1Y')]),
      offer('monthly-149', <PricingPhaseWrapper>[phase('₹99.00', 'P1M')]),
    ]);
    expect(details.price, '₹699.00');
    expect(monthly(details), '₹99.00');
    expect(yearly(details), '₹699.00');
  });

  test('trial-first response uses the monthly renewal, not the ₹4 phase', () {
    final details = product(<SubscriptionOfferDetailsWrapper>[
      offer('monthly-149', <PricingPhaseWrapper>[
        phase('₹4.00', 'P3D', recurring: false),
        phase('₹99.00', 'P1M'),
      ], offerId: 'intro-4rs-3days'),
    ]);
    expect(details.price, '₹4.00');
    expect(monthly(details), '₹99.00');
  });

  test('monthly-first response resolves yearly independently', () {
    final details = product(<SubscriptionOfferDetailsWrapper>[
      offer('monthly-149', <PricingPhaseWrapper>[phase('₹99.00', 'P1M')]),
      offer('yearly-699', <PricingPhaseWrapper>[phase('₹699.00', 'P12M')]),
    ]);
    expect(yearly(details), '₹699.00');
  });

  test(
    'base plan price takes precedence over finite introductory discounts',
    () {
      final details = product(<SubscriptionOfferDetailsWrapper>[
        offer('monthly-149', <PricingPhaseWrapper>[
          phase('₹10.00', 'P1M', recurring: false),
          phase('₹99.00', 'P1M'),
        ], offerId: 'intro-discount'),
        offer('monthly-149', <PricingPhaseWrapper>[phase('₹99.00', 'P1M')]),
      ]);
      expect(monthly(details), '₹99.00');
    },
  );

  test('missing plans and offline store use independent configured prices', () {
    expect(monthly(null), '₹99');
    expect(yearly(null), '₹699');
    final details = product(<SubscriptionOfferDetailsWrapper>[
      offer('yearly-699', <PricingPhaseWrapper>[phase('₹699.00', 'P1Y')]),
    ]);
    expect(monthly(details), '₹99');
    expect(SubscriptionPlanConfig.trialPriceDisplay, '₹4');
    expect(SubscriptionPlanConfig.trialDays, 3);
  });

  test('unexpected billing period cannot be relabeled as monthly', () {
    final details = product(<SubscriptionOfferDetailsWrapper>[
      offer('monthly-149', <PricingPhaseWrapper>[phase('₹699.00', 'P1Y')]),
    ]);
    expect(monthly(details), '₹99');
  });

  test(
    'actual store prices stay authoritative until Play Console is updated',
    () {
      final details = product(<SubscriptionOfferDetailsWrapper>[
        offer('yearly-699', <PricingPhaseWrapper>[phase('₹799.00', 'P1Y')]),
      ]);
      expect(yearly(details), '₹799.00');
      expect(monthly(details), '₹99');
    },
  );
}
