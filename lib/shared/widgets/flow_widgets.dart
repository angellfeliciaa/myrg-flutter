import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';

class FlowSection extends StatelessWidget {
  const FlowSection({required this.title, required this.children, super.key});
  final String title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.divider),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 14),
        ...children,
      ],
    ),
  );
}

class FlowInfo extends StatelessWidget {
  const FlowInfo(this.text, {this.warning = false, super.key});
  final String text;
  final bool warning;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: warning ? AppColors.dangerSoft : AppColors.secondarySoft,
      borderRadius: BorderRadius.circular(15),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          warning ? Icons.info_outline : Icons.check_circle_outline,
          size: 20,
          color: warning ? AppColors.error : AppColors.success,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 13, height: 1.5)),
        ),
      ],
    ),
  );
}

class FlowValue extends StatelessWidget {
  const FlowValue(this.label, this.value, {this.copyText, super.key});
  final String label;
  final String value;

  /// When set, tapping the row copies this text (e.g. the transaction number without "#").
  final String? copyText;

  @override
  Widget build(BuildContext context) {
    final valueText = Text(
      value,
      textAlign: TextAlign.end,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
    );
    final row = Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
                // Beside the label, where there is room: next to the value it would squeeze a
                // long number onto two lines.
                if (copyText != null) ...[
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.copy_rounded,
                    size: 15,
                    color: AppColors.primary,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: copyText == null
                ? valueText
                // A number to copy is never broken across lines: it shrinks a little instead
                // on a narrow phone.
                : FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: valueText,
                  ),
          ),
        ],
      ),
    );
    if (copyText == null) return row;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        Clipboard.setData(ClipboardData(text: copyText!));
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text('$label disalin.')));
      },
      child: row,
    );
  }
}
