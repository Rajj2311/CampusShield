/**
 * Gives ONE account the app-owner (super admin) power.
 *   export GOOGLE_APPLICATION_CREDENTIALS=/path/to/serviceAccount.json
 *   node scripts/set_owner.js you@example.com
 * The owner signs out/in again for the claim to take effect.
 */
const path = require("path");
const admin = require(path.join(__dirname, "../functions/node_modules/firebase-admin"));
admin.initializeApp();
(async () => {
  const email = process.argv[2];
  if (!email) throw new Error("Usage: node set_owner.js <email>");
  const user = await admin.auth().getUserByEmail(email);
  await admin.auth().setCustomUserClaims(user.uid, { superAdmin: true });
  console.log(`✅ ${email} (${user.uid}) is now owner/superAdmin`);
})().catch((e) => { console.error(e.message); process.exit(1); });
