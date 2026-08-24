import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// IMPORTANT WEB NOTE:
/// Browsers do not expose any stable hardware device ID (for privacy
/// reasons), so the device-binding security feature works differently
/// on web than on Android/iOS:
///   - Android/iOS: a real, stable hardware-backed ID (Android ID /
///     iOS identifierForVendor) — survives app reinstalls in most cases.
///   - Web: a random ID generated once and stored in the browser's
///     local storage. This is stable across page reloads and browser
///     restarts on the SAME browser/device, but:
///       * clearing browser storage / using a different browser /
///         incognito mode will look like a "new device" to the app
///       * it is not a hardware identifier, so it offers weaker
///         guarantees than the native platform IDs
/// This is a reasonable, honest trade-off for a web deployment — just
/// make wardens aware that "device changed" requests may be a little
/// more frequent for students using the web version.
class DeviceHelper {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  static const _webDeviceIdKey = 'chowkidar_web_device_id';

  static Future<String> getDeviceId() async {
    // Check kIsWeb FIRST — Platform.isAndroid/isIOS throws on web before
    // we'd ever reach the safe branch, so we must never call them there.
    if (kIsWeb) {
      return _getOrCreateWebDeviceId();
    }
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final info = await _deviceInfo.androidInfo;
        // ANDROID_ID — unique per device per app install
        return info.id;
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final info = await _deviceInfo.iosInfo;
        return info.identifierForVendor ?? 'ios_unknown';
      }
      return 'unknown_platform';
    } catch (e) {
      return 'unknown_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  static Future<String> _getOrCreateWebDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? existing = prefs.getString(_webDeviceIdKey);
    if (existing != null) return existing;

    // Generate once, store, and reuse from now on for this browser.
    final newId = 'web_${DateTime.now().millisecondsSinceEpoch}_'
        '${(1000 + (DateTime.now().microsecond % 9000))}';
    await prefs.setString(_webDeviceIdKey, newId);
    return newId;
  }

  static Future<String> getDeviceName() async {
    if (kIsWeb) {
      try {
        final info = await _deviceInfo.webBrowserInfo;
        return '${info.browserName.name} on ${info.platform ?? 'Web'}';
      } catch (_) {
        return 'Web Browser';
      }
    }
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final info = await _deviceInfo.androidInfo;
        return '${info.brand} ${info.model}';
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final info = await _deviceInfo.iosInfo;
        return info.name;
      }
      return 'Unknown Device';
    } catch (_) {
      return 'Unknown Device';
    }
  }
}
