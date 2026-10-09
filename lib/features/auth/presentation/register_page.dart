import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../core/network/rg_integration.dart';
import '../data/registration_repository.dart';
import '../../membership/data/member_repository.dart';
import '../data/demo_session.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/backend_config.dart';
import '../data/auth_api.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({this.repository, super.key});
  final RegistrationRepository? repository;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _referralController = TextEditingController();
  // Mentor's decision: the sign-up form has a password (login = email/phone + password, then PIN).
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();

  final _phoneFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _referralFocusNode = FocusNode();

  DateTime? _selectedBirthDate;
  var _hasSubmitted = false;
  var _isSubmitting = false;
  String? _submitError;
  late final _repository = widget.repository ?? RegistrationRepository.create();

  Future<void> _pickBirthDate() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final today = DateUtils.dateOnly(DateTime.now());
    final initialDate =
        _selectedBirthDate ?? DateTime(today.year - 21, today.month, today.day);

    final selectedDate = await showDatePicker(
      context: context,
      locale: const Locale('id', 'ID'),
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: today,
      helpText: 'Pilih tanggal lahir',
      cancelText: 'Batal',
      confirmText: 'Pilih',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate == null || !mounted) return;
    setState(() {
      _selectedBirthDate = selectedDate;
      _birthDateController.text = DateFormat('dd/MM/yyyy').format(selectedDate);
    });
    _formKey.currentState?.validate();
    _phoneFocusNode.requestFocus();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    setState(() => _hasSubmitted = true);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });
    if (BackendConfig.enabled) {
      await _submitToBackend();
      return;
    }
    try {
      final outcome = await _repository.validateAndRegister(
        RegistrationRequest(
          name: _fullNameController.text.trim(),
          phone: _phoneController.text.trim(),
          email: _emailController.text.trim(),
          birthDate: _selectedBirthDate!,
          referral: _referralController.text.trim(),
        ),
      );
      if (!mounted) return;
      if (outcome == RegistrationOutcome.memberConflict) {
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            icon: const Icon(
              Icons.person_search_rounded,
              color: AppColors.primary,
              size: 32,
            ),
            title: const Text('Nomor member sudah digunakan'),
            content: const Text(
              'Untuk melindungi data kamu, registrasi belum dapat dilanjutkan. Silakan datang ke cabang Raja Gadai agar petugas dapat memeriksa dan memperbaiki data member.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Mengerti'),
              ),
            ],
          ),
        );
        return;
      }
      if (outcome == RegistrationOutcome.syncMember) {
        final proceed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Member kamu ditemukan'),
            content: const Text(
              'Data member Raja Gadai akan disinkronkan dengan akun aplikasi ini. Verifikasi nomor telepon untuk melanjutkan.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Lanjut verifikasi'),
              ),
            ],
          ),
        );
        if (proceed != true || !mounted) return;
      }
      MemberRepository.resetForRegistration(_fullNameController.text.trim());
      DemoSession.reset();
      DemoSession.setContact(
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
      );
      context.push(AppRoutes.otp, extra: _phoneController.text.trim());
    } catch (_) {
      if (mounted) {
        setState(
          () => _submitError =
              'Data belum berhasil diperiksa. Coba lagi atau hubungi cabang jika masalah berlanjut.',
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  /// Backend: store the form and send the OTP. Whether the phone is an existing Raja Gadai member
  /// is answered after the OTP + PIN (pin/create), so nobody can look up members by phone number.
  Future<void> _submitToBackend() async {
    final phone = _phoneController.text.trim();
    try {
      await AuthApi.register(
        name: _fullNameController.text.trim(),
        birthDate: _selectedBirthDate!,
        phone: phone,
        password: _passwordController.text,
        email: _emailController.text.trim(),
        referral: _referralController.text.trim(),
      );
      if (!mounted) return;
      DemoSession.setContact(email: _emailController.text.trim(), phone: phone);
      context.push(AppRoutes.otp, extra: phone);
    } on ApiException catch (e) {
      if (mounted) setState(() => _submitError = e.displayMessage);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _goToLogin() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.login);
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _birthDateController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _referralController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    _phoneFocusNode.dispose();
    _emailFocusNode.dispose();
    _referralFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: AutofillGroup(
                      child: Form(
                        key: _formKey,
                        autovalidateMode: _hasSubmitted
                            ? AutovalidateMode.onUserInteraction
                            : AutovalidateMode.disabled,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: _RegisterBackButton(onPressed: _goToLogin),
                            ),
                            const SizedBox(height: 19),
                            Text(
                              AppStrings.createAccount,
                              style: const TextStyle(
                                color: Color(0xFF242424),
                                fontSize: 24,
                                height: 32 / 24,
                                letterSpacing: -0.84,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              AppStrings.createAccountDescription,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                                height: 21 / 14,
                              ),
                            ),
                            const SizedBox(height: 20),
                            _RegisterField(
                              label: AppStrings.fullName,
                              hintText: AppStrings.fullNameHint,
                              controller: _fullNameController,
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.name],
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(80),
                              ],
                              validator: Validators.fullName,
                              onFieldSubmitted: (_) => _pickBirthDate(),
                            ),
                            const SizedBox(height: 18),
                            _RegisterField(
                              label: AppStrings.birthDate,
                              hintText: AppStrings.birthDateHint,
                              controller: _birthDateController,
                              readOnly: true,
                              showCursor: false,
                              onTap: _pickBirthDate,
                              validator: (value) => Validators.required(
                                value,
                                fieldName: 'Tanggal lahir',
                              ),
                              suffix: Padding(
                                padding: const EdgeInsets.only(right: 16),
                                child: Image.asset(
                                  AppAssets.registerCalendarIcon,
                                  width: 20,
                                  height: 20,
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            _RegisterField(
                              label: AppStrings.phoneNumber,
                              hintText: AppStrings.phoneNumberHint,
                              controller: _phoneController,
                              focusNode: _phoneFocusNode,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [
                                AutofillHints.telephoneNumber,
                              ],
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(13),
                              ],
                              validator: Validators.indonesianPhone,
                              onFieldSubmitted: (_) =>
                                  _emailFocusNode.requestFocus(),
                            ),
                            const SizedBox(height: 18),
                            _RegisterField(
                              label: AppStrings.optionalEmail,
                              optional: true,
                              hintText: AppStrings.emailHint,
                              controller: _emailController,
                              focusNode: _emailFocusNode,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.email],
                              validator: Validators.optionalEmail,
                              onFieldSubmitted: (_) =>
                                  _referralFocusNode.requestFocus(),
                            ),
                            const SizedBox(height: 18),
                            _RegisterField(
                              label: 'Password',
                              hintText: 'Minimal 8 karakter, huruf dan angka',
                              controller: _passwordController,
                              obscureText: true,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.newPassword],
                              validator: (value) {
                                final base = Validators.password(value);
                                if (base != null) return base;
                                final hasLetter = RegExp(
                                  r'[A-Za-z]',
                                ).hasMatch(value!);
                                final hasDigit = RegExp(r'\d').hasMatch(value);
                                return hasLetter && hasDigit
                                    ? null
                                    : 'Password harus berisi huruf dan angka';
                              },
                            ),
                            const SizedBox(height: 18),
                            _RegisterField(
                              label: 'Konfirmasi Password',
                              hintText: 'Ulangi password',
                              controller: _passwordConfirmController,
                              obscureText: true,
                              textInputAction: TextInputAction.next,
                              validator: (value) =>
                                  value == _passwordController.text
                                  ? null
                                  : 'Password tidak sama',
                            ),
                            const SizedBox(height: 18),
                            _RegisterField(
                              label: AppStrings.referralCode,
                              optional: true,
                              hintText: AppStrings.referralCodeHint,
                              controller: _referralController,
                              focusNode: _referralFocusNode,
                              textCapitalization: TextCapitalization.characters,
                              textInputAction: TextInputAction.done,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp('[a-zA-Z0-9]'),
                                ),
                                LengthLimitingTextInputFormatter(20),
                              ],
                              onFieldSubmitted: (_) => _submit(),
                            ),
                            const SizedBox(height: 48),
                            if (RgIntegration.preview)
                              const Padding(
                                padding: EdgeInsets.only(bottom: 12),
                                child: Text(
                                  'Pratinjau registrasi • Data belum didaftarkan ke RG',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            if (_submitError != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Text(
                                  _submitError!,
                                  style: const TextStyle(
                                    color: AppColors.error,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            AppButton(
                              label: AppStrings.register,
                              onPressed: _submit,
                              isLoading: _isSubmitting,
                            ),
                            const SizedBox(height: 30),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Wrap(
                                alignment: WrapAlignment.center,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  const Text(
                                    AppStrings.alreadyHaveAccount,
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13,
                                      height: 1.5,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: _goToLogin,
                                    style: TextButton.styleFrom(
                                      foregroundColor: AppColors.primaryDark,
                                      minimumSize: const Size(0, 20),
                                      padding: const EdgeInsets.only(left: 3),
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      textStyle: const TextStyle(
                                        fontSize: 13,
                                        height: 1.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    child: const Text(AppStrings.loginNow),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _RegisterBackButton extends StatelessWidget {
  const _RegisterBackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primaryDark.withValues(alpha: 0.06),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox.square(
          dimension: 40,
          child: Center(
            child: Image.asset(AppAssets.loginBackIcon, width: 20, height: 20),
          ),
        ),
      ),
    );
  }
}

class _RegisterField extends StatelessWidget {
  const _RegisterField({
    required this.label,
    required this.hintText,
    required this.controller,
    this.optional = false,
    this.focusNode,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.autofillHints,
    this.inputFormatters,
    this.validator,
    this.readOnly = false,
    this.showCursor,
    this.suffix,
    this.onTap,
    this.onFieldSubmitted,
    this.obscureText = false,
  });

  final bool obscureText;
  final String label;
  final String hintText;
  final TextEditingController controller;
  final bool optional;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final FormFieldValidator<String>? validator;
  final bool readOnly;
  final bool? showCursor;
  final Widget? suffix;
  final VoidCallback? onTap;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: label,
            children: optional
                ? const [
                    TextSpan(
                      text: ' ${AppStrings.optional}',
                      style: TextStyle(fontWeight: FontWeight.w400),
                    ),
                  ]
                : null,
          ),
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 14,
            height: 21 / 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          obscureText: obscureText,
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          textCapitalization: textCapitalization,
          autofillHints: autofillHints,
          inputFormatters: inputFormatters,
          validator: validator,
          readOnly: readOnly,
          showCursor: showCursor,
          onTap: onTap,
          onFieldSubmitted: onFieldSubmitted,
          autocorrect: false,
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 13,
            height: 1.4,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              color: AppColors.ink.withValues(alpha: 0.5),
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
            filled: true,
            fillColor: AppColors.fieldBackground,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            suffixIcon: suffix,
            suffixIconConstraints: const BoxConstraints(
              minWidth: 52,
              minHeight: 48,
            ),
            border: _border,
            enabledBorder: _border,
            focusedBorder: _border.copyWith(
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.2,
              ),
            ),
            errorBorder: _border.copyWith(
              borderSide: const BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: _border.copyWith(
              borderSide: const BorderSide(color: AppColors.error, width: 1.2),
            ),
            errorStyle: const TextStyle(fontSize: 11, height: 1.2),
          ),
        ),
      ],
    );
  }

  static const _border = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(12)),
    borderSide: BorderSide.none,
  );
}
