const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

// Roz raat 12:00 baje IST = 18:30 UTC
exports.resetDailyAttendance = functions.pubsub
  .schedule("30 18 * * *")
  .timeZone("Asia/Kolkata")
  .onRun(async (context) => {
    const db = admin.firestore();
    const studentsSnap = await db.collection("students").get();

    const batch = db.batch();
    studentsSnap.docs.forEach((doc) => {
      const data = doc.data();
      // Leave pe hain toh reset mat karo
      if (data.todayStatus !== "leave") {
        batch.update(doc.ref, { todayStatus: "absent" });
      }
    });

    await batch.commit();
    console.log(`✅ Reset ${studentsSnap.docs.length} students to absent`);
    return null;
  });
