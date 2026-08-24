import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'utils/remote_config_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Remote Config initialize karo
  await RemoteConfigHelper.init();
  
  runApp(const ChowkidarApp());
}

class ChowkidarApp extends StatelessWidget {
  const ChowkidarApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chowkidar',
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
