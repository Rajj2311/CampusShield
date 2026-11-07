import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const CampusShieldApp());
}

class CampusShieldApp extends StatelessWidget {
  const CampusShieldApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CampusShield',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF1A3A5C),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A3A5C), secondary: const Color(0xFFF0A500)),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
