import 'package:flutter/material.dart';
import '../utils/tenant.dart';
import 'role_select_screen.dart';
import 'college/college_register_screen.dart';
import 'college/college_admin_login_screen.dart';

/// First screen on a fresh install: the user enters their college code
/// (e.g. "iilm"). Colleges are created/approved by the app owner.
class CollegeSelectScreen extends StatefulWidget {
  const CollegeSelectScreen({super.key});
  @override
  State<CollegeSelectScreen> createState() => _CollegeSelectScreenState();
}

class _CollegeSelectScreenState extends State<CollegeSelectScreen> {
  final _codeCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _continue() async {
    setState(() { _loading = true; _error = null; });
    final err = await Tenant.load(_codeCtrl.text);
    if (!mounted) return;
    if (err != null) {
      setState(() { _error = err; _loading = false; });
      return;
    }
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const RoleSelectScreen()));
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A3A5C),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Image.asset('assets/images/mark.png', width: 96, height: 96),
              const SizedBox(height: 24),
              const Text('CAMPUSSHIELD',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold,
                      color: Colors.white, letterSpacing: 4)),
              const SizedBox(height: 40),
              const Text('Enter your college code',
                  style: TextStyle(fontSize: 16, color: Colors.white70)),
              const SizedBox(height: 16),
              TextField(
                controller: _codeCtrl,
                autocorrect: false,
                textCapitalization: TextCapitalization.none,
                onSubmitted: (_) => _continue(),
                decoration: InputDecoration(
                  hintText: 'e.g. iilm',
                  prefixIcon: const Icon(Icons.apartment, color: Color(0xFF1A3A5C)),
                  filled: true, fillColor: Colors.white,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none)),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.redAccent)),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _continue,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF0A500),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14))),
                  child: _loading
                      ? const SizedBox(width: 22, height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Continue',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                              color: Color(0xFF1A3A5C))),
                ),
              ),
              const SizedBox(height: 28),
              const Divider(color: Colors.white24),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const CollegeRegisterScreen())),
                icon: const Icon(Icons.add_business, color: Color(0xFFF0A500)),
                label: const Text('Register your college',
                    style: TextStyle(color: Color(0xFFF0A500), fontWeight: FontWeight.bold)),
              ),
              TextButton.icon(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const CollegeAdminLoginScreen())),
                icon: const Icon(Icons.admin_panel_settings, color: Colors.white70),
                label: const Text('College admin login',
                    style: TextStyle(color: Colors.white70)),
              ),
              const SizedBox(height: 12),
              const Text('Ask your college administration for the college code.',
                  style: TextStyle(color: Colors.white54, fontSize: 12)),
            ]),
          ),
        ),
      ),
    );
  }
}
