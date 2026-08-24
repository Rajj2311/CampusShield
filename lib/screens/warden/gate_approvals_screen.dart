import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/warden_helper.dart';

class GateApprovalsScreen extends StatefulWidget {
  const GateApprovalsScreen({super.key});
  @override
  State<GateApprovalsScreen> createState() => _GateApprovalsScreenState();
}

class _GateApprovalsScreenState extends State<GateApprovalsScreen> {
  String? _wardenHostel;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final h = await WardenHelper.getMyHostel();
    setState(() => _wardenHostel = h);
  }

  Future<void> _approve(String docId, bool approved) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final leaveDoc = await FirebaseFirestore.instance
        .collection('leaveRequests').doc(docId).get();
    final d = leaveDoc.data() as Map<String, dynamic>? ?? {};

    await FirebaseFirestore.instance
        .collection('leaveRequests').doc(docId).update({
      'gateStatus':           approved ? 'completed' : 'rejected_at_gate',
      'wardenApprovalStatus': approved ? 'approved' : 'rejected',
      'wardenApprovedBy':     uid,
      'wardenApprovalTime':   FieldValue.serverTimestamp(),
    });

    // The student's todayStatus was left as 'leave' when the guard first
    // escalated this late/expired return to the warden. Now that the
    // warden has made a decision, flip it back so the student isn't
    // stuck showing 'leave' forever (the nightly reset intentionally
    // skips anyone whose todayStatus is still 'leave').
    final roll = d['roll'];
    if (roll != null) {
      final studentSnap = await FirebaseFirestore.instance
          .collection('students')
          .where('roll', isEqualTo: roll)
          .limit(1)
          .get();
      if (studentSnap.docs.isNotEmpty) {
        await studentSnap.docs.first.reference.update({
          'todayStatus': 'absent',
        });
      }
    }

    await FirebaseFirestore.instance.collection('activity').add({
      'title':     'Gate approval ${approved ? 'granted' : 'rejected'} by warden',
      'time':      'Just now',
      'type':      'gate_approval',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_wardenHostel == null) return const Scaffold(
      body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A3A5C),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          const Text('Gate Approvals', style: TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold,
            fontSize: 16)),
          Text(_wardenHostel!, style: const TextStyle(
            color: Color(0xFFF0A500), fontSize: 11)),
        ]),
        iconTheme: const IconThemeData(color: Colors.white)),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('leaveRequests')
            .where('block', isEqualTo: _wardenHostel)
            .where('gateStatus', isEqualTo: 'pending_warden_approval')
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(
            child: CircularProgressIndicator());
          if (snap.data!.docs.isEmpty) return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
              Icon(Icons.verified_outlined,
                size: 64, color: Colors.grey),
              SizedBox(height: 12),
              Text('No pending gate approvals.',
                style: TextStyle(color: Colors.grey)),
            ]));

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: snap.data!.docs.length,
            itemBuilder: (context, i) {
              final doc = snap.data!.docs[i];
              final d   = doc.data() as Map<String, dynamic>;
              final type = d['approvalType'] ?? '';
              final isLate = type == 'late_return';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFF0A500).withOpacity(0.5)),
                  boxShadow: [BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8)]),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    // Header
                    Row(children: [
                      Container(padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFF8E1),
                          shape: BoxShape.circle),
                        child: const Icon(Icons.warning_amber,
                          color: Color(0xFFF0A500), size: 20)),
                      const SizedBox(width: 10),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                        Text(d['name'] ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
                        Text('Room ${d['room'] ?? ''}',
                          style: const TextStyle(
                            fontSize: 12, color: Colors.grey)),
                      ])),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0A500)
                              .withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12)),
                        child: Text(
                          isLate ? 'Late Return' : 'Expired Leave',
                          style: const TextStyle(
                            color: Color(0xFFF0A500),
                            fontSize: 11,
                            fontWeight: FontWeight.bold))),
                    ]),
                    const SizedBox(height: 12),

                    // Leave details
                    _detailRow('Leave Period',
                      '${d['from']} → ${d['to']}'),
                    _detailRow('Reason', d['reason'] ?? ''),
                    _detailRow('Scanned by Guard',
                      '${d['guardName']} at '
                      '${d['guardScanTime']} on '
                      '${d['guardScanDate']}'),

                    // Parent info
                    if ((d['parentPhone1'] ?? '').isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F7FA),
                          borderRadius: BorderRadius.circular(8)),
                        child: Row(children: [
                          const Icon(Icons.family_restroom,
                            size: 14, color: Color(0xFF1A3A5C)),
                          const SizedBox(width: 6),
                          Expanded(child: Text(
                            '${d['parentName'] ?? ''} '
                            '(${d['parentRelation'] ?? ''}) — '
                            '${d['parentPhone1']}',
                            style: const TextStyle(fontSize: 12))),
                        ])),
                    ],
                    const SizedBox(height: 12),

                    // Approve / Reject
                    Row(children: [
                      Expanded(child: ElevatedButton.icon(
                        onPressed: () => _approve(doc.id, false),
                        icon: const Icon(Icons.close,
                          size: 16, color: Colors.white),
                        label: const Text('Reject', style: TextStyle(
                          color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC62828),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8))))),
                      const SizedBox(width: 10),
                      Expanded(child: ElevatedButton.icon(
                        onPressed: () => _approve(doc.id, true),
                        icon: const Icon(Icons.check,
                          size: 16, color: Colors.white),
                        label: const Text('Approve', style: TextStyle(
                          color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8))))),
                    ]),
                  ])));
            });
        }),
    );
  }

  Widget _detailRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start,
      children: [
      Text('$label: ', style: const TextStyle(
        fontSize: 12, fontWeight: FontWeight.w600,
        color: Color(0xFF1A3A5C))),
      Expanded(child: Text(value, style: const TextStyle(
        fontSize: 12, color: Colors.black87))),
    ]));
}