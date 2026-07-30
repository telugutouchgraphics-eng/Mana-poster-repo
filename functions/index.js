const admin = require("firebase-admin");
const {onRequest} = require("firebase-functions/v2/https");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const {onMessagePublished} = require("firebase-functions/v2/pubsub");
const {logger} = require("firebase-functions");
const crypto = require("crypto");
const fs = require("fs");
const {google} = require("googleapis");
const path = require("path");
const puppeteer = require("puppeteer-core");
const chromium = require("@sparticuz/chromium");
const sharp = require("sharp");

// Source marker used to force runtime redeploy when firebase.json runtime changes.
const functionsRuntimeMarker = "nodejs22-2026-04-22";

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();
const subscriptionCollections = {
  tokenOwnership: "playPurchaseTokens",
  serverTokens: "serverSubscriptionTokens",
};
const subscriptionPlanConfig = {
  primaryMonthlyProductId: "mana_poster_premium_monthly_149",
  trialDays: 3,
  trialPrice: 4,
  monthlyPrice: 149,
};
const editorSubscriptionPlanConfig = {
  productId: "mana_poster_editor_pro",
  monthlyBasePlanId: "monthly-99",
  yearlyBasePlanId: "yearly-699",
};
const referralRewardConfig = {
  requiredPaidReferrals: 15,
  rewardDays: 30,
  codePrefix: "MP",
  codeHashLength: 10,
  purchaseAttributionGraceMillis: 10 * 60 * 1000,
};
const referralCollections = {
  codes: "referralCodes",
  claims: "referralClaims",
  events: "referralEvents",
};
const supportedProductIds = new Set([
  subscriptionPlanConfig.primaryMonthlyProductId,
  editorSubscriptionPlanConfig.productId,
]);
const playPackageName =
    String(process.env.MANA_POSTER_PLAY_PACKAGE_NAME || "com.manaposter.app")
        .trim();
const playSubscriptionProductIds = new Set([
  subscriptionPlanConfig.primaryMonthlyProductId,
  editorSubscriptionPlanConfig.productId,
]);
const playApiScope = ["https://www.googleapis.com/auth/androidpublisher"];
let androidPublisherClientPromise = null;
const playRtdnTopic =
    String(process.env.MANA_POSTER_PLAY_RTDN_TOPIC || "play-billing-rtdn")
        .trim();
const manaReminderToolKey = String(process.env.MANA_REMINDER_TOOL_KEY || "").trim();
const manualLifetimeWhitelistSource = "manual_lifetime_whitelist";
const manualLifetimeWhitelistedEmails = new Set([
  "manaposter2026@gmail.com",
  "shaikvaseema62@gmail.com",
  "babuy2045@gmail.com",
]);
const allowedCorsOrigins = parseAllowedOrigins(
    process.env.MANA_POSTER_ALLOWED_ORIGINS || process.env.ALLOW_ORIGIN || "*",
);

const dynamicEventCatalog = require("./dynamic_event_catalog.json");

const posterRetentionWindowMillis = 7 * 24 * 60 * 60 * 1000;
const posterCleanupBatchSize = 250;
const first150TrialConfigPath = "promo_config/first150";
const first150TrialSource = "first150_trial";
const first150TrialProductId = "first150_trial";
const first150TrialState = "FIRST150_TRIAL";
const first150TrialNewUserWindowMillis = 24 * 60 * 60 * 1000;

function parseAllowedOrigins(rawValue) {
  const raw = String(rawValue || "").trim();
  if (!raw) {
    return new Set(["*"]);
  }
  const parts = raw.split(",")
      .map((item) => item.trim())
      .filter((item) => item.length > 0);
  return new Set(parts.length > 0 ? parts : ["*"]);
}

function setCors(req, res) {
  const origin = String(req.headers.origin || "").trim();
  if (allowedCorsOrigins.has("*")) {
    res.set("Access-Control-Allow-Origin", "*");
  } else if (origin && allowedCorsOrigins.has(origin)) {
    res.set("Access-Control-Allow-Origin", origin);
    res.set("Vary", "Origin");
  }
  res.set("Access-Control-Allow-Headers", "Authorization, Content-Type");
  res.set("Access-Control-Allow-Methods", "POST, OPTIONS");
}

function sha256(value) {
  return crypto.createHash("sha256").update(String(value || "")).digest("hex");
}

function isPlayBillingConfigured() {
  return playPackageName.length > 0;
}

async function getAndroidPublisherClient() {
  if (!androidPublisherClientPromise) {
    androidPublisherClientPromise = (async () => {
      const auth = new google.auth.GoogleAuth({scopes: playApiScope});
      const authClient = await auth.getClient();
      return google.androidpublisher({
        version: "v3",
        auth: authClient,
      });
    })();
  }
  return androidPublisherClientPromise;
}

function isActiveSubscriptionState(state) {
  return new Set([
    "SUBSCRIPTION_STATE_ACTIVE",
  ]).has(String(state || ""));
}

function isExpiredSubscriptionState(state) {
  return new Set([
    "SUBSCRIPTION_STATE_EXPIRED",
    "SUBSCRIPTION_STATE_CANCELED",
    "SUBSCRIPTION_STATE_CANCELLED",
  ]).has(String(state || ""));
}

function activeTemplatePurchaseState(purchaseState) {
  return Number(purchaseState) === 0;
}

function parseValidDateTimeOrNull(value) {
  const candidate = String(value || "").trim();
  if (!candidate) {
    return null;
  }
  const date = new Date(candidate);
  return Number.isNaN(date.getTime()) ? null : date;
}

function subscriptionLineItemBasePlanId(item) {
  return String(
      item?.autoRenewingPlan?.basePlanId ||
      item?.offerDetails?.basePlanId ||
      item?.basePlanId ||
      "",
  ).trim();
}

function subscriptionLineItemOfferId(item) {
  return String(
      item?.offerDetails?.offerId ||
      item?.autoRenewingPlan?.offerId ||
      item?.offerId ||
      "",
  ).trim();
}

function subscriptionLineItemRecurringPriceUnits(item) {
  return String(
      item?.autoRenewingPlan?.recurringPrice?.units ||
      item?.autoRenewingPlan?.price?.units ||
      "",
  ).trim();
}

function looksLikeTrialOrIntroLineItem(item) {
  const offerId = subscriptionLineItemOfferId(item).toLowerCase();
  const basePlanId = subscriptionLineItemBasePlanId(item).toLowerCase();
  const offerTags = Array.isArray(item?.offerDetails?.offerTags) ?
    item.offerDetails.offerTags.map((tag) => String(tag || "").toLowerCase()) :
    [];
  const marker = [offerId, basePlanId, ...offerTags].join(" ");
  if (marker.includes("trial") || marker.includes("intro")) {
    return true;
  }
  const expiryDate = parseValidDateTimeOrNull(item?.expiryTime);
  const startDate = parseValidDateTimeOrNull(item?.startTime);
  if (!expiryDate || !startDate) {
    return false;
  }
  const durationDays = (expiryDate.getTime() - startDate.getTime()) / (1000 * 60 * 60 * 24);
  return durationDays > 0 && durationDays <= 3.1;
}

function isPreferredMonthlyBasePlanLineItem(item, productIdHint) {
  const productId = String(item?.productId || "").trim();
  if (!productIdHint || productId !== productIdHint) {
    return false;
  }
  const recurringPriceUnits = subscriptionLineItemRecurringPriceUnits(item);
  if (recurringPriceUnits && recurringPriceUnits !== String(subscriptionPlanConfig.monthlyPrice)) {
    return false;
  }
  if (looksLikeTrialOrIntroLineItem(item)) {
    return false;
  }
  return !!item?.autoRenewingPlan;
}

function selectSubscriptionEntitlementLineItem(lineItems, productIdHint = "") {
  const normalizedHint = String(productIdHint || "").trim();
  const candidates = lineItems.filter((item) => parseValidDateTimeOrNull(item?.expiryTime));
  if (!candidates.length) {
    return null;
  }
  const matchingProductItems = normalizedHint ?
    candidates.filter((item) => String(item?.productId || "").trim() === normalizedHint) :
    candidates;
  const productScopedItems = matchingProductItems.length ? matchingProductItems : candidates;
  const monthlyBasePlanItems = productScopedItems.filter((item) =>
    isPreferredMonthlyBasePlanLineItem(item, normalizedHint),
  );
  const selectionPool = monthlyBasePlanItems.length ? monthlyBasePlanItems : productScopedItems;
  return selectionPool
      .slice()
      .sort((left, right) => {
        const rightExpiry = parseValidDateTimeOrNull(right?.expiryTime)?.getTime() || 0;
        const leftExpiry = parseValidDateTimeOrNull(left?.expiryTime)?.getTime() || 0;
        return rightExpiry - leftExpiry;
      })[0];
}

async function verifySubscriptionPurchaseWithGoogle({
  purchaseToken,
}) {
  if (!isPlayBillingConfigured()) {
    throw new Error("Play Billing package name is not configured");
  }
  const publisher = await getAndroidPublisherClient();
  const response = await publisher.purchases.subscriptionsv2.get({
    packageName: playPackageName,
    token: purchaseToken,
  });
  const payload = response.data || {};
  const lineItems = Array.isArray(payload.lineItems) ? payload.lineItems : [];
  const productIds = lineItems
      .map((item) => String(item.productId || "").trim())
      .filter((item) => item.length > 0);
  const hintedProductId = productIds.find((item) => playSubscriptionProductIds.has(item)) || "";
  const primaryProductId = hintedProductId || productIds[0] || "";
  const selectedLineItem = selectSubscriptionEntitlementLineItem(
      lineItems,
      primaryProductId || subscriptionPlanConfig.primaryMonthlyProductId,
  );
  const expiryTime = firstValidDateTimeString([selectedLineItem?.expiryTime]);
  const autoRenewing = lineItems.some((item) => {
    const autoPlan = item && item.autoRenewingPlan;
    if (!autoPlan || typeof autoPlan !== "object") {
      return false;
    }
    if ("autoRenewEnabled" in autoPlan) {
      return autoPlan.autoRenewEnabled !== false;
    }
    return true;
  });
  const latestOrderId = firstNonEmptyString([
    payload.latestOrderId,
    payload.latestSuccessfulOrderId,
    selectedLineItem?.latestSuccessfulOrderId,
    ...lineItems.map((item) => item.latestSuccessfulOrderId),
  ]);
  const startTime = firstValidDateTimeString([
    payload.startTime,
    selectedLineItem?.startTime,
    ...lineItems.map((item) => item.startTime),
  ]);
  return {
    raw: payload,
    productIds,
    primaryProductId,
    basePlanId: subscriptionLineItemBasePlanId(selectedLineItem),
    linkedPurchaseToken: String(payload.linkedPurchaseToken || "").trim(),
    subscriptionState: String(payload.subscriptionState || "").trim(),
    startTime,
    expiryTime,
    autoRenewing,
    latestOrderId,
    valid:
        primaryProductId.length > 0 &&
        playSubscriptionProductIds.has(primaryProductId) &&
        isActiveSubscriptionState(payload.subscriptionState),
  };
}

function firstNonEmptyString(values) {
  for (const value of values) {
    const normalized = String(value || "").trim();
    if (normalized) {
      return normalized;
    }
  }
  return "";
}

function firstValidDateTimeString(values) {
  for (const value of values) {
    const candidate = String(value || "").trim();
    if (!candidate) {
      continue;
    }
    const date = new Date(candidate);
    if (!Number.isNaN(date.getTime())) {
      return candidate;
    }
  }
  return "";
}

function subscriptionAccessScopesForPlan({productId, basePlanId, valid}) {
  const normalizedProductId = String(productId || "").trim();
  const normalizedBasePlanId = String(basePlanId || "").trim();
  if (!valid) {
    return {appAccess: false, editorAccess: false, accessScope: "inactive"};
  }
  if (normalizedProductId === subscriptionPlanConfig.primaryMonthlyProductId) {
    return {appAccess: true, editorAccess: false, accessScope: "app"};
  }
  if (normalizedProductId === editorSubscriptionPlanConfig.productId) {
    if (normalizedBasePlanId === editorSubscriptionPlanConfig.yearlyBasePlanId) {
      return {appAccess: true, editorAccess: true, accessScope: "bundle"};
    }
    if (normalizedBasePlanId === editorSubscriptionPlanConfig.monthlyBasePlanId) {
      return {appAccess: false, editorAccess: true, accessScope: "editor"};
    }
  }
  return {appAccess: false, editorAccess: false, accessScope: "inactive"};
}

function requestedSubscriptionScope(payload) {
  const scope = String(payload?.scope || payload?.entitlementScope || "").trim().toLowerCase();
  return scope === "editor" ? "editor" : "app";
}

function isAccessActiveForScope(access, scope) {
  return scope === "editor" ? access.editorAccess === true : access.appAccess === true;
}

function toFirestoreTimestamp(value) {
  const candidate = String(value || "").trim();
  if (!candidate) {
    return null;
  }
  const date = new Date(candidate);
  if (Number.isNaN(date.getTime())) {
    return null;
  }
  return admin.firestore.Timestamp.fromDate(date);
}

function firestoreValueToIsoString(value) {
  if (!value) {
    return null;
  }
  if (typeof value.toDate === "function") {
    return value.toDate().toISOString();
  }
  const candidate = String(value || "").trim();
  if (!candidate) {
    return null;
  }
  const date = new Date(candidate);
  if (Number.isNaN(date.getTime())) {
    return null;
  }
  return date.toISOString();
}

function firestoreValueToDate(value) {
  if (!value) {
    return null;
  }
  if (value instanceof admin.firestore.Timestamp) {
    return value.toDate();
  }
  if (typeof value.toDate === "function") {
    try {
      return value.toDate();
    } catch (_) {
      return null;
    }
  }
  const candidate = new Date(value);
  return Number.isNaN(candidate.getTime()) ? null : candidate;
}

function normalizeReferralCode(value) {
  return String(value || "")
      .trim()
      .toUpperCase()
      .replace(/[^A-Z0-9]/g, "")
      .slice(0, 24);
}

function buildReferralCodeForUid(uid, hashLength = referralRewardConfig.codeHashLength) {
  const hash = sha256(`referral:${uid}`)
      .slice(0, hashLength)
      .toUpperCase();
  return `${referralRewardConfig.codePrefix}${hash}`;
}

function buildReferralLink(code) {
  const normalizedCode = normalizeReferralCode(code);
  const referrer = encodeURIComponent(`mp_ref=${normalizedCode}`);
  return `https://play.google.com/store/apps/details?id=${encodeURIComponent(playPackageName)}&referrer=${referrer}`;
}

async function ensureReferralCodeForUid(uid) {
  for (const hashLength of [10, 16, 22]) {
    const code = buildReferralCodeForUid(uid, hashLength);
    const ref = db.collection(referralCollections.codes).doc(code);
    const snap = await ref.get();
    const existingUid = String((snap.data() || {}).uid || "").trim();
    if (snap.exists && existingUid && existingUid !== uid) {
      continue;
    }
    const payload = {
      code,
      uid,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };
    if (!snap.exists) {
      payload.createdAt = admin.firestore.FieldValue.serverTimestamp();
    }
    await ref.set(payload, {merge: true});
    return code;
  }
  throw new Error("Unable to allocate referral code");
}

function referralRewardWindow(entitlementData) {
  const startsAt = firestoreValueToDate(entitlementData.referralRewardStartsAt);
  const expiresAt = firestoreValueToDate(entitlementData.referralRewardExpiresAt);
  const nowMillis = Date.now();
  const startsMillis = startsAt ? startsAt.getTime() : 0;
  const expiresMillis = expiresAt ? expiresAt.getTime() : 0;
  return {
    startsAt,
    expiresAt,
    active:
      expiresMillis > nowMillis &&
      (startsMillis === 0 || startsMillis <= nowMillis),
  };
}

async function recordPaidReferralForSubscriber({
  subscriberUid,
  productId,
  tokenHash,
  latestOrderId,
  purchaseStartTime,
}) {
  const sourceRef = db.doc(`users/${subscriberUid}/referral/source`);
  const sourceSnap = await sourceRef.get();
  if (!sourceSnap.exists) {
    return {counted: false, reason: "no_referral_source"};
  }
  const sourceData = sourceSnap.data() || {};
  const referrerUid = String(sourceData.referrerUid || "").trim();
  const referralCode = normalizeReferralCode(sourceData.referralCode);
  if (!referrerUid || referrerUid === subscriberUid) {
    return {counted: false, reason: "invalid_referrer"};
  }
  const appliedAt = firestoreValueToDate(sourceData.appliedAt);
  const purchaseStartedAt = firestoreValueToDate(purchaseStartTime);
  if (
    appliedAt &&
    purchaseStartedAt &&
    appliedAt.getTime() >
      purchaseStartedAt.getTime() +
        referralRewardConfig.purchaseAttributionGraceMillis
  ) {
    return {counted: false, reason: "purchase_started_before_referral"};
  }

  const claimRef = db.collection(referralCollections.claims).doc(subscriberUid);
  const summaryRef = db.doc(`users/${referrerUid}/referralRewards/summary`);
  const entitlementRef = db.doc(`users/${referrerUid}/entitlements/pro`);
  const eventRef = db.collection(referralCollections.events).doc();
  const nowDate = new Date();
  const nowTimestamp = admin.firestore.Timestamp.fromDate(nowDate);
  const rewardMillis = referralRewardConfig.rewardDays * 24 * 60 * 60 * 1000;
  let result = {counted: false, reason: "transaction_not_run"};

  await db.runTransaction(async (tx) => {
    const [claimSnap, summarySnap, entitlementSnap] = await Promise.all([
      tx.get(claimRef),
      tx.get(summaryRef),
      tx.get(entitlementRef),
    ]);
    if (claimSnap.exists) {
      result = {counted: false, reason: "subscriber_already_counted"};
      return;
    }

    const summary = summarySnap.data() || {};
    const entitlement = entitlementSnap.data() || {};
    const currentCycleNumber = Math.max(
        1,
        Number(summary.currentCycleNumber || 1) || 1,
    );
    const currentCyclePaidCount = Math.max(
        0,
        Number(summary.currentCyclePaidCount || 0) || 0,
    );
    const nextPaidCount = currentCyclePaidCount + 1;
    const shouldGrant =
      nextPaidCount >= referralRewardConfig.requiredPaidReferrals;

    const summaryPatch = {
      currentCycleNumber,
      currentCyclePaidCount: nextPaidCount,
      requiredPaidReferrals: referralRewardConfig.requiredPaidReferrals,
      rewardDays: referralRewardConfig.rewardDays,
      totalPaidReferralCount: admin.firestore.FieldValue.increment(1),
      updatedAt: nowTimestamp,
    };

    tx.set(claimRef, {
      subscriberUid,
      referrerUid,
      referralCode,
      productId: productId || null,
      tokenHash: tokenHash || null,
      latestOrderId: latestOrderId || null,
      countedAt: nowTimestamp,
    });
    tx.set(sourceRef, {
      status: "paid_counted",
      countedAt: nowTimestamp,
      referrerUid,
      referralCode,
    }, {merge: true});

    if (shouldGrant) {
      const currentRewardExpiry = firestoreValueToDate(
          entitlement.referralRewardExpiresAt,
      );
      const paidExpiry = firestoreValueToDate(entitlement.expiryTime);
      const baseMillis = Math.max(
          nowDate.getTime(),
          currentRewardExpiry ? currentRewardExpiry.getTime() : 0,
          paidExpiry ? paidExpiry.getTime() : 0,
      );
      const rewardStartsAt = admin.firestore.Timestamp.fromMillis(baseMillis);
      const rewardExpiresAt =
        admin.firestore.Timestamp.fromMillis(baseMillis + rewardMillis);
      summaryPatch.currentCycleNumber = currentCycleNumber + 1;
      summaryPatch.currentCyclePaidCount = 0;
      summaryPatch.rewardGrantCount = admin.firestore.FieldValue.increment(1);
      summaryPatch.lastRewardStartsAt = rewardStartsAt;
      summaryPatch.lastRewardExpiresAt = rewardExpiresAt;

      tx.set(entitlementRef, {
        isPro: true,
        status: "active",
        source: "referral_reward",
        referralRewardActive: true,
        referralRewardStartsAt: rewardStartsAt,
        referralRewardExpiresAt: rewardExpiresAt,
        referralRewardCycleNumber: currentCycleNumber,
        referralRewardRequiredPaidReferrals:
          referralRewardConfig.requiredPaidReferrals,
        referralRewardDays: referralRewardConfig.rewardDays,
        updatedAt: nowTimestamp,
      }, {merge: true});
      tx.set(eventRef, {
        type: "referral_reward_granted",
        referrerUid,
        subscriberUid,
        referralCode,
        cycleNumber: currentCycleNumber,
        rewardStartsAt,
        rewardExpiresAt,
        createdAt: nowTimestamp,
      });
      result = {counted: true, rewardGranted: true};
    } else {
      tx.set(eventRef, {
        type: "paid_referral_counted",
        referrerUid,
        subscriberUid,
        referralCode,
        cycleNumber: currentCycleNumber,
        currentCyclePaidCount: nextPaidCount,
        requiredPaidReferrals: referralRewardConfig.requiredPaidReferrals,
        createdAt: nowTimestamp,
      });
      result = {
        counted: true,
        rewardGranted: false,
        currentCyclePaidCount: nextPaidCount,
      };
    }
    tx.set(summaryRef, summaryPatch, {merge: true});
  });

  return result;
}

function buildSubscriptionMetadataPatch(verification) {
  const patch = {
    autoRenewing: verification.autoRenewing === true,
    latestOrderId: verification.latestOrderId || null,
    basePlanId: verification.basePlanId || null,
    lastSyncedAt: admin.firestore.FieldValue.serverTimestamp(),
  };
  const startTime = toFirestoreTimestamp(verification.startTime);
  if (startTime) {
    patch.startTime = startTime;
  }
  const expiryTime = toFirestoreTimestamp(verification.expiryTime);
  if (expiryTime) {
    patch.expiryTime = expiryTime;
  }
  return patch;
}

function deriveEntitlementStatus({isPro, subscriptionState, expiryTime}) {
  if (isPro) {
    return "active";
  }
  if (isExpiredSubscriptionState(subscriptionState)) {
    return "expired";
  }
  const expiryDate = expiryTime instanceof admin.firestore.Timestamp ?
    expiryTime.toDate() :
    new Date(expiryTime || "");
  if (!Number.isNaN(expiryDate.getTime()) && expiryDate.getTime() <= Date.now()) {
    return "expired";
  }
  return "inactive";
}

function isFirst150TrialActive(entitlementData) {
  if (String(entitlementData.source || "").trim() !== first150TrialSource) {
    return false;
  }
  const expiryMillis = toMillis(entitlementData.expiryTime);
  return expiryMillis > Date.now();
}

function isEligibleFirst150NewUser(userRecord, nowMillis = Date.now()) {
  const creationMillis = Date.parse(
      String(userRecord && userRecord.metadata &&
        userRecord.metadata.creationTime || ""),
  );
  if (!Number.isFinite(creationMillis) || creationMillis <= 0) {
    return false;
  }
  const lastSignInMillis = Date.parse(
      String(userRecord && userRecord.metadata &&
        userRecord.metadata.lastSignInTime || ""),
  );
  if (!Number.isFinite(lastSignInMillis) || lastSignInMillis <= 0) {
    return false;
  }
  const accountAgeMillis = nowMillis - creationMillis;
  if (accountAgeMillis < 0 || accountAgeMillis > first150TrialNewUserWindowMillis) {
    return false;
  }
  return Math.abs(lastSignInMillis - creationMillis) <=
    first150TrialNewUserWindowMillis;
}

function isEligibleForFirst150StartWindow(userRecord, startsAtMillis) {
  if (!Number.isFinite(startsAtMillis) || startsAtMillis <= 0) {
    return false;
  }
  const creationMillis = Date.parse(
      String(userRecord && userRecord.metadata &&
        userRecord.metadata.creationTime || ""),
  );
  if (!Number.isFinite(creationMillis) || creationMillis <= 0) {
    return false;
  }
  return creationMillis >= startsAtMillis;
}

function serverSubscriptionTokenRef(tokenHash) {
  return db.collection(subscriptionCollections.serverTokens).doc(tokenHash);
}

async function upsertServerSubscriptionToken({
  uid,
  token,
  tokenHash,
  productId,
  basePlanId,
  platform,
  source,
  linkedPurchaseTokenHash,
  ackPending = false,
  ackAttempts = null,
}) {
  const payload = {
    uid,
    kind: "subscription",
    token,
    tokenHash,
    productId: productId || null,
    basePlanId: basePlanId || null,
    platform: platform || null,
    source: source || null,
    linkedPurchaseTokenHash: linkedPurchaseTokenHash || null,
    ackPending,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    lastVerifiedAt: admin.firestore.FieldValue.serverTimestamp(),
  };
  if (ackAttempts !== null) {
    payload.ackAttempts = ackAttempts;
  }
  await serverSubscriptionTokenRef(tokenHash).set(payload, {merge: true});
}

async function resolveStoredSubscriptionToken({
  uid,
  entitlementRef,
  entitlementData,
}) {
  const tokenHash = String(entitlementData.verificationTokenHash || "").trim();
  const legacyToken = String(entitlementData.verificationToken || "").trim();
  if (tokenHash) {
    const serverSnap = await serverSubscriptionTokenRef(tokenHash).get();
    const serverToken = String((serverSnap.data() || {}).token || "").trim();
    if (serverToken) {
      return {tokenHash, token: serverToken};
    }
  }
  if (legacyToken) {
    const legacyTokenHash = sha256(legacyToken);
    await upsertServerSubscriptionToken({
      uid,
      token: legacyToken,
      tokenHash: legacyTokenHash,
      productId: String(entitlementData.productId || "").trim(),
      platform: String(entitlementData.platform || "").trim(),
      source: String(entitlementData.source || "").trim(),
    });
    await entitlementRef.set({
      verificationTokenHash: legacyTokenHash,
      verificationToken: admin.firestore.FieldValue.delete(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, {merge: true});
    return {tokenHash: legacyTokenHash, token: legacyToken};
  }
  return {tokenHash, token: ""};
}

async function resolveStoredSubscriptionTokensForUser({
  uid,
  entitlementRef,
  entitlementData,
}) {
  const tokens = new Map();
  const primary = await resolveStoredSubscriptionToken({
    uid,
    entitlementRef,
    entitlementData,
  });
  if (primary.token) {
    tokens.set(primary.tokenHash || sha256(primary.token), primary);
  }
  const snap = await db.collection(subscriptionCollections.serverTokens)
      .where("uid", "==", uid)
      .where("kind", "==", "subscription")
      .limit(10)
      .get();
  snap.forEach((doc) => {
    const data = doc.data() || {};
    const token = String(data.token || "").trim();
    if (!token) {
      return;
    }
    tokens.set(doc.id, {
      tokenHash: doc.id,
      token,
      productId: String(data.productId || "").trim(),
    });
  });
  return Array.from(tokens.values());
}

function emptyAggregatedSubscriptionAccess() {
  return {
    isPro: false,
    appAccess: false,
    editorAccess: false,
    status: "inactive",
    productId: null,
    basePlanId: null,
    subscriptionState: null,
    startTime: null,
    expiryTime: null,
    autoRenewing: null,
    latestOrderId: null,
    verification: null,
  };
}

async function aggregateSubscriptionAccessForUser({
  uid,
  entitlementRef,
  entitlementData,
}) {
  const aggregate = emptyAggregatedSubscriptionAccess();
  const storedTokens = await resolveStoredSubscriptionTokensForUser({
    uid,
    entitlementRef,
    entitlementData,
  });
  for (const storedToken of storedTokens) {
    try {
      const verification = await verifySubscriptionPurchaseWithGoogle({
        purchaseToken: storedToken.token,
      });
      const access = subscriptionAccessScopesForPlan({
        productId: verification.primaryProductId || storedToken.productId,
        basePlanId: verification.basePlanId,
        valid: verification.valid,
      });
      if (!access.appAccess && !access.editorAccess) {
        continue;
      }
      aggregate.isPro = true;
      aggregate.appAccess = aggregate.appAccess || access.appAccess;
      aggregate.editorAccess = aggregate.editorAccess || access.editorAccess;
      aggregate.status = "active";
      const expiryMillis = Date.parse(String(verification.expiryTime || ""));
      const currentExpiryMillis = toMillis(aggregate.expiryTime);
      const shouldUseThisToken =
        currentExpiryMillis <= 0 ||
        (Number.isFinite(expiryMillis) && expiryMillis > currentExpiryMillis);
      if (shouldUseThisToken) {
        aggregate.productId = verification.primaryProductId || storedToken.productId || null;
        aggregate.basePlanId = verification.basePlanId || null;
        aggregate.subscriptionState = verification.subscriptionState || null;
        aggregate.startTime = toFirestoreTimestamp(verification.startTime) || aggregate.startTime;
        aggregate.expiryTime = toFirestoreTimestamp(verification.expiryTime) || aggregate.expiryTime;
        aggregate.autoRenewing = verification.autoRenewing === true;
        aggregate.latestOrderId = verification.latestOrderId || aggregate.latestOrderId;
        aggregate.verification = verification;
      }
    } catch (error) {
      logger.warn("subscriptionStatus token aggregate failed", {
        uid,
        tokenHash: storedToken.tokenHash || null,
        error: error instanceof Error ? error.message : String(error),
      });
    }
  }
  return aggregate;
}

async function acknowledgeSubscriptionPurchase({
  purchaseToken,
  subscriptionId,
}) {
  if (!subscriptionId) {
    return true;
  }
  try {
    const publisher = await getAndroidPublisherClient();
    await publisher.purchases.subscriptions.acknowledge({
      packageName: playPackageName,
      subscriptionId,
      token: purchaseToken,
      requestBody: {},
    });
    return true;
  } catch (error) {
    logger.warn("acknowledgeSubscriptionPurchase failed", error);
    return false;
  }
}

async function verifyOneTimeProductPurchaseWithGoogle({
  productId,
  purchaseToken,
}) {
  if (!isPlayBillingConfigured()) {
    throw new Error("Play Billing package name is not configured");
  }
  if (!productId) {
    throw new Error("productId is required");
  }
  const publisher = await getAndroidPublisherClient();
  const response = await publisher.purchases.products.get({
    packageName: playPackageName,
    productId,
    token: purchaseToken,
  });
  const payload = response.data || {};
  return {
    raw: payload,
    valid: activeTemplatePurchaseState(payload.purchaseState),
    consumptionState: Number(payload.consumptionState || 0),
    acknowledgementState: Number(payload.acknowledgementState || 0),
  };
}

async function acknowledgeOneTimeProductPurchase({
  productId,
  purchaseToken,
}) {
  if (!productId) {
    return;
  }
  try {
    const publisher = await getAndroidPublisherClient();
    await publisher.purchases.products.acknowledge({
      packageName: playPackageName,
      productId,
      token: purchaseToken,
      requestBody: {},
    });
  } catch (error) {
    logger.warn("acknowledgeOneTimeProductPurchase failed", error);
  }
}

async function assertPurchaseTokenOwnership({
  tokenHash,
  uid,
  kind,
  metadata = {},
}) {
  const ref = db.collection(subscriptionCollections.tokenOwnership).doc(tokenHash);
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (snap.exists) {
      const data = snap.data() || {};
      const existingUid = String(data.uid || "").trim();
      if (existingUid && existingUid !== uid) {
        logger.warn("subscription token ownership conflict", {
          tokenHash,
          existingUid,
          attemptedUid: uid,
          kind,
          ...metadata,
        });
        const error = new Error(
            "This Play Store subscription is already linked to another Mana Poster account. Sign in with that account or use a different Play Store account to subscribe.",
        );
        error.code = 409;
        error.reason = "SUBSCRIPTION_LINKED_TO_ANOTHER_ACCOUNT";
        throw error;
      }
    }
    tx.set(ref, {
      uid,
      kind,
      tokenHash,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      ...metadata,
    }, {merge: true});
  });
}

