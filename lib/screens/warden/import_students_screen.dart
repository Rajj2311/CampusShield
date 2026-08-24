import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' hide Border;
import '../../utils/warden_helper.dart';

class ImportStudentsScreen extends StatefulWidget {
  const ImportStudentsScreen({super.key});
  @override
  State<ImportStudentsScreen> createState() => _ImportStudentsScreenState();
}

class _ImportStudentsScreenState extends State<ImportStudentsScreen> {
  String? _wardenHostel;
  bool    _isLoading = false;
  int     _imported  = 0;
  int     _failed    = 0;
  List<Map<String, String>> _preview = [];
  List<Map<String, String>> _allRows = [];
  String? _fileName;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final h = await WardenHelper.getMyHostel();
    setState(() => _wardenHostel = h);
  }

  Future<void> _pickFile() async {
    setState(() {
      _error   = null;
      _preview = [];
      _allRows = [];
      _fileName = null;
    });
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        withData: true, // ensures bytes are populated on web too, not just a file path
      );
      if (result == null || result.files.single.bytes == null) return;

      final bytes = result.files.single.bytes!;
      final name  = result.files.single.name;
      setState(() => _fileName = name);

      final excel = Excel.decodeBytes(bytes);

      if (excel.tables.isEmpty) {
        setState(() => _error = 'No sheets found in file.');
        return;
      }

      final sheet = excel.tables[excel.tables.keys.first]!;
      if (sheet.rows.isEmpty) {
        setState(() => _error = 'File is empty.');
        return;
      }

      final rows = <Map<String, String>>[];
      for (int i = 1; i < sheet.rows.length; i++) {
        final row = sheet.rows[i];
        if (row.every((cell) =>
            cell == null || (cell.value?.toString().trim() ?? '').isEmpty)) {
          continue;
        }
        String cell(int idx) => row.length > idx
            ? (row[idx]?.value?.toString().trim() ?? '') : '';
        rows.add({
          'name':           cell(0),
          'roll':           cell(1).toUpperCase(),
          'room':           cell(2),
          'course':         cell(3),
          'phone':          cell(4),
          'parentName':     cell(5),
          'parentRelation': cell(6),
          'parentPhone1':   cell(7),
          'parentPhone2':   cell(8),
        });
      }

      if (rows.isEmpty) {
        setState(() => _error = 'No data rows found (row 1 is header).');
        return;
      }

      setState(() {
        _allRows = rows;
        _preview = rows.take(5).toList();
      });
    } catch (e) {
      setState(() => _error = 'Error reading file: ${e.toString()}');
    }
  }

  Future<void> _importAll() async {
    if (_allRows.isEmpty || _wardenHostel == null) return;
    setState(() { _isLoading = true; _imported = 0; _failed = 0; });

    for (final row in _allRows) {
      if ((row['name'] ?? '').isEmpty || (row['roll'] ?? '').isEmpty) {
        setState(() => _failed++);
        continue;
      }
      try {
        final existing = await FirebaseFirestore.instance
            .collection('students')
            .where('roll', isEqualTo: row['roll'])
            .limit(1).get();
        if (existing.docs.isNotEmpty) {
          setState(() => _failed++);
          continue;
        }
        await FirebaseFirestore.instance.collection('students').add({
          'name':           row['name'],
          'roll':           row['roll'],
          'room':           row['room'],
          'course':         row['course'],
          'phone':          row['phone'],
          'parentName':     row['parentName'],
          'parentRelation': row['parentRelation'],
          'parentPhone1':   row['parentPhone1'],
          'parentPhone2':   row['parentPhone2'],
          'block':          _wardenHostel,
          'hasAccount':     false,
          'todayStatus':    'absent',
          'createdAt':      FieldValue.serverTimestamp(),
        });
        setState(() => _imported++);
      } catch (_) {
        setState(() => _failed++);
      }
    }
    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('✅ Import done! $_imported added, $_failed skipped.'),
        backgroundColor: const Color(0xFF2E7D32)));
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
          const Text('Import Students', style: TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          Text(_wardenHostel ?? '', style: const TextStyle(
            color: Color(0xFFF0A500), fontSize: 11)),
        ]),
        iconTheme: const IconThemeData(color: Colors.white)),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [

          // ── Instructions ──────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF1565C0).withOpacity(0.3))),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Row(children: [
                Icon(Icons.info_outline,
                  color: Color(0xFF1565C0), size: 18),
                SizedBox(width: 8),
                Text('Excel Format (.xlsx)', style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1565C0), fontSize: 14)),
              ]),
              SizedBox(height: 10),
              Text(
                'Row 1 = Header (skipped automatically)\n\n'
                'Column order:\n'
                'A → Full Name\n'
                'B → Roll Number\n'
                'C → Room Number\n'
                'D → Course\n'
                'E → Student Phone\n'
                'F → Parent Name\n'
                'G → Relation (Father/Mother)\n'
                'H → Parent Phone 1\n'
                'I → Parent Phone 2 (optional)',
                style: TextStyle(fontSize: 12,
                  color: Color(0xFF1565C0), height: 1.5)),
            ])),
          const SizedBox(height: 20),

          // ── Pick File Button ──────────────────────────────
          SizedBox(width: double.infinity, height: 52,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.upload_file, color: Colors.white),
              label: Text(
                _fileName != null
                    ? '📄 $_fileName'
                    : 'SELECT EXCEL FILE (.xlsx)',
                style: const TextStyle(color: Colors.white,
                  fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis),
              onPressed: _pickFile,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12))))),

          // Error
          if (_error != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                const Icon(Icons.error_outline,
                  color: Color(0xFFC62828), size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(_error!,
                  style: const TextStyle(
                    color: Color(0xFFC62828), fontSize: 13))),
              ])),
          ],

          // ── Preview ───────────────────────────────────────
          if (_preview.isNotEmpty) ...[
            const SizedBox(height: 24),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
              Text('Preview (${_allRows.length} students found)',
                style: const TextStyle(fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A3A5C))),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8)),
                child: Text(_wardenHostel ?? '',
                  style: const TextStyle(
                    color: Color(0xFF2E7D32), fontSize: 11,
                    fontWeight: FontWeight.w600))),
            ]),
            const SizedBox(height: 10),

            ..._preview.map((row) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 4)]),
              child: Row(children: [
                CircleAvatar(radius: 18,
                  backgroundColor: const Color(0xFF1A3A5C)
                      .withOpacity(0.1),
                  child: Text(
                    (row['name'] ?? '?').isNotEmpty
                        ? (row['name']!)[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Color(0xFF1A3A5C), fontSize: 13,
                      fontWeight: FontWeight.bold))),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  Text(row['name'] ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13)),
                  Text(
                    '${row['roll']}  •  '
                    'Room ${row['room']}  •  ${row['course']}',
                    style: const TextStyle(
                      fontSize: 11, color: Colors.grey)),
                  if ((row['parentName'] ?? '').isNotEmpty)
                    Text('Parent: ${row['parentName']} '
                         '(${row['parentPhone1']})',
                      style: const TextStyle(
                        fontSize: 10, color: Colors.grey)),
                ])),
              ]))),

            if (_allRows.length > 5)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  '... and ${_allRows.length - 5} more students',
                  style: const TextStyle(
                    color: Colors.grey, fontSize: 12,
                    fontStyle: FontStyle.italic))),

            const SizedBox(height: 20),

            // Import Button
            SizedBox(width: double.infinity, height: 54,
              child: ElevatedButton.icon(
                icon: _isLoading
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.cloud_upload, color: Colors.white),
                label: Text(
                  _isLoading
                    ? 'Importing... $_imported / ${_allRows.length}'
                    : 'IMPORT ALL ${_allRows.length} STUDENTS',
                  style: const TextStyle(color: Colors.white,
                    fontWeight: FontWeight.bold, fontSize: 14)),
                onPressed: _isLoading ? null : _importAll,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A3A5C),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))))),
          ],

          // ── Result ────────────────────────────────────────
          if (!_isLoading && (_imported > 0 || _failed > 0)) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8)]),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                Column(children: [
                  const Icon(Icons.check_circle,
                    color: Color(0xFF2E7D32), size: 32),
                  const SizedBox(height: 6),
                  Text('$_imported', style: const TextStyle(
                    fontSize: 28, fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32))),
                  const Text('Imported',
                    style: TextStyle(color: Color(0xFF2E7D32))),
                ]),
                Container(width: 1, height: 60,
                  color: Colors.grey.shade200),
                Column(children: [
                  const Icon(Icons.skip_next,
                    color: Color(0xFFF0A500), size: 32),
                  const SizedBox(height: 6),
                  Text('$_failed', style: const TextStyle(
                    fontSize: 28, fontWeight: FontWeight.bold,
                    color: Color(0xFFF0A500))),
                  const Text('Skipped (duplicates)',
                    style: TextStyle(color: Color(0xFFF0A500))),
                ]),
              ])),
          ],

          const SizedBox(height: 20),
        ])),
    );
  }
}