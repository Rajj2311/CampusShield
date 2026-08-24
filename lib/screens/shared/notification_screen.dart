import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/notification_helper.dart';

class NotificationScreen extends StatefulWidget {
  final String userId;
  const NotificationScreen({super.key, required this.userId});
  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 1),
      () => NotificationHelper.markAllRead(widget.userId));
  }

  IconData _icon(String type) {
    switch (type) {
      case 'leave':      return Icons.event_note;
      case 'complaint':  return Icons.report;
      case 'notice':     return Icons.campaign;
      case 'attendance': return Icons.how_to_reg;
      default:           return Icons.notifications;
    }
  }

  Color _color(String type) {
    switch (type) {
      case 'leave':      return const Color(0xFF1565C0);
      case 'complaint':  return const Color(0xFFC62828);
      case 'notice':     return const Color(0xFF6A1B9A);
      case 'attendance': return const Color(0xFF2E7D32);
      default:           return const Color(0xFF1A3A5C);
    }
  }

  String _timeAgo(Timestamp? ts) {
    if (ts == null) return '';
    final diff = DateTime.now().difference(ts.toDate());
    if (diff.inMinutes < 1)  return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24)   return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A3A5C),
        title: const Text('Notifications', style: TextStyle(
          color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          TextButton(
            onPressed: () => NotificationHelper.markAllRead(widget.userId),
            child: const Text('Mark all read',
              style: TextStyle(color: Color(0xFFF0A500), fontSize: 12))),
        ]),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .doc(widget.userId)
            .collection('items')
            .orderBy('createdAt', descending: true)
            .limit(50)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(
            child: CircularProgressIndicator(color: Color(0xFF1A3A5C)));
          if (snap.data!.docs.isEmpty) {
            return const Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.notifications_none, size: 64, color: Colors.grey),
              SizedBox(height: 12),
              Text('No notifications yet',
                style: TextStyle(color: Colors.grey, fontSize: 15)),
            ]));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: snap.data!.docs.length,
            itemBuilder: (context, i) {
              final d      = snap.data!.docs[i].data() as Map<String, dynamic>;
              final isRead = d['isRead'] ?? false;
              final type   = d['type'] ?? 'general';
              final ts     = d['createdAt'] as Timestamp?;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: isRead ? Colors.white : const Color(0xFFEEF4FF),
                  borderRadius: BorderRadius.circular(12),
                  border: isRead ? null : Border.all(
                    color: const Color(0xFF1A3A5C).withOpacity(0.15)),
                  boxShadow: [BoxShadow(
                    color: Colors.black.withOpacity(0.04), blurRadius: 6)]),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _color(type).withOpacity(0.12),
                      shape: BoxShape.circle),
                    child: Icon(_icon(type),
                      color: _color(type), size: 20)),
                  title: Text(d['title'] ?? '',
                    style: TextStyle(
                      fontWeight: isRead
                          ? FontWeight.normal : FontWeight.bold,
                      fontSize: 13, color: const Color(0xFF1A3A5C))),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    const SizedBox(height: 2),
                    Text(d['body'] ?? '',
                      style: const TextStyle(
                        fontSize: 12, color: Colors.black87)),
                    const SizedBox(height: 4),
                    Text(_timeAgo(ts),
                      style: const TextStyle(
                        fontSize: 10, color: Colors.grey)),
                  ]),
                  trailing: isRead ? null : Container(
                    width: 8, height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF1A3A5C),
                      shape: BoxShape.circle)),
                ));
            });
        }),
    );
  }
}