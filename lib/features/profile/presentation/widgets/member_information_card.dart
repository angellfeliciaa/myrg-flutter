import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../membership/models/member_profile.dart';

class MemberInformationCard extends StatefulWidget {
  const MemberInformationCard({required this.member, super.key});
  final MemberProfile member;

  @override
  State<MemberInformationCard> createState() => _MemberInformationCardState();
}

class _MemberInformationCardState extends State<MemberInformationCard> {
  static const _green = Color(0xFFF0F6DC);
  bool _expanded = false;

  Widget _row(String label, Widget value) => ConstrainedBox(
    constraints: const BoxConstraints(minHeight: 46),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                height: 20 / 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Align(alignment: Alignment.centerRight, child: value),
          ),
        ],
      ),
    ),
  );

  Widget _value(String value) => Text(
    value,
    textAlign: TextAlign.right,
    style: const TextStyle(
      fontSize: 13,
      height: 20 / 13,
      fontWeight: FontWeight.w500,
      color: Color(0xFF242424),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final member = widget.member;
    final active = member.membershipReady && member.benefitsActive;
    final expiry = member.membershipReady ? member.pointsValidUntil : null;
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE7E7EA)),
      ),
      clipBehavior: Clip.antiAlias,
      child: AnimatedSize(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Material(
              color: _green,
              child: Semantics(
                button: true,
                value: _expanded ? 'Terbuka' : 'Tertutup',
                child: InkWell(
                  key: const ValueKey('member-information-toggle'),
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'M',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Informasi Member',
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 17 / 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF242424),
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Detail keanggotaan kamu',
                                style: TextStyle(
                                  fontSize: 10,
                                  height: 1.2,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        AnimatedRotation(
                          turns: _expanded ? .5 : 0,
                          duration: const Duration(milliseconds: 220),
                          child: const Icon(
                            Icons.keyboard_arrow_down,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (_expanded)
              Padding(
                key: const ValueKey('member-information-details'),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _row(
                      'Nomor Member',
                      _value(
                        member.number.isEmpty
                            ? 'Belum tersedia'
                            : member.number,
                      ),
                    ),
                    _row(
                      'Tier Saat Ini',
                      _value(
                        member.membershipReady
                            ? member.tier.label
                            : 'Belum aktif',
                      ),
                    ),
                    _row(
                      'Masa Berlaku Poin',
                      _value(
                        expiry == null
                            ? 'Belum tersedia'
                            : DateFormat('d MMM yyyy', 'id').format(expiry),
                      ),
                    ),
                    _row(
                      'Benefit Tambahan',
                      Container(
                        constraints: const BoxConstraints(
                          minWidth: 72,
                          minHeight: 24,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: active ? _green : AppColors.surfaceSoft,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Text(
                          active ? 'Aktif' : 'Belum aktif',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10,
                            height: 1.4,
                            fontWeight: FontWeight.w600,
                            color: active
                                ? AppColors.secondary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
