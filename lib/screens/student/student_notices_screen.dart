import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentNoticesScreen extends StatelessWidget {
  final Map<String, dynamic> studentData;
  const StudentNoticesScreen({super.key, required this.studentData});

  @override
  Widget build(BuildContext context) {
    final block = studentData['block'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A3A5C),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          const Text('Notices', style: TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          Text(block, style: const TextStyle(
            color: Color(0xFFF0A500), fontSize: 11)),
        ]),
        iconTheme: const IconThemeData(color: Colors.white)),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notices')
            .where('hostelBlock', isEqualTo: block)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(
            child: CircularProgressIndicator(color: Color(0xFF1A3A5C)));

          if (snap.data!.docs.isEmpty) return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.campaign_outlined, size: 64, color: Colors.grey),
              SizedBox(height: 12),
              Text('No notices yet.',
                style: TextStyle(color: Colors.grey, fontSize: 14)),
            ]));

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: snap.data!.docs.length,
            itemBuilder: (context, i) {
              final d = snap.data!.docs[i].data() as Map<String, dynamic>;
              final isPinned  = d['pinned'] == true;
              final urgency   = d['urgency'] ?? 'Normal';
              final isUrgent  = urgency == 'Urgent';
              final color     = isUrgent
                  ? const Color(0xFFC62828)
                  : const Color(0xFF1A3A5C);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: isUrgent
                      ? Border.all(color: const Color(0xFFC62828),
                          width: 1.5)
                      : isPinned
                          ? Border.all(
                              color: const Color(0xFFF0A500).withOpacity(0.5),
                              width: 1.5)
                          : null,
                  boxShadow: [BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8)]),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.06),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(14),
                        topRight: Radius.circular(14))),
                    child: Row(children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          shape: BoxShape.circle),
                        child: Icon(
                          isUrgent
                              ? Icons.warning_amber_rounded
                              : Icons.campaign,
                          color: color, size: 18)),
                      const SizedBox(width: 10),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                        Text(d['title'] ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 4),
                        // Urgency badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8)),
                          child: Text(urgency, style: TextStyle(
                            fontSize: 10, color: color,
                            fontWeight: FontWeight.w600))),
                      ])),
                      if (isPinned) const Icon(Icons.push_pin,
                        color: Color(0xFFF0A500), size: 18),
                    ])),

                  // Body
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                    child: Text(d['body'] ?? '',
                      style: const TextStyle(
                        fontSize: 13, height: 1.5,
                        color: Colors.black87))),
                ]));
            });
        }),
    );
  }
}