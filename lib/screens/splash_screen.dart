import 'package:flutter/material.dart';
import 'auth_gate_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}
class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AuthGateScreen()));
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A3A5C),
      body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Image.asset('assets/images/logo.png', width: 180, height: 180),
        const SizedBox(height: 24),
        const Text('CHOWKIDAR', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 4)),
        const SizedBox(height: 8),
        const Text('Smart Hostel Management', style: TextStyle(fontSize: 16, color: Color(0xFFF0A500), letterSpacing: 1)),
      ])),
    );
  }
}
