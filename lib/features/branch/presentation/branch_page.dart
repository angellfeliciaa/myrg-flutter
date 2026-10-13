import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/location/device_location.dart';
import '../../../core/network/backend_config.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/widgets/phase_one_widgets.dart';
import '../data/branch_repository.dart';
import '../models/branch.dart';

class BranchPage extends StatefulWidget {
  const BranchPage({this.repository = const BranchRepository(), super.key});
  final BranchRepository repository;
  @override
  State<BranchPage> createState() => _BranchPageState();
}

class _BranchPageState extends State<BranchPage> {
  final _search = TextEditingController();
  List<Branch> _branches = [];
  bool _loading = true, _failed = false;
  double? _radius;
  String? _service;

  // Backend mode: the phone's position, for distances and "3 Cabang Terdekat".
  bool _locating = false;
  bool _located = false;
  LocationProblem? _locationProblem;

  /// The permission dialog appears on the first visit only; after a "no" the page shows a
  /// card with a button instead of asking again on every open.
  static bool _askedThisSession = false;

  /// Where the phone was last time, so a refresh reloads with distances right away.
  static LocationResult? _lastPosition;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Adds distances once the position is known. The list is already on screen by then, so a
  /// slow GPS fix or a refused permission never blocks it.
  Future<void> _locate({required bool request}) async {
    if (!BackendConfig.enabled || _locating) return;
    setState(() => _locating = true);
    final result = await DeviceLocation.current(request: request);
    if (!mounted) return;
    if (!result.ok) {
      setState(() {
        _locating = false;
        _locationProblem = result.problem;
      });
      return;
    }
    _lastPosition = result;
    try {
      final branches = await widget.repository.loadNear(
        result.latitude!,
        result.longitude!,
      );
      if (!mounted) return;
      setState(() {
        _branches = branches;
        _located = true;
        _locationProblem = null;
      });
    } catch (_) {
      // Keep the list without distances.
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _fixLocation() async {
    final problem = _locationProblem;
    if (problem == LocationProblem.deniedForever ||
        problem == LocationProblem.serviceOff) {
      await DeviceLocation.openSettings(problem!);
      return; // the member comes back and pulls to refresh
    }
    await _locate(request: true);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final known = BackendConfig.enabled ? _lastPosition : null;
      final branches = known == null
          ? await widget.repository.load()
          : await widget.repository.loadNear(known.latitude!, known.longitude!);
      if (mounted) {
        setState(() {
          _branches = branches;
          _loading = false;
          _located = known != null;
        });
        final ask = !_askedThisSession;
        _askedThisSession = true;
        _locate(request: ask);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _failed = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Widget _sectionTitle(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      text,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
    ),
  );

  Future<void> _filter() async {
    var radius = _radius;
    var service = _service;
    final apply = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filter Cabang',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 24),
                if (_branches.any((b) => b.distanceKm != null)) ...[
                  const Text(
                    'Jarak contoh',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final value in <double?>[null, 2, 3, 5])
                        ChoiceChip(
                          label: Text(
                            value == null ? 'Semua' : '${value.toInt()} km',
                          ),
                          selected: radius == value,
                          onSelected: (_) => update(() => radius = value),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                const Text(
                  'Layanan',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final value in <String?>[
                      null,
                      'Gadai HP',
                      'Gadai Elektronik',
                      'Pembayaran',
                      'Pengambilan Barang',
                    ])
                      ChoiceChip(
                        label: Text(value ?? 'Semua'),
                        selected: service == value,
                        onSelected: (_) => update(() => service = value),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                PhaseOneButton(
                  label: 'Terapkan Filter',
                  onPressed: () => Navigator.pop(context, true),
                ),
                Center(
                  child: TextButton(
                    onPressed: () => update(() {
                      radius = null;
                      service = null;
                    }),
                    child: const Text('Reset'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (apply == true && mounted) {
      setState(() {
        _radius = radius;
        _service = service;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final visible =
        _branches
            .where(
              (b) =>
                  '${b.name} ${b.address}'.toLowerCase().contains(query) &&
                  (_radius == null ||
                      (b.distanceKm != null && b.distanceKm! <= _radius!)) &&
                  (_service == null || b.services.contains(_service)),
            )
            .toList()
          ..sort(
            (a, b) => (a.distanceKm ?? double.infinity).compareTo(
              b.distanceKm ?? double.infinity,
            ),
          );
    // "3 Cabang Terdekat" only on the plain list: a search or filter is the member's own order.
    final showNearest =
        _located && query.isEmpty && _radius == null && _service == null;
    return PhaseOneScaffold(
      title: 'Cabang',
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _search,
                    onChanged: (_) => setState(() {}),
                    textInputAction: TextInputAction.search,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Cari cabang atau area',
                      hintStyle: const TextStyle(fontSize: 12),
                      fillColor: Colors.white,
                      filled: true,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 12,
                      ),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Opacity(
                          opacity: .5,
                          child: Image.asset(
                            'assets/icons/valuation_search.png',
                            width: 16,
                            height: 16,
                          ),
                        ),
                      ),
                      prefixIconConstraints: const BoxConstraints(minWidth: 40),
                      suffixIcon: _search.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Hapus pencarian',
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () => setState(_search.clear),
                            ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFD9D9DD)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Filter cabang',
                  onPressed: _filter,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primarySoft,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: Image.asset(
                    'assets/icons/branch_filter.png',
                    width: 20,
                    height: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (query.isEmpty) ...[
              const BranchMapImage(),
              const SizedBox(height: 16),
            ],
            if (_radius != null || _service != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Filter: ${_radius == null ? 'Semua jarak' : '${_radius!.toInt()} km'}${_service == null ? '' : ' • $_service'}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() {
                        _radius = null;
                        _service = null;
                      }),
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              ),
            if (_locating && !_loading)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  'Mencari cabang terdekat...',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            if (_locationProblem != null && !_loading && !_locating) ...[
              PhaseOneCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(switch (_locationProblem!) {
                      LocationProblem.serviceOff =>
                        'Lokasi HP sedang mati. Nyalakan untuk melihat cabang terdekat.',
                      LocationProblem.deniedForever =>
                        'Izin lokasi ditolak. Izinkan lewat Pengaturan untuk melihat cabang terdekat.',
                      LocationProblem.denied =>
                        'Izinkan lokasi untuk melihat 3 cabang terdekat dan jaraknya.',
                      LocationProblem.unavailable =>
                        'Lokasi belum bisa dibaca. Coba lagi di tempat terbuka.',
                    }, style: const TextStyle(fontSize: 13, height: 1.5)),
                    TextButton(
                      onPressed: _fixLocation,
                      child: Text(
                        _locationProblem == LocationProblem.deniedForever ||
                                _locationProblem == LocationProblem.serviceOff
                            ? 'Buka Pengaturan'
                            : 'Aktifkan Lokasi',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_failed)
              PhaseOneCard(
                child: Column(
                  children: [
                    const Text('Cabang belum dapat ditampilkan'),
                    TextButton(
                      onPressed: _load,
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              )
            else if (visible.isEmpty)
              PhaseOneCard(
                child: Column(
                  children: [
                    const Text(
                      'Cabang tidak ditemukan',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Coba kata kunci atau filter lain.',
                      style: TextStyle(fontSize: 13),
                    ),
                    TextButton(
                      onPressed: () => setState(() {
                        _search.clear();
                        _radius = null;
                        _service = null;
                      }),
                      child: const Text('Reset pencarian'),
                    ),
                  ],
                ),
              )
            else
              for (final (index, b) in visible.indexed) ...[
                if (showNearest && index == 0)
                  _sectionTitle(
                    visible.length < 3
                        ? 'Cabang Terdekat'
                        : '3 Cabang Terdekat',
                  ),
                if (showNearest && index == 3) _sectionTitle('Cabang Lainnya'),
                PhaseOneCard(
                  onTap: () => context.push(AppRoutes.branchDetail, extra: b),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFE5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Image.asset(
                          'assets/icons/branch_marker.png',
                          width: 24,
                          height: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              b.name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              b.address,
                              style: const TextStyle(
                                fontSize: 12,
                                height: 1.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            BranchMeta(branch: b),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            if (!BackendConfig.enabled)
              const Text(
                'Pratinjau FE • Peta, jarak dan informasi cabang memakai data contoh, bukan lokasi GPS.',
                style: TextStyle(
                  fontSize: 11,
                  height: 1.4,
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class BranchMapImage extends StatelessWidget {
  const BranchMapImage({this.detail = false, super.key});
  final bool detail;
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: AspectRatio(
      aspectRatio: detail ? 967 / 350 : 967 / 356,
      child: LayoutBuilder(
        builder: (context, c) => ClipRect(
          child: OverflowBox(
            maxWidth: c.maxWidth * (detail ? 1.0589 : 1.0622),
            maxHeight: c.maxHeight * (detail ? 1.1857 : 1.1569),
            child: Image.asset(
              detail
                  ? 'assets/images/branch_detail_map.png'
                  : 'assets/images/branch_map.png',
              width: c.maxWidth * (detail ? 1.0589 : 1.0622),
              height: c.maxHeight * (detail ? 1.1857 : 1.1569),
              fit: BoxFit.fill,
              semanticLabel: 'Ilustrasi peta cabang contoh',
            ),
          ),
        ),
      ),
    ),
  );
}

class BranchMeta extends StatelessWidget {
  const BranchMeta({required this.branch, super.key});
  final Branch branch;
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 4,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      if (branch.distanceKm != null) ...[
        Text(
          '${branch.distanceKm!.toStringAsFixed(1)} Km',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const Text('|', style: TextStyle(color: AppColors.divider)),
      ],
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('assets/icons/branch_clock.png', width: 14, height: 14),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              branch.hours,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    ],
  );
}
