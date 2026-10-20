import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/ui.dart';
import '../auth_gate_screen.dart';

/// Login for college administrators (and for applicants checking their
/// request status). After sign-in the auth gate routes to the right screen.
class CollegeAdminLoginScreen extends StatefulWidget {
  const CollegeAdminLoginScreen({super.key});
  @override
  State<CollegeAdminLoginScreen> createState() =>
      _CollegeAdminLoginScreenState();
}

class _CollegeAdminLoginScreenState extends State<CollegeAdminLoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _email.text.trim(), password: _password.text.trim());
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AuthGateScreen()),
          (route) => false);
    } on FirebaseAuthException {
      setState(() => _error = 'Login failed. Check your email and password.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = _email.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Enter your email above first.');
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset email sent.')));
    } on FirebaseAuthException {
      setState(() => _error = 'Could not send the reset email.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kNavy,
        title: const Text('College Admin Login',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 24),
            Center(
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                    color: kNavy, borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.apartment, size: 40, color: kAmber),
              ),
            ),
            const SizedBox(height: 24),
            AppTextField(
                controller: _email,
                label: 'Email',
                hint: 'Enter your email',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress),
            AppTextField(
                controller: _password,
                label: 'Password',
                hint: 'Enter your password',
                icon: Icons.lock_outline,
                obscure: true),
            if (_error != null) ErrorBanner(_error!),
            PrimaryButton(label: 'LOGIN', loading: _loading, onPressed: _login),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: _forgotPassword,
                child: const Text('Forgot password?',
                    style: TextStyle(color: Color(0xFFC62828))),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
