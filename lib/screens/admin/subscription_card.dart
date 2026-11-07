import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/payment_config.dart';
import '../../utils/tenant.dart';
import '../../widgets/ui.dart';

/// Plan, validity and payment receipts of this college.
class SubscriptionCard extends StatelessWidget {
  const SubscriptionCard({super.key});

  String _receiptText(Map<String, dynamic> r) {
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

  void _showReceipt(BuildContext context, Map<String, dynamic> r) {
    final text = _receiptText(r);
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

  @override
  Widget build(BuildContext context) {
    final exp = Tenant.expiresAt;
    final daysLeft = exp?.difference(DateTime.now()).inDays;
    final warn = daysLeft != null && daysLeft <= 30;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Subscription',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kNavy)),
      const SizedBox(height: 12),
      SectionCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(Tenant.planName.isEmpty ? 'Plan: -' : 'Plan: ${Tenant.planName}',
              style: const TextStyle(fontWeight: FontWeight.bold, color: kNavy)),
          const SizedBox(height: 4),
          Text(
              exp == null
                  ? 'Valid: no expiry date set'
                  : 'Valid until ${formatDate(exp)}${daysLeft! >= 0 ? ' ($daysLeft days left)' : ''}',
              style: TextStyle(color: warn ? const Color(0xFFC62828) : Colors.black87)),
          if (warn)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text('Your subscription ends soon. Contact CampusShield to renew.',
                  style: TextStyle(color: Color(0xFFC62828), fontSize: 12)),
            ),
        ]),
      ),
      const SizedBox(height: 4),
      const Text('Receipts',
          style: TextStyle(fontWeight: FontWeight.bold, color: kNavy)),
      const SizedBox(height: 8),
      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('receipts')
            .where('collegeId', isEqualTo: Tenant.id)
            .snapshots(),
        builder: (context, snap) {
          if (snap.hasError) return const Text('Could not load receipts.');
          if (!snap.hasData) return const LinearProgressIndicator();
          final docs = snap.data!.docs.toList()
            ..sort((a, b) {
              final x = a.data()['issuedAt'];
              final y = b.data()['issuedAt'];
              if (x is Timestamp && y is Timestamp) return y.compareTo(x);
              return 0;
            });
          if (docs.isEmpty) {
            return const Text('No receipts yet.', style: TextStyle(color: Colors.black54));
          }
          return Column(
            children: docs.map((d) {
              final r = d.data();
              final issued = r['issuedAt'];
              return SectionCard(
                child: InkWell(
                  onTap: () => _showReceipt(context, r),
                  child: Row(children: [
                    const Icon(Icons.receipt_long, color: kNavy),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('${r['receiptNo']}',
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text(
                            '${r['planName']} - Rs. ${r['amount']}${issued is Timestamp ? ' - ${formatDate(issued.toDate())}' : ''}',
                            style: const TextStyle(color: Colors.black54, fontSize: 12)),
                      ]),
                    ),
                    const Icon(Icons.chevron_right),
                  ]),
                ),
              );
            }).toList(),
          );
        },
      ),
    ]);
  }
}
