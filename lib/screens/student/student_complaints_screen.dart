import 'dart:io' as io;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../../constants.dart';
import '../../utils/image_upload_helper.dart';

class StudentComplaintsScreen extends StatefulWidget {
  final Map<String, dynamic> studentData;
  const StudentComplaintsScreen({super.key, required this.studentData});
  @override
  State<StudentComplaintsScreen> createState() => _StudentComplaintsScreenState();
}

class _StudentComplaintsScreenState extends State<StudentComplaintsScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl  = TextEditingController();
  String _category = 'Electrician';
  XFile? _beforePhoto;
  bool   _isLoading = false;

  // ── Photo Pick ──────────────────────────────────────────────────────
  Future<void> _pickPhoto() async {
    final file = await ImageUploadHelper.showPickerDialog(context);
    if (file != null) setState(() => _beforePhoto = file);
  }

  // ── Submit ──────────────────────────────────────────────────────────
  Future<void> _submitComplaint() async {
    if (_titleCtrl.text.trim().isEmpty || _descCtrl.text.trim().isEmpty) {
      _snack('❌ Please fill in title and description.', error: true); return;
    }
    // Photo optional jab tak Storage enable na ho
    // if (_beforePhoto == null) {
    //   _snack('❌ Please upload a photo of the issue.', error: true); return;
    // }
    setState(() => _isLoading = true);
    try {
      // Photo upload temporarily disabled (Storage not enabled)
      final photoUrl = '';

      // Find warden of this hostel
      final block = widget.studentData['block'] ?? '';
      final wardenSnap = await FirebaseFirestore.instance
          .collection('wardens')
          .where('hostelBlock', isEqualTo: block)
          .limit(1).get();
      final wardenId = wardenSnap.docs.isNotEmpty ? wardenSnap.docs.first.id : '';

      // Find worker of this category (any hostel — workers serve all hostels)
      final workerSnap = await FirebaseFirestore.instance
          .collection('workers')
          .where('category', isEqualTo: _category)
          .limit(1).get();
      final workerId   = workerSnap.docs.isNotEmpty ? workerSnap.docs.first.id : '';
      final workerName = workerSnap.docs.isNotEmpty
          ? (workerSnap.docs.first.data()['name'] ?? '') : 'Unassigned';

      await FirebaseFirestore.instance.collection('complaints').add({
        'title':        _titleCtrl.text.trim(),
        'description':  _descCtrl.text.trim(),
        'category':     _category,
        'beforePhotoUrl': photoUrl,
        'afterPhotoUrl':  null,
        'status':       'Pending',       // Pending → In Progress → Resolved → Closed / Reopened
        'studentId':    FirebaseAuth.instance.currentUser?.uid ?? '',
        'studentName':  widget.studentData['name'] ?? '',
        'roll':         widget.studentData['roll'] ?? '',
        'room':         widget.studentData['room'] ?? '',
        'block':        block,
        'hostelBlock':  block,
        'assignedWorkerId':   workerId,
        'assignedWorkerName': workerName,
        'wardenId':     wardenId,
        'studentVerified': null,         // null → 'fixed' / 'not_fixed'
        'createdAt':    FieldValue.serverTimestamp(),
        'resolvedAt':   null,
        'closedAt':     null,
      });

      _titleCtrl.clear(); _descCtrl.clear();
      setState(() => _beforePhoto = null);
      _snack('✅ Complaint submitted! Assigned to $workerName.');
    } catch (e) {
      _snack('❌ Error: $e', error: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? const Color(0xFFC62828) : const Color(0xFF2E7D32)));
  }

  // ── Verify Fix (student side) ────────────────────────────────────────
  Future<void> _verifyFix(String complaintId, bool isFixed) async {
    await FirebaseFirestore.instance.collection('complaints').doc(complaintId).update({
      'studentVerified': isFixed ? 'fixed' : 'not_fixed',
      'status': isFixed ? 'Closed' : 'Reopened',
      'closedAt': isFixed ? FieldValue.serverTimestamp() : null,
    });
    _snack(isFixed ? '✅ Marked as Fixed & Closed!' : '🔄 Complaint Reopened!',
      error: !isFixed);
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'Resolved': return const Color(0xFF1565C0);
      case 'Closed':   return const Color(0xFF2E7D32);
      case 'Reopened': return const Color(0xFFC62828);
      case 'In Progress': return const Color(0xFFF57F17);
      default:         return const Color(0xFF9E9E9E);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(backgroundColor: const Color(0xFF1A3A5C),
        title: const Text('Complaints', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── New Complaint Form ───────────────────────────────────────
          Container(padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)]),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('New Complaint', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A3A5C))),
              const SizedBox(height: 16),

              // Title
              TextField(controller: _titleCtrl,
                decoration: InputDecoration(hintText: 'Short title (e.g. Fan not working)',
                  filled: true, fillColor: const Color(0xFFF5F7FA),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none))),
              const SizedBox(height: 12),

              // Category selector
              const Text('Category', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1A3A5C))),
              const SizedBox(height: 8),
              SizedBox(height: 40,
                child: ListView(scrollDirection: Axis.horizontal,
                  children: kWorkerCategories.map((cat) {
                    final sel = _category == cat['label'];
                    return GestureDetector(
                      onTap: () => setState(() => _category = cat['label']),
                      child: Container(margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: sel ? Color(cat['color']) : const Color(0xFFF5F7FA),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: sel ? Color(cat['color']) : Colors.grey.shade300)),
                        child: Row(children: [
                          Text(cat['icon'], style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 4),
                          Text(cat['label'], style: TextStyle(
                            color: sel ? Colors.white : Colors.black87,
                            fontSize: 12, fontWeight: FontWeight.w600)),
                        ])));
                  }).toList())),
              const SizedBox(height: 12),

              // Description
              TextField(controller: _descCtrl, maxLines: 3,
                decoration: InputDecoration(hintText: 'Describe the issue in detail...',
                  filled: true, fillColor: const Color(0xFFF5F7FA),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none))),
              const SizedBox(height: 16),

              // Before Photo
              const Text('📸 Photo of Issue (Required)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1A3A5C))),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickPhoto,
                child: Container(height: 160, width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F7FA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _beforePhoto != null ? const Color(0xFF2E7D32) : Colors.grey.shade300,
                      width: _beforePhoto != null ? 2 : 1,
                      style: BorderStyle.solid)),
                  child: _beforePhoto != null
                    ? ClipRRect(borderRadius: BorderRadius.circular(12),
                        child: kIsWeb
                          ? Image.network(_beforePhoto!.path, fit: BoxFit.cover)
                          : Image.file(io.File(_beforePhoto!.path), fit: BoxFit.cover))
                    : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.add_a_photo_outlined, size: 36, color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        Text('Tap to upload issue photo', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                        Text('Camera or Gallery', style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
                      ]))),
              if (_beforePhoto != null) ...[
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 14),
                  const SizedBox(width: 4),
                  const Text('Photo added ✓', style: TextStyle(color: Color(0xFF2E7D32), fontSize: 12)),
                  const Spacer(),
                  TextButton(onPressed: _pickPhoto,
                    child: const Text('Change', style: TextStyle(fontSize: 12, color: Color(0xFF1A3A5C)))),
                ]),
              ],
              const SizedBox(height: 16),

              // Submit Button
              SizedBox(width: double.infinity, height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submitComplaint,
                  icon: _isLoading
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.send, color: Colors.white),
                  label: Text(_isLoading ? 'Submitting...' : 'SUBMIT COMPLAINT',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A3A5C),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
            ])),
          const SizedBox(height: 24),

          // ── My Complaints History ────────────────────────────────────
          const Text('My Complaints', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1A3A5C))),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('complaints')
                .where('roll', isEqualTo: widget.studentData['roll'])
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) return const Center(child: CircularProgressIndicator());
              if (snap.data!.docs.isEmpty)
                return const Text('No complaints yet.', style: TextStyle(color: Colors.grey));
              return Column(children: snap.data!.docs.map((doc) {
                final d      = doc.data() as Map<String, dynamic>;
                final status = d['status'] ?? 'Pending';
                final color  = _statusColor(status);
                final needsVerify = status == 'Resolved' && d['studentVerified'] == null;

                return Container(margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    // Header
                    Container(padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.08),
                        borderRadius: const BorderRadius.only(topLeft: Radius.circular(14), topRight: Radius.circular(14))),
                      child: Row(children: [
                        Text(kWorkerCategories.firstWhere(
                          (c) => c['label'] == d['category'],
                          orElse: () => {'icon': '🔩'})['icon'] ?? '🔩',
                          style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 10),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(d['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text('${d['category'] ?? ''} • Room ${d['room'] ?? ''}',
                            style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ])),
                        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                          child: Text(status, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold))),
                      ])),

                    Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(d['description'] ?? '', style: const TextStyle(fontSize: 13, color: Colors.black87)),
                      const SizedBox(height: 10),

                      // Assigned worker info
                      Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: const Color(0xFFF5F7FA), borderRadius: BorderRadius.circular(8)),
                        child: Row(children: [
                          const Icon(Icons.engineering, size: 14, color: Color(0xFF1A3A5C)),
                          const SizedBox(width: 6),
                          Text('Assigned to: ${d['assignedWorkerName'] ?? 'Unassigned'}',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF1A3A5C), fontWeight: FontWeight.w500)),
                        ])),
                      const SizedBox(height: 10),

                      // Before/After photos
                      Row(children: [
                        if (d['beforePhotoUrl'] != null)
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Text('Before:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey)),
                            const SizedBox(height: 4),
                            ClipRRect(borderRadius: BorderRadius.circular(8),
                              child: Image.network(d['beforePhotoUrl'], height: 90, width: double.infinity, fit: BoxFit.cover)),
                          ])),
                        if (d['beforePhotoUrl'] != null && d['afterPhotoUrl'] != null)
                          const SizedBox(width: 10),
                        if (d['afterPhotoUrl'] != null)
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Text('After (Fixed):', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey)),
                            const SizedBox(height: 4),
                            ClipRRect(borderRadius: BorderRadius.circular(8),
                              child: Image.network(d['afterPhotoUrl'], height: 90, width: double.infinity, fit: BoxFit.cover)),
                          ])),
                      ]),

                      // Verify Fix buttons (only when worker marks resolved)
                      if (needsVerify) ...[
                        const SizedBox(height: 12),
                        Container(padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: const Color(0xFFFFF8E1), borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFF0A500).withOpacity(0.4))),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Text('🔍 Worker marked as resolved. Is the issue fixed?',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A3A5C))),
                            const SizedBox(height: 10),
                            Row(children: [
                              Expanded(child: ElevatedButton.icon(
                                onPressed: () => _verifyFix(doc.id, false),
                                icon: const Icon(Icons.close, size: 16, color: Colors.white),
                                label: const Text('Not Fixed', style: TextStyle(color: Colors.white, fontSize: 12)),
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC62828),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))))),
                              const SizedBox(width: 10),
                              Expanded(child: ElevatedButton.icon(
                                onPressed: () => _verifyFix(doc.id, true),
                                icon: const Icon(Icons.check, size: 16, color: Colors.white),
                                label: const Text('Yes, Fixed!', style: TextStyle(color: Colors.white, fontSize: 12)),
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))))),
                            ]),
                          ])),
                      ],
                    ])),
                  ]));
              }).toList());
            }),
        ]),
      ),
    );
  }
}