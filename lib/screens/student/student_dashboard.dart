import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../role_select_screen.dart';
import 'student_attendance_screen.dart';
import 'student_leave_screen.dart';
import 'student_complaints_screen.dart';
import 'student_notices_screen.dart';
import '../shared/mess_menu_screen.dart';
import 'student_profile_screen.dart';
import '../../widgets/notification_bell.dart';
import '../../utils/tenant.dart';

class StudentDashboard extends StatefulWidget {
  final Map<String, dynamic> studentData;
  final String studentId;
  const StudentDashboard({
    super.key,
    required this.studentData,
    required this.studentId,
  });
  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _currentIndex = 0;

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const RoleSelectScreen()),
      );
    }
  }

  void _showMoreMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.restaurant, color: Color(0xFF1A3A5C)),
              title: const Text('Mess Menu'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MessMenuScreen(isWarden: false)));
              }),
            ListTile(
              leading: const Icon(Icons.campaign, color: Color(0xFF1A3A5C)),
              title: const Text('Notices'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StudentNoticesScreen(
                      studentData: widget.studentData)));
              }),
            ListTile(
              leading: const Icon(Icons.person_outline, color: Color(0xFF1A3A5C)),
              title: const Text('My Profile'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StudentProfileScreen(
                      studentData: widget.studentData,
                      studentId: widget.studentId)));
              }),
            ListTile(
              leading: const Icon(Icons.logout, color: Color(0xFFC62828)),
              title: const Text('Logout',
                style: TextStyle(color: Color(0xFFC62828))),
              onTap: () {
                Navigator.pop(context);
                _logout();
              }),
            const SizedBox(height: 8),
          ])));
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    final List<Widget> screens = [
      _HomeTab(
        studentData: widget.studentData,
        studentId: widget.studentId),
      StudentAttendanceScreen(
        studentData: widget.studentData,
        studentId: widget.studentId),
      StudentLeaveScreen(studentData: widget.studentData),
      StudentComplaintsScreen(studentData: widget.studentData),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A3A5C),
        automaticallyImplyLeading: false,
        title: Row(children: [
          const Icon(Icons.security, color: Color(0xFFF0A500), size: 22),
          const SizedBox(width: 8),
          const Text('CampusShield',
            style: TextStyle(color: Colors.white,
              fontWeight: FontWeight.bold, fontSize: 18)),
        ]),
        actions: [
          NotificationBell(userId: uid),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () => _showMoreMenu(context)),
        ]),
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF1A3A5C),
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.how_to_reg_outlined),
            activeIcon: Icon(Icons.how_to_reg),
            label: 'Attendance'),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_note_outlined),
            activeIcon: Icon(Icons.event_note),
            label: 'Leave'),
          BottomNavigationBarItem(
            icon: Icon(Icons.report_outlined),
            activeIcon: Icon(Icons.report),
            label: 'Complaints'),
        ]),
    );
  }
}

// ── Home Tab ──────────────────────────────────────────────────────────────────
class _HomeTab extends StatelessWidget {
  final Map<String, dynamic> studentData;
  final String studentId;
  const _HomeTab({required this.studentData, required this.studentId});

