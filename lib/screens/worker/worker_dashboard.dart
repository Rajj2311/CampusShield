import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/image_upload_helper.dart';
import '../role_select_screen.dart';
import '../../utils/tenant.dart';

class WorkerDashboard extends StatefulWidget {
  final Map<String, dynamic> workerData;
  final String workerId;
  const WorkerDashboard({super.key, required this.workerData, required this.workerId});
  @override
  State<WorkerDashboard> createState() => _WorkerDashboardState();
}

class _WorkerDashboardState extends State<WorkerDashboard> {
  String _filter = 'All';

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) Navigator.pushReplacement(context,
      MaterialPageRoute(builder: (_) => const RoleSelectScreen()));
  }

  // ── Accept Complaint ─────────────────────────────────────────────────
  Future<void> _acceptComplaint(String docId) async {
    await Tenant.col('complaints').doc(docId).update({
      'status': 'In Progress',
      'acceptedAt': FieldValue.serverTimestamp(),
    });
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Complaint accepted! Start working.'),
        backgroundColor: Color(0xFF2E7D32)));
  }

  // ── Mark Resolved with Proof Photo ───────────────────────────────────
  Future<void> _markResolved(String docId) async {
    // Photo is optional; it becomes mandatory once Storage is enabled
    await Tenant.col('complaints').doc(docId).update({
  'afterPhotoUrl': null,

  // Complaint resolved again
  'status': 'Resolved',

  // IMPORTANT: Reset student verification every time
  'studentVerified': null,

  'resolvedAt': FieldValue.serverTimestamp(),
  'resolvedByWorkerId': widget.workerId,
  'resolvedByWorkerName': widget.workerData['name'] ?? '',
});
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Marked as Resolved! Student will verify.'),
        backgroundColor: Color(0xFF2E7D32)));
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

  @override
  Widget build(BuildContext context) {
    final hostel   = 'All Hostels';
    final category = widget.workerData['category'] ?? '';
    final icon     = Tenant.workerCategories
        .firstWhere((c) => c['label'] == category, orElse: () => {'icon': '🔩'})['icon'];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(backgroundColor: const Color(0xFF1A3A5C), automaticallyImplyLeading: false,
        title: Row(children: [
          Text('$icon', style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.workerData['name'] ?? 'Worker',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            Text('$category • All Hostels',
              style: const TextStyle(color: Color(0xFFF0A500), fontSize: 10)),
          ]),
        ]),
        actions: [
          IconButton(icon: const Icon(Icons.logout, color: Colors.white), onPressed: _logout),
        ]),
      body: Column(children: [
        // Stats bar
        StreamBuilder<QuerySnapshot>(
          stream: Tenant.col('complaints')
              .where('assignedWorkerId', isEqualTo: widget.workerId).snapshots(),
          builder: (context, snap) {
            final all    = snap.data?.docs ?? [];
            final pending    = all.where((d) => (d.data() as Map)['status'] == 'Pending').length;
            final inProgress = all.where((d) => (d.data() as Map)['status'] == 'In Progress').length;
            final resolved   = all.where((d) => (d.data() as Map)['status'] == 'Resolved').length;
            final closed     = all.where((d) => (d.data() as Map)['status'] == 'Closed').length;
            return Container(color: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                _statChip('Pending',     pending,    const Color(0xFF9E9E9E)),
                _statChip('In Progress', inProgress, const Color(0xFFF57F17)),
                _statChip('Resolved',    resolved,   const Color(0xFF1565C0)),
                _statChip('Closed',      closed,     const Color(0xFF2E7D32)),
              ]));
          }),

        // Filter tabs
        Container(color: Colors.white, padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
          child: SingleChildScrollView(scrollDirection: Axis.horizontal,
            child: Row(children: ['All', 'Pending', 'In Progress', 'Resolved', 'Reopened'].map((f) {
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
                    fontSize: 12, fontWeight: FontWeight.w600))));
            }).toList()))),
        const Divider(height: 1),

        // Complaints list
        Expanded(child: StreamBuilder<QuerySnapshot>(
          stream: Tenant.col('complaints')
              .where('assignedWorkerId', isEqualTo: widget.workerId)
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            var docs = snap.data!.docs;
            if (_filter != 'All') {
              docs = docs.where((d) => (d.data() as Map)['status'] == _filter).toList();
            }
            if (docs.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('$icon', style: const TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Text(_filter == 'All' ? 'No complaints assigned yet.' : 'No $_filter complaints.',
                style: const TextStyle(color: Colors.grey, fontSize: 14)),
            ]));

            return ListView.builder(
              padding: const EdgeInsets.all(12), itemCount: docs.length,
              itemBuilder: (context, i) {
                final doc    = docs[i];
                final d      = doc.data() as Map<String, dynamic>;
                final status = d['status'] ?? 'Pending';
                final color  = _statusColor(status);

                return Container(margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)]),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    // Header
                    Container(padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: color.withOpacity(0.08),
                        borderRadius: const BorderRadius.only(topLeft: Radius.circular(14), topRight: Radius.circular(14))),
                      child: Row(children: [
                        Text(Tenant.workerCategories.firstWhere(
                          (c) => c['label'] == d['category'], orElse: () => {'icon': '🔩'})['icon'] ?? '🔩',
                          style: const TextStyle(fontSize: 22)),
                        const SizedBox(width: 10),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(d['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text('${d['studentName'] ?? ''} • Room ${d['room'] ?? ''} • ${d['hostelBlock'] ?? ''}',
                            style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ])),
                        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                          child: Text(status, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold))),
                      ])),

                    Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(d['description'] ?? '', style: const TextStyle(fontSize: 13)),
                      const SizedBox(height: 12),

                      // Before photo
                      if (d['beforePhotoUrl'] != null) ...[
                        const Text('📸 Issue Photo:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
                        const SizedBox(height: 6),
                        ClipRRect(borderRadius: BorderRadius.circular(10),
                          child: Image.network(d['beforePhotoUrl'], height: 160, width: double.infinity,
                            fit: BoxFit.cover, loadingBuilder: (_, child, prog) =>
                              prog == null ? child : const Center(child: CircularProgressIndicator()))),
                        const SizedBox(height: 12),
                      ],

                      // After photo (if already resolved)
                      if (d['afterPhotoUrl'] != null) ...[
                        const Text('✅ Proof Photo (After Fix):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
                        const SizedBox(height: 6),
                        ClipRRect(borderRadius: BorderRadius.circular(10),
                          child: Image.network(d['afterPhotoUrl'], height: 160, width: double.infinity,
                            fit: BoxFit.cover)),
                        const SizedBox(height: 12),
                      ],

                      // Reopened alert
                      if (status == 'Reopened') ...[
                        Container(padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(8)),
                          child: const Row(children: [
                            Icon(Icons.warning_amber, color: Color(0xFFC62828), size: 16), SizedBox(width: 8),
                            Expanded(child: Text('Student reported issue not fixed. Please revisit.',
                              style: TextStyle(color: Color(0xFFC62828), fontSize: 12, fontWeight: FontWeight.w500))),
                          ])),
                        const SizedBox(height: 10),
                      ],

                      // Action buttons
                      if (status == 'Pending') SizedBox(width: double.infinity, height: 44,
                        child: ElevatedButton.icon(
                          onPressed: () => _acceptComplaint(doc.id),
                          icon: const Icon(Icons.play_circle_outline, color: Colors.white),
                          label: const Text('ACCEPT & START WORK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF57F17),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))))),

                      if (status == 'In Progress' || status == 'Reopened') SizedBox(width: double.infinity, height: 44,
                        child: ElevatedButton.icon(
                          onPressed: () => _markResolved(doc.id),
                          icon: const Icon(Icons.camera_alt, color: Colors.white),
                          label: const Text('UPLOAD PROOF & MARK RESOLVED',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))))),

                      if (status == 'Resolved') Container(padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(8)),
                        child: const Row(children: [
                          Icon(Icons.hourglass_top, color: Color(0xFF1565C0), size: 16), SizedBox(width: 8),
                          Text('Waiting for student to verify...', style: TextStyle(color: Color(0xFF1565C0), fontSize: 12)),
                        ])),

                      if (status == 'Closed') Container(padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(8)),
                        child: const Row(children: [
                          Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 16), SizedBox(width: 8),
                          Text('Complaint Closed — Student Verified ✅', style: TextStyle(color: Color(0xFF2E7D32), fontSize: 12)),
                        ])),
                    ])),
                  ]));
              });
          })),
      ]),
    );
  }

  Widget _statChip(String label, int count, Color color) => Column(children: [
    Text('$count', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
    Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey)),
  ]);
}