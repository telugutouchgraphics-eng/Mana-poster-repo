#!/usr/bin/env node

const fs = require("fs");
const path = require("path");

const admin = require("../functions/node_modules/firebase-admin");

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

const repoRoot = path.resolve(__dirname, "..");
const defaultSeedPath = path.join(repoRoot, "docs", "landing-page-firestore-seed.json");

function parseArgs(argv) {
  const args = {
    seedPath: defaultSeedPath,
    replacePosters: false,
  };

  for (let index = 0; index < argv.length; index += 1) {
    const value = argv[index];
    if (value === "--seed" && index + 1 < argv.length) {
      args.seedPath = path.resolve(repoRoot, argv[index + 1]);
      index += 1;
      continue;
    }
    if (value === "--replace-posters") {
      args.replacePosters = true;
      continue;
    }
    if (value === "--help" || value === "-h") {
      printHelp();
      process.exit(0);
    }
    throw new Error(`Unknown argument: ${value}`);
  }

  return args;
}

function printHelp() {
  console.log(
      [
        "Usage: node tool/seed_website_content.js [--seed <json-path>] [--replace-posters]",
        "",
        "Reads docs/landing-page-firestore-seed.json by default and writes:",
        "  - websiteConfig/landingPage",
        "  - websitePosters",
        "",
        "Options:",
        "  --seed <json-path>      Custom seed JSON path relative to repo root.",
        "  --replace-posters       Delete Firestore websitePosters docs that are not in the seed file.",
      ].join("\n"),
  );
}

function readSeedFile(seedPath) {
  const raw = fs.readFileSync(seedPath, "utf8");
  const parsed = JSON.parse(raw);
  const landingPage = parsed["websiteConfig/landingPage"];
  const websitePosters = parsed.websitePosters;

  if (!landingPage || typeof landingPage !== "object" || Array.isArray(landingPage)) {
    throw new Error('Seed JSON must contain an object at "websiteConfig/landingPage".');
  }
  if (!Array.isArray(websitePosters)) {
    throw new Error('Seed JSON must contain an array at "websitePosters".');
  }

  return {
    landingPage,
    websitePosters,
  };
}

function normalizePosterSeed(rawPoster, index) {
  if (!rawPoster || typeof rawPoster !== "object" || Array.isArray(rawPoster)) {
    throw new Error(`websitePosters[${index}] must be an object.`);
  }

  const id = String(rawPoster.id || "").trim();
  const category = String(rawPoster.category || rawPoster.tag || rawPoster.title || "").trim();
  const imageUrl = String(rawPoster.imageUrl || "").trim();
  const sortOrderValue = rawPoster.sortOrder;
  const sortOrder = Number.isFinite(sortOrderValue) ? Number(sortOrderValue) : Number.parseInt(String(sortOrderValue || index + 1), 10);
  const active = rawPoster.active === undefined ? true : rawPoster.active === true;

  if (!id) {
    throw new Error(`websitePosters[${index}] is missing a non-empty "id".`);
  }
  if (!category) {
    throw new Error(`websitePosters[${index}] is missing a non-empty "category".`);
  }
  if (!imageUrl) {
    throw new Error(`websitePosters[${index}] is missing a non-empty "imageUrl".`);
  }
  if (!Number.isFinite(sortOrder)) {
    throw new Error(`websitePosters[${index}] has an invalid "sortOrder".`);
  }

  return {
    id,
    data: {
      category,
      imageUrl,
      sortOrder,
      active,
    },
  };
}

async function writeLandingPage(landingPage) {
  await db.collection("websiteConfig").doc("landingPage").set(landingPage, {merge: true});
}

async function writeWebsitePosters(posters, replacePosters) {
  const normalizedPosters = posters.map(normalizePosterSeed);
  const seedIds = new Set(normalizedPosters.map((item) => item.id));
  const batch = db.batch();

  normalizedPosters.forEach((poster) => {
    const ref = db.collection("websitePosters").doc(poster.id);
    batch.set(ref, poster.data, {merge: true});
  });

  if (replacePosters) {
    const existing = await db.collection("websitePosters").get();
    existing.docs.forEach((doc) => {
      if (!seedIds.has(doc.id)) {
        batch.delete(doc.ref);
      }
    });
  }

  await batch.commit();
  return normalizedPosters.length;
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  const {landingPage, websitePosters} = readSeedFile(args.seedPath);

  await writeLandingPage(landingPage);
  const posterCount = await writeWebsitePosters(
      websitePosters,
      args.replacePosters,
  );

  console.log(`Seeded websiteConfig/landingPage from ${path.relative(repoRoot, args.seedPath)}.`);
  console.log(`Upserted ${posterCount} websitePosters document(s).`);
  if (args.replacePosters) {
    console.log("Removed Firestore websitePosters docs not present in the seed file.");
  }
}

main().catch((error) => {
  console.error(error instanceof Error ? error.message : String(error));
  process.exitCode = 1;
});
