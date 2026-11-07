import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../payment_config.dart';
import '../theme.dart';
import 'payment_settings_screen.dart';

String receiptText(Map<String, dynamic> r) {
  DateTime? t(String k) => r[k] is Timestamp ? (r[k] as Timestamp).toDate() : null;
  final from = t('periodStart');
  final to = t('periodEnd');
  final issued = t('issuedAt');
  return [
    'CAMPUSSHIELD - PAYMENT RECEIPT',
    'Receipt no: ${r['receiptNo']}',
    if (issued != null) 'Date: ${formatDate(issued)}',
    'College: ${r['collegeName']} (${r['collegeId']})',
    'Plan: ${r['planName']}',
    'Amount received: Rs. ${r['amount']}',
    'Method: ${r['method']}${(r['reference'] ?? '').toString().isEmpty ? '' : ' (${r['reference']})'}',
    if (from != null && to != null) 'Valid: ${formatDate(from)} to ${formatDate(to)}',
  ].join('\n');
}

void showReceipt(BuildContext context, Map<String, dynamic> r) {
  final text = receiptText(r);
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Receipt'),
      content: SelectableText(text),
      actions: [
        TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: text));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('Receipt copied')));
            },
            child: const Text('Copy')),
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
      ],
    ),
  );
}

/// All receipts + access to payment settings.
class PaymentsScreen extends StatelessWidget {
  final String? collegeId; // null = every college
  const PaymentsScreen({super.key, this.collegeId});

  @override
  Widget build(BuildContext context) {
    Query<Map<String, dynamic>> q = FirebaseFirestore.instance.collection('receipts');
    if (collegeId != null) q = q.where('collegeId', isEqualTo: collegeId);
    return Column(children: [
      if (collegeId == null)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const PaymentSettingsScreen())),
              icon: const Icon(Icons.settings),
              label: const Text('Payment settings & plans'),
            ),
          ),
        ),
      Expanded(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: q.snapshots(),
          builder: (context, snap) {
            if (snap.hasError) return Center(child: Text('Could not load.\n${snap.error}'));
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            final docs = snap.data!.docs.toList()
              ..sort((a, b) {
                final x = a.data()['issuedAt'];
                final y = b.data()['issuedAt'];
                if (x is Timestamp && y is Timestamp) return y.compareTo(x);
                return 0;
              });
            if (docs.isEmpty) {
              return const Center(
                  child: Text('No receipts yet.', style: TextStyle(color: Colors.black54)));
            }
            num total = 0;
            for (final d in docs) {
              final a = d.data()['amount'];
              if (a is num) total += a;
            }
            return ListView(padding: const EdgeInsets.all(16), children: [
              Card2(
                child: Row(children: [
                  const Icon(Icons.account_balance_wallet, color: kAmber),
                  const SizedBox(width: 12),
                  Text('Total received: Rs. $total  (${docs.length} receipts)',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: kNavy)),
                ]),
              ),
              ...docs.map((d) {
                final r = d.data();
                final issued = r['issuedAt'];
                return Card2(
                  onTap: () => showReceipt(context, r),
                  child: Row(children: [
                    const Icon(Icons.receipt_long, color: kNavy),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('${r['collegeName']}  -  Rs. ${r['amount']}',
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text(
                            '${r['receiptNo']}  |  ${r['planName']}${issued is Timestamp ? '  |  ${formatDate(issued.toDate())}' : ''}',
                            style: const TextStyle(color: Colors.black54, fontSize: 12)),
                      ]),
                    ),
                  ]),
                );
              }),
            ]);
          },
        ),
      ),
    ]);
  }
}
