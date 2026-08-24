import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/warden_helper.dart';

class NoticesScreen extends StatefulWidget {
  const NoticesScreen({super.key});
  @override
  State<NoticesScreen> createState() => _NoticesScreenState();
}

class _NoticesScreenState extends State<NoticesScreen> {
  String? _wardenHostel;

  @override
  void initState() {
    super.initState();
    _loadHostel();
  }

  Future<void> _loadHostel() async {
    final hostel = await WardenHelper.getMyHostel();
    setState(() => _wardenHostel = hostel);
  }

  void _showAddNotice(BuildContext context) {
    final titleCtrl = TextEditingController();
    final bodyCtrl  = TextEditingController();
    String urgency  = 'Normal';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 20, right: 20, top: 20),
          child: SingleChildScrollView(child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Post Notice',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                color: Color(0xFF1A3A5C))),
            const SizedBox(height: 14),

            // Title
            TextField(controller: titleCtrl,
              decoration: InputDecoration(hintText: 'Notice Title',
                filled: true, fillColor: const Color(0xFFF5F7FA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none))),
            const SizedBox(height: 10),

            // Body
            TextField(controller: bodyCtrl, maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Write notice details here...',
                filled: true, fillColor: const Color(0xFFF5F7FA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none))),
            const SizedBox(height: 12),

            // Urgency selector
            const Text('Urgency Level',
              style: TextStyle(fontWeight: FontWeight.w600,
                color: Color(0xFF1A3A5C), fontSize: 13)),
            const SizedBox(height: 8),
            Row(children: ['Normal', 'Urgent'].map((u) {
              final sel = urgency == u;
              final color = u == 'Urgent'
                  ? const Color(0xFFC62828)
                  : const Color(0xFF2E7D32);
              return GestureDetector(
                onTap: () => setModal(() => urgency = u),
                child: Container(
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: sel ? color : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color)),
                  child: Text(u, style: TextStyle(
                    color: sel ? Colors.white : color,
                    fontWeight: FontWeight.w600, fontSize: 13))));
            }).toList()),
            const SizedBox(height: 16),

            // Submit button
            SizedBox(width: double.infinity, height: 48,
              child: ElevatedButton(
                onPressed: () async {
                  if (titleCtrl.text.trim().isEmpty) return;
                  await FirebaseFirestore.instance
                      .collection('notices').add({
                    'title':       titleCtrl.text.trim(),
                    'body':        bodyCtrl.text.trim(),
                    'urgency':     urgency,
                    'hostelBlock': _wardenHostel ?? '',
                    'postedBy':    FirebaseAuth.instance.currentUser?.uid ?? '',
                    'createdAt':   FieldValue.serverTimestamp(),
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A3A5C),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
                child: const Text('POST NOTICE',
                  style: TextStyle(color: Colors.white,
                    fontWeight: FontWeight.bold, letterSpacing: 1)))),
            const SizedBox(height: 20),
          ])))));
  }

  Future<void> _deleteNotice(String docId) async {
    await FirebaseFirestore.instance
        .collection('notices').doc(docId).delete();
  }

  @override
  Widget build(BuildContext context) {
    if (_wardenHostel == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(
          color: Color(0xFF1A3A5C))));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A3A5C),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          const Text('Notice Board',
            style: TextStyle(color: Colors.white,
              fontWeight: FontWeight.bold, fontSize: 16)),
          Text(_wardenHostel!,
            style: const TextStyle(
              color: Color(0xFFF0A500), fontSize: 11)),
        ]),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () => _showAddNotice(context)),
        ]),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notices')
            .where('hostelBlock', isEqualTo: _wardenHostel)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(
            child: CircularProgressIndicator(color: Color(0xFF1A3A5C)));

          final docs = snap.data!.docs;
          if (docs.isEmpty) return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.campaign_outlined, size: 64, color: Colors.grey),
              SizedBox(height: 12),
              Text('No notices posted yet.',
                style: TextStyle(color: Colors.grey, fontSize: 14)),
              SizedBox(height: 6),
              Text('Tap + to post a new notice',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
            ]));

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final doc     = docs[i];
              final d       = doc.data() as Map<String, dynamic>;
              final urgency = d['urgency'] ?? 'Normal';
              final isUrgent = urgency == 'Urgent';
              final color   = isUrgent
                  ? const Color(0xFFC62828)
                  : const Color(0xFF1A3A5C);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: isUrgent
                      ? Border.all(color: const Color(0xFFC62828),
                          width: 1.5)
                      : null,
                  boxShadow: [BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8)]),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.07),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(14),
                        topRight: Radius.circular(14))),
                    child: Row(children: [
                      Icon(
                        isUrgent
                            ? Icons.warning_amber_rounded
                            : Icons.campaign_outlined,
                        color: color, size: 20),
                      const SizedBox(width: 8),
                      Expanded(child: Text(d['title'] ?? '',
                        style: TextStyle(fontWeight: FontWeight.bold,
                          fontSize: 14, color: color))),
                      // Urgency badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10)),
                        child: Text(urgency, style: TextStyle(
                          color: color, fontSize: 10,
                          fontWeight: FontWeight.bold))),
                      const SizedBox(width: 8),
                      // Delete button
                      GestureDetector(
                        onTap: () => showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Delete Notice?'),
                            content: const Text(
                              'This notice will be permanently deleted.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel')),
                              TextButton(
                                onPressed: () {
                                  _deleteNotice(doc.id);
                                  Navigator.pop(context);
                                },
                                child: const Text('Delete',
                                  style: TextStyle(
                                    color: Color(0xFFC62828)))),
                            ])),
                        child: const Icon(Icons.delete_outline,
                          color: Colors.grey, size: 18)),
                    ])),

                  // Body
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Text(d['body'] ?? '',
                      style: const TextStyle(
                        fontSize: 13, color: Colors.black87,
                        height: 1.5))),
                ]));
            });
        }),
    );
  }
}