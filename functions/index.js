const admin = require("firebase-admin");
const {onRequest} = require("firebase-functions/v2/https");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const {logger} = require("firebase-functions");

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();
const supportedProductIds = new Set([
  "pro_monthly_20",
  "mana_poster_pro_monthly_20",
]);

const dynamicEventCatalog = [
  {id: "ambedkar-jayanthi", title: "Dr. B.R. Ambedkar Jayanthi", month: 4, day: 14},
  {id: "independence-day", title: "Independence Day", month: 8, day: 15},
  {id: "teachers-day", title: "Teachers Day", month: 9, day: 5},
  {id: "gandhi-jayanthi", title: "Gandhi Jayanthi", month: 10, day: 2},
  {id: "children-day", title: "Children Day", month: 11, day: 14},
  {id: "republic-day", title: "Republic Day", month: 1, day: 26},
];

function setCors(res) {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Headers", "Authorization, Content-Type");
  res.set("Access-Control-Allow-Methods", "POST, OPTIONS");
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
    },
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
      const imageUrl = await getPrimaryBannerImage();
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
      const imageUrl = await getPrimaryBannerImage();
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
      const imageUrl = await getPrimaryBannerImage();
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
      schedule: "0 8 * * *",
      timeZone: "Asia/Kolkata",
    },
    async () => {
      const now = new Date();
      const matchingEvents = dynamicEventCatalog.filter((event) => {
        const delta = daysUntilEvent(event.month, event.day, now);
        return delta >= 0 && delta <= 2;
      });

      if (matchingEvents.length === 0) {
        return;
      }

      const imageUrl = await getPrimaryBannerImage();

      for (const event of matchingEvents) {
        const key = `${now.getFullYear()}-${event.id}-${now.getMonth() + 1}-${now.getDate()}`;
        const sentRef = db.collection("notificationJobs").doc("dynamicEventReminders")
            .collection("sent").doc(key);
        const exists = await sentRef.get();
        if (exists.exists) {
          continue;
        }

        await sendTopicReminder({
          title: `${event.title} reminder`,
          body: `${event.title} poster share cheyyadaniki ready ga undandi.`,
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
