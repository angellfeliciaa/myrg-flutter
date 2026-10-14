import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/app_button.dart';
import '../data/demo_session.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/backend_config.dart';
import '../data/auth_api.dart';
import 'forgot_password.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _identityController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocusNode = FocusNode();

  var _obscurePassword = true;
  var _hasSubmitted = false;
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    if (_loading) return;
    setState(() => _hasSubmitted = true);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });
    if (BackendConfig.enabled) {
      await _loginWithBackend();
      return;
    }
    final valid = await DemoSession.login(_passwordController.text);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (!valid) _error = 'Password akun demo tidak sesuai.';
    });
    if (!valid) return;
    context.push(AppRoutes.pin);
  }

  Future<void> _loginWithBackend() async {
    final identifier = _identityController.text.trim();
    try {
      await AuthApi.login(identifier, _passwordController.text);
      if (mounted) context.push(AppRoutes.pin);
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.code == 'DEVICE_VERIFICATION_REQUIRED') {
        if (identifier.contains('@')) {
          setState(
            () => _error =
                'Perangkat baru: masuk dengan nomor HP agar kode OTP bisa dikirim.',
          );
          return;
        }
        try {
          AuthApi.purpose = OtpPurpose.newDevice;
          await AuthApi.sendOtp(identifier);
          if (mounted) context.push(AppRoutes.otp, extra: identifier);
        } on ApiException catch (otpError) {
          if (mounted) setState(() => _error = otpError.message);
        }
        return;
      }
      setState(() => _error = e.displayMessage);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.onboarding);
    }
  }

  Future<void> _social(String provider) async {
    if (_loading) return;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Demo login $provider'),
        content: const Text(
          'Simulasi FE saja. Tidak membuka OAuth, mengambil data, atau masuk ke akun Google/Apple asli.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Simulasi Gagal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Lanjut Demo'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (result == true) context.push(AppRoutes.pin);
    if (result == false) {
      setState(
        () => _error =
            'Login $provider dibatalkan dalam simulasi. Silakan coba lagi.',
      );
    }
  }

  Future<void> _forgot() async {
    if (!BackendConfig.enabled) return _forgotDemo();
    final identity = _identityController.text.trim();
    final phone = await runForgotPassword(
      context,
      initialPhone: identity.contains('@') ? '' : identity,
    );
    if (phone == null || !mounted) return;
    _identityController.text = phone;
    _passwordController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password baru disimpan. Silakan masuk.')),
    );
  }

  void _forgotDemo() => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Lupa Password'),
      content: const Text(
        'Pemulihan akun asli belum dijalankan dalam demo FE. Password demo awal: password123. Ganti password tersedia melalui Akun → Keamanan Akun.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Mengerti'),
        ),
      ],
    ),
  );

  @override
  void dispose() {
    _identityController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
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
                              child: _BackButton(onPressed: _goBack),
                            ),
                            const SizedBox(height: 19),
                            Text(
                              AppStrings.welcomeBack,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    color: const Color(0xFF242424),
                                    fontSize: 24,
                                    height: 42 / 24,
                                    letterSpacing: -0.84,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 16),
                            _LoginTextField(
                              controller: _identityController,
                              hintText: AppStrings.emailOrPhone,
                              iconAsset: AppAssets.loginEmailIcon,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [
                                AutofillHints.username,
                                AutofillHints.email,
                                AutofillHints.telephoneNumber,
                              ],
                              validator: Validators.emailOrPhone,
                              onFieldSubmitted: (_) {
                                _passwordFocusNode.requestFocus();
                              },
                            ),
                            const SizedBox(height: 16),
                            _LoginTextField(
                              controller: _passwordController,
                              focusNode: _passwordFocusNode,
                              hintText: AppStrings.password,
                              iconAsset: AppAssets.loginLockIcon,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              autofillHints: const [AutofillHints.password],
                              validator: Validators.password,
                              onFieldSubmitted: (_) => _submit(),
                              suffix: IconButton(
                                tooltip: _obscurePassword
                                    ? 'Tampilkan password'
                                    : 'Sembunyikan password',
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                                icon: Image.asset(
                                  AppAssets.loginEyeIcon,
                                  width: 18,
                                  height: 18,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _forgot,
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.textSecondary
                                      .withValues(alpha: 0.8),
                                  minimumSize: const Size(0, 20),
                                  padding: EdgeInsets.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  textStyle: const TextStyle(
                                    fontSize: 13,
                                    height: 1.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                child: const Text(AppStrings.forgotPassword),
                              ),
                            ),
                            const SizedBox(height: 24),
                            AppButton(
                              label: AppStrings.login,
                              onPressed: _submit,
                              isLoading: _loading,
                            ),
                            if (_error != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  _error!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.error,
                                  ),
                                ),
                              ),
                            // Demo credentials are only true in demo mode.
                            if (!BackendConfig.enabled)
                              const Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: Text(
                                  'Demo FE • Password awal: password123 • PIN awal: 123456',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 24),
                            const _DividerWithLabel(),
                            const SizedBox(height: 24),
                            _SocialLoginButton(
                              label: AppStrings.continueWithGoogle,
                              iconAsset: AppAssets.loginGoogleIcon,
                              backgroundColor: AppColors.fieldBackground,
                              foregroundColor: AppColors.ink,
                              onPressed: () => _social('Google'),
                            ),
                            const SizedBox(height: 16),
                            _SocialLoginButton(
                              label: AppStrings.continueWithApple,
                              iconAsset: AppAssets.loginAppleIcon,
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              onPressed: () => _social('Apple'),
                            ),
                            const Spacer(),
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 32,
                                bottom: 29,
                              ),
                              child: Wrap(
                                alignment: WrapAlignment.center,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  const Text(
                                    AppStrings.noAccount,
                                    style: TextStyle(
                                      color: AppColors.mutedPurple,
                                      fontSize: 13,
                                      height: 1.5,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        context.push(AppRoutes.register),
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
                                    child: const Text(AppStrings.registerNow),
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

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onPressed});

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

class _LoginTextField extends StatelessWidget {
  const _LoginTextField({
    required this.controller,
    required this.hintText,
    required this.iconAsset,
    required this.textInputAction,
    required this.validator,
    this.focusNode,
    this.keyboardType,
    this.autofillHints,
    this.obscureText = false,
    this.suffix,
    this.onFieldSubmitted,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hintText;
  final String iconAsset;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final Iterable<String>? autofillHints;
  final bool obscureText;
  final Widget? suffix;
  final FormFieldValidator<String> validator;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      obscureText: obscureText,
      autocorrect: false,
      enableSuggestions: !obscureText,
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
      style: const TextStyle(color: AppColors.ink, fontSize: 13, height: 1.4),
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
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 16, right: 12),
          child: Image.asset(iconAsset, width: 18, height: 18),
        ),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 46,
          minHeight: 48,
        ),
        suffixIcon: suffix,
        suffixIconConstraints: const BoxConstraints(
          minWidth: 50,
          minHeight: 48,
        ),
        border: _border,
        enabledBorder: _border,
        focusedBorder: _border.copyWith(
          borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
        ),
        errorBorder: _border.copyWith(
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: _border.copyWith(
          borderSide: const BorderSide(color: AppColors.error, width: 1.2),
        ),
        errorStyle: const TextStyle(fontSize: 11, height: 1.2),
      ),
    );
  }

  static const _border = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(12)),
    borderSide: BorderSide.none,
  );
}

class _DividerWithLabel extends StatelessWidget {
  const _DividerWithLabel();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: Divider(height: 1, color: Color(0x99666666))),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            AppStrings.or,
            style: TextStyle(color: Color(0x99666666), fontSize: 13),
          ),
        ),
        Expanded(child: Divider(height: 1, color: Color(0x99666666))),
      ],
    );
  }
}

class _SocialLoginButton extends StatelessWidget {
  const _SocialLoginButton({
    required this.label,
    required this.iconAsset,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onPressed,
  });

  final String label;
  final String iconAsset;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(iconAsset, width: 20, height: 20),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: foregroundColor,
                    fontSize: 15,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
