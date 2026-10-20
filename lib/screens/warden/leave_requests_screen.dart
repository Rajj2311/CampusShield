import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/notification_helper.dart';
import '../../utils/warden_helper.dart';
import '../../utils/tenant.dart';

class LeaveRequestsScreen extends StatefulWidget {
  const LeaveRequestsScreen({super.key});
  @override
  State<LeaveRequestsScreen> createState() => _LeaveRequestsScreenState();
}

class _LeaveRequestsScreenState extends State<LeaveRequestsScreen> {
  String? _wardenHostel;
  String  _filter = 'All';

  @override
  void initState() {
    super.initState();
    _loadHostel();
  }

  Future<void> _loadHostel() async {
    final hostel = await WardenHelper.getMyHostel();
    setState(() => _wardenHostel = hostel);
  }

  // ── Approve / Reject ──────────────────────────────────────────
  Future<void> _updateStatus(String docId, String status) async {
    final Map<String, dynamic> updateData = {'status': status};
    if (status == 'Approved') {
      final qrToken =
          '${docId}_${DateTime.now().millisecondsSinceEpoch}';
      updateData['qrToken']    = qrToken;
      updateData['gateStatus'] = 'ready';
    }
    await Tenant.col('leaveRequests').doc(docId).update(updateData);

    final doc = await Tenant.col('leaveRequests').doc(docId).get();
    final studentId = doc.data()?['studentId'] ?? '';

    await NotificationHelper.send(
      toUserId: studentId,
      title: status == 'Approved'
          ? '✅ Leave Approved!' : '❌ Leave Rejected',
      body: status == 'Approved'
          ? 'Your leave has been approved. Open app to view QR Gate Pass.'
          : 'Your leave request was rejected by the warden.',
      type: 'leave',
      relatedId: docId);

    await Tenant.col('activity').add({
      'title':     'Leave request $status',
      'time':      'Just now',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Info Row Widget ───────────────────────────────────────────
  Widget _infoRow(IconData icon, String text,
      {bool isPhone = false}) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(children: [
        Icon(icon, size: 12, color: Colors.black54),
        const SizedBox(width: 6),
        isPhone
          ? Text(text, style: const TextStyle(
              fontSize: 12, color: Color(0xFF1565C0),
              decoration: TextDecoration.underline,
              fontWeight: FontWeight.w500))
          : Expanded(child: Text(text, style: const TextStyle(
              fontSize: 12, color: Colors.black87))),
      ]));
  }

  // ── Add Leave Manually ────────────────────────────────────────
  void _showAddLeave(BuildContext context) {
    final nameCtrl   = TextEditingController();
    final rollCtrl   = TextEditingController();
    final roomCtrl   = TextEditingController();
    final fromCtrl   = TextEditingController();
    final toCtrl     = TextEditingController();
    final daysCtrl   = TextEditingController(text: '1');
    final reasonCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 20, right: 20, top: 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            const Text('Add Leave Request', style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold,
              color: Color(0xFF1A3A5C))),
            const SizedBox(height: 14),
            _textField(nameCtrl, 'Student Name'),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _textField(rollCtrl, 'Roll Number')),
              const SizedBox(width: 10),
              Expanded(child: _textField(roomCtrl, 'Room Number')),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _textField(fromCtrl, 'From Date')),
              const SizedBox(width: 10),
              Expanded(child: _textField(toCtrl, 'To Date')),
            ]),
            const SizedBox(height: 10),
            _textField(daysCtrl, 'Number of Days',
              type: TextInputType.number),
            const SizedBox(height: 10),
            _textField(reasonCtrl, 'Reason', maxLines: 2),
            const SizedBox(height: 14),
            SizedBox(width: double.infinity, height: 48,
              child: ElevatedButton(
                onPressed: () async {
                  if (nameCtrl.text.trim().isNotEmpty) {
                    await Tenant.col('leaveRequests').add({
                      'name':        nameCtrl.text.trim(),
                      'roll':        rollCtrl.text.trim().toUpperCase(),
                      'room':        roomCtrl.text.trim(),
                      'block':       _wardenHostel ?? '',
                      'hostelBlock': _wardenHostel ?? '',
                      'from':        fromCtrl.text.trim(),
                      'to':          toCtrl.text.trim(),
                      'days': int.tryParse(daysCtrl.text.trim()) ?? 1,
                      'reason':      reasonCtrl.text.trim(),
                      'status':      'Pending',
                      'createdAt':   FieldValue.serverTimestamp(),
                    });
                    if (ctx.mounted) Navigator.pop(ctx);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A3A5C),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
                child: const Text('SUBMIT', style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold)))),
            const SizedBox(height: 20),
          ]))));
  }

  Widget _textField(TextEditingController ctrl, String hint,
      {int maxLines = 1, TextInputType? type}) =>
    TextField(
      controller: ctrl, maxLines: maxLines, keyboardType: type,
      decoration: InputDecoration(hintText: hint,
        filled: true, fillColor: const Color(0xFFF5F7FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none)));

  Color _statusColor(String s) {
    switch (s) {
      case 'Approved':  return const Color(0xFF2E7D32);
      case 'Rejected':  return const Color(0xFFC62828);
      case 'Active':    return const Color(0xFF1565C0);
      case 'Completed': return const Color(0xFF546E7A);
      default:          return const Color(0xFFF0A500);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_wardenHostel == null) {
      return const Scaffold(body: Center(
        child: CircularProgressIndicator(color: Color(0xFF1A3A5C))));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A3A5C),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          const Text('Leave Requests', style: TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold,
            fontSize: 16)),
          Text(_wardenHostel!, style: const TextStyle(
            color: Color(0xFFF0A500), fontSize: 11)),
        ]),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () => _showAddLeave(context)),
        ]),
      body: Column(children: [
        // Filter tabs
        Container(color: Colors.white,
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['All','Pending','Approved',
                         'Rejected','Active','Completed']
                .map((f) {
                final sel = _filter == f;
                return GestureDetector(
                  onTap: () => setState(() => _filter = f),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: sel
                          ? const Color(0xFF1A3A5C)
                          : const Color(0xFFF5F7FA),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF1A3A5C)
                            .withOpacity(0.3))),
                    child: Text(f, style: TextStyle(
                      color: sel ? Colors.white
                                 : const Color(0xFF1A3A5C),
                      fontSize: 12,
                      fontWeight: FontWeight.w600))));
              }).toList()))),
        const Divider(height: 1),

        // List
        Expanded(child: StreamBuilder<QuerySnapshot>(
          stream: _filter == 'All'
            ? Tenant.col('leaveRequests')
                .where('block', isEqualTo: _wardenHostel)
                .snapshots()
            : Tenant.col('leaveRequests')
                .where('block', isEqualTo: _wardenHostel)
                .where('status', isEqualTo: _filter)
                .snapshots(),
          builder: (context, snap) {
            if (!snap.hasData) return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF1A3A5C)));

            final docs = snap.data!.docs;
            if (docs.isEmpty) return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                const Icon(Icons.event_note,
                  size: 64, color: Colors.grey),
                const SizedBox(height: 12),
                Text(
                  'No ${_filter == 'All' ? '' : _filter} '
                  'leave requests.',
                  style: const TextStyle(
                    color: Colors.grey, fontSize: 14)),
              ]));

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: docs.length,
              itemBuilder: (context, i) {
                final doc    = docs[i];
                final d      = doc.data() as Map<String, dynamic>;
                final status = d['status'] ?? 'Pending';
                final color  = _statusColor(status);

                // Parent info check
                final hasParent =
                    (d['parentName'] ?? '').toString().isNotEmpty ||
                    (d['parentPhone1'] ?? '').toString().isNotEmpty;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8)]),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                    // ── Header ───────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.08),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(14),
                          topRight: Radius.circular(14))),
                      child: Row(children: [
                        CircleAvatar(
                          backgroundColor: color.withOpacity(0.15),
                          child: Text(
                            (d['name'] ?? '?')[0].toUpperCase(),
                            style: TextStyle(color: color,
                              fontWeight: FontWeight.bold))),
                        const SizedBox(width: 10),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                          Text(d['name'] ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14)),
                          Text('Roll: ${d['roll'] ?? ''}'
                               '  •  Room: ${d['room'] ?? ''}',
                            style: const TextStyle(
                              fontSize: 11, color: Colors.grey)),
                        ])),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12)),
                          child: Text(status, style: TextStyle(
                            color: color, fontSize: 11,
                            fontWeight: FontWeight.bold))),
                      ])),

                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                        // ── Dates ────────────────────────────
                        Row(children: [
                          const Icon(Icons.calendar_today,
                            size: 13, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            '${d['from'] ?? ''} → ${d['to'] ?? ''}'
                            '  (${d['days'] ?? 1} days)',
                            style: const TextStyle(
                              fontSize: 12, color: Colors.black87)),
                        ]),
                        const SizedBox(height: 4),

                        // ── Reason ───────────────────────────
                        Text(d['reason'] ?? '',
                          style: const TextStyle(
                            fontSize: 13, color: Colors.black87)),
                        const SizedBox(height: 10),

                        // ── Parent Info ──────────────────────
                        if (hasParent)
                          Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF8E1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFFF0A500)
                                    .withOpacity(0.4))),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                              Row(children: [
                                const Icon(Icons.family_restroom,
                                  size: 14,
                                  color: Color(0xFFF0A500)),
                                const SizedBox(width: 6),
                                const Text('Parent / Guardian',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFF0A500))),
                              ]),
                              const SizedBox(height: 6),
                              if ((d['parentName'] ?? '')
                                  .toString().isNotEmpty)
                                _infoRow(Icons.person_outline,
                                  '${d['parentName']} '
                                  '(${d['parentRelation'] ?? ''})'),
                              if ((d['parentPhone1'] ?? '')
                                  .toString().isNotEmpty)
                                _infoRow(Icons.phone,
                                  d['parentPhone1'],
                                  isPhone: true),
                              if ((d['parentPhone2'] ?? '')
                                  .toString().isNotEmpty)
                                _infoRow(Icons.phone_outlined,
                                  '${d['parentPhone2']} (Alternate)',
                                  isPhone: true),
                            ])),

                        // ── Approve/Reject Buttons ────────────
                        if (status == 'Pending')
                          Row(children: [
                            Expanded(child: ElevatedButton.icon(
                              onPressed: () =>
                                  _updateStatus(doc.id, 'Rejected'),
                              icon: const Icon(Icons.close,
                                size: 16, color: Colors.white),
                              label: const Text('Reject',
                                style: TextStyle(
                                  color: Colors.white, fontSize: 13)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFC62828),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(8))))),
                            const SizedBox(width: 10),
                            Expanded(child: ElevatedButton.icon(
                              onPressed: () =>
                                  _updateStatus(doc.id, 'Approved'),
                              icon: const Icon(Icons.check,
                                size: 16, color: Colors.white),
                              label: const Text('Approve',
                                style: TextStyle(
                                  color: Colors.white, fontSize: 13)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2E7D32),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(8))))),
                          ]),

                        // ── Gate Status ───────────────────────
                        if (status == 'Approved' ||
                            status == 'Active' ||
                            status == 'Completed')
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8)),
                            child: Row(children: [
                              Icon(
                                status == 'Completed'
                                    ? Icons.check_circle
                                    : status == 'Active'
                                        ? Icons.directions_walk
                                        : Icons.qr_code,
                                color: color, size: 14),
                              const SizedBox(width: 6),
                              Text(
                                status == 'Completed'
                                    ? 'Return: ${d['returnTime'] ?? 'Logged'}'
                                    : status == 'Active'
                                        ? 'Out since: ${d['exitTime'] ?? ''}'
                                        : 'QR Gate Pass Generated ✓',
                                style: TextStyle(color: color,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500)),
                            ])),
                      ])),
                  ]));
              });
          })),
      ]),
    );
  }
}