const admin = require("firebase-admin");
const {onRequest} = require("firebase-functions/v2/https");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const {onMessagePublished} = require("firebase-functions/v2/pubsub");
const {logger} = require("firebase-functions");
const crypto = require("crypto");
const {google} = require("googleapis");
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
const supportedProductIds = new Set([
  subscriptionPlanConfig.primaryMonthlyProductId,
]);
const playPackageName =
    String(process.env.MANA_POSTER_PLAY_PACKAGE_NAME || "com.manaposter.app")
        .trim();
const playSubscriptionProductIds = new Set([
  subscriptionPlanConfig.primaryMonthlyProductId,
]);
const playApiScope = ["https://www.googleapis.com/auth/androidpublisher"];
let androidPublisherClientPromise = null;
const playRtdnTopic =
    String(process.env.MANA_POSTER_PLAY_RTDN_TOPIC || "play-billing-rtdn")
        .trim();

const dynamicEventCatalog = [
  {
    id: "ambedkar-jayanthi",
    title: "Dr. B.R. Ambedkar Jayanthi",
    month: 4,
    day: 14,
    keywords: ["ambedkar", "jayanthi"],
  },
  {
    id: "independence-day",
    title: "Independence Day",
    month: 8,
    day: 15,
    keywords: ["independence", "national"],
  },
  {
    id: "teachers-day",
    title: "Teachers Day",
    month: 9,
    day: 5,
    keywords: ["teachers", "teacher"],
  },
  {
    id: "gandhi-jayanthi",
    title: "Gandhi Jayanthi",
    month: 10,
    day: 2,
    keywords: ["gandhi", "jayanthi"],
  },
  {
    id: "children-day",
    title: "Children Day",
    month: 11,
    day: 14,
    keywords: ["children", "childrens day"],
  },
  {
    id: "republic-day",
    title: "Republic Day",
    month: 1,
    day: 26,
    keywords: ["republic", "national"],
  },
];

const posterRetentionWindowMillis = 7 * 24 * 60 * 60 * 1000;
const posterCleanupBatchSize = 250;

