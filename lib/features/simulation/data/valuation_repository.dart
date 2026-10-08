import '../../../core/constants/app_assets.dart';
import '../models/valuation.dart';

abstract interface class ValuationRepository {
  Future<List<ValuationBrand>> brands(ValuationCategory category);
  Future<List<ValuationModel>> models(
    ValuationCategory category,
    ValuationBrand brand,
  );
  Future<ValuationResult> estimate(
    ValuationCategory category,
    ValuationBrand brand,
    ValuationModel model,
  );
}

/// FE fixtures only. Catalog, capacities and amounts are not live offers.
class MockValuationRepository implements ValuationRepository {
  const MockValuationRepository();
  static const categories = [
    ValuationCategory('phone', 'Handphone', AppAssets.valuationPhone),
    ValuationCategory('laptop', 'Laptop', AppAssets.valuationLaptop),
    ValuationCategory('tablet', 'Tablet', AppAssets.valuationTablet),
    ValuationCategory('watch', 'Smartwatch', AppAssets.valuationWatch),
    ValuationCategory('camera', 'Kamera', AppAssets.valuationCamera),
    ValuationCategory('console', 'Game Console', AppAssets.valuationGame),
  ];
  static const _phoneBrands = [
    ValuationBrand(
      'Apple',
      popular: true,
      logoAsset: AppAssets.valuationApple,
      logoWidth: 67,
      logoHeight: 26,
    ),
    ValuationBrand(
      'Samsung',
      popular: true,
      logoAsset: AppAssets.valuationSamsung,
      logoWidth: 101,
      logoHeight: 17,
      cropLogo: true,
    ),
    ValuationBrand(
      'Xiaomi',
      popular: true,
      logoAsset: AppAssets.valuationXiaomi,
      logoWidth: 94,
      logoHeight: 33,
    ),
    ValuationBrand(
      'Huawei',
      popular: true,
      logoAsset: AppAssets.valuationHuawei,
      logoWidth: 78,
      logoHeight: 22,
    ),
    ValuationBrand(
      'OPPO',
      popular: true,
      logoAsset: AppAssets.valuationOppo,
      logoWidth: 66,
      logoHeight: 16,
      cropLogo: true,
    ),
    ValuationBrand(
      'vivo',
      popular: true,
      logoAsset: AppAssets.valuationVivo,
      logoWidth: 56,
      logoHeight: 16,
    ),
    ValuationBrand('ASUS'),
    ValuationBrand('Google'),
    ValuationBrand('HONOR'),
    ValuationBrand('Infinix'),
  ];

  @override
  Future<List<ValuationBrand>> brands(ValuationCategory category) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return switch (category.id) {
      'phone' || 'tablet' || 'watch' => _phoneBrands,
      'laptop' => [
        _phoneBrands[0],
        _phoneBrands[1],
        const ValuationBrand('ASUS', popular: true),
        const ValuationBrand('Acer'),
        const ValuationBrand('HP'),
        const ValuationBrand('Lenovo'),
      ],
      'camera' => const [
        ValuationBrand('Canon', popular: true),
        ValuationBrand('Sony', popular: true),
        ValuationBrand('Nikon', popular: true),
        ValuationBrand('Fujifilm'),
        ValuationBrand('Panasonic'),
      ],
      _ => const [
        ValuationBrand('Sony', popular: true),
        ValuationBrand('Nintendo', popular: true),
        ValuationBrand('Microsoft'),
      ],
    };
  }

  @override
  Future<List<ValuationModel>> models(
    ValuationCategory category,
    ValuationBrand brand,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (category.id == 'phone' && brand.name == 'Apple') {
      return const [
        ValuationModel('iPhone 17 Pro Max', '256 GB'),
        ValuationModel('iPhone 17 Pro', '256 GB'),
        ValuationModel('iPhone 17', '256 GB'),
        ValuationModel('iPhone Air', '256 GB'),
        ValuationModel('iPhone 16 Pro Max', '256 GB'),
        ValuationModel('iPhone 16 Pro', '128 GB'),
        ValuationModel('iPhone 16 Plus', '128 GB'),
        ValuationModel('iPhone 16', '128 GB'),
        ValuationModel(
          'iPhone 13',
          '128 GB',
          imageAsset: AppAssets.valuationIphone,
        ),
      ];
    }
    final names = switch (category.id) {
      'phone' => switch (brand.name) {
        'Samsung' => ['Galaxy S24', 'Galaxy A55'],
        'Xiaomi' => ['14', 'Redmi Note 13'],
        'Google' => ['Pixel 8', 'Pixel 7'],
        'ASUS' => ['Zenfone 10', 'ROG Phone 8'],
        _ => ['Model A', 'Model B'],
      },
      'laptop' =>
        brand.name == 'Apple'
            ? ['MacBook Air', 'MacBook Pro']
            : ['Laptop Series A', 'Laptop Series B'],
      'tablet' =>
        brand.name == 'Apple'
            ? ['iPad Air', 'iPad Pro']
            : ['Tablet Series A', 'Tablet Series B'],
      'watch' =>
        brand.name == 'Apple'
            ? ['Watch Series 9', 'Watch SE']
            : ['Watch Series A', 'Watch Series B'],
      'camera' => ['Camera Series A', 'Camera Series B'],
      _ => switch (brand.name) {
        'Sony' => ['PlayStation 5', 'PlayStation 4'],
        'Nintendo' => ['Switch', 'Switch OLED'],
        _ => ['Xbox Series S', 'Xbox Series X'],
      },
    };
    final variant = switch (category.id) {
      'phone' || 'tablet' => '128 GB',
      'laptop' => '8 GB RAM • 256 GB SSD',
      _ => 'Varian standar',
    };
    return names.map((name) => ValuationModel(name, variant)).toList();
  }

  @override
  Future<ValuationResult> estimate(
    ValuationCategory category,
    ValuationBrand brand,
    ValuationModel model,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return ValuationResult(
      category: category,
      brand: brand,
      model: model,
      minimum: 4500000,
      maximum: 5200000,
    );
  }
}
