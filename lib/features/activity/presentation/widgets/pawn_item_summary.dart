import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/phase_one_widgets.dart';
import '../../models/activity_transaction.dart';

class PawnItemSummary extends StatelessWidget {
  const PawnItemSummary({
    required this.transaction,
    required this.label,
    required this.amount,
    this.showAttention = false,
    super.key,
  });
  final ActivityTransaction transaction;
  final String label, amount;
  final bool showAttention;
  @override
  Widget build(BuildContext context) => PhaseOneCard(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 86,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primarySoft.withValues(alpha: .6),
            borderRadius: BorderRadius.circular(8),
          ),
          child: transaction.title.toLowerCase().contains('iphone 13')
              ? ClipRect(
                  child: SizedBox(
                    width: 46.1,
                    height: 81.8,
                    child: OverflowBox(
                      maxWidth: 91.9,
                      maxHeight: 91.9,
                      child: Image.asset(
                        'assets/images/valuation_iphone.png',
                        width: 91.9,
                        height: 91.9,
                        fit: BoxFit.fill,
                      ),
                    ),
                  ),
                )
              : const Icon(
                  Icons.inventory_2_outlined,
                  size: 30,
                  color: AppColors.primary,
                ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                transaction.title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (transaction.subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  transaction.subtitle!,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              if (showAttention && transaction.attentionLabel != null) ...[
                const SizedBox(height: 6),
                Text(
                  transaction.attentionLabel!,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFFFF3F47),
                  ),
                ),
              ],
              if (transaction.dueDate != null) ...[
                const SizedBox(height: 6),
                Text.rich(
                  TextSpan(
                    text: 'Jatuh Tempo   ',
                    children: [
                      TextSpan(
                        text: transaction.dueDate,
                        style: const TextStyle(color: Color(0xFFFF3F47)),
                      ),
                    ],
                  ),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(height: 1),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                amount,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
