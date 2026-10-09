import '../../../core/constants/app_assets.dart';
import '../../../core/network/myrg_api.dart';
import '../models/valuation.dart';
import 'valuation_repository.dart';

/// Backend mode: the simulation reads MyRG's catalog (GET /catalog/categories, Figma name
/// /valuation/type). Categories, brands, models and the min/max price are managed by MyRG
/// admin, so this needs no login and does not use the member's daily taksiran quota.
class CatalogValuationRepository implements ValuationRepository {
  const CatalogValuationRepository();

  static (DateTime, List<ValuationCategory>)? _cache;

  /// The catalog changes only when admin edits it: one download per 10 minutes.
  @override
  Future<List<ValuationCategory>> loadCategories() async {
    final cached = _cache;
    if (cached != null &&
        DateTime.now().difference(cached.$1) < const Duration(minutes: 10)) {
      return cached.$2;
    }
    final data = await MyrgApi.get('/catalog/categories', auth: false);
    final categories = [
      for (final c in data as List? ?? const [])
        if (c is Map) _CatalogCategory.fromApi(Map<String, dynamic>.from(c)),
    ];
    _cache = (DateTime.now(), categories);
    return categories;
  }

  @override
  Future<List<ValuationBrand>> brands(ValuationCategory category) async =>
      category is _CatalogCategory ? category.brands : const [];

  @override
  Future<List<ValuationModel>> models(
    ValuationCategory category,
    ValuationBrand brand,
  ) async => brand is _CatalogBrand ? brand.models : const [];

  @override
  Future<ValuationResult> estimate(
    ValuationCategory category,
    ValuationBrand brand,
    ValuationModel model,
  ) async {
    final item = model as _CatalogModel;
    return ValuationResult(
      category: category,
      brand: brand,
      model: model,
      minimum: item.minimum,
      maximum: item.maximum,
    );
  }

  /// Icons exist only for the Figma categories; anything new admin adds gets the phone icon.
  static String iconFor(String name) {
    final n = name.toLowerCase();
    if (n.contains('laptop')) return AppAssets.valuationLaptop;
    if (n.contains('tablet') || n.contains('ipad')) {
      return AppAssets.valuationTablet;
    }
    if (n.contains('watch') || n.contains('jam')) {
      return AppAssets.valuationWatch;
    }
    if (n.contains('kamera') || n.contains('camera')) {
      return AppAssets.valuationCamera;
    }
    if (n.contains('game') || n.contains('konsol') || n.contains('console')) {
      return AppAssets.valuationGame;
    }
    return AppAssets.valuationPhone;
  }
}

class _CatalogCategory extends ValuationCategory {
  _CatalogCategory(super.id, super.name, super.iconAsset, this.brands);

  factory _CatalogCategory.fromApi(Map<String, dynamic> json) {
    final name = '${json['name'] ?? ''}';
    return _CatalogCategory(
      '${json['id']}',
      name,
      CatalogValuationRepository.iconFor(name),
      [
        for (final b in json['brands'] as List? ?? const [])
          if (b is Map)
            _CatalogBrand.fromApi(Map<String, dynamic>.from(b), name),
      ],
    );
  }

  final List<_CatalogBrand> brands;
}

class _CatalogBrand extends ValuationBrand {
  _CatalogBrand(
    super.name, {
    required this.models,
    super.popular,
    super.logoAsset,
    super.logoWidth,
    super.logoHeight,
    super.cropLogo,
  });

  /// Reuses the Figma logo (and "popular" spot) when the brand is one of the known ones.
  factory _CatalogBrand.fromApi(Map<String, dynamic> json, String category) {
    final name = '${json['brand'] ?? ''}';
    final models = [
      for (final i in json['items'] as List? ?? const [])
        if (i is Map)
          _CatalogModel(
            '${i['name'] ?? ''}',
            category,
            minimum: (i['minPrice'] as num? ?? 0).toInt(),
            maximum: (i['maxPrice'] as num? ?? 0).toInt(),
          ),
    ];
    final known = MockValuationRepository.knownBrands
        .where((b) => b.name.toLowerCase() == name.toLowerCase())
        .firstOrNull;
    return known == null
        ? _CatalogBrand(name, models: models)
        : _CatalogBrand(
            name,
            models: models,
            popular: known.popular,
            logoAsset: known.logoAsset,
            logoWidth: known.logoWidth,
            logoHeight: known.logoHeight,
            cropLogo: known.cropLogo,
          );
  }

  final List<_CatalogModel> models;
}

class _CatalogModel extends ValuationModel {
  const _CatalogModel(
    super.name,
    super.variant, {
    required this.minimum,
    required this.maximum,
  });
  final int minimum, maximum;
}
