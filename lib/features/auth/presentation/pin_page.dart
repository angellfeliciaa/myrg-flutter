import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../data/demo_session.dart';
import 'widgets/pin_pad_screen.dart';

class PinPage extends StatelessWidget {
  const PinPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PinPadScreen(
      title: 'Masukkan PIN',
      description: 'Masukkan 6 digit PIN anda',
      dark: true,
      hint: DemoSession.hasDefaultPin
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
        final valid = await DemoSession.verifyPin(pin);
        if (!context.mounted) return null;
        if (!valid) return 'PIN salah. Silakan coba kembali.';
        context.go(AppRoutes.home);
        return null;
      },
    );
  }
}
