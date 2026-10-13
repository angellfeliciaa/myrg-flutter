import 'package:flutter/foundation.dart';

class DemoContact {
  const DemoContact({
    this.email = 'estherhoward@gmail.com',
    this.phone = '+6287860709553',
    this.isFixture = true,
    this.avatarBytes,
    this.avatarUrl,
    this.birthDate,
  });
  final String email;
  final String phone;
  final bool isFixture;

  /// Demo mode: the photo picked on Edit Akun, kept for this session only.
  final Uint8List? avatarBytes;

  /// Backend mode only: profile photo (GET /me avatarUrl) and birth date (yyyy-MM-dd).
  final String? avatarUrl;
  final String? birthDate;
}

/// In-memory FE simulation only. Never a credential store or production auth.
abstract final class DemoSession {
  static final contact = ValueNotifier(const DemoContact());
  static String _pin = '123456';
  static String _password = 'password123';
  static bool authenticated = false;
  static bool get hasDefaultPin => _pin == '123456';
  static void setContact({
    required String email,
    required String phone,
    String? avatarUrl,
    String? birthDate,
  }) {
    contact.value = DemoContact(
      email: email,
      phone: phone,
      isFixture: false,
      avatarUrl: avatarUrl,
      birthDate: birthDate,
    );
  }

  /// Local preview only: never submits identity changes to RG.
  static void updateProfile({
    required String email,
    required String phone,
    required Uint8List? avatarBytes,
  }) {
    contact.value = DemoContact(
      email: email,
      phone: phone,
      isFixture: contact.value.isFixture,
      avatarBytes: avatarBytes,
    );
  }

  static void createPin(String pin) {
    _pin = pin;
    authenticated = true;
  }

  static Future<bool> verifyPin(String pin) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    final valid = pin == _pin;
    if (valid) authenticated = true;
    return valid;
  }

  static Future<bool> login(String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    return password == _password;
  }

  static Future<bool> changePassword(
    String oldPassword,
    String newPassword,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (oldPassword != _password) return false;
    _password = newPassword;
    return true;
  }

  static void logout() {
    authenticated = false;
  }

  static void reset() {
    _pin = '123456';
    _password = 'password123';
    authenticated = false;
    contact.value = const DemoContact();
  }
}
