/**
 * One-time migration: moves the existing single-college (IILM) data into
 * colleges/iilm/... and builds userIndex for every existing user.
 *
 * USAGE (from project root, with a service-account key):
 *   cd functions && npm i   (firebase-admin is already there)
 *   export GOOGLE_APPLICATION_CREDENTIALS=/path/to/serviceAccount.json
 *   node ../scripts/migrate_to_multicollege.js --dry-run     # preview
 *   node ../scripts/migrate_to_multicollege.js               # do it
 *
 * Old top-level collections are NOT deleted. Remove them yourself after you
 * have verified the app works.
 */
const path = require("path");
const admin = require(path.join(__dirname, "../functions/node_modules/firebase-admin"));
admin.initializeApp();
const db = admin.firestore();
const auth = admin.auth();

const COLLEGE_ID = "iilm";
const DRY = process.argv.includes("--dry-run");

const COLLECTIONS = [
  "students", "wardens", "guards", "workers", "attendanceRecords",
  "attendanceHistory", "leaveRequests", "complaints", "notices",
  "messMenuDays", "gateHistory", "activity", "deviceChangeRequests", "settings",
];

const COLLEGE_PROFILE = {
  name: "IILM University, Greater Noida",
  status: "approved",
  hostels: [
    "CET Boys", "CET Girls", "Ashoka Girls Hostel",
    "Rosewood Girls Hostel", "Gulmohar Boys Hostel", "Silver Oak Hostel",
  ],
  attendanceStartHour: 20,
  attendanceEndHour: 21,
  geofence: [
    [28.45955209192866, 77.49014626270895],
    [28.461831141589286, 77.48808584610427],
    [28.46270892761878, 77.48930903609478],
    [28.461451751413396, 77.49062649519446],
    [28.46236708512053, 77.49217674802014],
    [28.46144275546668, 77.49294675809352],
    [28.460005642934608, 77.49079789274877],
  ].map(([lat, lng]) => ({ lat, lng })),
  createdAt: admin.firestore.FieldValue.serverTimestamp(),
};

// CHANGE THESE before running — they replace the old hard-coded codes.
const ROLE_CODES = { warden: "CHANGE-ME-WARDEN", guard: "CHANGE-ME-GUARD", worker: "CHANGE-ME-WORKER" };

async function copyCollection(name) {
  const snap = await db.collection(name).get();
  let n = 0;
  let batch = db.batch();
  for (const d of snap.docs) {
    batch.set(db.collection("colleges").doc(COLLEGE_ID).collection(name).doc(d.id), d.data());
    if (++n % 400 === 0 && !DRY) { await batch.commit(); batch = db.batch(); }
  }
  if (!DRY) await batch.commit();
  console.log(`  ${name}: ${snap.size} docs`);
}

// notifications/{uid}/items/* is a nested collection
async function copyNotifications() {
  const users = await db.collection("notifications").listDocuments();
  let n = 0;
  for (const u of users) {
    const items = await u.collection("items").get();
    for (const it of items.docs) {
      n++;
      if (!DRY) {
        await db.collection("colleges").doc(COLLEGE_ID).collection("notifications")
          .doc(u.id).collection("items").doc(it.id).set(it.data());
      }
    }
  }
  console.log(`  notifications: ${n} items`);
}

async function uidForEmail(email) {
  if (!email) return null;
  try { return (await auth.getUserByEmail(email)).uid; } catch { return null; }
}

async function buildUserIndex() {
  const base = db.collection("colleges").doc(COLLEGE_ID);
  let made = 0, skipped = 0;
  for (const [coll, role] of [["wardens","warden"],["guards","guard"],["workers","worker"],["students","student"]]) {
    const snap = await base.collection(coll).get();
    for (const d of snap.docs) {
      const data = d.data();
      if (role === "student" && data.hasAccount !== true) continue;
      // Wardens/guards/workers created by the app use uid as doc id.
      let uid = role === "student" ? null : d.id;
      if (!uid || !(await auth.getUser(uid).then(() => true, () => false))) {
        uid = await uidForEmail(data.email);
      }
      if (!uid) { skipped++; console.log(`  ! no auth user for ${coll}/${d.id} (${data.email || "no email"})`); continue; }
      if (!DRY) {
        await db.collection("userIndex").doc(uid).set({
          collegeId: COLLEGE_ID, role, docId: d.id,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }
      made++;
    }
  }
  console.log(`  userIndex: ${made} created, ${skipped} skipped`);
}

(async () => {
  console.log(DRY ? "DRY RUN — nothing is written" : "MIGRATING", "->", `colleges/${COLLEGE_ID}`);
  if (!DRY) {
    await db.collection("colleges").doc(COLLEGE_ID).set(COLLEGE_PROFILE, { merge: true });
    await db.collection("colleges").doc(COLLEGE_ID).collection("settings").doc("codes").set(ROLE_CODES);
  }
  for (const c of COLLECTIONS) await copyCollection(c);
  await copyNotifications();
  await buildUserIndex();
  console.log("Done. Verify in the app, then delete the old top-level collections.");
})().catch((e) => { console.error(e); process.exit(1); });
