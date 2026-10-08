import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_colors.dart';

class HomeTransactionCard extends StatelessWidget {
  const HomeTransactionCard({
    required this.dueLabel,
    required this.productName,
    required this.dueDate,
    required this.amount,
    required this.onManage,
    this.productIcon,
    super.key,
  });
  final String dueLabel;
  final String productName;
  final String dueDate;
  final String amount;
  final VoidCallback onManage;
  final IconData? productIcon;

  @override
  Widget build(BuildContext context) {
    final parts = productName.split('|').map((part) => part.trim()).toList();
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        margin: const EdgeInsets.only(right: 12, bottom: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE8E5EA), width: .8),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D2B153A),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(17),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 28),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFECEE),
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFF6DADD), width: .8),
                  ),
                ),
                child: _DueBannerText(label: dueLabel),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: productIcon == null
                              ? Image.asset(
                                  AppAssets.homeTransactionPhone,
                                  fit: BoxFit.contain,
                                )
                              : Icon(
                                  productIcon,
                                  color: AppColors.primary,
                                  size: 24,
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                parts.first,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                  height: 1.2,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (parts.length > 1) ...[
                                const SizedBox(height: 3),
                                Text(
                                  parts.skip(1).join(' • '),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                    height: 1.2,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.event_outlined,
                                    size: 13,
                                    color: Color(0xFFE5484D),
                                  ),
                                  const SizedBox(width: 5),
                                  Flexible(
                                    child: Text(
                                      dueDate,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      semanticsLabel: 'Jatuh tempo $dueDate',
                                      style: const TextStyle(
                                        color: Color(0xFFE5484D),
                                        fontSize: 12,
                                        height: 1.2,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: AppColors.divider,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Nominal Pembayaran',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                amount,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 17,
                                  height: 1.2,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 82,
                          height: 44,
                          child: FilledButton(
                            onPressed: onManage,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(82, 44),
                              elevation: 0,
                              shape: const StadiumBorder(),
                              textStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            child: const Text('Kelola'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DueBannerText extends StatelessWidget {
  const _DueBannerText({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) {
    final match = RegExp(r'\d+\s+hari', caseSensitive: false).firstMatch(label);
    return Text.rich(
      TextSpan(
        style: const TextStyle(
          color: Color(0xFFE5484D),
          fontSize: 12,
          height: 1.2,
          fontWeight: FontWeight.w500,
        ),
        children: match == null
            ? [TextSpan(text: label)]
            : [
                TextSpan(text: label.substring(0, match.start)),
                TextSpan(
                  text: match.group(0),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(text: label.substring(match.end)),
              ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      semanticsLabel: label,
    );
  }
}
