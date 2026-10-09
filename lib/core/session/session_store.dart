import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Tokens and device identity, kept in the platform's secure storage (Keystore / Keychain) and
/// mirrored in memory so every request does not hit the disk.
abstract final class SessionStore {
  static const _storage = FlutterSecureStorage();
  static const _kAccess = 'myrg_access_token';
  static const _kRefresh = 'myrg_refresh_token';
  static const _kPhone = 'myrg_phone';
  static const _kDevice = 'myrg_device_id';

  static String? _access;
  static String? _refresh;
  static String? _phone;
  static String? _deviceId;
  static bool _loaded = false;

  static Future<void> load() async {
    if (_loaded) return;
    try {
      // One read instead of four: start-up waits on this before the first frame.
      final all = await _storage.readAll();
      _access = all[_kAccess];
      _refresh = all[_kRefresh];
      _phone = all[_kPhone];
      _deviceId = all[_kDevice];
    } catch (_) {
      // Unreadable storage (e.g. restored backup): start without a session.
    }
    _loaded = true;
  }

  static String? get accessToken => _access;
  static String? get refreshToken => _refresh;
  static String? get phone => _phone;

  /// A session exists that can be unlocked with the PIN on this device.
  static bool get hasSession => _refresh != null && _phone != null;

  /// One id per installation; the backend binds the session (and push token) to it.
  static Future<String> deviceId() async {
    await load();
    if (_deviceId != null) return _deviceId!;
    final random = Random.secure();
    _deviceId =
        'device-${List.generate(16, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join()}';
    await _storage.write(key: _kDevice, value: _deviceId);
    return _deviceId!;
  }

  /// `data.tokens` from pin/create, pin/insert, auth/login/otp or auth/refresh.
  static Future<void> saveTokens(Map<String, dynamic> tokens) async {
    _access = tokens['accessToken'] as String?;
    _refresh = tokens['refreshToken'] as String?;
    await Future.wait([
      _storage.write(key: _kAccess, value: _access),
      _storage.write(key: _kRefresh, value: _refresh),
    ]);
  }

  static Future<void> savePhone(String phone) async {
    _phone = phone;
    await _storage.write(key: _kPhone, value: phone);
  }

  /// Logout / session ended. The device id stays (same installation).
  static Future<void> clear() async {
    _access = null;
    _refresh = null;
    _phone = null;
    await Future.wait([
      _storage.delete(key: _kAccess),
      _storage.delete(key: _kRefresh),
      _storage.delete(key: _kPhone),
    ]);
  }

  /// Re-read tokens from storage (another refresh may have stored newer ones).
  static Future<void> reloadTokens() async {
    _access = await _storage.read(key: _kAccess);
    _refresh = await _storage.read(key: _kRefresh);
  }
}
