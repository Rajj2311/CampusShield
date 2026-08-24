import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants.dart';
import 'guard_dashboard.dart';
import '../../utils/remote_config_helper.dart';

class GuardRegisterScreen extends StatefulWidget {
  const GuardRegisterScreen({super.key});
  @override
  State<GuardRegisterScreen> createState() => _GuardRegisterScreenState();
}
final _emailController = TextEditingController();
class _GuardRegisterScreenState extends State<GuardRegisterScreen> {
  final _nameController = TextEditingController();
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();
  final _codeController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _register() async {
    final guardId = _idController.text.trim().toUpperCase();
    if (_nameController.text.trim().isEmpty || guardId.isEmpty || _passwordController.text.trim().length < 6) {
      setState(() => _errorMessage = 'Fill all fields. Password must be at least 6 characters.');
      return;
    }
    await RemoteConfigHelper.refresh();
    if (_codeController.text.trim() != RemoteConfigHelper.guardCode) {
      setState(() => _errorMessage = 'Invalid security code. Contact your warden.');
      return;
    }
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final realEmail = _emailController.text.trim();
      if (realEmail.isEmpty) {
        setState(() { _errorMessage = 'Please enter your email address.'; _isLoading = false; });
        return;
      }
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: realEmail, password: _passwordController.text.trim());
      await FirebaseFirestore.instance.collection('guards').doc(cred.user!.uid).set({
        'name': _nameController.text.trim(),
        'guardId': guardId,
        'email': realEmail,
        'role': 'Guard',
        'createdAt': FieldValue.serverTimestamp(),
      });
      final data = {'name': _nameController.text.trim(), 'guardId': guardId, 'role': 'Guard'};
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (_) => GuardDashboard(guardData: data)));
    } on FirebaseAuthException catch (e) {
      setState(() { _errorMessage = e.code == 'email-already-in-use' ? 'Guard ID already registered.' : 'Registration failed.'; });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(backgroundColor: const Color(0xFF1A3A5C),
        title: const Text('Guard Register', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white)),
      body: SafeArea(child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 20),
          Center(child: Container(width: 70, height: 70,
            decoration: BoxDecoration(color: const Color(0xFF1A3A5C), borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.qr_code_scanner, size: 40, color: Color(0xFFF0A500)))),
          const SizedBox(height: 16),
          const Text('Full Name', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A3A5C))),
          const SizedBox(height: 8),
          TextField(controller: _nameController,
            decoration: InputDecoration(hintText: 'Enter your full name',
              prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF1A3A5C)),
              filled: true, fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
          const SizedBox(height: 16),
          const Text('Guard ID', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A3A5C))),
          const SizedBox(height: 8),
          TextField(controller: _idController,
            decoration: InputDecoration(hintText: 'e.g. GRD001',
              prefixIcon: const Icon(Icons.badge_outlined, color: Color(0xFF1A3A5C)),
              filled: true, fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
          const SizedBox(height: 16),
          const Text('Your Email', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A3A5C))),
          const SizedBox(height: 8),
          TextField(controller: _emailController, keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(hintText: 'e.g. guard@gmail.com',
              prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF1A3A5C)),
              filled: true, fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
          const SizedBox(height: 4),
          const Text('⚠️ Use your real email — password reset link will come here',
            style: TextStyle(fontSize: 11, color: Color(0xFFF0A500))),
          const SizedBox(height: 16),
          const Text('Set Password', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A3A5C))),
          const SizedBox(height: 8),
          TextField(controller: _passwordController, obscureText: true,
            decoration: InputDecoration(hintText: 'Min 6 characters',
              prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF1A3A5C)),
              filled: true, fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
          const SizedBox(height: 16),
          const Text('Security Code', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A3A5C))),
          const SizedBox(height: 8),
          TextField(controller: _codeController, obscureText: true,
            decoration: InputDecoration(hintText: 'Code given by warden',
              prefixIcon: const Icon(Icons.vpn_key_outlined, color: Color(0xFF1A3A5C)),
              filled: true, fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Container(padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                const Icon(Icons.error_outline, color: Color(0xFFC62828), size: 18), const SizedBox(width: 8),
                Expanded(child: Text(_errorMessage!, style: const TextStyle(color: Color(0xFFC62828), fontSize: 13))),
              ])),
          ],
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _register,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A3A5C),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                : const Text('REGISTER', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2)))),
        ]),
      )),
    );
  }
}

