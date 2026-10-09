import 'dart:async';

import 'package:dio/dio.dart';

import '../../../core/network/backend_config.dart';
import '../../../core/network/myrg_api.dart';
import '../../auth/data/demo_session.dart';
import '../models/member_profile.dart';
import 'member_repository.dart';

/// Fills the existing notifiers (MemberRepository.profile, DemoSession.contact) from the backend,
/// so the home and account screens keep working unchanged.
abstract final class MemberApi {
  /// From `member` in a login answer or GET /me.
  static void applyProfile(Map<String, dynamic> member) {
    DemoSession.setContact(
      email: (member['email'] as String?) ?? '',
      phone: (member['phone'] as String?) ?? '',
      avatarUrl: reachableUrl(member['avatarUrl'] as String?),
      birthDate: member['birthDate'] as String?,
    );
  }

  /// The backend builds photo links from its APP_URL. During development that is often
  /// http://localhost:8000, which the emulator cannot open; point such links at the API host.
  static String? reachableUrl(String? url) {
    if (url == null) return null;
    final uri = Uri.tryParse(url);
    if (uri == null || !{'localhost', '127.0.0.1'}.contains(uri.host)) {
      return url;
    }
    final api = Uri.parse(BackendConfig.baseUrl);
    return uri
        .replace(scheme: api.scheme, host: api.host, port: api.port)
        .toString();
  }

  static Future<void> _apply(Object? data) async {
    applyProfile(Map<String, dynamic>.from(data as Map));
    // The card carries the name; it updates in the background, the save does not wait for it.
    unawaited(refreshCard(force: true));
  }

  /// Edit profile (PUT /me). [email] '' removes it; [birthDate] is yyyy-MM-dd or null.
  static Future<void> updateProfile({
    required String name,
    required String email,
    required String? birthDate,
  }) async => _apply(
    await MyrgApi.put(
      '/me',
      body: {
        'name': name,
        'email': email.isEmpty ? null : email,
        'birthDate': birthDate,
      },
    ),
  );

  /// Ganti Foto (POST /me/avatar, multipart field "photo": jpg/png/webp, max 2 MB).
  static Future<void> uploadAvatar(String filePath) async => _apply(
    await MyrgApi.post(
      '/me/avatar',
      body: FormData.fromMap({'photo': await MultipartFile.fromFile(filePath)}),
    ),
  );

  static Future<void> deleteAvatar() async =>
      _apply(await MyrgApi.delete('/me/avatar'));

  static Future<void>? _cardLoading;
  static DateTime? _cardAt;
  static int _cardGeneration = 0;

  /// GET /loyalty/member-card -> MemberProfile. Skipped when read in the last 30 seconds,
  /// unless [force] (after a payment or a profile change), which also starts a new request
  /// instead of reusing one that began earlier.
  static Future<void> refreshCard({bool force = false}) {
    final at = _cardAt;
    if (!force && at != null && DateTime.now().difference(at).inSeconds < 30) {
      return Future.value();
    }
    final running = _cardLoading;
    if (!force && running != null) return running;

    final generation = ++_cardGeneration;
    late final Future<void> request;
    request = _refreshCard(generation).whenComplete(() {
      if (identical(_cardLoading, request)) _cardLoading = null;
    });
    _cardLoading = request;
    return request;
  }

  /// Logout / another account: a card request still on the way is dropped.
  static void clear() {
    _cardGeneration++;
    _cardLoading = null;
    _cardAt = null;
    MemberRepository.resetForRegistration('');
    DemoSession.setContact(email: '', phone: '');
  }

  static Future<void> _refreshCard(int generation) async {
    try {
      final c = Map<String, dynamic>.from(
        await MyrgApi.get('/loyalty/member-card') as Map,
      );
      if (generation != _cardGeneration) return;
      MemberRepository.profile.value = MemberProfile(
        name: c['name'] as String? ?? '',
        number: c['number'] as String? ?? '',
        tier: _tier(c['tier'] as String?) ?? MemberTier.bronze,
        nextTier: _tier(c['nextTier'] as String?),
        xp: (c['xp'] as num?)?.toInt() ?? 0,
        points: (c['points'] as num?)?.toInt() ?? 0,
        levelStart: (c['levelStart'] as num?)?.toInt() ?? 0,
        levelTarget: (c['levelTarget'] as num?)?.toInt() ?? 0,
        balance: (c['balance'] as num?)?.toInt() ?? 0,
        voucherCount: (c['voucherCount'] as num?)?.toInt() ?? 0,
        hasPawned: c['hasPawned'] == true,
        identityVerified: c['identityVerified'] == true,
        bankVerified: c['bankVerified'] == true,
        membershipReady: c['membershipReady'] == true,
        benefits: [for (final b in (c['benefits'] as List? ?? const [])) '$b'],
      );
      _cardAt = DateTime.now();
    } catch (_) {
      // Keep what is shown; the card refreshes on the next app start.
    }
  }

  static MemberTier? _tier(String? code) => switch (code) {
    'bronze' => MemberTier.bronze,
    'silver' => MemberTier.silver,
    'gold' => MemberTier.gold,
    'platinum' => MemberTier.platinum,
    _ => null,
  };
}
