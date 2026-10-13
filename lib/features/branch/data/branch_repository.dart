import '../../../core/network/myrg_api.dart';
import '../models/branch.dart';

/// Backend mode: GET /branches. Demo mode: Figma fixtures (not live addresses, GPS distances
/// or schedules).
class BranchRepository {
  const BranchRepository();
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

  static final _found = <String, (DateTime, List<Branch>)>{};

  /// How many outlets one request asks for. Raja Gadai has ~700; the page shows the nearest
  /// three and a short "others" list, and the search box asks the backend for anything else.
  static const pageSize = 30;

  /// Backend mode: outlets matching [q], nearest first when the phone's position is known
  /// (the backend measures against Raja Gadai's outlet coordinates), within [radiusKm] if set.
  Future<List<Branch>> find({
    double? lat,
    double? lng,
    String q = '',
    double? radiusKm,
  }) async {
    final located = lat != null && lng != null;
    // ~100 m grid: walking around a room does not download the list again.
    final key = [
      if (located) '${lat.toStringAsFixed(3)},${lng.toStringAsFixed(3)}',
      q.toLowerCase(),
      '${radiusKm ?? ''}',
    ].join('|');
    final cached = _found[key];
    if (cached != null &&
        DateTime.now().difference(cached.$1) < const Duration(minutes: 10)) {
      return cached.$2;
    }
    final data = await MyrgApi.get(
      '/branches',
      query: <String, dynamic>{
        if (located) ...{'lat': lat, 'lng': lng},
        if (located && radiusKm != null) 'radius': radiusKm,
        if (q.isNotEmpty) 'q': q,
        'limit': pageSize,
      },
      auth: false,
    );
    final branches = [
      for (final b in data as List? ?? const [])
        if (b is Map) Branch.fromApi(Map<String, dynamic>.from(b)),
    ];
    if (_found.length > 40) _found.clear(); // typed searches must not pile up
    _found[key] = (DateTime.now(), branches);
    return branches;
  }

  /// Demo mode: the Figma fixtures. (Backend mode uses [find].)
  Future<List<Branch>> load() async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    return fixtures;
  }
}
