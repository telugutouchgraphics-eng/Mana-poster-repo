const {test} = require("node:test");
const assert = require("node:assert/strict");
const {subscriptionInvoiceSnapshot} = require("./subscription_invoice");
const identity = {orderId: "GPA.example..0", purchaseToken: "test-token", productId: "premium"};
function order(units, basePlanId = "monthly-149", phase = {baseDetails: {}}) {
  return {...identity, state: "PROCESSED", createTime: "2026-09-01T00:00:00Z", lineItems: [{
    productId: identity.productId,
    total: {currencyCode: "INR", units, nanos: 0},
    subscriptionDetails: {basePlanId, offerPhaseDetails: phase},
  }]};
}
test("records original paid 149, new 99 and yearly 699 independently of catalog", () => {
  for (const units of ["149", "99", "699"]) {
    assert.equal(subscriptionInvoiceSnapshot(order(units), identity).paidPrice.units, units);
  }
  assert.equal(subscriptionInvoiceSnapshot(order("699", "yearly-699"), identity).invoiceBasePlanId, "yearly-699");
});
test("distinguishes introductory payment from renewal on the same offer", () => {
  assert.equal(subscriptionInvoiceSnapshot(order("4", "monthly-149", {introductoryPriceDetails: {}}), identity).invoiceIsTrialOrIntro, true);
  assert.equal(subscriptionInvoiceSnapshot(order("99"), identity).invoiceIsTrialOrIntro, false);
});
test("does not manufacture a paid amount for missing, invalid or unrelated orders", () => {
  for (const patch of [{orderId: "other"}, {purchaseToken: "other"}, {state: "PENDING"}, {lineItems: []}]) {
    assert.deepEqual(subscriptionInvoiceSnapshot({...order("149"), ...patch}, identity), {});
  }
  const invalid = order("149");
  invalid.lineItems[0].total.nanos = -1;
  assert.deepEqual(subscriptionInvoiceSnapshot(invalid, identity), {});
});
test("preserves fractional and zero amounts, excluding revenue and listing price", () => {
  const paidOrder = order("0");
  paidOrder.lineItems[0].listingPrice = {currencyCode: "INR", units: "149"};
  paidOrder.lineItems[0].total.nanos = 500000000;
  assert.deepEqual(subscriptionInvoiceSnapshot(paidOrder, identity).paidPrice, {currencyCode: "INR", units: "0", nanos: 500000000});
});

test("optional order lookup failure cannot reject subscription verification", async () => {
  const fs = require("node:fs");
  const vm = require("node:vm");
  const source = fs.readFileSync(require.resolve("./index.js"), "utf8");
  const helper = source.slice(source.indexOf("async function fetchSubscriptionInvoiceSnapshot("), source.indexOf("function isActiveSubscriptionState("));
  const context = vm.createContext({
    playPackageName: "com.manaposter.app",
    subscriptionInvoiceSnapshot,
    logger: {warn() {}},
    getAndroidPublisherClient: async () => ({context: {_options: {auth: {
      request: async () => {throw new Error("Order lookup permission denied");},
    }}}}),
  });
  vm.runInContext(helper, context);
  const result = await context.fetchSubscriptionInvoiceSnapshot({latestOrderId: identity.orderId}, identity.purchaseToken);
  assert.equal(Object.keys(result).length, 0);
});
