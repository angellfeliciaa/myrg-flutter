import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/app_button.dart';
import '../data/auth_api.dart';

/// Lupa PIN (backend mode): phone -> OTP -> new PIN (/auth/pin/reset). Every session ends, so
/// the member unlocks with the new PIN afterwards. Returns true when the PIN was changed.
Future<bool> runForgotPin(
  BuildContext context, {
  String initialPhone = '',
}) async {
  final phone = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _PhoneSheet(initialPhone: initialPhone),
  );
  if (phone == null || !context.mounted) return false;

  final verified = await context.push<bool>(AppRoutes.otp, extra: phone);
  if (verified != true || !context.mounted) return false;

  return await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        isDismissible: false,
        builder: (_) => const _NewPinSheet(),
      ) ==
      true;
}

class _PhoneSheet extends StatefulWidget {
  const _PhoneSheet({required this.initialPhone});
  final String initialPhone;
  @override
  State<_PhoneSheet> createState() => _PhoneSheetState();
}

class _PhoneSheetState extends State<_PhoneSheet> {
  late final _phone = TextEditingController(text: widget.initialPhone);
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
      AuthApi.purpose = OtpPurpose.resetPin;
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
            'Lupa PIN',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            'Kami kirim kode OTP ke nomor HP akun kamu untuk membuat PIN baru.',
            style: TextStyle(fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Nomor HP',
              hintText: '08xxxxxxxxxx',
            ),
            validator: (value) {
              // The stored number is +62...; the form check wants 08...
              final local = (value ?? '').trim().replaceFirst(
                RegExp(r'^\+?62'),
                '0',
              );
              return Validators.indonesianPhone(local);
            },
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

class _NewPinSheet extends StatefulWidget {
  const _NewPinSheet();
  @override
  State<_NewPinSheet> createState() => _NewPinSheetState();
}

class _NewPinSheetState extends State<_NewPinSheet> {
  final _pin = TextEditingController();
  final _confirm = TextEditingController();
  final _form = GlobalKey<FormState>();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _pin.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_loading || !_form.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AuthApi.resetPin(_pin.text);
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.displayMessage);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _field(
    String label,
    TextEditingController controller,
    FormFieldValidator<String> validator,
  ) => TextFormField(
    controller: controller,
    obscureText: true,
    keyboardType: TextInputType.number,
    maxLength: 6,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    decoration: InputDecoration(labelText: label, counterText: ''),
    validator: validator,
  );

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
            'Buat PIN Baru',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 20),
          _field(
            'PIN baru',
            _pin,
            (v) => (v ?? '').length == 6 ? null : 'Masukkan 6 digit PIN',
          ),
          const SizedBox(height: 12),
          _field(
            'Ulangi PIN baru',
            _confirm,
            (v) => v == _pin.text ? null : 'PIN tidak sama',
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: AppColors.error)),
          ],
          const SizedBox(height: 20),
          AppButton(label: 'Simpan PIN', isLoading: _loading, onPressed: _save),
          TextButton(
            onPressed: _loading ? null : () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
        ],
      ),
    ),
  );
}
