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
const manaReminderToolKey = String(process.env.MANA_REMINDER_TOOL_KEY || "").trim();

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
  return new Set(["telugu", "hindi", "english", "tamil", "kannada", "malayalam"]).has(normalized) ?
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
    return {name: "", photoUrl: "", preferredLanguage: "english"};
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
      };
    }
    const baseProfile = notificationProfileFromData(snap.data() || {});
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
          String(authUser?.photoURL || "").trim(),
    };
  } catch (error) {
    logger.warn("loadNotificationProfileForUid failed", {uid, error});
    return {name: "", photoUrl: "", preferredLanguage: "english"};
  }
}

function defaultLanguageForName(name) {
  return /[\u0C00-\u0C7F]/.test(String(name || "")) ? "telugu" : "english";
}

function reminderCopy(kind, language, userName) {
  const displayName = pickFirstUsablePosterName(userName);
  const lang =
      sanitizeLanguage(language) ||
      (displayName ? defaultLanguageForName(displayName) : "english");
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
  return reminderCopy(kind, language, userName);
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
  headerText = "",
  footerText = "",
  categoryKey = "",
  titleKey = "",
  bodyKey = "",
}) {
  const normalizedTitle = String(title || "").trim();
  const normalizedBody = String(body || "").trim();
  const normalizedImageUrl = String(imageUrl || "").trim();
  const normalizedPlatform = String(platform || "").trim().toLowerCase();
  const isAndroidTarget = normalizedPlatform === "android";
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
      route: "home",
      title: isAndroidTarget && normalizedImageUrl ? "" : normalizedTitle,
      body: isAndroidTarget && normalizedImageUrl ? "" : normalizedBody,
      title_key: isAndroidTarget && normalizedImageUrl ? "" : titleKey || "",
      body_key: isAndroidTarget && normalizedImageUrl ? "" : bodyKey || "",
      userName: userName || "",
      userPhoto: userPhotoUrl || "",
      headerText: headerText || "",
      footerText: footerText || "",
      categoryKey: categoryKey || "",
      posterBaseImage: posterBaseImageUrl || "",
      posterImage: normalizedImageUrl,
    },
  };

  if (!isAndroidTarget) {
    message.notification = {
      title: normalizedTitle,
      body: normalizedBody,
    };
    message.android.notification = {
      channelId: "mana_poster_general",
      clickAction: "FLUTTER_NOTIFICATION_CLICK",
      title: normalizedImageUrl ? "\u200B" : normalizedTitle,
      body: normalizedImageUrl ? "" : normalizedBody,
    };
  }

  if (normalizedImageUrl && !isAndroidTarget) {
    message.android.notification.imageUrl = normalizedImageUrl;
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

async function sendWelcomeToToken(token, platform = "") {
  const imageUrl = await getPrimaryBannerImage();
  await sendReminderToToken({
    token,
    platform,
    title: "Welcome to Mana Poster",
    body: "Mee kosam daily posters ready ga untayi. Open chesi share cheyyandi.",
    imageUrl,
    posterBaseImageUrl: imageUrl || "",
    headerText: "Welcome to Mana Poster",
    footerText: "Share",
    categoryKey: "welcome",
    titleKey: "welcome_title",
    bodyKey: "welcome_body",
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
  if (uid && fcmToken) {
    const snap = await db.collection("users").doc(uid).collection("deviceTokens")
        .where("token", "==", fcmToken)
        .limit(1)
        .get();
    if (!snap.empty) {
      const data = snap.docs[0].data() || {};
      platform = String(data.platform || "android").trim() || "android";
    }
  }

  const profile = await loadNotificationProfileForUid(uid);
  const jobs = [
    {categoryKey: "morning", keywords: morningKeywords},
    {categoryKey: "afternoon", keywords: afternoonKeywords},
    {categoryKey: "night", keywords: nightKeywords},
  ];
  const results = [];
  for (const job of jobs) {
    const imageUrl = await pickImageForReminder(job.keywords);
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
    });
  }

  await runWithConcurrency(userJobs, 2, async ({token, uid, ref, platform}) => {
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
        platform,
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
    if (!token || seenTokens.has(token) || !tokenAllowsCategory(data, categoryKey)) {
      continue;
    }
    seenTokens.add(token);
    publicJobs.push({
      token,
      ref: doc.ref,
      platform: String(data.platform || "").trim(),
    });
  }

  await runWithConcurrency(publicJobs, 2, async ({token, ref, platform}) => {
    try {
      const copy = reminderCopyLocalized(categoryKey, "english", "Mana Poster User");
      await sendPersonalizedReminderToToken({
        token,
        platform,
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
}) {
  const userTokenSnap = await db.collectionGroup("deviceTokens").get();
  const publicSnap = await db.collection("publicDeviceTokens").get();
  const seenTokens = new Set();
  const jobs = [];

  for (const doc of userTokenSnap.docs) {
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
    });
  }

  await runWithConcurrency(jobs, 4, async ({token, ref, platform}) => {
    try {
      await sendReminderToToken({
        token,
        platform,
        title,
        body,
        imageUrl: imageUrl || null,
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

    status = deriveEntitlementStatus({
      isPro,
      subscriptionState,
      expiryTime,
    });
    isPro = status === "active";

    if (isPro !== (data.isPro === true) || status !== (data.status || null)) {
      await entitlementRef.set({
        isPro,
        status,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, {merge: true});
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
          await sendWelcomeToToken(token, String(data.platform || "").trim());
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
          const copy = reminderCopyLocalized(
              "welcome",
              profile.preferredLanguage,
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
          logger.error("user welcome send failed", {
            uid,
            token,
            error: messagingErrorDetails(error),
          });
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

        await sendDirectReminderToEligibleTokens({
          categoryKey: "dynamic_event",
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
