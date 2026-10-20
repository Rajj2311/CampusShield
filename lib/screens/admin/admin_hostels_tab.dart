import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/tenant.dart';
import '../../widgets/ui.dart';

/// Add or remove the hostels of this college.
class AdminHostelsTab extends StatefulWidget {
  const AdminHostelsTab({super.key});
  @override
  State<AdminHostelsTab> createState() => _AdminHostelsTabState();
}

class _AdminHostelsTabState extends State<AdminHostelsTab> {
  final _ctrl = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final name = _ctrl.text.trim();
    if (name.isEmpty) return;
    if (Tenant.hostels.any((h) => h.toLowerCase() == name.toLowerCase())) {
      setState(() => _error = 'This hostel already exists.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await Tenant.doc.update({'hostels': FieldValue.arrayUnion([name])});
      await Tenant.reload();
      _ctrl.clear();
    } on FirebaseException {
      _error = 'Could not add the hostel. Try again.';
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _remove(String name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove hostel?'),
        content: Text(
            'Remove "$name" from the list? Existing students and wardens of this hostel are not deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Remove', style: TextStyle(color: Color(0xFFC62828)))),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      await Tenant.doc.update({'hostels': FieldValue.arrayRemove([name])});
      await Tenant.reload();
    } on FirebaseException {
      _error = 'Could not remove the hostel. Try again.';
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final hostels = Tenant.hostels;
    return ListView(padding: const EdgeInsets.all(16), children: [
      const Text('Hostels',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kNavy)),
      const SizedBox(height: 4),
      const Text('Wardens choose their hostel from this list when they register.',
          style: TextStyle(color: Colors.black54)),
      const SizedBox(height: 16),
      Row(children: [
        Expanded(
          child: TextField(
            controller: _ctrl,
            textCapitalization: TextCapitalization.words,
            onSubmitted: (_) => _add(),
            decoration: InputDecoration(
              hintText: 'New hostel name',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filled(
          onPressed: _busy ? null : _add,
          icon: const Icon(Icons.add),
          style: IconButton.styleFrom(backgroundColor: kAmber),
        ),
      ]),
      if (_error != null) ...[
        const SizedBox(height: 12),
        ErrorBanner(_error!),
      ],
      const SizedBox(height: 16),
      ...hostels.map((h) => SectionCard(
            child: Row(children: [
              const Icon(Icons.home_work, color: kNavy),
              const SizedBox(width: 12),
              Expanded(child: Text(h, style: const TextStyle(fontWeight: FontWeight.w600))),
              IconButton(
                tooltip: 'Remove',
                icon: const Icon(Icons.delete_outline, color: Color(0xFFC62828)),
                onPressed: _busy ? null : () => _remove(h),
              ),
            ]),
          )),
    ]);
  }
}
