import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/shared/notification_screen.dart';

class NotificationBell extends StatelessWidget {
  final String userId;
  const NotificationBell({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    if (userId.isEmpty) return const SizedBox();
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .doc(userId)
          .collection('items')
          .where('isRead', isEqualTo: false)
          .snapshots(),
      builder: (context, snap) {
        final count = snap.data?.docs.length ?? 0;
        return IconButton(
          onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) =>
              NotificationScreen(userId: userId))),
          icon: Stack(children: [
            const Icon(Icons.notifications_outlined,
              color: Colors.white, size: 26),
            if (count > 0) Positioned(right: 0, top: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Color(0xFFC62828), shape: BoxShape.circle),
                constraints: const BoxConstraints(
                  minWidth: 16, minHeight: 16),
                child: Text('$count',
                  style: const TextStyle(color: Colors.white,
                    fontSize: 9, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center))),
          ]));
      });
  }
}