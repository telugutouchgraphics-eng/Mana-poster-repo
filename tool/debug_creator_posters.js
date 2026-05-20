const admin = require("../functions/node_modules/firebase-admin");

admin.initializeApp({projectId: "mana-poster-ap"});

function simplify(value) {
  if (!value || typeof value !== "object") {
    return value;
  }
  if (typeof value.toDate === "function") {
    return value.toDate().toISOString();
  }
  if (Array.isArray(value)) {
    return value.map(simplify);
  }
  return Object.fromEntries(
      Object.entries(value).map(([key, item]) => [key, simplify(item)]),
  );
}

async function main() {
  const snapshot = await admin
      .firestore()
      .collection("creatorPosters")
      .where("status", "==", "approved")
      .limit(40)
      .get();
  console.log("approved_count", snapshot.size);
  for (const doc of snapshot.docs) {
    const data = simplify(doc.data());
    const category = String(data.categoryId || data.categoryLabel || "")
        .toLowerCase();
    if (
      category.includes("good") ||
      category.includes("morning") ||
      String(data.title || "").toLowerCase().includes("morning")
    ) {
      console.log(doc.id, JSON.stringify(data, null, 2));
    }
  }
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
