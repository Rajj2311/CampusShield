import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import 'payment_config.dart';

/// Multi-college (multi-tenant) context.
///
/// Every college's data lives under `colleges/{collegeId}/...`.
/// All screens must use [Tenant.col] instead of
/// `FirebaseFirestore.instance.collection(...)` for college data.
///
/// Global (non-tenant) collections:
///   colleges/{id}      -> public college profile + config (status, hostels, ...)
///   userIndex/{uid}    -> which college + role + doc a signed-in user belongs to
class Tenant {
  static const _prefKey = 'collegeId';
  static const statusApproved = 'approved';

  static String? _id;
  static Map<String, dynamic> _config = {};

  static bool get isSet => _id != null;

  static String get id {
    final v = _id;
    if (v == null) {
      throw StateError('Tenant not set. Select a college first.');
    }
    return v;
  }

  static Map<String, dynamic> get config => _config;
  static String get name => (_config['name'] as String?) ?? 'College';
  static String? get logoUrl => _config['logoUrl'] as String?;

  static DocumentReference<Map<String, dynamic>> get doc =>
      FirebaseFirestore.instance.collection('colleges').doc(id);

  /// College-scoped collection, e.g. Tenant.col('students').
  static CollectionReference<Map<String, dynamic>> col(String name) =>
      doc.collection(name);

  // ── Per-college customisation (falls back to defaults) ───────────
  static List<String> get hostels {
    final h = _config['hostels'];
    if (h is List && h.isNotEmpty) return h.map((e) => e.toString()).toList();
    return kHostelBlocks;
  }

  static List<Map<String, dynamic>> get workerCategories {
    final c = _config['workerCategories'];
    if (c is List && c.isNotEmpty) {
      return c.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return kWorkerCategories;
  }

  /// Campus polygon as [[lat,lng],...]; null if the college hasn't set one.
  static List<List<double>>? get geofence {
    final g = _config['geofence'];
    if (g is List && g.length >= 3) {
      return g
          .map((p) => [
                ((p as Map)['lat'] as num).toDouble(),
                (p['lng'] as num).toDouble(),
              ])
          .toList();
    }
    return null;
  }

  static DateTime? get expiresAt {
    final e = _config['expiresAt'];
    return e is Timestamp ? e.toDate() : null;
  }

  static String get planName => (_config['planName'] as String?) ?? '';

  static int get attendanceStartHour =>
      (_config['attendanceStartHour'] as num?)?.toInt() ?? 20;
  static int get attendanceEndHour =>
      (_config['attendanceEndHour'] as num?)?.toInt() ?? 21;

  // ── Loading / switching college ──────────────────────────────────
  /// Loads a college profile and makes it the active tenant.
  /// Returns null on success, or a user-facing error message.
  /// Set when the college was loaded with [allowInactive] while suspended or
  /// expired (only used to show the college admin the renewal screen).
  static String? inactiveReason;

  static Future<String?> load(String collegeId, {bool allowInactive = false}) async {
    inactiveReason = null;
    final cid = collegeId.trim().toLowerCase();
    if (cid.isEmpty) return 'Enter your college code.';
    try {
      final snap =
          await FirebaseFirestore.instance.collection('colleges').doc(cid).get();
      if (!snap.exists) return 'College not found. Check the code.';
      final data = snap.data() ?? {};
      final status = data['status'] as String? ?? 'pending';
      if (status == 'pending') {
        return 'This college is awaiting approval from Chowkidar.';
      }
      if (status != statusApproved) {
        const msg = 'This college account is suspended. Contact Chowkidar support.';
        if (!allowInactive) return msg;
        inactiveReason = msg;
      }
      final exp = data['expiresAt'];
      if (inactiveReason == null &&
          exp is Timestamp &&
          exp.toDate().isBefore(DateTime.now())) {
        final cfg = await PaymentConfig.load();
        final contact = cfg.phone.isEmpty ? 'Chowkidar support' : cfg.phone;
        final msg =
            'The subscription of this college has expired. Contact $contact to renew.';
        if (!allowInactive) return msg;
        inactiveReason = msg;
      }
      _id = cid;
      _config = data;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, cid);
      return null;
    } catch (e) {
      return 'Could not reach server. Check your internet.';
    }
  }

  /// Re-reads the active college profile (after an admin changes settings).
  static Future<void> reload() async {
    final snap = await doc.get();
    final data = snap.data();
    if (data != null) _config = data;
  }

  /// Restores the last used college (before login).
  static Future<bool> restore() async {
    if (_id != null) return true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefKey);
      if (saved == null) return false;
      return (await load(saved)) == null;
    } catch (_) {
      return false;
    }
  }

  static Future<void> clear() async {
    _id = null;
    _config = {};
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefKey);
    } catch (_) {}
  }

  // ── User index (uid -> college/role/doc) ─────────────────────────
  /// Called right after Firebase Auth account creation. Security rules
  /// verify the role code (staff) or the student doc (students), so a
  /// wrong code throws permission-denied here.
  static Future<void> bindUser({
    required String uid,
    required String role, // warden | guard | worker | student
    required String docId,
    String? code,
  }) async {
    await FirebaseFirestore.instance.collection('userIndex').doc(uid).set({
      'collegeId': id,
      'role': role,
      'docId': docId,
      'code': ?code,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
