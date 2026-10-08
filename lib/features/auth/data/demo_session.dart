import 'package:flutter/foundation.dart';

class DemoContact {
  const DemoContact({
    this.email = 'estherhoward@gmail.com',
    this.phone = '+6287860709553',
    this.isFixture = true,
  });
  final String email;
  final String phone;
  final bool isFixture;
}

/// In-memory FE simulation only. Never a credential store or production auth.
abstract final class DemoSession {
  static final contact = ValueNotifier(const DemoContact());
  static String _pin = '123456';
  static String _password = 'password123';
  static bool authenticated = false;
  static bool get hasDefaultPin => _pin == '123456';
  static void setContact({required String email, required String phone}) {
    contact.value = DemoContact(email: email, phone: phone, isFixture: false);
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
