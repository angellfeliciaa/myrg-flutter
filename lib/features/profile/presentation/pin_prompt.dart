import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_exception.dart';
import '../../../shared/widgets/app_button.dart';

/// Asks for the 6-digit PIN and runs [onPin] with it. A wrong PIN (or any backend error) is
/// shown in the sheet so the member can try again. Returns true once [onPin] succeeded.
Future<bool> askPin(
  BuildContext context, {
  required String title,
  required String message,
  required String actionLabel,
  required Future<void> Function(String pin) onPin,
  bool destructive = false,
}) async =>
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _PinSheet(
        title: title,
        message: message,
        actionLabel: actionLabel,
        onPin: onPin,
        destructive: destructive,
      ),
    ) ==
    true;

class _PinSheet extends StatefulWidget {
  const _PinSheet({
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onPin,
    required this.destructive,
  });
  final String title, message, actionLabel;
  final Future<void> Function(String pin) onPin;
  final bool destructive;
  @override
  State<_PinSheet> createState() => _PinSheetState();
}

class _PinSheetState extends State<_PinSheet> {
  final _pin = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _pin.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;
    if (_pin.text.length != 6) {
      setState(() => _error = 'Masukkan 6 digit PIN');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.onPin(_pin.text);
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _error = e.displayMessage);
        _pin.clear();
      }
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
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(widget.message, style: const TextStyle(fontSize: 14, height: 1.5)),
        const SizedBox(height: 20),
        TextField(
          controller: _pin,
          autofocus: true,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 6,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(labelText: 'PIN', counterText: ''),
          onSubmitted: (_) => _submit(),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: const TextStyle(color: AppColors.error)),
        ],
        const SizedBox(height: 20),
        if (widget.destructive)
          FilledButton(
            onPressed: _loading ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              minimumSize: const Size.fromHeight(52),
              shape: const StadiumBorder(),
            ),
            child: _loading
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(widget.actionLabel),
          )
        else
          AppButton(
            label: widget.actionLabel,
            isLoading: _loading,
            onPressed: _submit,
          ),
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context, false),
          child: const Text('Batal'),
        ),
      ],
    ),
  );
}
