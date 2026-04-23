const admin = require("firebase-admin");
const {onRequest} = require("firebase-functions/v2/https");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const {logger} = require("firebase-functions");
const crypto = require("crypto");
const {google} = require("googleapis");

// Source marker used to force runtime redeploy when firebase.json runtime changes.
const functionsRuntimeMarker = "nodejs22-2026-04-22";

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();
const supportedProductIds = new Set([
  "pro_monthly_20",
  "mana_poster_pro_monthly_20",
  "mana_poster_premium_monthly_149",
  "mana_poster_premium_monthly_149_legacy",
]);
const playPackageName =
    String(process.env.MANA_POSTER_PLAY_PACKAGE_NAME || "com.manaposter.app")
        .trim();
const playSubscriptionProductIds = new Set([
  ...supportedProductIds,
  ...String(process.env.MANA_POSTER_SUBSCRIPTION_PRODUCT_IDS || "")
      .split(",")
      .map((item) => item.trim())
      .filter((item) => item.length > 0),
]);
const playApiScope = ["https://www.googleapis.com/auth/androidpublisher"];
let androidPublisherClientPromise = null;

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
  return {
    raw: payload,
    productIds,
    primaryProductId,
    linkedPurchaseToken: String(payload.linkedPurchaseToken || "").trim(),
    subscriptionState: String(payload.subscriptionState || "").trim(),
    valid:
        primaryProductId.length > 0 &&
        playSubscriptionProductIds.has(primaryProductId) &&
        isActiveSubscriptionState(payload.subscriptionState),
  };
}

async function acknowledgeSubscriptionPurchase({
  purchaseToken,
  subscriptionId,
}) {
  if (!subscriptionId) {
    return;
  }
  try {
    const publisher = await getAndroidPublisherClient();
    await publisher.purchases.subscriptions.acknowledge({
      packageName: playPackageName,
      subscriptionId,
      token: purchaseToken,
      requestBody: {},
    });
  } catch (error) {
    logger.warn("acknowledgeSubscriptionPurchase failed", error);
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
  const ref = db.collection("playPurchaseTokens").doc(tokenHash);
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
  if (!email || !accessConfig.emails.has(email)) {
    throw new Error("Website admin access denied");
  }
  return decoded;
}

async function grantLandingAdminAccessByEmail(email, password = "") {
  const normalizedEmail = normalizeText(email);
  if (!normalizedEmail || !normalizedEmail.includes("@")) {
    throw new Error("Valid landing admin email is required");
  }

  let userRecord;
  try {
    userRecord = await admin.auth().getUserByEmail(normalizedEmail);
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
        email: normalizedEmail,
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
    admin: true,
    landingAdmin: true,
  });

  return {
    uid: userRecord.uid,
    email: normalizedEmail,
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
    notification: {
      title,
      body,
      imageUrl: imageUrl || undefined,
    },
    android: {
      priority: "high",
      notification: {
        channelId: "mana_poster_general",
        imageUrl: imageUrl || undefined,
      },
    },
    data: {
      click_action: "FLUTTER_NOTIFICATION_CLICK",
      route: "home",
      imageUrl: imageUrl || "",
    },
  };

  return admin.messaging().send(message);
}

async function sendWelcomeToToken(token) {
  const imageUrl = await getPrimaryBannerImage();
  await admin.messaging().send({
    token,
    notification: {
      title: "Welcome to Mana Poster",
      body: "Mee kosam daily posters ready ga untayi. Open chesi share cheyyandi.",
      imageUrl: imageUrl || undefined,
    },
    android: {
      priority: "high",
      notification: {
        channelId: "mana_poster_general",
        imageUrl: imageUrl || undefined,
      },
    },
    data: {
      type: "welcome",
      click_action: "FLUTTER_NOTIFICATION_CLICK",
      route: "home",
      imageUrl: imageUrl || "",
    },
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

function websiteConfigPayload(payload) {
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
    previewEyebrow: safeText(payload.previewEyebrow, 120),
    previewTitle: safeText(payload.previewTitle, 180),
    previewSubtitle: safeText(payload.previewSubtitle, 420),
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
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };
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
          linkedPurchaseTokenHash: verification.linkedPurchaseToken ?
            sha256(verification.linkedPurchaseToken) :
            null,
          subscriptionState: verification.subscriptionState || null,
          updatedAt: now,
          status: isValid ? "active" : "inactive",
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
        createdAt: now,
      });
    });

    if (verification.linkedPurchaseToken) {
      const previousTokenHash = sha256(verification.linkedPurchaseToken);
      const linkedTokenRef = db.collection("playPurchaseTokens").doc(previousTokenHash);
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

    if (isValid) {
      await acknowledgeSubscriptionPurchase({
        purchaseToken: token,
        subscriptionId: verification.primaryProductId,
      });
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
      productId: verification.primaryProductId || productId || null,
      subscriptionState: verification.subscriptionState || null,
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
          await sendWelcomeToToken(token);
          await doc.ref.set({
            welcomeSent: true,
            welcomeSentAt: admin.firestore.FieldValue.serverTimestamp(),
          }, {merge: true});
        } catch (error) {
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
    },
    async () => {
      const imageUrl = await pickImageForReminder([
        "good morning",
        "morning",
        "suprabhatam",
      ]);
      await sendTopicReminder({
        title: "Good Morning",
        body: "Good morning poster ready ga undi, share cheyyandi.",
        imageUrl,
      });
    },
);

exports.dailyGoodAfternoonReminder = onSchedule(
    {
      region: "asia-south1",
      schedule: "0 13 * * *",
      timeZone: "Asia/Kolkata",
    },
    async () => {
      const imageUrl = await pickImageForReminder([
        "good afternoon",
        "afternoon",
      ]);
      await sendTopicReminder({
        title: "Good Afternoon",
        body: "Good afternoon poster ready ga undi, share cheyyandi.",
        imageUrl,
      });
    },
);

exports.dailyGoodNightReminder = onSchedule(
    {
      region: "asia-south1",
      schedule: "30 20 * * *",
      timeZone: "Asia/Kolkata",
    },
    async () => {
      const imageUrl = await pickImageForReminder([
        "good night",
        "night",
      ]);
      await sendTopicReminder({
        title: "Good Night",
        body: "Good night poster ready ga undi, share cheyyandi.",
        imageUrl,
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
