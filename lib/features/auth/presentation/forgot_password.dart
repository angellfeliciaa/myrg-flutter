import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/app_button.dart';
import '../data/auth_api.dart';

/// Lupa Password (backend mode): phone -> OTP (/otp/send, /otp/verify) -> new password
/// (/password/reset). Returns the phone when the password was changed, so the login form can
/// be filled in with it.
Future<String?> runForgotPassword(
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
  if (phone == null || !context.mounted) return null;

  final verified = await context.push<bool>(AppRoutes.otp, extra: phone);
  if (verified != true || !context.mounted) return null;

  final changed = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    isDismissible: false,
    builder: (_) => const _NewPasswordSheet(),
  );
  return changed == true ? phone : null;
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
      AuthApi.purpose = OtpPurpose.forgotPassword;
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
            'Lupa Password',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            'Masukkan nomor HP yang terdaftar. Kami kirim kode OTP untuk membuat password baru.',
            style: TextStyle(fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Nomor HP',
              hintText: '08xxxxxxxxxx',
            ),
            validator: Validators.indonesianPhone,
            onFieldSubmitted: (_) => _send(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Colors.red)),
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

class _NewPasswordSheet extends StatefulWidget {
  const _NewPasswordSheet();
  @override
  State<_NewPasswordSheet> createState() => _NewPasswordSheetState();
}

class _NewPasswordSheetState extends State<_NewPasswordSheet> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _form = GlobalKey<FormState>();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  /// Same rule as the backend's PasswordPolicy: at least 8 characters, letters and digits.
  String? _validate(String? value) {
    final base = Validators.password(value);
    if (base != null) return base;
    final hasLetter = RegExp(r'[A-Za-z]').hasMatch(value!);
    final hasDigit = RegExp(r'\d').hasMatch(value);
    return hasLetter && hasDigit
        ? null
        : 'Password harus berisi huruf dan angka';
  }

  Future<void> _save() async {
    if (_loading || !_form.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AuthApi.resetPassword(_password.text);
      if (mounted) Navigator.pop(context, true);
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
            'Buat Password Baru',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _password,
            obscureText: true,
            autofocus: true,
            autofillHints: const [AutofillHints.newPassword],
            decoration: const InputDecoration(
              labelText: 'Password baru',
              hintText: 'Minimal 8 karakter, huruf dan angka',
            ),
            validator: _validate,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _confirm,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Ulangi password baru',
            ),
            validator: (value) =>
                value == _password.text ? null : 'Password tidak sama',
            onFieldSubmitted: (_) => _save(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 20),
          AppButton(
            label: 'Simpan Password',
            isLoading: _loading,
            onPressed: _save,
          ),
          TextButton(
            onPressed: _loading ? null : () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
        ],
      ),
    ),
  );
}
