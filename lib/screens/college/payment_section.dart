import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/payment_config.dart';
import '../../widgets/ui.dart';

/// Shown to a college admin while the request is pending: how to pay,
/// plus a form to submit the payment reference for verification.
class PendingPaymentView extends StatefulWidget {
  final String uid;
  final Map<String, dynamic> data;
  final VoidCallback onSignOut;
  const PendingPaymentView(
      {super.key, required this.uid, required this.data, required this.onSignOut});
  @override
  State<PendingPaymentView> createState() => _PendingPaymentViewState();
}

class _PendingPaymentViewState extends State<PendingPaymentView> {
  PaymentConfig _cfg = const PaymentConfig();
  final _reference = TextEditingController();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  String _method = 'UPI';
  bool _saving = false;
  bool _editing = false;
  String? _error;

  static const _methods = ['UPI', 'Bank transfer', 'Cash', 'Cheque', 'Other'];

  @override
  void initState() {
    super.initState();
    final pay = widget.data['payment'];
    if (pay is Map) {
      _method = (pay['method'] ?? 'UPI').toString();
      if (!_methods.contains(_method)) _method = 'Other';
      _reference.text = (pay['reference'] ?? '').toString();
      _amount.text = (pay['amount'] ?? '').toString();
      _note.text = (pay['note'] ?? '').toString();
    } else {
      final a = widget.data['amount'];
      if (a is num && a > 0) _amount.text = a.toString();
    }
    PaymentConfig.load().then((c) {
      if (mounted) setState(() => _cfg = c);
    });
  }

  @override
  void dispose() {
    _reference.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  void _copy(String label, String v) {
    Clipboard.setData(ClipboardData(text: v));
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('$label copied')));
  }

  Future<void> _submit() async {
    final ref = _reference.text.trim();
    final amount = num.tryParse(_amount.text.trim());
    if (_method != 'Cash' && ref.isEmpty) {
      setState(() => _error = 'Enter the payment reference (UPI transaction ID, UTR or cheque number).');
      return;
    }
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Enter the amount you paid.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await FirebaseFirestore.instance
          .collection('collegeRequests')
          .doc(widget.uid)
          .update({
        'payment': {
          'method': _method,
          'reference': ref,
          'amount': amount,
          'note': _note.text.trim(),
        },
        'paymentSubmitted': true,
        'paymentSubmittedAt': FieldValue.serverTimestamp(),
      });
      _editing = false;
    } on FirebaseException {
      _error = 'Could not submit. Please try again.';
    }
    if (mounted) setState(() => _saving = false);
  }

  Widget _copyRow(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(color: Colors.black54, fontSize: 11)),
            SelectableText(value,
                style: const TextStyle(fontWeight: FontWeight.w600, color: kNavy)),
          ]),
        ),
        IconButton(
            tooltip: 'Copy',
            icon: const Icon(Icons.copy, size: 18, color: kNavy),
            onPressed: () => _copy(label, value)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final college = d['collegeName'] ?? 'your college';
    final planName = d['planName'] ?? '';
    final amount = d['amount'];
    final submitted = d['paymentSubmitted'] == true;
    final c = _cfg;
    final hasPayInfo = c.upiId.isNotEmpty || c.accountNo.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Center(child: Icon(Icons.payments_outlined, size: 56, color: kAmber)),
        const SizedBox(height: 8),
        Center(
          child: Text(submitted ? 'Payment under verification' : 'Complete your payment',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kNavy)),
        ),
        const SizedBox(height: 8),
        Text(
            '$college - $planName plan${amount is num && amount > 0 ? ' - Rs. $amount' : ''}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54)),
        const Divider(height: 28),
        const Text('How to pay',
            style: TextStyle(fontWeight: FontWeight.bold, color: kNavy)),
        const SizedBox(height: 4),
        Text(c.instructions, style: const TextStyle(height: 1.4, fontSize: 13)),
        if (hasPayInfo) ...[
          _copyRow('Payee name', c.payeeName),
          _copyRow('UPI ID', c.upiId),
          _copyRow('Bank', c.bankName),
          _copyRow('Account number', c.accountNo),
          _copyRow('IFSC', c.ifsc),
        ],
        if (c.phone.isNotEmpty || c.whatsapp.isNotEmpty || c.email.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text('Contact us',
              style: TextStyle(fontWeight: FontWeight.bold, color: kNavy)),
          _copyRow('Phone', c.phone),
          _copyRow('WhatsApp', c.whatsapp),
          _copyRow('Email', c.email),
        ],
        const Divider(height: 28),
        if (submitted && !_editing) ...[
          const Text(
              'We received your payment details. Your college will be activated as soon as the payment is verified. This page updates automatically.',
              style: TextStyle(height: 1.4)),
          const SizedBox(height: 8),
          Text(
              'Method: ${(d['payment'] as Map?)?['method'] ?? '-'}   Reference: ${(d['payment'] as Map?)?['reference'] ?? '-'}   Amount: ${(d['payment'] as Map?)?['amount'] ?? '-'}',
              style: const TextStyle(fontSize: 12, color: Colors.black54)),
          TextButton(
              onPressed: () => setState(() => _editing = true),
              child: const Text('Edit payment details')),
        ] else ...[
          const Text('I have paid',
              style: TextStyle(fontWeight: FontWeight.bold, color: kNavy)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _method,
            items: _methods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
            onChanged: (v) => setState(() => _method = v ?? _method),
            decoration: _dec('Payment method'),
          ),
          const SizedBox(height: 10),
          TextField(controller: _reference, decoration: _dec('Reference (UPI transaction ID / UTR / cheque no.)')),
          const SizedBox(height: 10),
          TextField(
              controller: _amount,
              keyboardType: TextInputType.number,
              decoration: _dec('Amount paid (Rs.)')),
          const SizedBox(height: 10),
          TextField(controller: _note, decoration: _dec('Note (optional)')),
          if (_error != null) ...[
            const SizedBox(height: 10),
            ErrorBanner(_error!),
          ],
          const SizedBox(height: 12),
          PrimaryButton(label: 'SUBMIT PAYMENT DETAILS', loading: _saving, onPressed: _submit),
        ],
        const SizedBox(height: 8),
        Center(
          child: TextButton(onPressed: widget.onSignOut, child: const Text('Sign out')),
        ),
      ]),
    );
  }

  InputDecoration _dec(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: kBg,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      );
}
