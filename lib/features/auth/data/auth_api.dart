import '../../../core/network/myrg_api.dart';
import '../../../core/session/session_store.dart';
import '../../activity/data/activity_api.dart';
import '../../membership/data/member_api.dart';

/// Why the OTP page is shown.
enum OtpPurpose { register, newDevice, forgotPassword, changePhone, resetPin }

/// Sign-up and login against the MyRG backend (docs/integrasi-flutter.md, 4.2 and 4.3).
///
/// Sign-up: register -> otp/send -> otp/verify -> pin/create.
/// Login: login (email/phone + password) -> pin/insert. A new phone: OTP -> auth/login/otp.
/// Opening the app again: pin/insert with phone + PIN + deviceId.
abstract final class AuthApi {
  // Steps of the flow in progress (memory only: a restarted app starts the flow again).
  static String? _registrationToken;
  static String? _otpToken;
  static String? _pinToken;
  static String? _phone;
  static OtpPurpose purpose = OtpPurpose.register;

  /// Sign-up step 1: store the form, then send the OTP. Returns seconds until a resend is allowed.
  static Future<int> register({
    required String name,
    required DateTime birthDate,
    required String phone,
    required String password,
    String? email,
    String? referral,
  }) async {
    final data =
        await MyrgApi.post(
              '/register',
              auth: false,
              body: {
                'name': name,
                'birthDate': birthDate.toIso8601String().split('T').first,
                'phone': phone,
                'password': password,
                'passwordConfirmation': password,
                if (email != null && email.isNotEmpty) 'email': email,
                if (referral != null && referral.isNotEmpty)
                  'referral': referral,
              },
            )
            as Map;
    _registrationToken = data['registrationToken'] as String;
    _phone = phone;
    purpose = OtpPurpose.register;

    return sendOtp(phone);
  }

  static Future<int> sendOtp([String? phone]) async {
    final target = phone ?? _phone!;
    _phone = target;
    final data =
        await MyrgApi.post('/otp/send', auth: false, body: {'phone': target})
            as Map;

    return (data['resendAfterSeconds'] as num?)?.toInt() ?? 60;
  }

  static Future<void> verifyOtp(String code) async {
    final data =
        await MyrgApi.post(
              '/otp/verify',
              auth: false,
              body: {'phone': _phone, 'code': code},
            )
            as Map;
    _otpToken = data['otpToken'] as String;
  }

  /// Sign-up last step. Returns the outcome: 'syncMember' (existing Raja Gadai member, data linked)
  /// or 'newCustomer'. A data mismatch at Raja Gadai throws MEMBER_NUMBER_IN_USE.
  static Future<String> createPin(String pin) async {
    final data =
        await MyrgApi.post(
              '/pin/create',
              auth: false,
              body: {
                'registrationToken': _registrationToken,
                'otpToken': _otpToken,
                'pin': pin,
                'deviceId': await SessionStore.deviceId(),
                'deviceName': 'Aplikasi MyRG',
              },
            )
            as Map;
    await _startSession(data);
    _registrationToken = null;

    return (data['outcome'] as String?) ?? 'newCustomer';
  }

  /// Login step 1. A new phone throws DEVICE_VERIFICATION_REQUIRED (then OTP -> [loginWithOtp]).
  static Future<void> login(String identifier, String password) async {
    final data =
        await MyrgApi.post(
              '/login',
              auth: false,
              body: {
                'identifier': identifier,
                'password': password,
                'deviceId': await SessionStore.deviceId(),
                'deviceName': 'Aplikasi MyRG',
              },
            )
            as Map;
    _pinToken = data['pinToken'] as String;
    if (!identifier.contains('@')) _phone = identifier;
  }

  /// PIN page: after the password step, or quick unlock of a stored session on this phone.
  static Future<void> insertPin(String pin) async {
    final Map<String, dynamic> body = _pinToken != null
        ? {'pinToken': _pinToken, 'pin': pin}
        : {
            'phone': SessionStore.phone ?? _phone,
            'pin': pin,
            'deviceId': await SessionStore.deviceId(),
          };
    final data =
        await MyrgApi.post('/pin/insert', auth: false, body: body) as Map;
    await _startSession(data);
    _pinToken = null;
  }

  /// New phone: after OTP to the account's number.
  static Future<void> loginWithOtp() async {
    final data =
        await MyrgApi.post(
              '/auth/login/otp',
              auth: false,
              body: {
                'otpToken': _otpToken,
                'deviceId': await SessionStore.deviceId(),
                'deviceName': 'Aplikasi MyRG',
              },
            )
            as Map;
    await _startSession(data);
  }

  static Future<void> resetPassword(String newPassword) async {
    await MyrgApi.post(
      '/password/reset',
      auth: false,
      body: {
        'otpToken': _otpToken,
        'password': newPassword,
        'passwordConfirmation': newPassword,
      },
    );
  }

  /// Lupa PIN, last step (after OTP to the account's number). All sessions end; the member
  /// then unlocks with the new PIN.
  static Future<void> resetPin(String newPin) async {
    await MyrgApi.post(
      '/auth/pin/reset',
      auth: false,
      body: {'otpToken': _otpToken, 'newPin': newPin},
    );
  }

  /// Logout, session ended or another account: drop what the previous member left in memory.
  static void clearLocalData() {
    _registrationToken = null;
    _otpToken = null;
    _pinToken = null;
    ActivityApi.clear();
    MemberApi.clear();
  }

  static Future<void> changePassword(String current, String next) async {
    await MyrgApi.put(
      '/me/password',
      body: {'currentPassword': current, 'newPassword': next},
    );
  }

  /// Ganti PIN (logged in). Other phones are logged out; this one stays.
  static Future<void> changePin(String current, String next) async {
    await MyrgApi.put('/me/pin', body: {'currentPin': current, 'newPin': next});
  }

  /// Ganti nomor HP, last step: OTP to the NEW number was verified, confirm with the PIN.
  static Future<void> changePhone(String pin) async {
    final member = Map<String, dynamic>.from(
      await MyrgApi.put('/me/phone', body: {'otpToken': _otpToken, 'pin': pin})
          as Map,
    );
    await SessionStore.savePhone(
      member['phone'] as String,
    ); // quick unlock uses the new number
    MemberApi.applyProfile(member);
  }

  /// Hapus akun (Play Store / App Store requirement), confirmed with the PIN. Pawns at Raja Gadai
  /// are not affected.
  static Future<void> deleteAccount(String pin, {String? reason}) async {
    await MyrgApi.delete(
      '/me',
      body: {
        'pin': pin,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      },
    );
    await SessionStore.clear();
    clearLocalData();
  }

  static Future<void> logout() async {
    try {
      await MyrgApi.post('/auth/logout');
    } catch (_) {
      // Logging out locally matters most; the server session ends anyway on the next login.
    }
    await SessionStore.clear();
    clearLocalData();
  }

  static bool get hasPendingPinToken => _pinToken != null;

  static Future<void> _startSession(Map data) async {
    clearLocalData(); // maybe another account than the last one on this phone
    await SessionStore.saveTokens(
      Map<String, dynamic>.from(data['tokens'] as Map),
    );
    final member = Map<String, dynamic>.from(data['member'] as Map);
    await SessionStore.savePhone(member['phone'] as String);
    MemberApi.applyProfile(member);
    MemberApi.refreshCard(
      force: true,
    ); // fire and forget: the home card updates when it arrives
  }
}
