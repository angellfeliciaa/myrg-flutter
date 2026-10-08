import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/router/app_router.dart';
import 'widgets/pin_pad_screen.dart';
import '../data/demo_session.dart';

class ConfirmPinPage extends StatelessWidget {
  const ConfirmPinPage({required this.createdPin, super.key});

  final String createdPin;

  @override
  Widget build(BuildContext context) {
    return PinPadScreen(
      title: AppStrings.confirmPin,
      description: AppStrings.confirmPinDescription,
      onBack: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(AppRoutes.createPin);
        }
      },
      onCompleted: (pin) async {
        if (pin != createdPin) {
          return 'PIN tidak sama. Silakan masukkan kembali.';
        }

        if (!context.mounted) return null;
        DemoSession.createPin(pin);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('PIN berhasil dibuat.')));
        context.go(AppRoutes.home);
        return null;
      },
    );
  }
}
