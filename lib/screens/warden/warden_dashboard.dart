import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../role_select_screen.dart';
import 'attendance_screen.dart';
import 'complaints_screen.dart';
import 'leave_requests_screen.dart';
import '../shared/mess_menu_screen.dart';
import 'notices_screen.dart';
import 'students_screen.dart';
import '../../utils/warden_helper.dart';
import '../../widgets/notification_bell.dart';
import 'activity_screen.dart';
import 'import_students_screen.dart';
import 'gate_approvals_screen.dart';
import 'device_approvals_screen.dart';

class WardenDashboard extends StatefulWidget {
  const WardenDashboard({super.key});
  @override
  State<WardenDashboard> createState() => _WardenDashboardState();
}

class _WardenDashboardState extends State<WardenDashboard> {
  String? _wardenHostel;
  String? _wardenName;

  @override
  void initState() {
    super.initState();
    _loadWarden();
  }

  Future<void> _loadWarden() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('wardens').doc(uid).get();
    if (!doc.exists) return;
    setState(() {
      _wardenHostel = doc.data()?['hostelBlock'] ?? '';
      _wardenName   = doc.data()?['name'] ?? 'Warden';
    });
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) Navigator.pushReplacement(context,
      MaterialPageRoute(builder: (_) => const RoleSelectScreen()));
  }

  @override
  Widget build(BuildContext context) {
    if (_wardenHostel == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F7FA),
        body: Center(child: CircularProgressIndicator(
          color: Color(0xFF1A3A5C))));
    }

    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A3A5C),
        automaticallyImplyLeading: false,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          const Text('Warden Dashboard',
            style: TextStyle(color: Colors.white,
              fontWeight: FontWeight.bold, fontSize: 16)),
          Text(_wardenHostel ?? '',
            style: const TextStyle(
              color: Color(0xFFF0A500), fontSize: 11)),
        ]),
        actions: [
          NotificationBell(userId: uid),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout),
        ]),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [

          // ── Welcome Card ─────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [
                Color(0xFF1A3A5C), Color(0xFF2D5F8A)]),
              borderRadius: BorderRadius.circular(16)),
            child: Row(children: [
              CircleAvatar(radius: 28,
                backgroundColor: const Color(0xFFF0A500),
                child: const Icon(Icons.admin_panel_settings,
                  color: Color(0xFF1A3A5C), size: 28)),
              const SizedBox(width: 16),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Text('Welcome, $_wardenName! 👋',
                  style: const TextStyle(fontSize: 18,
                    fontWeight: FontWeight.bold, color: Colors.white)),
                Text(_wardenHostel ?? '',
                  style: const TextStyle(
                    color: Colors.white70, fontSize: 12)),
              ])),
            ])),
          const SizedBox(height: 20),

          // ── Stats Row ────────────────────────────────────────────
          Row(children: [
            // Total Students
            Expanded(child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('students')
                  .where('block', isEqualTo: _wardenHostel)
                  .snapshots(),
              builder: (context, snap) => _statCard(
                'Students',
                '${snap.data?.docs.length ?? 0}',
                Icons.people, const Color(0xFF1565C0)))),
            const SizedBox(width: 12),
            // Pending Leaves
            Expanded(child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('leaveRequests')
                  .where('block', isEqualTo: _wardenHostel)
                  .where('status', isEqualTo: 'Pending')
                  .snapshots(),
              builder: (context, snap) => _statCard(
                'Pending Leaves',
                '${snap.data?.docs.length ?? 0}',
                Icons.event_note, const Color(0xFFF0A500)))),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            // Open Complaints
            Expanded(child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('complaints')
                  .where('hostelBlock', isEqualTo: _wardenHostel)
                  .where('status', isEqualTo: 'Pending')
                  .snapshots(),
              builder: (context, snap) => _statCard(
                'Open Complaints',
                '${snap.data?.docs.length ?? 0}',
                Icons.report_outlined, const Color(0xFFC62828)))),
            const SizedBox(width: 12),
            // Students Out
            Expanded(child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('leaveRequests')
                  .where('block', isEqualTo: _wardenHostel)
                  .where('gateStatus', isEqualTo: 'out')
                  .snapshots(),
              builder: (context, snap) => _statCard(
                'Students Out',
                '${snap.data?.docs.length ?? 0}',
                Icons.directions_walk, const Color(0xFF2E7D32)))),
          ]),
          const SizedBox(height: 24),

          // ── Quick Actions ────────────────────────────────────────
          const Text('Quick Actions',
            style: TextStyle(fontSize: 15,
              fontWeight: FontWeight.bold, color: Color(0xFF1A3A5C))),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.95,
            children: [
              _actionCard('Attendance', Icons.how_to_reg,
                const Color(0xFF1565C0), () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) =>
                    const AttendanceScreen()))),
              _actionCard('Leave Requests', Icons.event_note,
                const Color(0xFFF0A500), () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) =>
                    const LeaveRequestsScreen()))),
              _actionCard('Complaints', Icons.report_outlined,
                const Color(0xFFC62828), () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) =>
                    const ComplaintsScreen()))),
              _actionCard('Mess Menu', Icons.restaurant,
                const Color(0xFF2E7D32), () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) =>
                    const MessMenuScreen(isWarden: true)))),
              _actionCard('Notices', Icons.campaign,
                const Color(0xFF6A1B9A), () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) =>
                    const NoticesScreen()))),
              _actionCard('Students', Icons.people,
                const Color(0xFF00838F), () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) =>
                    const StudentsScreen()))),
              _actionCard('Import Students', Icons.upload_file,
                const Color(0xFF00897B), () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) =>
                    const ImportStudentsScreen()))),
              _actionCard('Device Approvals', Icons.smartphone,
                const Color(0xFF7B1FA2), () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) =>
                    const DeviceApprovalsScreen()))),
              _actionCard('Gate Approvals', Icons.verified_user,
                const Color(0xFFF0A500), () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) =>
                    const GateApprovalsScreen()))),
            ]),
          const SizedBox(height: 24),

          // ── Recent Activity ──────────────────────────────────────
          const Text('Recent Activity',
            style: TextStyle(fontSize: 15,
              fontWeight: FontWeight.bold, color: Color(0xFF1A3A5C))),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('activity')
                .orderBy('createdAt', descending: true)
                .limit(8)
                .snapshots(),
            builder: (context, snap) {
              if (!snap.hasData || snap.data!.docs.isEmpty) {
                return const Text('No recent activity.',
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
                      const Icon(Icons.circle,
                        size: 8, color: Color(0xFF1A3A5C)),
                      const SizedBox(width: 10),
                      Expanded(child: Text(d['title'] ?? '',
                        style: const TextStyle(fontSize: 12))),
                      Text(d['time'] ?? '',
                        style: const TextStyle(
                          fontSize: 10, color: Colors.grey)),
                    ]));
                }).toList());
            }),
            TextButton.icon(
            onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ActivityScreen())),
            icon: const Icon(Icons.open_in_new,
              size: 14, color: Color(0xFF1A3A5C)),
            label: const Text('View All Activities',
              style: TextStyle(color: Color(0xFF1A3A5C),
                fontSize: 12))),
        ])),
    );
  }
  // ── Stat Card Widget ─────────────────────────────────────────────
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
        Text(value, style: TextStyle(fontSize: 24,
          fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(
          fontSize: 11, color: Colors.grey)),
      ]));
  }

  // ── Action Card Widget ───────────────────────────────────────────
Widget _actionCard(String label, IconData icon,
      Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8)]),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24)),
          const SizedBox(height: 8),
          Text(label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A3A5C))),
        ])));
  }
}