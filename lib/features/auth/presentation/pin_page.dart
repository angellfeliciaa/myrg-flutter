import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../data/demo_session.dart';
import 'widgets/pin_pad_screen.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/backend_config.dart';
import '../../../core/session/session_store.dart';
import '../data/auth_api.dart';
import 'forgot_pin.dart';

class PinPage extends StatelessWidget {
  const PinPage({super.key});

  /// Quick unlock found that another phone is now the account's trusted device: verify this
  /// phone with an OTP instead of leaving the member stuck on the PIN pad.
  Future<void> _verifyThisPhone(BuildContext context) async {
    final phone = SessionStore.phone;
    if (phone == null) {
      context.go(AppRoutes.login);
      return;
    }
    try {
      AuthApi.purpose = OtpPurpose.newDevice;
      await AuthApi.sendOtp(phone);
      if (context.mounted) context.push(AppRoutes.otp, extra: phone);
    } on ApiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _forgotPin(BuildContext context) async {
    final changed = await runForgotPin(
      context,
      initialPhone: SessionStore.phone ?? '',
    );
    if (!changed || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PIN baru disimpan. Masukkan PIN baru.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PinPadScreen(
      title: 'Masukkan PIN',
      description: 'Masukkan 6 digit PIN anda',
      dark: true,
      footer: BackendConfig.enabled
          ? TextButton(
              onPressed: () => _forgotPin(context),
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              child: const Text('Lupa PIN?'),
            )
          : null,
      hint: BackendConfig.enabled
          ? null
          : DemoSession.hasDefaultPin
          ? 'Demo FE • PIN awal 123456'
          : 'Demo FE • Gunakan PIN yang sudah dibuat',
      onBack: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(AppRoutes.login);
        }
      },
      onCompleted: (pin) async {
        if (BackendConfig.enabled) {
          try {
            await AuthApi.insertPin(pin);
            if (context.mounted) context.go(AppRoutes.home);
            return null;
          } on ApiException catch (e) {
            if (!context.mounted) return e.message;
            if (e.code == 'LOGIN_EXPIRED') context.go(AppRoutes.login);
            if (e.code == 'DEVICE_VERIFICATION_REQUIRED') {
              await _verifyThisPhone(context);
            }
            return e.message;
          }
        }
        final valid = await DemoSession.verifyPin(pin);
        if (!context.mounted) return null;
        if (!valid) return 'PIN salah. Silakan coba kembali.';
        context.go(AppRoutes.home);
        return null;
      },
    );
  }
}
