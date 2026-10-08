import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../data/onboarding_repository.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(),
);

final onboardingRepositoryProvider = Provider<OnboardingRepository>(
  (ref) => SecureOnboardingRepository(ref.watch(secureStorageProvider)),
);