function setCors(res) {
  res.set("Access-Control-Allow-Origin", "*");
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
    "SUBSCRIPTION_STATE_IN_GRACE_PERIOD",
    "SUBSCRIPTION_STATE_ON_HOLD",
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
  const primaryProductId = productIds[0] || "";
  const expiryTime = firstValidDateTimeString(
      lineItems.map((item) => item.expiryTime),
  );
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
    ...lineItems.map((item) => item.latestSuccessfulOrderId),
  ]);
  const startTime = firstValidDateTimeString([
    payload.startTime,
    ...lineItems.map((item) => item.startTime),
  ]);
  return {
    raw: payload,
    productIds,
    primaryProductId,
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

function buildSubscriptionMetadataPatch(verification) {
  return {
    startTime: toFirestoreTimestamp(verification.startTime),
    expiryTime: toFirestoreTimestamp(verification.expiryTime),
    autoRenewing: verification.autoRenewing === true,
    latestOrderId: verification.latestOrderId || null,
    lastSyncedAt: admin.firestore.FieldValue.serverTimestamp(),
  };
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

function serverSubscriptionTokenRef(tokenHash) {
  return db.collection(subscriptionCollections.serverTokens).doc(tokenHash);
}

async function upsertServerSubscriptionToken({
  uid,
  token,
  tokenHash,
  productId,
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
        throw new Error("Purchase token is already linked to another account");
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

const defaultWebsiteAdminEmail = "manaposter2026@gmail.com";
const websiteAdminEnvEmails = new Set(
    String(
        process.env.MANA_POSTER_WEBSITE_ADMIN_EMAILS ||
        process.env.WEBSITE_ADMIN_EMAILS ||
        defaultWebsiteAdminEmail,
    )
        .split(",")
        .map((item) => normalizeText(item))
        .filter((item) => item.length > 0),
);

async function getWebsiteAdminAccessConfig() {
  const fallbackEmails = Array.from(websiteAdminEnvEmails);
  try {
    const snap = await db.collection("websiteConfig").doc("websiteAdminAccess").get();
    const data = snap.exists ? (snap.data() || {}) : {};
    const docEmails = [
      ...((Array.isArray(data.allowedEmails) ? data.allowedEmails : []).map((item) => normalizeText(item))),
      normalizeText(data.primaryEmail),
    ].filter((item) => item.length > 0);
    const emails = new Set(docEmails.length > 0 ? docEmails : fallbackEmails);
    return {
      emails,
      primaryEmail: docEmails[0] || fallbackEmails[0] || defaultWebsiteAdminEmail,
    };
  } catch (error) {
    logger.warn("getWebsiteAdminAccessConfig failed", error);
    return {
      emails: new Set(fallbackEmails),
      primaryEmail: fallbackEmails[0] || defaultWebsiteAdminEmail,
    };
  }
}

async function websiteAdminEnabled() {
  const config = await getWebsiteAdminAccessConfig();
  return config.emails.size > 0;
}

function websiteAdminAuthEmail(email) {
  const normalizedEmail = normalizeText(email);
  const atIndex = normalizedEmail.indexOf("@");
  if (atIndex <= 0) {
    return normalizedEmail;
  }
  const local = normalizedEmail.slice(0, atIndex);
  const domain = normalizedEmail.slice(atIndex + 1);
  if (local.endsWith("+manaposter-landing")) {
    return normalizedEmail;
  }
  return `${local}+manaposter-landing@${domain}`;
}

function websiteAdminContactEmail(email) {
  const normalizedEmail = normalizeText(email);
  const atIndex = normalizedEmail.indexOf("@");
  if (atIndex <= 0) {
    return normalizedEmail;
  }
  const local = normalizedEmail.slice(0, atIndex);
  const suffixes = ["+manaposter-website", "+manaposter-landing"];
  const suffix = suffixes.find((item) => local.endsWith(item));
  if (!suffix) {
    return normalizedEmail;
  }
  return `${local.slice(0, -suffix.length)}${normalizedEmail.slice(atIndex)}`;
}

function sanitizeFileName(fileName) {
  const cleaned = String(fileName || "")
      .trim()
      .replace(/[^a-zA-Z0-9._-]+/g, "-")
      .replace(/-+/g, "-")
      .replace(/^-|-$/g, "");
  return cleaned || `asset-${Date.now()}`;
}

function safeUrl(raw) {
  const value = String(raw || "").trim();
  if (!value) {
    return "";
  }
  try {
    const url = new URL(value);
    if (url.protocol !== "https:" && url.protocol !== "http:" &&
        url.protocol !== "mailto:") {
      return "";
    }
    return value;
  } catch (_) {
    return "";
  }
}

function safeText(raw, maxLength = 240) {
  return String(raw || "")
      .replace(/<[^>]*>/g, "")
      .trim()
      .slice(0, maxLength);
}

function decodeBase64Payload(base64Data) {
  const raw = String(base64Data || "").trim();
  if (!raw) {
    throw new Error("base64Data is required");
  }
  const payload = raw.includes(",") ? raw.split(",").pop() : raw;
  return Buffer.from(payload, "base64");
}

function buildStorageDownloadUrl(bucketName, objectPath, token) {
  return `https://firebasestorage.googleapis.com/v0/b/${bucketName}/o/${encodeURIComponent(objectPath)}?alt=media&token=${token}`;
}

async function requireWebsiteAdmin(req) {
  const accessConfig = await getWebsiteAdminAccessConfig();
  if (accessConfig.emails.size === 0) {
    throw new Error("Website admin email allowlist is not configured");
  }
  const decoded = await verifyAuth(req);
  const email = normalizeText(decoded.email);
  const contactEmail = websiteAdminContactEmail(email);
  if (!email ||
      (!accessConfig.emails.has(email) && !accessConfig.emails.has(contactEmail))) {
    throw new Error("Website admin access denied");
  }
  return decoded;
}

async function grantLandingAdminAccessByEmail(email, password = "") {
  const normalizedEmail = normalizeText(email);
  if (!normalizedEmail || !normalizedEmail.includes("@")) {
    throw new Error("Valid landing admin email is required");
  }
  const authEmail = websiteAdminAuthEmail(normalizedEmail);

  let userRecord;
  try {
    userRecord = await admin.auth().getUserByEmail(authEmail);
    if (password && password.length >= 6) {
      userRecord = await admin.auth().updateUser(userRecord.uid, {
        password,
        emailVerified: true,
      });
    }
  } catch (error) {
    if (error && error.code === "auth/user-not-found") {
      if (!password || password.length < 6) {
        throw new Error(
            `Password minimum 6 characters required to create ${normalizedEmail}`,
        );
      }
      userRecord = await admin.auth().createUser({
        email: authEmail,
        password,
        emailVerified: true,
      });
    } else {
      throw error;
    }
  }

  const existingClaims = userRecord.customClaims || {};
  await admin.auth().setCustomUserClaims(userRecord.uid, {
    ...existingClaims,
    landingAdmin: true,
  });

  return {
    uid: userRecord.uid,
    email: normalizedEmail,
    authEmail,
  };
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

function reminderCategoryKey(input) {
  const normalized = normalizeText(input);
  if (normalized.includes("welcome")) {
    return "welcome";
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
    ],
    afternoon: [
      {shell: "#F8F5FF", frame: "#5243AA", header: "#342A70", footer: "#6D5DF6", accent: "#D8D1FF", text: "#342A70"},
      {shell: "#F2FAFF", frame: "#0B6FA4", header: "#084B6E", footer: "#22A7F0", accent: "#CDEEFF", text: "#084B6E"},
      {shell: "#F5FCFF", frame: "#007F8C", header: "#00535C", footer: "#00B8C9", accent: "#C9F6FA", text: "#00535C"},
      {shell: "#F8FFF7", frame: "#2F7A32", header: "#1C4B1E", footer: "#58B85A", accent: "#D8F4D8", text: "#1C4B1E"},
      {shell: "#FFF7FB", frame: "#9C3D73", header: "#64244A", footer: "#E05FA9", accent: "#FFD6EB", text: "#64244A"},
    ],
    night: [
      {shell: "#EEF2FF", frame: "#1E3A8A", header: "#0F1D4D", footer: "#3B82F6", accent: "#C9D6FF", text: "#0F1D4D"},
      {shell: "#F4F1FF", frame: "#4338CA", header: "#251E78", footer: "#7C6BFF", accent: "#D7D1FF", text: "#251E78"},
      {shell: "#EEF7FF", frame: "#0F4C81", header: "#082C4A", footer: "#38A3FF", accent: "#CCE9FF", text: "#082C4A"},
      {shell: "#F5F7FA", frame: "#334155", header: "#0F172A", footer: "#64748B", accent: "#D8DEE8", text: "#0F172A"},
      {shell: "#F8F5FF", frame: "#5B3B8F", header: "#352154", footer: "#8F67FF", accent: "#E0D1FF", text: "#352154"},
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
    return {
      name: businessName || String(data.displayName || "").trim() || "User",
      photoUrl: businessLogoUrl,
    };
  }

  const nameTelugu = String(data.nameTelugu || "").trim();
  const nameEnglish = String(data.nameEnglish || "").trim();
  const displayName = String(data.displayName || "").trim();
  const originalPhotoUrl = String(data.originalPhotoUrl || "").trim();
  const photoUrl = String(data.photoUrl || "").trim();

  return {
    name: nameTelugu || nameEnglish || displayName || "User",
    photoUrl: originalPhotoUrl || photoUrl,
  };
}

function sanitizeLanguage(value) {
  const normalized = normalizeText(value);
  return new Set(["telugu", "hindi", "english", "tamil", "kannada", "malayalam"]).has(normalized) ?
    normalized :
    "";
}

async function loadNotificationProfileForUid(uid) {
  if (!uid) {
    return {name: "User", photoUrl: "", preferredLanguage: "english"};
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
      const fallbackName = String(authUser?.displayName || "").trim() || "User";
      const preferredLanguage = sanitizeLanguage(
          userSnap.exists ? (userSnap.data() || {}).preferredLanguage : "",
      ) || defaultLanguageForName(fallbackName);
      return {
        name: fallbackName,
        photoUrl: String(authUser?.photoURL || "").trim(),
        preferredLanguage,
      };
    }
    const baseProfile = notificationProfileFromData(snap.data() || {});
    const resolvedName = String(baseProfile.name || "").trim() ||
        String(authUser?.displayName || "").trim() ||
        "User";
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
          String(authUser?.photoURL || "").trim(),
    };
  } catch (error) {
    logger.warn("loadNotificationProfileForUid failed", {uid, error});
    return {name: "User", photoUrl: "", preferredLanguage: "english"};
  }
}

function defaultLanguageForName(name) {
  return /[\u0C00-\u0C7F]/.test(String(name || "")) ? "telugu" : "english";
}

function reminderCopy(kind, language, userName) {
  const lang = sanitizeLanguage(language) || defaultLanguageForName(userName);
  const name = String(userName || "").trim() || "User";
  const map = {
    welcome: {
      telugu: {
        title: "Mana Poster కి స్వాగతం",
        body: "మీ కోసం రోజువారీ పోస్టర్లు సిద్ధంగా ఉన్నాయి. యాప్ ఓపెన్ చేసి షేర్ చేయండి.",
        header: `${name}, మీ పోస్టర్ సిద్ధంగా ఉంది`,
        footer: "షేర్ చేయండి",
      },
      english: {
        title: "Welcome to Mana Poster",
        body: "Daily posters are ready for you. Open and share.",
        header: `${name}, your poster is ready`,
        footer: "Share",
      },
      hindi: {
        title: "Mana Poster में आपका स्वागत है",
        body: "आपके लिए daily posters ready हैं. Open करके share करें.",
        header: `${name}, आपका poster ready है`,
        footer: "Share",
      },
      tamil: {
        title: "Mana Poster-க்கு வரவேற்கிறோம்",
        body: "உங்களுக்கான தினசரி posters ready. Open செய்து share செய்யுங்கள்.",
        header: `${name}, உங்கள் poster ready`,
        footer: "Share",
      },
      kannada: {
        title: "Mana Poster ಗೆ ಸ್ವಾಗತ",
        body: "ನಿಮಗಾಗಿ daily posters ready ಇವೆ. Open ಮಾಡಿ share ಮಾಡಿ.",
        header: `${name}, ನಿಮ್ಮ poster ready`,
        footer: "Share",
      },
      malayalam: {
        title: "Mana Poster ലേക്ക് സ്വാഗതം",
        body: "നിങ്ങൾക്കായി daily posters ready ആണ്. Open ചെയ്ത് share ചെയ്യൂ.",
        header: `${name}, നിങ്ങളുടെ poster ready`,
        footer: "Share",
      },
    },
    morning: {
      telugu: {
        title: "శుభోదయం",
        body: "మీ ఉదయపు పోస్టర్ సిద్ధంగా ఉంది. ఇప్పుడే షేర్ చేయండి.",
        header: `${name}, మీ ఉదయపు పోస్టర్ సిద్ధంగా ఉంది`,
        footer: "షేర్ చేయండి",
      },
      english: {
        title: "Good Morning",
        body: "Your good morning poster is ready. Share it now.",
        header: `${name}, your morning poster is ready`,
        footer: "Share",
      },
      hindi: {
        title: "सुप्रभात",
        body: "आपका good morning poster ready है. अभी share करें.",
        header: `${name}, आपका morning poster ready है`,
        footer: "Share",
      },
      tamil: {
        title: "காலை வணக்கம்",
        body: "உங்கள் good morning poster ready. இப்போது share செய்யுங்கள்.",
        header: `${name}, உங்கள் morning poster ready`,
        footer: "Share",
      },
      kannada: {
        title: "ಶುಭೋದಯ",
        body: "ನಿಮ್ಮ good morning poster ready ಇದೆ. ಈಗಲೇ share ಮಾಡಿ.",
        header: `${name}, ನಿಮ್ಮ morning poster ready`,
        footer: "Share",
      },
      malayalam: {
        title: "സുപ്രഭാതം",
        body: "നിങ്ങളുടെ good morning poster ready ആണ്. ഇപ്പോൾ share ചെയ്യൂ.",
        header: `${name}, നിങ്ങളുടെ morning poster ready`,
        footer: "Share",
      },
    },
    afternoon: {
      telugu: {
        title: "శుభ మధ్యాహ్నం",
        body: "మీ మధ్యాహ్న పోస్టర్ సిద్ధంగా ఉంది. ఇప్పుడే షేర్ చేయండి.",
        header: `${name}, మీ మధ్యాహ్న పోస్టర్ సిద్ధంగా ఉంది`,
        footer: "షేర్ చేయండి",
      },
      english: {
        title: "Good Afternoon",
        body: "Your good afternoon poster is ready. Share it now.",
        header: `${name}, your afternoon poster is ready`,
        footer: "Share",
      },
      hindi: {
        title: "शुभ दोपहर",
        body: "आपका good afternoon poster ready है. अभी share करें.",
        header: `${name}, आपका afternoon poster ready है`,
        footer: "Share",
      },
      tamil: {
        title: "மதிய வணக்கம்",
        body: "உங்கள் good afternoon poster ready. இப்போது share செய்யுங்கள்.",
        header: `${name}, உங்கள் afternoon poster ready`,
        footer: "Share",
      },
      kannada: {
        title: "ಶುಭ ಮಧ್ಯಾಹ್ನ",
        body: "ನಿಮ್ಮ good afternoon poster ready ಇದೆ. ಈಗಲೇ share ಮಾಡಿ.",
        header: `${name}, ನಿಮ್ಮ afternoon poster ready`,
        footer: "Share",
      },
      malayalam: {
        title: "ശുഭ മധ്യാഹ്നം",
        body: "നിങ്ങളുടെ good afternoon poster ready ആണ്. ഇപ്പോൾ share ചെയ്യൂ.",
        header: `${name}, നിങ്ങളുടെ afternoon poster ready`,
        footer: "Share",
      },
    },
    night: {
      telugu: {
        title: "శుభ రాత్రి",
        body: "మీ రాత్రి పోస్టర్ సిద్ధంగా ఉంది. ఇప్పుడే షేర్ చేయండి.",
        header: `${name}, మీ రాత్రి పోస్టర్ సిద్ధంగా ఉంది`,
        footer: "షేర్ చేయండి",
      },
      english: {
        title: "Good Night",
        body: "Your good night poster is ready. Share it now.",
        header: `${name}, your night poster is ready`,
        footer: "Share",
      },
      hindi: {
        title: "शुभ रात्रि",
        body: "आपका good night poster ready है. अभी share करें.",
        header: `${name}, आपका night poster ready है`,
        footer: "Share",
      },
      tamil: {
        title: "இரவு வணக்கம்",
        body: "உங்கள் good night poster ready. இப்போது share செய்யுங்கள்.",
        header: `${name}, உங்கள் night poster ready`,
        footer: "Share",
      },
      kannada: {
        title: "ಶುಭ ರಾತ್ರಿ",
        body: "ನಿಮ್ಮ good night poster ready ಇದೆ. ಈಗಲೇ share ಮಾಡಿ.",
        header: `${name}, ನಿಮ್ಮ night poster ready`,
        footer: "Share",
      },
      malayalam: {
        title: "ശുഭ രാത്രി",
        body: "നിങ്ങളുടെ good night poster ready ആണ്. ഇപ്പോൾ share ചെയ്യൂ.",
        header: `${name}, നിങ്ങളുടെ night poster ready`,
        footer: "Share",
      },
    },
  };

  const bucket = map[kind] || map.welcome;
  return bucket[lang] || bucket.english;
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

function reminderCopyLocalized(kind, language, userName) {
  const lang = sanitizeLanguage(language) || defaultLanguageForName(userName);
  const name = String(userName || "").trim() || "User";
  const map = {
    welcome: {
      telugu: {
        title: "Mana Poster కి స్వాగతం",
        body: "మీ కోసం రోజువారీ పోస్టర్లు సిద్ధంగా ఉన్నాయి. ఓపెన్ చేసి షేర్ చేయండి.",
        header: `${name}, మీ పోస్టర్ రెడీ`,
        footer: "షేర్ చేయండి",
      },
      english: {
        title: "Welcome to Mana Poster",
        body: "Daily posters are ready for you. Open and share.",
        header: `${name}, your poster is ready`,
        footer: "Share",
      },
      hindi: {
        title: "Mana Poster में आपका स्वागत है",
        body: "आपके लिए daily posters ready हैं. Open करके share करें.",
        header: `${name}, आपका poster ready है`,
        footer: "Share",
      },
      tamil: {
        title: "Mana Poster-க்கு வரவேற்கிறோம்",
        body: "உங்களுக்கான தினசரி posters ready. Open செய்து share செய்யுங்கள்.",
        header: `${name}, உங்கள் poster ready`,
        footer: "Share",
      },
      kannada: {
        title: "Mana Poster ಗೆ ಸ್ವಾಗತ",
        body: "ನಿಮಗಾಗಿ daily posters ready ಇವೆ. Open ಮಾಡಿ share ಮಾಡಿ.",
        header: `${name}, ನಿಮ್ಮ poster ready`,
        footer: "Share",
      },
      malayalam: {
        title: "Mana Posterിലേക്ക് സ്വാഗതം",
        body: "നിങ്ങൾക്കായി daily posters ready ആണ്. Open ചെയ്ത് share ചെയ്യൂ.",
        header: `${name}, നിങ്ങളുടെ poster ready`,
        footer: "Share",
      },
    },
    morning: {
      telugu: {
        title: "శుభోదయం",
        body: "Good morning పోస్టర్ సిద్ధంగా ఉంది. షేర్ చేయండి.",
        header: `${name}, మీ morning పోస్టర్ రెడీ`,
        footer: "షేర్ చేయండి",
      },
      english: {
        title: "Good Morning",
        body: "Your good morning poster is ready. Share it now.",
        header: `${name}, your morning poster is ready`,
        footer: "Share",
      },
      hindi: {
        title: "सुप्रभात",
        body: "आपका good morning poster ready है. अभी share करें.",
        header: `${name}, आपका morning poster ready है`,
        footer: "Share",
      },
      tamil: {
        title: "காலை வணக்கம்",
        body: "உங்கள் good morning poster ready. இப்போது share செய்யுங்கள்.",
        header: `${name}, உங்கள் morning poster ready`,
        footer: "Share",
      },
      kannada: {
        title: "ಶುಭೋದಯ",
        body: "ನಿಮ್ಮ good morning poster ready ಇದೆ. ಈಗಲೇ share ಮಾಡಿ.",
        header: `${name}, ನಿಮ್ಮ morning poster ready`,
        footer: "Share",
      },
      malayalam: {
        title: "സുപ്രഭാതം",
        body: "നിങ്ങളുടെ good morning poster ready ആണ്. ഇപ്പോൾ share ചെയ്യൂ.",
        header: `${name}, നിങ്ങളുടെ morning poster ready`,
        footer: "Share",
      },
    },
    afternoon: {
      telugu: {
        title: "శుభ మధ్యాహ్నం",
        body: "Good afternoon పోస్టర్ సిద్ధంగా ఉంది. షేర్ చేయండి.",
        header: `${name}, మీ afternoon పోస్టర్ రెడీ`,
        footer: "షేర్ చేయండి",
      },
      english: {
        title: "Good Afternoon",
        body: "Your good afternoon poster is ready. Share it now.",
        header: `${name}, your afternoon poster is ready`,
        footer: "Share",
      },
      hindi: {
        title: "शुभ दोपहर",
        body: "आपका good afternoon poster ready है. अभी share करें.",
        header: `${name}, आपका afternoon poster ready है`,
        footer: "Share",
      },
      tamil: {
        title: "மதிய வணக்கம்",
        body: "உங்கள் good afternoon poster ready. இப்போது share செய்யுங்கள்.",
        header: `${name}, உங்கள் afternoon poster ready`,
        footer: "Share",
      },
      kannada: {
        title: "ಶುಭ ಮಧ್ಯಾಹ್ನ",
        body: "ನಿಮ್ಮ good afternoon poster ready ಇದೆ. ಈಗಲೇ share ಮಾಡಿ.",
        header: `${name}, ನಿಮ್ಮ afternoon poster ready`,
        footer: "Share",
      },
      malayalam: {
        title: "ശുഭ മധ്യാഹ്നം",
        body: "നിങ്ങളുടെ good afternoon poster ready ആണ്. ഇപ്പോൾ share ചെയ്യൂ.",
        header: `${name}, നിങ്ങളുടെ afternoon poster ready`,
        footer: "Share",
      },
    },
    night: {
      telugu: {
        title: "శుభ రాత్రి",
        body: "Good night పోస్టర్ సిద్ధంగా ఉంది. షేర్ చేయండి.",
        header: `${name}, మీ night పోస్టర్ రెడీ`,
        footer: "షేర్ చేయండి",
      },
      english: {
        title: "Good Night",
        body: "Your good night poster is ready. Share it now.",
        header: `${name}, your night poster is ready`,
        footer: "Share",
      },
      hindi: {
        title: "शुभ रात्रि",
        body: "आपका good night poster ready है. अभी share करें.",
        header: `${name}, आपका night poster ready है`,
        footer: "Share",
      },
      tamil: {
        title: "இரவு வணக்கம்",
        body: "உங்கள் good night poster ready. இப்போது share செய்யுங்கள்.",
        header: `${name}, உங்கள் night poster ready`,
        footer: "Share",
      },
      kannada: {
        title: "ಶುಭ ರಾತ್ರಿ",
        body: "ನಿಮ್ಮ good night poster ready ಇದೆ. ಈಗಲೇ share ಮಾಡಿ.",
        header: `${name}, ನಿಮ್ಮ night poster ready`,
        footer: "Share",
      },
      malayalam: {
        title: "ശുഭ രാത്രി",
        body: "നിങ്ങളുടെ good night poster ready ആണ്. ഇപ്പോൾ share ചെയ്യൂ.",
        header: `${name}, നിങ്ങളുടെ night poster ready`,
        footer: "Share",
      },
    },
  };

  const bucket = map[kind] || map.welcome;
  return bucket[lang] || bucket.english;
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
  const posterBuffer = await downloadBufferFromUrl(posterImageUrl);
  if (!posterBuffer) {
    return null;
  }

  const palette = framePalette(categoryKey, seed || userName || posterImageUrl);
  const posterResized = await sharp(posterBuffer)
      .resize(924, 650, {fit: "cover", position: "attention"})
      .jpeg({quality: 90})
      .toBuffer();
  const posterDataUri = `data:image/jpeg;base64,${posterResized.toString("base64")}`;

  let avatarDataUri = initialsSvgDataUri(userName, palette);
  const avatarBuffer = await downloadBufferFromUrl(userPhotoUrl);
  if (avatarBuffer) {
    try {
      const avatarResized = await sharp(avatarBuffer)
          .resize(220, 220, {fit: "cover", position: "attention"})
          .jpeg({quality: 90})
          .toBuffer();
      avatarDataUri = `data:image/jpeg;base64,${avatarResized.toString("base64")}`;
    } catch (error) {
      logger.warn("avatar resize failed", {userPhotoUrl, error});
    }
  }

  const safeHeader = xmlEscape(headerText || title).slice(0, 80);
  const safeUserName = xmlEscape(userName || "User").slice(0, 40);
  const safeFooter = xmlEscape(footerText || "Share").slice(0, 30);
  const fontFamily = "Noto Sans Telugu, Noto Sans, Arial Unicode MS, DejaVu Sans, sans-serif";
  const svg = `
  <svg xmlns="http://www.w3.org/2000/svg" width="1080" height="1350" viewBox="0 0 1080 1350">
    <rect width="1080" height="1350" fill="${palette.shell}" />
    <rect x="28" y="28" width="1024" height="1294" rx="46" fill="${palette.frame}" />
    <rect x="54" y="54" width="972" height="1242" rx="34" fill="#ffffff" />
    <rect x="78" y="78" width="924" height="132" rx="12" fill="${palette.header}" />
    <circle cx="148" cy="144" r="48" fill="#ffffff" opacity="0.96" />
    <clipPath id="miniAvatarClip">
      <circle cx="148" cy="144" r="42" />
    </clipPath>
    <image href="${avatarDataUri}" x="106" y="102" width="84" height="84" preserveAspectRatio="xMidYMid slice" clip-path="url(#miniAvatarClip)" />
    <text x="220" y="136" font-family="${fontFamily}" font-size="42" font-weight="700" fill="#ffffff">${safeUserName}</text>
    <text x="220" y="180" font-family="${fontFamily}" font-size="34" font-weight="700" fill="#ffffff">${safeHeader}</text>
    <clipPath id="posterClip">
      <rect x="78" y="226" width="924" height="650" rx="0" ry="0" />
    </clipPath>
    <image href="${posterDataUri}" x="78" y="226" width="924" height="650" preserveAspectRatio="xMidYMid slice" clip-path="url(#posterClip)" />
    <rect x="78" y="876" width="924" height="310" rx="0" fill="#ffffff" />
    <circle cx="540" cy="886" r="118" fill="#ffffff" />
    <circle cx="540" cy="886" r="102" fill="${palette.accent}" />
    <clipPath id="avatarClip">
      <circle cx="540" cy="886" r="94" />
    </clipPath>
    <image href="${avatarDataUri}" x="446" y="792" width="188" height="188" preserveAspectRatio="xMidYMid slice" clip-path="url(#avatarClip)" />
    <text x="540" y="1108" text-anchor="middle" font-family="${fontFamily}" font-size="58" font-weight="700" fill="${palette.text}">${safeUserName}</text>
    <rect x="78" y="1200" width="924" height="86" rx="8" fill="#00C72A" />
    <text x="540" y="1254" text-anchor="middle" font-family="${fontFamily}" font-size="38" font-weight="700" fill="#ffffff">${safeFooter}</text>
  </svg>`;

  return sharp(Buffer.from(svg))
      .png({quality: 92})
      .toBuffer();
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
  title,
  body,
  imageUrl = null,
  userName = "",
  userPhotoUrl = "",
  titleKey = "",
  bodyKey = "",
}) {
  const message = {
    token,
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
      title_key: titleKey || "",
      body_key: bodyKey || "",
      userName: userName || "",
      userPhoto: userPhotoUrl || "",
      posterImage: imageUrl || "",
    },
  };

  return admin.messaging().send(message);
}

async function sendPersonalizedReminderToToken({
  token,
  title,
  body,
  headerText,
  footerText,
  baseImageUrl,
  categoryKey,
  userName,
  userPhotoUrl,
  seed,
}) {
  let imageUrl = String(baseImageUrl || "").trim();
  if (imageUrl) {
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
    }
  }

  return sendReminderToToken({
    token,
    title,
    body,
    imageUrl: imageUrl || null,
    userName,
    userPhotoUrl,
  });
}

async function sendWelcomeToToken(token) {
  const imageUrl = await getPrimaryBannerImage();
  await sendReminderToToken({
    token,
    title: "Welcome to Mana Poster",
    body: "Mee kosam daily posters ready ga untayi. Open chesi share cheyyandi.",
    imageUrl,
  });
}

async function sendPersonalizedWelcomeToToken({
  token,
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
    title: copy.title,
    body: copy.body,
    headerText: copy.header,
    footerText: copy.footer,
    baseImageUrl: imageUrl,
    categoryKey: "welcome",
    userName,
    userPhotoUrl,
    seed,
  });
}

