import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/formatter.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/backend_config.dart';
import '../data/catalog_valuation_repository.dart';
import '../data/valuation_repository.dart';
import '../models/valuation.dart';

enum _Step { category, brand, model, result }

class SimulationPage extends StatefulWidget {
  const SimulationPage({this.repository, super.key});

  /// Defaults to MyRG's catalog in backend mode, Figma fixtures otherwise.
  final ValuationRepository? repository;

  @override
  State<SimulationPage> createState() => _SimulationPageState();
}

class _SimulationPageState extends State<SimulationPage> {
  static const _background = Color(0xFFFAFAFA);
  static const _ink = Color(0xFF242424);
  final _brandSearch = TextEditingController();
  final _modelSearch = TextEditingController();
  _Step _step = _Step.category;
  ValuationCategory? _category;
  ValuationBrand? _brand;
  ValuationModel? _model;
  ValuationResult? _result;
  List<ValuationBrand> _brands = [];
  List<ValuationModel> _models = [];
  bool _loading = false;
  bool _failed = false;
  String? _errorMessage;
  int _request = 0;
  late final ValuationRepository _repository =
      widget.repository ??
      (BackendConfig.enabled
          ? const CatalogValuationRepository()
          : const MockValuationRepository());
  late List<ValuationCategory> _categories =
      _repository is CatalogValuationRepository
      ? const []
      : MockValuationRepository.categories;

  @override
  void initState() {
    super.initState();
    if (_repository is CatalogValuationRepository) _load();
  }

