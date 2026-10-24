import 'package:flutter_test/flutter_test.dart';
import 'package:mana_poster/app/config/subscription_plan_config.dart';
import 'package:mana_poster/features/prehome/services/purchase_invoice_service.dart';

void main() {
  Map<String, dynamic> event({
    String basePlan = 'monthly-149',
    String? paidUnits,
  }) => {
    'productId': SubscriptionPlanConfig.primaryMonthlyProductId,
    'basePlanId': basePlan,
    if (paidUnits != null) ...{
      'invoicePriceSource': 'google_play_order',
      'paidPrice': {'currencyCode': 'INR', 'units': paidUnits, 'nanos': 0},
    },
  };

  test('legacy events never adopt the current catalog price', () {
    final invoice = PurchaseInvoice.fromFirestore('old', event());
    expect(invoice.priceLabel, isEmpty);
    expect(invoice.billingPeriod, InvoiceBillingPeriod.monthly);
  });
  test('keeps the recorded 149 and 99 amounts distinct', () {
    expect(
      PurchaseInvoice.fromFirestore('old', event(paidUnits: '149')).priceLabel,
      '₹149.00',
    );
    expect(
      PurchaseInvoice.fromFirestore('new', event(paidUnits: '99')).priceLabel,
      '₹99.00',
    );
  });
  test('recognizes yearly purchases with and without an amount record', () {
    for (final price in [null, '699']) {
      final invoice = PurchaseInvoice.fromFirestore(
        'yearly',
        event(basePlan: 'yearly-699', paidUnits: price),
      );
      expect(invoice.billingPeriod, InvoiceBillingPeriod.yearly);
      expect(invoice.priceLabel, price == null ? '' : '₹699.00');
    }
  });
  test('uses order plan and date instead of current entitlement metadata', () {
    final invoice = PurchaseInvoice.fromFirestore('order', {
      ...event(paidUnits: '699'),
      'invoiceBasePlanId': 'yearly-699',
      'invoiceTransactionDate': '2026-09-01T00:00:00Z',
      'transactionDate': '2026-10-08T00:00:00Z',
    });
    expect(invoice.billingPeriod, InvoiceBillingPeriod.yearly);
    expect(invoice.transactionAt, DateTime.utc(2026, 9, 1));
  });
  test('introductory amounts remain separate from recurring plan price', () {
    final invoice = PurchaseInvoice.fromFirestore('trial', {
      ...event(paidUnits: '4'),
      'invoiceIsTrialOrIntro': true,
    });
    expect(invoice.billingPeriod, InvoiceBillingPeriod.introductory);
    expect(invoice.priceLabel, '₹4.00');
  });
  test('rejects invalid amounts and unverified price metadata', () {
    expect(
      PurchaseInvoice.fromFirestore(
        'invalid',
        event(paidUnits: '-149'),
      ).priceLabel,
      isEmpty,
    );
    expect(
      PurchaseInvoice.fromFirestore('unverified', {
        ...event(paidUnits: '99'),
        'invoicePriceSource': 'catalog',
      }).priceLabel,
      isEmpty,
    );
  });

  test('preserves zero, fractional precision and foreign currencies', () {
    final invoice = PurchaseInvoice.fromFirestore('fraction', {
      ...event(paidUnits: '0'),
      'paidPrice': {'currencyCode': 'KWD', 'units': '0', 'nanos': 125000000},
    });
    expect(invoice.priceLabel, 'KWD 0.125');
    expect(
      PurchaseInvoice.fromFirestore('free', event(paidUnits: '0')).priceLabel,
      '₹0.00',
    );
  });
}
