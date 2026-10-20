import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'worker_dashboard.dart';
import 'worker_register_screen.dart';
import '../../utils/tenant.dart';

class WorkerLoginScreen extends StatefulWidget {
  const WorkerLoginScreen({super.key});
  @override
  State<WorkerLoginScreen> createState() => _WorkerLoginScreenState();
}
class _WorkerLoginScreenState extends State<WorkerLoginScreen> {
  final _idCtrl   = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  Future<void> _login() async {
  setState(() { _loading = true; _error = null; });
  try {
    final workerId = _idCtrl.text.trim().toUpperCase();
    if (workerId.isEmpty || _passCtrl.text.trim().isEmpty) {
      setState(() {
        _error = 'Please enter Worker ID and password.';
        _loading = false;
      });
      return;
    }

    // Step 1: fetch the real email from Firestore
    final snap = await Tenant.col('workers')
        .where('workerId', isEqualTo: workerId)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) {
      setState(() {
        _error = 'Worker ID not found.';
        _loading = false;
      });
      return;
    }

    final data = snap.docs.first.data();
    final realEmail = (data['email'] ?? '').toString().trim();

    if (realEmail.isEmpty) {
      setState(() {
        _error = 'No email found. Please re-register.';
        _loading = false;
      });
      return;
    }

    // Step 2: sign in with the real email
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: realEmail,
      password: _passCtrl.text.trim(),
    );

    if (mounted) Navigator.pushReplacement(context,
      MaterialPageRoute(builder: (_) =>
        WorkerDashboard(
          workerData: data,
          workerId: snap.docs.first.id)));

  } on FirebaseAuthException catch (e) {
    String msg;
    switch (e.code) {
      case 'user-not-found':
        msg = 'Not registered. Please register first.';
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
    setState(() => _error = msg);
  } catch (e) {
    setState(() => _error = 'Error: ${e.toString()}');
  } finally {
    if (mounted) setState(() => _loading = false);
  }
}

  void _showForgotPassword() {
    final idCtrl = TextEditingController();
    showModalBottomSheet(context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Reset Password', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A3A5C))),
          const SizedBox(height: 12),
          TextField(controller: idCtrl,
            decoration: InputDecoration(hintText: 'Enter your Worker ID (e.g. WRK001)',
              prefixIcon: const Icon(Icons.badge_outlined, color: Color(0xFF1A3A5C)),
              filled: true, fillColor: const Color(0xFFF5F7FA),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, height: 48,
            child: ElevatedButton(
              onPressed: () async {
                final wid = idCtrl.text.trim().toUpperCase();
                if (wid.isEmpty) return;
                final snap = await Tenant.col('workers').where('workerId', isEqualTo: wid).limit(1).get();
                if (snap.docs.isEmpty) {
                  if (ctx.mounted) ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('❌ Worker ID not found.'), backgroundColor: Color(0xFFC62828)));
                  return;
                }
                final email = snap.docs.first.data()['email'] ?? '';
                await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                Navigator.pop(ctx);
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('✅ Reset link sent to $email'), backgroundColor: const Color(0xFF2E7D32)));
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
        title: const Text('Worker Login', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white)),
      body: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 40),
          Center(child: Container(width: 70, height: 70,
            decoration: BoxDecoration(color: const Color(0xFF1A3A5C), borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.engineering, size: 40, color: Color(0xFFF0A500)))),
          const SizedBox(height: 24),
          const Text('Worker ID', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A3A5C))),
          const SizedBox(height: 8),
          TextField(controller: _idCtrl,
            decoration: InputDecoration(hintText: 'e.g. WRK001',
              prefixIcon: const Icon(Icons.badge_outlined, color: Color(0xFF1A3A5C)),
              filled: true, fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
          const SizedBox(height: 16),
          const Text('Password', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A3A5C))),
          const SizedBox(height: 8),
          TextField(controller: _passCtrl, obscureText: _obscure,
            decoration: InputDecoration(hintText: 'Enter your password',
              prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF1A3A5C)),
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                onPressed: () => setState(() => _obscure = !_obscure)),
              filled: true, fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
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
            child: ElevatedButton(onPressed: _loading ? null : _login,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A3A5C),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: _loading
                ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                : const Text('LOGIN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2)))),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            TextButton(onPressed: _showForgotPassword,
              child: const Text('Forgot Password?', style: TextStyle(color: Color(0xFFC62828), fontSize: 13))),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WorkerRegisterScreen())),
              child: const Text('New worker? Register', style: TextStyle(color: Color(0xFF1A3A5C)))),
          ]),
        ]))),
    );
  }
}