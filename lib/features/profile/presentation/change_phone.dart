import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/app_button.dart';
import '../../auth/data/auth_api.dart';
import 'pin_prompt.dart';

/// Ganti Nomor HP (backend mode): new number -> OTP to that number -> confirm with the PIN
/// (PUT /me/phone). Returns true when the number was changed.
Future<bool> runChangePhone(BuildContext context) async {
  final phone = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => const _NewPhoneSheet(),
  );
  if (phone == null || !context.mounted) return false;
  final verified = await context.push<bool>(AppRoutes.otp, extra: phone);
  if (verified != true || !context.mounted) return false;
  return askPin(
    context,
    title: 'Konfirmasi PIN',
    message: 'Masukkan PIN untuk mengganti nomor HP menjadi $phone.',
    actionLabel: 'Ganti Nomor',
    onPin: AuthApi.changePhone,
  );
}

class _NewPhoneSheet extends StatefulWidget {
  const _NewPhoneSheet();
  @override
  State<_NewPhoneSheet> createState() => _NewPhoneSheetState();
}

class _NewPhoneSheetState extends State<_NewPhoneSheet> {
  final _phone = TextEditingController();
  final _form = GlobalKey<FormState>();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_loading || !_form.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      AuthApi.purpose = OtpPurpose.changePhone;
      await AuthApi.sendOtp(_phone.text.trim());
      if (mounted) Navigator.pop(context, _phone.text.trim());
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.displayMessage);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      24,
      8,
      24,
      24 + MediaQuery.viewInsetsOf(context).bottom,
    ),
    child: Form(
      key: _form,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Ganti Nomor HP',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            'Kode OTP dikirim ke nomor baru. Setelah itu konfirmasi dengan PIN.',
            style: TextStyle(fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _phone,
            autofocus: true,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Nomor HP baru',
              hintText: '08xxxxxxxxxx',
            ),
            validator: Validators.indonesianPhone,
            onFieldSubmitted: (_) => _send(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: AppColors.error)),
          ],
          const SizedBox(height: 20),
          AppButton(
            label: 'Kirim Kode OTP',
            isLoading: _loading,
            onPressed: _send,
          ),
        ],
      ),
    ),
  );
}
