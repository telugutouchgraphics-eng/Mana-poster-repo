const admin = require("firebase-admin");
const {onRequest} = require("firebase-functions/v2/https");
const {logger} = require("firebase-functions");

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();
const supportedProductIds = new Set([
  "pro_monthly_20",
  "mana_poster_pro_monthly_20",
]);

function setCors(res) {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Headers", "Authorization, Content-Type");
  res.set("Access-Control-Allow-Methods", "POST, OPTIONS");
}

async function verifyAuth(req) {
  const auth = req.headers.authorization || "";
  if (!auth.startsWith("Bearer ")) {
    throw new Error("Missing bearer token");
  }
  const token = auth.slice("Bearer ".length).trim();
  if (!token) {
    throw new Error("Missing bearer token");
  }
  return admin.auth().verifyIdToken(token);
}

exports.verifySubscription = onRequest({region: "asia-south1"}, async (req, res) => {
  setCors(res);
  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }
  if (req.method !== "POST") {
    res.status(405).json({isPro: false, message: "Method not allowed"});
    return;
  }

  try {
    const decoded = await verifyAuth(req);
    const payload = req.body || {};
    const uid = decoded.uid;
    const productId = String(payload.productId || "").trim();
    const source = String(payload.verificationSource || "").trim();
    const token = String(payload.serverVerificationData || "").trim();
    const localVerificationData = String(payload.localVerificationData || "");
    const transactionId = String(payload.transactionId || "");
    const transactionDate = String(payload.transactionDate || "");
    const purchaseStatus = String(payload.purchaseStatus || "");
    const platform = String(payload.platform || "");

    const isValid =
      supportedProductIds.has(productId) &&
      source.length > 0 &&
      token.length > 0 &&
      (purchaseStatus === "purchased" || purchaseStatus === "restored" || purchaseStatus.length === 0);

    const entitlementRef = db.doc(`users/${uid}/entitlements/pro`);
    const eventRef = db.collection(`users/${uid}/purchaseEvents`).doc();
    const now = admin.firestore.FieldValue.serverTimestamp();

    await db.runTransaction(async (tx) => {
      tx.set(
        entitlementRef,
        {
          isPro: isValid,
          productId: productId || null,
          source: source || null,
          platform: platform || null,
          verificationTokenHash: token ? token.slice(0, 24) : null,
          lastTransactionId: transactionId || null,
          lastTransactionDate: transactionDate || null,
          updatedAt: now,
          status: isValid ? "active" : "inactive",
        },
        {merge: true},
      );

      tx.set(eventRef, {
        type: "verify",
        isPro: isValid,
        productId: productId || null,
        source: source || null,
        platform: platform || null,
        localVerificationData: localVerificationData || null,
        transactionId: transactionId || null,
        transactionDate: transactionDate || null,
        purchaseStatus: purchaseStatus || null,
        createdAt: now,
      });
    });

    res.status(200).json({
      isPro: isValid,
      message: isValid ? "Verification success" : "Verification failed",
    });
  } catch (error) {
    logger.error("verifySubscription error", error);
    res.status(401).json({
      isPro: false,
      message: error instanceof Error ? error.message : "Unauthorized",
    });
  }
});

exports.subscriptionStatus = onRequest({region: "asia-south1"}, async (req, res) => {
  setCors(res);
  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }
  if (req.method !== "POST") {
    res.status(405).json({isPro: false, message: "Method not allowed"});
    return;
  }

  try {
    const decoded = await verifyAuth(req);
    const uid = decoded.uid;

    const entitlementRef = db.doc(`users/${uid}/entitlements/pro`);
    const snap = await entitlementRef.get();
    const data = snap.data() || {};
    const isPro = data.isPro === true;

    res.status(200).json({
      isPro,
      message: isPro ? "Entitlement active" : "Entitlement inactive",
      status: data.status || null,
      productId: data.productId || null,
    });
  } catch (error) {
    logger.error("subscriptionStatus error", error);
    res.status(401).json({
      isPro: false,
      message: error instanceof Error ? error.message : "Unauthorized",
    });
  }
});
