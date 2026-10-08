import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/phase_one_widgets.dart';
import '../../auth/data/demo_session.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});
  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _form = GlobalKey<FormState>();
  final _old = TextEditingController(),
      _new = TextEditingController(),
      _confirm = TextEditingController();
  final _visible = [false, false, false];
  bool _loading = false;
  String? _error;
  @override
  void dispose() {
    _old.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading || !_form.currentState!.validate()) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });
    final valid = await DemoSession.changePassword(_old.text, _new.text);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (!valid) _error = 'Password lama tidak sesuai dengan akun demo.';
    });
    if (!valid) return;
    _old.clear();
    _new.clear();
    _confirm.clear();
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.check_circle_outline,
          color: AppColors.success,
          size: 40,
        ),
        title: const Text('Password demo diperbarui'),
        content: const Text(
          'Perubahan hanya berlaku selama aplikasi ini terbuka. Tidak ada password akun asli yang diubah.',
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
  }

  @override
  Widget build(BuildContext context) => PhaseOneScaffold(
    title: 'Ganti Password',
    footer: PhaseOneButton(
      label: 'Simpan Password',
      loading: _loading,
      onPressed: _submit,
    ),
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _form,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Jaga keamanan akunmu',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Buat password baru yang berbeda dari password sebelumnya.',
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            for (int index = 0; index < 3; index++) ...[
              Text(
                [
                  'Password Lama',
                  'Password Baru',
                  'Konfirmasi Password Baru',
                ][index],
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: [_old, _new, _confirm][index],
                enabled: !_loading,
                obscureText: !_visible[index],
                enableSuggestions: false,
                autocorrect: false,
                textInputAction: index == 2
                    ? TextInputAction.done
                    : TextInputAction.next,
                onFieldSubmitted: index == 2 ? (_) => _submit() : null,
                validator: (value) {
                  final required = Validators.required(
                    value,
                    fieldName: 'Password',
                  );
                  if (required != null) return required;
                  if (index == 1) {
                    final error = Validators.password(value);
                    if (error != null) return error;
                    if (value == _old.text) {
                      return 'Password baru harus berbeda.';
                    }
                  }
                  if (index == 2 && value != _new.text) {
                    return 'Konfirmasi password tidak sama.';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  fillColor: AppColors.fieldBackground,
                  hintText: index == 1
                      ? 'Minimal 8 karakter'
                      : 'Masukkan password',
                  hintStyle: const TextStyle(fontSize: 13),
                  suffixIcon: IconButton(
                    tooltip: _visible[index]
                        ? 'Sembunyikan password'
                        : 'Tampilkan password',
                    onPressed: () =>
                        setState(() => _visible[index] = !_visible[index]),
                    icon: Icon(
                      _visible[index]
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
            if (_error != null)
              Text(
                _error!,
                style: const TextStyle(color: AppColors.error, fontSize: 13),
              ),
            const SizedBox(height: 16),
            const Text(
              'Demo FE • Password awal: password123. Gunakan data contoh, bukan password akun asli.',
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