  Future<void> _load() async {
    final request = ++_request;
    final step = _step;
    setState(() {
      _loading = true;
      _failed = false;
      _errorMessage = null;
    });
    try {
      final categories = step == _Step.category
          ? await _repository.loadCategories()
          : null;
      final brands = step == _Step.brand
          ? await _repository.brands(_category!)
          : null;
      final models = step == _Step.model
          ? await _repository.models(_category!, _brand!)
          : null;
      final result = step == _Step.result
          ? await _repository.estimate(_category!, _brand!, _model!)
          : null;
      if (!mounted || request != _request) return;
      setState(() {
        if (categories != null) _categories = categories;
        if (brands != null) _brands = brands;
        if (models != null) _models = models;
        if (result != null) _result = result;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || request != _request) return;
      setState(() {
        _loading = false;
        _failed = true;
        // Backend answers say why (e.g. today's taksiran limit is used up).
        _errorMessage = e is ApiException ? e.displayMessage : null;
      });
    }
  }

  void _chooseCategory(ValuationCategory category) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _category = category;
      _brand = null;
      _model = null;
      _result = null;
      _brands = [];
      _models = [];
      _brandSearch.clear();
      _modelSearch.clear();
      _step = _Step.brand;
    });
    _load();
  }

  void _chooseBrand(ValuationBrand brand) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _brand = brand;
      _model = null;
      _result = null;
      _models = [];
      _modelSearch.clear();
      _step = _Step.model;
    });
    _load();
  }

  void _chooseModel(ValuationModel model) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _model = model;
      _result = null;
      _step = _Step.result;
    });
    _load();
  }

  void _back() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_step == _Step.category) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(AppRoutes.home);
      }
      return;
    }
    final wasLoading = _loading || _failed;
    ++_request; // Ignore a pending mock response after leaving its step.
    setState(() {
      _step = _Step.values[_step.index - 1];
      _loading = false;
      _failed = false;
    });
    if (wasLoading && _step == _Step.model && _models.isEmpty) _load();
    if (wasLoading && _step == _Step.brand && _brands.isEmpty) _load();
  }

  void _restart() {
    ++_request;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _step = _Step.category;
      _category = null;
      _brand = null;
      _model = null;
      _result = null;
      _brands = [];
      _models = [];
      _loading = false;
      _failed = false;
      _brandSearch.clear();
      _modelSearch.clear();
    });
  }

  @override
  void dispose() {
    ++_request;
    _brandSearch.dispose();
    _modelSearch.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final titles = [
      'Pilih Kategori Barang',
      'Pilih Merk Perangkat',
      'Pilih Model Perangkat',
      'Hasil Estimasi Nilai Pinjaman',
    ];
    final descriptions = [
      'Pilih jenis barang yang ingin anda estimasikan',
      'Pilih merk ${_category?.name.toLowerCase() ?? 'perangkat'} anda',
      'Pilih model ${_category?.name.toLowerCase() ?? 'perangkat'} anda',
      'Berikut estimasi nilai pinjaman perangkat anda',
    ];
    return PopScope(
      canPop: _step == _Step.category,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
          systemNavigationBarColor: _background,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        child: Scaffold(
          backgroundColor: _background,
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 24, 0),
                  child: Row(
                    children: [
                      SizedBox.square(
                        dimension: 48,
                        child: IconButton(
                          key: const ValueKey('simulation-back'),
                          tooltip: 'Kembali',
                          onPressed: _back,
                          padding: EdgeInsets.zero,
                          icon: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.primaryDark.withValues(
                                alpha: .06,
                              ),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Image.asset(
                              AppAssets.valuationBack,
                              width: 20,
                              height: 20,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      const Expanded(
                        child: Text(
                          'Cek Pinjaman',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: _ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    key: ValueKey('simulation-scroll-${_step.name}'),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.fromLTRB(
                      24,
                      _step == _Step.brand ? 20 : 28,
                      24,
                      24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titles[_step.index],
                          style: const TextStyle(
                            fontSize: 24,
                            height: 1.2,
                            color: _ink,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          descriptions[_step.index],
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.3,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        SizedBox(
                          height:
                              _step == _Step.category || _step == _Step.result
                              ? 32
                              : 24,
                        ),
                        if (_loading)
                          const _FeedbackState(loading: true)
                        else if (_failed)
                          _FeedbackState(onRetry: _load, message: _errorMessage)
                        else
                          ...switch (_step) {
                            _Step.category => _categoryContent(),
                            _Step.brand => _brandContent(),
                            _Step.model => _modelContent(),
                            _Step.result => _resultContent(),
                          },
                      ],
                    ),
                  ),
                ),
                if (_step == _Step.result &&
                    !_loading &&
                    !_failed &&
                    _result != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Theme(
                          data: Theme.of(context).copyWith(
                            filledButtonTheme: FilledButtonThemeData(
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: const StadiumBorder(),
                                textStyle: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                          ),
                          child: AppButton(
                            label: 'Lanjut Gadai',
                            height: 48,
                            onPressed: () =>
                                context.push(AppRoutes.pawn, extra: _result),
                          ),
                        ),
                        TextButton(
                          onPressed: _restart,
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            minimumSize: const Size.fromHeight(44),
                          ),
                          child: const Text(
                            'Cek Ulang',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _categoryContent() => [
    for (final category in _categories) ...[
      _Surface(
        child: InkWell(
          onTap: () => _chooseCategory(category),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 72),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F1FB),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Image.asset(
                      category.iconAsset,
                      width: 20,
                      height: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      category.name,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.2,
                        fontWeight: FontWeight.w600,
                        color: _ink,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Image.asset(
                    AppAssets.valuationChevronPurple,
                    width: 24,
                    height: 24,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 16),
    ],
  ];

  List<Widget> _brandContent() {
    final query = _brandSearch.text.trim().toLowerCase();
    final popular = _brands.where((brand) => brand.popular).toList();
    final all =
        query.isNotEmpty
              ? _brands
                    .where((brand) => brand.name.toLowerCase().contains(query))
                    .toList()
              : _brands
                    .where((brand) => !brand.popular || brand.name == 'Huawei')
                    .toList()
          ..sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );
    return [
      _search(_brandSearch, 'Cari merk perangkat anda'),
      const SizedBox(height: 24),
      if (query.isEmpty && popular.isNotEmpty) ...[
        _sectionLabel('Merk Popular'),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth < 290 ? 2 : 3;
            final width = (constraints.maxWidth - (columns - 1) * 16) / columns;
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                for (final brand in popular)
                  SizedBox(
                    width: width,
                    height: 52,
                    child: _Surface(
                      radius: 12,
                      child: Semantics(
                        button: true,
                        label: brand.name,
                        child: InkWell(
                          key: ValueKey('valuation-brand-${brand.name}'),
                          onTap: () => _chooseBrand(brand),
                          child: Center(child: _BrandLogo(brand: brand)),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
      ],
      _sectionLabel('Semua Merk'),
      const SizedBox(height: 16),
      if (all.isEmpty)
        _empty(
          'Merk tidak ditemukan',
          'Coba kata kunci lain atau hapus pencarian.',
          _brandSearch,
        )
      else
        _list(
          all.map((brand) => (brand.name, () => _chooseBrand(brand))).toList(),
        ),
    ];
  }

  List<Widget> _modelContent() {
    final query = _modelSearch.text.trim().toLowerCase();
    final models = _models
        .where((model) => model.label.toLowerCase().contains(query))
        .toList();
    return [
      _search(_modelSearch, 'Cari model perangkat anda'),
      const SizedBox(height: 24),
      _sectionLabel('Semua Model'),
      const SizedBox(height: 16),
      if (models.isEmpty)
        _empty(
          'Model tidak ditemukan',
          'Coba kata kunci lain atau hapus pencarian.',
          _modelSearch,
        )
      else
        _list(
          models
              .map((model) => (model.label, () => _chooseModel(model)))
              .toList(),
        ),
    ];
  }

  List<Widget> _resultContent() {
    final result = _result!;
    String amount(int value) =>
        Formatter.rupiah(value).replaceFirst('Rp', 'Rp ');
    return [
      _Surface(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                children: [
                  for (final value in [result.minimum, result.maximum]) ...[
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        amount(value),
                        style: const TextStyle(
                          fontSize: 36,
                          height: 1.2,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    if (value == result.minimum) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: 16,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.asset(AppAssets.valuationInfo, width: 20, height: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Nilai final akan ditentukan setelah pemeriksaan fisik oleh petugas',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.3,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      _Surface(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 86,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F4FC),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: result.model.imageAsset == null
                    ? Image.asset(
                        result.category.iconAsset,
                        width: 28,
                        height: 28,
                      )
                    : ClipRect(
                        child: SizedBox(
                          width: 46.1,
                          height: 81.8,
                          child: OverflowBox(
                            maxWidth: 91.9,
                            maxHeight: 91.9,
                            child: Image.asset(
                              result.model.imageAsset!,
                              width: 91.9,
                              height: 91.9,
                              fit: BoxFit.fill,
                            ),
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result.productName,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.2,
                          fontWeight: FontWeight.w600,
                          color: _ink,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        result.model.variant,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.3,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Text(
          BackendConfig.enabled
              ? 'Estimasi awal, bukan penawaran pinjaman. Nilai akhir ditentukan setelah barang diperiksa Raja Gadai.'
              : 'Simulasi FE • Data dan nominal contoh, bukan penawaran pinjaman.',
          style: const TextStyle(
            fontSize: 11,
            height: 1.4,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    ];
  }

  Widget _search(TextEditingController controller, String hint) => TextField(
    controller: controller,
    onChanged: (_) => setState(() {}),
    textInputAction: TextInputAction.search,
    onSubmitted: (_) => FocusManager.instance.primaryFocus?.unfocus(),
    style: const TextStyle(fontSize: 14, color: _ink),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 12, color: Color(0xFFACACB2)),
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      prefixIcon: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        child: Opacity(
          opacity: .5,
          child: Image.asset(AppAssets.valuationSearch, width: 16, height: 16),
        ),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 44),
      suffixIcon: controller.text.isEmpty
          ? null
          : IconButton(
              tooltip: 'Hapus pencarian',
              icon: const Icon(Icons.close, size: 18),
              onPressed: () => setState(controller.clear),
            ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD9D9DD)),
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
  );

  Widget _sectionLabel(String label) => Text(
    label,
    style: const TextStyle(
      fontSize: 16,
      height: 1.2,
      fontWeight: FontWeight.w600,
      color: _ink,
    ),
  );

  Widget _list(List<(String, VoidCallback)> entries) => _Surface(
    child: Column(
      children: [
        for (int index = 0; index < entries.length; index++) ...[
          InkWell(
            onTap: entries[index].$2,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 61),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 18,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        entries[index].$1,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.3,
                          fontWeight: FontWeight.w500,
                          color: _ink,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Image.asset(
                      AppAssets.valuationChevron,
                      width: 20,
                      height: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (index < entries.length - 1)
            const Divider(height: 1, thickness: 1, color: Color(0xFFE5E3E8)),
        ],
      ],
    ),
  );

  Widget _empty(
    String title,
    String description,
    TextEditingController controller,
  ) => _Surface(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          if (controller.text.isNotEmpty)
            TextButton(
              onPressed: () => setState(controller.clear),
              child: const Text('Hapus pencarian'),
            ),
        ],
      ),
    ),
  );
}

class _Surface extends StatelessWidget {
  const _Surface({required this.child, this.radius = 16});
  final Widget child;
  final double radius;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: const BorderSide(color: Color(0xFFEBEBEB), width: .8),
    ),
    clipBehavior: Clip.antiAlias,
    child: child,
  );
}

class _BrandLogo extends StatelessWidget {
  const _BrandLogo({required this.brand});
  final ValuationBrand brand;
  @override
  Widget build(BuildContext context) {
    if (brand.logoAsset == null) {
      return Padding(
        padding: const EdgeInsets.all(8),
        child: Text(
          brand.name,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox(
          width: brand.logoWidth,
          height: brand.logoHeight,
          child: brand.cropLogo
              ? ClipRect(
                  child: OverflowBox(
                    maxWidth: brand.logoWidth,
                    maxHeight: double.infinity,
                    child: Image.asset(
                      brand.logoAsset!,
                      width: brand.logoWidth,
                      fit: BoxFit.fitWidth,
                    ),
                  ),
                )
              : Image.asset(brand.logoAsset!, fit: BoxFit.fill),
        ),
      ),
    );
  }
}

class _FeedbackState extends StatelessWidget {
  const _FeedbackState({this.loading = false, this.onRetry, this.message});
  final bool loading;
  final VoidCallback? onRetry;

  /// Why it failed, when the backend said so.
  final String? message;
  @override
  Widget build(BuildContext context) => _Surface(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          if (loading)
            const CircularProgressIndicator(color: AppColors.primary)
          else
            const Icon(Icons.info_outline, color: AppColors.primary, size: 32),
          const SizedBox(height: 16),
          Text(
            loading
                ? 'Menyiapkan simulasi…'
                : 'Simulasi belum dapat ditampilkan',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            loading
                ? (BackendConfig.enabled
                      ? 'Mohon tunggu sebentar.'
                      : 'Menggunakan data contoh untuk pratinjau FE.')
                : message ?? 'Silakan coba kembali.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          if (!loading)
            TextButton(onPressed: onRetry, child: const Text('Coba Lagi')),
        ],
      ),
    ),
  );
}
