import '../../../core/network/backend_config.dart';
import '../../../core/network/myrg_api.dart';
import '../models/branch.dart';

/// Backend mode: GET /branches. Demo mode: Figma fixtures (not live addresses, GPS distances
/// or schedules).
class BranchRepository {
  const BranchRepository();
  static (DateTime, List<Branch>)? _cache;
  static const fixtures = [
    Branch(
      id: 'tebet',
      name: 'Raja Gadai Tebet',
      address: 'Jl. Kemang Raya No. 15, Jakarta Selatan',
      distanceKm: 1.2,
    ),
    Branch(
      id: 'kemang',
      name: 'Raja Gadai Kemang',
      address: 'Jl. Melawai Raya No. 10, Jakarta Selatan',
      distanceKm: 2.5,
    ),
    Branch(
      id: 'menteng',
      name: 'Raja Gadai Menteng',
      address: 'Jl. HOS Cokroaminoto No. 22, Jakarta Pusat',
      distanceKm: 3.1,
    ),
  ];

  static (DateTime, String, List<Branch>)? _nearCache;

  /// Outlets with distanceKm from the phone's position, nearest first (the backend measures
  /// against Raja Gadai's outlet coordinates; outlets without coordinates come last).
  Future<List<Branch>> loadNear(double lat, double lng) async {
    // ~100 m grid: walking around a room does not download the list again.
    final key = '${lat.toStringAsFixed(3)},${lng.toStringAsFixed(3)}';
    final cached = _nearCache;
    if (cached != null &&
        cached.$2 == key &&
        DateTime.now().difference(cached.$1) < const Duration(minutes: 10)) {
      return cached.$3;
    }
    final data = await MyrgApi.get(
      '/branches',
      query: {'lat': lat, 'lng': lng},
      auth: false,
    );
    final branches = [
      for (final b in data as List? ?? const [])
        if (b is Map) Branch.fromApi(Map<String, dynamic>.from(b)),
    ];
    _nearCache = (DateTime.now(), key, branches);
    return branches;
  }

  /// All outlets, without distances (used until the phone's position is known).
  Future<List<Branch>> load() async {
    if (BackendConfig.enabled) {
      // Outlets, hours and services rarely change: one download per 10 minutes is enough.
      final cached = _cache;
      if (cached != null &&
          DateTime.now().difference(cached.$1) < const Duration(minutes: 10)) {
        return cached.$2;
      }
      final data = await MyrgApi.get('/branches', auth: false);
      final branches = [
        for (final b in data as List? ?? const [])
          if (b is Map) Branch.fromApi(Map<String, dynamic>.from(b)),
      ];
      _cache = (DateTime.now(), branches);
      return branches;
    }
    await Future<void>.delayed(const Duration(milliseconds: 350));
    return fixtures;
  }
}
