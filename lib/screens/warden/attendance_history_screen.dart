import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/tenant.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  final String hostelBlock;
  const AttendanceHistoryScreen({super.key, required this.hostelBlock});
  @override
  State<AttendanceHistoryScreen> createState() => _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  String? _selectedKey;

  Color _statusColor(String s) => s == 'present'
      ? const Color(0xFF2E7D32)
      : s == 'leave' ? const Color(0xFFF0A500) : const Color(0xFFC62828);
  Color _statusBg(String s) => s == 'present'
      ? const Color(0xFFE8F5E9)
      : s == 'leave' ? const Color(0xFFFFF8E1) : const Color(0xFFFFEBEE);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A3A5C),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Attendance History', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          Text(widget.hostelBlock, style: const TextStyle(color: Color(0xFFF0A500), fontSize: 11)),
        ]),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: Tenant.col('attendanceHistory')
            .where('hostelBlock', isEqualTo: widget.hostelBlock)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (snap.hasData == false) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF1A3A5C)));
          }
          if (snap.data!.docs.isEmpty) {
            return const Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.history, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No attendance history yet.', style: TextStyle(color: Colors.grey, fontSize: 15)),
                SizedBox(height: 8),
                Text('Submit attendance to build history.', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ]));
          }
          final docs = snap.data!.docs;
          return Column(children: [
            Container(color: Colors.white, padding: const EdgeInsets.all(16),
              child: Row(children: [
                const Icon(Icons.calendar_month, color: Color(0xFF1A3A5C), size: 18),
                const SizedBox(width: 8),
                Text(docs.length.toString() + ' records found',
                    style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A3A5C))),
              ])),
            const Divider(height: 1),
            Expanded(child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: docs.length,
              itemBuilder: (context, i) {
                final d = docs[i].data() as Map<String, dynamic>;
                final date = d['date'] ?? '';
                final present = d['presentCount'] ?? 0;
                final absent = d['absentCount'] ?? 0;
                final leave = d['leaveCount'] ?? 0;
                final total = d['totalStudents'] ?? 0;
                final records = (d['records'] as List<dynamic>? ?? []);
                final key = date + docs[i].id;
                final isExpanded = _selectedKey == key;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
                  child: Column(children: _buildCard(date, present, absent, leave, total, records, key, isExpanded)));
              })),
          ]);
        }),
    );
  }

  List<Widget> _buildCard(String date, int present, int absent, int leave,
      int total, List<dynamic> records, String key, bool isExpanded) {
    final children = <Widget>[
      InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => setState(() => _selectedKey = isExpanded ? null : key),
        child: Padding(padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF1A3A5C).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.calendar_today, color: Color(0xFF1A3A5C), size: 18)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(date, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1A3A5C))),
              Text('Total: ' + total.toString() + ' students', style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ])),
            _miniChip(present.toString() + ' P', const Color(0xFF2E7D32)),
            const SizedBox(width: 4),
            _miniChip(absent.toString() + ' A', const Color(0xFFC62828)),
            const SizedBox(width: 4),
            _miniChip(leave.toString() + ' L', const Color(0xFFF0A500)),
            const SizedBox(width: 8),
            Icon(isExpanded ? Icons.expand_less : Icons.expand_more, color: Colors.grey),
          ]))),
    ];

    if (isExpanded) {
      children.add(const Divider(height: 1));
      children.add(Container(
        color: const Color(0xFF1A3A5C).withOpacity(0.05),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: const Row(children: [
          Expanded(flex: 3, child: Text('Name', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1A3A5C)))),
          Expanded(flex: 2, child: Text('Roll', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1A3A5C)))),
          Expanded(flex: 1, child: Text('Room', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1A3A5C)))),
          SizedBox(width: 60, child: Text('Status', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1A3A5C)))),
        ])));

      for (final r in records) {
        final rec = r as Map<String, dynamic>;
        final status = rec['status'] ?? 'absent';
        children.add(Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1)))),
          child: Row(children: [
            Expanded(flex: 3, child: Text(rec['name'] ?? '',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis)),
            Expanded(flex: 2, child: Text(rec['roll'] ?? '',
                style: const TextStyle(fontSize: 11, color: Colors.grey))),
            Expanded(flex: 1, child: Text(rec['room'] ?? '',
                style: const TextStyle(fontSize: 11, color: Colors.grey))),
            SizedBox(width: 60, child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(color: _statusBg(status), borderRadius: BorderRadius.circular(8)),
              child: Text(
                status[0].toUpperCase() + status.substring(1),
                textAlign: TextAlign.center,
                style: TextStyle(color: _statusColor(status), fontSize: 10, fontWeight: FontWeight.bold)))),
          ])));
      }
      children.add(const SizedBox(height: 8));
    }
    return children;
  }

  Widget _miniChip(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
    decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
    child: Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)));
}