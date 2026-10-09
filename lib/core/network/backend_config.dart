import 'rg_integration.dart';

/// Where the MyRG backend lives. The app only talks to the MyRG backend; the backend talks to
/// Raja Gadai's core system.
///
/// Run against the backend:
///   flutter run --dart-define=RG_PREVIEW=false --dart-define=MYRG_API_URL=http://10.0.2.2:8000/api/v1
/// Without RG_PREVIEW=false the app keeps using its demo data (presentations).
abstract final class BackendConfig {
  static bool get enabled => !RgIntegration.preview;

  /// Android emulator reaches the laptop's `php artisan serve` at 10.0.2.2.
  static const baseUrl = String.fromEnvironment(
    'MYRG_API_URL',
    defaultValue: 'http://10.0.2.2:8000/api/v1',
  );
}
