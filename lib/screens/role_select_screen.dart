import 'package:flutter/material.dart';
import 'warden/warden_login_screen.dart';
import 'student/student_login_screen.dart';
import 'guard/guard_login_screen.dart';
import 'worker/worker_login_screen.dart';
import 'college_select_screen.dart';
import 'college/college_admin_login_screen.dart';
import '../utils/tenant.dart';

class RoleSelectScreen extends StatelessWidget {
  const RoleSelectScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A3A5C),
      body: SafeArea(child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Image.asset('assets/images/mark.png', width: 96, height: 96),
          const SizedBox(height: 24),
          const Text('CAMPUSSHIELD', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 4)),
          const SizedBox(height: 8),
          Text(Tenant.isSet ? Tenant.name : 'Smart Hostel Management', textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: Color(0xFFF0A500))),
          const SizedBox(height: 50),
          const Text('Login As', style: TextStyle(fontSize: 18, color: Colors.white70)),
          const SizedBox(height: 20),

          // Warden
          SizedBox(width: double.infinity, height: 54,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WardenLoginScreen())),
              icon: const Icon(Icons.admin_panel_settings, color: Color(0xFF1A3A5C)),
              label: const Text('Warden / Admin', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A3A5C))),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF0A500),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))))),
          const SizedBox(height: 12),

          // Student
          SizedBox(width: double.infinity, height: 54,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentLoginScreen())),
              icon: const Icon(Icons.school, color: Colors.white),
              label: const Text('Student', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.15),
                side: const BorderSide(color: Colors.white, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))))),
          const SizedBox(height: 12),

          // Guard
          SizedBox(width: double.infinity, height: 54,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GuardLoginScreen())),
              icon: const Icon(Icons.qr_code_scanner, color: Color(0xFF1A3A5C)),
              label: const Text('Guard Login', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A3A5C))),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF0A500),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))))),
          const SizedBox(height: 12),

          // Worker
          SizedBox(width: double.infinity, height: 54,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WorkerLoginScreen())),
              icon: const Icon(Icons.engineering, color: Colors.white),
              label: const Text('Worker Login', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.12),
                side: const BorderSide(color: Colors.white70, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))))),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const CollegeAdminLoginScreen())),
            icon: const Icon(Icons.apartment, color: Colors.white70),
            label: const Text('College Admin', style: TextStyle(color: Colors.white70))),
          const SizedBox(height: 4),
          TextButton(
            onPressed: () async {
              await Tenant.clear();
              if (context.mounted) {
                Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const CollegeSelectScreen()));
              }
            },
            child: const Text('Change college', style: TextStyle(color: Colors.white54))),
        ]),
      )),
    );
  }
}