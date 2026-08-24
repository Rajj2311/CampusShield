import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../shared/leave_qr_screen.dart';

class StudentLeaveScreen extends StatefulWidget {
  final Map<String, dynamic> studentData;
  const StudentLeaveScreen({super.key, required this.studentData});
  @override
  State<StudentLeaveScreen> createState() => _StudentLeaveScreenState();
}

class _StudentLeaveScreenState extends State<StudentLeaveScreen> {
  DateTime? _fromDate;
  DateTime? _toDate;
  final _reasonCtrl = TextEditingController();
  bool _isLoading = false;
  String? _error;

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';

  int _calcDays() {
    if (_fromDate == null || _toDate == null) return 0;
    return _toDate!.difference(_fromDate!).inDays;
  }

  Future<void> _pickDate(bool isFrom) async {
    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final initial = isFrom
        ? (_fromDate ?? today)
        : (_toDate ?? (_fromDate ?? today));
    final first = isFrom ? today : (_fromDate ?? today);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(first) ? first : initial,
      firstDate: first,
      lastDate: DateTime(today.year + 1),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF1A3A5C),
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: Color(0xFF1A3A5C))),
        child: child!));

    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _fromDate = picked;
        if (_toDate != null && _toDate!.isBefore(picked)) {
          _toDate = picked;
        }
      } else {
        _toDate = picked;
      }
    });
  }

  Future<void> _submitLeave() async {
    if (_fromDate == null || _toDate == null) {
      setState(() => _error = 'Please select from and to dates.');
      return;
    }
    if (_reasonCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Please write a reason.');
      return;
    }
    setState(() { _isLoading = true; _error = null; });
    try {
      await FirebaseFirestore.instance.collection('leaveRequests').add({
        'name':        widget.studentData['name'],
        'roll':        widget.studentData['roll'],
        'room':        widget.studentData['room'],
        'block':       widget.studentData['block'] ?? '',
        'hostelBlock': widget.studentData['block'] ?? '',
        'studentId':   FirebaseAuth.instance.currentUser?.uid ?? '',
        'from':        _formatDate(_fromDate!),
        'to':          _formatDate(_toDate!),
        'fromTimestamp': _fromDate!.millisecondsSinceEpoch,
        'toTimestamp':   _toDate!.millisecondsSinceEpoch,
        'days':        _calcDays(),
        'reason':      _reasonCtrl.text.trim(),
        'status':      'Pending',
        'parentName':     widget.studentData['parentName'] ?? '',
        'parentRelation': widget.studentData['parentRelation'] ?? '',
        'parentPhone1':   widget.studentData['parentPhone1'] ?? '',
        'parentPhone2':   widget.studentData['parentPhone2'] ?? '',
        'createdAt':   FieldValue.serverTimestamp(),
      });
      setState(() {
        _fromDate = null;
        _toDate   = null;
        _reasonCtrl.clear();
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Leave request submitted!'),
          backgroundColor: Color(0xFF2E7D32)));
    } catch (e) {
      setState(() => _error = 'Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final roll = widget.studentData['roll'] ?? '';
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A3A5C),
        title: const Text('Leave Request', style: TextStyle(
          color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [

          // ── New Request Form ─────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(0.05), blurRadius: 8)]),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              const Text('New Leave Request', style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold,
                color: Color(0xFF1A3A5C))),
              const SizedBox(height: 16),

              // Date pickers
              Row(children: [
                Expanded(child: _datePicker(
                  label: 'From Date',
                  value: _fromDate != null
                      ? _formatDate(_fromDate!) : null,
                  onTap: () => _pickDate(true))),
                const SizedBox(width: 12),
                Expanded(child: _datePicker(
                  label: 'To Date',
                  value: _toDate != null
                      ? _formatDate(_toDate!) : null,
                  onTap: () => _pickDate(false))),
              ]),
              const SizedBox(height: 8),

              // Days count
              if (_fromDate != null && _toDate != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A3A5C).withOpacity(0.06),
                    borderRadius: BorderRadius.circular(8)),
                  child: Row(children: [
                    const Icon(Icons.info_outline,
                      size: 14, color: Color(0xFF1A3A5C)),
                    const SizedBox(width: 6),
                    Text('Total: ${_calcDays()} day(s)',
                      style: const TextStyle(
                        fontSize: 12, color: Color(0xFF1A3A5C),
                        fontWeight: FontWeight.w600)),
                  ])),
              const SizedBox(height: 12),

              // Reason
              const Text('Reason', style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600,
                color: Color(0xFF1A3A5C))),
              const SizedBox(height: 6),
              TextField(
                controller: _reasonCtrl, maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Write the reason for leave...',
                  filled: true, fillColor: const Color(0xFFF5F7FA),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none))),

              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(
                  color: Color(0xFFC62828), fontSize: 12)),
              ],
              const SizedBox(height: 16),

              SizedBox(width: double.infinity, height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitLeave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A3A5C),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
                  child: _isLoading
                    ? const CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2)
                    : const Text('SUBMIT REQUEST', style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold)))),
            ])),
          const SizedBox(height: 24),

          // ── My Leave History ─────────────────────────────
          const Text('My Leave History', style: TextStyle(
            fontSize: 15, fontWeight: FontWeight.bold,
            color: Color(0xFF1A3A5C))),
          const SizedBox(height: 12),

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('leaveRequests')
                .where('roll', isEqualTo: roll)
                .snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) return const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF1A3A5C)));
              if (snap.data!.docs.isEmpty)
                return const Text('No leave requests yet.',
                  style: TextStyle(color: Colors.grey));

              return Column(
                children: snap.data!.docs.map((doc) {
                  final d = doc.data() as Map<String, dynamic>;
                  final status = d['status'] ?? 'Pending';
                  final color = status == 'Approved'
                      ? const Color(0xFF2E7D32)
                      : status == 'Rejected'
                          ? const Color(0xFFC62828)
                          : const Color(0xFFF0A500);
                  final showQR = status == 'Approved' &&
                      (d['qrToken'] != null);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 6)]),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                      Row(children: [
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                          Text('${d['from']} → ${d['to']}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13)),
                          Text(d['reason'] ?? '',
                            style: const TextStyle(
                              fontSize: 11, color: Colors.grey),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                          Text('${d['days'] ?? 1} day(s)',
                            style: const TextStyle(
                              fontSize: 11, color: Colors.grey)),
                        ])),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10)),
                          child: Text(status, style: TextStyle(
                            color: color, fontSize: 11,
                            fontWeight: FontWeight.w600))),
                      ]),
                      if (showQR) ...[
                        const SizedBox(height: 10),
                        SizedBox(width: double.infinity, height: 36,
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.push(
                              context, MaterialPageRoute(
                                builder: (_) => LeaveQRScreen(
                                  leaveData: d,
                                  leaveId: doc.id))),
                            icon: const Icon(Icons.qr_code,
                              size: 16, color: Colors.white),
                            label: const Text('View Gate Pass',
                              style: TextStyle(
                                fontSize: 12, color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1A3A5C),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(8))))),
                      ],
                    ]));
                }).toList());
            }),
        ])),
    );
  }

  Widget _datePicker({
    required String label,
    required String? value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200)),
        child: Row(children: [
          const Icon(Icons.calendar_today,
            size: 16, color: Color(0xFF1A3A5C)),
          const SizedBox(width: 8),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Text(label, style: const TextStyle(
              fontSize: 10, color: Colors.grey)),
            Text(value ?? 'DD/MM/YYYY',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: value != null
                    ? const Color(0xFF1A3A5C)
                    : Colors.grey)),
          ])),
        ])));
  }
}