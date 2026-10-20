import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/tenant.dart';
import 'role_select_screen.dart';
import 'college_select_screen.dart';
import 'student/student_dashboard.dart';
import 'warden/warden_dashboard.dart';
import 'guard/guard_dashboard.dart';
import 'worker/worker_dashboard.dart';

// ───── AUTH GATE (Auto-Login Checker) ─────
// Signed-in user -> userIndex/{uid} -> college + role + doc id.
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

    // Not signed in: go to college picker (first run) or role picker.
    if (user == null) {
      final hasCollege = await Tenant.restore();
      _goTo(hasCollege ? const RoleSelectScreen() : const CollegeSelectScreen());
      return;
    }

    String? problem;
    try {
      final idxSnap = await FirebaseFirestore.instance
          .collection('userIndex').doc(user.uid).get();
      final idx = idxSnap.data();
      if (idx == null) {
        problem = 'Your account is not linked to any college.';
      } else {
        final err = await Tenant.load(idx['collegeId'] as String);
        if (err != null) {
          problem = err;
        } else {
          final role  = idx['role'] as String;
          final docId = idx['docId'] as String;
          final screen = await _screenFor(role, docId);
          if (screen != null) { _goTo(screen); return; }
          problem = 'Account record not found. Contact your administration.';
        }
      }
    } catch (e) {
      debugPrint('AuthGate error: $e');
      problem = 'Could not load your account. Check your internet.';
    }

    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(problem)));
    final hasCollege = await Tenant.restore();
    _goTo(hasCollege ? const RoleSelectScreen() : const CollegeSelectScreen());
  }

  Future<Widget?> _screenFor(String role, String docId) async {
    switch (role) {
      case 'warden':
        final d = await Tenant.col('wardens').doc(docId).get();
        return d.exists ? const WardenDashboard() : null;
      case 'worker':
        final d = await Tenant.col('workers').doc(docId).get();
        return d.exists
            ? WorkerDashboard(workerData: d.data()!, workerId: d.id) : null;
      case 'guard':
        final d = await Tenant.col('guards').doc(docId).get();
        return d.exists ? GuardDashboard(guardData: d.data()!) : null;
      case 'student':
        final d = await Tenant.col('students').doc(docId).get();
        return d.exists
            ? StudentDashboard(studentData: d.data()!, studentId: d.id) : null;
    }
    return null;
  }

  void _goTo(Widget screen) {
    if (mounted) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => screen));
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF1A3A5C),
      body: Center(child: CircularProgressIndicator(color: Color(0xFFF0A500))),
    );
  }
}
