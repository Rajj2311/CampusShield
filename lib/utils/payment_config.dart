import 'package:cloud_firestore/cloud_firestore.dart';

class PlanOption {
  final String id;
  final String name;
  final num price;
  final int months;
  final String features;
  const PlanOption({
    required this.id,
    required this.name,
    required this.price,
    required this.months,
    required this.features,
  });

  factory PlanOption.fromMap(Map<String, dynamic> m) => PlanOption(
        id: (m['id'] ?? '').toString(),
        name: (m['name'] ?? '').toString(),
        price: (m['price'] as num?) ?? 0,
        months: (m['months'] as num?)?.toInt() ?? 12,
        features: (m['features'] ?? '').toString(),
      );

  String get priceLabel => price > 0 ? 'Rs. $price for $months months' : 'Contact us for the price';
}

/// Payment instructions and plans, edited by the owner in the Owner app
/// (document `appConfig/payment`, publicly readable).
class PaymentConfig {
  final String payeeName;
  final String upiId;
  final String bankName;
  final String accountNo;
  final String ifsc;
  final String phone;
  final String whatsapp;
  final String email;
  final String instructions;
  final List<PlanOption> plans;

  const PaymentConfig({
    this.payeeName = '',
    this.upiId = '',
    this.bankName = '',
    this.accountNo = '',
    this.ifsc = '',
    this.phone = '',
    this.whatsapp = '',
    this.email = '',
    this.instructions =
        'Contact the Chowkidar team to pay. After paying, enter your payment reference in the app. Your college is activated once the payment is verified.',
    this.plans = const [
      PlanOption(id: 'basic', name: 'Basic', price: 0, months: 12, features: 'Core hostel management'),
      PlanOption(id: 'advanced', name: 'Advanced', price: 0, months: 12, features: 'All features'),
    ],
  });

  factory PaymentConfig.fromMap(Map<String, dynamic> m) {
    final raw = m['plans'];
    final plans = raw is List && raw.isNotEmpty
        ? raw.map((e) => PlanOption.fromMap(Map<String, dynamic>.from(e as Map))).toList()
        : const PaymentConfig().plans;
    String s(String k) => (m[k] ?? '').toString();
    return PaymentConfig(
      payeeName: s('payeeName'),
      upiId: s('upiId'),
      bankName: s('bankName'),
      accountNo: s('accountNo'),
      ifsc: s('ifsc'),
      phone: s('phone'),
      whatsapp: s('whatsapp'),
      email: s('email'),
      instructions: s('instructions').isEmpty ? const PaymentConfig().instructions : s('instructions'),
      plans: plans,
    );
  }

  static Future<PaymentConfig> load() async {
    try {
      final snap = await FirebaseFirestore.instance.collection('appConfig').doc('payment').get();
      final data = snap.data();
      if (data == null) return const PaymentConfig();
      return PaymentConfig.fromMap(data);
    } catch (_) {
      return const PaymentConfig();
    }
  }

  PlanOption? plan(String? id) {
    for (final p in plans) {
      if (p.id == id) return p;
    }
    return null;
  }
}

String formatDate(DateTime d) {
  const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${d.day} ${m[d.month - 1]} ${d.year}';
}
