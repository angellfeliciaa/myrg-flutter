import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/router/app_router.dart';
import 'widgets/pin_pad_screen.dart';

class CreatePinPage extends StatelessWidget {
  const CreatePinPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PinPadScreen(
      title: AppStrings.createPin,
      description: AppStrings.createPinDescription,
      onBack: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(AppRoutes.otp);
        }
      },
      onCompleted: (pin) async {
        await context.push(AppRoutes.confirmPin, extra: pin);
        return null;
      },
    );
  }
}
