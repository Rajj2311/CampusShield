import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../json_codec.dart';
import '../theme.dart';

/// Lists the documents of any collection (owner has full access).
class DataBrowser extends StatelessWidget {
  final String title;
  final CollectionReference<Map<String, dynamic>> ref;
  const DataBrowser({super.key, required this.title, required this.ref});

  String _label(String id, Map<String, dynamic> d) {
    for (final k in ['name', 'title', 'collegeName', 'email', 'label']) {
      final v = d[k];
      if (v is String && v.isNotEmpty) return v;
    }
    return id;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kNavy,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(title,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: kAmber,
        onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => DocEditor(ref: ref, docId: null, data: const {}))),
        child: const Icon(Icons.add, color: kNavy),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: ref.limit(300).snapshots(),
        builder: (context, snap) {
          if (snap.hasError) return Center(child: Text('Could not load.\n${snap.error}'));
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return const Center(
                child: Text('No documents.', style: TextStyle(color: Colors.black54)));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final d = docs[i];
              return Card2(
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => DocEditor(ref: ref, docId: d.id, data: d.data()))),
                child: Row(children: [
                  const Icon(Icons.description_outlined, color: kNavy),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_label(d.id, d.data()),
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text(d.id,
                          style: const TextStyle(color: Colors.black45, fontSize: 11)),
                    ]),
                  ),
                  const Icon(Icons.chevron_right),
                ]),
              );
            },
          );
        },
      ),
    );
  }
}

/// Edit a document as JSON, delete it, or open one of its sub-collections.
class DocEditor extends StatefulWidget {
  final CollectionReference<Map<String, dynamic>> ref;
  final String? docId; // null = new document
  final Map<String, dynamic> data;
  const DocEditor({super.key, required this.ref, required this.docId, required this.data});
  @override
  State<DocEditor> createState() => _DocEditorState();
}

class _DocEditorState extends State<DocEditor> {
  late final _json = TextEditingController(
      text: const JsonEncoder.withIndent('  ').convert(encodeValue(widget.data)));
  late final _id = TextEditingController(text: widget.docId ?? '');
  final _sub = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _json.dispose();
    _id.dispose();
    _sub.dispose();
    super.dispose();
  }

  void _msg(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _save() async {
    Map<String, dynamic> map;
    try {
      final decoded = jsonDecode(_json.text);
      if (decoded is! Map) throw const FormatException('Top level must be an object');
      map = Map<String, dynamic>.from(decodeValue(decoded) as Map);
    } on FormatException catch (e) {
      _msg('Invalid JSON: ${e.message}');
      return;
    }
    final id = _id.text.trim();
    setState(() => _busy = true);
    try {
      if (widget.docId == null) {
        if (id.isEmpty) {
          await widget.ref.add(map);
        } else {
          await widget.ref.doc(id).set(map);
        }
      } else {
        await widget.ref.doc(widget.docId).set(map);
      }
      if (mounted) Navigator.pop(context);
    } on FirebaseException catch (e) {
      _msg('Save failed: ${e.message ?? e.code}');
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete document?'),
        content: Text('${widget.ref.path}/${widget.docId}\n\nThis cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete', style: TextStyle(color: kRed))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await widget.ref.doc(widget.docId).delete();
      if (mounted) Navigator.pop(context);
    } on FirebaseException catch (e) {
      _msg('Delete failed: ${e.message ?? e.code}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.docId == null;
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kNavy,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(isNew ? 'New document' : 'Edit document',
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        actions: [
          if (!isNew)
            IconButton(
                tooltip: 'Delete',
                icon: const Icon(Icons.delete_outline, color: Colors.white),
                onPressed: _delete),
        ],
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Text(widget.ref.path, style: const TextStyle(color: Colors.black54, fontSize: 12)),
        const SizedBox(height: 8),
        if (isNew)
          TextField(
              controller: _id,
              decoration: const InputDecoration(
                  labelText: 'Document ID (leave empty for automatic)',
                  filled: true,
                  fillColor: Colors.white)),
        const SizedBox(height: 8),
        TextField(
          controller: _json,
          maxLines: null,
          minLines: 12,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          decoration: const InputDecoration(filled: true, fillColor: Colors.white),
        ),
        const SizedBox(height: 4),
        const Text(
            'Dates are written as {"_ts": milliseconds}. Saving replaces the whole document.',
            style: TextStyle(color: Colors.black54, fontSize: 11)),
        const SizedBox(height: 12),
        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: _busy ? null : _save,
            style: ElevatedButton.styleFrom(backgroundColor: kNavy, foregroundColor: Colors.white),
            child: const Text('SAVE'),
          ),
        ),
        if (!isNew) ...[
          const SizedBox(height: 20),
          Row(children: [
            Expanded(
              child: TextField(
                  controller: _sub,
                  decoration: const InputDecoration(
                      labelText: 'Open sub-collection (name)',
                      filled: true,
                      fillColor: Colors.white)),
            ),
            IconButton(
              icon: const Icon(Icons.folder_open, color: kNavy),
              onPressed: () {
                final n = _sub.text.trim();
                if (n.isEmpty) return;
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => DataBrowser(
                            title: '${widget.docId}/$n',
                            ref: widget.ref.doc(widget.docId).collection(n))));
              },
            ),
          ]),
        ],
      ]),
    );
  }
}
