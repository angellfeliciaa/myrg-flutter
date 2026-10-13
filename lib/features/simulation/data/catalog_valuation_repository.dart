import '../../../core/constants/app_assets.dart';
import '../../../core/network/myrg_api.dart';
import '../models/valuation.dart';
import 'valuation_repository.dart';

/// Backend mode, two sources behind one screen:
/// - Raja Gadai's item list (GET /valuations/rg-items): Handphone and Laptop with RG's brand /
///   item codes and variants. The range comes from Core RG (POST /valuations/estimate): needs
///   login and uses one of the member's daily taksiran slots.
/// - MyRG's catalog (GET /catalog/categories): every other category, with the min/max price
///   set by MyRG admin. No login, no quota.
/// A category in both lists is taken from Raja Gadai.
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
    final results = await Future.wait([
      MyrgApi.get('/catalog/categories', auth: false),
      // Optional: without RG's list the admin catalog still works.
      MyrgApi.get(
        '/valuations/rg-items',
        auth: false,
      ).then<Object?>((v) => v, onError: (_) => null),
    ]);
    final categories = mergeSources(results[0], results[1]);
    _cache = (DateTime.now(), categories);
    return categories;
  }

  /// Admin catalog first (its order), each category replaced by Raja Gadai's when RG has the
  /// same one; RG categories the admin catalog lacks are added at the end.
  static List<ValuationCategory> mergeSources(
    Object? catalog,
    Object? rgItems,
  ) {
    final fromRg = <String, _CatalogCategory>{
      for (final t in rgItems as List? ?? const [])
        if (t is Map)
          '${t['name'] ?? ''}'.toLowerCase(): _CatalogCategory.fromRg(
            Map<String, dynamic>.from(t),
          ),
    };
    final merged = <ValuationCategory>[
      for (final c in catalog as List? ?? const [])
        if (c is Map)
          fromRg.remove('${c['name'] ?? ''}'.toLowerCase()) ??
              _CatalogCategory.fromApi(Map<String, dynamic>.from(c)),
    ];
    return [...merged, ...fromRg.values];
  }

  /// True when the range for [model] is computed by Core RG (login + daily quota).
  static bool usesCoreRg(ValuationModel model) => model is _RgModel;

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
    if (model is _RgModel) {
      final data = Map<String, dynamic>.from(
        await MyrgApi.post(
              '/valuations/estimate',
              body: {
                'brandId': model.brandId,
                'itemId': model.itemId,
                'attributes': model.attributes,
              },
            )
            as Map,
      );
      return ValuationResult(
        category: category,
        brand: brand,
        model: model,
        minimum: (data['minAmount'] as num? ?? 0).toInt(),
        maximum: (data['maxAmount'] as num? ?? 0).toInt(),
      );
    }
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

  /// One type of Raja Gadai's item list: brands -> models, one entry per variant.
  factory _CatalogCategory.fromRg(Map<String, dynamic> json) {
    final name = '${json['name'] ?? ''}';
    return _CatalogCategory(
      'rg-${json['type']}',
      name,
      CatalogValuationRepository.iconFor(name),
      [
        for (final b in json['brands'] as List? ?? const [])
          if (b is Map)
            _CatalogBrand.named('${b['name'] ?? ''}', [
              for (final i in b['items'] as List? ?? const [])
                if (i is Map)
                  for (final v in i['variants'] as List? ?? const [])
                    if (v is Map)
                      _RgModel(
                        '${i['name'] ?? ''}',
                        '${v['label'] ?? ''}',
                        brandId: '${b['brandId']}',
                        itemId: '${i['itemId']}',
                        attributes: {
                          for (final a
                              in (v['attributes'] as Map? ?? const {}).entries)
                            '${a.key}': '${a.value}',
                        },
                      ),
            ]),
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

  factory _CatalogBrand.fromApi(Map<String, dynamic> json, String category) {
    final name = '${json['brand'] ?? ''}';
    final models = <ValuationModel>[
      for (final i in json['items'] as List? ?? const [])
        if (i is Map)
          _CatalogModel(
            '${i['name'] ?? ''}',
            category,
            minimum: (i['minPrice'] as num? ?? 0).toInt(),
            maximum: (i['maxPrice'] as num? ?? 0).toInt(),
          ),
    ];
    return _CatalogBrand.named(name, models);
  }

  /// Reuses the Figma logo (and "popular" spot) when the brand is one of the known ones.
  factory _CatalogBrand.named(String name, List<ValuationModel> models) {
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

  final List<ValuationModel> models;
}

/// One variant of a Raja Gadai item, e.g. FIND X8 5G with RAM 12 GB / ROM 256 GB.
class _RgModel extends ValuationModel {
  _RgModel(
    super.name,
    super.variant, {
    required this.brandId,
    required this.itemId,
    required this.attributes,
  }) : super(listLabel: variant.isEmpty ? null : '$name ($variant)');
  final String brandId, itemId;
  final Map<String, String> attributes;
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
