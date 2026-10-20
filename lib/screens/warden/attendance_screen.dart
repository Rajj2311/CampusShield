import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'attendance_history_screen.dart';
import '../../utils/tenant.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});
  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  String _selectedBlock = 'All';
  String? _wardenHostel;
  bool _resetDone = false;

  @override
  void initState() {
    super.initState();
    _loadWardenAndReset();
  }

  Future<void> _loadWardenAndReset() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await Tenant.col('wardens').doc(uid).get();
    if (!doc.exists) return;
    final hostel = doc.data()?['hostelBlock'] ?? Tenant.hostels[0];
    setState(() => _wardenHostel = hostel);
    await _dailyReset();
  }

  // ── Daily Reset Logic ───────────────────────────────────────────────
  Future<void> _dailyReset() async {
    final today = _todayStr();
    final resetDoc = await Tenant.col('settings').doc('attendanceReset').get();
    final lastReset = resetDoc.data()?['date'] ?? '';
    if (lastReset == today) {
      setState(() => _resetDone = true);
      return;
    }

    final students = await Tenant.col('students').get();
    final docs = students.docs;

    // ── 500 ki chunks mein batch karo (Firestore limit) ──────────
    const chunkSize = 499;
    for (int i = 0; i < docs.length; i += chunkSize) {
      final chunk = docs.sublist(
        i, (i + chunkSize) > docs.length ? docs.length : i + chunkSize);
      final batch = FirebaseFirestore.instance.batch();
      for (final s in chunk) {
        // Leave pe gaye students ko reset mat karo
        if ((s.data()['todayStatus'] ?? 'absent') != 'leave') {
          batch.update(s.reference, {'todayStatus': 'absent'});
        }
      }
      await batch.commit();
    }

    await Tenant.col('settings')
        .doc('attendanceReset')
        .set({'date': today, 'resetAt': FieldValue.serverTimestamp()});

    setState(() => _resetDone = true);
  }
  String _todayStr() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2,'0')}-${n.day.toString().padLeft(2,'0')}';
  }

  Color _statusColor(String s) => s == 'present'
      ? const Color(0xFF2E7D32)
      : s == 'absent' ? const Color(0xFFC62828) : const Color(0xFFF0A500);
  IconData _statusIcon(String s) => s == 'present'
      ? Icons.check_circle
      : s == 'absent' ? Icons.cancel : Icons.beach_access;

  Future<void> _cycleStatus(DocumentSnapshot doc) async {
    final current = (doc.data() as Map)['todayStatus'] ?? 'absent';
    final next = current == 'present' ? 'absent' : current == 'absent' ? 'leave' : 'present';
    await Tenant.col('students').doc(doc.id).update({'todayStatus': next});
  }

  // ── Submit + Save History ───────────────────────────────────────────
  Future<void> _submitAttendance(BuildContext context, List<DocumentSnapshot> docs) async {
    final today = _todayStr();
    final uid   = FirebaseAuth.instance.currentUser?.uid;

    // Build student-wise records
    final records = docs.map((doc) {
      final d = doc.data() as Map<String, dynamic>;
      return {
        'studentId': doc.id,
        'name': d['name'] ?? '',
        'roll': d['roll'] ?? '',
        'room': d['room'] ?? '',
        'block': d['block'] ?? '',
        'status': d['todayStatus'] ?? 'absent',
      };
    }).toList();

    final present = records.where((r) => r['status'] == 'present').length;
    final absent  = records.where((r) => r['status'] == 'absent').length;
    final leave   = records.where((r) => r['status'] == 'leave').length;

    // Save to attendanceHistory
    await Tenant.col('attendanceHistory').add({
      'date': today,
      'hostelBlock': _wardenHostel ?? 'Unknown',
      'submittedBy': uid,
      'totalStudents': docs.length,
      'presentCount': present,
      'absentCount': absent,
      'leaveCount': leave,
      'records': records,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await Tenant.col('activity').add({
      'title': 'Attendance submitted for ${_wardenHostel ?? 'hostel'} — $present present, $absent absent',
      'time': 'Just now', 'createdAt': FieldValue.serverTimestamp(),
    });

    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Attendance submitted & saved to history!'),
        backgroundColor: Color(0xFF2E7D32)));
  }

  @override
  Widget build(BuildContext context) {
    if (_wardenHostel == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F7FA),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF1A3A5C))));
    }

    Query query = Tenant.col('students')
        .where('block', isEqualTo: _wardenHostel);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A3A5C),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Mark Attendance', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          Text(_wardenHostel!, style: const TextStyle(color: Color(0xFFF0A500), fontSize: 11)),
        ]),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            tooltip: 'View History',
            onPressed: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => AttendanceHistoryScreen(hostelBlock: _wardenHostel!))),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snap.data!.docs;
          final present = docs.where((d) => (d.data() as Map)['todayStatus'] == 'present').length;
          final absent  = docs.where((d) => (d.data() as Map)['todayStatus'] == 'absent').length;
          final leave   = docs.where((d) => (d.data() as Map)['todayStatus'] == 'leave').length;

          return Column(children: [
            // Summary chips
            Container(padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16), color: Colors.white,
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                _chip('Present', present, const Color(0xFF2E7D32)),
                _chip('Absent',  absent,  const Color(0xFFC62828)),
                _chip('Leave',   leave,   const Color(0xFFF0A500)),
                _chip('Total',   docs.length, const Color(0xFF1A3A5C)),
              ])),
            // Today's date banner
            Container(color: const Color(0xFF1A3A5C).withOpacity(0.05),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(children: [
                const Icon(Icons.calendar_today, size: 13, color: Color(0xFF1A3A5C)),
                const SizedBox(width: 6),
                Text('Today: ${_todayStr()}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF1A3A5C), fontWeight: FontWeight.w600)),
                if (!_resetDone) ...[
                  const SizedBox(width: 8),
                  const SizedBox(width: 12, height: 12,
                    child: CircularProgressIndicator(strokeWidth: 1.5, color: Color(0xFFF0A500))),
                  const SizedBox(width: 4),
                  const Text('Resetting...', style: TextStyle(fontSize: 11, color: Color(0xFFF0A500))),
                ],
              ])),
            const Divider(height: 1),
            docs.isEmpty
              ? const Expanded(child: Center(child: Text('No students found in this hostel.',
                  style: TextStyle(color: Colors.grey))))
              : Expanded(child: ListView.builder(
                  padding: const EdgeInsets.all(12), itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final doc = docs[i];
                    final d   = doc.data() as Map<String, dynamic>;
                    final status = d['todayStatus'] ?? 'absent';
                    return Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)]),
                      child: Row(children: [
                        CircleAvatar(backgroundColor: const Color(0xFF1A3A5C).withOpacity(0.1),
                          child: Text((d['name'] ?? '?')[0],
                            style: const TextStyle(color: Color(0xFF1A3A5C), fontWeight: FontWeight.bold))),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(d['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          Text('Roll: ${d['roll'] ?? ''}  •  Room: ${d['room'] ?? ''}',
                            style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ])),
                        GestureDetector(onTap: () => _cycleStatus(doc),
                          child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: _statusColor(status).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20)),
                            child: Row(children: [
                              Icon(_statusIcon(status), color: _statusColor(status), size: 16),
                              const SizedBox(width: 4),
                              Text(status[0].toUpperCase() + status.substring(1),
                                style: TextStyle(color: _statusColor(status), fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                            ]))),
                      ]));
                  })),
            Padding(padding: const EdgeInsets.all(16),
              child: SizedBox(width: double.infinity, height: 52,
                child: ElevatedButton.icon(
                  onPressed: () => _submitAttendance(context, docs),
                  icon: const Icon(Icons.check, color: Colors.white),
                  label: const Text('SUBMIT ATTENDANCE', style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1)),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A3A5C),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))))),
          ]);
        }),
    );
  }

  Widget _chip(String label, int count, Color color) => Column(children: [
    Text('$count', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
    Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
  ]);
}