import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_colors.dart';

typedef PinCompleted = Future<String?> Function(String pin);

class PinPadScreen extends StatefulWidget {
  const PinPadScreen({
    required this.title,
    required this.description,
    required this.onCompleted,
    required this.onBack,
    this.dark = false,
    this.hint,
    super.key,
  });

  final String title;
  final String description;
  final PinCompleted onCompleted;
  final VoidCallback onBack;
  final bool dark;
  final String? hint;

  @override
  State<PinPadScreen> createState() => _PinPadScreenState();
}

class _PinPadScreenState extends State<PinPadScreen> {
  static const _pinLength = 6;

  var _pin = '';
  var _isProcessing = false;
  String? _errorText;

  Future<void> _addDigit(String digit) async {
    if (_isProcessing || _pin.length >= _pinLength) return;
    HapticFeedback.selectionClick();

    final nextPin = '$_pin$digit';
    setState(() {
      _pin = nextPin;
      _errorText = null;
    });

    if (nextPin.length != _pinLength) return;
    setState(() => _isProcessing = true);
    final error = await widget.onCompleted(nextPin);
    if (!mounted) return;
    setState(() {
      _pin = '';
      _isProcessing = false;
      _errorText = error;
    });
    if (error != null) HapticFeedback.heavyImpact();
  }

  void _removeDigit() {
    if (_isProcessing || _pin.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
      _errorText = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: widget.dark
            ? Brightness.light
            : Brightness.dark,
        statusBarBrightness: widget.dark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: widget.dark
            ? AppColors.primary
            : Colors.white,
        systemNavigationBarIconBrightness: widget.dark
            ? Brightness.light
            : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: widget.dark ? AppColors.primary : Colors.white,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(height: widget.dark ? 88 : 64),
                            Text(
                              widget.title,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: widget.dark
                                    ? Colors.white
                                    : const Color(0xFF242424),
                                fontSize: 24,
                                height: 33 / 24,
                                letterSpacing: -0.44,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.description,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: widget.dark
                                    ? Colors.white
                                    : AppColors.textSecondary,
                                fontSize: 14,
                                height: 19.5 / 14,
                              ),
                            ),
                            const SizedBox(height: 56),
                            _PinIndicators(
                              enteredDigits: _pin.length,
                              hasError: _errorText != null,
                              dark: widget.dark,
                            ),
                            SizedBox(
                              height: 80,
                              child: Center(
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 180),
                                  child: _errorText == null
                                      ? const SizedBox.shrink()
                                      : Text(
                                          _errorText!,
                                          key: ValueKey(_errorText),
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: widget.dark
                                                ? Colors.white
                                                : AppColors.error,
                                            fontSize: 12,
                                            height: 1.4,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                            IgnorePointer(
                              ignoring: _isProcessing,
                              child: AnimatedOpacity(
                                opacity: _isProcessing ? 0.7 : 1,
                                duration: const Duration(milliseconds: 120),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: SizedBox(
                                    width: 288,
                                    child: _NumberPad(
                                      onDigitPressed: _addDigit,
                                      onDeletePressed: _removeDigit,
                                      dark: widget.dark,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            if (widget.hint != null)
                              Text(
                                widget.hint!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: widget.dark
                                      ? Colors.white70
                                      : AppColors.textSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Positioned(
                        left: 24,
                        top: 12,
                        child: _PinBackButton(onPressed: widget.onBack),
                      ),
                    ],
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

class _PinIndicators extends StatelessWidget {
  const _PinIndicators({
    required this.enteredDigits,
    required this.hasError,
    this.dark = false,
  });

  final int enteredDigits;
  final bool hasError;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (index) {
        final isEntered = index < enteredDigits;
        return Padding(
          padding: EdgeInsets.only(right: index == 5 ? 0 : 16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 13,
            height: 13,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isEntered
                  ? (dark ? Colors.white : AppColors.primary)
                  : Colors.transparent,
              border: Border.all(
                color: dark
                    ? Colors.white
                    : hasError
                    ? AppColors.error
                    : AppColors.primary,
                width: 2.5,
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _NumberPad extends StatelessWidget {
  const _NumberPad({
    required this.onDigitPressed,
    required this.onDeletePressed,
    this.dark = false,
  });

  final ValueChanged<String> onDigitPressed;
  final VoidCallback onDeletePressed;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _NumberRow(
          digits: const ['1', '2', '3'],
          onDigitPressed: onDigitPressed,
          dark: dark,
        ),
        const SizedBox(height: 32),
        _NumberRow(
          digits: const ['4', '5', '6'],
          onDigitPressed: onDigitPressed,
          dark: dark,
        ),
        const SizedBox(height: 32),
        _NumberRow(
          digits: const ['7', '8', '9'],
          onDigitPressed: onDigitPressed,
          dark: dark,
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox.square(dimension: 80),
            const SizedBox(width: 24),
            _NumberButton(digit: '0', onPressed: onDigitPressed, dark: dark),
            const SizedBox(width: 24),
            Semantics(
              button: true,
              label: 'Hapus digit terakhir',
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onDeletePressed,
                child: ClipOval(child: Image.asset(
                  dark
                      ? 'assets/icons/pin_enter_delete.png'
                      : AppAssets.pinDeleteButton,
                  width: 80,
                  height: 80,
                )),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _NumberRow extends StatelessWidget {
  const _NumberRow({
    required this.digits,
    required this.onDigitPressed,
    this.dark = false,
  });

  final List<String> digits;
  final bool dark;
  final ValueChanged<String> onDigitPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var index = 0; index < digits.length; index++) ...[
          if (index > 0) const SizedBox(width: 24),
          _NumberButton(
            digit: digits[index],
            onPressed: onDigitPressed,
            dark: dark,
          ),
        ],
      ],
    );
  }
}

class _NumberButton extends StatelessWidget {
  const _NumberButton({
    required this.digit,
    required this.onPressed,
    this.dark = false,
  });

  final String digit;
  final bool dark;
  final ValueChanged<String> onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Angka $digit',
      child: SizedBox.square(
        dimension: 80,
        child: Material(
          color: dark ? Colors.white : AppColors.primary,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => onPressed(digit),
            child: Center(
              child: Text(
                digit,
                style: TextStyle(
                  color: dark ? AppColors.primary : Colors.white,
                  fontSize: 28,
                  height: 1,
                  letterSpacing: -0.28,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PinBackButton extends StatelessWidget {
  const _PinBackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.fieldBackground,
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
