import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'guard_dashboard.dart';
import 'guard_register_screen.dart';

class GuardLoginScreen extends StatefulWidget {
  const GuardLoginScreen({super.key});
  @override
  State<GuardLoginScreen> createState() => _GuardLoginScreenState();
}
class _GuardLoginScreenState extends State<GuardLoginScreen> {
  final _idController       = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading       = false;
  String? _errorMessage;

  Future<void> _login() async {
  setState(() { _isLoading = true; _errorMessage = null; });
  try {
    final guardId = _idController.text.trim().toUpperCase();
    if (guardId.isEmpty || _passwordController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter Guard ID and password.';
        _isLoading = false;
      });
      return;
    }

    // ✅ Step 1: Firestore se real email fetch karo
    // (guards collection publicly readable nahi hai, isliye
    //  pehle email dhundne ke liye temporary anonymous login)
    final snap = await FirebaseFirestore.instance
        .collection('guards')
        .where('guardId', isEqualTo: guardId)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) {
      setState(() {
        _errorMessage = 'Guard ID not registered.';
        _isLoading = false;
      });
      return;
    }

    final guardData = snap.docs.first.data();
    final realEmail = (guardData['email'] ?? '').toString().trim();

    if (realEmail.isEmpty) {
      setState(() {
        _errorMessage = 'No email found. Please re-register.';
        _isLoading = false;
      });
      return;
    }

    // ✅ Step 2: Real email se login karo
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: realEmail,
      password: _passwordController.text.trim(),
    );

    if (mounted) Navigator.pushReplacement(context,
      MaterialPageRoute(builder: (_) =>
        GuardDashboard(guardData: guardData)));

  } on FirebaseAuthException catch (e) {
    String msg;
    switch (e.code) {
      case 'user-not-found':
        msg = 'Guard ID not registered. Please register first.';
        break;
      case 'wrong-password':
      case 'invalid-credential':
        msg = 'Wrong password. Try again.';
        break;
      case 'too-many-requests':
        msg = 'Too many attempts. Please wait.';
        break;
      default:
        msg = 'Login failed: ${e.code}';
    }
    setState(() => _errorMessage = msg);
  } catch (e) {
    setState(() => _errorMessage = 'Error: ${e.toString()}');
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}

  void _showForgotPassword(BuildContext context) {
    final idCtrl = TextEditingController();
    showModalBottomSheet(context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Reset Password', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A3A5C))),
          const SizedBox(height: 6),
          const Text('Enter your Guard ID — reset link will be sent to your registered email.',
            style: TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 16),
          TextField(controller: idCtrl,
            decoration: InputDecoration(hintText: 'Enter your Guard ID (e.g. GRD001)',
              prefixIcon: const Icon(Icons.badge_outlined, color: Color(0xFF1A3A5C)),
              filled: true, fillColor: const Color(0xFFF5F7FA),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, height: 48,
            child: ElevatedButton(
              onPressed: () async {
                final guardId = idCtrl.text.trim().toUpperCase();
                if (guardId.isEmpty) return;
                try {
                  final snap = await FirebaseFirestore.instance
                      .collection('guards').where('guardId', isEqualTo: guardId).limit(1).get();
                  if (snap.docs.isEmpty) {
                    if (ctx.mounted) ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('❌ Guard ID not found.'),
                        backgroundColor: Color(0xFFC62828)));
                    return;
                  }
                  final email = snap.docs.first.data()['email'] ?? '';
                  if (email.isEmpty) {
                    if (ctx.mounted) ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('❌ No email registered. Please re-register.'),
                        backgroundColor: Color(0xFFC62828)));
                    return;
                  }
                  await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                  Navigator.pop(ctx);
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('✅ Reset link sent to $email — check your inbox!'),
                      backgroundColor: const Color(0xFF2E7D32)));
                } catch (e) {
                  if (ctx.mounted) ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('❌ Something went wrong. Try again.'),
                      backgroundColor: Color(0xFFC62828)));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A3A5C),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('SEND RESET LINK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
          const SizedBox(height: 24),
        ])));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(backgroundColor: const Color(0xFF1A3A5C),
        title: const Text('Guard Login', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white)),
      body: SafeArea(child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 40),
          Center(child: Container(width: 70, height: 70,
            decoration: BoxDecoration(color: const Color(0xFF1A3A5C), borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.qr_code_scanner, size: 40, color: Color(0xFFF0A500)))),
          const SizedBox(height: 24),

          const Text('Guard ID', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A3A5C))),
          const SizedBox(height: 8),
          TextField(controller: _idController,
            decoration: InputDecoration(hintText: 'e.g. GRD001',
              prefixIcon: const Icon(Icons.badge_outlined, color: Color(0xFF1A3A5C)),
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
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            TextButton(
              onPressed: () => _showForgotPassword(context),
              child: const Text('Forgot Password?', style: TextStyle(color: Color(0xFFC62828), fontSize: 13))),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GuardRegisterScreen())),
              child: const Text('New guard? Register here', style: TextStyle(color: Color(0xFF1A3A5C)))),
          ]),
        ]),
      )),
    );
  }
}