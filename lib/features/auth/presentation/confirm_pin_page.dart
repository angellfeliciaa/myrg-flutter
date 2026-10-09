import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/router/app_router.dart';
import 'widgets/pin_pad_screen.dart';
import '../data/demo_session.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/backend_config.dart';
import '../data/auth_api.dart';

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
        if (BackendConfig.enabled) return _createAccount(context, pin);
        DemoSession.createPin(pin);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('PIN berhasil dibuat.')));
        context.go(AppRoutes.home);
        return null;
      },
    );
  }

  /// pin/create: the account is made and logged in. Returns an error for the PIN pad, or null.
  Future<String?> _createAccount(BuildContext context, String pin) async {
    try {
      final outcome = await AuthApi.createPin(pin);
      if (!context.mounted) return null;
      if (outcome == 'syncMember') {
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Member kamu ditemukan'),
            content: const Text(
              'Data member Raja Gadai kamu sudah terhubung dengan akun ini.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Lanjut'),
              ),
            ],
          ),
        );
      }
      if (context.mounted) context.go(AppRoutes.home);
      return null;
    } on ApiException catch (e) {
      if (!context.mounted) return null;
      if (e.code == 'MEMBER_NUMBER_IN_USE') {
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            icon: const Icon(
              Icons.person_search_rounded,
              color: AppColors.primary,
              size: 32,
            ),
            title: const Text('Data member perlu diperiksa'),
            content: Text(e.message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Mengerti'),
              ),
            ],
          ),
        );
        if (context.mounted) context.go(AppRoutes.login);
        return null;
      }
      if (e.code == 'REGISTRATION_EXPIRED') {
        if (context.mounted) context.go(AppRoutes.register);
      }
      return e.message;
    }
  }
}
