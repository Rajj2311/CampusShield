import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/payment_config.dart';
import '../../utils/tenant.dart';
import '../../widgets/ui.dart';
import '../admin/subscription_card.dart';
import '../auth_gate_screen.dart';

/// Shown to a college admin whose college is expired or suspended: how to
/// renew and the receipts of earlier payments.
class SubscriptionExpiredScreen extends StatefulWidget {
  const SubscriptionExpiredScreen({super.key});
  @override
  State<SubscriptionExpiredScreen> createState() =>
      _SubscriptionExpiredScreenState();
}

class _SubscriptionExpiredScreenState extends State<SubscriptionExpiredScreen> {
  PaymentConfig _cfg = const PaymentConfig();

  @override
  void initState() {
    super.initState();
    PaymentConfig.load().then((c) {
      if (mounted) setState(() => _cfg = c);
    });
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AuthGateScreen()),
        (route) => false);
  }

  Widget _row(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Row(children: [
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: Colors.black54, fontSize: 11)),
          SelectableText(value,
              style: const TextStyle(fontWeight: FontWeight.w600, color: kNavy)),
        ]),
      ),
      IconButton(
          icon: const Icon(Icons.copy, size: 18, color: kNavy),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: value));
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text('$label copied')));
          }),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final c = _cfg;
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kNavy,
        automaticallyImplyLeading: false,
        title: Text(Tenant.name,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
              tooltip: 'Sign out',
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: _signOut),
        ],
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        ErrorBanner(Tenant.inactiveReason ?? 'This college is not active.'),
        const Text('How to renew',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kNavy)),
        const SizedBox(height: 8),
        Text(c.instructions, style: const TextStyle(height: 1.4)),
        const SizedBox(height: 12),
        SectionCard(
          child: Column(children: [
            _row('Payee name', c.payeeName),
            _row('UPI ID', c.upiId),
            _row('Bank', c.bankName),
            _row('Account number', c.accountNo),
            _row('IFSC', c.ifsc),
            _row('Phone', c.phone),
            _row('WhatsApp', c.whatsapp),
            _row('Email', c.email),
          ]),
        ),
        const SizedBox(height: 8),
        const SubscriptionCard(),
        const SizedBox(height: 16),
        PrimaryButton(label: 'CHECK AGAIN', onPressed: _signOutAndRetry),
      ]),
    );
  }

  /// After the owner records the payment, re-run the login gate.
  void _signOutAndRetry() {
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AuthGateScreen()),
        (route) => false);
  }
}
