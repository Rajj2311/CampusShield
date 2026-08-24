import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants.dart';
import 'worker_dashboard.dart';
import '../../utils/remote_config_helper.dart';

class WorkerRegisterScreen extends StatefulWidget {
  const WorkerRegisterScreen({super.key});
  @override
  State<WorkerRegisterScreen> createState() => _WorkerRegisterScreenState();
}
class _WorkerRegisterScreenState extends State<WorkerRegisterScreen> {
  final _nameCtrl  = TextEditingController();
  final _idCtrl    = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  final _codeCtrl  = TextEditingController();
  String _category = 'Electrician';
  bool   _loading  = false;
  String? _error;

  Future<void> _register() async {
    final wid = _idCtrl.text.trim().toUpperCase();
    if (_nameCtrl.text.trim().isEmpty || wid.isEmpty ||
        _emailCtrl.text.trim().isEmpty || _passCtrl.text.trim().length < 6) {
      setState(() => _error = 'Fill all fields. Password min 6 characters.'); return;
    }

    // Remote Config se fresh code fetch karo
    await RemoteConfigHelper.refresh();
    if (_codeCtrl.text.trim() != RemoteConfigHelper.workerCode) {
      setState(() => _error = 'Invalid security code. Contact your warden.'); return;
    }

    setState(() { _loading = true; _error = null; });
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(), password: _passCtrl.text.trim());
      final data = {
        'name': _nameCtrl.text.trim(),
        'workerId': wid,
        'email': _emailCtrl.text.trim(),
        'category': _category,
        'role': 'Worker',
        'createdAt': FieldValue.serverTimestamp(),
      };
      await FirebaseFirestore.instance.collection('workers').doc(cred.user!.uid).set(data);
      if (mounted) Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => WorkerDashboard(workerData: data, workerId: cred.user!.uid)));
    } on FirebaseAuthException catch (e) {
      setState(() { _error = e.code == 'email-already-in-use'
          ? 'Email already registered.' : 'Registration failed.'; });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(backgroundColor: const Color(0xFF1A3A5C),
        title: const Text('Worker Register', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white)),
      body: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 70, height: 70,
            decoration: BoxDecoration(color: const Color(0xFF1A3A5C), borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.engineering, size: 40, color: Color(0xFFF0A500)))),
          const SizedBox(height: 20),

          _label('Full Name'),
          _field(_nameCtrl, 'Enter your full name', Icons.person_outline),
          const SizedBox(height: 14),
          _label('Worker ID'),
          _field(_idCtrl, 'e.g. WRK001', Icons.badge_outlined),
          const SizedBox(height: 14),
          _label('Email'),
          _field(_emailCtrl, 'e.g. worker@gmail.com', Icons.email_outlined, email: true),
          const SizedBox(height: 4),
          const Text('⚠️ Use real email — password reset link sent here',
            style: TextStyle(fontSize: 11, color: Color(0xFFF0A500))),
          const SizedBox(height: 14),
          _label('Password'),
          _field(_passCtrl, 'Min 6 characters', Icons.lock_outline, obscure: true),
          const SizedBox(height: 14),

          // Category dropdown
          _label('Your Category'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _category,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.engineering, color: Color(0xFF1A3A5C)),
              filled: true, fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
            items: kWorkerCategories.map((c) => DropdownMenuItem(
              value: c['label'] as String,
              child: Text('${c['icon']}  ${c['label']}'))).toList(),
            onChanged: (v) => setState(() => _category = v!)),
          const SizedBox(height: 14),

          _label('Security Code'),
          _field(_codeCtrl, 'Code given by warden', Icons.vpn_key_outlined, obscure: true),

          if (_error != null) ...[
            const SizedBox(height: 12),
            Container(padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                const Icon(Icons.error_outline, color: Color(0xFFC62828), size: 18), const SizedBox(width: 8),
                Expanded(child: Text(_error!, style: const TextStyle(color: Color(0xFFC62828), fontSize: 13))),
              ])),
          ],
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, height: 52,
            child: ElevatedButton(onPressed: _loading ? null : _register,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A3A5C),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: _loading
                ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                : const Text('REGISTER', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2)))),
        ]))),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A3A5C))));

  Widget _field(TextEditingController ctrl, String hint, IconData icon,
      {bool obscure = false, bool email = false}) =>
    TextField(controller: ctrl, obscureText: obscure,
      keyboardType: email ? TextInputType.emailAddress : TextInputType.text,
      decoration: InputDecoration(hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF1A3A5C)),
        filled: true, fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)));
}