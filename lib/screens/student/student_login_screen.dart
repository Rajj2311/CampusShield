import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'student_dashboard.dart';
import 'student_register_screen.dart';
import '../../utils/device_helper.dart';
import '../../utils/tenant.dart';

class StudentLoginScreen extends StatefulWidget {
  const StudentLoginScreen({super.key});
  @override
  State<StudentLoginScreen> createState() => _StudentLoginScreenState();
}
class _StudentLoginScreenState extends State<StudentLoginScreen> {
  final _rollController     = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading       = false;
  String? _errorMessage;

  Future<void> _login() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final roll = _rollController.text.trim().toUpperCase();
      if (roll.isEmpty || _passwordController.text.trim().isEmpty) {
        setState(() {
          _errorMessage = 'Please enter roll number and password.';
          _isLoading = false;
        });
        return;
      }

      // Step 1: fetch the student from Firestore
      final snap = await Tenant.col('students')
          .where('roll', isEqualTo: roll)
          .limit(1).get();

      if (snap.docs.isEmpty) {
        setState(() {
          _errorMessage = 'Roll number not found. Contact warden.';
          _isLoading = false;
        });
        return;
      }

      final studentDoc  = snap.docs.first;
      final studentData = Map<String, dynamic>.from(studentDoc.data());
      final savedEmail  = (studentData['email'] ?? '').toString().trim();
      final oldEmail    = '$roll@chowkidar.student';
      final loginEmail  = savedEmail.isNotEmpty ? savedEmail : oldEmail;

