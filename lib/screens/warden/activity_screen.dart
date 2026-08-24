import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/warden_helper.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});
  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  String? _wardenHostel;
  String  _filter = 'All';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final h = await WardenHelper.getMyHostel();
    setState(() => _wardenHostel = h);
  }

  IconData _icon(String type) {
    switch (type) {
      case 'gate':         return Icons.swap_horiz;
      case 'gate_approval': return Icons.verified_user;
      case 'leave':        return Icons.event_note;
      case 'complaint':    return Icons.report;
      case 'attendance':   return Icons.how_to_reg;
      default:             return Icons.circle;
    }
  }

  Color _color(String type) {
    switch (type) {
      case 'gate':         return const Color(0xFF2E7D32);
      case 'gate_approval': return const Color(0xFFF0A500);
      case 'leave':        return const Color(0xFF1565C0);
      case 'complaint':    return const Color(0xFFC62828);
      case 'attendance':   return const Color(0xFF6A1B9A);
      default:             return const Color(0xFF1A3A5C);
    }
  }

  String _timeAgo(Timestamp? ts) {
    if (ts == null) return '';
    final diff = DateTime.now().difference(ts.toDate());
    if (diff.inMinutes < 1)  return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24)   return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A3A5C),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          const Text('All Activities', style: TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold,
            fontSize: 16)),
          Text(_wardenHostel ?? '', style: const TextStyle(
            color: Color(0xFFF0A500), fontSize: 11)),
        ]),
        iconTheme: const IconThemeData(color: Colors.white)),
      body: Column(children: [
        Container(color: Colors.white,
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['All','gate','leave','complaint',
                         'attendance','gate_approval']
                .map((f) {
                final sel = _filter == f;
                final labels = {
                  'gate': 'Gate', 'leave': 'Leave',
                  'complaint': 'Complaint',
                  'attendance': 'Attendance',
                  'gate_approval': 'Approvals'};
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
                    child: Text(
                      labels[f] ?? f.toUpperCase(),
                      style: TextStyle(
                        color: sel ? Colors.white
                                   : const Color(0xFF1A3A5C),
                        fontSize: 11,
                        fontWeight: FontWeight.w600))));
              }).toList()))),
        const Divider(height: 1),

        Expanded(child: StreamBuilder<QuerySnapshot>(
          stream: _filter == 'All'
            ? FirebaseFirestore.instance
                .collection('activity')
                .orderBy('createdAt', descending: true)
                .limit(100)
                .snapshots()
            : FirebaseFirestore.instance
                .collection('activity')
                .where('type', isEqualTo: _filter)
                .orderBy('createdAt', descending: true)
                .limit(100)
                .snapshots(),
          builder: (context, snap) {
            if (!snap.hasData) return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF1A3A5C)));
            if (snap.data!.docs.isEmpty) return const Center(
              child: Text('No activities yet.',
                style: TextStyle(color: Colors.grey)));

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: snap.data!.docs.length,
              itemBuilder: (context, i) {
                final d = snap.data!.docs[i].data()
                    as Map<String, dynamic>;
                final type = d['type'] ?? 'general';
                final ts   = d['createdAt'] as Timestamp?;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 6)]),
                  child: Row(children: [
                    Container(padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _color(type).withOpacity(0.1),
                        shape: BoxShape.circle),
                      child: Icon(_icon(type),
                        color: _color(type), size: 16)),
                    const SizedBox(width: 10),
                    Expanded(child: Text(d['title'] ?? '',
                      style: const TextStyle(fontSize: 13))),
                    Text(_timeAgo(ts), style: const TextStyle(
                      fontSize: 10, color: Colors.grey)),
                  ]));
              });
          })),
      ]),
    );
  }
}