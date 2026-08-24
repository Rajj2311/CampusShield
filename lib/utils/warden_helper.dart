import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WardenHelper {
  static Future<String?> getMyHostel() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    final doc = await FirebaseFirestore.instance
        .collection('wardens').doc(uid).get();
    return doc.data()?['hostelBlock'];
  }
}