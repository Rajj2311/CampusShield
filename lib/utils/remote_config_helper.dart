import 'package:firebase_remote_config/firebase_remote_config.dart';

class RemoteConfigHelper {
  static final _rc = FirebaseRemoteConfig.instance;
  static bool _initialized = false;

  // ── App start pe ek baar call karo ──────────────────────────────
  static Future<void> init() async {
    if (_initialized) return;
    await _rc.setConfigSettings(RemoteConfigSettings(
      fetchTimeout:        const Duration(seconds: 10),
      minimumFetchInterval: const Duration(minutes: 1), // 1 min cache
    ));
    await _rc.setDefaults({
      'warden_secret_code': 'IILM-WARDEN-2026',
      'guard_secret_code':  'IILM-GUARD-2026',
      'worker_secret_code': 'IILM-WORKER-2026',
    });
    await _rc.fetchAndActivate();
    _initialized = true;
  }

  // ── Secret codes fetch karo ──────────────────────────────────────
  static String get wardenCode =>
      _rc.getString('warden_secret_code');
  static String get guardCode =>
      _rc.getString('guard_secret_code');
  static String get workerCode =>
      _rc.getString('worker_secret_code');

  // ── Fresh fetch (register screen pe call karo) ───────────────────
  static Future<void> refresh() async {
    await _rc.fetchAndActivate();
  }
}