async function getPrimaryBannerImage() {
  try {
    const snap = await db
        .collection("appBanners")
        .where("active", "==", true)
        .orderBy("sortOrder", "asc")
        .limit(1)
        .get();
    if (snap.empty) {
      return null;
    }
    const data = snap.docs[0].data() || {};
    const imageUrl = String(data.imageUrl || "").trim();
    return imageUrl.length > 0 ? imageUrl : null;
  } catch (error) {
    logger.warn("getPrimaryBannerImage failed", error);
    return null;
  }
}

function buildStorageDownloadUrl(bucketName, objectPath, token) {
  return `https://firebasestorage.googleapis.com/v0/b/${bucketName}/o/${encodeURIComponent(objectPath)}?alt=media&token=${token}`;
}

async function sendTopicReminder({
  title,
  body,
  imageUrl = null,
}) {
  const message = {
    topic: "all_users",
    android: {
      priority: "high",
    },
    apns: {
      payload: {
        aps: {
          contentAvailable: true,
        },
      },
    },
    data: {
      click_action: "FLUTTER_NOTIFICATION_CLICK",
      route: "home",
      title: title || "",
      body: body || "",
      title_key: "",
      body_key: "",
      userName: "",
      userPhoto: "",
      posterImage: imageUrl || "",
    },
  };

  return admin.messaging().send(message);
}