      // Step 2 — Firebase Auth login
      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: loginEmail,
          password: _passwordController.text.trim());
      } on FirebaseAuthException catch (e) {
        if (savedEmail.isNotEmpty &&
            (e.code == 'invalid-credential' ||
             e.code == 'wrong-password')) {
          await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: oldEmail,
            password: _passwordController.text.trim());
        } else {
          rethrow;
        }
      }

      // Step 3 — Device binding check
      final currentDeviceId   = await DeviceHelper.getDeviceId();
      final currentDeviceName = await DeviceHelper.getDeviceName();
      final boundDeviceId     = (studentData['boundDeviceId'] ?? '').toString();

      if (boundDeviceId.isEmpty) {
        // First login: bind this device
        await Tenant.col('students').doc(studentDoc.id).update({
          'boundDeviceId':   currentDeviceId,
          'boundDeviceName': currentDeviceName,
          'deviceBoundAt':   FieldValue.serverTimestamp(),
        });
        studentData['boundDeviceId']   = currentDeviceId;
        studentData['boundDeviceName'] = currentDeviceName;

      } else if (boundDeviceId != currentDeviceId) {
        // Different device: check for an existing pending request
        final pendingReq = await Tenant.col('deviceChangeRequests')
            .where('studentId', isEqualTo: studentDoc.id)
            .where('status', isEqualTo: 'pending')
            .limit(1).get();

        if (pendingReq.docs.isNotEmpty) {
          // A request is already pending
          await FirebaseAuth.instance.signOut();
          setState(() {
            _errorMessage =
                'New device request already pending.\n'
                'Please wait for the warden approval.';
            _isLoading = false;
          });
          return;
        }

        // Send the request to the warden
        final wardenSnap = await Tenant.col('wardens')
            .where('hostelBlock',
                isEqualTo: studentData['block'] ?? '')
            .limit(1).get();

        final wardenId = wardenSnap.docs.isNotEmpty
            ? wardenSnap.docs.first.id : '';

        await Tenant.col('deviceChangeRequests').add({
          'studentId':        studentDoc.id,
          'studentName':      studentData['name'],
          'roll':             roll,
          'room':             studentData['room'],
          'block':            studentData['block'] ?? '',
          'oldDeviceId':      boundDeviceId,
          'oldDeviceName':    studentData['boundDeviceName'] ?? 'Unknown',
          'newDeviceId':      currentDeviceId,
          'newDeviceName':    currentDeviceName,
          'wardenId':         wardenId,
          'status':           'pending',
          'requestedAt':      FieldValue.serverTimestamp(),
        });

        // Notify the warden
        if (wardenId.isNotEmpty) {
          await Tenant.col('notifications')
              .doc(wardenId)
              .collection('items').add({
            'title':     '📱 New Device Login Request',
            'body':      '${studentData['name']} (${roll})'
                         'Attempted to log in from a new device.: '
                         '$currentDeviceName',
            'type':      'device_request',
            'relatedId': studentDoc.id,
            'isRead':    false,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }

        await FirebaseAuth.instance.signOut();
        if (mounted) _showDeviceRequestSent(currentDeviceName);
        return;
      }

      // Step 4: go to the dashboard
      if (mounted) Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => StudentDashboard(
          studentData: studentData,
          studentId: studentDoc.id)));

    } on FirebaseAuthException catch (e) {
      String msg;
      switch (e.code) {
        case 'user-not-found':
          msg = 'No account found. Please register first.'; break;
        case 'wrong-password':
        case 'invalid-credential':
          msg = 'Wrong password. Try again.'; break;
        case 'too-many-requests':
          msg = 'Too many attempts. Please wait.'; break;
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

  void _showDeviceRequestSent(String deviceName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.smartphone, color: Color(0xFFF0A500)),
          SizedBox(width: 8),
          Text('New Device Detected',
            style: TextStyle(fontSize: 16)),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          const Text(
            'This account is already logged in on another device.',
            style: TextStyle(fontSize: 13)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(8)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              const Text('New Device:',
                style: TextStyle(fontSize: 11, color: Colors.grey)),
              Text(deviceName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 13)),
            ])),
          const SizedBox(height: 10),
          const Text(
            '✅ The approval request has been sent to the warden.\n\n'
            'You will be able to log in on this device once the warden approves your request.',
            style: TextStyle(fontSize: 13, height: 1.5)),
        ]),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A3A5C),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10))),
            child: const Text('Okay, got it.',
              style: TextStyle(color: Colors.white))),
        ]));
  }

  void _showForgotPassword(BuildContext context) {
    final rollCtrl = TextEditingController();
    showModalBottomSheet(context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Reset Password', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A3A5C))),
          const SizedBox(height: 6),
          const Text('Enter your roll number — reset link will be sent to your registered email.',
            style: TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 16),
          TextField(controller: rollCtrl,
            decoration: InputDecoration(hintText: 'Enter your roll number (e.g. CS001)',
              prefixIcon: const Icon(Icons.badge_outlined, color: Color(0xFF1A3A5C)),
              filled: true, fillColor: const Color(0xFFF5F7FA),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, height: 48,
            child: ElevatedButton(
              onPressed: () async {
                final roll = rollCtrl.text.trim().toUpperCase();
                if (roll.isEmpty) return;
                try {
                  final snap = await Tenant.col('students').where('roll', isEqualTo: roll).limit(1).get();
                  if (snap.docs.isEmpty) {
                    if (ctx.mounted) ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('❌ Roll number not found.'),
                        backgroundColor: Color(0xFFC62828)));
                    return;
                  }
                  final email = (snap.docs.first.data()['email'] ?? '').toString().trim();
                  if (email.isEmpty) {
                    if (ctx.mounted) ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('❌ No email registered. Contact warden.'),
                        backgroundColor: Color(0xFFC62828)));
                    return;
                  }
                  await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('✅ Reset link sent to $email'),
                      backgroundColor: const Color(0xFF2E7D32)));
                } catch (e) {
                  if (ctx.mounted) ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('❌ Something went wrong. Try again.'),
                      backgroundColor: Color(0xFFC62828)));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A3A5C),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('SEND RESET LINK',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
          const SizedBox(height: 24),
        ])));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(backgroundColor: const Color(0xFF1A3A5C),
        title: const Text('Student Login',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white)),
      body: SafeArea(child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 40),
          Center(child: Container(width: 70, height: 70,
            decoration: BoxDecoration(color: const Color(0xFF1A3A5C),
              borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.school, size: 40, color: Color(0xFFF0A500)))),
          const SizedBox(height: 24),

          const Text('Roll Number',
            style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A3A5C))),
          const SizedBox(height: 8),
          TextField(controller: _rollController,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(hintText: 'e.g. CS001',
              prefixIcon: const Icon(Icons.badge_outlined, color: Color(0xFF1A3A5C)),
              filled: true, fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none))),
          const SizedBox(height: 16),

          const Text('Password',
            style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A3A5C))),
          const SizedBox(height: 8),
          TextField(controller: _passwordController, obscureText: _obscurePassword,
            decoration: InputDecoration(hintText: 'Enter your password',
              prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF1A3A5C)),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword)),
              filled: true, fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none))),

          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Container(padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                const Icon(Icons.error_outline, color: Color(0xFFC62828), size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(_errorMessage!,
                  style: const TextStyle(color: Color(0xFFC62828), fontSize: 13))),
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
                : const Text('LOGIN', style: TextStyle(fontSize: 16,
                    fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2)))),
          const SizedBox(height: 8),

          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            TextButton(onPressed: () => _showForgotPassword(context),
              child: const Text('Forgot Password?',
                style: TextStyle(color: Color(0xFFC62828), fontSize: 13))),
            TextButton(
              onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const StudentRegisterScreen())),
              child: const Text('New student? Register here',
                style: TextStyle(color: Color(0xFF1A3A5C)))),
          ]),
        ]),
      )),
    );
  }
}