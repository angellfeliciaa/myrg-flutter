import 'package:flutter/foundation.dart';
import '../models/member_profile.dart';

/// Preview values. Production must hydrate this from the authenticated RG member.
abstract final class MemberRepository {
  static void resetForRegistration(String name) {
    // A register result does not prove identity/bank verification. Hydrate after OTP.
    profile.value = MemberProfile(
      name: name,
      number: '',
      tier: MemberTier.silver,
      points: 0,
      levelStart: 0,
      levelTarget: 0,
      balance: 0,
      voucherCount: 0,
      hasPawned: false,
      identityVerified: false,
      bankVerified: false,
      membershipReady: false,
    );
  }

  static final profile = ValueNotifier<MemberProfile>(
    const MemberProfile(
      name: 'Esther Howard',
      number: 'RG00077123',
      tier: MemberTier.gold,
      points: 4500,
      levelStart: 3000,
      levelTarget: 6000,
      nextTier: MemberTier.platinum,
      balance: 150000,
      voucherCount: 1,
      hasPawned: true,
      identityVerified: true,
      bankVerified: true,
      benefits: [
        'Promo khusus member',
        'Voucher biaya layanan',
        'Poin setiap transaksi',
      ],
    ),
  );
}
