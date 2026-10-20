import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme.dart';
import 'college_detail_screen.dart';

class CollegesScreen extends StatelessWidget {
  const CollegesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('colleges').snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(child: Text('Could not load colleges.\n${snap.error}'));
        }
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return const Center(
              child: Text('No colleges yet.', style: TextStyle(color: Colors.black54)));
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: docs.map((d) {
            final c = d.data();
            final status = (c['status'] as String?) ?? 'pending';
            final active = status == 'approved';
            return Card2(
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => CollegeDetailScreen(collegeId: d.id))),
              child: Row(children: [
                const CircleAvatar(
                    backgroundColor: kNavy,
                    child: Icon(Icons.apartment, color: Colors.white)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${c['name'] ?? d.id}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('Code: ${d.id}  •  ${c['city'] ?? ''}',
                        style: const TextStyle(color: Colors.black54, fontSize: 12)),
                  ]),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: (active ? kGreen : kRed).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(status,
                      style: TextStyle(
                          color: active ? kGreen : kRed,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ),
              ]),
            );
          }).toList(),
        );
      },
    );
  }
}