function xmlEscape(value) {
  return String(value || "")
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
      .replace(/'/g, "&#39;");
}

function stableHashNumber(value) {
  const hex = crypto.createHash("md5").update(String(value || "")).digest("hex");
  return parseInt(hex.slice(0, 8), 16);
}

function getIstDayKey(now = new Date()) {
  const formatter = new Intl.DateTimeFormat("en-CA", {
    timeZone: "Asia/Kolkata",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  });
  return formatter.format(now);
}

function safeNotificationMetricKey(value) {
  const normalized = normalizeText(value)
      .replace(/[^a-z0-9_-]+/g, "-")
      .replace(/-+/g, "-")
      .replace(/^-|-$/g, "");
  return normalized || "default";
}

function notificationTokenId(token) {
  return sha256(token).slice(0, 40);
}

function notificationOpenRoute(categoryKey, openKind = "") {
  const category = reminderCategoryKey(categoryKey);
  const kind = safeNotificationMetricKey(openKind || category);
  if (kind === "dynamic-event" || kind === "event") {
    return `event/${safeNotificationMetricKey(categoryKey || "event")}`;
  }
  if (category && category !== "default" && category !== "welcome") {
    return `category/${safeNotificationMetricKey(category)}`;
  }
  return "home";
}

async function reserveNotificationDelivery({
  token,
  categoryKey,
  slotKey,
  dayKey = getIstDayKey(new Date()),
}) {
  const normalizedToken = String(token || "").trim();
  if (!normalizedToken) {
    return {allowed: false, reason: "missing_token"};
  }
  const category = safeNotificationMetricKey(reminderCategoryKey(categoryKey));
  if (category === "welcome") {
    return {allowed: true, reason: "welcome_exempt"};
  }
  const slot = safeNotificationMetricKey(slotKey || category);
  const tokenHash = notificationTokenId(normalizedToken);
  const ref = db
      .collection("notificationDeliveryDays")
      .doc(dayKey)
      .collection("tokens")
      .doc(tokenHash);
  try {
    return await db.runTransaction(async (tx) => {
      const snap = await tx.get(ref);
      const data = snap.exists ? (snap.data() || {}) : {};
      const count = Number(data.count || 0);
      const categories = data.categories || {};
      const slots = data.slots || {};
      if (slots[slot] === true) {
        return {allowed: false, reason: "same_slot_already_sent"};
      }
      if (category !== "dynamic_event" && categories[category] === true) {
        return {allowed: false, reason: "same_category_already_sent"};
      }
      tx.set(ref, {
        tokenHash,
        dayKey,
        count: count + 1,
        categories: {
          [category]: true,
        },
        slots: {
          [slot]: true,
        },
        lastCategory: category,
        lastSlot: slot,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        createdAt: data.createdAt || admin.firestore.FieldValue.serverTimestamp(),
      }, {merge: true});
      return {allowed: true, reason: "reserved", refPath: ref.path};
    });
  } catch (error) {
    logger.warn("notification delivery reservation failed", {
      categoryKey,
      slotKey,
      dayKey,
      error,
    });
    return {allowed: true, reason: "reservation_failed_open"};
  }
}

function reminderCategoryKey(input) {
  const normalized = normalizeText(input);
  if (normalized.includes("welcome")) {
    return "welcome";
  }
  if (normalized.includes("dynamic") || normalized.includes("event")) {
    return "dynamic_event";
  }
  if (normalized.includes("motivation") || normalized.includes("inspiration")) {
    return "motivation";
  }
  if (normalized.includes("joke") || normalized.includes("funny") || normalized.includes("humor")) {
    return "jokes";
  }
  if (normalized.includes("islam") || normalized.includes("muslim")) {
    return "islam";
  }
  if (normalized.includes("bible") || normalized.includes("christian")) {
    return "bible";
  }
  if (normalized.includes("weekday") || normalized.includes("monday") ||
      normalized.includes("tuesday") || normalized.includes("wednesday") ||
      normalized.includes("thursday") || normalized.includes("friday") ||
      normalized.includes("saturday") || normalized.includes("sunday")) {
    return normalized
        .replace(/\s+/g, "_")
        .replace(/[^a-z0-9_]+/g, "");
  }
  if (normalized.includes("morning")) {
    return "morning";
  }
  if (normalized.includes("afternoon")) {
    return "afternoon";
  }
  if (normalized.includes("night")) {
    return "night";
  }
  return "default";
}

function framePalette(categoryKey, seed) {
  const palettes = {
    welcome: [
      {shell: "#FFF5E8", frame: "#7A3E00", header: "#4A2500", footer: "#FF8A00", accent: "#FFE0B2", text: "#4A2500"},
      {shell: "#FFF0F5", frame: "#8F2D56", header: "#5B1636", footer: "#FF5C8A", accent: "#FFD0DF", text: "#5B1636"},
      {shell: "#F6F0FF", frame: "#5B3B8F", header: "#352154", footer: "#8F67FF", accent: "#E0D1FF", text: "#352154"},
      {shell: "#EEFDF7", frame: "#0F7B52", header: "#084A31", footer: "#19B97E", accent: "#CFF7E7", text: "#084A31"},
      {shell: "#F3FBFF", frame: "#0B5D8A", header: "#083B57", footer: "#21A6E8", accent: "#D2F0FF", text: "#083B57"},
    ],
    morning: [
      {shell: "#FFF8EC", frame: "#8A5A00", header: "#5B3B00", footer: "#FFB300", accent: "#FFE2A8", text: "#5B3B00"},
      {shell: "#FFF4E6", frame: "#A74C00", header: "#6E2C00", footer: "#FF8A00", accent: "#FFD0A8", text: "#6E2C00"},
      {shell: "#FFF8F0", frame: "#B35C1E", header: "#743B12", footer: "#F59E0B", accent: "#FFE7C2", text: "#743B12"},
      {shell: "#FFF7E1", frame: "#8A6A00", header: "#5C4700", footer: "#EAB308", accent: "#FCE59A", text: "#5C4700"},
      {shell: "#FFF5EA", frame: "#A6512F", header: "#6E311A", footer: "#FB923C", accent: "#FFD9C2", text: "#6E311A"},
      {shell: "#FFFCEE", frame: "#8C6B12", header: "#5E4707", footer: "#FACC15", accent: "#FEF3C7", text: "#5E4707"},
      {shell: "#FFF6E5", frame: "#9A5B16", header: "#6C3F0F", footer: "#FDBA74", accent: "#FFEDD5", text: "#6C3F0F"},
    ],
    afternoon: [
      {shell: "#F8F5FF", frame: "#5243AA", header: "#342A70", footer: "#6D5DF6", accent: "#D8D1FF", text: "#342A70"},
      {shell: "#F2FAFF", frame: "#0B6FA4", header: "#084B6E", footer: "#22A7F0", accent: "#CDEEFF", text: "#084B6E"},
      {shell: "#F5FCFF", frame: "#007F8C", header: "#00535C", footer: "#00B8C9", accent: "#C9F6FA", text: "#00535C"},
      {shell: "#F8FFF7", frame: "#2F7A32", header: "#1C4B1E", footer: "#58B85A", accent: "#D8F4D8", text: "#1C4B1E"},
      {shell: "#FFF7FB", frame: "#9C3D73", header: "#64244A", footer: "#E05FA9", accent: "#FFD6EB", text: "#64244A"},
      {shell: "#F4F8FF", frame: "#1D4ED8", header: "#1E3A8A", footer: "#60A5FA", accent: "#DBEAFE", text: "#1E3A8A"},
      {shell: "#F0FDFA", frame: "#0F766E", header: "#134E4A", footer: "#2DD4BF", accent: "#CCFBF1", text: "#134E4A"},
    ],
    night: [
      {shell: "#EEF2FF", frame: "#1E3A8A", header: "#0F1D4D", footer: "#3B82F6", accent: "#C9D6FF", text: "#0F1D4D"},
      {shell: "#F4F1FF", frame: "#4338CA", header: "#251E78", footer: "#7C6BFF", accent: "#D7D1FF", text: "#251E78"},
      {shell: "#EEF7FF", frame: "#0F4C81", header: "#082C4A", footer: "#38A3FF", accent: "#CCE9FF", text: "#082C4A"},
      {shell: "#F5F7FA", frame: "#334155", header: "#0F172A", footer: "#64748B", accent: "#D8DEE8", text: "#0F172A"},
      {shell: "#F8F5FF", frame: "#5B3B8F", header: "#352154", footer: "#8F67FF", accent: "#E0D1FF", text: "#352154"},
      {shell: "#F0F9FF", frame: "#075985", header: "#082F49", footer: "#0EA5E9", accent: "#E0F2FE", text: "#082F49"},
      {shell: "#F5F3FF", frame: "#6D28D9", header: "#4C1D95", footer: "#A78BFA", accent: "#EDE9FE", text: "#4C1D95"},
    ],
    default: [
      {shell: "#FFF9F2", frame: "#8A4B08", header: "#4D2804", footer: "#FF8E3C", accent: "#FFD9BA", text: "#4D2804"},
      {shell: "#F5FAFF", frame: "#0B6FA4", header: "#084B6E", footer: "#2BB3FF", accent: "#D4F0FF", text: "#084B6E"},
      {shell: "#F8FFF7", frame: "#2F7A32", header: "#1C4B1E", footer: "#5CC85F", accent: "#D8F4D8", text: "#1C4B1E"},
      {shell: "#FFF5FB", frame: "#A13D77", header: "#67244B", footer: "#F062B5", accent: "#FFD9ED", text: "#67244B"},
      {shell: "#F6F2FF", frame: "#6140A9", header: "#382564", footer: "#9370FF", accent: "#DDD2FF", text: "#382564"},
    ],
  };
  const variants = palettes[categoryKey] || palettes.default;
  return variants[stableHashNumber(seed) % variants.length];
}

async function downloadBufferFromUrl(url) {
  const normalized = String(url || "").trim();
  if (!normalized) {
    return null;
  }
  try {
    const response = await fetch(normalized);
    if (!response.ok) {
      return null;
    }
    const arrayBuffer = await response.arrayBuffer();
    return Buffer.from(arrayBuffer);
  } catch (error) {
    logger.warn("downloadBufferFromUrl failed", {url: normalized, error});
    return null;
  }
}

function notificationProfileFromData(data) {
  const identityMode = normalizeText(data.identityMode);
  if (identityMode === "business") {
    const businessName = String(data.businessName || "").trim();
    const businessLogoUrl = String(data.businessLogoUrl || "").trim();
    const displayName = String(data.displayName || "").trim();
    return {
      name: pickFirstUsablePosterName(businessName, displayName) || "",
      photoUrl: businessLogoUrl,
    };
  }

  const nameTelugu = String(data.nameTelugu || "").trim();
  const nameEnglish = String(data.nameEnglish || "").trim();
  const displayName = String(data.displayName || "").trim();
  const originalPhotoUrl = String(data.originalPhotoUrl || "").trim();
  const photoUrl = String(data.photoUrl || "").trim();

  return {
    name: pickFirstUsablePosterName(nameTelugu, nameEnglish, displayName),
    photoUrl: originalPhotoUrl || photoUrl,
  };
}

function sanitizeLanguage(value) {
  const normalized = normalizeText(value);
  return new Set([
    "telugu",
    "hindi",
    "english",
    "tamil",
    "kannada",
    "malayalam",
    "assamese",
    "konkani",
    "gujarati",
    "marathi",
    "meitei",
    "mizo",
    "odia",
    "punjabi",
    "nepali",
    "bengali",
    "kashmiri",
    "ladakhi",
  ]).has(normalized) ?
    normalized :
    "";
}

function looksLikeEmailAddress(value) {
  const t = String(value || "").trim();
  if (!t.includes("@")) {
    return false;
  }
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(t);
}

function isCorruptedPlaceholderName(value) {
  const t = String(value || "").trim();
  if (!t) {
    return true;
  }
  const condensed = t.replace(/\s+/g, "");
  if (/^[\?]+$/.test(condensed)) {
    return true;
  }
  if (/^\uFFFD+$/.test(condensed)) {
    return true;
  }
  return false;
}

function pickFirstUsablePosterName(...candidates) {
  for (const candidate of candidates) {
    const t = String(candidate || "").trim();
    if (!t || looksLikeEmailAddress(t)) {
      continue;
    }
    if (isCorruptedPlaceholderName(t)) {
      continue;
    }
    return t;
  }
  return "";
}

function reminderGreetingPrefix(displayName, bodySentence) {
  const body = String(bodySentence || "").trim();
  const n = pickFirstUsablePosterName(displayName);
  if (!n || !body) {
    return body;
  }
  return `${n}, ${body}`;
}

async function loadNotificationProfileForUid(uid) {
  if (!uid) {
    return {
      name: "",
      photoUrl: "",
      preferredLanguage: "english",
      selectedRegion: "",
      religionPreference: "",
    };
  }
  try {
    let authUser = null;
    try {
      authUser = await admin.auth().getUser(uid);
    } catch (_) {}
    const snap = await db.collection("users").doc(uid)
        .collection("posterProfile").doc("main").get();
    const userSnap = await db.collection("users").doc(uid).get();
    if (!snap.exists) {
      const preferredLanguage = sanitizeLanguage(
          userSnap.exists ? (userSnap.data() || {}).preferredLanguage : "",
      ) || defaultLanguageForName(
          pickFirstUsablePosterName(authUser?.displayName),
      );
      return {
        name: pickFirstUsablePosterName(authUser?.displayName),
        photoUrl: String(authUser?.photoURL || "").trim(),
        preferredLanguage,
        selectedRegion: notificationRegionFromData(
            userSnap.exists ? (userSnap.data() || {}) : {},
        ),
        religionPreference: normalizeReligionPreference(
            userSnap.exists ? (userSnap.data() || {}).religionPreference : "",
        ),
      };
    }
    const profileData = snap.data() || {};
    const baseProfile = notificationProfileFromData(profileData);
    const personalPhotoSyncPending = Boolean(profileData.personalPhotoSyncPending);
    const resolvedName = pickFirstUsablePosterName(
        baseProfile.name,
        authUser?.displayName,
    );
    const preferredLanguage = sanitizeLanguage(
        userSnap.exists ? (userSnap.data() || {}).preferredLanguage : "",
    ) || defaultLanguageForName(resolvedName);
    const profile = {
      ...baseProfile,
      preferredLanguage,
    };
    return {
      ...profile,
      name: resolvedName,
      photoUrl: String(profile.photoUrl || "").trim() ||
          (personalPhotoSyncPending ? "" : String(authUser?.photoURL || "").trim()),
      selectedRegion: notificationRegionFromData(
          userSnap.exists ? (userSnap.data() || {}) : {},
      ),
      religionPreference: normalizeReligionPreference(
          userSnap.exists ? (userSnap.data() || {}).religionPreference : "",
      ),
    };
  } catch (error) {
    logger.warn("loadNotificationProfileForUid failed", {uid, error});
    return {
      name: "",
      photoUrl: "",
      preferredLanguage: "english",
      selectedRegion: "",
      religionPreference: "",
    };
  }
}

function defaultLanguageForName(name) {
  return /[\u0C00-\u0C7F]/.test(String(name || "")) ? "telugu" : "english";
}

function notificationDisplayName(userName, language) {
  const fallbackByLanguage = {
    telugu: "మిత్రమా",
    hindi: "दोस्त",
    english: "Friend",
    tamil: "நண்பரே",
    kannada: "ಸ್ನೇಹಿತರೆ",
    malayalam: "സുഹൃത്തേ",
    assamese: "বন্ধু",
    konkani: "मोगाळा",
    gujarati: "મિત્ર",
    marathi: "मित्रा",
    meitei: "মরুপ",
    mizo: "Thian",
    odia: "ବନ୍ଧୁ",
    punjabi: "ਦੋਸਤ",
    nepali: "साथी",
    bengali: "বন্ধু",
    kashmiri: "دوست",
    ladakhi: "གྲོགས་པོ",
  };
  return pickFirstUsablePosterName(userName) ||
    fallbackByLanguage[sanitizeLanguage(language) || "english"] ||
    "Friend";
}

function buildNotificationCopy(kind, language, userName, extra = {}) {
  const lang = sanitizeLanguage(language) || "english";
  const name = notificationDisplayName(userName, lang);
  const timing = String(extra.timing || "").trim();
  const eventTitle = String(extra.eventTitle || "").trim();
  const timingText = timing === "tomorrow" ? "tomorrow" : "today";
  const map = {
    telugu: {
      welcome: ["Mana Poster కి స్వాగతం", `${name} గారు, మీ కోసం రోజువారీ పోస్టర్లు రెడీగా ఉన్నాయి.`],
      morning: ["శుభోదయం", `${name} గారు, మీ గుడ్ మార్నింగ్ పోస్టర్ షేర్ చేయడానికి రెడీగా ఉంది.`],
      afternoon: ["శుభ మధ్యాహ్నం", `${name} గారు, మీ మధ్యాహ్నం పోస్టర్ షేర్ చేయడానికి రెడీగా ఉంది.`],
      night: ["శుభ రాత్రి", `${name} గారు, మీ గుడ్ నైట్ పోస్టర్ షేర్ చేయడానికి రెడీగా ఉంది.`],
      motivation: ["మోటివేషన్ టైమ్", `${name} గారు, మీ మోటివేషన్ పోస్టర్ షేర్ చేయడానికి రెడీగా ఉంది.`],
      jokes: ["జోక్స్ టైమ్", `${name} గారు, మీ జోక్స్ పోస్టర్ షేర్ చేయడానికి రెడీగా ఉంది.`],
      dynamic_event: [eventTitle || "ఈవెంట్ రిమైండర్", `${name} గారు, ${eventTitle || "ఈవెంట్"} ${timing === "tomorrow" ? "రేపు" : "ఈ రోజు"} ఉంది. పోస్టర్ షేర్ చేయడానికి రెడీగా ఉంది.`],
    },
    hindi: {
      welcome: ["Mana Poster में आपका स्वागत है", `${name} जी, आपके लिए रोज़ाना पोस्टर तैयार हैं।`],
      morning: ["सुप्रभात", `${name} जी, आपका गुड मॉर्निंग पोस्टर शेयर करने के लिए तैयार है।`],
      afternoon: ["शुभ दोपहर", `${name} जी, आपका दोपहर पोस्टर शेयर करने के लिए तैयार है।`],
      night: ["शुभ रात्रि", `${name} जी, आपका गुड नाइट पोस्टर शेयर करने के लिए तैयार है।`],
      motivation: ["मोटिवेशन टाइम", `${name} जी, आपका मोटिवेशन पोस्टर शेयर करने के लिए तैयार है।`],
      jokes: ["जोक्स टाइम", `${name} जी, आपका जोक्स पोस्टर शेयर करने के लिए तैयार है।`],
      dynamic_event: [eventTitle || "इवेंट रिमाइंडर", `${name} जी, ${eventTitle || "इवेंट"} ${timing === "tomorrow" ? "कल" : "आज"} है। पोस्टर शेयर करने के लिए तैयार है।`],
    },
    english: {
      welcome: ["Welcome to Mana Poster", `${name}, your daily posters are ready to share.`],
      morning: ["Good Morning", `${name}, your good morning poster is ready to share.`],
      afternoon: ["Good Afternoon", `${name}, your afternoon poster is ready to share.`],
      night: ["Good Night", `${name}, your good night poster is ready to share.`],
      motivation: ["Motivation Time", `${name}, your motivational poster is ready to share.`],
      jokes: ["Jokes Time", `${name}, your jokes poster is ready to share.`],
      dynamic_event: [eventTitle || "Event Reminder", `${name}, ${eventTitle || "event"} is ${timingText}. Your poster is ready to share.`],
    },
    tamil: {
      welcome: ["Mana Posterக்கு வரவேற்கிறோம்", `${name} அவர்களே, தினசரி போஸ்டர்கள் பகிர தயாராக உள்ளன.`],
      morning: ["காலை வணக்கம்", `${name} அவர்களே, உங்கள் காலை வணக்கம் போஸ்டர் பகிர தயாராக உள்ளது.`],
      afternoon: ["மதிய வணக்கம்", `${name} அவர்களே, உங்கள் மதிய போஸ்டர் பகிர தயாராக உள்ளது.`],
      night: ["இரவு வணக்கம்", `${name} அவர்களே, உங்கள் குட் நைட் போஸ்டர் பகிர தயாராக உள்ளது.`],
      motivation: ["மோட்டிவேஷன் நேரம்", `${name} அவர்களே, உங்கள் மோட்டிவேஷன் போஸ்டர் பகிர தயாராக உள்ளது.`],
      jokes: ["ஜோக்ஸ் நேரம்", `${name} அவர்களே, உங்கள் ஜோக்ஸ் போஸ்டர் பகிர தயாராக உள்ளது.`],
      dynamic_event: [eventTitle || "நிகழ்வு நினைவூட்டல்", `${name} அவர்களே, ${eventTitle || "நிகழ்வு"} ${timing === "tomorrow" ? "நாளை" : "இன்று"} உள்ளது. போஸ்டர் பகிர தயாராக உள்ளது.`],
    },
    kannada: {
      welcome: ["Mana Poster ಗೆ ಸ್ವಾಗತ", `${name} ಅವರೇ, ದಿನನಿತ್ಯದ ಪೋಸ್ಟರ್‌ಗಳು ಹಂಚಿಕೊಳ್ಳಲು ಸಿದ್ಧವಾಗಿವೆ.`],
      morning: ["ಶುಭೋದಯ", `${name} ಅವರೇ, ನಿಮ್ಮ ಗುಡ್ ಮಾರ್ನಿಂಗ್ ಪೋಸ್ಟರ್ ಹಂಚಿಕೊಳ್ಳಲು ಸಿದ್ಧವಾಗಿದೆ.`],
      afternoon: ["ಶುಭ ಮಧ್ಯಾಹ್ನ", `${name} ಅವರೇ, ನಿಮ್ಮ ಮಧ್ಯಾಹ್ನದ ಪೋಸ್ಟರ್ ಹಂಚಿಕೊಳ್ಳಲು ಸಿದ್ಧವಾಗಿದೆ.`],
      night: ["ಶುಭ ರಾತ್ರಿ", `${name} ಅವರೇ, ನಿಮ್ಮ ಗುಡ್ ನೈಟ್ ಪೋಸ್ಟರ್ ಹಂಚಿಕೊಳ್ಳಲು ಸಿದ್ಧವಾಗಿದೆ.`],
      motivation: ["ಮೋಟಿವೇಶನ್ ಸಮಯ", `${name} ಅವರೇ, ನಿಮ್ಮ ಮೋಟಿವೇಶನ್ ಪೋಸ್ಟರ್ ಹಂಚಿಕೊಳ್ಳಲು ಸಿದ್ಧವಾಗಿದೆ.`],
      jokes: ["ಜೋಕ್ಸ್ ಸಮಯ", `${name} ಅವರೇ, ನಿಮ್ಮ ಜೋಕ್ಸ್ ಪೋಸ್ಟರ್ ಹಂಚಿಕೊಳ್ಳಲು ಸಿದ್ಧವಾಗಿದೆ.`],
      dynamic_event: [eventTitle || "ಈವೆಂಟ್ ರಿಮೈಂಡರ್", `${name} ಅವರೇ, ${eventTitle || "ಈವೆಂಟ್"} ${timing === "tomorrow" ? "ನಾಳೆ" : "ಇಂದು"} ಇದೆ. ಪೋಸ್ಟರ್ ಹಂಚಿಕೊಳ್ಳಲು ಸಿದ್ಧವಾಗಿದೆ.`],
    },
    malayalam: {
      welcome: ["Mana Poster ലേക്ക് സ്വാഗതം", `${name}, ദിവസേന പോസ്റ്ററുകൾ ഷെയർ ചെയ്യാൻ തയ്യാറാണ്.`],
      morning: ["സുപ്രഭാതം", `${name}, നിങ്ങളുടെ ഗുഡ് മോണിംഗ് പോസ്റ്റർ ഷെയർ ചെയ്യാൻ തയ്യാറാണ്.`],
      afternoon: ["ശുഭ മധ്യാഹ്നം", `${name}, നിങ്ങളുടെ ഉച്ചക്കാല പോസ്റ്റർ ഷെയർ ചെയ്യാൻ തയ്യാറാണ്.`],
      night: ["ശുഭ രാത്രി", `${name}, നിങ്ങളുടെ ഗുഡ് നൈറ്റ് പോസ്റ്റർ ഷെയർ ചെയ്യാൻ തയ്യാറാണ്.`],
      motivation: ["മോട്ടിവേഷൻ സമയം", `${name}, നിങ്ങളുടെ മോട്ടിവേഷൻ പോസ്റ്റർ ഷെയർ ചെയ്യാൻ തയ്യാറാണ്.`],
      jokes: ["ജോക്സ് സമയം", `${name}, നിങ്ങളുടെ ജോക്സ് പോസ്റ്റർ ഷെയർ ചെയ്യാൻ തയ്യാറാണ്.`],
      dynamic_event: [eventTitle || "ഇവന്റ് റിമൈൻഡർ", `${name}, ${eventTitle || "ഇവന്റ്"} ${timing === "tomorrow" ? "നാളെ" : "ഇന്ന്"} ആണ്. പോസ്റ്റർ ഷെയർ ചെയ്യാൻ തയ്യാറാണ്.`],
    },
    assamese: {
      welcome: ["Mana Poster লৈ স্বাগতম", `${name}, দৈনিক পোষ্টাৰ শ্বেয়াৰ কৰিবলৈ সাজু আছে।`],
      morning: ["শুভ ৰাতিপুৱা", `${name}, আপোনাৰ গুড মৰ্ণিং পোষ্টাৰ শ্বেয়াৰ কৰিবলৈ সাজু আছে।`],
      afternoon: ["শুভ দুপৰীয়া", `${name}, আপোনাৰ দুপৰীয়াৰ পোষ্টাৰ শ্বেয়াৰ কৰিবলৈ সাজু আছে।`],
      night: ["শুভ ৰাতি", `${name}, আপোনাৰ গুড নাইট পোষ্টাৰ শ্বেয়াৰ কৰিবলৈ সাজু আছে।`],
      motivation: ["মোটিভেশন টাইম", `${name}, আপোনাৰ মোটিভেশন পোষ্টাৰ শ্বেয়াৰ কৰিবলৈ সাজু আছে।`],
      jokes: ["জোকছ টাইম", `${name}, আপোনাৰ জোকছ পোষ্টাৰ শ্বেয়াৰ কৰিবলৈ সাজু আছে।`],
      dynamic_event: [eventTitle || "ইভেন্ট ৰিমাইন্ডাৰ", `${name}, ${eventTitle || "ইভেন্ট"} ${timing === "tomorrow" ? "কাইলৈ" : "আজি"} আছে। পোষ্টাৰ শ্বেয়াৰ কৰিবলৈ সাজু আছে।`],
    },
    konkani: {
      welcome: ["Mana Poster कडेन येवकार", `${name}, दिसपट्टी पोस्टर शेअर करपाक तयार आसात.`],
      morning: ["देव बरो सकाळ", `${name}, तुमचो गुड मॉर्निंग पोस्टर शेअर करपाक तयार आसा.`],
      afternoon: ["शुभ दनपार", `${name}, तुमचो दनपार पोस्टर शेअर करपाक तयार आसा.`],
      night: ["शुभ रात", `${name}, तुमचो गुड नाइट पोस्टर शेअर करपाक तयार आसा.`],
      motivation: ["मोटिवेशन टाइम", `${name}, तुमचो मोटिवेशन पोस्टर शेअर करपाक तयार आसा.`],
      jokes: ["जोक्स टाइम", `${name}, तुमचो जोक्स पोस्टर शेअर करपाक तयार आसा.`],
      dynamic_event: [eventTitle || "इव्हेंट रिमाइंडर", `${name}, ${eventTitle || "इव्हेंट"} ${timing === "tomorrow" ? "फाल्या" : "आयज"} आसा. पोस्टर शेअर करपाक तयार आसा.`],
    },
    gujarati: {
      welcome: ["Mana Poster માં આપનું સ્વાગત છે", `${name}, દૈનિક પોસ્ટર્સ શેર કરવા તૈયાર છે.`],
      morning: ["સુપ્રભાત", `${name}, તમારું ગુડ મોર્નિંગ પોસ્ટર શેર કરવા તૈયાર છે.`],
      afternoon: ["શુભ બપોર", `${name}, તમારું બપોરનું પોસ્ટર શેર કરવા તૈયાર છે.`],
      night: ["શુભ રાત્રી", `${name}, તમારું ગુડ નાઈટ પોસ્ટર શેર કરવા તૈયાર છે.`],
      motivation: ["મોટિવેશન ટાઈમ", `${name}, તમારું મોટિવેશન પોસ્ટર શેર કરવા તૈયાર છે.`],
      jokes: ["જોક્સ ટાઈમ", `${name}, તમારું જોક્સ પોસ્ટર શેર કરવા તૈયાર છે.`],
      dynamic_event: [eventTitle || "ઇવેન્ટ રિમાઇન્ડર", `${name}, ${eventTitle || "ઇવેન્ટ"} ${timing === "tomorrow" ? "કાલે" : "આજે"} છે. પોસ્ટર શેર કરવા તૈયાર છે.`],
    },
    marathi: {
      welcome: ["Mana Poster मध्ये स्वागत", `${name}, रोजचे पोस्टर्स शेअर करण्यासाठी तयार आहेत.`],
      morning: ["शुभ सकाळ", `${name}, तुमचा गुड मॉर्निंग पोस्टर शेअर करण्यासाठी तयार आहे.`],
      afternoon: ["शुभ दुपार", `${name}, तुमचा दुपारचा पोस्टर शेअर करण्यासाठी तयार आहे.`],
      night: ["शुभ रात्री", `${name}, तुमचा गुड नाईट पोस्टर शेअर करण्यासाठी तयार आहे.`],
      motivation: ["मोटिवेशन टाइम", `${name}, तुमचा मोटिवेशन पोस्टर शेअर करण्यासाठी तयार आहे.`],
      jokes: ["जोक्स टाइम", `${name}, तुमचा जोक्स पोस्टर शेअर करण्यासाठी तयार आहे.`],
      dynamic_event: [eventTitle || "इव्हेंट रिमाइंडर", `${name}, ${eventTitle || "इव्हेंट"} ${timing === "tomorrow" ? "उद्या" : "आज"} आहे. पोस्टर शेअर करण्यासाठी तयार आहे.`],
    },
    meitei: {
      welcome: ["Mana Poster দা তৌজরকপা", `${name}, নুমিৎ খুদিংগী poster share তৌনবা ready ওইরে.`],
      morning: ["গুড মর্নিং", `${name}, নহাক্কী good morning poster share তৌনবা ready ওইরে.`],
      afternoon: ["গুড আফটারনুন", `${name}, নহাক্কী afternoon poster share তৌনবা ready ওইরে.`],
      night: ["গুড নাইট", `${name}, নহাক্কী good night poster share তৌনবা ready ওইরে.`],
      motivation: ["Motivation Time", `${name}, নহাক্কী motivation poster share তৌনবা ready ওইরে.`],
      jokes: ["Jokes Time", `${name}, নহাক্কী jokes poster share তৌনবা ready ওইরে.`],
      dynamic_event: [eventTitle || "Event Reminder", `${name}, ${eventTitle || "event"} ${timing === "tomorrow" ? "হয়েং" : "ঙসি"} লৈ. Poster share তৌনবা ready ওইরে.`],
    },
    mizo: {
      welcome: ["Mana Poster-ah lo lawm a che", `${name}, ni tin poster share tur a inpeih tawh.`],
      morning: ["Good Morning", `${name}, i good morning poster share tur a inpeih tawh.`],
      afternoon: ["Good Afternoon", `${name}, i afternoon poster share tur a inpeih tawh.`],
      night: ["Good Night", `${name}, i good night poster share tur a inpeih tawh.`],
      motivation: ["Motivation Time", `${name}, i motivation poster share tur a inpeih tawh.`],
      jokes: ["Jokes Time", `${name}, i jokes poster share tur a inpeih tawh.`],
      dynamic_event: [eventTitle || "Event Reminder", `${name}, ${eventTitle || "event"} ${timing === "tomorrow" ? "naktukah" : "vawiin"} a awm. Poster share tur a inpeih tawh.`],
    },
    odia: {
      welcome: ["Mana Poster କୁ ସ୍ୱାଗତ", `${name}, ଦୈନିକ ପୋଷ୍ଟର ଶେୟାର ପାଇଁ ପ୍ରସ୍ତୁତ ଅଛି।`],
      morning: ["ସୁପ୍ରଭାତ", `${name}, ଆପଣଙ୍କ ଗୁଡ୍ ମର୍ଣ୍ଣିଙ୍ଗ ପୋଷ୍ଟର ଶେୟାର ପାଇଁ ପ୍ରସ୍ତୁତ ଅଛି।`],
      afternoon: ["ଶୁଭ ମଧ୍ୟାହ୍ନ", `${name}, ଆପଣଙ୍କ ମଧ୍ୟାହ୍ନ ପୋଷ୍ଟର ଶେୟାର ପାଇଁ ପ୍ରସ୍ତୁତ ଅଛି।`],
      night: ["ଶୁଭ ରାତ୍ରି", `${name}, ଆପଣଙ୍କ ଗୁଡ୍ ନାଇଟ୍ ପୋଷ୍ଟର ଶେୟାର ପାଇଁ ପ୍ରସ୍ତୁତ ଅଛି।`],
      motivation: ["ମୋଟିଭେସନ ଟାଇମ", `${name}, ଆପଣଙ୍କ ମୋଟିଭେସନ ପୋଷ୍ଟର ଶେୟାର ପାଇଁ ପ୍ରସ୍ତୁତ ଅଛି।`],
      jokes: ["ଜୋକ୍ସ ଟାଇମ", `${name}, ଆପଣଙ୍କ ଜୋକ୍ସ ପୋଷ୍ଟର ଶେୟାର ପାଇଁ ପ୍ରସ୍ତୁତ ଅଛି।`],
      dynamic_event: [eventTitle || "ଇଭେଣ୍ଟ ରିମାଇଣ୍ଡର", `${name}, ${eventTitle || "ଇଭେଣ୍ଟ"} ${timing === "tomorrow" ? "ଆସନ୍ତାକାଲି" : "ଆଜି"} ଅଛି। ପୋଷ୍ଟର ଶେୟାର ପାଇଁ ପ୍ରସ୍ତୁତ ଅଛି।`],
    },
    punjabi: {
      welcome: ["Mana Poster ਵਿੱਚ ਸੁਆਗਤ ਹੈ", `${name}, ਰੋਜ਼ਾਨਾ ਪੋਸਟਰ ਸ਼ੇਅਰ ਕਰਨ ਲਈ ਤਿਆਰ ਹਨ।`],
      morning: ["ਸਤਿ ਸ੍ਰੀ ਅਕਾਲ", `${name}, ਤੁਹਾਡਾ ਗੁੱਡ ਮਾਰਨਿੰਗ ਪੋਸਟਰ ਸ਼ੇਅਰ ਕਰਨ ਲਈ ਤਿਆਰ ਹੈ।`],
      afternoon: ["ਸ਼ੁਭ ਦੁਪਹਿਰ", `${name}, ਤੁਹਾਡਾ ਦੁਪਹਿਰ ਪੋਸਟਰ ਸ਼ੇਅਰ ਕਰਨ ਲਈ ਤਿਆਰ ਹੈ।`],
      night: ["ਸ਼ੁਭ ਰਾਤਰੀ", `${name}, ਤੁਹਾਡਾ ਗੁੱਡ ਨਾਈਟ ਪੋਸਟਰ ਸ਼ੇਅਰ ਕਰਨ ਲਈ ਤਿਆਰ ਹੈ।`],
      motivation: ["ਮੋਟੀਵੇਸ਼ਨ ਟਾਈਮ", `${name}, ਤੁਹਾਡਾ ਮੋਟੀਵੇਸ਼ਨ ਪੋਸਟਰ ਸ਼ੇਅਰ ਕਰਨ ਲਈ ਤਿਆਰ ਹੈ।`],
      jokes: ["ਜੋਕਸ ਟਾਈਮ", `${name}, ਤੁਹਾਡਾ ਜੋਕਸ ਪੋਸਟਰ ਸ਼ੇਅਰ ਕਰਨ ਲਈ ਤਿਆਰ ਹੈ।`],
      dynamic_event: [eventTitle || "ਇਵੈਂਟ ਰਿਮਾਈਂਡਰ", `${name}, ${eventTitle || "ਇਵੈਂਟ"} ${timing === "tomorrow" ? "ਕੱਲ੍ਹ" : "ਅੱਜ"} ਹੈ। ਪੋਸਟਰ ਸ਼ੇਅਰ ਕਰਨ ਲਈ ਤਿਆਰ ਹੈ।`],
    },
    nepali: {
      welcome: ["Mana Poster मा स्वागत छ", `${name}, दैनिक पोस्टर शेयर गर्न तयार छन्।`],
      morning: ["शुभ प्रभात", `${name}, तपाईंको गुड मर्निङ पोस्टर शेयर गर्न तयार छ।`],
      afternoon: ["शुभ दिउँसो", `${name}, तपाईंको दिउँसोको पोस्टर शेयर गर्न तयार छ।`],
      night: ["शुभ रात्री", `${name}, तपाईंको गुड नाइट पोस्टर शेयर गर्न तयार छ।`],
      motivation: ["मोटिभेसन टाइम", `${name}, तपाईंको मोटिभेसन पोस्टर शेयर गर्न तयार छ।`],
      jokes: ["जोक्स टाइम", `${name}, तपाईंको जोक्स पोस्टर शेयर गर्न तयार छ।`],
      dynamic_event: [eventTitle || "इभेन्ट रिमाइन्डर", `${name}, ${eventTitle || "इभेन्ट"} ${timing === "tomorrow" ? "भोलि" : "आज"} छ। पोस्टर शेयर गर्न तयार छ।`],
    },
    bengali: {
      welcome: ["Mana Poster-এ স্বাগতম", `${name}, দৈনিক পোস্টার শেয়ার করার জন্য প্রস্তুত আছে।`],
      morning: ["সুপ্রভাত", `${name}, আপনার গুড মর্নিং পোস্টার শেয়ার করার জন্য প্রস্তুত আছে।`],
      afternoon: ["শুভ দুপুর", `${name}, আপনার দুপুরের পোস্টার শেয়ার করার জন্য প্রস্তুত আছে।`],
      night: ["শুভ রাত্রি", `${name}, আপনার গুড নাইট পোস্টার শেয়ার করার জন্য প্রস্তুত আছে।`],
      motivation: ["মোটিভেশন টাইম", `${name}, আপনার মোটিভেশন পোস্টার শেয়ার করার জন্য প্রস্তুত আছে।`],
      jokes: ["জোকস টাইম", `${name}, আপনার জোকস পোস্টার শেয়ার করার জন্য প্রস্তুত আছে।`],
      dynamic_event: [eventTitle || "ইভেন্ট রিমাইন্ডার", `${name}, ${eventTitle || "ইভেন্ট"} ${timing === "tomorrow" ? "আগামীকাল" : "আজ"} আছে। পোস্টার শেয়ার করার জন্য প্রস্তুত আছে।`],
    },
    kashmiri: {
      welcome: ["Mana Poster منز خوش آمدید", `${name}, روزانہ پوسٹر شیئر کرنہٕ خٲطرٕ تیار چھ۔`],
      morning: ["گڈ مارننگ", `${name}, توہند گڈ مارننگ پوسٹر شیئر کرنہٕ خٲطرٕ تیار چھ۔`],
      afternoon: ["گڈ آفٹرنون", `${name}, توہند دوپہر پوسٹر شیئر کرنہٕ خٲطرٕ تیار چھ۔`],
      night: ["گڈ نائٹ", `${name}, توہند گڈ نائٹ پوسٹر شیئر کرنہٕ خٲطرٕ تیار چھ۔`],
      motivation: ["موٹیویشن ٹائم", `${name}, توہند موٹیویشن پوسٹر شیئر کرنہٕ خٲطرٕ تیار چھ۔`],
      jokes: ["جوکس ٹائم", `${name}, توہند جوکس پوسٹر شیئر کرنہٕ خٲطرٕ تیار چھ۔`],
      dynamic_event: [eventTitle || "ایونٹ ریمائنڈر", `${name}, ${eventTitle || "ایونٹ"} ${timing === "tomorrow" ? "پگاہ" : "از"} چھ۔ پوسٹر شیئر کرنہٕ خٲطرٕ تیار چھ۔`],
    },
    ladakhi: {
      welcome: ["Mana Poster ལ་ཕེབས་པར་དགའ་བསུ", `${name}, ཉིན་རེའི་པོསྚར་ཤེར་བྱེད་པར་གྲ་སྒྲིག་ཡོད།`],
      morning: ["ཞོགས་པ་བདེ་ལེགས", `${name}, ཁྱེད་ཀྱི་གུད་མོར་ནིང་པོསྚར་ཤེར་བྱེད་པར་གྲ་སྒྲིག་ཡོད།`],
      afternoon: ["ཉིན་གུང་བདེ་ལེགས", `${name}, ཁྱེད་ཀྱི་ཉིན་གུང་པོསྚར་ཤེར་བྱེད་པར་གྲ་སྒྲིག་ཡོད།`],
      night: ["མཚན་མོ་བདེ་ལེགས", `${name}, ཁྱེད་ཀྱི་གུད་ནཱའིཊ་པོསྚར་ཤེར་བྱེད་པར་གྲ་སྒྲིག་ཡོད།`],
      motivation: ["Motivation Time", `${name}, ཁྱེད་ཀྱི་མོ་ཊི་ཝེ་ཤན་པོསྚར་ཤེར་བྱེད་པར་གྲ་སྒྲིག་ཡོད།`],
      jokes: ["Jokes Time", `${name}, ཁྱེད་ཀྱི་ཇོཀས་པོསྚར་ཤེར་བྱེད་པར་གྲ་སྒྲིག་ཡོད།`],
      dynamic_event: [eventTitle || "Event Reminder", `${name}, ${eventTitle || "event"} ${timing === "tomorrow" ? "སང་ཉིན" : "དེ་རིང"} ཡོད། པོསྚར་ཤེར་བྱེད་པར་གྲ་སྒྲིག་ཡོད།`],
    },
  };
  const bucket = map[lang] || map.english;
  const pair = bucket[kind] || bucket.welcome;
  return {
    title: pair[0],
    body: pair[1],
    header: pair[1],
    footer: bucket === map.telugu ? "ఇప్పుడే షేర్ చేయండి" : "Share now",
  };
}

function reminderCopy(kind, language, userName) {
  const displayName = pickFirstUsablePosterName(userName);
  const lang =
      sanitizeLanguage(language) ||
      (displayName ? defaultLanguageForName(displayName) : "english");
  return buildNotificationCopy(kind, lang, displayName);
  const name = displayName;
  const map = {
    welcome: {
      telugu: {
        title: "Mana Poster కి స్వాగతం",
        body: "మీ కోసం రోజువారీ పోస్టర్లు సిద్ధంగా ఉన్నాయి. యాప్ ఓపెన్ చేసి షేర్ చేయండి.",
        header: reminderGreetingPrefix(
            name,
            "మీ పోస్టర్ షేర్ చేయడానికి సిద్ధంగా ఉంది",
        ),
        footer: "షేర్ చేయండి",
      },
      english: {
        title: "Welcome to Mana Poster",
        body: "Daily posters are ready for you. Open and share.",
        header: reminderGreetingPrefix(name, "your poster is ready to share"),
        footer: "Share",
      },
      hindi: {
        title: "Mana Poster में आपका स्वागत है",
        body: "आपके लिए रोज़ाना पोस्टर तैयार हैं। ऐप खोलें और शेयर करें।",
        header: reminderGreetingPrefix(name, "आपका पोस्टर शेयर करने के लिए तैयार है"),
        footer: "Share",
      },
      tamil: {
        title: "Mana Posterக்கு வரவேற்கிறோம்",
        body: "உங்களுக்கான தினசரி போஸ்டர்கள் தயாராக உள்ளன. ஆப்பை திறந்து பகிருங்கள்.",
        header: reminderGreetingPrefix(name, "உங்கள் போஸ்டர் பகிர தயாராக உள்ளது"),
        footer: "Share",
      },
      kannada: {
        title: "Mana Poster ಗೆ ಸ್ವಾಗತ",
        body: "ನಿಮಗಾಗಿ ದಿನನಿತ್ಯದ ಪೋಸ್ಟರ್‌ಗಳು ಸಿದ್ಧವಾಗಿವೆ. ಆಪ್ ತೆರೆಯಿರಿ ಮತ್ತು ಹಂಚಿಕೊಳ್ಳಿ.",
        header: reminderGreetingPrefix(name, "ನಿಮ್ಮ ಪೋಸ್ಟರ್ ಹಂಚಿಕೊಳ್ಳಲು ಸಿದ್ಧವಾಗಿದೆ"),
        footer: "Share",
      },
      malayalam: {
        title: "Mana Poster ലേക്ക് സ്വാഗതം",
        body: "നിങ്ങൾക്കായി ദിവസേന പോസ്റ്ററുകൾ തയ്യാറാണ്. ആപ്പ് തുറന്ന് ഷെയർ ചെയ്യൂ.",
        header: reminderGreetingPrefix(name, "നിങ്ങളുടെ പോസ്റ്റർ ഷെയർ ചെയ്യാൻ തയ്യാറാണ്"),
        footer: "Share",
      },
    },
    morning: {
      telugu: {
        title: "శుభోదయం",
        body: "మీ ఉదయపు పోస్టర్ సిద్ధంగా ఉంది. ఇప్పుడే షేర్ చేయండి.",
        header: reminderGreetingPrefix(
            name,
            "మీ ఉదయపు పోస్టర్ షేర్ చేయడానికి సిద్ధంగా ఉంది",
        ),
        footer: "షేర్ చేయండి",
      },
      english: {
        title: "Good Morning",
        body: "Your good morning poster is ready. Share it now.",
        header: reminderGreetingPrefix(name, "your morning poster is ready to share"),
        footer: "Share",
      },
      hindi: {
        title: "सुप्रभात",
        body: "आपका सुबह का पोस्टर तैयार है। अभी शेयर करें।",
        header: reminderGreetingPrefix(
            name,
            "आपका सुबह का पोस्टर शेयर करने के लिए तैयार है",
        ),
        footer: "Share",
      },
      tamil: {
        title: "காலை வணக்கம்",
        body: "உங்கள் காலை போஸ்டர் தயாராக உள்ளது. இப்போதே பகிருங்கள்.",
        header: reminderGreetingPrefix(
            name,
            "உங்கள் காலை போஸ்டர் பகிர தயாராக உள்ளது",
        ),
        footer: "Share",
      },
      kannada: {
        title: "ಶುಭೋದಯ",
        body: "ನಿಮ್ಮ ಬೆಳಗಿನ ಪೋಸ್ಟರ್ ಸಿದ್ಧವಾಗಿದೆ. ಈಗಲೇ ಹಂಚಿಕೊಳ್ಳಿ.",
        header: reminderGreetingPrefix(
            name,
            "ನಿಮ್ಮ ಬೆಳಗಿನ ಪೋಸ್ಟರ್ ಹಂಚಿಕೊಳ್ಳಲು ಸಿದ್ಧವಾಗಿದೆ",
        ),
        footer: "Share",
      },
      malayalam: {
        title: "സുപ്രഭാതം",
        body: "നിങ്ങളുടെ രാവിലെ പോസ്റ്റർ തയ്യാറാണ്. ഇപ്പോൾ ഷെയർ ചെയ്യൂ.",
        header: reminderGreetingPrefix(
            name,
            "നിങ്ങളുടെ രാവിലെ പോസ്റ്റർ ഷെയർ ചെയ്യാൻ തയ്യാറാണ്",
        ),
        footer: "Share",
      },
    },
    afternoon: {
      telugu: {
        title: "శుభ మధ్యాహ్నం",
        body: "మీ మధ్యాహ్న పోస్టర్ సిద్ధంగా ఉంది. ఇప్పుడే షేర్ చేయండి.",
        header: reminderGreetingPrefix(
            name,
            "మీ మధ్యాహ్న పోస్టర్ షేర్ చేయడానికి సిద్ధంగా ఉంది",
        ),
        footer: "షేర్ చేయండి",
      },
      english: {
        title: "Good Afternoon",
        body: "Your good afternoon poster is ready. Share it now.",
        header: reminderGreetingPrefix(
            name,
            "your afternoon poster is ready to share",
        ),
        footer: "Share",
      },
      hindi: {
        title: "शुभ दोपहर",
        body: "आपका दोपहर का पोस्टर तैयार है। अभी शेयर करें।",
        header: reminderGreetingPrefix(
            name,
            "आपका दोपहर का पोस्टर शेयर करने के लिए तैयार है",
        ),
        footer: "Share",
      },
      tamil: {
        title: "மதிய வணக்கம்",
        body: "உங்கள் மதிய போஸ்டர் தயாராக உள்ளது. இப்போதே பகிருங்கள்.",
        header: reminderGreetingPrefix(
            name,
            "உங்கள் மதிய போஸ்டர் பகிர தயாராக உள்ளது",
        ),
        footer: "Share",
      },
      kannada: {
        title: "ಶುಭ ಮಧ್ಯಾಹ್ನ",
        body: "ನಿಮ್ಮ ಮಧ್ಯಾಹ್ನದ ಪೋಸ್ಟರ್ ಸಿದ್ಧವಾಗಿದೆ. ಈಗಲೇ ಹಂಚಿಕೊಳ್ಳಿ.",
        header: reminderGreetingPrefix(
            name,
            "ನಿಮ್ಮ ಮಧ್ಯಾಹ್ನದ ಪೋಸ್ಟರ್ ಹಂಚಿಕೊಳ್ಳಲು ಸಿದ್ಧವಾಗಿದೆ",
        ),
        footer: "Share",
      },
      malayalam: {
        title: "ശുഭ മധ്യാഹ്നം",
        body: "നിങ്ങളുടെ ഉച്ചക്കാല പോസ്റ്റർ തയ്യാറാണ്. ഇപ്പോൾ ഷെയർ ചെയ്യൂ.",
        header: reminderGreetingPrefix(
            name,
            "നിങ്ങളുടെ ഉച്ചക്കാല പോസ്റ്റർ ഷെയർ ചെയ്യാൻ തയ്യാറാണ്",
        ),
        footer: "Share",
      },
    },
    night: {
      telugu: {
        title: "శుభ రాత్రి",
        body: "మీ రాత్రి పోస్టర్ సిద్ధంగా ఉంది. ఇప్పుడే షేర్ చేయండి.",
        header: reminderGreetingPrefix(
            name,
            "మీ రాత్రి పోస్టర్ షేర్ చేయడానికి సిద్ధంగా ఉంది",
        ),
        footer: "షేర్ చేయండి",
      },
      english: {
        title: "Good Night",
        body: "Your good night poster is ready. Share it now.",
        header: reminderGreetingPrefix(name, "your night poster is ready to share"),
        footer: "Share",
      },
      hindi: {
        title: "शुभ रात्रि",
        body: "आपका रात का पोस्टर तैयार है। अभी शेयर करें।",
        header: reminderGreetingPrefix(
            name,
            "आपका रात का पोस्टर शेयर करने के लिए तैयार है",
        ),
        footer: "Share",
      },
      tamil: {
        title: "இரவு வணக்கம்",
        body: "உங்கள் இரவு போஸ்டர் தயாராக உள்ளது. இப்போதே பகிருங்கள்.",
        header: reminderGreetingPrefix(
            name,
            "உங்கள் இரவு போஸ்டர் பகிர தயாராக உள்ளது",
        ),
        footer: "Share",
      },
      kannada: {
        title: "ಶುಭ ರಾತ್ರಿ",
        body: "ನಿಮ್ಮ ರಾತ್ರಿ ಪೋಸ್ಟರ್ ಸಿದ್ಧವಾಗಿದೆ. ಈಗಲೇ ಹಂಚಿಕೊಳ್ಳಿ.",
        header: reminderGreetingPrefix(
            name,
            "ನಿಮ್ಮ ರಾತ್ರಿ ಪೋಸ್ಟರ್ ಹಂಚಿಕೊಳ್ಳಲು ಸಿದ್ಧವಾಗಿದೆ",
        ),
        footer: "Share",
      },
      malayalam: {
        title: "ശുഭ രാത്രി",
        body: "നിങ്ങളുടെ രാത്രി പോസ്റ്റർ തയ്യാറാണ്. ഇപ്പോൾ ഷെയർ ചെയ്യൂ.",
        header: reminderGreetingPrefix(
            name,
            "നിങ്ങളുടെ രാത്രി പോസ്റ്റർ ഷെയർ ചെയ്യാൻ തയ്യാറാണ്",
        ),
        footer: "Share",
      },
    },
    motivation: {
      telugu: {
        title: "మోటివేషన్ టైమ్",
        body: "మీ కోసం motivational పోస్టర్ సిద్ధంగా ఉంది. ఇప్పుడే ఓపెన్ చేసి షేర్ చేయండి.",
        header: reminderGreetingPrefix(
            name,
            "మీ motivational పోస్టర్ షేర్ చేయడానికి సిద్ధంగా ఉంది",
        ),
        footer: "షేర్ చేయండి",
      },
      english: {
        title: "Motivation Time",
        body: "Your motivational poster is ready. Open the app and share it now.",
        header: reminderGreetingPrefix(
            name,
            "your motivational poster is ready to share",
        ),
        footer: "Share",
      },
      hindi: {
        title: "मोटिवेशन टाइम",
        body: "आपका motivational पोस्टर तैयार है। अभी ऐप खोलें और शेयर करें।",
        header: reminderGreetingPrefix(
            name,
            "आपका motivational पोस्टर शेयर करने के लिए तैयार है",
        ),
        footer: "Share",
      },
      tamil: {
        title: "மோட்டிவேஷன் நேரம்",
        body: "உங்கள் motivational போஸ்டர் தயாராக உள்ளது. இப்போதே திறந்து பகிருங்கள்.",
        header: reminderGreetingPrefix(
            name,
            "உங்கள் motivational போஸ்டர் பகிர தயாராக உள்ளது",
        ),
        footer: "Share",
      },
      kannada: {
        title: "ಮೋಟಿವೇಶನ್ ಸಮಯ",
        body: "ನಿಮ್ಮ motivational ಪೋಸ್ಟರ್ ಸಿದ್ಧವಾಗಿದೆ. ಈಗಲೇ ಆಪ್ ತೆರೆಯಿರಿ ಮತ್ತು ಹಂಚಿಕೊಳ್ಳಿ.",
        header: reminderGreetingPrefix(
            name,
            "ನಿಮ್ಮ motivational ಪೋಸ್ಟರ್ ಹಂಚಿಕೊಳ್ಳಲು ಸಿದ್ಧವಾಗಿದೆ",
        ),
        footer: "Share",
      },
      malayalam: {
        title: "മോട്ടിവേഷൻ സമയം",
        body: "നിങ്ങളുടെ motivational പോസ്റ്റർ തയ്യാറാണ്. ഇപ്പോൾ ആപ്പ് തുറന്ന് ഷെയർ ചെയ്യൂ.",
        header: reminderGreetingPrefix(
            name,
            "നിങ്ങളുടെ motivational പോസ്റ്റർ ഷെയർ ചെയ്യാൻ തയ്യാറാണ്",
        ),
        footer: "Share",
      },
    },
    jokes: {
      telugu: {
        title: "జోక్స్ టైమ్",
        body: "మీ కోసం funny jokes పోస్టర్ సిద్ధంగా ఉంది. ఇప్పుడే ఓపెన్ చేసి షేర్ చేయండి.",
        header: reminderGreetingPrefix(
            name,
            "మీ jokes పోస్టర్ షేర్ చేయడానికి సిద్ధంగా ఉంది",
        ),
        footer: "షేర్ చేయండి",
      },
      english: {
        title: "Jokes Time",
        body: "Your jokes poster is ready. Open the app and share a fun one now.",
        header: reminderGreetingPrefix(
            name,
            "your jokes poster is ready to share",
        ),
        footer: "Share",
      },
      hindi: {
        title: "जोक्स टाइम",
        body: "आपका funny jokes पोस्टर तैयार है। अभी ऐप खोलें और शेयर करें।",
        header: reminderGreetingPrefix(
            name,
            "आपका jokes पोस्टर शेयर करने के लिए तैयार है",
        ),
        footer: "Share",
      },
      tamil: {
        title: "ஜோக்ஸ் நேரம்",
        body: "உங்கள் funny jokes போஸ்டர் தயாராக உள்ளது. இப்போதே திறந்து பகிருங்கள்.",
        header: reminderGreetingPrefix(
            name,
            "உங்கள் jokes போஸ்டர் பகிர தயாராக உள்ளது",
        ),
        footer: "Share",
      },
      kannada: {
        title: "ಜೋಕ್ಸ್ ಸಮಯ",
        body: "ನಿಮ್ಮ funny jokes ಪೋಸ್ಟರ್ ಸಿದ್ಧವಾಗಿದೆ. ಈಗಲೇ ಆಪ್ ತೆರೆಯಿರಿ ಮತ್ತು ಹಂಚಿಕೊಳ್ಳಿ.",
        header: reminderGreetingPrefix(
            name,
            "ನಿಮ್ಮ jokes ಪೋಸ್ಟರ್ ಹಂಚಿಕೊಳ್ಳಲು ಸಿದ್ಧವಾಗಿದೆ",
        ),
        footer: "Share",
      },
      malayalam: {
        title: "ജോക്സ് സമയം",
        body: "നിങ്ങളുടെ funny jokes പോസ്റ്റർ തയ്യാറാണ്. ഇപ്പോൾ ആപ്പ് തുറന്ന് ഷെയർ ചെയ്യൂ.",
        header: reminderGreetingPrefix(
            name,
            "നിങ്ങളുടെ jokes പോസ്റ്റർ ഷെയർ ചെയ്യാൻ തയ്യാറാണ്",
        ),
        footer: "Share",
      },
    },
  };

  const bucket = map[kind] || map.welcome;
  return bucket[lang] || bucket.english;
}

function reminderCopyVariants(kind, language, userName) {
  const displayName = pickFirstUsablePosterName(userName);
  const lang =
      sanitizeLanguage(language) ||
      (displayName ? defaultLanguageForName(displayName) : "english");
  return [buildNotificationCopy(kind, lang, displayName)];
  const name = displayName;
  const map = {
    morning: {
      telugu: [
        {title: "శుభోదయం", body: "ఈరోజు ఉదయం share చేయడానికి అందమైన పోస్టర్లు రెడీగా ఉన్నాయి.", header: reminderGreetingPrefix(name, "మీ ఉదయపు పోస్టర్ రెడీగా ఉంది"), footer: "ఇప్పుడే షేర్ చేయండి"},
        {title: "శుభోదయం", body: "మీ status కి సరిపోయే fresh morning posters ఇప్పుడు Mana Poster లో ఉన్నాయి.", header: reminderGreetingPrefix(name, "ఈరోజు ఉదయపు greeting సిద్ధంగా ఉంది"), footer: "ఓపెన్ చేయండి"},
        {title: "శుభోదయం", body: "రోజు మొదలవ్వడానికి ఒక మంచి పోస్టర్ share చేయండి. కొత్త morning designs రెడీగా ఉన్నాయి.", header: reminderGreetingPrefix(name, "మీ morning share కోసం పోస్టర్ సిద్ధం"), footer: "షేర్ చేయండి"},
        {title: "శుభోదయం", body: "ఈరోజు ఉదయానికి ఆకట్టుకునే కొత్త పోస్టర్ collection సిద్ధంగా ఉంది.", header: reminderGreetingPrefix(name, "మీ కోసం morning పోస్టర్లు వచ్చాయి"), footer: "చూడండి"},
        {title: "శుభోదయం", body: "Good morning wishes ని special ga పంపడానికి కొత్త పోస్టర్ select చేయండి.", header: reminderGreetingPrefix(name, "ఈరోజు morning poster ready"), footer: "Select & Share"},
      ],
      english: [
        {title: "Good Morning", body: "Fresh morning posters are ready for today. Open Mana Poster and share one now.", header: reminderGreetingPrefix(name, "your morning poster is ready"), footer: "Share now"},
        {title: "Good Morning", body: "Start the day with a bright new greeting poster from Mana Poster.", header: reminderGreetingPrefix(name, "today's morning greeting is ready"), footer: "Open now"},
        {title: "Good Morning", body: "Your daily morning poster collection has a fresh pick waiting for you.", header: reminderGreetingPrefix(name, "a new morning poster is waiting"), footer: "See posters"},
        {title: "Good Morning", body: "Send a beautiful morning wish today with a fresh poster from the app.", header: reminderGreetingPrefix(name, "share your morning poster today"), footer: "Choose & share"},
        {title: "Good Morning", body: "A new morning design is ready to make your status stand out today.", header: reminderGreetingPrefix(name, "your morning status poster is ready"), footer: "Open app"},
      ],
    },
    afternoon: {
      telugu: [
        {title: "శుభ మధ్యాహ్నం", body: "ఈ మధ్యాహ్నం share చేయడానికి కొత్త attractive posters సిద్ధంగా ఉన్నాయి.", header: reminderGreetingPrefix(name, "మీ మధ్యాహ్న పోస్టర్ రెడీగా ఉంది"), footer: "ఇప్పుడే ఓపెన్ చేయండి"},
        {title: "శుభ మధ్యాహ్నం", body: "మధ్యాహ్నం greeting కి సరిపోయే fresh designs ఇప్పుడు app లో ఉన్నాయి.", header: reminderGreetingPrefix(name, "ఈరోజు మధ్యాహ్న greeting సిద్ధంగా ఉంది"), footer: "చూడండి"},
        {title: "శుభ మధ్యాహ్నం", body: "మీ status కి కొత్త afternoon poster ఎంపిక చేసుకునే సమయం వచ్చింది.", header: reminderGreetingPrefix(name, "మీ afternoon share కోసం పోస్టర్ సిద్ధం"), footer: "Select చేయండి"},
        {title: "శుభ మధ్యాహ్నం", body: "రోజు మధ్యలో కూడా highlight అయ్యే పోస్టర్ ready ga ఉంది.", header: reminderGreetingPrefix(name, "ఈ మధ్యాహ్నం పోస్టర్లు వచ్చాయి"), footer: "షేర్ చేయండి"},
        {title: "శుభ మధ్యాహ్నం", body: "ఇప్పుడే ఒక nice afternoon poster share చేసి reach పెంచండి.", header: reminderGreetingPrefix(name, "మీ afternoon poster ready"), footer: "Open & Share"},
      ],
      english: [
        {title: "Good Afternoon", body: "Fresh afternoon posters are ready for you. Open the app and share one today.", header: reminderGreetingPrefix(name, "your afternoon poster is ready"), footer: "Share now"},
        {title: "Good Afternoon", body: "A bright new afternoon greeting is waiting in Mana Poster.", header: reminderGreetingPrefix(name, "today's afternoon greeting is ready"), footer: "Open now"},
        {title: "Good Afternoon", body: "Make your afternoon status stand out with a new poster from the app.", header: reminderGreetingPrefix(name, "a new afternoon poster is ready"), footer: "See posters"},
        {title: "Good Afternoon", body: "Your daily poster feed has a fresh afternoon design ready to share.", header: reminderGreetingPrefix(name, "your afternoon share is ready"), footer: "Choose & share"},
        {title: "Good Afternoon", body: "A fresh afternoon poster is ready to keep your audience engaged today.", header: reminderGreetingPrefix(name, "your afternoon status poster is ready"), footer: "Open app"},
      ],
    },
    night: {
      telugu: [
        {title: "శుభ రాత్రి", body: "ఈ రాత్రి share చేయడానికి కొత్త good night posters రెడీగా ఉన్నాయి.", header: reminderGreetingPrefix(name, "మీ రాత్రి పోస్టర్ రెడీగా ఉంది"), footer: "ఇప్పుడే షేర్ చేయండి"},
        {title: "శుభ రాత్రి", body: "రోజు ముగిసేలోపు ఒక attractive night poster ని share చేయండి.", header: reminderGreetingPrefix(name, "ఈరోజు night greeting సిద్ధంగా ఉంది"), footer: "ఓపెన్ చేయండి"},
        {title: "శుభ రాత్రి", body: "మీ status కోసం fresh night designs ఇప్పుడు app లో ఉన్నాయి.", header: reminderGreetingPrefix(name, "మీ night పోస్టర్ సిద్ధంగా ఉంది"), footer: "చూడండి"},
        {title: "శుభ రాత్రి", body: "ఈ రాత్రికి calm and classy poster collection మీ కోసం సిద్ధంగా ఉంది.", header: reminderGreetingPrefix(name, "ఈరోజు రాత్రి share ready"), footer: "Select చేయండి"},
        {title: "శుభ రాత్రి", body: "Good night wishes ని special ga పంపడానికి కొత్త పోస్టర్ ఎంచుకోండి.", header: reminderGreetingPrefix(name, "మీ night poster వచ్చేసింది"), footer: "Open & Share"},
      ],
      english: [
        {title: "Good Night", body: "Fresh good night posters are ready. Open Mana Poster and share one tonight.", header: reminderGreetingPrefix(name, "your night poster is ready"), footer: "Share now"},
        {title: "Good Night", body: "End the day with a classy night greeting from Mana Poster.", header: reminderGreetingPrefix(name, "tonight's greeting is ready"), footer: "Open now"},
        {title: "Good Night", body: "A fresh night poster is waiting to light up your status tonight.", header: reminderGreetingPrefix(name, "your night share is ready"), footer: "See posters"},
        {title: "Good Night", body: "Your daily poster feed has a calm new night design ready to share.", header: reminderGreetingPrefix(name, "a new night poster is ready"), footer: "Choose & share"},
        {title: "Good Night", body: "Send a beautiful good night wish today with a fresh poster from the app.", header: reminderGreetingPrefix(name, "your night status poster is ready"), footer: "Open app"},
      ],
    },
    motivation: {
      telugu: [
        {title: "మోటివేషన్ టైమ్", body: "ఈరోజు మోటివేషన్ పోస్టర్ తో మీ audience కి spark ఇవ్వండి.", header: reminderGreetingPrefix(name, "మీ motivational పోస్టర్ సిద్ధంగా ఉంది"), footer: "ఇప్పుడే షేర్ చేయండి"},
        {title: "Daily Motivation", body: "ఒక strong quote poster ఈ రోజు reach ని పెంచగలదు. ఇప్పుడు చూడండి.", header: reminderGreetingPrefix(name, "ఈరోజు motivation పోస్టర్ రెడీ"), footer: "చూడండి"},
        {title: "Inspiration Ready", body: "Fresh motivational designs మీ status కి ready ga ఉన్నాయి.", header: reminderGreetingPrefix(name, "మీ కోసం inspiration పోస్టర్లు వచ్చాయి"), footer: "Open చేయండి"},
        {title: "Boost Your Day", body: "ఈ రోజు ఒక powerful motivation poster share చేసే time వచ్చింది.", header: reminderGreetingPrefix(name, "మీ motivational share ready"), footer: "Select చేయండి"},
        {title: "Motivation పోస్టర్", body: "Okka attractive quote poster తో ఈరోజు engagement పెంచండి.", header: reminderGreetingPrefix(name, "మీ motivation poster సిద్ధం"), footer: "Share now"},
      ],
      english: [
        {title: "Motivation Time", body: "Share a powerful motivational poster today and energize your audience.", header: reminderGreetingPrefix(name, "your motivational poster is ready"), footer: "Share now"},
        {title: "Daily Motivation", body: "A strong quote poster is ready to boost your reach today.", header: reminderGreetingPrefix(name, "today's motivation poster is ready"), footer: "Open now"},
        {title: "Inspiration Ready", body: "Fresh motivational designs are waiting for your next status update.", header: reminderGreetingPrefix(name, "your inspiration poster is ready"), footer: "See posters"},
        {title: "Boost Your Day", body: "A new motivation poster is ready to keep your content active today.", header: reminderGreetingPrefix(name, "your motivational share is ready"), footer: "Choose & share"},
        {title: "Keep Them Inspired", body: "Open Mana Poster and post a fresh motivational design today.", header: reminderGreetingPrefix(name, "your motivation update is ready"), footer: "Open app"},
      ],
      hindi: [
        {title: "मोटिवेशन टाइम", body: "आज एक powerful motivational पोस्टर शेयर करके अपने audience को inspire करें।", header: reminderGreetingPrefix(name, "आपका motivational पोस्टर तैयार है"), footer: "अभी शेयर करें"},
        {title: "Daily Motivation", body: "आज आपकी reach बढ़ाने के लिए एक strong quote poster तैयार है।", header: reminderGreetingPrefix(name, "आज का motivation poster तैयार है"), footer: "अभी खोलें"},
        {title: "Inspiration Ready", body: "आपके next status update के लिए fresh motivational designs तैयार हैं।", header: reminderGreetingPrefix(name, "आपका inspiration poster तैयार है"), footer: "पोस्टर देखें"},
      ],
      tamil: [
        {title: "மோட்டிவேஷன் நேரம்", body: "இன்று ஒரு powerful motivational போஸ்டரை பகிர்ந்து உங்கள் audience ஐ inspire செய்யுங்கள்.", header: reminderGreetingPrefix(name, "உங்கள் motivational போஸ்டர் தயாராக உள்ளது"), footer: "இப்போதே பகிருங்கள்"},
        {title: "Daily Motivation", body: "இன்றைய reach ஐ boost செய்ய ஒரு strong quote poster தயாராக உள்ளது.", header: reminderGreetingPrefix(name, "இன்றைய motivation poster தயாராக உள்ளது"), footer: "இப்போது திறக்கவும்"},
        {title: "Inspiration Ready", body: "உங்கள் next status update க்காக fresh motivational designs தயாராக உள்ளன.", header: reminderGreetingPrefix(name, "உங்கள் inspiration poster தயாராக உள்ளது"), footer: "போஸ்டர்கள் பார்க்கவும்"},
      ],
      kannada: [
        {title: "ಮೋಟಿವೇಶನ್ ಸಮಯ", body: "ಇಂದು ಒಂದು powerful motivational ಪೋಸ್ಟರ್ ಹಂಚಿಕೊಂಡು ನಿಮ್ಮ audience ಗೆ inspiration ನೀಡಿ.", header: reminderGreetingPrefix(name, "ನಿಮ್ಮ motivational ಪೋಸ್ಟರ್ ಸಿದ್ಧವಾಗಿದೆ"), footer: "ಈಗಲೇ ಹಂಚಿಕೊಳ್ಳಿ"},
        {title: "Daily Motivation", body: "ಇಂದಿನ reach ಹೆಚ್ಚಿಸಲು ಒಂದು strong quote poster ಸಿದ್ಧವಾಗಿದೆ.", header: reminderGreetingPrefix(name, "ಇಂದಿನ motivation poster ಸಿದ್ಧವಾಗಿದೆ"), footer: "ಈಗ ತೆರೆಯಿರಿ"},
        {title: "Inspiration Ready", body: "ನಿಮ್ಮ next status update ಗಾಗಿ fresh motivational designs ಸಿದ್ಧವಾಗಿವೆ.", header: reminderGreetingPrefix(name, "ನಿಮ್ಮ inspiration poster ಸಿದ್ಧವಾಗಿದೆ"), footer: "ಪೋಸ್ಟರ್‌ಗಳನ್ನು ನೋಡಿ"},
      ],
      malayalam: [
        {title: "മോട്ടിവേഷൻ സമയം", body: "ഇന്ന് ഒരു powerful motivational പോസ്റ്റർ ഷെയർ ചെയ്ത് നിങ്ങളുടെ audience നെ inspire ചെയ്യൂ.", header: reminderGreetingPrefix(name, "നിങ്ങളുടെ motivational പോസ്റ്റർ തയ്യാറാണ്"), footer: "ഇപ്പോൾ ഷെയർ ചെയ്യൂ"},
        {title: "Daily Motivation", body: "ഇന്നത്തെ reach boost ചെയ്യാൻ ഒരു strong quote poster തയ്യാറായി കാത്തിരിക്കുന്നു.", header: reminderGreetingPrefix(name, "ഇന്നത്തെ motivation poster തയ്യാറാണ്"), footer: "ഇപ്പോൾ തുറക്കൂ"},
        {title: "Inspiration Ready", body: "നിങ്ങളുടെ next status update നായി fresh motivational designs തയ്യാറാണ്.", header: reminderGreetingPrefix(name, "നിങ്ങളുടെ inspiration poster തയ്യാറാണ്"), footer: "പോസ്റ്ററുകൾ കാണൂ"},
      ],
    },
    jokes: {
      telugu: [
        {title: "Jokes Ready", body: "ఈరోజు నవ్వించే కొత్త jokes posters మీ కోసం సిద్ధంగా ఉన్నాయి.", header: reminderGreetingPrefix(name, "మీ jokes పోస్టర్ రెడీగా ఉంది"), footer: "ఇప్పుడే చూడండి"},
        {title: "Fun Time", body: "ఒక funny poster తో మీ status కి instant attention తెచ్చుకోండి.", header: reminderGreetingPrefix(name, "ఈరోజు jokes share సిద్ధంగా ఉంది"), footer: "షేర్ చేయండి"},
        {title: "Daily Jokes", body: "Fresh comedy posters ఇప్పుడు app లో ready ga ఉన్నాయి.", header: reminderGreetingPrefix(name, "మీ funny పోస్టర్ వచ్చింది"), footer: "Open చేయండి"},
        {title: "Laugh & Share", body: "ఈ రోజు audience ని smile చేయించే poster ఒకటి share చేయండి.", header: reminderGreetingPrefix(name, "మీ jokes పోస్టర్లు సిద్ధం"), footer: "Select చేయండి"},
        {title: "Comedy Poster", body: "Okka fun poster తో engagement పెంచడానికి right time ఇదే.", header: reminderGreetingPrefix(name, "మీ comedy poster ready"), footer: "Share now"},
      ],
      english: [
        {title: "Jokes Ready", body: "Fresh jokes posters are ready today. Open the app and share a fun one.", header: reminderGreetingPrefix(name, "your jokes poster is ready"), footer: "Open now"},
        {title: "Fun Time", body: "Bring a smile to your audience with a fresh funny poster today.", header: reminderGreetingPrefix(name, "today's fun poster is ready"), footer: "Share now"},
        {title: "Daily Jokes", body: "New comedy poster ideas are waiting in Mana Poster right now.", header: reminderGreetingPrefix(name, "your funny poster is ready"), footer: "See posters"},
        {title: "Laugh & Share", body: "A fresh jokes poster is ready to boost engagement on your status.", header: reminderGreetingPrefix(name, "your fun share is ready"), footer: "Choose & share"},
        {title: "Comedy Poster", body: "Open Mana Poster and post a fun, light-hearted design today.", header: reminderGreetingPrefix(name, "your comedy update is ready"), footer: "Open app"},
      ],
      hindi: [
        {title: "जोक्स रेडी", body: "आज के लिए fresh jokes posters तैयार हैं। ऐप खोलें और एक मजेदार पोस्टर शेयर करें।", header: reminderGreetingPrefix(name, "आपका jokes poster तैयार है"), footer: "अभी खोलें"},
        {title: "Fun Time", body: "आज एक fresh funny poster के साथ अपने audience के चेहरे पर मुस्कान लाइए।", header: reminderGreetingPrefix(name, "आज का fun poster तैयार है"), footer: "अभी शेयर करें"},
        {title: "Daily Jokes", body: "नए comedy poster ideas अभी Mana Poster में आपका इंतज़ार कर रहे हैं।", header: reminderGreetingPrefix(name, "आपका funny poster तैयार है"), footer: "पोस्टर देखें"},
      ],
      tamil: [
        {title: "ஜோக்ஸ் ரெடி", body: "இன்றைக்கு fresh jokes posters தயாராக உள்ளன. ஆப்பை திறந்து ஒரு fun poster பகிருங்கள்.", header: reminderGreetingPrefix(name, "உங்கள் jokes poster தயாராக உள்ளது"), footer: "இப்போது திறக்கவும்"},
        {title: "Fun Time", body: "இன்று ஒரு fresh funny poster மூலம் உங்கள் audience க்கு சிரிப்பு கொண்டு வாருங்கள்.", header: reminderGreetingPrefix(name, "இன்றைய fun poster தயாராக உள்ளது"), footer: "இப்போதே பகிருங்கள்"},
        {title: "Daily Jokes", body: "புதிய comedy poster ideas இப்போது Mana Poster இல் காத்திருக்கின்றன.", header: reminderGreetingPrefix(name, "உங்கள் funny poster தயாராக உள்ளது"), footer: "போஸ்டர்கள் பார்க்கவும்"},
      ],
      kannada: [
        {title: "ಜೋಕ್ಸ್ ರೆಡಿ", body: "ಇಂದಿಗಾಗಿ fresh jokes posters ಸಿದ್ಧವಾಗಿವೆ. ಆಪ್ ತೆರೆಯಿರಿ ಮತ್ತು ಒಂದು fun poster ಹಂಚಿಕೊಳ್ಳಿ.", header: reminderGreetingPrefix(name, "ನಿಮ್ಮ jokes poster ಸಿದ್ಧವಾಗಿದೆ"), footer: "ಈಗ ತೆರೆಯಿರಿ"},
        {title: "Fun Time", body: "ಇಂದು ಒಂದು fresh funny poster ಮೂಲಕ ನಿಮ್ಮ audience ಗೆ ನಗು ತರಿರಿ.", header: reminderGreetingPrefix(name, "ಇಂದಿನ fun poster ಸಿದ್ಧವಾಗಿದೆ"), footer: "ಈಗಲೇ ಹಂಚಿಕೊಳ್ಳಿ"},
        {title: "Daily Jokes", body: "ಹೊಸ comedy poster ideas ಈಗ Mana Poster ನಲ್ಲಿ ನಿಮಗಾಗಿ ಕಾಯುತ್ತಿವೆ.", header: reminderGreetingPrefix(name, "ನಿಮ್ಮ funny poster ಸಿದ್ಧವಾಗಿದೆ"), footer: "ಪೋಸ್ಟರ್‌ಗಳನ್ನು ನೋಡಿ"},
      ],
      malayalam: [
        {title: "ജോക്സ് റെഡി", body: "ഇന്നത്തേക്ക് fresh jokes posters തയ്യാറാണ്. ആപ്പ് തുറന്ന് ഒരു fun poster ഷെയർ ചെയ്യൂ.", header: reminderGreetingPrefix(name, "നിങ്ങളുടെ jokes poster തയ്യാറാണ്"), footer: "ഇപ്പോൾ തുറക്കൂ"},
        {title: "Fun Time", body: "ഇന്ന് ഒരു fresh funny poster വഴി നിങ്ങളുടെ audience നെ ചിരിപ്പിക്കൂ.", header: reminderGreetingPrefix(name, "ഇന്നത്തെ fun poster തയ്യാറാണ്"), footer: "ഇപ്പോൾ ഷെയർ ചെയ്യൂ"},
        {title: "Daily Jokes", body: "പുതിയ comedy poster ideas ഇപ്പോൾ Mana Poster ൽ കാത്തിരിക്കുന്നു.", header: reminderGreetingPrefix(name, "നിങ്ങളുടെ funny poster തയ്യാറാണ്"), footer: "പോസ്റ്ററുകൾ കാണൂ"},
      ],
    },
  };

  const fallback = reminderCopy(kind, lang, userName);
  const variantsByKind = map[kind];
  if (!variantsByKind) {
    return [fallback];
  }
  const variants = variantsByKind[lang] || [fallback];
  return Array.isArray(variants) && variants.length > 0 ? variants : [fallback];
}

function notificationLanguageFromTokenData(data, fallback = "english") {
  const regionLanguageCode = String(
      (data && data.selectedRegionLanguageCode) || "",
  ).trim().toLowerCase();
  const languageByRegionCode = {
    te: "telugu",
    hi: "hindi",
    en: "english",
    ta: "tamil",
    kn: "kannada",
    ml: "malayalam",
    as: "assamese",
    kok: "konkani",
    gu: "gujarati",
    mr: "marathi",
    mni: "meitei",
    lus: "mizo",
    or: "odia",
    pa: "punjabi",
    ne: "nepali",
    bn: "bengali",
    ks: "kashmiri",
    lbj: "ladakhi",
  };
  if (languageByRegionCode[regionLanguageCode]) {
    return languageByRegionCode[regionLanguageCode];
  }
  return sanitizeLanguage(
      (data && (data.preferredLanguage || data.language || data.locale)) || "",
  ) || fallback;
}

function normalizeRegionId(value) {
  return String(value || "")
      .trim()
      .toLowerCase()
      .replace(/&/g, "and")
      .replace(/[^a-z0-9]+/g, "_")
      .replace(/^_+|_+$/g, "");
}

const teluguSharedContentRegionIds = ["andhra_pradesh", "telangana"];
const hindiSharedContentRegionIds = [
  "bihar",
  "chhattisgarh",
  "haryana",
  "himachal_pradesh",
  "jharkhand",
  "madhya_pradesh",
  "rajasthan",
  "uttar_pradesh",
  "uttarakhand",
  "delhi",
  "andaman_nicobar",
];

function isPoliticalCategoryId(categoryId) {
  return normalizeRegionId(categoryId).startsWith("party_");
}

function isPoliticalDynamicEvent(event) {
  const parts = [
    event?.id,
    event?.title,
    event?.type,
    event?.scope,
    ...(Array.isArray(event?.keywords) ? event.keywords : []),
    ...(Array.isArray(event?.tags) ? event.tags : []),
  ].map((item) => normalizeText(item));
  return parts.some((item) =>
    item.includes("political") ||
    item.includes("politics") ||
    item.includes("party_") ||
    item.includes("party "),
  );
}

function eventRegionIds(event) {
  return Array.from(new Set((Array.isArray(event?.regionIds) ? event.regionIds : [])
      .map((item) => normalizeRegionId(item))
      .filter((item) => item.length > 0)));
}

function dynamicEventAppliesToRegion(event, regionId) {
  const resolvedRegionId = normalizeRegionId(regionId);
  const scopedRegionIds = eventRegionIds(event);
  if (scopedRegionIds.length === 0) {
    return true;
  }
  if (!resolvedRegionId) {
    return false;
  }
  if (scopedRegionIds.includes(resolvedRegionId)) {
    return true;
  }
  if (
    !isPoliticalDynamicEvent(event) &&
    teluguSharedContentRegionIds.includes(resolvedRegionId) &&
    scopedRegionIds.some((item) => teluguSharedContentRegionIds.includes(item))
  ) {
    return true;
  }
  return false;
}

function sharedContentRegionIdsFor(regionId, categoryId = "") {
  const resolvedRegionId = normalizeRegionId(regionId);
  if (!resolvedRegionId) {
    return [];
  }
  if (isPoliticalCategoryId(categoryId)) {
    return [resolvedRegionId];
  }
  if (teluguSharedContentRegionIds.includes(resolvedRegionId)) {
    return teluguSharedContentRegionIds;
  }
  if (hindiSharedContentRegionIds.includes(resolvedRegionId)) {
    return hindiSharedContentRegionIds;
  }
  return [resolvedRegionId];
}

function applyRegionScope(query, regionIds) {
  const uniqueRegionIds = Array.from(new Set((regionIds || [])
      .map((item) => normalizeRegionId(item))
      .filter((item) => item.length > 0)));
  if (uniqueRegionIds.length > 1) {
    return query.where("regionId", "in", uniqueRegionIds.slice(0, 10));
  }
  return query.where("regionId", "==", uniqueRegionIds[0] || "__none__");
}

function notificationRegionFromData(data) {
  return normalizeRegionId(
      data && (
        data.selectedRegion ||
        data.regionId ||
        data.stateId ||
        data.state ||
        data.selectedState
      ),
  );
}

function initialsSvgDataUri(name, palette) {
  const raw = String(name || "").trim();
  const initials = (raw.match(/\p{L}|\p{N}/gu) || []).slice(0, 2).join("").toUpperCase() || "U";
  const svg = `
    <svg xmlns="http://www.w3.org/2000/svg" width="220" height="220" viewBox="0 0 220 220">
      <defs>
        <linearGradient id="g" x1="0" x2="1" y1="0" y2="1">
          <stop offset="0%" stop-color="${palette.footer}" />
          <stop offset="100%" stop-color="${palette.frame}" />
        </linearGradient>
      </defs>
      <rect width="220" height="220" rx="110" fill="url(#g)" />
      <text x="110" y="128" text-anchor="middle" font-family="Arial, sans-serif" font-size="92" font-weight="700" fill="#ffffff">${xmlEscape(initials)}</text>
    </svg>`;
  return `data:image/svg+xml;base64,${Buffer.from(svg).toString("base64")}`;
}

function reminderCopyLocalized(kind, language, userName, now = new Date()) {
  const variants = reminderCopyVariants(kind, language, userName);
  const dayKey = getIstDayKey(now);
  const index = stableHashNumber(`${kind}-${sanitizeLanguage(language) || "english"}-${dayKey}`) % variants.length;
  return variants[index];
}

function greetingReminderVariants(kind, language) {
  const lang = sanitizeLanguage(language) || "english";
  const map = {
    evening: {
      telugu: [
        {title: "శుభ సాయంత్రం", body: "ఈ రోజు సాయంత్రం మీకు శుభాకాంక్షలు. Mana Poster ఓపెన్ చేసి కొత్త పోస్టర్లు చూడండి."},
        {title: "శుభ సాయంత్రం", body: "సాయంత్రం శుభాకాంక్షలు. మీకు నచ్చిన పోస్టర్ ఎంచుకుని షేర్ చేయండి."},
        {title: "శుభ సాయంత్రం", body: "ఈ సాయంత్రం greeting సిద్ధంగా ఉంది. యాప్ ఓపెన్ చేసి చూడండి."},
        {title: "శుభ సాయంత్రం", body: "మీ సాయంత్రం ఇంకా బాగుండాలి. Mana Poster లో కొత్త పోస్టర్లు రెడీగా ఉన్నాయి."},
        {title: "శుభ సాయంత్రం", body: "ఈరోజు సాయంత్రానికి మీ కోసం greeting రెడీగా ఉంది. ఇప్పుడే ఓపెన్ చేయండి."},
        {title: "శుభ సాయంత్రం", body: "సాయంత్రం శుభాకాంక్షలు. మీ పోస్టర్ collection చూడడానికి యాప్ ఓపెన్ చేయండి."},
        {title: "శుభ సాయంత్రం", body: "ఈ సాయంత్రం share చేయడానికి మంచి పోస్టర్లు సిద్ధంగా ఉన్నాయి. ఒక్కసారి చూడండి."},
      ],
      english: [
        {title: "Good Evening", body: "Wishing you a pleasant evening. Open Mana Poster and explore fresh posters."},
        {title: "Good Evening", body: "Your evening greeting is here. Open the app and share a poster you like."},
        {title: "Good Evening", body: "Fresh evening posters are ready for you. Take a quick look in Mana Poster."},
        {title: "Good Evening", body: "Hope your evening is going well. Open Mana Poster for new greeting posters."},
        {title: "Good Evening", body: "A new evening greeting is ready. Open the app and check it now."},
        {title: "Good Evening", body: "Take a moment to see today’s evening posters in Mana Poster."},
        {title: "Good Evening", body: "Evening greetings are ready to explore. Open Mana Poster now."},
      ],
      hindi: [
        {title: "शुभ संध्या", body: "आपको सुखद संध्या की शुभकामनाएँ। Mana Poster खोलें और नए पोस्टर देखें।"},
        {title: "शुभ संध्या", body: "आपकी शाम की शुभकामना तैयार है। ऐप खोलें और पसंदीदा पोस्टर शेयर करें।"},
        {title: "शुभ संध्या", body: "ताज़ा शाम के पोस्टर आपके लिए तैयार हैं। Mana Poster में अभी देखें।"},
        {title: "शुभ संध्या", body: "उम्मीद है आपकी शाम अच्छी जा रही है। नए पोस्टर देखने के लिए ऐप खोलें।"},
        {title: "शुभ संध्या", body: "आज की शाम के लिए नया greeting तैयार है। अभी ऐप खोलें।"},
        {title: "शुभ संध्या", body: "आज के शाम वाले पोस्टर देखने के लिए Mana Poster खोलें।"},
        {title: "शुभ संध्या", body: "शाम की शुभकामनाएँ तैयार हैं। अभी Mana Poster देखें।"},
      ],
      tamil: [
        {title: "மாலை வணக்கம்", body: "இனிய மாலை வணக்கம். Mana Poster திறந்து புதிய போஸ்டர்களைப் பாருங்கள்."},
        {title: "மாலை வணக்கம்", body: "உங்கள் மாலை வாழ்த்து தயாராக உள்ளது. ஆப்பை திறந்து பிடித்த போஸ்டரை பகிருங்கள்."},
        {title: "மாலை வணக்கம்", body: "புதிய மாலை போஸ்டர்கள் தயாராக உள்ளன. Mana Poster இல் பாருங்கள்."},
        {title: "மாலை வணக்கம்", body: "உங்கள் மாலை நன்றாக அமையட்டும். புதிய greeting போஸ்டர்களுக்கு ஆப்பை திறக்கவும்."},
        {title: "மாலை வணக்கம்", body: "இன்றைய மாலைக்கான புதிய greeting தயார். இப்போதே திறந்து பாருங்கள்."},
        {title: "மாலை வணக்கம்", body: "இன்றைய மாலை போஸ்டர்களைப் பார்க்க Mana Poster திறக்கவும்."},
        {title: "மாலை வணக்கம்", body: "மாலை வாழ்த்துகள் தயாராக உள்ளன. இப்போது Mana Poster பாருங்கள்."},
      ],
      kannada: [
        {title: "ಶುಭ ಸಂಜೆ", body: "ನಿಮಗೆ ಸುಂದರವಾದ ಸಂಜೆ ಶುಭಾಶಯಗಳು. Mana Poster ತೆರೆಯಿರಿ ಮತ್ತು ಹೊಸ ಪೋಸ್ಟರ್‌ಗಳನ್ನು ನೋಡಿ."},
        {title: "ಶುಭ ಸಂಜೆ", body: "ನಿಮ್ಮ ಸಂಜೆ ಶುಭಾಶಯ ಸಿದ್ಧವಾಗಿದೆ. ಆಪ್ ತೆರೆಯಿರಿ ಮತ್ತು ಇಷ್ಟವಾದ ಪೋಸ್ಟರ್ ಹಂಚಿಕೊಳ್ಳಿ."},
        {title: "ಶುಭ ಸಂಜೆ", body: "ಹೊಸ ಸಂಜೆ ಪೋಸ್ಟರ್‌ಗಳು ಸಿದ್ಧವಾಗಿವೆ. Mana Poster ನಲ್ಲಿ ನೋಡಿ."},
        {title: "ಶುಭ ಸಂಜೆ", body: "ನಿಮ್ಮ ಸಂಜೆ ಚೆನ್ನಾಗಿರಲಿ. ಹೊಸ greeting ಪೋಸ್ಟರ್‌ಗಳಿಗಾಗಿ ಆಪ್ ತೆರೆಯಿರಿ."},
        {title: "ಶುಭ ಸಂಜೆ", body: "ಇಂದಿನ ಸಂಜೆಗಾಗಿ ಹೊಸ greeting ಸಿದ್ಧವಾಗಿದೆ. ಈಗಲೇ ತೆರೆಯಿರಿ."},
        {title: "ಶುಭ ಸಂಜೆ", body: "ಇಂದಿನ ಸಂಜೆ ಪೋಸ್ಟರ್‌ಗಳನ್ನು ನೋಡಲು Mana Poster ತೆರೆಯಿರಿ."},
        {title: "ಶುಭ ಸಂಜೆ", body: "ಸಂಜೆಯ ಶುಭಾಶಯಗಳು ಸಿದ್ಧವಾಗಿವೆ. ಈಗ Mana Poster ನೋಡಿ."},
      ],
      malayalam: [
        {title: "സായാഹ്ന വന്ദനം", body: "സുഖകരമായ ഒരു സായാഹ്നാശംസകൾ. Mana Poster തുറന്ന് പുതിയ പോസ്റ്ററുകൾ കാണൂ."},
        {title: "സായാഹ്ന വന്ദനം", body: "നിങ്ങളുടെ സായാഹ്ന greeting തയ്യാറാണ്. ആപ്പ് തുറന്ന് ഇഷ്ടപ്പെട്ട പോസ്റ്റർ ഷെയർ ചെയ്യൂ."},
        {title: "സായാഹ്ന വന്ദനം", body: "പുതിയ സായാഹ്ന പോസ്റ്ററുകൾ തയ്യാറാണ്. Mana Posterയിൽ നോക്കൂ."},
        {title: "സായാഹ്ന വന്ദനം", body: "നിങ്ങളുടെ സായാഹ്നം മനോഹരമാകട്ടെ. പുതിയ greeting പോസ്റ്ററുകൾക്കായി ആപ്പ് തുറക്കൂ."},
        {title: "സായാഹ്ന വന്ദനം", body: "ഇന്നത്തെ സായാഹ്നത്തിനായുള്ള പുതിയ greeting തയ്യാറായി. ഇപ്പോൾ തന്നെ തുറക്കൂ."},
        {title: "സായാഹ്ന വന്ദനം", body: "ഇന്നത്തെ സായാഹ്ന പോസ്റ്ററുകൾ കാണാൻ Mana Poster തുറക്കൂ."},
        {title: "സായാഹ്ന വന്ദനം", body: "സായാഹ്നാശംസകൾ തയ്യാറാണ്. ഇപ്പോൾ Mana Poster നോക്കൂ."},
      ],
    },
  };

  const variants = (map[kind] || {}).hasOwnProperty(lang) ?
    map[kind][lang] :
    (map[kind] || {}).english;
  return Array.isArray(variants) && variants.length > 0 ? variants : [
    {title: "Mana Poster", body: "Open the app to see the latest posters."},
  ];
}

function greetingReminderVariant(kind, language, now = new Date()) {
  const variants = greetingReminderVariants(kind, language);
  const dayKey = getIstDayKey(now);
  const index = stableHashNumber(`${kind}-${dayKey}`) % variants.length;
  return variants[index];
}

function truncateSingleLineText(value, maxLength) {
  const text = String(value || "").replace(/\s+/g, " ").trim();
  if (!text) {
    return "";
  }
  const limit = Math.max(1, Number(maxLength) || text.length);
  const chars = Array.from(text);
  if (chars.length <= limit) {
    return text;
  }
  return `${chars.slice(0, Math.max(0, limit - 1)).join("")}\u2026`;
}

function wrapTextLines(value, maxCharsPerLine, maxLines) {
  const source = String(value || "").replace(/\s+/g, " ").trim();
  if (!source) {
    return [];
  }
  const limit = Math.max(6, Number(maxCharsPerLine) || 24);
  const lines = [];
  let current = "";
  const words = source.split(" ");
  for (const word of words) {
    const candidate = current ? `${current} ${word}` : word;
    if (Array.from(candidate).length <= limit) {
      current = candidate;
      continue;
    }
    if (current) {
      lines.push(current);
      current = word;
    } else {
      lines.push(truncateSingleLineText(word, limit));
      current = "";
    }
    if (lines.length >= maxLines) {
      break;
    }
  }
  if (lines.length < maxLines && current) {
    lines.push(current);
  }
  if (lines.length > maxLines) {
    return lines.slice(0, maxLines);
  }
  if (lines.length === maxLines && words.length > 0) {
    const joined = lines.join(" ");
    if (Array.from(joined).length < Array.from(source).length) {
      lines[maxLines - 1] = truncateSingleLineText(lines[maxLines - 1], limit - 1);
    }
  }
  return lines;
}

function renderSvgTextLines(lines, {
  x,
  y,
  lineHeight,
  fontFamily,
  fontSize,
  fontWeight,
  fill,
  textAnchor = "start",
}) {
  return lines.map((line, index) => {
    const lineY = y + (index * lineHeight);
    return `<text x="${x}" y="${lineY}" text-anchor="${textAnchor}" font-family="${fontFamily}" font-size="${fontSize}" font-weight="${fontWeight}" fill="${fill}">${xmlEscape(line.normalize("NFC"))}</text>`;
  }).join("");
}

function reminderBadgeLabel(categoryKey, title) {
  const normalized = reminderCategoryKey(categoryKey);
  if (normalized === "morning") {
    return "Good Morning";
  }
  if (normalized === "afternoon") {
    return "Good Afternoon";
  }
  if (normalized === "night") {
    return "Good Night";
  }
  if (normalized === "motivation") {
    return "Motivation";
  }
  if (normalized === "jokes") {
    return "Jokes";
  }
  return truncateSingleLineText(String(title || "Mana Poster").trim(), 16);
}

function htmlEscape(value) {
  return String(value || "")
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
      .replace(/'/g, "&#39;");
}

function whatsappGlyphDataUri() {
  const svg = `
    <svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64">
      <circle cx="32" cy="32" r="32" fill="#25D366"/>
      <path d="M20 18c2.7-2.7 6.4-4.2 10.3-4.2 8 0 14.7 6.5 14.7 14.6 0 3.9-1.5 7.6-4.3 10.4L43 46l-7.4-2.2c-1.7.7-3.5 1-5.3 1-8.1 0-14.6-6.5-14.6-14.6 0-3.9 1.5-7.6 4.3-10.4Zm10.3-1.7c-3.4 0-6.6 1.3-9 3.7a12.67 12.67 0 0 0-3.7 9c0 7 5.7 12.7 12.7 12.7 1.7 0 3.4-.3 5-.9l.7-.3 4.4 1.3-1.4-4.2.4-.7c2.1-2.8 3.2-6.4 2.4-10-1.1-5.3-5.8-9.2-11.5-9.6Z" fill="#ffffff"/>
      <path d="M26.9 23.6c-.4-.8-.8-.8-1.1-.8h-.9c-.3 0-.8.1-1.2.5-.4.4-1.6 1.6-1.6 4 0 2.3 1.6 4.5 1.9 4.8.3.3 3.2 5.1 8 6.9 4 1.5 4.8 1.2 5.7 1.1.8-.1 2.7-1.1 3.1-2.2.4-1 .4-1.9.3-2.1-.1-.2-.4-.3-.9-.6-.5-.2-2.7-1.3-3.1-1.4-.4-.2-.8-.2-1 .2-.3.4-1.1 1.4-1.3 1.7-.2.3-.5.3-.9.1-.5-.2-2-.7-3.9-2.4-1.4-1.2-2.4-2.8-2.7-3.2-.3-.5 0-.7.2-1 .2-.2.4-.5.6-.8.2-.3.3-.5.5-.8.2-.3.1-.6 0-.8-.2-.2-1.4-3.2-1.6-3.6Z" fill="#ffffff"/>
    </svg>`;
  return `data:image/svg+xml;base64,${Buffer.from(svg).toString("base64")}`;
}

function chevronUpGlyphDataUri() {
  const svg = `
    <svg xmlns="http://www.w3.org/2000/svg" width="40" height="40" viewBox="0 0 40 40">
      <path d="M11 25l9-9 9 9" fill="none" stroke="#151515" stroke-width="3.4" stroke-linecap="round" stroke-linejoin="round"/>
    </svg>`;
  return `data:image/svg+xml;base64,${Buffer.from(svg).toString("base64")}`;
}

function headerPrefixLabel(kind, language) {
  const category = reminderCategoryKey(kind);
  const lang = sanitizeLanguage(language) || "english";
  const labels = {
    morning: {
      telugu: "మీ ఉదయపు పోస్టర్",
      english: "your morning poster",
      hindi: "आपका सुबह का पोस्टर",
      tamil: "உங்கள் காலை போஸ்டர்",
      kannada: "ನಿಮ್ಮ ಬೆಳಗಿನ ಪೋಸ್ಟರ್",
      malayalam: "നിങ്ങളുടെ രാവിലെ പോസ്റ്റർ",
    },
    afternoon: {
      telugu: "మీ మధ్యాహ్న పోస్టర్",
      english: "your afternoon poster",
      hindi: "आपका दोपहर का पोस्टर",
      tamil: "உங்கள் மதிய போஸ்டர்",
      kannada: "ನಿಮ್ಮ ಮಧ್ಯಾಹ್ನದ ಪೋಸ್ಟರ್",
      malayalam: "നിങ്ങളുടെ ഉച്ചക്കാല പോസ്റ്റർ",
    },
    night: {
      telugu: "మీ రాత్రి పోస్టర్",
      english: "your night poster",
      hindi: "आपका रात का पोस्टर",
      tamil: "உங்கள் இரவு போஸ்டர்",
      kannada: "ನಿಮ್ಮ ರಾತ್ರಿ ಪೋಸ್ಟರ್",
      malayalam: "നിങ്ങളുടെ രാത്രി പോസ്റ്റർ",
    },
    welcome: {
      telugu: "మీ పోస్టర్",
      english: "your poster",
      hindi: "आपका पोस्टर",
      tamil: "உங்கள் போஸ்டர்",
      kannada: "ನಿಮ್ಮ ಪೋಸ್ಟರ್",
      malayalam: "നിങ്ങളുടെ പോസ്റ്റർ",
    },
  };
  const group = labels[category] || labels.welcome;
  return group[lang] || group.english;
}

async function loadBrandLogoDataUri() {
  if (loadBrandLogoDataUri.cached) {
    return loadBrandLogoDataUri.cached;
  }
  const logoPath = path.join(__dirname, "assets", "branding", "mana_poster_logo.png");
  const logoBuffer = await sharp(logoPath)
      .resize(72, 72, {fit: "contain", background: {r: 0, g: 0, b: 0, alpha: 0}})
      .png()
      .toBuffer();
  loadBrandLogoDataUri.cached = `data:image/png;base64,${logoBuffer.toString("base64")}`;
  return loadBrandLogoDataUri.cached;
}

async function loadNotificationFontDataUri() {
  if (loadNotificationFontDataUri.cached) {
    return loadNotificationFontDataUri.cached;
  }
  const fontPath = path.join(__dirname, "assets", "fonts", "notosanstelugu_condensed_bold.ttf");
  const fontBuffer = await fs.promises.readFile(fontPath);
  loadNotificationFontDataUri.cached = `data:font/ttf;base64,${fontBuffer.toString("base64")}`;
  return loadNotificationFontDataUri.cached;
}

let notificationBrowserPromise = null;

async function resolveNotificationBrowserExecutablePath() {
  if (process.platform === "win32") {
    const candidates = [
      "C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe",
      "C:\\Program Files (x86)\\Google\\Chrome\\Application\\chrome.exe",
      "C:\\Program Files\\Microsoft\\Edge\\Application\\msedge.exe",
      "C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe",
    ];
    for (const candidate of candidates) {
      if (fs.existsSync(candidate)) {
        return candidate;
      }
    }
  }
  return chromium.executablePath();
}

async function getNotificationBrowser() {
  if (!notificationBrowserPromise) {
    notificationBrowserPromise = (async () => {
      const executablePath = await resolveNotificationBrowserExecutablePath();
      return puppeteer.launch({
        executablePath,
        headless: true,
        args: [
          ...(chromium.args || []),
          "--no-sandbox",
          "--disable-setuid-sandbox",
          "--font-render-hinting=medium",
        ],
        defaultViewport: {
          width: 1080,
          height: 1160,
          deviceScaleFactor: 1,
        },
      });
    })().catch((error) => {
      notificationBrowserPromise = null;
      throw error;
    });
  }
  return notificationBrowserPromise;
}

function notificationFontPath() {
  return path.join(__dirname, "assets", "fonts", "notosanstelugu_condensed_bold.ttf");
}

async function renderNotificationTextBuffer(text, {
  width,
  fontSize,
  color = "#1E1E1E",
  align = "left",
  dpi = 144,
  lineSpacing = 0,
} = {}) {
  const value = String(text || "").trim().normalize("NFC");
  if (!value) {
    return null;
  }
  return sharp({
    text: {
      text: value,
      font: "Noto Sans Telugu Condensed Bold",
      fontfile: notificationFontPath(),
      width,
      rgba: true,
      align,
      dpi,
      spacing: lineSpacing,
    },
  }).png().toBuffer();
}

const notificationFrameBuffers = new Map();
const notificationFrameByCategory = {
  welcome: "morning.png",
  morning: "morning.png",
  afternoon: "afternoon.png",
  night: "night.png",
};

async function loadNotificationFrameBuffer(categoryKey) {
  const normalized = reminderCategoryKey(categoryKey);
  const fileName = notificationFrameByCategory[normalized] || notificationFrameByCategory.morning;
  if (notificationFrameBuffers.has(fileName)) {
    logger.info("loadNotificationFrameBuffer cache hit", {
      categoryKey: normalized,
      fileName,
    });
    return notificationFrameBuffers.get(fileName);
  }
  const framePath = path.join(__dirname, "assets", "notification_frames", fileName);
  logger.info("loadNotificationFrameBuffer reading frame", {
    categoryKey: normalized,
    fileName,
    framePath,
  });
  const frameBuffer = await fs.promises.readFile(framePath);
  notificationFrameBuffers.set(fileName, frameBuffer);
  logger.info("loadNotificationFrameBuffer loaded frame", {
    categoryKey: normalized,
    fileName,
    bytes: frameBuffer.length,
  });
  return frameBuffer;
}

async function buildPersonalizedNotificationImage({
  title,
  body,
  headerText,
  footerText,
  posterImageUrl,
  userName,
  userPhotoUrl,
  categoryKey,
  seed,
}) {
  logger.info("buildPersonalizedNotificationImage started", {
    categoryKey: reminderCategoryKey(categoryKey),
    hasPosterImageUrl: Boolean(String(posterImageUrl || "").trim()),
    hasUserPhotoUrl: Boolean(String(userPhotoUrl || "").trim()),
    seed: String(seed || "").slice(0, 48),
  });
  const posterBuffer = await downloadBufferFromUrl(posterImageUrl);
  if (!posterBuffer) {
    logger.warn("buildPersonalizedNotificationImage poster download missing", {
      categoryKey: reminderCategoryKey(categoryKey),
      posterImageUrl: String(posterImageUrl || "").slice(0, 256),
    });
    return null;
  }

  const palette = {
    shell: "#ffffff",
    frame: "#0A9F16",
    header: "#15930E",
    footer: "#03B92B",
    accent: "#03B92B",
    text: "#1F7D1F",
  };
  const fontDataUri = await loadNotificationFontDataUri();
  await loadNotificationFrameBuffer(categoryKey);
  const posterResized = await sharp(posterBuffer)
      .resize(980, 390, {fit: "cover", position: "attention"})
      .png()
      .toBuffer();
  const posterDataUri = `data:image/png;base64,${posterResized.toString("base64")}`;

  let avatarDataUri = initialsSvgDataUri(userName, palette);
  const avatarBuffer = await downloadBufferFromUrl(userPhotoUrl);
  if (avatarBuffer) {
    try {
      const avatarResized = await sharp(avatarBuffer)
          .resize(216, 216, {fit: "cover", position: "attention"})
          .png()
          .toBuffer();
      avatarDataUri = `data:image/png;base64,${avatarResized.toString("base64")}`;
    } catch (error) {
      logger.warn("avatar resize failed", {userPhotoUrl, error});
    }
  }

  const safeHeader = String(headerText || title || body || "")
      .trim()
      .normalize("NFC");
  const safeFooter = String(footerText || "షేర్ చేయండి")
      .trim()
      .normalize("NFC");
  const safeDisplayName = String(userName || "")
      .trim()
      .normalize("NFC")
      .slice(0, 80);
  const browser = await getNotificationBrowser();
  const page = await browser.newPage();
  try {
    const html = `<!doctype html>
    <html>
      <head>
        <meta charset="utf-8">
        <style>
          @font-face {
            font-family: "ManaPosterTelugu";
            src: url(${fontDataUri}) format("truetype");
          }
          body {
            margin: 0;
            background: #ffffff;
            font-family: "ManaPosterTelugu", "Nirmala UI", "Gautami", sans-serif;
            -webkit-font-smoothing: antialiased;
          }
          .root {
            width: 1080px;
            height: 900px;
            background: #ffffff;
            position: relative;
            overflow: hidden;
          }
          .card-shell {
            position: absolute;
            inset: 0;
            background: #ffffff;
            border: 10px solid ${palette.frame};
            box-sizing: border-box;
            overflow: hidden;
          }
          .notification-header {
            position: absolute;
            left: 0;
            top: 0;
            width: 100%;
            height: 232px;
            background: ${palette.header};
          }
          .header-avatar {
            position: absolute;
            left: 34px;
            top: 62px;
            width: 106px;
            height: 106px;
            border-radius: 53px;
            object-fit: cover;
            border: 4px solid rgba(255,255,255,0.82);
            box-sizing: border-box;
          }
          .header-brand {
            position: absolute;
            left: 168px;
            top: 28px;
            font-size: 20px;
            line-height: 1.1;
            font-weight: 900;
            color: #ffffff;
            font-family: "ManaPosterTelugu", "Nirmala UI", "Gautami", sans-serif;
          }
          .header {
            position: absolute;
            left: 168px;
            top: 52px;
            width: 868px;
            font-size: 54px;
            line-height: 1.12;
            font-weight: 900;
            color: #ffffff;
            max-height: 168px;
            overflow: hidden;
            font-family: "ManaPosterTelugu", "Nirmala UI", "Gautami", sans-serif;
            word-break: normal;
          }
          .poster {
            position: absolute;
            left: 36px;
            top: 246px;
            width: 1008px;
            height: 390px;
            object-fit: cover;
            display: block;
          }
          .footer-white {
            position: absolute;
            left: 36px;
            top: 636px;
            width: 1008px;
            height: 190px;
            background: #ffffff;
          }
          .avatar-wrap {
            position: absolute;
            left: 50%;
            top: 562px;
            width: 172px;
            height: 172px;
            transform: translateX(-50%);
            border-radius: 50%;
            background: #ffffff;
            padding: 6px;
            box-sizing: border-box;
            border: 4px solid ${palette.frame};
          }
          .avatar {
            width: 100%;
            height: 100%;
            border-radius: 50%;
            object-fit: cover;
            display: block;
          }
          .name-under {
            position: absolute;
            left: 50%;
            top: 742px;
            transform: translateX(-50%);
            width: 920px;
            text-align: center;
            font-size: 30px;
            line-height: 1.25;
            font-weight: 800;
            color: ${palette.text};
            font-family: "ManaPosterTelugu", "Nirmala UI", "Gautami", sans-serif;
            max-height: 88px;
            overflow: hidden;
          }
          .share {
            position: absolute;
            left: 36px;
            bottom: 34px;
            width: 1008px;
            height: 72px;
            border-radius: 0;
            background: ${palette.footer};
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 14px;
            color: #ffffff;
            font-size: 28px;
            font-weight: 800;
            font-family: "ManaPosterTelugu", "Nirmala UI", "Gautami", sans-serif;
          }
          .share-icon {
            width: 34px;
            height: 34px;
            object-fit: contain;
          }
        </style>
      </head>
      <body>
        <div class="root">
          <div class="card-shell">
            <div class="notification-header"></div>
            <img class="header-avatar" src="${avatarDataUri}" alt="">
            <div class="header-brand">Mana Poster Ai</div>
            <div class="header">${htmlEscape(safeHeader)}</div>
            <img class="poster" src="${posterDataUri}" alt="">
            <div class="footer-white"></div>
            <div class="avatar-wrap">
              <img class="avatar" src="${avatarDataUri}" alt="">
            </div>
            ${safeDisplayName ? `<div class="name-under">${htmlEscape(safeDisplayName)}</div>` : ""}
            <div class="share">
              <img class="share-icon" src="${whatsappGlyphDataUri()}" alt="">
              <span>${htmlEscape(safeFooter)}</span>
            </div>
          </div>
        </div>
      </body>
    </html>`;
    await page.setViewport({width: 1080, height: 900, deviceScaleFactor: 1});
    await page.setContent(html, {waitUntil: "load"});
    await page.evaluate(async () => {
      try {
        await document.fonts.ready;
      } catch (_) {}
    });
    const outputBuffer = await page.screenshot({type: "png"});
    logger.info("buildPersonalizedNotificationImage completed", {
      categoryKey: reminderCategoryKey(categoryKey),
      outputBytes: outputBuffer.length,
    });
    return outputBuffer;
  } finally {
    await page.close().catch(() => {});
  }
}

async function uploadNotificationImageBuffer({
  buffer,
  objectPath,
}) {
  const bucket = admin.storage().bucket();
  const token = crypto.randomUUID();
  const file = bucket.file(objectPath);
  await file.save(buffer, {
    resumable: false,
    metadata: {
      contentType: "image/png",
      cacheControl: "public,max-age=86400",
      metadata: {
        firebaseStorageDownloadTokens: token,
      },
    },
  });
  return buildStorageDownloadUrl(bucket.name, objectPath, token);
}

async function sendReminderToToken({
  token,
  platform = "",
  title,
  body,
  imageUrl = null,
  posterBaseImageUrl = "",
  userName = "",
  userPhotoUrl = "",
  languageCode = "",
  headerText = "",
  footerText = "",
  categoryKey = "",
  titleKey = "",
  bodyKey = "",
  route = "",
  openKind = "",
}) {
  const normalizedTitle = String(title || "").trim();
  const normalizedBody = String(body || "").trim();
  const normalizedImageUrl = String(imageUrl || "").trim();
  const resolvedRoute = String(route || "").trim() ||
      notificationOpenRoute(categoryKey, openKind);
  const normalizedCategory = reminderCategoryKey(categoryKey);
  const message = {
    token,
    android: {
      priority: "high",
    },
    apns: {
      payload: {
        aps: {
          alert: {
            title: normalizedTitle,
            body: normalizedBody,
          },
          contentAvailable: true,
        },
      },
    },
    data: {
      click_action: "FLUTTER_NOTIFICATION_CLICK",
      route: resolvedRoute,
      title: normalizedTitle,
      body: normalizedBody,
      title_key: titleKey || "",
      body_key: bodyKey || "",
      userName: userName || "",
      userPhoto: userPhotoUrl || "",
      languageCode: String(languageCode || "").trim(),
      headerText: headerText || "",
      footerText: footerText || "",
      categoryKey: categoryKey || "",
      notificationKind: normalizedCategory,
      posterPreviewImage: normalizedImageUrl,
      posterBaseImage: posterBaseImageUrl || "",
      posterImage: normalizedImageUrl,
    },
  };

  if (String(platform || "").trim().toLowerCase() === "ios") {
    message.notification = {
      title: normalizedTitle,
      body: normalizedBody,
    };
  }

  if (normalizedImageUrl && String(platform || "").trim().toLowerCase() === "ios") {
    message.apns.fcmOptions = {image: normalizedImageUrl};
  }

  return admin.messaging().send(message);
}

async function sendPersonalizedReminderToToken({
  token,
  platform = "",
  title,
  body,
  headerText,
  footerText,
  baseImageUrl,
  categoryKey,
  userName,
  userPhotoUrl,
  languageCode = "",
  seed,
}) {
  let imageUrl = String(baseImageUrl || "").trim();
  if (imageUrl) {
    try {
      logger.info("sendPersonalizedReminderToToken image generation started", {
        tokenSuffix: String(token || "").slice(-12),
        categoryKey: reminderCategoryKey(categoryKey),
        hasBaseImageUrl: true,
      });
      const buffer = await buildPersonalizedNotificationImage({
        title,
        body,
        headerText,
        footerText,
        posterImageUrl: imageUrl,
        userName,
        userPhotoUrl,
        categoryKey,
        seed,
      });
      if (buffer) {
        imageUrl = await uploadNotificationImageBuffer({
          buffer,
          objectPath: `notifications/rendered/${categoryKey}/${Date.now()}-${stableHashNumber(seed)}.png`,
        });
        logger.info("sendPersonalizedReminderToToken image upload completed", {
          tokenSuffix: String(token || "").slice(-12),
          categoryKey: reminderCategoryKey(categoryKey),
          imageUrl,
        });
      } else {
        imageUrl = "";
        logger.warn("sendPersonalizedReminderToToken using plain fallback after null image buffer", {
          tokenSuffix: String(token || "").slice(-12),
          categoryKey: reminderCategoryKey(categoryKey),
        });
      }
    } catch (error) {
      imageUrl = "";
      logger.error("sendPersonalizedReminderToToken image generation failed, using plain fallback", {
        tokenSuffix: String(token || "").slice(-12),
        categoryKey: reminderCategoryKey(categoryKey),
        error: messagingErrorDetails(error),
      });
    }
  }

  logger.info("sendPersonalizedReminderToToken sending notification", {
    tokenSuffix: String(token || "").slice(-12),
    categoryKey: reminderCategoryKey(categoryKey),
    hasImageUrl: Boolean(String(imageUrl || "").trim()),
  });
  const messageId = await sendReminderToToken({
    token,
    platform,
    title,
    body,
    imageUrl: imageUrl || null,
    posterBaseImageUrl: baseImageUrl || "",
    userName,
    userPhotoUrl,
    languageCode,
    headerText,
    footerText,
    categoryKey,
    titleKey: `${categoryKey}_title`,
    bodyKey: `${categoryKey}_body`,
  });
  logger.info("sendPersonalizedReminderToToken send success", {
    tokenSuffix: String(token || "").slice(-12),
    categoryKey: reminderCategoryKey(categoryKey),
    hasImageUrl: Boolean(String(imageUrl || "").trim()),
    messageId,
  });
  return messageId;
}

async function sendWelcomeToToken(
    token,
    platform = "",
    language = "english",
    userName = "",
) {
  const copy = reminderCopyLocalized("welcome", language, userName);
  const imageUrl = await getPrimaryBannerImage();
  await sendReminderToToken({
    token,
    platform,
    title: copy.title,
    body: copy.body,
    imageUrl,
    posterBaseImageUrl: imageUrl || "",
    headerText: copy.header,
    footerText: copy.footer,
    categoryKey: "welcome",
    titleKey: "welcome_title",
    bodyKey: "welcome_body",
    userName,
    languageCode: language,
  });
}

async function sendPersonalizedWelcomeToToken({
  token,
  platform = "",
  userName,
  userPhotoUrl,
  seed,
  title,
  body,
  headerText,
  footerText,
  language,
}) {
  const copy = {
    title: title || reminderCopyLocalized("welcome", language, userName).title,
    body: body || reminderCopyLocalized("welcome", language, userName).body,
    header: headerText || reminderCopyLocalized("welcome", language, userName).header,
    footer: footerText || reminderCopyLocalized("welcome", language, userName).footer,
  };
  const imageUrl = await getPrimaryBannerImage();
  await sendPersonalizedReminderToToken({
    token,
    platform,
    title: copy.title,
    body: copy.body,
    headerText: copy.header,
    footerText: copy.footer,
    baseImageUrl: imageUrl,
    categoryKey: "welcome",
    userName,
    userPhotoUrl,
    languageCode: language,
    seed,
  });
}

function normalizeText(value) {
  return String(value || "").trim().toLowerCase();
}

async function getRelatedPosterImagesByKeywords(keywords, regionId = "") {
  const keyList = (keywords || [])
      .map((item) => normalizeText(item))
      .filter((item) => item.length > 0);
  const resolvedRegionId = normalizeRegionId(regionId);
  if (keyList.length === 0 || !resolvedRegionId) {
    return [];
  }

  try {
    const lookupRegionIds = sharedContentRegionIdsFor(resolvedRegionId);
    const snap = await applyRegionScope(db
        .collection("creatorPosters")
        .where("status", "==", "approved"), lookupRegionIds)
        .orderBy("createdAt", "desc")
        .limit(300)
        .get();

    const matchedImages = [];
    const nowMillis = Date.now();
    for (const doc of snap.docs) {
      const data = doc.data() || {};
      const categoryId = String(data.categoryId || "");
      const categoryLabel = String(data.categoryLabel || "");
      const imageUrl = String(data.imageUrl || "").trim();
      if (!imageUrl) {
        continue;
      }
      if (!posterIsCurrentlyVisible(data, nowMillis)) {
        continue;
      }
      const matched = keyList.some((keyword) =>
        categoryMatchesStrictAlias(categoryId, categoryLabel, keyword),
      );
      if (matched) {
        matchedImages.push(imageUrl);
      }
    }
    return matchedImages;
  } catch (error) {
    logger.warn("getRelatedPosterImagesByKeywords failed", error);
    return [];
  }
}

function reminderCategoryAliases(input) {
  const category = reminderCategoryKey(input);
  if (category === "morning") {
    return ["good_morning", "good morning", "morning", "suprabhatam"];
  }
  if (category === "afternoon") {
    return ["good_afternoon", "good afternoon", "afternoon", "madhyahna"];
  }
  if (category === "night") {
    return ["good_night", "good night", "night", "evening", "ratri"];
  }
  if (category === "motivation") {
    return ["motivational", "motivation"];
  }
  if (category === "jokes") {
    return ["jokes", "joke", "funny", "humor", "comedy"];
  }
  if (category === "islam") {
    return ["islam", "muslim"];
  }
  if (category === "bible") {
    return ["bible", "christian"];
  }
  if (category.startsWith("weekday_") && category.endsWith("_special")) {
    const weekday = category
        .replace(/^weekday_/, "")
        .replace(/_special$/, "");
    return [category, `${weekday} special`, "weekday special"];
  }
  return [];
}

function normalizeCategoryToken(value) {
  return normalizeText(value)
      .replace(/[^a-z0-9]+/g, " ")
      .trim()
      .replace(/\s+/g, " ");
}

function compactCategoryToken(value) {
  return normalizeCategoryToken(value).replace(/\s+/g, "");
}

function categoryMatchesStrictAlias(categoryId, categoryLabel, alias) {
  const normalizedAlias = normalizeCategoryToken(alias);
  const compactAlias = compactCategoryToken(alias);
  const candidates = [categoryId, categoryLabel]
      .map((item) => normalizeCategoryToken(item))
      .filter((item) => item.length > 0);
  return candidates.some((candidate) =>
    candidate === normalizedAlias ||
    compactCategoryToken(candidate) === compactAlias,
  );
}

function posterIsCurrentlyVisible(data, nowMillis = Date.now()) {
  const publishAt = toMillis(data.publishAt);
  const createdAt = toMillis(data.createdAt);
  const eventEndAt = toMillis(data.eventEndAt);
  const visibleFrom = publishAt > 0 ? publishAt : (createdAt > 0 ? createdAt : nowMillis);
  if (visibleFrom > nowMillis) {
    return false;
  }
  if (eventEndAt > 0 && nowMillis > eventEndAt) {
    return false;
  }
  return true;
}

async function getApprovedPosterImagesForReminderCategory(categoryKey, regionId = "") {
  const aliases = reminderCategoryAliases(categoryKey)
      .map((item) => normalizeText(item))
      .filter((item) => item.length > 0);
  const resolvedRegionId = normalizeRegionId(regionId);
  if (aliases.length === 0 || !resolvedRegionId) {
    return [];
  }

  try {
    const lookupRegionIds = sharedContentRegionIdsFor(resolvedRegionId, categoryKey);
    const snap = await applyRegionScope(db
        .collection("creatorPosters")
        .where("status", "==", "approved"), lookupRegionIds)
        .orderBy("createdAt", "desc")
        .limit(300)
        .get();

    const matchedImages = [];
    const nowMillis = Date.now();
    for (const doc of snap.docs) {
      const data = doc.data() || {};
      const categoryId = String(data.categoryId || "");
      const categoryLabel = String(data.categoryLabel || "");
      const imageUrl = String(data.imageUrl || "").trim();
      if (!imageUrl) {
        continue;
      }
      if (!posterIsCurrentlyVisible(data, nowMillis)) {
        continue;
      }
      const matched = aliases.some((alias) =>
        categoryMatchesStrictAlias(categoryId, categoryLabel, alias),
      );
      if (matched) {
        matchedImages.push(imageUrl);
      }
    }
    return matchedImages;
  } catch (error) {
    logger.warn("getApprovedPosterImagesForReminderCategory failed", {
      categoryKey,
      regionId: resolvedRegionId,
      error,
    });
    return [];
  }
}

async function pickImageForReminder(keywords, seed = "", regionId = "") {
  const resolvedRegionId = normalizeRegionId(regionId);
  if (!resolvedRegionId) {
    return "";
  }
  const normalizedCategory = reminderCategoryKey(
      Array.isArray(keywords) ? keywords.join(" ") : keywords,
  );
  const strictMatches = await getApprovedPosterImagesForReminderCategory(
      normalizedCategory,
      resolvedRegionId,
  );
  if (strictMatches.length > 0) {
    const index = stableHashNumber(
        `${normalizedCategory}-${seed || Date.now()}-strict`,
    ) % strictMatches.length;
    return strictMatches[index] || "";
  }

  const relatedMatches = await getRelatedPosterImagesByKeywords(keywords, resolvedRegionId);
  if (relatedMatches.length > 0) {
    const index = stableHashNumber(
        `${normalizedCategory}-${seed || Date.now()}-related`,
    ) % relatedMatches.length;
    return relatedMatches[index] || "";
  }

  return "";
}

async function pickStrictImageForReminderCategory(categoryKey, seed = "", regionId = "") {
  const resolvedRegionId = normalizeRegionId(regionId);
  if (!resolvedRegionId) {
    return "";
  }
  const strictMatches = await getApprovedPosterImagesForReminderCategory(
      categoryKey,
      resolvedRegionId,
  );
  if (strictMatches.length === 0) {
    return "";
  }
  const index = stableHashNumber(
      `${reminderCategoryKey(categoryKey)}-${seed || Date.now()}-strict-only`,
  ) % strictMatches.length;
  return strictMatches[index] || "";
}

async function runWithConcurrency(items, limit, worker) {
  const safeLimit = Math.max(1, Number(limit) || 1);
  let index = 0;
  const runners = Array.from({length: Math.min(safeLimit, items.length)}, async () => {
    while (true) {
      const currentIndex = index;
      index += 1;
      if (currentIndex >= items.length) {
        return;
      }
      await worker(items[currentIndex], currentIndex);
    }
  });
  await Promise.all(runners);
}

function isMessagingTokenGoneError(error) {
  const details = messagingErrorDetails(error);
  const code = details.code;
  const message = details.message;
  return code === "messaging/registration-token-not-registered" ||
    /Requested entity was not found/i.test(message) ||
    /NotRegistered/i.test(message) ||
    /registration-token-not-registered/i.test(message);
}

function messagingErrorDetails(error) {
  const codeCandidates = [
    error && error.code,
    error && error.errorInfo && error.errorInfo.code,
    error && error.details && error.details.code,
    error && error.status,
    error && error.response && error.response.data &&
      error.response.data.error && error.response.data.error.status,
  ];
  const messageCandidates = [
    error && error.message,
    error && error.errorInfo && error.errorInfo.message,
    error && error.details && error.details.message,
    error && error.response && error.response.data &&
      error.response.data.error && error.response.data.error.message,
    error && error.cause && error.cause.message,
    error,
  ];
  const code = codeCandidates
      .map((value) => String(value || "").trim())
      .find((value) => value.length > 0) || "";
  const message = messageCandidates
      .map((value) => String(value || "").trim())
      .find((value) => value.length > 0) || "";
  return {code, message};
}

async function cleanupInvalidTokenRef(ref) {
  if (!ref) {
    return;
  }
  try {
    await ref.delete();
  } catch (error) {
    logger.warn("cleanupInvalidTokenRef failed", {path: ref.path, error});
  }
}

async function sendThreeKindsToFcmToken(fcmToken, uidHint = "") {
  const morningKeywords = [
    "good morning",
    "morning",
    "suprabhatam",
  ];
  const afternoonKeywords = [
    "good afternoon",
    "afternoon",
    "madhyahna",
  ];
  const nightKeywords = [
    "good night",
    "night",
    "ratri",
  ];

  let uid = String(uidHint || "").trim();
  let platform = "android";
  let tokenRegionId = "";
  if (uid && fcmToken) {
    const snap = await db.collection("users").doc(uid).collection("deviceTokens")
        .where("token", "==", fcmToken)
        .limit(1)
        .get();
    if (!snap.empty) {
      const data = snap.docs[0].data() || {};
      platform = String(data.platform || "android").trim() || "android";
      tokenRegionId = notificationRegionFromData(data);
    }
  }

  const profile = await loadNotificationProfileForUid(uid);
  const resolvedRegionId = normalizeRegionId(tokenRegionId || profile.selectedRegion);
  const jobs = [
    {categoryKey: "morning", keywords: morningKeywords},
    {categoryKey: "afternoon", keywords: afternoonKeywords},
    {categoryKey: "night", keywords: nightKeywords},
  ];
  const results = [];
  for (const job of jobs) {
    const imageUrl = await pickStrictImageForReminderCategory(
        job.categoryKey,
        `${job.categoryKey}-manual-${Date.now()}-${resolvedRegionId}`,
        resolvedRegionId,
    );
    if (!imageUrl) {
      results.push({
        categoryKey: job.categoryKey,
        skipped: true,
        reason: resolvedRegionId ? "no_regional_category_poster" : "missing_region",
      });
      continue;
    }
    const copy = reminderCopyLocalized(
        job.categoryKey,
        profile.preferredLanguage,
        profile.name,
    );
    const messageId = await sendPersonalizedReminderToToken({
      token: fcmToken,
      platform,
      title: copy.title,
      body: copy.body,
      headerText: copy.header,
      footerText: copy.footer,
      baseImageUrl: imageUrl || "",
      categoryKey: job.categoryKey,
      userName: profile.name,
      userPhotoUrl: profile.photoUrl,
      languageCode: profile.preferredLanguage,
      seed:
        `${uid || "public"}-${fcmToken}-${job.categoryKey}-manual-${Date.now()}-${crypto.randomUUID()}`,
    });
    results.push({
      categoryKey: job.categoryKey,
      messageId,
      hasBaseImageUrl: Boolean(String(imageUrl || "").trim()),
    });
  }
  return results;
}

function tokenNotificationsEnabled(data) {
  return data.allNotifications !== false;
}

function tokenAllowsCategory(data, categoryKey) {
  if (!tokenNotificationsEnabled(data)) {
    return false;
  }
  const category = reminderCategoryKey(categoryKey);
  if (category === "morning" || category === "afternoon" || category === "night") {
    return data.newPosters !== false;
  }
  if (category === "welcome") {
    return true;
  }
  if (category === "subscription") {
    return data.subscriptionReminders !== false;
  }
  return data.newPosters !== false;
}

function normalizeReligionPreference(value) {
  const normalized = normalizeText(value);
  if (normalized === "hindu" || normalized === "muslim" || normalized === "christian") {
    return normalized;
  }
  if (normalized === "all") {
    return "all";
  }
  return "";
}

function tokenReligionFromData(data) {
  return normalizeReligionPreference(data && data.religionPreference);
}

function tokenAllowsReligion(data, targetReligion = "") {
  const target = normalizeReligionPreference(targetReligion);
  if (!target || target === "all") {
    return true;
  }
  return tokenReligionFromData(data) === target;
}

function weekdaySpecialCategoryKey(now = new Date()) {
  const weekday = new Intl.DateTimeFormat("en-US", {
    timeZone: "Asia/Kolkata",
    weekday: "long",
  }).format(now).toLowerCase();
  const allowed = new Set([
    "monday",
    "tuesday",
    "wednesday",
    "thursday",
    "friday",
    "saturday",
    "sunday",
  ]);
  const safeWeekday = allowed.has(weekday) ? weekday : "monday";
  return `weekday_${safeWeekday}_special`;
}

function religionDailyTarget(religion, now = new Date()) {
  const target = normalizeReligionPreference(religion);
  if (target === "muslim") {
    return {religion: target, categoryKey: "islam", label: "Islam"};
  }
  if (target === "christian") {
    return {religion: target, categoryKey: "bible", label: "Bible"};
  }
  if (target === "hindu") {
    const categoryKey = weekdaySpecialCategoryKey(now);
    const weekdayLabel = categoryKey
        .replace(/^weekday_/, "")
        .replace(/_special$/, "")
        .replace(/^\w/, (char) => char.toUpperCase());
    return {religion: target, categoryKey, label: `${weekdayLabel} Special`};
  }
  return null;
}

async function sendDailyPersonalizedReminder({
  keywords,
  categoryKey,
  reminderSeed = "",
  targetReligion = "",
  displayLabel = "",
}) {
  const now = new Date();
  const dayKey = getIstDayKey(now);
  const resolvedSeed = normalizeText(reminderSeed) || "default";
  const userTokenSnap = await db.collectionGroup("deviceTokens").get();
  const seenTokens = new Set();
  const profileCache = new Map();
  const imageCache = new Map();
  const userJobs = [];

  async function imageForRegion(regionId) {
    const resolvedRegionId = normalizeRegionId(regionId);
    const cacheKey = `${resolvedRegionId || "all"}:${categoryKey}:${resolvedSeed}`;
    if (imageCache.has(cacheKey)) {
      return imageCache.get(cacheKey);
    }
    let imageUrl = "";
    if (resolvedRegionId) {
      imageUrl = await pickStrictImageForReminderCategory(
          categoryKey,
          `${categoryKey}-${dayKey}-${resolvedSeed}-${resolvedRegionId}`,
          resolvedRegionId,
      );
    }
    imageCache.set(cacheKey, imageUrl || "");
    return imageUrl || "";
  }

  for (const doc of userTokenSnap.docs) {
    const data = doc.data() || {};
    const token = String(data.token || "").trim();
    if (!token || seenTokens.has(token) ||
        !tokenAllowsCategory(data, categoryKey)) {
      continue;
    }
    const userRef = doc.ref.parent && doc.ref.parent.parent;
    const uid = userRef ? userRef.id : "";
    seenTokens.add(token);
    userJobs.push({
      token,
      uid,
      ref: doc.ref,
      platform: String(data.platform || "").trim(),
      language: notificationLanguageFromTokenData(data),
      regionId: notificationRegionFromData(data),
      religionPreference: tokenReligionFromData(data),
    });
  }

  await runWithConcurrency(userJobs, 12, async ({
    token,
    uid,
    ref,
    platform,
    language,
    regionId,
    religionPreference,
  }) => {
    let profile = profileCache.get(uid);
    if (!profile) {
      profile = await loadNotificationProfileForUid(uid);
      profileCache.set(uid, profile);
    }
    try {
      if (targetReligion) {
        const tokenReligion = normalizeReligionPreference(religionPreference);
        const profileReligion = normalizeReligionPreference(profile.religionPreference);
        if (tokenReligion !== targetReligion && profileReligion !== targetReligion) {
          return;
        }
      }
      const resolvedRegionId = normalizeRegionId(regionId || profile.selectedRegion);
      const imageUrl = await imageForRegion(resolvedRegionId);
      if (!imageUrl) {
        logger.info("personalized daily reminder skipped: no poster", {
          uid,
          categoryKey,
          regionId: resolvedRegionId,
        });
        return;
      }
      const reservation = await reserveNotificationDelivery({
        token,
        categoryKey,
        slotKey: `${categoryKey}-${resolvedSeed}`,
        dayKey,
      });
      if (!reservation.allowed) {
        logger.info("personalized daily reminder skipped by frequency guard", {
          uid,
          categoryKey,
          reason: reservation.reason,
        });
        return;
      }
      const copy = targetReligion ?
        buildNotificationCopy(
            "dynamic_event",
            language || profile.preferredLanguage,
            profile.name,
            {eventTitle: displayLabel || categoryKey, timing: "today"},
        ) :
        reminderCopyLocalized(
            categoryKey,
            language || profile.preferredLanguage,
            profile.name,
            now,
        );
      await sendReminderToToken({
        token,
        platform,
        title: copy.title,
        body: copy.body,
        imageUrl: imageUrl || null,
        posterBaseImageUrl: imageUrl || "",
        headerText: copy.header || "",
        footerText: copy.footer || "",
        categoryKey,
        titleKey: `${categoryKey}_title`,
        bodyKey: `${categoryKey}_body`,
        userName: profile.name || "",
        userPhotoUrl: profile.photoUrl || "",
        languageCode: language || profile.preferredLanguage || "",
      });
    } catch (error) {
      if (isMessagingTokenGoneError(error)) {
        await cleanupInvalidTokenRef(ref);
      }
      logger.error("personalized daily reminder failed", {
        uid,
        token,
        categoryKey,
        error: messagingErrorDetails(error),
      });
    }
  });

  const publicSnap = await db.collection("publicDeviceTokens").get();
  const publicJobs = [];
  for (const doc of publicSnap.docs) {
    const data = doc.data() || {};
    const token = String(data.token || "").trim();
    if (!token || seenTokens.has(token) ||
        !tokenAllowsCategory(data, categoryKey) ||
        !tokenAllowsReligion(data, targetReligion)) {
      continue;
    }
    seenTokens.add(token);
    publicJobs.push({
      token,
      ref: doc.ref,
      platform: String(data.platform || "").trim(),
      language: notificationLanguageFromTokenData(data),
      regionId: notificationRegionFromData(data),
    });
  }

  await runWithConcurrency(publicJobs, 12, async ({token, ref, platform, language, regionId}) => {
    try {
      const resolvedRegionId = normalizeRegionId(regionId);
      const imageUrl = await imageForRegion(resolvedRegionId);
      if (!imageUrl) {
        logger.info("public daily reminder skipped: no poster", {
          tokenSuffix: String(token || "").slice(-12),
          categoryKey,
          regionId: resolvedRegionId,
        });
        return;
      }
      const reservation = await reserveNotificationDelivery({
        token,
        categoryKey,
        slotKey: `${categoryKey}-${resolvedSeed}`,
        dayKey,
      });
      if (!reservation.allowed) {
        logger.info("public daily reminder skipped by frequency guard", {
          tokenSuffix: String(token || "").slice(-12),
          categoryKey,
          reason: reservation.reason,
        });
        return;
      }
      const copy = targetReligion ?
        buildNotificationCopy(
            "dynamic_event",
            language,
            "Mana Poster User",
            {eventTitle: displayLabel || categoryKey, timing: "today"},
        ) :
        reminderCopyLocalized(
            categoryKey,
            language,
            "Mana Poster User",
            now,
        );
      await sendReminderToToken({
        token,
        platform,
        title: copy.title,
        body: copy.body,
        imageUrl: imageUrl || null,
        posterBaseImageUrl: imageUrl || "",
        headerText: copy.header || "",
        footerText: copy.footer || "",
        categoryKey,
        titleKey: `${categoryKey}_title`,
        bodyKey: `${categoryKey}_body`,
        userName: "Mana Poster User",
        languageCode: language,
      });
    } catch (error) {
      if (isMessagingTokenGoneError(error)) {
        await cleanupInvalidTokenRef(ref);
      }
      logger.error("public daily reminder failed", {
        token,
        categoryKey,
        error: messagingErrorDetails(error),
      });
    }
  });
}

async function sendDirectReminderToEligibleTokens({
  categoryKey,
  title,
  body,
  imageUrl = "",
  eventTitle = "",
  eventTiming = "",
  eventKeywords = [],
  dynamicEvent = null,
}) {
  const userTokenSnap = await db.collectionGroup("deviceTokens").get();
  const publicSnap = await db.collection("publicDeviceTokens").get();
  const seenTokens = new Set();
  const profileCache = new Map();
  const imageCache = new Map();
  const jobs = [];

  async function imageForRegion(regionId) {
    const resolvedRegionId = normalizeRegionId(regionId);
    const cacheKey = `${resolvedRegionId || "all"}:${categoryKey}:${eventTitle}`;
    if (imageCache.has(cacheKey)) {
      return imageCache.get(cacheKey);
    }
    let regionalImageUrl = "";
    if (eventTitle && resolvedRegionId) {
      regionalImageUrl = await pickImageForReminder(
          eventKeywords.length > 0 ? eventKeywords : [eventTitle],
          `${eventTitle}-${eventTiming}-${resolvedRegionId}`,
          resolvedRegionId,
      );
    } else if (!eventTitle) {
      regionalImageUrl = String(imageUrl || "").trim();
    }
    imageCache.set(cacheKey, regionalImageUrl || "");
    return regionalImageUrl || "";
  }

  for (const doc of userTokenSnap.docs) {
    const data = doc.data() || {};
    const token = String(data.token || "").trim();
    if (!token || seenTokens.has(token) || !tokenAllowsCategory(data, categoryKey)) {
      continue;
    }
    seenTokens.add(token);
    const userRef = doc.ref.parent && doc.ref.parent.parent;
    const uid = userRef ? userRef.id : "";
    jobs.push({
      token,
      uid,
      ref: doc.ref,
      platform: String(data.platform || "").trim(),
      language: notificationLanguageFromTokenData(data),
      regionId: notificationRegionFromData(data),
    });
  }

  for (const doc of publicSnap.docs) {
    const data = doc.data() || {};
    const token = String(data.token || "").trim();
    if (!token || seenTokens.has(token) || !tokenAllowsCategory(data, categoryKey)) {
      continue;
    }
    seenTokens.add(token);
    jobs.push({
      token,
      ref: doc.ref,
      platform: String(data.platform || "").trim(),
      language: notificationLanguageFromTokenData(data),
      regionId: notificationRegionFromData(data),
    });
  }

  await runWithConcurrency(jobs, 4, async ({token, uid, ref, platform, language, regionId}) => {
    try {
      let resolvedTitle = title;
      let resolvedBody = body;
      let resolvedHeader = "";
      let resolvedFooter = "";
      let resolvedUserName = "";
      let resolvedPhotoUrl = "";
      let resolvedRegionId = normalizeRegionId(regionId);
      if (eventTitle) {
        let profile = uid ? profileCache.get(uid) : null;
        if (uid && !profile) {
          profile = await loadNotificationProfileForUid(uid);
          profileCache.set(uid, profile);
        }
        resolvedRegionId = normalizeRegionId(resolvedRegionId || profile?.selectedRegion);
        if (dynamicEvent && !dynamicEventAppliesToRegion(dynamicEvent, resolvedRegionId)) {
          logger.info("direct dynamic reminder skipped by region scope", {
            tokenSuffix: String(token || "").slice(-12),
            uid,
            eventId: dynamicEvent.id || "",
            eventTitle,
            regionId: resolvedRegionId,
          });
          return;
        }
        const copy = buildNotificationCopy(
            "dynamic_event",
            language || profile?.preferredLanguage,
            profile?.name || "Mana Poster User",
            {eventTitle, timing: eventTiming},
        );
        resolvedTitle = copy.title;
        resolvedBody = copy.body;
        resolvedHeader = copy.header || "";
        resolvedFooter = copy.footer || "";
        resolvedUserName = profile?.name || "Mana Poster User";
        resolvedPhotoUrl = profile?.photoUrl || "";
      }
      const dayKey = getIstDayKey(new Date());
      const resolvedImageUrl = await imageForRegion(resolvedRegionId);
      if (!resolvedImageUrl) {
        logger.info("direct reminder skipped: no poster", {
          tokenSuffix: String(token || "").slice(-12),
          categoryKey,
          regionId: resolvedRegionId,
          eventTitle,
        });
        return;
      }
      const reservation = await reserveNotificationDelivery({
        token,
        categoryKey,
        slotKey: eventTitle ?
          `event-${eventTitle}-${eventTiming}` :
          `direct-${categoryKey}`,
        dayKey,
      });
      if (!reservation.allowed) {
        logger.info("direct reminder skipped by frequency guard", {
          tokenSuffix: String(token || "").slice(-12),
          categoryKey,
          eventTitle,
          reason: reservation.reason,
        });
        return;
      }
      await sendReminderToToken({
        token,
        platform,
        title: resolvedTitle,
        body: resolvedBody,
        imageUrl: resolvedImageUrl || null,
        posterBaseImageUrl: resolvedImageUrl || "",
        headerText: resolvedHeader,
        footerText: resolvedFooter,
        categoryKey,
        route: eventTitle ? `event/${safeNotificationMetricKey(eventTitle)}` : "",
        openKind: eventTitle ? "event" : "",
        userName: resolvedUserName,
        userPhotoUrl: resolvedPhotoUrl,
        languageCode: language,
      });
    } catch (error) {
      if (isMessagingTokenGoneError(error)) {
        await cleanupInvalidTokenRef(ref);
      }
      logger.error("direct reminder send failed", {
        token,
        categoryKey,
        error: messagingErrorDetails(error),
      });
    }
  });
}

async function sendLocalizedGreetingReminder({
  categoryKey,
  reminderKind,
}) {
  const now = new Date();
  const dayKey = getIstDayKey(now);
  const userTokenSnap = await db.collectionGroup("deviceTokens").get();
  const publicSnap = await db.collection("publicDeviceTokens").get();
  const seenTokens = new Set();
  const profileCache = new Map();
  const imageCache = new Map();
  const userJobs = [];

  async function imageForRegion(regionId) {
    const resolvedRegionId = normalizeRegionId(regionId);
    const cacheKey = `${resolvedRegionId || "all"}:${categoryKey}:${reminderKind}`;
    if (imageCache.has(cacheKey)) {
      return imageCache.get(cacheKey);
    }
    let imageUrl = "";
    if (resolvedRegionId) {
      imageUrl = await pickStrictImageForReminderCategory(
          categoryKey,
          `${categoryKey}-${reminderKind}-${dayKey}-${resolvedRegionId}`,
          resolvedRegionId,
      );
    }
    imageCache.set(cacheKey, imageUrl || "");
    return imageUrl || "";
  }

  for (const doc of userTokenSnap.docs) {
    const data = doc.data() || {};
    const token = String(data.token || "").trim();
    if (!token || seenTokens.has(token) || !tokenAllowsCategory(data, categoryKey)) {
      continue;
    }
    const userRef = doc.ref.parent && doc.ref.parent.parent;
    const uid = userRef ? userRef.id : "";
    seenTokens.add(token);
    userJobs.push({
      token,
      uid,
      ref: doc.ref,
      platform: String(data.platform || "").trim(),
      language: notificationLanguageFromTokenData(data),
      regionId: notificationRegionFromData(data),
    });
  }

  await runWithConcurrency(userJobs, 12, async ({token, uid, ref, platform, language, regionId}) => {
    let profile = profileCache.get(uid);
    if (!profile) {
      profile = await loadNotificationProfileForUid(uid);
      profileCache.set(uid, profile);
    }
    const copy = greetingReminderVariant(
        reminderKind,
        language || profile.preferredLanguage,
        now,
    );
    try {
      const resolvedRegionId = normalizeRegionId(regionId || profile.selectedRegion);
      const imageUrl = await imageForRegion(resolvedRegionId);
      if (!imageUrl) {
        logger.info("localized greeting reminder skipped: no poster", {
          uid,
          categoryKey,
          reminderKind,
          regionId: resolvedRegionId,
        });
        return;
      }
      const reservation = await reserveNotificationDelivery({
        token,
        categoryKey,
        slotKey: `${categoryKey}-${reminderKind}`,
        dayKey,
      });
      if (!reservation.allowed) {
        logger.info("localized greeting reminder skipped by frequency guard", {
          uid,
          categoryKey,
          reminderKind,
          reason: reservation.reason,
        });
        return;
      }
      await sendReminderToToken({
        token,
        platform,
        title: copy.title,
        body: copy.body,
        imageUrl: imageUrl || null,
        posterBaseImageUrl: imageUrl || "",
        categoryKey,
        titleKey: `${reminderKind}_title`,
        bodyKey: `${reminderKind}_body`,
        languageCode: language || profile.preferredLanguage || "",
      });
    } catch (error) {
      if (isMessagingTokenGoneError(error)) {
        await cleanupInvalidTokenRef(ref);
      }
      logger.error("localized greeting reminder failed", {
        uid,
        token,
        reminderKind,
        error: messagingErrorDetails(error),
      });
    }
  });

  const publicJobs = [];
  for (const doc of publicSnap.docs) {
    const data = doc.data() || {};
    const token = String(data.token || "").trim();
    if (!token || seenTokens.has(token) || !tokenAllowsCategory(data, categoryKey)) {
      continue;
    }
    seenTokens.add(token);
    publicJobs.push({
      token,
      ref: doc.ref,
      platform: String(data.platform || "").trim(),
      language: notificationLanguageFromTokenData(data),
      regionId: notificationRegionFromData(data),
    });
  }

  await runWithConcurrency(publicJobs, 12, async ({token, ref, platform, language, regionId}) => {
    const copy = greetingReminderVariant(reminderKind, language, now);
    try {
      const resolvedRegionId = normalizeRegionId(regionId);
      const imageUrl = await imageForRegion(resolvedRegionId);
      if (!imageUrl) {
        logger.info("public localized greeting reminder skipped: no poster", {
          tokenSuffix: String(token || "").slice(-12),
          categoryKey,
          reminderKind,
          regionId: resolvedRegionId,
        });
        return;
      }
      const reservation = await reserveNotificationDelivery({
        token,
        categoryKey,
        slotKey: `${categoryKey}-${reminderKind}`,
        dayKey,
      });
      if (!reservation.allowed) {
        logger.info("public localized greeting reminder skipped by frequency guard", {
          tokenSuffix: String(token || "").slice(-12),
          categoryKey,
          reminderKind,
          reason: reservation.reason,
        });
        return;
      }
      await sendReminderToToken({
        token,
        platform,
        title: copy.title,
        body: copy.body,
        imageUrl: imageUrl || null,
        posterBaseImageUrl: imageUrl || "",
        categoryKey,
        titleKey: `${reminderKind}_title`,
        bodyKey: `${reminderKind}_body`,
        languageCode: language,
      });
    } catch (error) {
      if (isMessagingTokenGoneError(error)) {
        await cleanupInvalidTokenRef(ref);
      }
      logger.error("public localized greeting reminder failed", {
        token,
        reminderKind,
        error: messagingErrorDetails(error),
      });
    }
  });
}

function daysUntilEvent(month, day, now = new Date()) {
  const year = now.getFullYear();
  const today = new Date(year, now.getMonth(), now.getDate());
  let eventDate = new Date(year, month - 1, day);
  if (eventDate < today) {
    eventDate = new Date(year + 1, month - 1, day);
  }
  const ms = eventDate.getTime() - today.getTime();
  return Math.floor(ms / (24 * 60 * 60 * 1000));
}

function normalizeEmail(value) {
  return String(value || "").trim().toLowerCase();
}

function isManualLifetimeWhitelistedEmail(email) {
  return manualLifetimeWhitelistedEmails.has(normalizeEmail(email));
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

function isAuthVerificationError(error) {
  const message = String(error && error.message ? error.message : error || "")
      .toLowerCase();
  const code = String(error && error.code ? error.code : "").toLowerCase();
  return message.includes("missing bearer token") ||
    message.includes("id token") ||
    message.includes("auth") ||
    message.includes("token expired") ||
    message.includes("token used too early") ||
    message.includes("unauthorized") ||
    code.includes("auth/");
}

function httpStatusForError(error) {
  if (isAuthVerificationError(error)) {
    return 401;
  }
  const directCode = Number(error && error.code);
  if (Number.isInteger(directCode) && directCode >= 400 && directCode < 600) {
    return directCode;
  }
  const nestedStatus = Number(
      error &&
      error.response &&
      error.response.status,
  );
  if (Number.isInteger(nestedStatus) && nestedStatus >= 400 && nestedStatus < 600) {
    return nestedStatus;
  }
  return 500;
}

function toMillis(value) {
  if (value === null || value === undefined) {
    return 0;
  }
  if (typeof value === "number" && Number.isFinite(value)) {
    return Math.trunc(value);
  }
  if (typeof value === "string") {
    const asNumber = Number(value);
    if (Number.isFinite(asNumber)) {
      return Math.trunc(asNumber);
    }
    const asDate = Date.parse(value);
    return Number.isFinite(asDate) ? asDate : 0;
  }
  if (value instanceof admin.firestore.Timestamp) {
    return value.toMillis();
  }
  if (typeof value.toMillis === "function") {
    try {
      return Number(value.toMillis()) || 0;
    } catch (_) {
      return 0;
    }
  }
  return 0;
}

function serializeApprovedCreatorPoster(doc) {
  const data = doc.data() || {};
  return {
    id: doc.id,
    title: String(data.title || "Creator Poster"),
    imageUrl: String(data.imageUrl || data.downloadUrl || data.publicUrl || ""),
    imagePath: String(data.imagePath || data.posterImagePath || data.storagePath || ""),
    thumbnailPath: String(data.thumbnailPath || data.posterThumbnailPath || data.thumbPath || ""),
    thumbnailUrl: String(data.thumbnailUrl || data.thumbUrl || data.previewUrl || ""),
    videoUrl: String(data.videoUrl || data.videoPreviewUrl || ""),
    mediaType: String(data.mediaType || data.type || ""),
    categoryId: String(data.categoryId || ""),
    categoryLabel: String(data.categoryLabel || ""),
    regionId: String(data.regionId || ""),
    creatorPublicId: String(data.creatorPublicId || ""),
    createdAt: toMillis(data.createdAt),
    widthPx: Number(data.widthPx) || null,
    heightPx: Number(data.heightPx) || null,
    personalizationConfig: data.personalizationConfig || data.personalization || null,
  };
}

async function queryApprovedCreatorPosters({regionId, categoryId, limit}) {
  const safeLimit = Math.max(1, Math.min(Number(limit) || 40, 120));
  const normalizedCategoryId = normalizeRegionId(categoryId);
  const lookupRegionIds = sharedContentRegionIdsFor(regionId || "telangana", normalizedCategoryId);
  const seen = new Set();
  const docs = [];
  const baseQuery = db.collection("creatorPosters").where("status", "==", "approved");
  if (normalizedCategoryId) {
    for (const lookupRegionId of lookupRegionIds) {
      const snap = await baseQuery
          .where("regionId", "==", lookupRegionId)
          .where("categoryId", "==", normalizedCategoryId)
          .orderBy("createdAt", "desc")
          .limit(safeLimit)
          .get();
      for (const doc of snap.docs) {
        if (!seen.has(doc.id)) {
          seen.add(doc.id);
          docs.push(doc);
        }
      }
    }
  } else {
    const snap = await applyRegionScope(baseQuery, lookupRegionIds)
        .orderBy("createdAt", "desc")
        .limit(safeLimit * 2)
        .get();
    for (const doc of snap.docs) {
      if (!seen.has(doc.id)) {
        seen.add(doc.id);
        docs.push(doc);
      }
    }
  }
  const nowMillis = Date.now();
  return docs
      .filter((doc) => posterIsCurrentlyVisible(doc.data(), nowMillis))
      .sort((left, right) => posterVisibleFromMillis(right.data()) - posterVisibleFromMillis(left.data()))
      .slice(0, safeLimit)
      .map(serializeApprovedCreatorPoster);
}

exports.appCreatorPostersFeed = onRequest({region: "asia-south1"}, async (req, res) => {
  setCors(req, res);
  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }
  if (req.method !== "POST") {
    res.status(405).json({ok: false, error: "Method not allowed."});
    return;
  }
  try {
    const body = req.body && typeof req.body === "object" ? req.body : {};
    const posters = await queryApprovedCreatorPosters({
      regionId: normalizeRegionId(body.regionId || "telangana"),
      categoryId: normalizeRegionId(body.categoryId || ""),
      limit: body.limit,
    });
    res.status(200).json({ok: true, posters});
  } catch (error) {
    logger.error("appCreatorPostersFeed failed", error);
    res.status(500).json({ok: false, error: "Unable to load posters."});
  }
});

function posterVisibleFromMillis(data) {
  const publishAt = toMillis(data.publishAt);
  if (publishAt > 0) {
    return publishAt;
  }
  return toMillis(data.createdAt);
}

function posterExpiryBaseMillis(data) {
  const status = String(data.status || "").trim().toLowerCase();
  if (status === "approved") {
    return posterVisibleFromMillis(data);
  }
  return toMillis(data.createdAt);
}

async function deletePosterStorageAssets(bucket, data) {
  const candidates = [
    String(data.imagePath || "").trim(),
    String(data.videoPath || "").trim(),
  ].filter((item) => item.length > 0);

  if (candidates.length === 0) {
    return;
  }

  await Promise.allSettled(candidates.map(async (path) => {
    try {
      await bucket.file(path).delete({ignoreNotFound: true});
    } catch (error) {
      logger.warn("Expired poster asset delete failed", {path, error});
    }
  }));
}

exports.referralStatus = onRequest({region: "asia-south1"}, async (req, res) => {
  setCors(req, res);
  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }
  if (req.method !== "POST") {
    res.status(405).json({message: "Method not allowed"});
    return;
  }

  try {
    const decoded = await verifyAuth(req);
    const uid = decoded.uid;
    const code = await ensureReferralCodeForUid(uid);
    const [summarySnap, entitlementSnap, sourceSnap] = await Promise.all([
      db.doc(`users/${uid}/referralRewards/summary`).get(),
      db.doc(`users/${uid}/entitlements/pro`).get(),
      db.doc(`users/${uid}/referral/source`).get(),
    ]);
    const summary = summarySnap.data() || {};
    const entitlement = entitlementSnap.data() || {};
    const source = sourceSnap.data() || {};
    const reward = referralRewardWindow(entitlement);

    res.status(200).json({
      code,
      link: buildReferralLink(code),
      requiredPaidReferrals: referralRewardConfig.requiredPaidReferrals,
      rewardDays: referralRewardConfig.rewardDays,
      currentCycleNumber: Math.max(
          1,
          Number(summary.currentCycleNumber || 1) || 1,
      ),
      currentCyclePaidCount: Math.max(
          0,
          Number(summary.currentCyclePaidCount || 0) || 0,
      ),
      totalPaidReferralCount: Math.max(
          0,
          Number(summary.totalPaidReferralCount || 0) || 0,
      ),
      rewardActive: reward.active,
      rewardStartsAt: reward.startsAt ? reward.startsAt.toISOString() : null,
      rewardExpiresAt: reward.expiresAt ? reward.expiresAt.toISOString() : null,
      appliedReferralStatus: source.status || null,
      appliedReferralCode: source.referralCode || null,
    });
  } catch (error) {
    logger.error("referralStatus error", error);
    res.status(httpStatusForError(error)).json({
      message: error instanceof Error ? error.message : "Unauthorized",
    });
  }
});

exports.applyReferralCode = onRequest({region: "asia-south1"}, async (req, res) => {
  setCors(req, res);
  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }
  if (req.method !== "POST") {
    res.status(405).json({accepted: false, message: "Method not allowed"});
    return;
  }

  try {
    const decoded = await verifyAuth(req);
    const uid = decoded.uid;
    const payload = req.body || {};
    const referralCode = normalizeReferralCode(payload.referralCode || payload.code);
    if (!referralCode) {
      res.status(400).json({accepted: false, message: "Referral code is required"});
      return;
    }

    const codeSnap = await db.collection(referralCollections.codes)
        .doc(referralCode)
        .get();
    if (!codeSnap.exists) {
      res.status(404).json({accepted: false, message: "Referral code not found"});
      return;
    }
    const referrerUid = String((codeSnap.data() || {}).uid || "").trim();
    if (!referrerUid || referrerUid === uid) {
      res.status(400).json({accepted: false, message: "Referral code cannot be used"});
      return;
    }

    const sourceRef = db.doc(`users/${uid}/referral/source`);
    const eventRef = db.collection(referralCollections.events).doc();
    let accepted = false;
    let message = "Referral already applied";
    await db.runTransaction(async (tx) => {
      const sourceSnap = await tx.get(sourceRef);
      if (sourceSnap.exists) {
        return;
      }
      const now = admin.firestore.FieldValue.serverTimestamp();
      tx.set(sourceRef, {
        referralCode,
        referrerUid,
        status: "pending_paid_subscription",
        appliedAt: now,
      });
      tx.set(eventRef, {
        type: "referral_code_applied",
        subscriberUid: uid,
        referrerUid,
        referralCode,
        createdAt: now,
      });
      accepted = true;
      message = "Referral applied";
    });

    res.status(200).json({accepted, message, referralCode});
  } catch (error) {
    logger.error("applyReferralCode error", error);
    res.status(httpStatusForError(error)).json({
      accepted: false,
      message: error instanceof Error ? error.message : "Unauthorized",
    });
  }
});

