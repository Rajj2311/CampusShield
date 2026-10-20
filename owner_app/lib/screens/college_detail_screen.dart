import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme.dart';

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
              ]),
            ),
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
            const SizedBox(height: 24),
          ]),
        );
      },
    );
  }
}
