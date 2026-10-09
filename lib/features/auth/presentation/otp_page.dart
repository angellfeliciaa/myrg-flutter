import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/backend_config.dart';
import '../data/auth_api.dart';

class OtpPage extends StatefulWidget {
  const OtpPage({required this.phoneNumber, super.key});

  final String phoneNumber;

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  static const _otpLength = 6;
  static const _resendDuration = 30;

  final _otpController = TextEditingController();
  final _otpFocusNode = FocusNode();

  Timer? _resendTimer;
  var _resendSeconds = BackendConfig.enabled ? 60 : _resendDuration;
  String? _errorText;
  var _busy = false;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_resendSeconds <= 1) {
        timer.cancel();
        setState(() => _resendSeconds = 0);
      } else {
        setState(() => _resendSeconds--);
      }
    });
  }

  Future<void> _resendOtp() async {
    if (BackendConfig.enabled) {
      try {
        final seconds = await AuthApi.sendOtp(widget.phoneNumber);
        if (!mounted) return;
        setState(() {
          _resendSeconds = seconds;
          _otpController.clear();
          _errorText = null;
        });
        _startResendTimer();
      } on ApiException catch (e) {
        if (mounted) setState(() => _errorText = e.message);
      }
      return;
    }
    setState(() {
      _resendSeconds = _resendDuration;
      _otpController.clear();
      _errorText = null;
    });
    _startResendTimer();
    _otpFocusNode.requestFocus();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'Simulasi kirim ulang • OTP demo: 123456. Tidak mengirim WhatsApp/email.',
          ),
        ),
      );
  }

  void _confirmOtp() {
    if (_otpController.text.length != _otpLength) {
      setState(() => _errorText = 'Masukkan 6 digit kode OTP');
      _otpFocusNode.requestFocus();
      HapticFeedback.mediumImpact();
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();
    if (BackendConfig.enabled) {
      _confirmWithBackend();
      return;
    }
    if (_otpController.text != '123456') {
      setState(
        () => _errorText = 'Kode OTP demo tidak sesuai. Gunakan 123456.',
      );
      return;
    }
    context.push(AppRoutes.createPin);
  }

  Future<void> _confirmWithBackend() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await AuthApi.verifyOtp(_otpController.text);
      if (!mounted) return;
      switch (AuthApi.purpose) {
        case OtpPurpose.register:
          context.push(AppRoutes.createPin);
        case OtpPurpose.newDevice:
          await AuthApi.loginWithOtp(); // this phone becomes the trusted device
          if (mounted) context.go(AppRoutes.home);
        case OtpPurpose.forgotPassword ||
            OtpPurpose.changePhone ||
            OtpPurpose.resetPin:
          context.pop(true); // the calling flow continues (new password / PIN)
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _errorText = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _goBack() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.register);
    }
  }

  String get _maskedPhone {
    final digits = widget.phoneNumber.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 3) return '+62••••••••890';
    return '+62••••••••${digits.substring(digits.length - 3)}';
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _otpController.dispose();
    _otpFocusNode.dispose();
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: _OtpBackButton(onPressed: _goBack),
                        ),
                        const SizedBox(height: 19),
                        const Text(
                          AppStrings.enterOtp,
                          style: TextStyle(
                            color: Color(0xFF242424),
                            fontSize: 24,
                            height: 32 / 24,
                            letterSpacing: -0.84,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text.rich(
                          TextSpan(
                            text: AppStrings.otpSentPrefix,
                            children: [
                              TextSpan(
                                text: _maskedPhone,
                                style: const TextStyle(
                                  color: AppColors.primaryDark,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const TextSpan(text: AppStrings.otpSentSuffix),
                            ],
                          ),
                          style: const TextStyle(
                            color: AppColors.mutedPurple,
                            fontSize: 14,
                            height: 22.75 / 14,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _OtpInput(
                          controller: _otpController,
                          focusNode: _otpFocusNode,
                          hasError: _errorText != null,
                          onChanged: (_) {
                            if (_errorText != null) {
                              setState(() => _errorText = null);
                            } else {
                              setState(() {});
                            }
                          },
                          onSubmitted: (_) => _confirmOtp(),
                        ),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 180),
                          child: _errorText == null
                              ? const SizedBox(height: 15)
                              : Padding(
                                  padding: const EdgeInsets.only(
                                    top: 6,
                                    bottom: 5,
                                  ),
                                  child: Text(
                                    _errorText!,
                                    style: const TextStyle(
                                      color: AppColors.error,
                                      fontSize: 11,
                                      height: 1.2,
                                    ),
                                  ),
                                ),
                        ),
                        _ResendOtp(
                          seconds: _resendSeconds,
                          onResend: _resendOtp,
                        ),
                        const Padding(
                          padding: EdgeInsets.only(top: 16),
                          child: Text(
                            'Pratinjau FE • Kode OTP demo: 123456',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Padding(
                          padding: const EdgeInsets.only(top: 32, bottom: 12),
                          child: AppButton(
                            label: AppStrings.confirm,
                            onPressed: _confirmOtp,
                          ),
                        ),
                      ],
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

class _OtpInput extends StatelessWidget {
  const _OtpInput({
    required this.controller,
    required this.focusNode,
    required this.hasError,
    required this.onChanged,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasError;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const gap = 12.0;
          final boxWidth = ((constraints.maxWidth - (gap * 5)) / 6).clamp(
            36.0,
            48.0,
          );
          final code = controller.text;

          return Stack(
            children: [
              IgnorePointer(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(6, (index) {
                    final isActive = focusNode.hasFocus && index == code.length;
                    final value = index < code.length ? code[index] : '';
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      width: boxWidth,
                      height: 56,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.fieldBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: hasError
                              ? AppColors.error
                              : isActive
                              ? AppColors.primary
                              : Colors.transparent,
                          width: isActive ? 1.2 : 1,
                        ),
                      ),
                      child: Text(
                        value,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }),
                ),
              ),
              Positioned.fill(
                child: Semantics(
                  label: 'Kode OTP 6 digit',
                  textField: true,
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    autofocus: false,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.oneTimeCode],
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    enableInteractiveSelection: false,
                    showCursor: false,
                    style: const TextStyle(color: Colors.transparent),
                    decoration: const InputDecoration(
                      filled: true,
                      fillColor: Colors.transparent,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: onChanged,
                    onSubmitted: onSubmitted,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ResendOtp extends StatelessWidget {
  const _ResendOtp({required this.seconds, required this.onResend});

  final int seconds;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    if (seconds > 0) {
      return Text.rich(
        TextSpan(
          text: '${AppStrings.otpNotReceived} ',
          children: [
            TextSpan(
              text: '($seconds)',
              style: const TextStyle(
                color: AppColors.secondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
          height: 1.5,
        ),
      );
    }

    return Row(
      children: [
        const Text(
          'Belum menerima kode?',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        TextButton(
          onPressed: onResend,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.secondary,
            padding: const EdgeInsets.only(left: 4),
            minimumSize: const Size(0, 24),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          child: const Text(AppStrings.resendOtp),
        ),
      ],
    );
  }
}

class _OtpBackButton extends StatelessWidget {
  const _OtpBackButton({required this.onPressed});

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
