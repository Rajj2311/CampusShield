import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/tenant.dart';

class GateHistoryScreen extends StatefulWidget {
  final String hostelBlock;
  const GateHistoryScreen({super.key, required this.hostelBlock});
  @override
  State<GateHistoryScreen> createState() => _GateHistoryScreenState();
}

class _GateHistoryScreenState extends State<GateHistoryScreen> {
  String _filter = 'All';

  Color _actionColor(String action) {
    switch (action) {
      case 'EXIT':        return const Color(0xFF2E7D32);
      case 'RETURN':      return const Color(0xFF1565C0);
      case 'LATE_RETURN': return const Color(0xFFF0A500);
      case 'EXPIRED':     return const Color(0xFFC62828);
      default:            return const Color(0xFF546E7A);
    }
  }

  IconData _actionIcon(String action) {
    switch (action) {
      case 'EXIT':        return Icons.logout;
      case 'RETURN':      return Icons.login;
      case 'LATE_RETURN': return Icons.warning_amber;
      case 'EXPIRED':     return Icons.error_outline;
      default:            return Icons.swap_horiz;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A3A5C),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          const Text('Gate History', style: TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold,
            fontSize: 16)),
          Text(widget.hostelBlock, style: const TextStyle(
            color: Color(0xFFF0A500), fontSize: 11)),
        ]),
        iconTheme: const IconThemeData(color: Colors.white)),
      body: Column(children: [
        // Filter
        Container(color: Colors.white,
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['All','EXIT','RETURN','LATE_RETURN','EXPIRED']
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
                    child: Text(
                      f == 'LATE_RETURN' ? 'Late Return' : f,
                      style: TextStyle(
                        color: sel ? Colors.white
                                   : const Color(0xFF1A3A5C),
                        fontSize: 11,
                        fontWeight: FontWeight.w600))));
              }).toList()))),
        const Divider(height: 1),

        Expanded(child: StreamBuilder<QuerySnapshot>(
          stream: _filter == 'All'
            ? Tenant.col('gateHistory')
                .where('hostelBlock', isEqualTo: widget.hostelBlock)
                .orderBy('createdAt', descending: true)
                .snapshots()
            : Tenant.col('gateHistory')
                .where('hostelBlock', isEqualTo: widget.hostelBlock)
                .where('action', isEqualTo: _filter)
                .orderBy('createdAt', descending: true)
                .snapshots(),
          builder: (context, snap) {
            if (snap.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 56, color: Color(0xFFC62828)),
                      const SizedBox(height: 12),
                      const Text('Could not load gate history.',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 8),
                      Text('${snap.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      const SizedBox(height: 4),
                      const Text(
                        'Tip: this usually means a Firestore composite index is missing '
                        '(hostelBlock + createdAt, or hostelBlock + action + createdAt). '
                        'Check the debug console for a link to auto-create it.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic)),
                    ],
                  ),
                ),
              );
            }
            if (!snap.hasData) return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF1A3A5C)));
            if (snap.data!.docs.isEmpty) return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                Icon(Icons.history, size: 64, color: Colors.grey),
                SizedBox(height: 12),
                Text('No gate history yet.',
                  style: TextStyle(color: Colors.grey)),
              ]));

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: snap.data!.docs.length,
              itemBuilder: (context, i) {
                final d = snap.data!.docs[i].data()
                    as Map<String, dynamic>;
                final action = d['action'] ?? '';
                final color  = _actionColor(action);
                final icon   = _actionIcon(action);

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 6)]),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        shape: BoxShape.circle),
                      child: Icon(icon, color: color, size: 20)),
                    const SizedBox(width: 12),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                      Text(d['studentName'] ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                      Text(
                        'Roll: ${d['roll'] ?? ''}  •  '
                        'Room ${d['room'] ?? ''}',
                        style: const TextStyle(
                          fontSize: 11, color: Colors.grey)),
                      Text(
                        'Guard: ${d['guardName'] ?? ''}',
                        style: const TextStyle(
                          fontSize: 11, color: Colors.grey)),
                    ])),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8)),
                        child: Text(
                          action == 'LATE_RETURN'
                              ? 'Late Return' : action,
                          style: TextStyle(color: color,
                            fontSize: 10,
                            fontWeight: FontWeight.bold))),
                      const SizedBox(height: 4),
                      Text(d['date'] ?? '',
                        style: const TextStyle(
                          fontSize: 10, color: Colors.grey)),
                      Text(d['time'] ?? '',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A3A5C))),
                    ]),
                  ]));
              });
          })),
      ]),
    );
  }
}