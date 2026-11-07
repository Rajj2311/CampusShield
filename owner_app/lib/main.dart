import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const OwnerApp());
}

class OwnerApp extends StatelessWidget {
  const OwnerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CampusShield Owner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: kNavy),
        useMaterial3: true,
      ),
      home: const _Gate(),
    );
  }
}

/// Signed in AND carrying the superAdmin claim -> home. Otherwise -> login.
class _Gate extends StatelessWidget {
  const _Gate();

  Future<bool> _isOwner(User user) async {
    final token = await user.getIdTokenResult(true);
    return token.claims?['superAdmin'] == true;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final user = snap.data;
        if (user == null) return const LoginScreen();
        return FutureBuilder<bool>(
          future: _isOwner(user),
          builder: (context, ownerSnap) {
            if (!ownerSnap.hasData) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }
            if (ownerSnap.data == true) return const HomeScreen();
            return const LoginScreen(notOwner: true);
          },
        );
      },
    );
  }
}
