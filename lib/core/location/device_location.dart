import 'package:geolocator/geolocator.dart';

/// Why the phone's position is not available.
enum LocationProblem { serviceOff, denied, deniedForever, unavailable }

class LocationResult {
  const LocationResult.at(double this.latitude, double this.longitude)
    : problem = null;
  const LocationResult.failed(LocationProblem this.problem)
    : latitude = null,
      longitude = null;

  final double? latitude, longitude;
  final LocationProblem? problem;
  bool get ok => problem == null;
}

/// The phone's position for "cabang terdekat".
///
/// Testing shortcut: `--dart-define=MYRG_TEST_LOCATION=-6.2253,106.8090` makes the app use that
/// point instead of asking the device (an emulator's default location is in California).
abstract final class DeviceLocation {
  static const _testLocation = String.fromEnvironment('MYRG_TEST_LOCATION');

  /// The fixed test point, when the app was started with MYRG_TEST_LOCATION.
  static LocationResult? get testOverride => parse(_testLocation);

  /// "lat,lng" -> a result; null when empty or not two valid numbers.
  static LocationResult? parse(String value) {
    final parts = value.split(',');
    if (parts.length != 2) return null;
    final lat = double.tryParse(parts[0].trim());
    final lng = double.tryParse(parts[1].trim());
    if (lat == null || lng == null || lat.abs() > 90 || lng.abs() > 180) {
      return null;
    }
    return LocationResult.at(lat, lng);
  }

  /// Asks for the location permission when [request] is true (the member tapped a button);
  /// otherwise only uses a permission that was already given.
  static Future<LocationResult> current({bool request = true}) async {
    final test = testOverride;
    if (test != null) return test;
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return const LocationResult.failed(LocationProblem.serviceOff);
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied && request) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        return const LocationResult.failed(LocationProblem.deniedForever);
      }
      if (permission == LocationPermission.denied) {
        return const LocationResult.failed(LocationProblem.denied);
      }
      // High accuracy on purpose: lower levels ask Android for network-based positioning only
      // (Wi-Fi / cell towers) and never switch the GPS on, so a phone without such a fix
      // (and every emulator) gets no position at all. The last known position can be days
      // old (another city), so it is only the fallback.
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 10),
          ),
        );
      } catch (_) {
        position = await Geolocator.getLastKnownPosition();
      }
      if (position == null) {
        return const LocationResult.failed(LocationProblem.unavailable);
      }
      return LocationResult.at(position.latitude, position.longitude);
    } catch (_) {
      return const LocationResult.failed(LocationProblem.unavailable);
    }
  }

  static Future<void> openSettings(LocationProblem problem) =>
      problem == LocationProblem.serviceOff
      ? Geolocator.openLocationSettings()
      : Geolocator.openAppSettings();
}
