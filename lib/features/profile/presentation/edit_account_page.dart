import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/phase_one_widgets.dart';
import '../../auth/data/demo_session.dart';
import '../../membership/data/member_repository.dart';
import '../data/profile_photo_picker.dart';
import 'widgets/profile_avatar.dart';

class EditAccountPage extends StatefulWidget {
  const EditAccountPage({this.photoPicker, super.key});
  final ProfilePhotoPicker? photoPicker;

  @override
  State<EditAccountPage> createState() => _EditAccountPageState();
}

class _EditAccountPageState extends State<EditAccountPage> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(
    text: MemberRepository.profile.value.name,
  );
  late final _phone = TextEditingController(
    text: DemoSession.contact.value.phone,
  );
  late final _email = TextEditingController(
    text: DemoSession.contact.value.email,
  );
  late final _picker = widget.photoPicker ?? GalleryProfilePhotoPicker();
  late final _fixturePhoto = DemoSession.contact.value.isFixture;
  Uint8List? _photo;
  String? _photoError;
  bool _picking = false, _saving = false;

  @override
  void initState() {
    super.initState();
    _photo = DemoSession.contact.value.avatarBytes;
    _recoverPhoto();
  }

  Future<void> _recoverPhoto() async {
    setState(() => _picking = true);
    try {
      final photo = await _picker.recover();
      if (mounted && photo != null) setState(() => _photo = photo);
    } catch (_) {
      if (mounted) {
        setState(
          () => _photoError =
              'Foto yang tertunda tidak bisa dibaca. Pilih ulang.',
        );
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _pickPhoto() async {
    if (_picking || _saving) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _picking = true;
      _photoError = null;
    });
    try {
      final photo = await _picker.pick();
      if (mounted && photo != null) setState(() => _photo = photo);
    } on FormatException catch (error) {
      if (mounted) setState(() => _photoError = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _photoError =
              'Galeri belum dapat dibuka. Periksa izin foto lalu coba lagi.',
        );
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  String? _validatePhone(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) return 'Nomor telepon wajib diisi';
    if (!RegExp(r'^\+?[0-9\s()-]+$').hasMatch(input)) {
      return 'Gunakan nomor Indonesia yang valid';
    }
    final digits = input.replaceAll(RegExp(r'\D'), '');
    final local = digits.startsWith('62') ? '0${digits.substring(2)}' : digits;
    return Validators.indonesianPhone(local);
  }

  Future<void> _save() async {
    if (_saving || _picking || !_form.currentState!.validate()) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _saving = true);
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    MemberRepository.updateDemoName(_name.text.trim());
    DemoSession.updateProfile(
      email: _email.text.trim(),
      phone: _phone.text.trim(),
      avatarBytes: _photo,
    );
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    messenger.showSnackBar(
      const SnackBar(
        content: Text(
          'Profil demo disimpan untuk sesi ini. Akun RG asli tidak diubah.',
        ),
      ),
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  Widget _field(
    String label,
    TextEditingController controller,
    String? Function(String?) validator,
    TextInputType keyboard, {
    bool email = false,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          height: 1.5,
          color: Color(0xFF242424),
        ),
      ),
      const SizedBox(height: 8),
      Semantics(
        label: label,
        child: TextFormField(
          key: ValueKey('edit-profile-$label'),
          controller: controller,
          enabled: !_saving,
          validator: validator,
          keyboardType: keyboard,
          textCapitalization: label == 'Nama Lengkap'
              ? TextCapitalization.words
              : TextCapitalization.none,
          textInputAction: email ? TextInputAction.done : TextInputAction.next,
          onFieldSubmitted: email ? (_) => _save() : null,
          onChanged: label == 'Nama Lengkap' ? (_) => setState(() {}) : null,
          style: TextStyle(
            fontSize: email ? 14 : 12,
            height: email ? 20 / 14 : 20 / 12,
            color: email ? AppColors.textSecondary : const Color(0x801A1A2E),
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.fieldBackground,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.2,
              ),
            ),
            errorMaxLines: 2,
          ),
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) => PhaseOneScaffold(
    title: 'Edit Akun',
    headerPadding: const EdgeInsets.fromLTRB(20, 26, 24, 0),
    headerTitleSpacing: 20,
    backButtonPadding: const EdgeInsets.all(4),
    footerPadding: const EdgeInsets.fromLTRB(24, 12, 24, 14),
    footer: PhaseOneButton(
      label: 'Simpan',
      loading: _saving,
      onPressed: _picking ? null : _save,
    ),
    child: SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 32),
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Column(
                children: [
                  ProfileAvatar(
                    name: _name.text,
                    isFixture: _fixturePhoto,
                    bytes: _photo,
                    size: 112,
                  ),
                  Semantics(
                    button: true,
                    label: 'Ganti Foto',
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _picking || _saving ? null : _pickPhoto,
                      child: Container(
                        width: 112,
                        height: 48,
                        alignment: Alignment.topCenter,
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Ganti Foto',
                          style: TextStyle(
                            fontSize: 14,
                            height: 17 / 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_picking)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  if (_photoError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _photoError!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 9),
            _field(
              'Nama Lengkap',
              _name,
              Validators.fullName,
              TextInputType.name,
            ),
            const SizedBox(height: 24),
            _field(
              'Nomor Telepon',
              _phone,
              _validatePhone,
              TextInputType.phone,
            ),
            const SizedBox(height: 24),
            _field(
              'Email',
              _email,
              Validators.optionalEmail,
              TextInputType.emailAddress,
              email: true,
            ),
          ],
        ),
      ),
    ),
  );
}