  @override
  Widget build(BuildContext context) {
    final name  = studentData['name']  ?? 'Student';
    final roll  = studentData['roll']  ?? '';
    final room  = studentData['room']  ?? '';
    final block = studentData['block'] ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Welcome Card ─────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A3A5C), Color(0xFF2D5F8A)]),
              borderRadius: BorderRadius.circular(16)),
            child: Row(children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: const Color(0xFFF0A500),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'S',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A3A5C)))),
              const SizedBox(width: 16),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Hi, $name! 👋',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
                  Text('$roll  •  Room $room  •  $block',
                    style: const TextStyle(
                      color: Colors.white70, fontSize: 11)),
                ])),
            ])),
          const SizedBox(height: 20),

          // ── Today's Attendance ───────────────────────────────────
          StreamBuilder<DocumentSnapshot>(
            stream: Tenant.col('students').doc(studentId).snapshots(),
            builder: (context, snap) {
              final status = (snap.data?.data()
                  as Map<String, dynamic>?)?['todayStatus'] ?? 'absent';
              final color = status == 'present'
                  ? const Color(0xFF2E7D32)
                  : status == 'leave'
                      ? const Color(0xFFF0A500)
                      : const Color(0xFFC62828);
              final icon = status == 'present'
                  ? Icons.check_circle
                  : status == 'leave'
                      ? Icons.beach_access
                      : Icons.cancel;
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.3))),
                child: Row(children: [
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: 10),
                  const Text("Today's Attendance: ",
                    style: TextStyle(fontSize: 13)),
                  Text(
                    status[0].toUpperCase() + status.substring(1),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color, fontSize: 13)),
                ]));
            }),
          const SizedBox(height: 20),

          // ── Today's Mess Menu ────────────────────────────────────
          const Text("Today's Mess Menu",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A3A5C))),
          const SizedBox(height: 10),
          StreamBuilder<DocumentSnapshot>(
            stream: () {
              final n = DateTime.now();
              final dayIndex = n.weekday - 1;
              return Tenant.col('messMenuDays')
                  .doc('$dayIndex')
                  .snapshots();
            }(),
            builder: (context, snap) {
              final data =
                  snap.data?.data() as Map<String, dynamic>? ?? {};
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8)]),
                child: Column(children: [
                  _messRow(Icons.free_breakfast, 'Breakfast',
                    data['breakfast'] ?? 'Poha, Tea',
                    const Color(0xFFF57F17)),
                  const Divider(height: 16),
                  _messRow(Icons.lunch_dining, 'Lunch',
                    data['lunch'] ?? 'Dal, Rice, Roti',
                    const Color(0xFF1565C0)),
                  const Divider(height: 16),
                  _messRow(Icons.fastfood, 'Snacks',
                    data['snacks'] ?? 'Samosa, Chai',
                    const Color(0xFF6A1B9A)),
                  const Divider(height: 16),
                  _messRow(Icons.dinner_dining, 'Dinner',
                    data['dinner'] ?? 'Sabzi, Roti, Dal',
                    const Color(0xFF1A3A5C)),
                ]));
            }),
          const SizedBox(height: 20),

          // ── Recent Notices ───────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Recent Notices',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A3A5C))),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StudentNoticesScreen(
                      studentData: studentData))),
                child: const Text('View All',
                  style: TextStyle(
                    color: Color(0xFF1A3A5C), fontSize: 12))),
            ]),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot>(
            stream: Tenant.col('notices')
                .where('hostelBlock', isEqualTo: block)
                .limit(3)
                .snapshots(),
            builder: (context, snap) {
              if (!snap.hasData || snap.data!.docs.isEmpty) {
                return const Text('No notices.',
                  style: TextStyle(color: Colors.grey, fontSize: 13));
              }
              return Column(
                children: snap.data!.docs.map((doc) {
                  final d = doc.data() as Map<String, dynamic>;
                  final isUrgent = d['urgency'] == 'Urgent';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: isUrgent
                          ? Border.all(
                              color: const Color(0xFFC62828)
                                  .withOpacity(0.4))
                          : null,
                      boxShadow: [BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 6)]),
                    child: Row(children: [
                      Icon(
                        isUrgent
                            ? Icons.warning_amber
                            : Icons.campaign,
                        color: isUrgent
                            ? const Color(0xFFC62828)
                            : const Color(0xFF1A3A5C),
                        size: 18),
                      const SizedBox(width: 10),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(d['title'] ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13)),
                          Text(d['body'] ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11, color: Colors.grey)),
                        ])),
                    ]));
                }).toList());
            }),
        ]));
  }

  Widget _messRow(IconData icon, String meal,
      String items, Color color) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 16)),
      const SizedBox(width: 10),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(meal,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color)),
          Text(items,
            style: const TextStyle(
              fontSize: 12, color: Colors.black87)),
        ])),
    ]);
  }
}