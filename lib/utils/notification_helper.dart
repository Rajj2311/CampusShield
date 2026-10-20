import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'tenant.dart';

class NotificationHelper {
  static Future<void> send({
    required String toUserId,
    required String title,
    required String body,
    required String type,
    String? relatedId,
  }) async {
    if (toUserId.isEmpty) return;
    await Tenant.col('notifications')
        .doc(toUserId)
        .collection('items')
        .add({
      'title':     title,
      'body':      body,
      'type':      type,
      'relatedId': relatedId,
      'isRead':    false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Stream<int> unreadCount(String userId) {
    return Tenant.col('notifications')
        .doc(userId)
        .collection('items')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  static Future<void> markAllRead(String userId) async {
    final snap = await Tenant.col('notifications')
        .doc(userId)
        .collection('items')
        .where('isRead', isEqualTo: false)
        .get();
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  static String? get currentUserId =>
      FirebaseAuth.instance.currentUser?.uid;
}