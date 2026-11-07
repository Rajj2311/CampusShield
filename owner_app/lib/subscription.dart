import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'payment_config.dart';

class PaymentEntry {
  final String planId;
  final String planName;
  final num amount;
  final int months;
  final String method;
  final String reference;
  final String note;
  const PaymentEntry({
    required this.planId,
    required this.planName,
    required this.amount,
    required this.months,
    required this.method,
    required this.reference,
    required this.note,
  });
}

String newReceiptNo() {
  final n = DateTime.now();
  final d = '${n.year}${n.month.toString().padLeft(2, '0')}${n.day.toString().padLeft(2, '0')}';
  final r = Random.secure().nextInt(9000) + 1000;
  return 'CSH-$d-$r';
}

DateTime addMonths(DateTime d, int months) {
  final total = d.month - 1 + months;
  final y = d.year + total ~/ 12;
  final m = total % 12 + 1;
  final lastDay = DateTime(y, m + 1, 0).day;
  return DateTime(y, m, d.day > lastDay ? lastDay : d.day, 23, 59, 59);
}

/// Adds the receipt to [batch] and returns the college fields to merge
/// (plan, validity, status). Renewals extend from the current expiry when
/// the subscription is still running.
Map<String, dynamic> applyPayment(
  WriteBatch batch, {
  required String collegeId,
  required String collegeName,
  required String adminName,
  required PaymentEntry p,
  DateTime? currentExpiry,
}) {
  final now = DateTime.now();
  final start = (currentExpiry != null && currentExpiry.isAfter(now)) ? currentExpiry : now;
  final end = addMonths(start, p.months);
  final no = newReceiptNo();
  batch.set(FirebaseFirestore.instance.collection('receipts').doc(no), {
    'receiptNo': no,
    'collegeId': collegeId,
    'collegeName': collegeName,
    'adminName': adminName,
    'plan': p.planId,
    'planName': p.planName,
    'amount': p.amount,
    'months': p.months,
    'method': p.method,
    'reference': p.reference,
    'note': p.note,
    'periodStart': Timestamp.fromDate(start),
    'periodEnd': Timestamp.fromDate(end),
    'issuedAt': FieldValue.serverTimestamp(),
  });
  return {
    'plan': p.planId,
    'planName': p.planName,
    'expiresAt': Timestamp.fromDate(end),
    'status': 'approved',
  };
}

const kMethods = ['UPI', 'Bank transfer', 'Cash', 'Cheque', 'Other'];

/// Dialog to record a verified payment (used for approvals and renewals).
Future<PaymentEntry?> showPaymentDialog(
  BuildContext context,
  PaymentConfig cfg, {
  String title = 'Record payment',
  String? planId,
  num? amount,
  int? months,
  String? method,
  String? reference,
}) {
  return showDialog<PaymentEntry>(
    context: context,
    builder: (_) => _PaymentDialog(
      cfg: cfg,
      title: title,
      planId: planId,
      amount: amount,
      months: months,
      method: method,
      reference: reference,
    ),
  );
}

class _PaymentDialog extends StatefulWidget {
  final PaymentConfig cfg;
  final String title;
  final String? planId;
  final num? amount;
  final int? months;
  final String? method;
  final String? reference;
  const _PaymentDialog({
    required this.cfg,
    required this.title,
    this.planId,
    this.amount,
    this.months,
    this.method,
    this.reference,
  });
  @override
  State<_PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<_PaymentDialog> {
  late String _plan = widget.cfg.plan(widget.planId)?.id ?? widget.cfg.plans.first.id;
  late String _method = kMethods.contains(widget.method) ? widget.method! : 'UPI';
  late final _amount = TextEditingController(
      text: (widget.amount ?? widget.cfg.plan(_plan)?.price ?? '').toString());
  late final _months = TextEditingController(
      text: (widget.months ?? widget.cfg.plan(_plan)?.months ?? 12).toString());
  late final _ref = TextEditingController(text: widget.reference ?? '');
  final _note = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    _months.dispose();
    _ref.dispose();
    _note.dispose();
    super.dispose();
  }

  InputDecoration _dec(String l) => InputDecoration(labelText: l, isDense: true);

  void _ok() {
    final amount = num.tryParse(_amount.text.trim());
    final months = int.tryParse(_months.text.trim());
    if (amount == null || amount < 0) {
      setState(() => _error = 'Enter a valid amount.');
      return;
    }
    if (months == null || months <= 0) {
      setState(() => _error = 'Enter the validity in months.');
      return;
    }
    final plan = widget.cfg.plan(_plan) ?? widget.cfg.plans.first;
    Navigator.pop(
        context,
        PaymentEntry(
          planId: plan.id,
          planName: plan.name,
          amount: amount,
          months: months,
          method: _method,
          reference: _ref.text.trim(),
          note: _note.text.trim(),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          DropdownButtonFormField<String>(
            initialValue: _plan,
            decoration: _dec('Plan'),
            items: widget.cfg.plans
                .map((p) => DropdownMenuItem(value: p.id, child: Text(p.name)))
                .toList(),
            onChanged: (v) {
              final p = widget.cfg.plan(v);
              setState(() {
                _plan = v ?? _plan;
                if (p != null && p.price > 0) _amount.text = p.price.toString();
                if (p != null) _months.text = p.months.toString();
              });
            },
          ),
          const SizedBox(height: 8),
          TextField(
              controller: _amount,
              keyboardType: TextInputType.number,
              decoration: _dec('Amount received (Rs.)')),
          const SizedBox(height: 8),
          TextField(
              controller: _months,
              keyboardType: TextInputType.number,
              decoration: _dec('Validity (months)')),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _method,
            decoration: _dec('Method'),
            items: kMethods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
            onChanged: (v) => setState(() => _method = v ?? _method),
          ),
          const SizedBox(height: 8),
          TextField(controller: _ref, decoration: _dec('Reference / UTR')),
          const SizedBox(height: 8),
          TextField(controller: _note, decoration: _dec('Note (optional)')),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
            ),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        TextButton(onPressed: _ok, child: const Text('Confirm')),
      ],
    );
  }
}
