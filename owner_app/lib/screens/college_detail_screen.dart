import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../payment_config.dart';
import '../subscription.dart';
import '../theme.dart';
import 'data_browser.dart';
import 'payments_screen.dart';

/// Everything the owner needs about one college: stats, admin contact,
/// suspend/reactivate and private billing notes.
class CollegeDetailScreen extends StatefulWidget {
  final String collegeId;
  const CollegeDetailScreen({super.key, required this.collegeId});
  @override
  State<CollegeDetailScreen> createState() => _CollegeDetailScreenState();
}

class _CollegeDetailScreenState extends State<CollegeDetailScreen> {
  DocumentReference<Map<String, dynamic>> get _ref =>
      FirebaseFirestore.instance.collection('colleges').doc(widget.collegeId);

  final _plan = TextEditingController();
  final _amount = TextEditingController();
  final _paidUntil = TextEditingController();
  final _notes = TextEditingController();
  bool _billingLoaded = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadBilling();
  }

  @override
  void dispose() {
    _plan.dispose();
    _amount.dispose();
    _paidUntil.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _msg(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _loadBilling() async {
    try {
      final s = await _ref.collection('settings').doc('billing').get();
      final d = s.data() ?? {};
      _plan.text = d['plan'] ?? '';
      _amount.text = d['amount'] ?? '';
      _paidUntil.text = d['paidUntil'] ?? '';
      _notes.text = d['notes'] ?? '';
    } on FirebaseException {
      // leave empty
    }
    if (mounted) setState(() => _billingLoaded = true);
  }

  Future<void> _saveBilling() async {
    setState(() => _saving = true);
    try {
      await _ref.collection('settings').doc('billing').set({
        'plan': _plan.text.trim(),
        'amount': _amount.text.trim(),
        'paidUntil': _paidUntil.text.trim(),
        'notes': _notes.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _msg('Billing notes saved.');
    } on FirebaseException catch (e) {
      _msg('Could not save: ${e.message ?? e.code}');
    }
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _setStatus(String status) async {
    try {
      await _ref.update({'status': status});
    } on FirebaseException catch (e) {
      _msg('Could not update: ${e.message ?? e.code}');
    }
  }


  static const _collections = [
    'students', 'wardens', 'guards', 'workers', 'complaints', 'leaveRequests',
    'notices', 'notifications', 'activity', 'deviceChangeRequests',
    'messMenuDays', 'gateHistory', 'attendanceRecords', 'attendanceHistory',
    'settings',
  ];

  Future<void> _renew(Map<String, dynamic> c) async {
    final cfg = await PaymentConfig.load();
    if (!mounted) return;
    final entry = await showPaymentDialog(context, cfg,
        title: 'Record payment / renew', planId: c['plan'] as String?);
    if (entry == null) return;
    try {
      final batch = FirebaseFirestore.instance.batch();
      final exp = c['expiresAt'];
      String adminName = '';
      try {
        final ct = await _ref.collection('settings').doc('contact').get();
        adminName = (ct.data()?['adminName'] ?? '').toString();
      } on FirebaseException {
        // optional
      }
      final sub = applyPayment(batch,
          collegeId: widget.collegeId,
          collegeName: (c['name'] ?? widget.collegeId).toString(),
          adminName: adminName,
          p: entry,
          currentExpiry: exp is Timestamp ? exp.toDate() : null);
      batch.update(_ref, sub);
      await batch.commit();
      _msg('Payment recorded and receipt created.');
    } on FirebaseException catch (e) {
      _msg('Could not save: ${e.message ?? e.code}');
    }
  }

  Future<void> _setExpiry(Map<String, dynamic> c) async {
    final exp = c['expiresAt'];
    final initial = exp is Timestamp ? exp.toDate() : DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2024),
      lastDate: DateTime(2100),
      helpText: 'Subscription valid until',
    );
    if (d == null) return;
    try {
      await _ref.update({
        'expiresAt': Timestamp.fromDate(DateTime(d.year, d.month, d.day, 23, 59, 59)),
      });
      _msg('Expiry date updated.');
    } on FirebaseException catch (e) {
      _msg('Could not update: ${e.message ?? e.code}');
    }
  }

  Future<void> _clearExpiry() async {
    try {
      await _ref.update({'expiresAt': FieldValue.delete()});
      _msg('Expiry removed. This college has no end date.');
    } on FirebaseException catch (e) {
      _msg('Could not update: ${e.message ?? e.code}');
    }
  }

  void _browse(String col) => Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => DataBrowser(
              title: '${widget.collegeId} / $col', ref: _ref.collection(col))));

  void _pickCollection() {
    final other = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 16, right: 16, top: 16),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Browse and edit data',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kNavy)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: _collections
                .map((col) => ActionChip(
                    label: Text(col),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _browse(col);
                    }))
                .toList(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: other,
            decoration: const InputDecoration(labelText: 'Other collection name'),
            onSubmitted: (v) {
              if (v.trim().isEmpty) return;
              Navigator.pop(ctx);
              _browse(v.trim());
            },
          ),
          const SizedBox(height: 16),
        ]),
      ),
    ).whenComplete(other.dispose);
  }

  Future<void> _deleteCollege(Map<String, dynamic> c) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete college permanently?'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(
              'This deletes all data of "${c['name'] ?? widget.collegeId}" (students, staff records, complaints, leaves, notices...) and its profile. Payment receipts are kept. This cannot be undone.\n\nType the college code "${widget.collegeId}" to confirm.'),
          TextField(controller: ctrl),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim() == widget.collegeId),
              child: const Text('Delete', style: TextStyle(color: kRed))),
        ],
      ),
    );
    ctrl.dispose();
    if (ok != true) return;
    final db = FirebaseFirestore.instance;
    try {
      for (final col in _collections) {
        while (true) {
          final snap = await _ref.collection(col).limit(400).get();
          if (snap.docs.isEmpty) break;
          final batch = db.batch();
          for (final d in snap.docs) {
            batch.delete(d.reference);
          }
          await batch.commit();
        }
      }
      final users = await db.collection('userIndex').where('collegeId', isEqualTo: widget.collegeId).get();
      for (var i = 0; i < users.docs.length; i += 400) {
        final batch = db.batch();
        for (final d in users.docs.skip(i).take(400)) {
          batch.delete(d.reference);
        }
        await batch.commit();
      }
      await _ref.delete();
      if (!mounted) return;
      Navigator.pop(context);
    } on FirebaseException catch (e) {
      _msg('Delete failed: ${e.message ?? e.code}');
    }
  }

  Future<int> _count(String col) async {
    final s = await _ref.collection(col).count().get();
    return s.count ?? 0;
  }

  Widget _stat(String label, String col, IconData icon) {
    return FutureBuilder<int>(
      future: _count(col),
      builder: (context, snap) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: kAmber, size: 20),
              Text(snap.hasData ? '${snap.data}' : '...',
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold, color: kNavy)),
              Text(label,
                  style: const TextStyle(color: Colors.black54, fontSize: 12)),
            ]),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, {int lines = 1}) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(
          controller: c,
          maxLines: lines,
          decoration: InputDecoration(
              labelText: label,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _ref.snapshots(),
      builder: (context, snap) {
        final c = snap.data?.data() ?? {};
        final status = (c['status'] as String?) ?? 'pending';
        final active = status == 'approved';
        return Scaffold(
          backgroundColor: kBg,
          appBar: AppBar(
            backgroundColor: kNavy,
            iconTheme: const IconThemeData(color: Colors.white),
            title: Text('${c['name'] ?? widget.collegeId}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          body: ListView(padding: const EdgeInsets.all(16), children: [
            Card2(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Code: ${widget.collegeId}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: kNavy)),
                Text('City: ${c['city'] ?? '-'}'),
                Text('Hostels: ${(c['hostels'] as List?)?.join(', ') ?? '-'}'),
                Text('Status: $status'),
                Text('Plan: ${c['planName'] ?? '-'}'),
                Text(c['expiresAt'] is Timestamp
                    ? 'Valid until: ${formatDate((c['expiresAt'] as Timestamp).toDate())}'
                    : 'Valid until: no end date'),
              ]),
            ),
            Row(children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _renew(c),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: kGreen, foregroundColor: Colors.white),
                  icon: const Icon(Icons.add_card),
                  label: const Text('Record payment'),
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                tooltip: 'Expiry',
                onSelected: (v) => v == 'set' ? _setExpiry(c) : _clearExpiry(),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'set', child: Text('Set expiry date')),
                  PopupMenuItem(value: 'clear', child: Text('Remove expiry (no end date)')),
                ],
                child: const Chip(avatar: Icon(Icons.event, size: 18), label: Text('Expiry')),
              ),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickCollection,
                  icon: const Icon(Icons.storage),
                  label: const Text('Browse data'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => DocEditor(
                              ref: FirebaseFirestore.instance.collection('colleges'),
                              docId: widget.collegeId,
                              data: c))),
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit profile'),
                ),
              ),
            ]),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => Scaffold(
                            backgroundColor: kBg,
                            appBar: AppBar(
                                backgroundColor: kNavy,
                                iconTheme: const IconThemeData(color: Colors.white),
                                title: const Text('Receipts',
                                    style: TextStyle(color: Colors.white))),
                            body: PaymentsScreen(collegeId: widget.collegeId)))),
                icon: const Icon(Icons.receipt_long),
                label: const Text('Receipts of this college'),
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.2,
              children: [
                _stat('Students', 'students', Icons.school),
                _stat('Wardens', 'wardens', Icons.admin_panel_settings),
                _stat('Guards', 'guards', Icons.shield),
                _stat('Workers', 'workers', Icons.engineering),
                _stat('Complaints', 'complaints', Icons.report_problem_outlined),
                _stat('Leaves', 'leaveRequests', Icons.exit_to_app),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Admin contact',
                style: TextStyle(fontWeight: FontWeight.bold, color: kNavy, fontSize: 16)),
            const SizedBox(height: 8),
            FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              future: _ref.collection('settings').doc('contact').get(),
              builder: (context, cs) {
                final d = cs.data?.data() ?? {};
                return Card2(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    SelectableText('${d['adminName'] ?? '-'}'),
                    SelectableText('Phone: ${d['phone'] ?? '-'}'),
                    SelectableText('Email: ${d['email'] ?? '-'}'),
                  ]),
                );
              },
            ),
            const SizedBox(height: 8),
            const Text('Billing notes (private)',
                style: TextStyle(fontWeight: FontWeight.bold, color: kNavy, fontSize: 16)),
            const SizedBox(height: 8),
            if (!_billingLoaded)
              const Center(child: CircularProgressIndicator())
            else ...[
              _field(_plan, 'Plan'),
              _field(_amount, 'Amount agreed'),
              _field(_paidUntil, 'Paid until (e.g. 31 Mar 2027)'),
              _field(_notes, 'Notes', lines: 3),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _saving ? null : _saveBilling,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: kNavy, foregroundColor: Colors.white),
                  child: const Text('Save billing notes'),
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () => _setStatus(active ? 'suspended' : 'approved'),
                style: OutlinedButton.styleFrom(foregroundColor: active ? kRed : kGreen),
                icon: Icon(active ? Icons.pause_circle_outline : Icons.play_circle_outline),
                label: Text(active ? 'Suspend college' : 'Reactivate college'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () => _deleteCollege(c),
                style: OutlinedButton.styleFrom(foregroundColor: kRed),
                icon: const Icon(Icons.delete_forever),
                label: const Text('Delete college permanently'),
              ),
            ),
            const SizedBox(height: 24),
          ]),
        );
      },
    );
  }
}
