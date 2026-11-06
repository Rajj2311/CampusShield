import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/tenant.dart';
import '../../widgets/ui.dart';

/// All students, wardens, guards and workers of every hostel of this college.
class AdminPeopleTab extends StatefulWidget {
  const AdminPeopleTab({super.key});
  @override
  State<AdminPeopleTab> createState() => _AdminPeopleTabState();
}

class _AdminPeopleTabState extends State<AdminPeopleTab> {
  static const _groups = <MapEntry<String, String>>[
    MapEntry('students', 'Students'),
    MapEntry('wardens', 'Wardens'),
    MapEntry('guards', 'Guards'),
    MapEntry('workers', 'Workers'),
    MapEntry('complaints', 'Complaints'),
    MapEntry('leaveRequests', 'Leaves'),
    MapEntry('notices', 'Notices'),
  ];

  static const _loginGroups = ['wardens', 'guards', 'workers'];

  String _title(Map<String, dynamic> d) {
    for (final k in ['name', 'title', 'studentName', 'subject', 'category']) {
      final v = d[k];
      if (v != null && v.toString().isNotEmpty) return v.toString();
    }
    return 'Record';
  }

  /// Edit the simple fields (text, numbers, true/false) of a record.
  Future<void> _edit(String id, Map<String, dynamic> d) async {
    final fields = d.entries
        .where((e) => e.value is String || e.value is num || e.value is bool)
        .toList();
    final ctrls = {for (final e in fields) e.key: TextEditingController(text: e.value.toString())};
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit ${_title(d)}'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: fields
                .map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: TextField(
                        controller: ctrls[e.key],
                        decoration: InputDecoration(labelText: e.key, isDense: true),
                      ),
                    ))
                .toList(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );
    final updates = <String, dynamic>{};
    if (ok == true) {
      for (final e in fields) {
        final t = ctrls[e.key]!.text.trim();
        if (e.value is num) {
          final n = num.tryParse(t);
          if (n != null) updates[e.key] = n;
        } else if (e.value is bool) {
          updates[e.key] = t.toLowerCase() == 'true';
        } else {
          updates[e.key] = t;
        }
      }
    }
    for (final c in ctrls.values) {
      c.dispose();
    }
    if (updates.isEmpty) return;
    try {
      await Tenant.col(_group).doc(id).update(updates);
    } on FirebaseException {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Could not save the changes.')));
      }
    }
  }

  String _group = 'students';
  String _hostel = 'All';
  String _query = '';

  String _hostelOf(Map<String, dynamic> d) =>
      (d['block'] ?? d['hostelBlock'] ?? d['hostel'] ?? '').toString();

  String _subtitle(Map<String, dynamic> d) {
    final parts = <String>[];
    for (final k in ['roll', 'guardId', 'workerId', 'category', 'room']) {
      final v = d[k];
      if (v != null && v.toString().isNotEmpty) parts.add(v.toString());
    }
    final h = _hostelOf(d);
    if (h.isNotEmpty) parts.add(h);
    return parts.join('  |  ');
  }

  Future<void> _delete(String id, Map<String, dynamic> d) async {
    final name = (d['name'] ?? 'this person').toString();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete record?'),
        content: Text('Delete $name? This removes their record and their access to this college.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete', style: TextStyle(color: Color(0xFFC62828)))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final batch = FirebaseFirestore.instance.batch();
      batch.delete(Tenant.col(_group).doc(id));
      // Staff accounts use their uid as the document id; remove the login binding too.
      if (_loginGroups.contains(_group)) {
        batch.delete(FirebaseFirestore.instance.collection('userIndex').doc(id));
      }
      await batch.commit();
    } on FirebaseException {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Could not delete the record.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _groups
                .map((g) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(g.value),
                        selected: _group == g.key,
                        selectedColor: kAmber,
                        onSelected: (_) => setState(() => _group = g.key),
                      ),
                    ))
                .toList(),
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Row(children: [
          Expanded(
            child: TextField(
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(width: 8),
          DropdownButton<String>(
            value: ['All', ...Tenant.hostels].contains(_hostel) ? _hostel : 'All',
            items: ['All', ...Tenant.hostels]
                .map((h) => DropdownMenuItem(value: h, child: Text(h)))
                .toList(),
            onChanged: (v) => setState(() => _hostel = v ?? 'All'),
          ),
        ]),
      ),
      Expanded(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: Tenant.col(_group).snapshots(),
          builder: (context, snap) {
            if (snap.hasError) return const Center(child: Text('Could not load records.'));
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator(color: kNavy));
            }
            final docs = snap.data!.docs.where((d) {
              final m = d.data();
              if (_hostel != 'All' && _hostelOf(m) != _hostel) return false;
              if (_query.isEmpty) return true;
              return m.values.any((v) => v.toString().toLowerCase().contains(_query));
            }).toList();
            if (docs.isEmpty) {
              return const Center(
                  child: Text('No records found.', style: TextStyle(color: Colors.black54)));
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: docs.length,
              itemBuilder: (context, i) {
                final m = docs[i].data();
                return SectionCard(
                  child: Row(children: [
                    CircleAvatar(
                        backgroundColor: kNavy,
                        child: Text(_title(m)[0].toUpperCase(),
                            style: const TextStyle(color: Colors.white))),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(_title(m),
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text(_subtitle(m),
                            style: const TextStyle(color: Colors.black54, fontSize: 12)),
                      ]),
                    ),
                    IconButton(
                      tooltip: 'Edit',
                      icon: const Icon(Icons.edit_outlined, color: kNavy),
                      onPressed: () => _edit(docs[i].id, m),
                    ),
                    IconButton(
                      tooltip: 'Delete',
                      icon: const Icon(Icons.delete_outline, color: Color(0xFFC62828)),
                      onPressed: () => _delete(docs[i].id, m),
                    ),
                  ]),
                );
              },
            );
          },
        ),
      ),
    ]);
  }
}
