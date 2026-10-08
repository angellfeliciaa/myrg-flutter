import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class OnboardingRepository {
  Future<bool> hasCompletedOnboarding();
  Future<void> completeOnboarding();
}

class SecureOnboardingRepository implements OnboardingRepository {
  SecureOnboardingRepository(this._storage);

  static const _completedKey = 'has_completed_onboarding';

  final FlutterSecureStorage _storage;

  @override
  Future<bool> hasCompletedOnboarding() async {
    return await _storage.read(key: _completedKey) == 'true';
  }

  @override
  Future<void> completeOnboarding() {
    return _storage.write(key: _completedKey, value: 'true');
  }
}
