import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../payment_config.dart';
import '../role_codes.dart';
import '../subscription.dart';
import '../theme.dart';

/// Pending college registrations. Approve = create the college workspace.
class RequestsScreen extends StatelessWidget {
  const RequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('collegeRequests')
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(child: Text('Could not load requests.\n${snap.error}'));
        }
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return const Center(
              child: Text('No pending requests.',
                  style: TextStyle(color: Colors.black54)));
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: docs.map((d) => _RequestCard(doc: d)).toList(),
        );
      },
    );
  }
}

class _RequestCard extends StatefulWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  const _RequestCard({required this.doc});
  @override
  State<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends State<_RequestCard> {
  bool _busy = false;

  void _msg(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _approve() async {
    final r = widget.doc.data();
    final uid = widget.doc.id;
    final code = (r['collegeCode'] as String).trim().toLowerCase();
    final cfg = await PaymentConfig.load();
    if (!mounted) return;
    final pay = r['payment'] is Map ? Map<String, dynamic>.from(r['payment'] as Map) : <String, dynamic>{};
    final entry = await showPaymentDialog(
      context,
      cfg,
      title: 'Verify payment and approve',
      planId: r['plan'] as String?,
      // The plan's current price is the amount to verify against.
      amount: (cfg.plan(r['plan'] as String?)?.price ?? 0) > 0
          ? cfg.plan(r['plan'] as String?)!.price
          : ((pay['amount'] as num?) ?? (r['amount'] as num?)),
      months: (r['months'] as num?)?.toInt(),
      method: pay['method'] as String?,
      reference: pay['reference'] as String?,
    );
    if (entry == null) return;
    setState(() => _busy = true);
    try {
      final db = FirebaseFirestore.instance;
      final existing = await db.collection('colleges').doc(code).get();
      if (existing.exists) {
        _msg('A college with code "$code" already exists.');
        return;
      }
      final college = db.collection('colleges').doc(code);
      final batch = db.batch();
      final sub = applyPayment(batch,
          collegeId: code,
          collegeName: r['collegeName'] as String,
          adminName: (r['adminName'] ?? '').toString(),
          p: entry);
      batch.set(college, {
        ...sub,
        'name': r['collegeName'],
        'city': r['city'],
        'hostels': r['hostels'] ?? [],
        'adminUid': uid,
        'attendanceStartHour': 20,
        'attendanceEndHour': 21,
        'createdAt': FieldValue.serverTimestamp(),
        'approvedAt': FieldValue.serverTimestamp(),
      });
      batch.set(college.collection('settings').doc('codes'), {
        'warden': generateRoleCode('WARDEN'),
        'guard': generateRoleCode('GUARD'),
        'worker': generateRoleCode('WORKER'),
      });
      batch.set(college.collection('settings').doc('contact'), {
        'adminName': r['adminName'],
        'phone': r['phone'],
        'email': r['email'],
        'city': r['city'],
      });
      batch.set(db.collection('userIndex').doc(uid), {
        'collegeId': code,
        'role': 'admin',
        'docId': uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
      batch.update(widget.doc.reference, {
        'status': 'approved',
        'approvedAt': FieldValue.serverTimestamp(),
      });
      await batch.commit();
      _msg('${r['collegeName']} approved.');
    } on FirebaseException catch (e) {
      _msg('Approval failed: ${e.message ?? e.code}');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reject() async {
    final ctrl = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject request'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: 'Reason (shown to the applicant)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text('Reject', style: TextStyle(color: kRed))),
        ],
      ),
    );
    ctrl.dispose();
    if (reason == null) return;
    setState(() => _busy = true);
    try {
      await widget.doc.reference.update({
        'status': 'rejected',
        'rejectReason': reason.isEmpty ? 'Not approved.' : reason,
        'reviewedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      _msg('Could not reject: ${e.message ?? e.code}');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.doc.data();
    final hostels = (r['hostels'] as List?)?.join(', ') ?? '-';
    Widget line(IconData i, String t) => Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(children: [
            Icon(i, size: 16, color: Colors.black45),
            const SizedBox(width: 8),
            Expanded(child: Text(t, style: const TextStyle(fontSize: 13))),
          ]),
        );
    return Card2(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${r['collegeName']}',
            style: const TextStyle(
                fontSize: 17, fontWeight: FontWeight.bold, color: kNavy)),
        line(Icons.tag, 'Code: ${r['collegeCode']}'),
        line(Icons.location_city, '${r['city']}'),
        line(Icons.home_work, 'Hostels: $hostels'),
        line(Icons.person, '${r['adminName']}'),
        line(Icons.phone, '${r['phone']}'),
        line(Icons.email, '${r['email']}'),
        line(Icons.workspace_premium,
            'Plan: ${r['planName'] ?? '-'}  |  Rs. ${r['amount'] ?? '-'}  |  ${r['months'] ?? '-'} months'),
        if (r['payment'] is Map)
          line(Icons.payments,
              'Paid: ${(r['payment'] as Map)['method']}  |  Rs. ${(r['payment'] as Map)['amount']}  |  Ref: ${(r['payment'] as Map)['reference']}')
        else
          line(Icons.hourglass_empty, 'Payment details not submitted yet'),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _busy ? null : _reject,
              style: OutlinedButton.styleFrom(foregroundColor: kRed),
              child: const Text('Reject'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: _busy ? null : _approve,
              style: ElevatedButton.styleFrom(
                  backgroundColor: kGreen, foregroundColor: Colors.white),
              child: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Approve'),
            ),
          ),
        ]),
      ]),
    );
  }
}