function normalizeText(value) {
  return String(value || "").trim().toLowerCase();
}

async function getRelatedPosterImageByKeywords(keywords) {
  const keyList = (keywords || [])
      .map((item) => normalizeText(item))
      .filter((item) => item.length > 0);
  if (keyList.length === 0) {
    return null;
  }

  try {
    const snap = await db
        .collection("creatorPosters")
        .where("status", "==", "approved")
        .orderBy("createdAt", "desc")
        .limit(180)
        .get();

    for (const doc of snap.docs) {
      const data = doc.data() || {};
      const categoryId = normalizeText(data.categoryId);
      const categoryLabel = normalizeText(data.categoryLabel);
      const title = normalizeText(data.title);
      const imageUrl = String(data.imageUrl || "").trim();
      if (!imageUrl) {
        continue;
      }
      const haystack = `${categoryId} ${categoryLabel} ${title}`;
      const matched = keyList.some((keyword) => haystack.includes(keyword));
      if (matched) {
        return imageUrl;
      }
    }
    return null;
  } catch (error) {
    logger.warn("getRelatedPosterImageByKeywords failed", error);
    return null;
  }
}

async function pickImageForReminder(keywords) {
  const related = await getRelatedPosterImageByKeywords(keywords);
  if (related) {
    return related;
  }
  return getPrimaryBannerImage();
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
  const code = String(
      (error && error.code) ||
      (error && error.errorInfo && error.errorInfo.code) ||
      "",
  ).trim();
  const message = String(
      (error && error.message) ||
      (error && error.errorInfo && error.errorInfo.message) ||
      "",
  ).trim();
  return code === "messaging/registration-token-not-registered" ||
    /Requested entity was not found/i.test(message) ||
    /NotRegistered/i.test(message);
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

async function sendDailyPersonalizedReminder({
  keywords,
  categoryKey,
}) {
  const imageUrl = await pickImageForReminder(keywords);
  const userTokenSnap = await db.collectionGroup("deviceTokens").get();
  const seenTokens = new Set();
  const profileCache = new Map();
  const userJobs = [];

  for (const doc of userTokenSnap.docs) {
    const data = doc.data() || {};
    const token = String(data.token || "").trim();
    if (!token || seenTokens.has(token)) {
      continue;
    }
    const userRef = doc.ref.parent && doc.ref.parent.parent;
    const uid = userRef ? userRef.id : "";
    seenTokens.add(token);
    userJobs.push({token, uid, ref: doc.ref});
  }

  await runWithConcurrency(userJobs, 2, async ({token, uid, ref}) => {
    let profile = profileCache.get(uid);
    if (!profile) {
      profile = await loadNotificationProfileForUid(uid);
      profileCache.set(uid, profile);
    }
    try {
      const copy = reminderCopyLocalized(
          categoryKey,
          profile.preferredLanguage,
          profile.name,
      );
      await sendPersonalizedReminderToToken({
        token,
        title: copy.title,
        body: copy.body,
        headerText: copy.header,
        footerText: copy.footer,
        baseImageUrl: imageUrl,
        categoryKey,
        userName: profile.name,
        userPhotoUrl: profile.photoUrl,
        seed: `${uid}-${token}-${categoryKey}`,
      });
    } catch (error) {
      if (isMessagingTokenGoneError(error)) {
        await cleanupInvalidTokenRef(ref);
      }
      logger.error("personalized daily reminder failed", {uid, token, categoryKey, error});
    }
  });

  const publicSnap = await db.collection("publicDeviceTokens").get();
  const publicJobs = [];
  for (const doc of publicSnap.docs) {
    const data = doc.data() || {};
    const token = String(data.token || "").trim();
    if (!token || seenTokens.has(token)) {
      continue;
    }
    seenTokens.add(token);
    publicJobs.push({token, ref: doc.ref});
  }

  await runWithConcurrency(publicJobs, 2, async ({token, ref}) => {
    try {
      const copy = reminderCopyLocalized(categoryKey, "english", "Mana Poster User");
      await sendPersonalizedReminderToToken({
        token,
        title: copy.title,
        body: copy.body,
        headerText: copy.header,
        footerText: copy.footer,
        baseImageUrl: imageUrl,
        categoryKey,
        userName: "Mana Poster User",
        userPhotoUrl: "",
        seed: `${token}-${categoryKey}`,
      });
    } catch (error) {
      if (isMessagingTokenGoneError(error)) {
        await cleanupInvalidTokenRef(ref);
      }
      logger.error("public daily reminder failed", {token, categoryKey, error});
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

function websiteConfigPayload(payload) {
  const rawCustomText = payload.customText && typeof payload.customText === "object" ?
    payload.customText :
    {};
  const customText = {};
  Object.entries(rawCustomText).forEach(([key, value]) => {
    const safeKey = safeText(key, 80);
    if (safeKey) {
      customText[safeKey] = safeText(value, 500);
    }
  });
  return {
    showHero: payload.showHero !== false,
    showPreview: payload.showPreview !== false,
    showFeatures: payload.showFeatures !== false,
    showCategories: payload.showCategories !== false,
    showDynamicEvents: payload.showDynamicEvents !== false,
    showPlans: payload.showPlans !== false,
    showTestimonials: payload.showTestimonials === true,
    showFaq: payload.showFaq !== false,
    showDownloadCta: payload.showDownloadCta === true,
    downloadUrl: safeUrl(payload.downloadUrl),
    watchDemoUrl: safeUrl(payload.watchDemoUrl),
    supportEmail: safeText(payload.supportEmail, 180),
    facebookUrl: safeUrl(payload.facebookUrl),
    instagramUrl: safeUrl(payload.instagramUrl),
    youtubeUrl: safeUrl(payload.youtubeUrl),
    heroEyebrow: safeText(payload.heroEyebrow, 120),
    heroTitle: safeText(payload.heroTitle, 180),
    heroSubtitle: safeText(payload.heroSubtitle, 420),
    heroPrimaryCtaLabel: safeText(payload.heroPrimaryCtaLabel, 80),
    heroSecondaryCtaLabel: safeText(payload.heroSecondaryCtaLabel, 80),
    heroHighlightLabel: safeText(payload.heroHighlightLabel, 120),
    heroImageUrl: safeUrl(payload.heroImageUrl),
    previewEyebrow: safeText(payload.previewEyebrow, 120),
    previewTitle: safeText(payload.previewTitle, 180),
    previewSubtitle: safeText(payload.previewSubtitle, 420),
    previewImageUrl: safeUrl(payload.previewImageUrl),
    featuresEyebrow: safeText(payload.featuresEyebrow, 120),
    featuresTitle: safeText(payload.featuresTitle, 180),
    featuresSubtitle: safeText(payload.featuresSubtitle, 420),
    categoriesEyebrow: safeText(payload.categoriesEyebrow, 120),
    categoriesTitle: safeText(payload.categoriesTitle, 180),
    categoriesSubtitle: safeText(payload.categoriesSubtitle, 420),
    dynamicEventsEyebrow: safeText(payload.dynamicEventsEyebrow, 120),
    dynamicEventsTitle: safeText(payload.dynamicEventsTitle, 180),
    dynamicEventsSubtitle: safeText(payload.dynamicEventsSubtitle, 420),
    plansEyebrow: safeText(payload.plansEyebrow, 120),
    plansTitle: safeText(payload.plansTitle, 180),
    plansSubtitle: safeText(payload.plansSubtitle, 420),
    plansPrimaryCtaLabel: safeText(payload.plansPrimaryCtaLabel, 80),
    faqEyebrow: safeText(payload.faqEyebrow, 120),
    faqTitle: safeText(payload.faqTitle, 180),
    faqSubtitle: safeText(payload.faqSubtitle, 420),
    downloadEyebrow: safeText(payload.downloadEyebrow, 120),
    downloadTitle: safeText(payload.downloadTitle, 180),
    downloadSubtitle: safeText(payload.downloadSubtitle, 420),
    downloadButtonLabel: safeText(payload.downloadButtonLabel, 80),
    footerTagline: safeText(payload.footerTagline, 280),
    customText,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };
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

function websitePosterPayload(payload) {
  const category = safeText(payload.category, 120);
  const imageUrl = safeUrl(payload.imageUrl);
  const sortOrder = Number.isFinite(Number(payload.sortOrder)) ?
    Number(payload.sortOrder) :
    0;
  return {
    category,
    imageUrl,
    sortOrder,
    active: payload.active !== false,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };
}

exports.websiteAdminGetContent = onRequest({region: "asia-south1"}, async (req, res) => {
  setCors(res);
  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }
  if (req.method !== "POST") {
    res.status(405).json({success: false, message: "Method not allowed"});
    return;
  }

  try {
    await requireWebsiteAdmin(req);
    const accessConfig = await getWebsiteAdminAccessConfig();
    const configSnap = await db.collection("websiteConfig").doc("landingPage").get();
    const posterSnap = await db.collection("websitePosters")
        .orderBy("sortOrder", "asc")
        .get();
    const posters = posterSnap.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
    }));
    res.status(200).json({
      success: true,
      config: configSnap.data() || {},
      posters,
      adminEmailsConfigured: accessConfig.emails.size,
      adminPrimaryEmail: accessConfig.primaryEmail,
    });
  } catch (error) {
    logger.error("websiteAdminGetContent error", error);
    res.status(403).json({
      success: false,
      message: error instanceof Error ? error.message : "Unauthorized",
    });
  }
});

exports.websiteAdminUpdateConfig = onRequest({region: "asia-south1"}, async (req, res) => {
  setCors(res);
  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }
  if (req.method !== "POST") {
    res.status(405).json({success: false, message: "Method not allowed"});
    return;
  }

  try {
    await requireWebsiteAdmin(req);
    const payload = websiteConfigPayload(req.body || {});
    await db.collection("websiteConfig").doc("landingPage").set(payload, {merge: true});
    res.status(200).json({success: true, config: payload});
  } catch (error) {
    logger.error("websiteAdminUpdateConfig error", error);
    res.status(403).json({
      success: false,
      message: error instanceof Error ? error.message : "Config update failed",
    });
  }
});

exports.websiteAdminUpsertPoster = onRequest({region: "asia-south1"}, async (req, res) => {
  setCors(res);
  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }
  if (req.method !== "POST") {
    res.status(405).json({success: false, message: "Method not allowed"});
    return;
  }

  try {
    await requireWebsiteAdmin(req);
    const payload = websitePosterPayload(req.body || {});
    if (!payload.category || !payload.imageUrl) {
      res.status(400).json({
        success: false,
        message: "category and imageUrl are required",
      });
      return;
    }
    const requestedId = safeText(req.body?.posterId || req.body?.id, 160)
        .replace(/[^a-zA-Z0-9_-]+/g, "-")
        .replace(/-+/g, "-")
        .replace(/^-|-$/g, "");
    const posterId = requestedId || `${payload.category.toLowerCase().replace(/[^a-z0-9]+/g, "-")}-${Date.now()}`;
    const ref = db.collection("websitePosters").doc(posterId);
    await ref.set({
      ...payload,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    }, {merge: true});
    res.status(200).json({
      success: true,
      poster: {
        id: posterId,
        ...payload,
      },
    });
  } catch (error) {
    logger.error("websiteAdminUpsertPoster error", error);
    res.status(403).json({
      success: false,
      message: error instanceof Error ? error.message : "Poster save failed",
    });
  }
});

