import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/ui.dart';
import '../../utils/payment_config.dart';
import 'request_status_screen.dart';

/// A college administrator registers a new college. The request is sent to
/// the Chowkidar owner, who approves or rejects it.
class CollegeRegisterScreen extends StatefulWidget {
  const CollegeRegisterScreen({super.key});
  @override
  State<CollegeRegisterScreen> createState() => _CollegeRegisterScreenState();
}

class _CollegeRegisterScreenState extends State<CollegeRegisterScreen> {
  final _name = TextEditingController();
  final _code = TextEditingController();
  final _city = TextEditingController();
  final _adminName = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _hostelCtrl = TextEditingController();
  final List<String> _hostels = [];
  bool _loading = false;
  String? _error;
  PaymentConfig _cfg = const PaymentConfig();
  String? _planId;

  @override
  void initState() {
    super.initState();
    PaymentConfig.load().then((c) {
      if (mounted) {
        setState(() {
          _cfg = c;
          _planId ??= c.plans.first.id;
        });
      }
    });
  }

  @override
  void dispose() {
    for (final c in [
      _name, _code, _city, _adminName, _phone, _email, _password, _hostelCtrl
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _addHostel() {
    final h = _hostelCtrl.text.trim();
    if (h.isEmpty) return;
    if (_hostels.any((e) => e.toLowerCase() == h.toLowerCase())) {
      setState(() => _error = 'This hostel is already added.');
      return;
    }
    setState(() {
      _hostels.add(h);
      _hostelCtrl.clear();
      _error = null;
    });
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    final code = _code.text.trim().toLowerCase();
    final city = _city.text.trim();
    final adminName = _adminName.text.trim();
    final phone = _phone.text.trim();
    final email = _email.text.trim();
    final pass = _password.text.trim();

    if (name.isEmpty || city.isEmpty || adminName.isEmpty || phone.isEmpty ||
        email.isEmpty) {
      setState(() => _error = 'Please fill in all fields.');
      return;
    }
    if (!RegExp(r'^[a-z0-9]{3,20}$').hasMatch(code)) {
      setState(() => _error =
          'College code must be 3 to 20 letters or digits (no spaces or symbols).');
      return;
    }
    if (pass.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters.');
      return;
    }
    if (_hostels.isEmpty) {
      setState(() => _error = 'Add at least one hostel.');
      return;
    }

    final plan = _cfg.plan(_planId) ?? _cfg.plans.first;

    setState(() {
      _loading = true;
      _error = null;
    });

    UserCredential? cred;
    try {
      final existing =
          await FirebaseFirestore.instance.collection('colleges').doc(code).get();
      if (existing.exists) {
        setState(() => _error =
            'This college code is already taken. Please choose another one.');
        return;
      }

      cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: pass);

      await FirebaseFirestore.instance
          .collection('collegeRequests')
          .doc(cred.user!.uid)
          .set({
        'collegeName': name,
        'collegeCode': code,
        'city': city,
        'adminName': adminName,
        'phone': phone,
        'email': email,
        'hostels': _hostels,
        'plan': plan.id,
        'planName': plan.name,
        'amount': plan.price,
        'months': plan.months,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const RequestStatusScreen()),
          (route) => false);
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = e.code == 'email-already-in-use'
            ? 'This email is already registered. Use another email or log in.'
            : e.code == 'invalid-email'
                ? 'Please enter a valid email address.'
                : e.code == 'weak-password'
                    ? 'Password is too weak.'
                    : 'Registration failed. Please try again.';
      });
    } on FirebaseException {
      await cred?.user?.delete();
      setState(() => _error = 'Could not submit the request. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kNavy,
        title: const Text('Register Your College',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text(
                'Submit your college for approval. After the Chowkidar team approves it, you can set up hostels and invite wardens, guards and workers.',
                style: TextStyle(color: Colors.black54, height: 1.4)),
            const SizedBox(height: 20),
            const Text('College details',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold, color: kNavy)),
            const SizedBox(height: 12),
            AppTextField(
                controller: _name,
                label: 'College name',
                hint: 'e.g. IILM University',
                icon: Icons.apartment,
                capitalization: TextCapitalization.words),
            AppTextField(
                controller: _code,
                label: 'College code',
                hint: 'e.g. iilm (letters and digits only)',
                icon: Icons.tag,
                maxLength: 20),
            AppTextField(
                controller: _city,
                label: 'City',
                hint: 'e.g. Greater Noida',
                icon: Icons.location_city,
                capitalization: TextCapitalization.words),
            const Text('Hostels',
                style: TextStyle(fontWeight: FontWeight.w600, color: kNavy)),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _hostelCtrl,
                  textCapitalization: TextCapitalization.words,
                  onSubmitted: (_) => _addHostel(),
                  decoration: InputDecoration(
                    hintText: 'Hostel name',
                    prefixIcon: const Icon(Icons.home_work_outlined, color: kNavy),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _addHostel,
                icon: const Icon(Icons.add),
                style: IconButton.styleFrom(backgroundColor: kAmber),
              ),
            ]),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _hostels
                  .map((h) => Chip(
                        label: Text(h),
                        onDeleted: () => setState(() => _hostels.remove(h)),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
            const Text('Choose a plan',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold, color: kNavy)),
            const SizedBox(height: 8),
            ..._cfg.plans.map((p) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: (_planId ?? _cfg.plans.first.id) == p.id ? kAmber : Colors.transparent,
                          width: 2)),
                  child: RadioListTile<String>(
                    value: p.id,
                    groupValue: _planId ?? _cfg.plans.first.id,
                    onChanged: (v) => setState(() => _planId = v),
                    activeColor: kNavy,
                    title: Text('${p.name}  -  ${p.priceLabel}',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(p.features),
                  ),
                )),
            const Text(
                'Payment is done after you submit this form. You will see how to pay on the next screen.',
                style: TextStyle(color: Colors.black54, fontSize: 12)),
            const SizedBox(height: 16),
            const Text('Administrator account',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold, color: kNavy)),
            const SizedBox(height: 12),
            AppTextField(
                controller: _adminName,
                label: 'Your name',
                hint: 'Full name',
                icon: Icons.person_outline,
                capitalization: TextCapitalization.words),
            AppTextField(
                controller: _phone,
                label: 'Phone number',
                hint: 'We will contact you on this number',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone),
            AppTextField(
                controller: _email,
                label: 'Email',
                hint: 'Used to log in',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress),
            AppTextField(
                controller: _password,
                label: 'Password',
                hint: 'Min 6 characters',
                icon: Icons.lock_outline,
                obscure: true),
            if (_error != null) ErrorBanner(_error!),
            PrimaryButton(
                label: 'SUBMIT FOR APPROVAL',
                loading: _loading,
                onPressed: _submit),
          ]),
        ),
      ),
    );
  }
}
