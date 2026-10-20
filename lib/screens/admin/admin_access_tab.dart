import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/role_codes.dart';
import '../../utils/tenant.dart';
import '../../widgets/ui.dart';

/// Registration codes for staff + list of wardens.
class AdminAccessTab extends StatelessWidget {
  const AdminAccessTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(16), children: const [
      Text('Registration codes',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kNavy)),
      SizedBox(height: 4),
      Text(
          'Share a code with the right people. They enter it when creating their account. Regenerating a code does not affect people who already registered.',
          style: TextStyle(color: Colors.black54, height: 1.4)),
      SizedBox(height: 16),
      _CodesCard(),
      SizedBox(height: 8),
      Text('Wardens',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kNavy)),
      SizedBox(height: 12),
      _WardensList(),
    ]);
  }
}

class _CodesCard extends StatelessWidget {
  const _CodesCard();

  static const _roles = <MapEntry<String, String>>[
    MapEntry('warden', 'Warden'),
    MapEntry('guard', 'Guard'),
    MapEntry('worker', 'Worker'),
  ];

  Future<void> _regenerate(BuildContext context, String role, String label) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Regenerate $label code?'),
        content: const Text('The old code will stop working for new registrations.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Regenerate')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await Tenant.col('settings').doc('codes').set(
          {role: generateRoleCode(role.toUpperCase())}, SetOptions(merge: true));
    } on FirebaseException {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not regenerate the code.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: Tenant.col('settings').doc('codes').snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return const ErrorBanner('Could not load the codes.');
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator(color: kNavy));
        }
        final data = snap.data!.data() ?? {};
        return Column(
          children: _roles.map((r) {
            final code = data[r.key] as String?;
            return SectionCard(
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${r.value} code',
                        style: const TextStyle(color: Colors.black54, fontSize: 12)),
                    const SizedBox(height: 4),
                    SelectableText(code ?? 'Not set',
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: kNavy,
                            letterSpacing: 1)),
                  ]),
                ),
                if (code != null)
                  IconButton(
                    tooltip: 'Copy',
                    icon: const Icon(Icons.copy, color: kNavy),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: code));
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${r.value} code copied')));
                    },
                  ),
                IconButton(
                  tooltip: 'Regenerate',
                  icon: const Icon(Icons.refresh, color: kAmber),
                  onPressed: () => _regenerate(context, r.key, r.value),
                ),
              ]),
            );
          }).toList(),
        );
      },
    );
  }
}

class _WardensList extends StatelessWidget {
  const _WardensList();

  Future<void> _remove(BuildContext context, String id, String name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove warden?'),
        content: Text('$name will lose access to this college.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Remove', style: TextStyle(color: Color(0xFFC62828)))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final batch = FirebaseFirestore.instance.batch();
      batch.delete(Tenant.col('wardens').doc(id));
      batch.delete(FirebaseFirestore.instance.collection('userIndex').doc(id));
      await batch.commit();
    } on FirebaseException {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not remove the warden.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: Tenant.col('wardens').snapshots(),
      builder: (context, snap) {
        if (snap.hasError) return const ErrorBanner('Could not load wardens.');
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator(color: kNavy));
        }
        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return const Text('No wardens yet. Share the warden code to invite them.',
              style: TextStyle(color: Colors.black54));
        }
        return Column(
          children: docs.map((d) {
            final w = d.data();
            final name = (w['name'] as String?) ?? 'Warden';
            return SectionCard(
              child: Row(children: [
                const CircleAvatar(
                    backgroundColor: kNavy,
                    child: Icon(Icons.admin_panel_settings, color: Colors.white)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text('${w['hostelBlock'] ?? '-'}',
                        style: const TextStyle(color: Colors.black54, fontSize: 12)),
                    Text('${w['email'] ?? ''}',
                        style: const TextStyle(color: Colors.black45, fontSize: 12)),
                  ]),
                ),
                IconButton(
                  tooltip: 'Remove',
                  icon: const Icon(Icons.person_remove_outlined, color: Color(0xFFC62828)),
                  onPressed: () => _remove(context, d.id, name),
                ),
              ]),
            );
          }).toList(),
        );
      },
    );
  }
}
