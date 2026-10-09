import 'package:flutter/material.dart';

enum MemberTier { bronze, silver, gold, platinum }

extension MemberTierStyle on MemberTier {
  String get label => switch (this) {
    MemberTier.bronze => 'Bronze',
    MemberTier.silver => 'Silver',
    MemberTier.gold => 'Gold',
    MemberTier.platinum => 'Platinum',
  };
  Color get cardColor => switch (this) {
    MemberTier.bronze => const Color(0xFF9C6B3C),
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
    int? xp,
  }) : _xp = xp;
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

  /// Tier progress (backend `xp`). Demo profiles have none: their points double as progress.
  final int? _xp;
  int get xp => _xp ?? points;
  double get progress => levelTarget <= levelStart
      ? 1
      : ((xp - levelStart) / (levelTarget - levelStart)).clamp(0, 1);
  int get pointsToUpgrade => (levelTarget - xp).clamp(0, levelTarget);
  bool get canReuseVerification =>
      hasPawned && identityVerified && bankVerified;
}
