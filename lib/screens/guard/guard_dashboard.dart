import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../role_select_screen.dart';
import 'guard_scan_screen.dart';
import 'gate_history_screen.dart';

class GuardDashboard extends StatefulWidget {
  final Map<String, dynamic> guardData;
  const GuardDashboard({super.key, required this.guardData});
  @override
  State<GuardDashboard> createState() => _GuardDashboardState();
}

class _GuardDashboardState extends State<GuardDashboard> {
  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) Navigator.pushReplacement(context,
      MaterialPageRoute(builder: (_) => const RoleSelectScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final hostelBlock =
        widget.guardData['hostelBlock'] ?? '';
    final guardName  = widget.guardData['name'] ?? 'Guard';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A3A5C),
        automaticallyImplyLeading: false,
        title: Row(children: const [
          Icon(Icons.security, color: Color(0xFFF0A500)),
          SizedBox(width: 8),
          Text('Chowkidar', style: TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold)),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            tooltip: 'Gate History',
            onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => GateHistoryScreen(
                hostelBlock: hostelBlock)))),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout),
        ]),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [

          // ── Welcome Card ─────────────────────────────────
          Container(width: double.infinity, padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A3A5C), Color(0xFF2D5F8A)]),
              borderRadius: BorderRadius.circular(16)),
            child: Row(children: [
              CircleAvatar(radius: 28,
                backgroundColor: const Color(0xFFF0A500),
                child: const Icon(Icons.security,
                  color: Color(0xFF1A3A5C), size: 28)),
              const SizedBox(width: 16),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Text('Welcome, $guardName! 🛡️',
                  style: const TextStyle(fontSize: 18,
                    fontWeight: FontWeight.bold, color: Colors.white)),
                Text(hostelBlock.isNotEmpty
                    ? hostelBlock : 'Guard',
                  style: const TextStyle(
                    color: Colors.white70, fontSize: 12)),
              ])),
            ])),
          const SizedBox(height: 20),

          // ── Stats ─────────────────────────────────────────
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('leaveRequests')
                .where('gateStatus', isEqualTo: 'out')
                .snapshots(),
            builder: (context, outSnap) {
              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('leaveRequests')
                    .where('gateStatus', isEqualTo: 'completed')
                    .snapshots(),
                builder: (context, doneSnap) {
                  final outCount  = outSnap.data?.docs.length ?? 0;
                  final doneCount = doneSnap.data?.docs.length ?? 0;
                  return Row(children: [
                    Expanded(child: _statCard(
                      'Currently Out', '$outCount',
                      Icons.directions_walk,
                      const Color(0xFFF0A500))),
                    const SizedBox(width: 12),
                    Expanded(child: _statCard(
                      'Returned Today', '$doneCount',
                      Icons.check_circle,
                      const Color(0xFF2E7D32))),
                  ]);
                });
            }),
          const SizedBox(height: 20),

          // ── Scan Button ───────────────────────────────────
          SizedBox(width: double.infinity, height: 64,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) =>
                  GuardScanScreen(guardName: guardName))),
              icon: const Icon(Icons.qr_code_scanner,
                color: Colors.white, size: 26),
              label: const Text('SCAN QR CODE', style: TextStyle(
                fontSize: 17, fontWeight: FontWeight.bold,
                color: Colors.white, letterSpacing: 1)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A3A5C),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16))))),
          const SizedBox(height: 24),

          // ── Students Currently Out ────────────────────────
          const Text('Students Currently Out', style: TextStyle(
            fontSize: 15, fontWeight: FontWeight.bold,
            color: Color(0xFF1A3A5C))),
          const SizedBox(height: 10),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('leaveRequests')
                .where('gateStatus', isEqualTo: 'out')
                .snapshots(),
            builder: (context, snap) {
              if (!snap.hasData || snap.data!.docs.isEmpty) {
                return const Text('No students are currently out.',
                  style: TextStyle(color: Colors.grey, fontSize: 13));
              }
              return Column(
                children: snap.data!.docs.map((doc) {
                  final d = doc.data() as Map<String, dynamic>;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 6)]),
                    child: Row(children: [
                      Container(padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0A500).withOpacity(0.15),
                          shape: BoxShape.circle),
                        child: const Icon(Icons.directions_walk,
                          color: Color(0xFFF0A500), size: 18)),
                      const SizedBox(width: 10),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                        Text(d['name'] ?? '', style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                        Text(
                          'Room ${d['room'] ?? ''}  •  '
                          'Exit: ${d['exitTime'] ?? ''}',
                          style: const TextStyle(
                            fontSize: 11, color: Colors.grey)),
                      ])),
                    ]));
                }).toList());
            }),
          const SizedBox(height: 20),

          // ── Recent Gate Activity ──────────────────────────
          const Text('Recent Gate Activity', style: TextStyle(
            fontSize: 15, fontWeight: FontWeight.bold,
            color: Color(0xFF1A3A5C))),
          const SizedBox(height: 10),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('activity')
                .orderBy('createdAt', descending: true)
                .limit(10)
                .snapshots(),
            builder: (context, snap) {
              if (!snap.hasData || snap.data!.docs.isEmpty) {
                return const Text('No activity yet.',
                  style: TextStyle(color: Colors.grey, fontSize: 13));
              }
              final gateActivity = snap.data!.docs.where((doc) {
                final d = doc.data() as Map<String, dynamic>;
                return (d['title'] ?? '').toString()
                    .contains('Gate');
              }).toList();
              if (gateActivity.isEmpty) return const Text(
                'No gate activity yet.',
                style: TextStyle(color: Colors.grey, fontSize: 13));
              return Column(
                children: gateActivity.map((doc) {
                  final d = doc.data() as Map<String, dynamic>;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 6)]),
                    child: Row(children: [
                      const Icon(Icons.history,
                        color: Color(0xFF1A3A5C), size: 18),
                      const SizedBox(width: 10),
                      Expanded(child: Text(d['title'] ?? '',
                        style: const TextStyle(fontSize: 12))),
                    ]));
                }).toList());
            }),
        ])),
    );
  }

  Widget _statCard(String label, String value,
      IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.05), blurRadius: 8)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontSize: 22,
          fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(
          fontSize: 11, color: Colors.grey)),
      ]));
  }
}