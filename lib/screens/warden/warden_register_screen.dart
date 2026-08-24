import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants.dart';
import 'warden_dashboard.dart';
import '../../utils/remote_config_helper.dart';
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}
class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController     = TextEditingController();
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  final _codeController     = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedHostel = 'CET Boys';
  Future<void> _register() async {
    if (_nameController.text.trim().isEmpty) { setState(() => _errorMessage = 'Please enter your name.'); return; }
    await RemoteConfigHelper.refresh(); // Fresh code fetch karo
    if (_codeController.text.trim() != RemoteConfigHelper.wardenCode) {
      setState(() => _errorMessage = 'Invalid admin code. Contact college administration.');
      return;
    }
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(), password: _passwordController.text.trim());
      await FirebaseFirestore.instance.collection('wardens').doc(cred.user!.uid).set({
        'name': _nameController.text.trim(), 'email': _emailController.text.trim(),
        'role': 'Warden', 'hostelBlock': _selectedHostel,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const WardenDashboard()));
    } on FirebaseAuthException catch (e) {
      setState(() { _errorMessage = e.code == 'email-already-in-use' ? 'Email already exists.' : 'Registration failed.'; });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(backgroundColor: const Color(0xFF1A3A5C),
        title: const Text('Create Account', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white)),
      body: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 20),
          Center(child: Container(width: 70, height: 70,
            decoration: BoxDecoration(color: const Color(0xFF1A3A5C), borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.security, size: 40, color: Color(0xFFF0A500)))),
          const SizedBox(height: 24),
          const Text('Full Name', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A3A5C))),
          const SizedBox(height: 8),
          TextField(controller: _nameController, decoration: InputDecoration(hintText: 'Enter your full name',
            prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF1A3A5C)),
            filled: true, fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
          const SizedBox(height: 16),
          const Text('Email', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A3A5C))),
          const SizedBox(height: 8),
          TextField(controller: _emailController, keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(hintText: 'Enter your email',
              prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF1A3A5C)),
              filled: true, fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
          const SizedBox(height: 16),
          const Text('Password', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A3A5C))),
          const SizedBox(height: 8),
          TextField(controller: _passwordController, obscureText: true,
            decoration: InputDecoration(hintText: 'Min 6 characters',
              prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF1A3A5C)),
              filled: true, fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
          const SizedBox(height: 16),
          const Text('Admin Secret Code', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A3A5C))),
          const SizedBox(height: 8),
          TextField(controller: _codeController, obscureText: true,
            decoration: InputDecoration(hintText: 'Code given by college admin',
              prefixIcon: const Icon(Icons.vpn_key_outlined, color: Color(0xFF1A3A5C)),
              filled: true, fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
          const SizedBox(height: 16),
          const Text('Your Hostel', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A3A5C))),
          const SizedBox(height: 8),
          StatefulBuilder(builder: (context, setDropdown) =>
            DropdownButtonFormField<String>(
              value: _selectedHostel,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.home_work_outlined, color: Color(0xFF1A3A5C)),
                filled: true, fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
              items: kHostelBlocks.map((h) => DropdownMenuItem(value: h, child: Text(h, style: const TextStyle(fontSize: 14)))).toList(),
              onChanged: (val) => setState(() => _selectedHostel = val!),
            )),
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
            child: ElevatedButton(onPressed: _isLoading ? null : _register,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A3A5C),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: _isLoading ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                : const Text('CREATE ACCOUNT', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1)))),
        ]))),
    );
  }
}

