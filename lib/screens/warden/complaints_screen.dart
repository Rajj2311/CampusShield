import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/tenant.dart';

class ComplaintsScreen extends StatefulWidget {
  const ComplaintsScreen({super.key});
  @override
  State<ComplaintsScreen> createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends State<ComplaintsScreen> {
  String  _filter      = 'All';
  String? _wardenHostel;

  @override
  void initState() {
    super.initState();
    _loadWardenHostel();
  }

  Future<void> _loadWardenHostel() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await Tenant.col('wardens').doc(uid).get();
    if (doc.exists) setState(() => _wardenHostel = doc.data()?['hostelBlock']);
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'In Progress': return const Color(0xFFF57F17);
      case 'Resolved':    return const Color(0xFF1565C0);
      case 'Closed':      return const Color(0xFF2E7D32);
      case 'Reopened':    return const Color(0xFFC62828);
      default:            return const Color(0xFF9E9E9E);
    }
  }

  Color _statusBg(String s) {
    switch (s) {
      case 'In Progress': return const Color(0xFFFFF3E0);
      case 'Resolved':    return const Color(0xFFE3F2FD);
      case 'Closed':      return const Color(0xFFE8F5E9);
      case 'Reopened':    return const Color(0xFFFFEBEE);
      default:            return const Color(0xFFF5F5F5);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_wardenHostel == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(backgroundColor: const Color(0xFF1A3A5C),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Complaints', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          Text(_wardenHostel!, style: const TextStyle(color: Color(0xFFF0A500), fontSize: 11)),
        ]),
        iconTheme: const IconThemeData(color: Colors.white)),
      body: StreamBuilder<QuerySnapshot>(
        stream: Tenant.col('complaints')
            .where('hostelBlock', isEqualTo: _wardenHostel)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final all = snap.data!.docs;

          // Counts
          final pending    = all.where((d) => (d.data() as Map)['status'] == 'Pending').length;
          final inProgress = all.where((d) => (d.data() as Map)['status'] == 'In Progress').length;
          final resolved   = all.where((d) => (d.data() as Map)['status'] == 'Resolved').length;
          final closed     = all.where((d) => (d.data() as Map)['status'] == 'Closed').length;
          final reopened   = all.where((d) => (d.data() as Map)['status'] == 'Reopened').length;

          final filtered = _filter == 'All' ? all
              : all.where((d) => (d.data() as Map)['status'] == _filter).toList();

          return Column(children: [
            // Stats
            Container(color: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                _chip('Pending',  pending,    const Color(0xFF9E9E9E)),
                _chip('Progress', inProgress, const Color(0xFFF57F17)),
                _chip('Resolved', resolved,   const Color(0xFF1565C0)),
                _chip('Closed',   closed,     const Color(0xFF2E7D32)),
                _chip('Reopened', reopened,   const Color(0xFFC62828)),
              ])),

            // Filter tabs
            Container(color: Colors.white, padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
              child: SingleChildScrollView(scrollDirection: Axis.horizontal,
                child: Row(children: ['All', 'Pending', 'In Progress', 'Resolved', 'Closed', 'Reopened'].map((f) {
                  final sel = _filter == f;
                  return GestureDetector(onTap: () => setState(() => _filter = f),
                    child: Container(margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: sel ? const Color(0xFF1A3A5C) : const Color(0xFFF5F7FA),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF1A3A5C).withOpacity(0.3))),
                      child: Text(f, style: TextStyle(
                        color: sel ? Colors.white : const Color(0xFF1A3A5C),
                        fontSize: 11, fontWeight: FontWeight.w600))));
                }).toList()))),
            const Divider(height: 1),

            filtered.isEmpty
              ? const Expanded(child: Center(child: Text('No complaints found.', style: TextStyle(color: Colors.grey))))
              : Expanded(child: ListView.builder(
                  padding: const EdgeInsets.all(12), itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final doc    = filtered[i];
                    final d      = doc.data() as Map<String, dynamic>;
                    final status = d['status'] ?? 'Pending';
                    final color  = _statusColor(status);

                    return Container(margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        // Header
                        Container(padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: _statusBg(status),
                            borderRadius: const BorderRadius.only(topLeft: Radius.circular(14), topRight: Radius.circular(14))),
                          child: Row(children: [
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(d['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              Text('${d['studentName'] ?? ''} • Room ${d['room'] ?? ''} • ${d['category'] ?? ''}',
                                style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            ])),
                            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                              child: Text(status, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold))),
                          ])),

                        Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(d['description'] ?? '', style: const TextStyle(fontSize: 13)),
                          const SizedBox(height: 10),

                          // Worker assignment info
                          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(color: const Color(0xFFF5F7FA), borderRadius: BorderRadius.circular(8)),
                            child: Row(children: [
                              const Icon(Icons.engineering, size: 14, color: Color(0xFF1A3A5C)),
                              const SizedBox(width: 6),
                              Text('Assigned: ${d['assignedWorkerName'] ?? 'Unassigned'}',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF1A3A5C), fontWeight: FontWeight.w500)),
                            ])),
                          const SizedBox(height: 10),

                          // Before / After photos side by side
                          if (d['beforePhotoUrl'] != null || d['afterPhotoUrl'] != null)
                            Row(children: [
                              if (d['beforePhotoUrl'] != null)
                                Expanded(child: Column(children: [
                                  const Text('Before', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey)),
                                  const SizedBox(height: 4),
                                  ClipRRect(borderRadius: BorderRadius.circular(8),
                                    child: Image.network(d['beforePhotoUrl'], height: 100, width: double.infinity, fit: BoxFit.cover)),
                                ])),
                              if (d['beforePhotoUrl'] != null && d['afterPhotoUrl'] != null)
                                const SizedBox(width: 10),
                              if (d['afterPhotoUrl'] != null)
                                Expanded(child: Column(children: [
                                  const Text('After', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey)),
                                  const SizedBox(height: 4),
                                  ClipRRect(borderRadius: BorderRadius.circular(8),
                                    child: Image.network(d['afterPhotoUrl'], height: 100, width: double.infinity, fit: BoxFit.cover)),
                                ])),
                            ]),

                          // Student verification status
                          if (d['studentVerified'] != null) ...[
                            const SizedBox(height: 10),
                            Container(padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: d['studentVerified'] == 'fixed' ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                                borderRadius: BorderRadius.circular(8)),
                              child: Row(children: [
                                Icon(d['studentVerified'] == 'fixed' ? Icons.check_circle : Icons.cancel,
                                  color: d['studentVerified'] == 'fixed' ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                                  size: 16),
                                const SizedBox(width: 6),
                                Text(d['studentVerified'] == 'fixed'
                                  ? 'Student verified: Issue Fixed ✅'
                                  : 'Student reported: Not Fixed ❌',
                                  style: TextStyle(fontSize: 12,
                                    color: d['studentVerified'] == 'fixed' ? const Color(0xFF2E7D32) : const Color(0xFFC62828))),
                              ])),
                          ],
                        ])),
                      ]));
                  })),
          ]);
        }),
    );
  }

  Widget _chip(String label, int count, Color color) => Column(children: [
    Text('$count', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
    Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey)),
  ]);
}