exports.websiteAdminDeletePoster = onRequest({region: "asia-south1"}, async (req, res) => {
  setCors(res);
  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }
  if (req.method !== "POST") {
    res.status(405).json({success: false, message: "Method not allowed"});
    return;
  }

  try {
    await requireWebsiteAdmin(req);
    const posterId = safeText(req.body?.posterId || req.body?.id, 160);
    if (!posterId) {
      res.status(400).json({success: false, message: "posterId is required"});
      return;
    }
    await db.collection("websitePosters").doc(posterId).delete();
    res.status(200).json({success: true, posterId});
  } catch (error) {
    logger.error("websiteAdminDeletePoster error", error);
    res.status(403).json({
      success: false,
      message: error instanceof Error ? error.message : "Poster delete failed",
    });
  }
});

exports.websiteAdminUploadAsset = onRequest({region: "asia-south1"}, async (req, res) => {
  setCors(res);
  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }
  if (req.method !== "POST") {
    res.status(405).json({success: false, message: "Method not allowed"});
    return;
  }

  try {
    await requireWebsiteAdmin(req);
    const assetType = safeText(req.body?.assetType, 40);
    const fileName = sanitizeFileName(req.body?.fileName);
    const contentType = String(req.body?.contentType || "").trim().toLowerCase();
    const buffer = decodeBase64Payload(req.body?.base64Data);

    const assetConfig = assetType === "demoVideo" ?
      {
        folder: "website/videos",
        maxBytes: 25 * 1024 * 1024,
        prefix: "video/",
      } :
      {
        folder: "website/posters",
        maxBytes: 10 * 1024 * 1024,
        prefix: "image/",
      };

    if (!contentType.startsWith(assetConfig.prefix)) {
      res.status(400).json({
        success: false,
        message: `Invalid content type for ${assetType || "asset"}`,
      });
      return;
    }
    if (buffer.length === 0 || buffer.length > assetConfig.maxBytes) {
      res.status(400).json({
        success: false,
        message: `Asset size must be between 1 byte and ${assetConfig.maxBytes} bytes`,
      });
      return;
    }

    const bucket = admin.storage().bucket();
    const objectPath = `${assetConfig.folder}/${Date.now()}-${fileName}`;
    const downloadToken = crypto.randomUUID();
    const file = bucket.file(objectPath);
    await file.save(buffer, {
      resumable: false,
      metadata: {
        contentType,
        cacheControl: "public,max-age=3600",
        metadata: {
          firebaseStorageDownloadTokens: downloadToken,
        },
      },
    });

    const downloadUrl = buildStorageDownloadUrl(
        bucket.name,
        objectPath,
        downloadToken,
    );

    res.status(200).json({
      success: true,
      assetType: assetType || "posterImage",
      path: objectPath,
      downloadUrl,
      contentType,
      bytes: buffer.length,
    });
  } catch (error) {
    logger.error("websiteAdminUploadAsset error", error);
    res.status(403).json({
      success: false,
      message: error instanceof Error ? error.message : "Upload failed",
    });
  }
});

