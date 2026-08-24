import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'student_dashboard.dart';

class StudentRegisterScreen extends StatefulWidget {
  const StudentRegisterScreen({super.key});
  @override
  State<StudentRegisterScreen> createState() => _StudentRegisterScreenState();
}
class _StudentRegisterScreenState extends State<StudentRegisterScreen> {
  final _rollController     = TextEditingController();
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _register() async {
    final roll  = _rollController.text.trim().toUpperCase();
    final email = _emailController.text.trim();
    final pass  = _passwordController.text.trim();

    if (roll.isEmpty || email.isEmpty || pass.length < 6) {
      setState(() => _errorMessage = 'Please fill all fields. Password min 8 characters.');
      return;
    }
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final snap = await FirebaseFirestore.instance
          .collection('students').where('roll', isEqualTo: roll).limit(1).get();
      if (snap.docs.isEmpty) {
        setState(() {
          _errorMessage = 'Roll number not found. Contact warden to add you first.';
          _isLoading = false;
        });
        return;
      }

      final studentDoc  = snap.docs.first;
      final studentData = Map<String, dynamic>.from(studentDoc.data());

      if (studentData['hasAccount'] == true) {
        setState(() {
          _errorMessage = 'This roll number is already registered. Please login instead.';
          _isLoading = false;
        });
        return;
      }

      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email, password: pass);

      await FirebaseFirestore.instance
          .collection('students')
          .doc(studentDoc.id)
          .update({'hasAccount': true, 'email': email});

      studentData['email']      = email;
      studentData['hasAccount'] = true;

      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (_) => StudentDashboard(
          studentData: studentData,
          studentId: studentDoc.id)));

    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.code == 'email-already-in-use'
            ? 'This email is already registered. Please login instead.'
            : e.code == 'invalid-email'
                ? 'Please enter a valid email address.'
                : 'Registration failed. Try again.';
      });
   } catch (e) {
      setState(() { _errorMessage = 'Error: ${e.toString()}'; });
    }  finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(backgroundColor: const Color(0xFF1A3A5C),
        title: const Text('Student Register', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white)),
      body: SafeArea(child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 20),
          Center(child: Container(width: 70, height: 70,
            decoration: BoxDecoration(color: const Color(0xFF1A3A5C), borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.school, size: 40, color: Color(0xFFF0A500)))),
          const SizedBox(height: 8),
          const Center(child: Text('Create Student Account',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A3A5C)))),
          const SizedBox(height: 4),
          const Center(child: Text('Warden must add your roll number first',
            style: TextStyle(fontSize: 12, color: Colors.grey), textAlign: TextAlign.center)),
          const SizedBox(height: 24),

          const Text('Roll Number', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A3A5C))),
          const SizedBox(height: 8),
          TextField(controller: _rollController,
            decoration: InputDecoration(hintText: 'e.g. CS001',
              prefixIcon: const Icon(Icons.badge_outlined, color: Color(0xFF1A3A5C)),
              filled: true, fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
          const SizedBox(height: 16),

          const Text('Your Email', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A3A5C))),
          const SizedBox(height: 8),
          TextField(controller: _emailController, keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(hintText: 'e.g. raj@gmail.com',
              prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF1A3A5C)),
              filled: true, fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
          const SizedBox(height: 4),
          const Text('⚠️ Use your real email — password reset link will be sent here',
            style: TextStyle(fontSize: 11, color: Color(0xFFF0A500))),
          const SizedBox(height: 16),

          const Text('Set Password', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A3A5C))),
          const SizedBox(height: 8),
          TextField(controller: _passwordController, obscureText: _obscurePassword,
            decoration: InputDecoration(hintText: 'Min 8 characters',
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