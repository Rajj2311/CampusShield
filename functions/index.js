const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

// Roz raat 12:00 baje IST = 18:30 UTC — har approved college ke students reset.
exports.resetDailyAttendance = functions.pubsub
  .schedule("30 18 * * *")
  .timeZone("Asia/Kolkata")
  .onRun(async () => {
    const db = admin.firestore();
    const colleges = await db
      .collection("colleges")
      .where("status", "==", "approved")
      .get();

    for (const college of colleges.docs) {
      const studentsSnap = await college.ref.collection("students").get();

      // Firestore batches are limited to 500 writes.
      let batch = db.batch();
      let ops = 0;
      let total = 0;
      for (const doc of studentsSnap.docs) {
        // Leave pe hain toh reset mat karo
        if (doc.data().todayStatus === "leave") continue;
        batch.update(doc.ref, { todayStatus: "absent" });
        ops++; total++;
        if (ops === 450) { await batch.commit(); batch = db.batch(); ops = 0; }
      }
      if (ops > 0) await batch.commit();
      console.log(`✅ ${college.id}: reset ${total} students to absent`);
    }
    return null;
  });
