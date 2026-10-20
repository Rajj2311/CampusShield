import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/warden_helper.dart';
import '../../utils/tenant.dart';

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});
  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
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

  // ── Section Label ─────────────────────────────────────────────
  Widget _sectionLabel(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0xFF1A3A5C).withOpacity(0.08),
      borderRadius: BorderRadius.circular(8)),
    child: Row(children: [
      Container(width: 3, height: 14,
        decoration: BoxDecoration(
          color: const Color(0xFF1A3A5C),
          borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 8),
      Text(text, style: const TextStyle(
        fontSize: 13, fontWeight: FontWeight.bold,
        color: Color(0xFF1A3A5C))),
    ]));

  // ── Field Widget ──────────────────────────────────────────────
  Widget _buildField(TextEditingController ctrl, String hint,
      IconData icon, {TextInputType? type}) =>
    TextField(controller: ctrl, keyboardType: type,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13),
        prefixIcon: Icon(icon, color: const Color(0xFF1A3A5C), size: 20),
        filled: true, fillColor: const Color(0xFFF5F7FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 14)));

  // ── Add Student Form ──────────────────────────────────────────
  void _showAddStudent(BuildContext context) {
    final nameCtrl         = TextEditingController();
    final rollCtrl         = TextEditingController();
    final roomCtrl         = TextEditingController();
    final phoneCtrl        = TextEditingController();
    final courseCtrl       = TextEditingController();
    final parentNameCtrl   = TextEditingController();
    final parentPhone1Ctrl = TextEditingController();
    final parentPhone2Ctrl = TextEditingController();
    final relationCtrl     = TextEditingController();

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
            const Text('Add Student', style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold,
              color: Color(0xFF1A3A5C))),
            const SizedBox(height: 16),

            // Student Details
            _sectionLabel('Student Details'),
            const SizedBox(height: 8),
            _buildField(nameCtrl, 'Full Name', Icons.person_outline),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _buildField(
                rollCtrl, 'Roll Number', Icons.badge_outlined)),
              const SizedBox(width: 10),
              Expanded(child: _buildField(
                roomCtrl, 'Room Number',
                Icons.door_back_door_outlined)),
            ]),
            const SizedBox(height: 10),
            _buildField(courseCtrl, 'Course (e.g. B.Tech CSE)',
              Icons.school_outlined),
            const SizedBox(height: 10),
            _buildField(phoneCtrl, 'Student Phone Number',
              Icons.phone_outlined, type: TextInputType.phone),
            const SizedBox(height: 16),

            // Parent Details
            _sectionLabel('Parent / Guardian Details'),
            const SizedBox(height: 8),
            _buildField(parentNameCtrl, 'Parent/Guardian Full Name',
              Icons.people_outline),
            const SizedBox(height: 10),
            _buildField(relationCtrl,
              'Relation (Father/Mother/Guardian)',
              Icons.family_restroom_outlined),
            const SizedBox(height: 10),
            _buildField(parentPhone1Ctrl, 'Primary Phone Number',
              Icons.phone_outlined, type: TextInputType.phone),
            const SizedBox(height: 10),
            _buildField(parentPhone2Ctrl, 'Alternate Phone (Optional)',
              Icons.phone_outlined, type: TextInputType.phone),
            const SizedBox(height: 20),

            // Submit Button
            SizedBox(width: double.infinity, height: 50,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.person_add, color: Colors.white),
                label: const Text('ADD STUDENT',
                  style: TextStyle(color: Colors.white,
                    fontWeight: FontWeight.bold, fontSize: 15)),
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty ||
                      rollCtrl.text.trim().isEmpty) return;
                  await Tenant.col('students').add({
                    'name':           nameCtrl.text.trim(),
                    'roll':           rollCtrl.text.trim().toUpperCase(),
                    'room':           roomCtrl.text.trim(),
                    'block':          _wardenHostel ?? '',
                    'course':         courseCtrl.text.trim(),
                    'phone':          phoneCtrl.text.trim(),
                    'parentName':     parentNameCtrl.text.trim(),
                    'parentRelation': relationCtrl.text.trim(),
                    'parentPhone1':   parentPhone1Ctrl.text.trim(),
                    'parentPhone2':   parentPhone2Ctrl.text.trim(),
                    'hasAccount':     false,
                    'todayStatus':    'absent',
                    'createdAt':      FieldValue.serverTimestamp(),
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A3A5C),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))))),
            const SizedBox(height: 24),
          ]))));
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
          const Text('Students', style: TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold,
            fontSize: 16)),
          Text(_wardenHostel!, style: const TextStyle(
            color: Color(0xFFF0A500), fontSize: 11)),
        ]),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add, color: Colors.white),
            onPressed: () => _showAddStudent(context)),
        ]),
      body: StreamBuilder<QuerySnapshot>(
        stream: Tenant.col('students')
            .where('block', isEqualTo: _wardenHostel)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF1A3A5C)));

          final docs = snap.data!.docs;
          if (docs.isEmpty) return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
              Icon(Icons.people_outline, size: 64, color: Colors.grey),
              SizedBox(height: 12),
              Text('No students added yet.',
                style: TextStyle(color: Colors.grey, fontSize: 14)),
              SizedBox(height: 6),
              Text('Tap + to add a student',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
            ]));

          return Column(children: [
            Container(color: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 10),
              child: Row(children: [
                const Icon(Icons.people,
                  color: Color(0xFF1A3A5C), size: 18),
                const SizedBox(width: 8),
                Text('${docs.length} students in $_wardenHostel',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A3A5C), fontSize: 13)),
              ])),
            const Divider(height: 1),
            Expanded(child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: docs.length,
              itemBuilder: (context, i) {
                final doc = docs[i];
                final d   = doc.data() as Map<String, dynamic>;
                final hasAccount = d['hasAccount'] ?? false;
                final hasParent  = (d['parentName'] ?? '').toString().isNotEmpty;

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 6)]),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    Row(children: [
                      CircleAvatar(
                        backgroundColor: const Color(0xFF1A3A5C)
                            .withOpacity(0.1),
                        child: Text(
                          (d['name'] ?? '?')[0].toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFF1A3A5C),
                            fontWeight: FontWeight.bold))),
                      const SizedBox(width: 12),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                        Text(d['name'] ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                        Text(
                          '${d['roll'] ?? ''}  •  Room ${d['room'] ?? ''}',
                          style: const TextStyle(
                            fontSize: 11, color: Colors.grey)),
                        if ((d['course'] ?? '').toString().isNotEmpty)
                          Text(d['course'] ?? '',
                            style: const TextStyle(
                              fontSize: 11, color: Colors.grey)),
                      ])),
                      Column(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: hasAccount
                                ? const Color(0xFF2E7D32).withOpacity(0.1)
                                : const Color(0xFFF0A500).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8)),
                          child: Text(
                            hasAccount ? 'Active' : 'No Account',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: hasAccount
                                  ? const Color(0xFF2E7D32)
                                  : const Color(0xFFF0A500)))),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () => showDialog(context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Remove Student?'),
                              content: Text(
                                '${d['name']} will be removed.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel')),
                                TextButton(
                                  onPressed: () {
                                    Tenant.col('students')
                                        .doc(doc.id).delete();
                                    Navigator.pop(context);
                                  },
                                  child: const Text('Remove',
                                    style: TextStyle(
                                      color: Color(0xFFC62828)))),
                              ])),
                          child: const Icon(Icons.delete_outline,
                            color: Colors.grey, size: 18)),
                      ]),
                    ]),

                    // Parent info preview
                    if (hasParent) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8E1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFFF0A500)
                                .withOpacity(0.3))),
                        child: Row(children: [
                          const Icon(Icons.family_restroom,
                            size: 13, color: Color(0xFFF0A500)),
                          const SizedBox(width: 6),
                          Expanded(child: Text(
                            '${d['parentName']} '
                            '(${d['parentRelation'] ?? ''}) • '
                            '${d['parentPhone1'] ?? ''}',
                            style: const TextStyle(
                              fontSize: 11, color: Colors.black87),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis)),
                        ])),
                    ],
                  ]));
              })),
          ]);
        }),
    );
  }
}