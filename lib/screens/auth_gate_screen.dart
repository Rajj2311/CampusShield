import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'role_select_screen.dart';
import 'student/student_dashboard.dart';
import 'warden/warden_dashboard.dart';
import 'guard/guard_dashboard.dart';
import 'worker/worker_dashboard.dart';

// ───── AUTH GATE (Auto-Login Checker) ─────
class AuthGateScreen extends StatefulWidget {
  const AuthGateScreen({super.key});
  @override
  State<AuthGateScreen> createState() => _AuthGateScreenState();
}
class _AuthGateScreenState extends State<AuthGateScreen> {
  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) { _goTo(const RoleSelectScreen()); return; }

    final email = user.email ?? '';
    try {
      // Warden check
      final wardenDoc = await FirebaseFirestore.instance
          .collection('wardens').doc(user.uid).get();
      if (wardenDoc.exists) {
        _goTo(const WardenDashboard()); return;
      }

      // Worker check — email se bhi, uid se bhi
      final workerByUid = await FirebaseFirestore.instance
          .collection('workers').doc(user.uid).get();
      if (workerByUid.exists) {
        _goTo(WorkerDashboard(
          workerData: workerByUid.data()!,
          workerId: user.uid)); return;
      }

      if (email.isNotEmpty) {
        final workerByEmail = await FirebaseFirestore.instance
            .collection('workers')
            .where('email', isEqualTo: email)
            .limit(1).get();
        if (workerByEmail.docs.isNotEmpty) {
          _goTo(WorkerDashboard(
            workerData: workerByEmail.docs.first.data(),
            workerId: workerByEmail.docs.first.id)); return;
        }
      }

      // Guard check — uid se bhi, email se bhi
      final guardByUid = await FirebaseFirestore.instance
          .collection('guards').doc(user.uid).get();
      if (guardByUid.exists) {
        _goTo(GuardDashboard(guardData: guardByUid.data()!)); return;
      }

      if (email.isNotEmpty) {
        final guardByEmail = await FirebaseFirestore.instance
            .collection('guards')
            .where('email', isEqualTo: email)
            .limit(1).get();
        if (guardByEmail.docs.isNotEmpty) {
          _goTo(GuardDashboard(
            guardData: guardByEmail.docs.first.data())); return;
        }
      }

      // Old format guard check (guardId@chowkidar.guard)
      if (email.endsWith('@chowkidar.guard')) {
        final guardId = email.split('@')[0].toUpperCase();
        final guardSnap = await FirebaseFirestore.instance
            .collection('guards')
            .where('guardId', isEqualTo: guardId)
            .limit(1).get();
        if (guardSnap.docs.isNotEmpty) {
          _goTo(GuardDashboard(
            guardData: guardSnap.docs.first.data())); return;
        }
      }

      // Old format worker check
      if (email.endsWith('@chowkidar.worker')) {
        final workerId = email.split('@')[0].toUpperCase();
        final workerSnap = await FirebaseFirestore.instance
            .collection('workers')
            .where('workerId', isEqualTo: workerId)
            .limit(1).get();
        if (workerSnap.docs.isNotEmpty) {
          _goTo(WorkerDashboard(
            workerData: workerSnap.docs.first.data(),
            workerId: workerSnap.docs.first.id)); return;
        }
      }

      // Student check
      if (email.isNotEmpty) {
        final studentSnap = await FirebaseFirestore.instance
            .collection('students')
            .where('email', isEqualTo: email)
            .limit(1).get();
        if (studentSnap.docs.isNotEmpty) {
          _goTo(StudentDashboard(
            studentData: studentSnap.docs.first.data(),
            studentId: studentSnap.docs.first.id)); return;
        }
      }

    } catch (e) {
      debugPrint('AuthGate error: $e');
    }

    // Kuch match nahi hua — logout
    await FirebaseAuth.instance.signOut();
    _goTo(const RoleSelectScreen());
  }

  void _goTo(Widget screen) {
    if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF1A3A5C),
      body: Center(child: CircularProgressIndicator(color: Color(0xFFF0A500))),
    );
  }
}