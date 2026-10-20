import 'package:firebase_auth/firebase_auth.dart';
import 'tenant.dart';

class WardenHelper {
  static Future<String?> getMyHostel() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    final doc = await Tenant.col('wardens').doc(uid).get();
    return doc.data()?['hostelBlock'];
  }
}