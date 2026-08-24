import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../role_select_screen.dart';

class StudentProfileScreen extends StatelessWidget {
  final Map<String, dynamic> studentData;
  final String studentId;
  const StudentProfileScreen({
    super.key,
    required this.studentData,
    required this.studentId,
  });

  @override
  Widget build(BuildContext context) {
    final name     = studentData['name']     ?? '';
    final roll     = studentData['roll']     ?? '';
    final room     = studentData['room']     ?? '';
    final block    = studentData['block']    ?? '';
    final course   = studentData['course']   ?? '';
    final phone    = studentData['phone']    ?? '';
    final email    = studentData['email']    ?? '';
    final pName    = studentData['parentName']     ?? '';
    final pRel     = studentData['parentRelation'] ?? '';
    final pPhone1  = studentData['parentPhone1']   ?? '';
    final pPhone2  = studentData['parentPhone2']   ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A3A5C),
        title: const Text('My Profile',
          style: TextStyle(color: Colors.white,
            fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [

          // ── Avatar + Name ─────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [
                Color(0xFF1A3A5C), Color(0xFF2D5F8A)]),
              borderRadius: BorderRadius.circular(16)),
            child: Column(children: [
              CircleAvatar(radius: 40,
                backgroundColor: const Color(0xFFF0A500),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'S',
                  style: const TextStyle(fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A3A5C)))),
              const SizedBox(height: 12),
              Text(name,
                style: const TextStyle(fontSize: 20,
                  fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 4),
              Text('$roll  •  Room $room',
                style: const TextStyle(
                  color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0A500).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20)),
                child: Text(block,
                  style: const TextStyle(
                    color: Color(0xFFF0A500),
                    fontSize: 12, fontWeight: FontWeight.w600))),
            ])),
          const SizedBox(height: 16),

          // ── Student Details Card ──────────────────────────
          _card(
            title: 'Student Details',
            icon: Icons.school,
            color: const Color(0xFF1565C0),
            rows: [
              _rowData('Roll Number', roll, Icons.badge_outlined),
              _rowData('Room', room, Icons.door_back_door_outlined),
              _rowData('Hostel Block', block, Icons.home_work_outlined),
              if (course.isNotEmpty)
                _rowData('Course', course, Icons.school_outlined),
              if (phone.isNotEmpty)
                _rowData('Phone', phone, Icons.phone_outlined),
              if (email.isNotEmpty)
                _rowData('Email', email, Icons.email_outlined),
            ]),
          const SizedBox(height: 12),

          // ── Parent / Guardian Card ────────────────────────
          if (pName.isNotEmpty || pPhone1.isNotEmpty)
            _card(
              title: 'Parent / Guardian Details',
              icon: Icons.family_restroom,
              color: const Color(0xFFF0A500),
              rows: [
                if (pName.isNotEmpty)
                  _rowData('Name', pName, Icons.person_outline),
                if (pRel.isNotEmpty)
                  _rowData('Relation', pRel,
                    Icons.family_restroom_outlined),
                if (pPhone1.isNotEmpty)
                  _rowData('Primary Phone', pPhone1,
                    Icons.phone, isPhone: true),
                if (pPhone2.isNotEmpty)
                  _rowData('Alternate Phone', pPhone2,
                    Icons.phone_outlined, isPhone: true),
              ]),
          const SizedBox(height: 24),

          // ── Logout ───────────────────────────────────────
          SizedBox(width: double.infinity, height: 50,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.logout, color: Colors.white),
              label: const Text('Logout',
                style: TextStyle(color: Colors.white,
                  fontSize: 15, fontWeight: FontWeight.bold)),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RoleSelectScreen()),
                    (_) => false);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC62828),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12))))),
          const SizedBox(height: 16),
        ])),
    );
  }

  Widget _card({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> rows,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 8)]),
      child: Column(children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(14),
              topRight: Radius.circular(14))),
          child: Row(children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color, fontSize: 14)),
          ])),
        // Rows
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(children: rows)),
      ]));
  }

  Widget _rowData(String label, String value,
      IconData icon, {bool isPhone = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFF1A3A5C).withOpacity(0.08),
            shape: BoxShape.circle),
          child: Icon(icon,
            color: const Color(0xFF1A3A5C), size: 14)),
        const SizedBox(width: 10),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Text(label, style: const TextStyle(
            fontSize: 10, color: Colors.grey)),
          Text(value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isPhone
                  ? const Color(0xFF1565C0)
                  : Colors.black87)),
        ])),
      ]));
  }
}