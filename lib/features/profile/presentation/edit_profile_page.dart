import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/phase_one_widgets.dart';
import '../../auth/data/auth_api.dart';
import '../../auth/data/demo_session.dart';
import '../../membership/data/member_api.dart';
import '../../membership/data/member_repository.dart';
import 'pin_prompt.dart';

/// Edit Profil (backend mode): photo, name, email, birth date (PUT /me, /me/avatar) and
/// Ganti Nomor HP (OTP to the new number + PIN, PUT /me/phone).
class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});
  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(
    text: MemberRepository.profile.value.name,
  );
  late final _email = TextEditingController(
    text: DemoSession.contact.value.email,
  );
  late DateTime? _birthDate = DateTime.tryParse(
    DemoSession.contact.value.birthDate ?? '',
  );
  bool _saving = false;
  bool _photoBusy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  void _snack(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 25),
      firstDate: DateTime(1900, 1, 2),
      lastDate: now.subtract(const Duration(days: 1)),
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await MemberApi.updateProfile(
        name: _name.text.trim(),
        email: _email.text.trim(),
        birthDate: _birthDate == null
            ? null
            : DateFormat('yyyy-MM-dd').format(_birthDate!),
      );
      if (!mounted) return;
      _snack('Profil diperbarui.');
      context.pop();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.displayMessage);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _photo() async {
    final hasPhoto = DemoSession.contact.value.avatarUrl != null;
    final choice = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Pilih dari galeri'),
            onTap: () => Navigator.pop(context, 'gallery'),
          ),
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('Ambil foto'),
            onTap: () => Navigator.pop(context, 'camera'),
          ),
          if (hasPhoto)
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.error),
              title: const Text(
                'Hapus foto',
                style: TextStyle(color: AppColors.error),
              ),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
          const SizedBox(height: 12),
        ],
      ),
    );
    if (choice == null || !mounted) return;
    setState(() => _photoBusy = true);
    try {
      if (choice == 'delete') {
        await MemberApi.deleteAvatar();
      } else {
        // Resized on the phone: the backend accepts at most 2 MB.
        final file = await ImagePicker().pickImage(
          source: choice == 'camera' ? ImageSource.camera : ImageSource.gallery,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 85,
        );
        if (file == null) return;
        await MemberApi.uploadAvatar(file.path);
      }
      if (mounted) _snack('Foto profil diperbarui.');
    } on ApiException catch (e) {
      if (mounted) _snack(e.displayMessage);
    } finally {
      if (mounted) setState(() => _photoBusy = false);
    }
  }

  Future<void> _changePhone() async {
    final phone = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => const _NewPhoneSheet(),
    );
    if (phone == null || !mounted) return;
    final verified = await context.push<bool>(AppRoutes.otp, extra: phone);
    if (verified != true || !mounted) return;
    final changed = await askPin(
      context,
      title: 'Konfirmasi PIN',
      message: 'Masukkan PIN untuk mengganti nomor HP menjadi $phone.',
      actionLabel: 'Ganti Nomor',
      onPin: AuthApi.changePhone,
    );
    if (changed && mounted) _snack('Nomor HP berhasil diganti.');
  }

  @override
  Widget build(BuildContext context) => PhaseOneScaffold(
    title: 'Edit Profil',
    child: ValueListenableBuilder<DemoContact>(
      valueListenable: DemoSession.contact,
      builder: (context, contact, _) => Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: AppColors.primarySoft,
                    foregroundImage: contact.avatarUrl == null
                        ? null
                        : ResizeImage(
                            NetworkImage(contact.avatarUrl!),
                            width: 256,
                          ),
                    child: Text(
                      _name.text.isEmpty
                          ? 'RG'
                          : _name.text.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        fontSize: 28,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  if (_photoBusy) const CircularProgressIndicator(),
                ],
              ),
            ),
            Center(
              child: TextButton(
                onPressed: _photoBusy ? null : _photo,
                child: const Text('Ganti Foto'),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              maxLength: 80,
              decoration: const InputDecoration(
                labelText: 'Nama lengkap',
                counterText: '',
              ),
              validator: Validators.fullName,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email (opsional)'),
              validator: Validators.optionalEmail,
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _pickBirthDate,
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Tanggal lahir'),
                child: Text(
                  _birthDate == null
                      ? 'Belum diisi'
                      : DateFormat('d MMMM y', 'id').format(_birthDate!),
                ),
              ),
            ),
            const SizedBox(height: 24),
            PhaseOneCard(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Nomor HP',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          contact.phone,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _changePhone,
                    child: const Text('Ganti'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: AppColors.error)),
              const SizedBox(height: 16),
            ],
            PhaseOneButton(label: 'Simpan', loading: _saving, onPressed: _save),
          ],
        ),
      ),
    ),
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
