import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../membership/models/member_profile.dart';

class HomeMembershipCard extends StatelessWidget {
  const HomeMembershipCard({
    required this.member,
    required this.onBalanceTap,
    required this.onPointsTap,
    required this.onVoucherTap,
    super.key,
  });

  final MemberProfile member;
  final VoidCallback onBalanceTap;
  final VoidCallback onPointsTap;
  final VoidCallback onVoucherTap;

  @override
  Widget build(BuildContext context) {
    if (!member.membershipReady) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Halo, ${member.name}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            const Text(
              'Data member, saldo, dan poin akan tersedia setelah verifikasi akun selesai.',
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
          ],
        ),
      );
    }
    final number = NumberFormat.decimalPattern('id');
    final isGold = member.tier == MemberTier.gold;
    final ink = isGold ? AppColors.primary : member.tier.inkColor;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
      decoration: BoxDecoration(
        color: isGold ? const Color(0xFFAACE38) : member.tier.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x80F5F5F7)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 4,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 32),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selamat Siang,',
                          style: TextStyle(color: ink, fontSize: 12, height: 1),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          member.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: ink,
                            fontSize: 16,
                            height: 1.15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0x1AE7E7EA),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isGold)
                          Image.asset(
                            AppAssets.homeGoldBadge,
                            width: 16,
                            height: 16,
                            fit: BoxFit.contain,
                          )
                        else
                          Icon(
                            Icons.workspace_premium_rounded,
                            color: ink,
                            size: 16,
                          ),
                        const SizedBox(width: 2),
                        Text(
                          member.tier.label,
                          style: TextStyle(
                            color: isGold ? const Color(0xFFFFE28D) : ink,
                            fontSize: 12,
                            height: 1,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            constraints: const BoxConstraints(minHeight: 55),
            padding: const EdgeInsets.fromLTRB(16, 7, 16, 9),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _Metric(
                  label: 'Saldo RG',
                  value: 'Rp ${number.format(member.balance)}',
                  flex: 31,
                  onTap: onBalanceTap,
                ),
                const _MetricDivider(),
                _Metric(
                  label: 'Poin ErGe',
                  value: number.format(member.points),
                  asset: AppAssets.homePoints,
                  flex: 27,
                  onTap: onPointsTap,
                ),
                const _MetricDivider(),
                _Metric(
                  label: 'Voucher Saya',
                  value: '${member.voucherCount}',
                  asset: AppAssets.homeVoucher,
                  flex: 29,
                  onTap: onVoucherTap,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Divider(height: 1, color: ink.withValues(alpha: .25)),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text.rich(
                  TextSpan(
                    style: TextStyle(
                      color: ink,
                      fontSize: 14,
                      height: 1.2,
                      fontWeight: FontWeight.w500,
                    ),
                    children: member.nextTier == null
                        ? const [
                            TextSpan(
                              text: 'Kamu sudah berada di level tertinggi',
                            ),
                          ]
                        : [
                            const TextSpan(text: 'Raih '),
                            TextSpan(
                              text:
                                  '${number.format(member.pointsToUpgrade)} poin',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const TextSpan(text: ' untuk upgrade ke '),
                            TextSpan(
                              text: member.nextTier!.label,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                  ),
                ),
                const SizedBox(height: 7),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    minHeight: 13,
                    value: member.progress,
                    backgroundColor: const Color(0xFFECE7F3),
                    valueColor: AlwaysStoppedAnimation(
                      member.tier == MemberTier.platinum
                          ? AppColors.secondary
                          : AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      number.format(member.levelStart),
                      style: TextStyle(
                        color: ink,
                        fontSize: 13,
                        height: 1,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      number.format(member.levelTarget),
                      style: TextStyle(
                        color: ink,
                        fontSize: 13,
                        height: 1,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.onTap,
    required this.flex,
    this.asset,
  });
  final String label;
  final String value;
  final VoidCallback onTap;
  final int flex;
  final String? asset;

  @override
  Widget build(BuildContext context) => Expanded(
    flex: flex,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              if (asset != null) ...[
                Image.asset(asset!, width: 20, height: 20, fit: BoxFit.contain),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 14,
                    height: 1.4,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _MetricDivider extends StatelessWidget {
  const _MetricDivider();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 7),
    child: SizedBox(
      height: 36,
      child: VerticalDivider(width: 1, color: Color(0xFFD8D3DB)),
    ),
  );
}
