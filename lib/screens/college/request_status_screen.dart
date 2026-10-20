import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/ui.dart';
import '../auth_gate_screen.dart';
import '../college_select_screen.dart';

/// Shows the approval status of the signed-in administrator's college request.
class RequestStatusScreen extends StatelessWidget {
  const RequestStatusScreen({super.key});

  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const CollegeSelectScreen()),
          (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      backgroundColor: kNavy,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: uid == null
                ? const Text('Please log in again.',
                    style: TextStyle(color: Colors.white))
                : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('collegeRequests')
                        .doc(uid)
                        .snapshots(),
                    builder: (context, snap) {
                      if (!snap.hasData) {
                        return const CircularProgressIndicator(color: kAmber);
                      }
                      final data = snap.data!.data();
                      if (data == null) {
                        return _card(context,
                            icon: Icons.info_outline,
                            color: Colors.grey,
                            title: 'No request found',
                            body: 'We could not find a college request for this account.',
                            actions: [
                              TextButton(
                                  onPressed: () => _signOut(context),
                                  child: const Text('Sign out'))
                            ]);
                      }
                      final status = data['status'] as String? ?? 'pending';
                      final college = data['collegeName'] ?? 'your college';
                      if (status == 'approved') {
                        return _card(context,
                            icon: Icons.check_circle,
                            color: const Color(0xFF2E7D32),
                            title: 'Approved!',
                            body:
                                '$college is approved. Continue to set up your hostels and invite your team.',
                            actions: [
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: kNavy),
                                onPressed: () => Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => const AuthGateScreen()),
                                    (route) => false),
                                child: const Text('Continue',
                                    style: TextStyle(color: Colors.white)),
                              ),
                            ]);
                      }
                      if (status == 'rejected') {
                        final reason = (data['rejectReason'] as String?)?.trim();
                        return _card(context,
                            icon: Icons.cancel,
                            color: const Color(0xFFC62828),
                            title: 'Request not approved',
                            body: reason == null || reason.isEmpty
                                ? 'Your request for $college was not approved. Please contact Chowkidar support.'
                                : 'Your request for $college was not approved.\n\nReason: $reason',
                            actions: [
                              TextButton(
                                  onPressed: () => _signOut(context),
                                  child: const Text('Sign out'))
                            ]);
                      }
                      return _card(context,
                          icon: Icons.hourglass_top,
                          color: kAmber,
                          title: 'Request under review',
                          body:
                              'Thank you for registering $college. The Chowkidar team will review your request and contact you on ${data['phone'] ?? 'your phone number'} or ${data['email'] ?? 'your email'}.\n\nThis page updates automatically once a decision is made.',
                          actions: [
                            TextButton(
                                onPressed: () => _signOut(context),
                                child: const Text('Sign out'))
                          ]);
                    },
                  ),
          ),
        ),
      ),
    );
  }

  Widget _card(BuildContext context,
      {required IconData icon,
      required Color color,
      required String title,
      required String body,
      required List<Widget> actions}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(18)),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 64, color: color),
        const SizedBox(height: 16),
        Text(title,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: kNavy)),
        const SizedBox(height: 12),
        Text(body,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black87, height: 1.4)),
        const SizedBox(height: 20),
        ...actions,
      ]),
    );
  }
}