exports.claimFirst150Trial = onRequest({region: "asia-south1"}, async (req, res) => {
  setCors(req, res);
  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }
  if (req.method !== "POST") {
    res.status(405).json({claimed: false, message: "Method not allowed"});
    return;
  }

  try {
    const decoded = await verifyAuth(req);
    const uid = decoded.uid;
    const nowMillis = Date.now();
    const configRef = db.doc(first150TrialConfigPath);
    const configSnap = await configRef.get();
    const config = configSnap.data() || {};
    const startsAtMillis = toMillis(config.startsAt);
    const userRecord = await admin.auth().getUser(uid);
    if (!isEligibleFirst150NewUser(userRecord, nowMillis) ||
        !isEligibleForFirst150StartWindow(userRecord, startsAtMillis)) {
      res.status(200).json({
        claimed: false,
        alreadyClaimed: false,
        message: "User is not eligible for the first 150 trial offer",
      });
      return;
    }

    const entitlementRef = db.doc(`users/${uid}/entitlements/pro`);
    const eventRef = db.collection(`users/${uid}/purchaseEvents`).doc();
    const nowTimestamp = admin.firestore.Timestamp.fromMillis(nowMillis);
    let claimed = false;
    let alreadyClaimed = false;
    let expiryIso = null;
    let responseMessage = "Offer not available";

    await db.runTransaction(async (tx) => {
      const [freshConfigSnap, entitlementSnap] = await Promise.all([
        tx.get(configRef),
        tx.get(entitlementRef),
      ]);
      const config = freshConfigSnap.data() || {};
      const entitlement = entitlementSnap.data() || {};
      const freshStartsAtMillis = toMillis(config.startsAt);

      if (entitlement.first150Claimed === true ||
          String(entitlement.source || "").trim() === first150TrialSource) {
        alreadyClaimed = true;
        claimed = isFirst150TrialActive(entitlement);
        expiryIso = firestoreValueToIsoString(entitlement.expiryTime);
        responseMessage = "Trial already claimed";
        return;
      }
      if (
        entitlementSnap.exists &&
        (
          entitlement.isPro === true ||
          String(entitlement.productId || "").trim().length > 0 ||
          String(entitlement.source || "").trim().length > 0 ||
          String(entitlement.verificationTokenHash || "").trim().length > 0
        )
      ) {
        responseMessage = "Existing entitlement found";
        return;
      }

      const enabled = config.enabled === true;
      const limit = Math.max(0, Number(config.limit || 0) || 0);
      const usedCount = Math.max(0, Number(config.usedCount || 0) || 0);
      const days = Math.max(1, Number(config.days || 30) || 30);

      if (!enabled ||
          limit <= 0 ||
          usedCount >= limit ||
          !Number.isFinite(freshStartsAtMillis) ||
          freshStartsAtMillis <= 0 ||
          !isEligibleForFirst150StartWindow(userRecord, freshStartsAtMillis)) {
        responseMessage = enabled ? "Offer limit reached" : "Offer disabled";
        return;
      }

      const expiryMillis = nowMillis + (days * 24 * 60 * 60 * 1000);
      const expiryTimestamp = admin.firestore.Timestamp.fromMillis(expiryMillis);

      tx.set(configRef, {
        usedCount: admin.firestore.FieldValue.increment(1),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, {merge: true});

      tx.set(entitlementRef, {
        isPro: true,
        status: "active",
        productId: first150TrialProductId,
        source: first150TrialSource,
        subscriptionState: first150TrialState,
        first150Claimed: true,
        isPremiumTrial: true,
        startTime: nowTimestamp,
        expiryTime: expiryTimestamp,
        autoRenewing: false,
        latestOrderId: null,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        lastSyncedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, {merge: true});

      tx.set(eventRef, {
        type: "first150_trial_claimed",
        productId: first150TrialProductId,
        source: first150TrialSource,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        expiryTime: expiryTimestamp,
        days,
      });

      claimed = true;
      expiryIso = expiryTimestamp.toDate().toISOString();
      responseMessage = "First 150 premium trial granted";
    });

    res.status(200).json({
      claimed,
      alreadyClaimed,
      isPro: claimed,
      message: responseMessage,
      expiryTime: expiryIso,
    });
  } catch (error) {
    logger.error("claimFirst150Trial error", error);
    res.status(httpStatusForError(error)).json({
      claimed: false,
      message: error instanceof Error ? error.message : "Unauthorized",
    });
  }
});

exports.verifySubscription = onRequest({region: "asia-south1"}, async (req, res) => {
  setCors(req, res);
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
    const requestedScope = requestedSubscriptionScope(payload);
    if (!token) {
      res.status(400).json({isPro: false, message: "Purchase token is required"});
      return;
    }

    logger.info("verifySubscription request received", {
      uid,
      productId: productId || null,
      purchaseStatus: purchaseStatus || null,
      platform: platform || null,
      tokenHash: sha256(token),
    });

    const verification = await verifySubscriptionPurchaseWithGoogle({
      purchaseToken: token,
    });
    const isValid = verification.valid &&
        (!productId || verification.productIds.includes(productId)) &&
        (purchaseStatus === "purchased" ||
          purchaseStatus === "restored" ||
          purchaseStatus.length === 0);
    const access = subscriptionAccessScopesForPlan({
      productId: verification.primaryProductId || productId,
      basePlanId: verification.basePlanId,
      valid: isValid,
    });
    const scopeIsPro = isAccessActiveForScope(access, requestedScope);
    const tokenHash = sha256(token);

    await assertPurchaseTokenOwnership({
      tokenHash,
      uid,
      kind: "subscription",
      metadata: {
        productId: verification.primaryProductId || productId || null,
        platform: platform || null,
      },
    });

    const entitlementRef = db.doc(`users/${uid}/entitlements/pro`);
    const eventRef = db.collection(`users/${uid}/purchaseEvents`).doc();
    const now = admin.firestore.FieldValue.serverTimestamp();
    const linkedPurchaseTokenHash = verification.linkedPurchaseToken ?
      sha256(verification.linkedPurchaseToken) :
      null;
    const entitlementStatus = deriveEntitlementStatus({
      isPro: isValid,
      subscriptionState: verification.subscriptionState,
      expiryTime: verification.expiryTime,
    });

    await db.runTransaction(async (tx) => {
      tx.set(
        entitlementRef,
        {
          isPro: isValid,
          appAccess: access.appAccess,
          editorAccess: access.editorAccess,
          accessScope: access.accessScope,
          productId: verification.primaryProductId || productId || null,
          basePlanId: verification.basePlanId || null,
          source: source || null,
          platform: platform || null,
          verificationTokenHash: tokenHash,
          lastTransactionId: transactionId || null,
          lastTransactionDate: transactionDate || null,
          linkedPurchaseTokenHash,
          subscriptionState: verification.subscriptionState || null,
          ...buildSubscriptionMetadataPatch(verification),
          updatedAt: now,
          status: entitlementStatus,
          ackPending: false,
        },
        {merge: true},
      );

      tx.set(eventRef, {
        type: "verify",
        isPro: isValid,
        appAccess: access.appAccess,
        editorAccess: access.editorAccess,
        accessScope: access.accessScope,
        productId: verification.primaryProductId || productId || null,
        basePlanId: verification.basePlanId || null,
        source: source || null,
        platform: platform || null,
        localVerificationData: localVerificationData || null,
        transactionId: transactionId || null,
        transactionDate: transactionDate || null,
        purchaseStatus: purchaseStatus || null,
        verificationTokenHash: tokenHash,
        subscriptionState: verification.subscriptionState || null,
        expiryTime: verification.expiryTime || null,
        autoRenewing: verification.autoRenewing === true,
        latestOrderId: verification.latestOrderId || null,
        createdAt: now,
      });
    });

    await upsertServerSubscriptionToken({
      uid,
      token,
      tokenHash,
      productId: verification.primaryProductId || productId || null,
      basePlanId: verification.basePlanId || null,
      platform,
      source,
      linkedPurchaseTokenHash,
      ackPending: false,
      ackAttempts: 0,
    });

    let referralReward = null;
    if (isValid && access.appAccess) {
      try {
        referralReward = await recordPaidReferralForSubscriber({
          subscriberUid: uid,
          productId: verification.primaryProductId || productId || null,
          tokenHash,
          latestOrderId: verification.latestOrderId || transactionId || null,
          purchaseStartTime: verification.startTime || transactionDate || null,
        });
      } catch (error) {
        logger.warn("Paid referral count skipped", {
          uid,
          tokenHash,
          error: error instanceof Error ? error.message : String(error),
        });
      }
    }

    if (verification.linkedPurchaseToken) {
      const previousTokenHash = sha256(verification.linkedPurchaseToken);
      const linkedTokenRef = db.collection(subscriptionCollections.tokenOwnership)
          .doc(previousTokenHash);
      const linkedTokenSnap = await linkedTokenRef.get();
      if (linkedTokenSnap.exists) {
        const previousUid = String((linkedTokenSnap.data() || {}).uid || "").trim();
        if (previousUid && previousUid !== uid) {
          await db.doc(`users/${previousUid}/entitlements/pro`).set({
            isPro: false,
            status: "replaced",
            replacedByUid: uid,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          }, {merge: true});
        }
      }
    }

    let ackSucceeded = true;
    if (isValid) {
      ackSucceeded = await acknowledgeSubscriptionPurchase({
        purchaseToken: token,
        subscriptionId: verification.primaryProductId,
      });
      if (!ackSucceeded) {
        await entitlementRef.set({
          ackPending: true,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, {merge: true});
        await serverSubscriptionTokenRef(tokenHash).set({
          ackPending: true,
          ackAttempts: admin.firestore.FieldValue.increment(1),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, {merge: true});
      }
    }

    logger.info("verifySubscription completed", {
      uid,
      isValid,
      appAccess: access.appAccess,
      editorAccess: access.editorAccess,
      productId: verification.primaryProductId || productId || null,
      basePlanId: verification.basePlanId || null,
      subscriptionState: verification.subscriptionState || null,
    });

    res.status(200).json({
      isPro: scopeIsPro,
      appAccess: access.appAccess,
      editorAccess: access.editorAccess,
      accessScope: access.accessScope,
      message: scopeIsPro ? "Verification success" : "Verification failed",
      status: entitlementStatus,
      productId: verification.primaryProductId || productId || null,
      basePlanId: verification.basePlanId || null,
      subscriptionState: verification.subscriptionState || null,
      startDate: verification.startTime || null,
      expiryTime: verification.expiryTime || null,
      autoRenewing: verification.autoRenewing === true,
      latestOrderId: verification.latestOrderId || null,
      lastSyncedAt: new Date().toISOString(),
      ackPending: !ackSucceeded,
      referralReward,
    });
  } catch (error) {
    logger.error("verifySubscription error", error);
    res.status(httpStatusForError(error)).json({
      isPro: false,
      message: error instanceof Error ? error.message : "Unauthorized",
    });
  }
});

exports.subscriptionStatus = onRequest({region: "asia-south1"}, async (req, res) => {
  setCors(req, res);
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
    const email = normalizeEmail(decoded.email);

    if (isManualLifetimeWhitelistedEmail(email)) {
      logger.info("subscriptionStatus manual whitelist override", {
        uid,
        source: manualLifetimeWhitelistSource,
        emailHash: sha256(email).slice(0, 12),
      });
      const entitlementRef = db.doc(`users/${uid}/entitlements/pro`);
      await entitlementRef.set({
        isPro: true,
        status: "active",
        source: manualLifetimeWhitelistSource,
        productId: "manual_lifetime_whitelist",
        subscriptionState: manualLifetimeWhitelistSource,
        autoRenewing: false,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, {merge: true});
      res.status(200).json({
        isPro: true,
        hasAccess: true,
        message: "Entitlement active",
        status: "active",
        source: manualLifetimeWhitelistSource,
        productId: "manual_lifetime_whitelist",
        subscriptionState: manualLifetimeWhitelistSource,
        startDate: null,
        expiryTime: null,
        autoRenewing: false,
        latestOrderId: null,
        referralRewardActive: false,
        referralRewardStartsAt: null,
        referralRewardExpiresAt: null,
        lastSyncedAt: new Date().toISOString(),
      });
      return;
    }

    const entitlementRef = db.doc(`users/${uid}/entitlements/pro`);
    const snap = await entitlementRef.get();
    const data = snap.data() || {};
    const requestedScope = requestedSubscriptionScope(req.body || {});
    const reward = referralRewardWindow(data);
    const aggregate = await aggregateSubscriptionAccessForUser({
      uid,
      entitlementRef,
      entitlementData: data,
    });
    let appAccess = aggregate.appAccess;
    let editorAccess = aggregate.editorAccess;
    let status = aggregate.status || data.status || "inactive";
    let productId = aggregate.productId || data.productId || null;
    let basePlanId = aggregate.basePlanId || data.basePlanId || null;
    let subscriptionState = aggregate.subscriptionState || data.subscriptionState || null;
    let startTime = aggregate.startTime || data.startTime || null;
    let expiryTime = aggregate.expiryTime || data.expiryTime || null;
    let autoRenewing = aggregate.autoRenewing ?? data.autoRenewing ?? null;
    let latestOrderId = aggregate.latestOrderId || data.latestOrderId || null;
    if (!aggregate.isPro && String(data.source || "") === first150TrialSource) {
      const first150Active = isFirst150TrialActive(data);
      appAccess = first150Active;
      editorAccess = false;
      status = deriveEntitlementStatus({
        isPro: first150Active,
        subscriptionState: data.subscriptionState || first150TrialState,
        expiryTime,
      });
      productId = data.productId || first150TrialProductId;
      subscriptionState = data.subscriptionState || first150TrialState;
      autoRenewing = false;
    }
    if (!appAccess && reward.active) {
      appAccess = true;
      status = "active";
      productId = productId || "referral_reward";
      subscriptionState = subscriptionState || "REFERRAL_REWARD";
      startTime = reward.startsAt || startTime;
      expiryTime = reward.expiresAt || expiryTime;
      autoRenewing = false;
    }
    const isPro = isAccessActiveForScope({appAccess, editorAccess}, requestedScope);

    if (
      isPro !== (data.isPro === true) ||
      appAccess !== (data.appAccess === true) ||
      editorAccess !== (data.editorAccess === true) ||
      status !== (data.status || null) ||
      reward.active !== (data.referralRewardActive === true)
    ) {
      await entitlementRef.set({
        isPro: appAccess || editorAccess,
        appAccess,
        editorAccess,
        status,
        productId,
        basePlanId,
        subscriptionState,
        startTime,
        expiryTime,
        autoRenewing: autoRenewing === true,
        latestOrderId: latestOrderId || null,
        referralRewardActive: reward.active,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, {merge: true});
    }

    res.status(200).json({
      isPro,
      appAccess,
      editorAccess,
      message: isPro ? "Entitlement active" : "Entitlement inactive",
      status,
      productId,
      basePlanId,
      subscriptionState,
      startDate: firestoreValueToIsoString(startTime),
      expiryTime: firestoreValueToIsoString(expiryTime),
      autoRenewing: autoRenewing === true,
      latestOrderId: latestOrderId || null,
      referralRewardActive: reward.active,
      referralRewardStartsAt: reward.startsAt ? reward.startsAt.toISOString() : null,
      referralRewardExpiresAt: reward.expiresAt ? reward.expiresAt.toISOString() : null,
      lastSyncedAt: new Date().toISOString(),
    });
  } catch (error) {
    logger.error("subscriptionStatus error", error);
    res.status(httpStatusForError(error)).json({
      isPro: false,
      message: error instanceof Error ? error.message : "Unauthorized",
    });
  }
});

async function syncSubscriptionEntitlementFromToken({
  uid,
  purchaseToken,
  trigger,
  productIdHint = "",
}) {
  const tokenHash = sha256(purchaseToken);
  await assertPurchaseTokenOwnership({
    tokenHash,
    uid,
    kind: "subscription",
    metadata: {
      productId: productIdHint || null,
      trigger,
      source: "internal_sync",
    },
  });
  const verification = await verifySubscriptionPurchaseWithGoogle({
    purchaseToken,
  });
  const isPro = verification.valid &&
    (!productIdHint || verification.productIds.includes(productIdHint));
  const access = subscriptionAccessScopesForPlan({
    productId: verification.primaryProductId || productIdHint,
    basePlanId: verification.basePlanId,
    valid: isPro,
  });
  const entitlementRef = db.doc(`users/${uid}/entitlements/pro`);
  const linkedPurchaseTokenHash = verification.linkedPurchaseToken ?
    sha256(verification.linkedPurchaseToken) :
    null;
  await entitlementRef.set({
    isPro: access.appAccess || access.editorAccess,
    appAccess: access.appAccess,
    editorAccess: access.editorAccess,
    accessScope: access.accessScope,
    status: isPro ? "active" : "inactive",
    productId: verification.primaryProductId || productIdHint || null,
    basePlanId: verification.basePlanId || null,
    subscriptionState: verification.subscriptionState || null,
    verificationTokenHash: tokenHash,
    linkedPurchaseTokenHash,
    ...buildSubscriptionMetadataPatch(verification),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, {merge: true});
  await upsertServerSubscriptionToken({
    uid,
    token: purchaseToken,
    tokenHash,
    productId: verification.primaryProductId || productIdHint || null,
    basePlanId: verification.basePlanId || null,
    linkedPurchaseTokenHash,
    ackPending: false,
  });
  await db.collection(`users/${uid}/purchaseEvents`).add({
    type: "subscription_sync",
    trigger,
    isPro,
    appAccess: access.appAccess,
    editorAccess: access.editorAccess,
    accessScope: access.accessScope,
    productId: verification.primaryProductId || productIdHint || null,
    basePlanId: verification.basePlanId || null,
    verificationTokenHash: tokenHash,
    subscriptionState: verification.subscriptionState || null,
    expiryTime: verification.expiryTime || null,
    autoRenewing: verification.autoRenewing === true,
    latestOrderId: verification.latestOrderId || null,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  return {isPro, access, verification, tokenHash};
}

exports.verifyTemplatePurchase = onRequest({region: "asia-south1"}, async (req, res) => {
  setCors(req, res);
  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }
  if (req.method !== "POST") {
    res.status(405).json({success: false, message: "Method not allowed"});
    return;
  }

  try {
    const decoded = await verifyAuth(req);
    const payload = req.body || {};
    const uid = decoded.uid;
    const templateId = String(payload.templateId || "").trim();
    const productId = String(payload.productId || "").trim();
    const purchaseToken = String(payload.serverVerificationData || "").trim();
    const source = String(payload.verificationSource || "").trim();
    const purchaseStatus = String(payload.purchaseStatus || "").trim();
    const transactionId = String(payload.transactionId || "").trim();
    const transactionDate = String(payload.transactionDate || "").trim();
    const platform = String(payload.platform || "").trim();

    if (!templateId || !productId || !purchaseToken) {
      res.status(400).json({
        success: false,
        message: "templateId, productId, and purchase token are required",
      });
      return;
    }

    const verification = await verifyOneTimeProductPurchaseWithGoogle({
      productId,
      purchaseToken,
    });
    const isValid = verification.valid &&
        (purchaseStatus === "purchased" ||
          purchaseStatus === "restored" ||
          purchaseStatus.length === 0);
    const tokenHash = sha256(purchaseToken);

    await assertPurchaseTokenOwnership({
      tokenHash,
      uid,
      kind: "template",
      metadata: {
        productId,
        templateId,
        platform: platform || null,
      },
    });

    const templateRef = db.doc(`users/${uid}/templateEntitlements/${templateId}`);
    const eventRef = db.collection(`users/${uid}/purchaseEvents`).doc();
    const now = admin.firestore.FieldValue.serverTimestamp();

    await db.runTransaction(async (tx) => {
      tx.set(templateRef, {
        templateId,
        productId,
        isActive: isValid,
        source: source || null,
        platform: platform || null,
        verificationTokenHash: tokenHash,
        transactionId: transactionId || null,
        transactionDate: transactionDate || null,
        purchaseStatus: purchaseStatus || null,
        updatedAt: now,
      }, {merge: true});
      tx.set(eventRef, {
        type: "template_verify",
        templateId,
        productId,
        isActive: isValid,
        verificationTokenHash: tokenHash,
        transactionId: transactionId || null,
        transactionDate: transactionDate || null,
        purchaseStatus: purchaseStatus || null,
        createdAt: now,
      });
    });

    if (isValid) {
      await acknowledgeOneTimeProductPurchase({productId, purchaseToken});
    }

    const unlockedTemplateIds = isValid ? [templateId] : [];
    res.status(200).json({
      success: isValid,
      message: isValid ? "Template verification success" : "Template verification failed",
      unlockedTemplateIds,
      templateIds: unlockedTemplateIds,
    });
  } catch (error) {
    logger.error("verifyTemplatePurchase error", error);
    res.status(401).json({
      success: false,
      message: error instanceof Error ? error.message : "Unauthorized",
    });
  }
});

exports.templateEntitlementStatus = onRequest({region: "asia-south1"}, async (req, res) => {
  setCors(req, res);
  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }
  if (req.method !== "POST") {
    res.status(405).json({success: false, message: "Method not allowed"});
    return;
  }

  try {
    const decoded = await verifyAuth(req);
    const uid = decoded.uid;
    const snap = await db.collection(`users/${uid}/templateEntitlements`)
        .where("isActive", "==", true)
        .get();
    const unlockedTemplateIds = snap.docs
        .map((doc) => String((doc.data() || {}).templateId || doc.id).trim())
        .filter((item) => item.length > 0);
    res.status(200).json({
      success: true,
      unlockedTemplateIds,
      templateIds: unlockedTemplateIds,
      message: unlockedTemplateIds.length > 0 ?
        "Template entitlements found" :
        "No active template entitlements",
    });
  } catch (error) {
    logger.error("templateEntitlementStatus error", error);
    res.status(401).json({
      success: false,
      message: error instanceof Error ? error.message : "Unauthorized",
    });
  }
});

exports.requestAccountDeletion = onRequest({region: "asia-south1"}, async (req, res) => {
  setCors(req, res);
  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }
  if (req.method !== "POST") {
    res.status(405).json({success: false, message: "Method not allowed"});
    return;
  }

  try {
    const decoded = await verifyAuth(req);
    const uid = decoded.uid;
    const email = String(decoded.email || req.body?.email || "").trim();
    const now = admin.firestore.FieldValue.serverTimestamp();

    await db.collection("deletionRequests").doc(uid).set({
      uid,
      email: email || null,
      source: "in_app",
      status: "completed",
      requestedAt: now,
      completedAt: now,
    }, {merge: true});

    const userRef = db.collection("users").doc(uid);
    await db.recursiveDelete(userRef);

    const uploadsQuery = await db.collection("userPosterUploads")
        .where("userId", "==", uid)
        .get();
    if (!uploadsQuery.empty) {
      const bulkWriter = db.bulkWriter();
      uploadsQuery.docs.forEach((doc) => {
        bulkWriter.delete(doc.ref);
      });
      await bulkWriter.close();
    }

    const bucket = admin.storage().bucket();
    await Promise.allSettled([
      bucket.deleteFiles({prefix: `users/${uid}/poster_profile/`}),
      bucket.deleteFiles({prefix: `users/${uid}/rembg_jobs/`}),
      bucket.deleteFiles({prefix: `users/${uid}/community_uploads/`}),
    ]);

    await admin.auth().deleteUser(uid);

    res.status(200).json({
      success: true,
      message: "Account deletion completed",
    });
  } catch (error) {
    logger.error("requestAccountDeletion error", error);
    res.status(500).json({
      success: false,
      message: error instanceof Error ? error.message : "Account deletion failed",
    });
  }
});

exports.reminderToolSendTriple = onRequest(
    {
      region: "asia-south1",
      memory: "1GiB",
      timeoutSeconds: 300,
    },
    async (req, res) => {
      if (!manaReminderToolKey) {
        res.status(503).json({success: false, message: "Tool disabled"});
        return;
      }
      if (req.method !== "POST") {
        res.status(405).json({success: false, message: "Method not allowed"});
        return;
      }
      const keyHeader = String(req.get("x-mana-reminder-tool-key") || "").trim();
      if (keyHeader !== manaReminderToolKey) {
        res.status(404).json({success: false, message: "Not found"});
        return;
      }
      try {
        const rawBody = typeof req.body === "string" ?
            JSON.parse(String(req.body || "{}")) :
            req.body || {};
        const fcmTok = String(rawBody.token || "").trim();
        const uidParam = String(rawBody.uid || "").trim();
        if (!fcmTok || !uidParam) {
          res.status(400).json({success: false, message: "token and uid required"});
          return;
        }
        const results = await sendThreeKindsToFcmToken(fcmTok, uidParam);
        res.status(200).json({success: true, results});
      } catch (error) {
        logger.error("reminderToolSendTriple failed", error);
        res.status(500).json({
          success: false,
          message: error instanceof Error ? error.message : String(error),
        });
      }
    },
);

exports.processWelcomeNotifications = onSchedule(
    {
      region: "asia-south1",
      schedule: "every 15 minutes",
      timeZone: "Asia/Kolkata",
      memory: "512MiB",
      timeoutSeconds: 180,
    },
    async () => {
      // Process public pre-login tokens.
      const publicSnap = await db
          .collection("publicDeviceTokens")
          .limit(40)
          .get();

      for (const doc of publicSnap.docs) {
        const data = doc.data() || {};
        if (data.welcomeSent === true) {
          continue;
        }
        const token = String(data.token || "").trim();
        if (!token) {
          continue;
        }
        try {
          await sendWelcomeToToken(
              token,
              String(data.platform || "").trim(),
              notificationLanguageFromTokenData(data),
          );
          await doc.ref.set({
            welcomeSent: true,
            welcomeSentAt: admin.firestore.FieldValue.serverTimestamp(),
          }, {merge: true});
        } catch (error) {
          if (isMessagingTokenGoneError(error)) {
            await cleanupInvalidTokenRef(doc.ref);
            continue;
          }
          logger.error("public welcome send failed", {
            token,
            error: messagingErrorDetails(error),
          });
        }
      }

      // Process logged-in user tokens.
      const userTokenSnap = await db
          .collectionGroup("deviceTokens")
          .where("welcomeSent", "==", false)
          .limit(60)
          .get();

      for (const doc of userTokenSnap.docs) {
        const data = doc.data() || {};
        const token = String(data.token || "").trim();
        if (!token) {
          continue;
        }
        try {
          const userRef = doc.ref.parent && doc.ref.parent.parent;
          const uid = userRef ? userRef.id : "";
          const profile = await loadNotificationProfileForUid(uid);
          const resolvedLanguage = notificationLanguageFromTokenData(
              data,
              profile.preferredLanguage,
          );
          const copy = reminderCopyLocalized(
              "welcome",
              resolvedLanguage,
              profile.name,
          );
          await sendPersonalizedWelcomeToToken({
            token,
            platform: String(data.platform || "").trim(),
            userName: profile.name,
            userPhotoUrl: profile.photoUrl,
            seed: `${uid}-${token}-welcome`,
            title: copy.title,
            body: copy.body,
            headerText: copy.header,
            footerText: copy.footer,
            language: resolvedLanguage,
          });
          await doc.ref.set({
            welcomeSent: true,
            welcomeSentAt: admin.firestore.FieldValue.serverTimestamp(),
          }, {merge: true});
        } catch (error) {
          if (isMessagingTokenGoneError(error)) {
            await cleanupInvalidTokenRef(doc.ref);
            continue;
          }
          logger.error("user welcome send failed", {
            uid,
            token,
            error: messagingErrorDetails(error),
          });
        }
      }
    },
);

exports.dailyGoodMorningReminder0730 = onSchedule(
    {
      region: "asia-south1",
      schedule: "30 7 * * *",
      timeZone: "Asia/Kolkata",
      memory: "1GiB",
      timeoutSeconds: 300,
    },
    async () => {
      await sendDailyPersonalizedReminder({
        keywords: [
        "good morning",
        "morning",
        "suprabhatam",
        ],
        categoryKey: "morning",
        reminderSeed: "0730",
      });
    },
);

exports.dailyGoodMorningReminder0930 = onSchedule(
    {
      region: "asia-south1",
      schedule: "30 9 * * *",
      timeZone: "Asia/Kolkata",
      memory: "1GiB",
      timeoutSeconds: 300,
    },
    async () => {
      await sendDailyPersonalizedReminder({
        keywords: [
        "good morning",
        "morning",
        "suprabhatam",
        ],
        categoryKey: "morning",
        reminderSeed: "0930",
      });
    },
);

exports.dailyGoodAfternoonReminder1200 = onSchedule(
    {
      region: "asia-south1",
      schedule: "0 12 * * *",
      timeZone: "Asia/Kolkata",
      memory: "1GiB",
      timeoutSeconds: 300,
    },
    async () => {
      await sendDailyPersonalizedReminder({
        keywords: [
        "good afternoon",
        "afternoon",
        ],
        categoryKey: "afternoon",
        reminderSeed: "1200",
      });
    },
);

exports.dailyGoodAfternoonReminder1300 = onSchedule(
    {
      region: "asia-south1",
      schedule: "0 13 * * *",
      timeZone: "Asia/Kolkata",
      memory: "1GiB",
      timeoutSeconds: 300,
    },
    async () => {
      await sendDailyPersonalizedReminder({
        keywords: [
        "good afternoon",
        "afternoon",
        ],
        categoryKey: "afternoon",
        reminderSeed: "1300",
      });
    },
);

exports.dailyMotivationReminder1130 = onSchedule(
    {
      region: "asia-south1",
      schedule: "30 11 * * *",
      timeZone: "Asia/Kolkata",
      memory: "1GiB",
      timeoutSeconds: 300,
    },
    async () => {
      await sendDailyPersonalizedReminder({
        keywords: [
          "motivational",
          "motivation",
          "good thoughts",
          "life advice",
          "inspiration",
        ],
        categoryKey: "motivation",
        reminderSeed: "1130",
      });
    },
);

exports.dailyGoodNightReminder2030 = onSchedule(
    {
      region: "asia-south1",
      schedule: "30 20 * * *",
      timeZone: "Asia/Kolkata",
      memory: "1GiB",
      timeoutSeconds: 300,
    },
    async () => {
      await sendDailyPersonalizedReminder({
        keywords: [
        "good night",
        "night",
        ],
        categoryKey: "night",
        reminderSeed: "2030",
      });
    },
);

exports.dailyJokesReminder1630 = onSchedule(
    {
      region: "asia-south1",
      schedule: "0 18 * * *",
      timeZone: "Asia/Kolkata",
      memory: "1GiB",
      timeoutSeconds: 300,
    },
    async () => {
      await sendDailyPersonalizedReminder({
        keywords: [
          "jokes",
          "funny",
          "humor",
          "comedy",
        ],
        categoryKey: "jokes",
        reminderSeed: "1800",
      });
    },
);

exports.dailyReligionReminder0815 = onSchedule(
    {
      region: "asia-south1",
      schedule: "15 8 * * *",
      timeZone: "Asia/Kolkata",
      memory: "1GiB",
      timeoutSeconds: 300,
    },
    async () => {
      const now = new Date();
      const targets = ["hindu", "muslim", "christian"]
          .map((religion) => religionDailyTarget(religion, now))
          .filter(Boolean);
      for (const target of targets) {
        await sendDailyPersonalizedReminder({
          keywords: [target.categoryKey, target.label],
          categoryKey: target.categoryKey,
          reminderSeed: `religion-${target.religion}`,
          targetReligion: target.religion,
          displayLabel: target.label,
        });
      }
    },
);

exports.dailyDynamicEventReminder = onSchedule(
    {
      region: "asia-south1",
      memory: "1GiB",
      schedule: "30 7 * * *",
      timeZone: "Asia/Kolkata",
    },
    async () => {
      const now = new Date();
      const matchingEvents = dynamicEventCatalog.filter((event) => {
        const delta = daysUntilEvent(event.month, event.day, now);
        return delta === 1 || delta === 0;
      });

      if (matchingEvents.length === 0) {
        return;
      }

      for (const event of matchingEvents) {
        const key = `${now.getFullYear()}-${event.id}-${now.getMonth() + 1}-${now.getDate()}`;
        const sentRef = db.collection("notificationJobs").doc("dynamicEventReminders")
            .collection("sent").doc(key);
        const exists = await sentRef.get();
        if (exists.exists) {
          continue;
        }

        const eventTimingLabel = daysUntilEvent(event.month, event.day, now) === 1 ?
          "repu" :
          "ee roju";
        const eventTiming = daysUntilEvent(event.month, event.day, now) === 1 ?
          "tomorrow" :
          "today";

        await sendDirectReminderToEligibleTokens({
          categoryKey: "dynamic_event",
          title: `${event.title} reminder`,
          body: `${event.title} ${eventTimingLabel} undi. Related poster ni share cheyyandi.`,
          eventTitle: event.title,
          eventTiming,
          eventKeywords: event.keywords || [event.title],
          dynamicEvent: event,
        });

        await sentRef.set({
          eventId: event.id,
          eventTitle: event.title,
          sentAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }
    },
);

exports.cleanupExpiredCreatorPosters = onSchedule(
    {
      region: "asia-south1",
      schedule: "15 2 * * *",
      timeZone: "Asia/Kolkata",
    },
    async () => {
      const bucket = admin.storage().bucket();
      const now = Date.now();
      let deletedCount = 0;
      let scannedCount = 0;
      let lastDoc = null;

      while (true) {
        let query = db
            .collection("creatorPosters")
            .orderBy("createdAt", "asc")
            .limit(posterCleanupBatchSize);
        if (lastDoc) {
          query = query.startAfter(lastDoc);
        }

        const snapshot = await query.get();
        if (snapshot.empty) {
          break;
        }

        const expiredDocs = [];
        for (const doc of snapshot.docs) {
          scannedCount += 1;
          const data = doc.data() || {};
          const expiryBase = posterExpiryBaseMillis(data);
          if (!expiryBase) {
            continue;
          }
          if (expiryBase + posterRetentionWindowMillis <= now) {
            expiredDocs.push({doc, data});
          }
        }

        for (const item of expiredDocs) {
          await deletePosterStorageAssets(bucket, item.data);
        }

        if (expiredDocs.length > 0) {
          const batch = db.batch();
          for (const item of expiredDocs) {
            batch.delete(item.doc.ref);
          }
          await batch.commit();
          deletedCount += expiredDocs.length;
        }

        lastDoc = snapshot.docs[snapshot.docs.length - 1];
        if (snapshot.docs.length < posterCleanupBatchSize) {
          break;
        }
      }

      logger.info("cleanupExpiredCreatorPosters completed", {
        scannedCount,
        deletedCount,
      });
    },
);

exports.cleanupExpiredCommunityStatuses = onSchedule(
    {
      region: "asia-south1",
      schedule: "every 60 minutes",
      timeZone: "Asia/Kolkata",
      timeoutSeconds: 300,
      memory: "256MiB",
    },
    async () => {
      async function deleteCommunityStatusComments(statusRef) {
        let deletedCount = 0;
        while (true) {
          const commentsSnap = await statusRef
              .collection("comments")
              .limit(200)
              .get();
          if (commentsSnap.empty) {
            break;
          }
          const commentsBatch = db.batch();
          for (const commentDoc of commentsSnap.docs) {
            commentsBatch.delete(commentDoc.ref);
          }
          await commentsBatch.commit();
          deletedCount += commentsSnap.size;
          if (commentsSnap.size < 200) {
            break;
          }
        }
        return deletedCount;
      }

      const now = Date.now();
      const snapshot = await db
          .collection("communityStatuses")
          .where("expiresAt", "<=", now)
          .limit(200)
          .get();

      if (snapshot.empty) {
        logger.info("cleanupExpiredCommunityStatuses completed", {
          deletedCount: 0,
          imageDeleteCount: 0,
        });
        return;
      }

      const imagePaths = [];
      let commentDeleteCount = 0;
      const batch = db.batch();
      for (const doc of snapshot.docs) {
        const data = doc.data() || {};
        const imagePath = String(data.imagePath || "").trim();
        if (imagePath) {
          imagePaths.push(imagePath);
        }
        commentDeleteCount += await deleteCommunityStatusComments(doc.ref);
        batch.delete(doc.ref);
      }
      await batch.commit();

      const bucket = admin.storage().bucket();
      await Promise.all(imagePaths.map(async (imagePath) => {
        try {
          await bucket.file(imagePath).delete({ignoreNotFound: true});
        } catch (error) {
          logger.warn("Community status image cleanup failed", {
            imagePath,
            error: error.message || error,
          });
        }
      }));

      logger.info("cleanupExpiredCommunityStatuses completed", {
        deletedCount: snapshot.size,
        commentDeleteCount,
        imageDeleteCount: imagePaths.length,
      });
    },
);

exports.retryPendingSubscriptionAcknowledgements = onSchedule(
    {
      region: "asia-south1",
      schedule: "every 30 minutes",
      timeZone: "Asia/Kolkata",
      memory: "512MiB",
    },
    async () => {
      const pendingSnap = await db.collection(subscriptionCollections.serverTokens)
          .where("kind", "==", "subscription")
          .where("ackPending", "==", true)
          .limit(50)
          .get();
      if (pendingSnap.empty) {
        return;
      }

      for (const doc of pendingSnap.docs) {
        const data = doc.data() || {};
        const purchaseToken = String(data.token || "").trim();
        const subscriptionId = String(data.productId || "").trim();
        if (!purchaseToken || !subscriptionId) {
          await doc.ref.set({
            ackPending: false,
            ackFailedReason: "missing-token-or-product",
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          }, {merge: true});
          continue;
        }

        const ackSucceeded = await acknowledgeSubscriptionPurchase({
          purchaseToken,
          subscriptionId,
        });
        const uid = String(data.uid || "").trim();
        if (ackSucceeded) {
          await doc.ref.set({
            ackPending: false,
            ackFailedReason: admin.firestore.FieldValue.delete(),
            acknowledgedAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          }, {merge: true});
          if (uid) {
            await db.doc(`users/${uid}/entitlements/pro`).set({
              ackPending: false,
              updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            }, {merge: true});
          }
          continue;
        }

        await doc.ref.set({
          ackPending: true,
          ackAttempts: admin.firestore.FieldValue.increment(1),
          ackFailedReason: "acknowledge-failed",
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, {merge: true});
      }
    },
);

exports.handlePlayBillingRtdn = onMessagePublished(
    {
      region: "asia-south1",
      topic: playRtdnTopic,
      memory: "512MiB",
    },
    async (event) => {
      const rawData = event.data && event.data.message ? event.data.message.data : null;
      if (!rawData) {
        logger.warn("handlePlayBillingRtdn missing message data");
        return;
      }

      const payload = JSON.parse(Buffer.from(rawData, "base64").toString("utf8"));
      const notification = payload.subscriptionNotification || {};
      const purchaseToken = String(notification.purchaseToken || "").trim();
      const productId = String(notification.subscriptionId || "").trim();
      if (!purchaseToken) {
        logger.warn("handlePlayBillingRtdn missing purchase token", payload);
        return;
      }

      const tokenHash = sha256(purchaseToken);
      const ownershipSnap = await db.collection(subscriptionCollections.tokenOwnership)
          .doc(tokenHash)
          .get();
      if (!ownershipSnap.exists) {
        logger.warn("handlePlayBillingRtdn unknown token hash", {tokenHash, productId});
        return;
      }

      const uid = String((ownershipSnap.data() || {}).uid || "").trim();
      if (!uid) {
        logger.warn("handlePlayBillingRtdn missing uid", {tokenHash, productId});
        return;
      }

      try {
        await syncSubscriptionEntitlementFromToken({
          uid,
          purchaseToken,
          productIdHint: productId,
          trigger: "rtdn",
        });
      } catch (error) {
        logger.error("handlePlayBillingRtdn sync failed", {
          tokenHash,
          uid,
          productId,
          error: error instanceof Error ? error.message : String(error),
        });
      }
    },
);
