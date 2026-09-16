const admin = require('firebase-admin');
const fs = require('fs');

const envContent = fs.readFileSync('C:/Users/telug/mana-poster-web-portal/.env.local', 'utf8');
const env = {};
envContent.split(/\r?\n/).forEach(line => {
  const idx = line.indexOf('=');
  if (idx > 0) {
    const key = line.slice(0, idx).trim();
    let val = line.slice(idx + 1).trim();
    env[key] = val;
  }
});

const privateKey = env.FIREBASE_PRIVATE_KEY ? env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n') : '';

const appAp = admin.initializeApp({
  credential: admin.credential.cert({
    projectId: env.FIREBASE_PROJECT_ID,
    clientEmail: env.FIREBASE_CLIENT_EMAIL,
    privateKey: privateKey,
  })
}, 'ap');

const editorServiceAccount = require('C:/Users/telug/mana-poster-web-portal/editor-service-account.json');
const appEditor = admin.initializeApp({
  credential: admin.credential.cert(editorServiceAccount)
}, 'editor');

async function run() {
  const dbAp = appAp.firestore();
  const dbEd = appEditor.firestore();

  console.log('--- Checking collections in mana-poster-ap ---');
  const collectionsAp = await dbAp.listCollections();
  console.log('AP Collections:', collectionsAp.map(c => c.id));

  for (const c of collectionsAp) {
    try {
      const snap = await c.orderBy('createdAt', 'desc').limit(2).get();
      if (!snap.empty) {
        const d = snap.docs[0].data();
        const dt = d.createdAt ? new Date(d.createdAt).toLocaleString('en-IN', {timeZone: 'Asia/Kolkata'}) : 'no-date';
        console.log(`  Collection ${c.id}: latest doc id=${snap.docs[0].id}, createdAt=${dt}`);
      }
    } catch (_) {}
  }

  console.log('\n--- Checking collections in mana-poster-editor ---');
  const collectionsEd = await dbEd.listCollections();
  console.log('Editor Collections:', collectionsEd.map(c => c.id));
  for (const c of collectionsEd) {
    try {
      const snap = await c.orderBy('createdAt', 'desc').limit(2).get();
      if (!snap.empty) {
        const d = snap.docs[0].data();
        const dt = d.createdAt ? new Date(d.createdAt).toLocaleString('en-IN', {timeZone: 'Asia/Kolkata'}) : 'no-date';
        console.log(`  Editor Collection ${c.id}: latest doc id=${snap.docs[0].id}, createdAt=${dt}`);
      }
    } catch (_) {}
  }
}

run().catch(console.error);

