import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_exception.dart';
import '../../../shared/widgets/phase_one_widgets.dart';
import '../../auth/data/auth_api.dart';

/// Ganti PIN (backend mode): current PIN + new PIN (PUT /me/pin). Weak PINs (123456, 111111,
/// birth date) are refused by the backend with WEAK_PIN.
class ChangePinPage extends StatefulWidget {
  const ChangePinPage({super.key});
  @override
  State<ChangePinPage> createState() => _ChangePinPageState();
}

class _ChangePinPageState extends State<ChangePinPage> {
  final _form = GlobalKey<FormState>();
  final _current = TextEditingController(),
      _new = TextEditingController(),
      _confirm = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  String? _sixDigits(String? value) =>
      (value ?? '').length == 6 ? null : 'Masukkan 6 digit PIN';

  Future<void> _submit() async {
    if (_loading || !_form.currentState!.validate()) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AuthApi.changePin(_current.text, _new.text);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(
            Icons.check_circle_outline,
            color: AppColors.success,
            size: 40,
          ),
          title: const Text('PIN diperbarui'),
          content: const Text(
            'Gunakan PIN baru saat membuka aplikasi. Perangkat lain sudah dikeluarkan.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Mengerti'),
            ),
          ],
        ),
      );
      if (mounted) Navigator.pop(context);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.displayMessage);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _field(
    String label,
    TextEditingController c, {
    FormFieldValidator<String>? validator,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      controller: c,
      obscureText: true,
      keyboardType: TextInputType.number,
      maxLength: 6,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(labelText: label, counterText: ''),
      validator: validator ?? _sixDigits,
    ),
  );

  @override
  Widget build(BuildContext context) => PhaseOneScaffold(
    title: 'Ganti PIN',
    child: Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'PIN dipakai untuk membuka aplikasi dan mengonfirmasi perubahan akun.',
            style: TextStyle(fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 24),
          _field('PIN saat ini', _current),
          _field('PIN baru', _new),
          _field(
            'Ulangi PIN baru',
            _confirm,
            validator: (value) => value == _new.text ? null : 'PIN tidak sama',
          ),
          if (_error != null) ...[
            Text(_error!, style: const TextStyle(color: AppColors.error)),
            const SizedBox(height: 16),
          ],
          PhaseOneButton(
            label: 'Simpan PIN',
            loading: _loading,
            onPressed: _submit,
          ),
        ],
      ),
    ),
  );
}
