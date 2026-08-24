import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'warden_dashboard.dart';
import 'warden_register_screen.dart';

class WardenLoginScreen extends StatefulWidget {
  const WardenLoginScreen({super.key});
  @override
  State<WardenLoginScreen> createState() => _WardenLoginScreenState();
}
class _WardenLoginScreenState extends State<WardenLoginScreen> {
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading       = false;
  String? _errorMessage;

  void _showForgotPassword(BuildContext context) {
    final emailCtrl = TextEditingController();
    showModalBottomSheet(context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Reset Password', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A3A5C))),
          const SizedBox(height: 6),
          const Text('Enter your email — reset link will be sent to your inbox.',
            style: TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 16),
          TextField(controller: emailCtrl, keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(hintText: 'Enter your email',
              prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF1A3A5C)),
              filled: true, fillColor: const Color(0xFFF5F7FA),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, height: 48,
            child: ElevatedButton(
              onPressed: () async {
                final email = emailCtrl.text.trim();
                if (email.isEmpty) return;
                try {
                  await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                  Navigator.pop(ctx);
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('✅ Reset link sent! Check your inbox.'),
                      backgroundColor: Color(0xFF2E7D32)));
                } catch (e) {
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('❌ Email not found. Check and try again.'),
                      backgroundColor: Color(0xFFC62828)));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A3A5C),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('SEND RESET LINK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
          const SizedBox(height: 24),
        ])));
  }

  Future<void> _login() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const WardenDashboard()));
    } on FirebaseAuthException catch (e) {
      setState(() { _errorMessage = 'Login failed. Check email and password.'; });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(backgroundColor: const Color(0xFF1A3A5C),
        title: const Text('Warden Login', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white)),
      body: SafeArea(child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 40),
          Center(child: Container(width: 70, height: 70,
            decoration: BoxDecoration(color: const Color(0xFF1A3A5C), borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.admin_panel_settings, size: 40, color: Color(0xFFF0A500)))),
          const SizedBox(height: 24),
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
          TextField(controller: _passwordController, obscureText: _obscurePassword,
            decoration: InputDecoration(hintText: 'Enter your password',
              prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF1A3A5C)),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword)),
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
              onPressed: _isLoading ? null : _login,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A3A5C),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                : const Text('LOGIN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2)))),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            TextButton(
              onPressed: () => _showForgotPassword(context),
              child: const Text('Forgot Password?', style: TextStyle(color: Color(0xFFC62828), fontSize: 13))),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
              child: const Text('New warden? Create account', style: TextStyle(color: Color(0xFF1A3A5C)))),
          ]),
        ]),
      )),
    );
  }
}

