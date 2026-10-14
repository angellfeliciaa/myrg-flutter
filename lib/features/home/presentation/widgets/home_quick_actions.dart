import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_colors.dart';

class HomeQuickActions extends StatelessWidget {
  const HomeQuickActions({required this.onActionTap, super.key});

  final ValueChanged<String> onActionTap;

  static const _actions = [
    _QuickAction('Gadai', AppAssets.homeServicePawn, AppColors.primarySoft),
    _QuickAction(
      'Cek Pinjaman',
      AppAssets.homeServiceCalculator,
      AppColors.secondarySoft,
    ),
    _QuickAction(
      'Cabang',
      AppAssets.homeServiceBranch,
      AppColors.secondarySoft,
    ),
    _QuickAction(
      'Referal',
      AppAssets.homeServiceReferral,
      AppColors.primarySoft,
    ),
    _QuickAction(
      'Member',
      AppAssets.homeServiceMember,
      AppColors.secondarySoft,
    ),
    _QuickAction('Redeem', AppAssets.homeServiceRedeem, AppColors.primarySoft),
    _QuickAction(
      'Aktivitas',
      AppAssets.homeNavActivity,
      AppColors.secondarySoft,
      tint: AppColors.primary,
    ),
    _QuickAction('Lainnya', AppAssets.homeServiceMore, AppColors.primarySoft),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFEDEAEF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A2C183A),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mau ngapain hari ini?',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        height: 1.2,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.25,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Semua kebutuhan gadaimu, satu tap aja.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              _NewChip(),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _actions.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 12,
              childAspectRatio: 0.8, // room for a two-line label under the icon
            ),
            itemBuilder: (context, index) {
              final action = _actions[index];
              return Semantics(
                button: true,
                label: action.label,
                child: InkWell(
                  borderRadius: BorderRadius.circular(15),
                  onTap: () => onActionTap(action.label),
                  child: Column(
                    // Icons line up along the top; a two-line label ("Cek Pinjaman")
                    // grows downwards instead of pushing its icon up.
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: action.background,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: action.tint == null
                            ? Image.asset(action.asset, fit: BoxFit.contain)
                            : ColorFiltered(
                                colorFilter: ColorFilter.mode(
                                  action.tint!,
                                  BlendMode.srcIn,
                                ),
                                child: Image.asset(
                                  action.asset,
                                  fit: BoxFit.contain,
                                ),
                              ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        action.label,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 12,
                          height: 1.2,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _NewChip extends StatelessWidget {
  const _NewChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.secondarySoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        '8 layanan',
        style: TextStyle(
          color: Color(0xFF56731B),
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _QuickAction {
  const _QuickAction(this.label, this.asset, this.background, {this.tint});

  final String label;
  final String asset;
  final Color background;
  final Color? tint;
}
