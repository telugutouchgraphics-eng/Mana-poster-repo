// Invoice amounts come from an order, never from the current catalog price.
function subscriptionInvoiceSnapshot(order, {orderId, purchaseToken, productId}) {
  if (order?.orderId !== orderId || order?.purchaseToken !== purchaseToken ||
      order?.state !== "PROCESSED") {
    return {};
  }
  const items = Array.isArray(order.lineItems) ? order.lineItems : [];
  const item = items.find((entry) => entry.productId === productId && entry.subscriptionDetails);
  if (!item) return {};
  const money = item.total;
  const units = String(money?.units ?? "0");
  const nanos = money?.nanos ?? 0;
  if (!/^[A-Z]{3}$/.test(money?.currencyCode || "") || !/^\d+$/.test(units) ||
      !Number.isInteger(nanos) || nanos < 0 || nanos >= 1000000000) {
    return {};
  }
  const details = item.subscriptionDetails;
  const phase = details.offerPhaseDetails;
  const introductory = phase ?
    !!(phase.freeTrialDetails || phase.introductoryPriceDetails) :
    ["FREE_TRIAL", "INTRODUCTORY"].includes(details.offerPhase);
  return {
    paidPrice: {currencyCode: money.currencyCode, units, nanos},
    invoiceBasePlanId: details.basePlanId || null,
    invoiceIsTrialOrIntro: introductory,
    invoiceTransactionDate: order.createTime || null,
    invoicePriceSource: "google_play_order",
  };
}

module.exports = {subscriptionInvoiceSnapshot};
