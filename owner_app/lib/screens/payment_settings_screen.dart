import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../payment_config.dart';
import '../theme.dart';

/// Owner edits: payee/UPI/bank details, contact info, instructions and plans.
/// Colleges see these on their "How to pay" screen.
class PaymentSettingsScreen extends StatefulWidget {
  const PaymentSettingsScreen({super.key});
  @override
  State<PaymentSettingsScreen> createState() => _PaymentSettingsScreenState();
}

class _PlanRow {
  final String id;
  final TextEditingController name;
  final TextEditingController price;
  final TextEditingController months;
  final TextEditingController features;
  _PlanRow(PlanOption p)
      : id = p.id,
        name = TextEditingController(text: p.name),
        price = TextEditingController(text: p.price.toString()),
        months = TextEditingController(text: p.months.toString()),
        features = TextEditingController(text: p.features);
  void dispose() {
    name.dispose();
    price.dispose();
    months.dispose();
    features.dispose();
  }
}

class _PaymentSettingsScreenState extends State<PaymentSettingsScreen> {
  final _c = <String, TextEditingController>{};
  final List<_PlanRow> _plans = [];
  bool _loaded = false;
  bool _saving = false;

  static const _fields = <MapEntry<String, String>>[
    MapEntry('payeeName', 'Payee name'),
    MapEntry('upiId', 'UPI ID'),
    MapEntry('bankName', 'Bank name'),
    MapEntry('accountNo', 'Account number'),
    MapEntry('ifsc', 'IFSC'),
    MapEntry('phone', 'Contact phone'),
    MapEntry('whatsapp', 'WhatsApp number'),
    MapEntry('email', 'Contact email'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    for (final p in _plans) {
      p.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final cfg = await PaymentConfig.load();
    final m = cfg.toMap();
    for (final f in _fields) {
      _c[f.key] = TextEditingController(text: (m[f.key] ?? '').toString());
    }
    _c['instructions'] = TextEditingController(text: cfg.instructions);
    _plans.addAll(cfg.plans.map(_PlanRow.new));
    if (mounted) setState(() => _loaded = true);
  }

  void _msg(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _save() async {
    final plans = <Map<String, dynamic>>[];
    for (var i = 0; i < _plans.length; i++) {
      final p = _plans[i];
      final name = p.name.text.trim();
      if (name.isEmpty) {
        _msg('Every plan needs a name.');
        return;
      }
      plans.add({
        'id': p.id.isEmpty ? name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '') : p.id,
        'name': name,
        'price': num.tryParse(p.price.text.trim()) ?? 0,
        'months': int.tryParse(p.months.text.trim()) ?? 12,
        'features': p.features.text.trim(),
      });
    }
    if (plans.isEmpty) {
      _msg('Add at least one plan.');
      return;
    }
    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance.collection('appConfig').doc('payment').set({
        for (final e in _c.entries) e.key: e.value.text.trim(),
        'plans': plans,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _msg('Saved.');
    } on FirebaseException catch (e) {
      _msg('Could not save: ${e.message ?? e.code}');
    }
    if (mounted) setState(() => _saving = false);
  }

  Widget _tf(TextEditingController c, String label,
          {int lines = 1, TextInputType? type}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(
          controller: c,
          maxLines: lines,
          keyboardType: type,
          decoration: InputDecoration(
              labelText: label,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kNavy,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Payment settings',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : ListView(padding: const EdgeInsets.all(16), children: [
              const Text('Pay-to details (shown to colleges)',
                  style: TextStyle(fontWeight: FontWeight.bold, color: kNavy, fontSize: 16)),
              const SizedBox(height: 10),
              for (final f in _fields) _tf(_c[f.key]!, f.value),
              _tf(_c['instructions']!, 'How to pay (instructions)', lines: 4),
              const SizedBox(height: 8),
              const Text('Plans',
                  style: TextStyle(fontWeight: FontWeight.bold, color: kNavy, fontSize: 16)),
              const SizedBox(height: 10),
              for (var i = 0; i < _plans.length; i++)
                Card2(
                  child: Column(children: [
                    _tf(_plans[i].name, 'Plan name'),
                    Row(children: [
                      Expanded(
                          child: _tf(_plans[i].price, 'Price (Rs.)',
                              type: TextInputType.number)),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _tf(_plans[i].months, 'Months',
                              type: TextInputType.number)),
                    ]),
                    _tf(_plans[i].features, 'Features / description', lines: 2),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: _plans.length <= 1
                            ? null
                            : () => setState(() => _plans.removeAt(i).dispose()),
                        icon: const Icon(Icons.delete_outline, color: kRed),
                        label: const Text('Remove plan', style: TextStyle(color: kRed)),
                      ),
                    ),
                  ]),
                ),
              OutlinedButton.icon(
                onPressed: () => setState(() => _plans.add(_PlanRow(const PlanOption(
                    id: '', name: '', price: 0, months: 12, features: '')))),
                icon: const Icon(Icons.add),
                label: const Text('Add plan'),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: kNavy, foregroundColor: Colors.white),
                  child: const Text('SAVE'),
                ),
              ),
              const SizedBox(height: 24),
            ]),
    );
  }
}
