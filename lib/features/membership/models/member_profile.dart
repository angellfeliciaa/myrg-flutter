import 'package:flutter/material.dart';

enum MemberTier { silver, gold, platinum }

extension MemberTierStyle on MemberTier {
  String get label => switch (this) {
    MemberTier.silver => 'Silver',
    MemberTier.gold => 'Gold',
    MemberTier.platinum => 'Platinum',
  };
  Color get cardColor => switch (this) {
    MemberTier.silver => const Color(0xFF536475),
    MemberTier.gold => const Color(0xFFA9CE37),
    MemberTier.platinum => const Color(0xFF632B8D),
  };
  Color get inkColor =>
      this == MemberTier.gold ? const Color(0xFF23340C) : Colors.white;
}

class MemberProfile {
  const MemberProfile({
    required this.name,
    required this.number,
    required this.tier,
    required this.points,
    required this.levelStart,
    required this.levelTarget,
    required this.balance,
    required this.voucherCount,
    required this.hasPawned,
    required this.identityVerified,
    required this.bankVerified,
    this.nextTier,
    this.benefits = const [],
    this.membershipReady = true,
    this.pointsValidUntil,
    this.benefitsActive = false,
  });
  final String name;
  final String number;
  final MemberTier tier;
  final int points;
  final int levelStart;
  final int levelTarget;
  final int balance;
  final int voucherCount;
  final MemberTier? nextTier;
  final bool hasPawned;
  final bool identityVerified;
  final bool bankVerified;
  final List<String> benefits;
  final bool membershipReady;
  final DateTime? pointsValidUntil;
  final bool benefitsActive;
  MemberProfile withName(String value) => MemberProfile(
    name: value,
    number: number,
    tier: tier,
    points: points,
    levelStart: levelStart,
    levelTarget: levelTarget,
    balance: balance,
    voucherCount: voucherCount,
    hasPawned: hasPawned,
    identityVerified: identityVerified,
    bankVerified: bankVerified,
    nextTier: nextTier,
    benefits: benefits,
    membershipReady: membershipReady,
    pointsValidUntil: pointsValidUntil,
    benefitsActive: benefitsActive,
  );
  double get progress => levelTarget <= levelStart
      ? 1
      : ((points - levelStart) / (levelTarget - levelStart)).clamp(0, 1);
  int get pointsToUpgrade => (levelTarget - points).clamp(0, levelTarget);
  bool get canReuseVerification =>
      hasPawned && identityVerified && bankVerified;
}