exports.websiteAdminUpdateAccess = onRequest({region: "asia-south1"}, async (req, res) => {
  setCors(res);
  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }
  if (req.method !== "POST") {
    res.status(405).json({success: false, message: "Method not allowed"});
    return;
  }

  try {
    const decoded = await requireWebsiteAdmin(req);
    const nextEmail = normalizeText(req.body?.newEmail);
    const nextPassword = String(req.body?.newPassword || "").trim();
    const requestedEmails = Array.isArray(req.body?.allowedEmails) ?
      req.body.allowedEmails :
      [];
    const allowedEmails = Array.from(
        new Set(
            [
              nextEmail,
              ...requestedEmails.map((item) => normalizeText(item)),
            ].filter((item) => item && item.includes("@")),
        ),
    );

    if (!nextEmail || !nextEmail.includes("@")) {
      throw new Error("Valid admin email is required");
    }
    if (nextPassword.length < 6) {
      throw new Error("Admin password must be at least 6 characters");
    }

    const grantedAdmins = [];
    for (const email of allowedEmails) {
      const grant = await grantLandingAdminAccessByEmail(
          email,
          email === nextEmail ? nextPassword : "",
      );
      grantedAdmins.push(grant);
    }

    await db.collection("websiteConfig").doc("websiteAdminAccess").set({
      primaryEmail: nextEmail,
      allowedEmails,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedByUid: decoded.uid,
      updatedByEmail: normalizeText(decoded.email),
      grants: grantedAdmins,
    }, {merge: true});

    res.status(200).json({
      success: true,
      primaryEmail: nextEmail,
      allowedEmails,
      grantedAdmins,
      message: "Landing admin access updated",
    });
  } catch (error) {
    logger.error("websiteAdminUpdateAccess error", error);
    res.status(403).json({
      success: false,
      message: error instanceof Error ? error.message : "Admin credentials update failed",
    });
  }
});

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
          productId: verification.primaryProductId || productId || null,
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
        productId: verification.primaryProductId || productId || null,
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
      platform,
      source,
      linkedPurchaseTokenHash,
      ackPending: false,
      ackAttempts: 0,
    });

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
      productId: verification.primaryProductId || productId || null,
      subscriptionState: verification.subscriptionState || null,
    });

    res.status(200).json({
      isPro: isValid,
      message: isValid ? "Verification success" : "Verification failed",
      status: entitlementStatus,
      productId: verification.primaryProductId || productId || null,
      subscriptionState: verification.subscriptionState || null,
      startDate: verification.startTime || null,
      expiryTime: verification.expiryTime || null,
      autoRenewing: verification.autoRenewing === true,
      latestOrderId: verification.latestOrderId || null,
      lastSyncedAt: new Date().toISOString(),
      ackPending: !ackSucceeded,
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
    const storedToken = await resolveStoredSubscriptionToken({
      uid,
      entitlementRef,
      entitlementData: data,
    });
    const token = storedToken.token;
    let isPro = data.isPro === true;
    let status = data.status || null;
    let productId = data.productId || null;
    let subscriptionState = data.subscriptionState || null;
    let startTime = data.startTime || null;
    let expiryTime = data.expiryTime || null;
    let autoRenewing = data.autoRenewing ?? null;
    let latestOrderId = data.latestOrderId || null;

    if (token) {
      try {
        const verification = await verifySubscriptionPurchaseWithGoogle({
          purchaseToken: token,
        });
        isPro = verification.valid;
        productId = verification.primaryProductId || productId;
        subscriptionState = verification.subscriptionState || null;
        startTime = toFirestoreTimestamp(verification.startTime) || startTime;
        expiryTime = toFirestoreTimestamp(verification.expiryTime) || expiryTime;
        autoRenewing = verification.autoRenewing === true;
        latestOrderId = verification.latestOrderId || latestOrderId;
        status = deriveEntitlementStatus({
          isPro,
          subscriptionState,
          expiryTime,
        });
        await entitlementRef.set({
          isPro,
          productId,
          subscriptionState,
          startTime,
          status,
          verificationTokenHash: storedToken.tokenHash || data.verificationTokenHash || null,
          ...buildSubscriptionMetadataPatch(verification),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          ackPending: false,
        }, {merge: true});
      } catch (error) {
        logger.warn("subscriptionStatus live sync failed", {
          uid,
          tokenHash: sha256(token),
          error: error instanceof Error ? error.message : String(error),
        });
      }
    }

    res.status(200).json({
      isPro,
      message: isPro ? "Entitlement active" : "Entitlement inactive",
      status,
      productId,
      subscriptionState,
      startDate: firestoreValueToIsoString(startTime),
      expiryTime: firestoreValueToIsoString(expiryTime),
      autoRenewing: autoRenewing === true,
      latestOrderId: latestOrderId || null,
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
  const verification = await verifySubscriptionPurchaseWithGoogle({
    purchaseToken,
  });
  const isPro = verification.valid &&
    (!productIdHint || verification.productIds.includes(productIdHint));
  const entitlementRef = db.doc(`users/${uid}/entitlements/pro`);
  const linkedPurchaseTokenHash = verification.linkedPurchaseToken ?
    sha256(verification.linkedPurchaseToken) :
    null;
  await entitlementRef.set({
    isPro,
    status: isPro ? "active" : "inactive",
    productId: verification.primaryProductId || productIdHint || null,
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
    linkedPurchaseTokenHash,
    ackPending: false,
  });
  await db.collection(`users/${uid}/purchaseEvents`).add({
    type: "subscription_sync",
    trigger,
    isPro,
    productId: verification.primaryProductId || productIdHint || null,
    verificationTokenHash: tokenHash,
    subscriptionState: verification.subscriptionState || null,
    expiryTime: verification.expiryTime || null,
    autoRenewing: verification.autoRenewing === true,
    latestOrderId: verification.latestOrderId || null,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  return {isPro, verification, tokenHash};
}

exports.verifyTemplatePurchase = onRequest({region: "asia-south1"}, async (req, res) => {
  setCors(res);
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
  setCors(res);
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
  setCors(res);
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

    const bucket = admin.storage().bucket();
    await Promise.allSettled([
      bucket.deleteFiles({prefix: `users/${uid}/poster_profile/`}),
      bucket.deleteFiles({prefix: `users/${uid}/rembg_jobs/`}),
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
          .where("welcomeSent", "==", false)
          .limit(40)
          .get();

      for (const doc of publicSnap.docs) {
        const data = doc.data() || {};
        const token = String(data.token || "").trim();
        if (!token) {
          continue;
        }
        try {
          await sendWelcomeToToken(token);
          await doc.ref.set({
            welcomeSent: true,
            welcomeSentAt: admin.firestore.FieldValue.serverTimestamp(),
          }, {merge: true});
        } catch (error) {
          if (isMessagingTokenGoneError(error)) {
            await cleanupInvalidTokenRef(doc.ref);
            continue;
          }
          logger.error("public welcome send failed", error);
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
          const copy = reminderCopyLocalized(
              "welcome",
              profile.preferredLanguage,
              profile.name,
          );
          await sendPersonalizedWelcomeToToken({
            token,
            userName: profile.name,
            userPhotoUrl: profile.photoUrl,
            seed: `${uid}-${token}-welcome`,
            title: copy.title,
            body: copy.body,
            headerText: copy.header,
            footerText: copy.footer,
            language: profile.preferredLanguage,
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
          logger.error("user welcome send failed", error);
        }
      }
    },
);

exports.dailyGoodMorningReminder = onSchedule(
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
      });
    },
);

exports.dailyGoodAfternoonReminder = onSchedule(
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
      });
    },
);

exports.dailyGoodNightReminder = onSchedule(
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
      });
    },
);

exports.dailyDynamicEventReminder = onSchedule(
    {
      region: "asia-south1",
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

        const imageUrl = await pickImageForReminder(event.keywords || [event.title]);

        const eventTimingLabel = daysUntilEvent(event.month, event.day, now) === 1 ?
          "repu" :
          "ee roju";

        await sendTopicReminder({
          title: `${event.title} reminder`,
          body: `${event.title} ${eventTimingLabel} undi. Related poster ni share cheyyandi.`,
          imageUrl,
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
