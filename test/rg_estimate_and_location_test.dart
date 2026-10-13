import 'package:flutter_test/flutter_test.dart';
import 'package:myrg/core/location/device_location.dart';
import 'package:myrg/features/simulation/data/catalog_valuation_repository.dart';
import 'package:myrg/shared/widgets/rg_webview_page.dart';

/// Cek Pinjaman from two sources (Raja Gadai's item list + MyRG's admin catalog) and the test
/// location used for "cabang terdekat".
void main() {
  const repository = CatalogValuationRepository();

  final catalog = [
    {
      'id': 1,
      'name': 'Handphone',
      'brands': [
        {
          'brand': 'Apple',
          'items': [
            {
              'id': 1,
              'name': 'iPhone 13',
              'minPrice': 4000000,
              'maxPrice': 6500000,
            },
          ],
        },
      ],
    },
    {
      'id': 2,
      'name': 'Emas',
      'brands': [
        {
          'brand': 'Antam',
          'items': [
            {
              'id': 9,
              'name': 'Logam Mulia 5 gram',
              'minPrice': 4500000,
              'maxPrice': 5200000,
            },
          ],
        },
      ],
    },
  ];
  final rgItems = [
    {
      'type': 'HANDPHONE',
      'name': 'Handphone',
      'brands': [
        {
          'brandId': 'O002',
          'name': 'OPPO',
          'items': [
            {
              'itemId': 'HPHIG-272',
              'name': 'FIND X8 5G',
              'variants': [
                {
                  'id': 2,
                  'label': 'RAM 16 GB • ROM 512 GB',
                  'attributes': {'ram': '16', 'rom': '512'},
                },
                {
                  'id': 3,
                  'label': 'RAM 12 GB • ROM 256 GB',
                  'attributes': {'ram': '12', 'rom': '256'},
                },
              ],
            },
          ],
        },
      ],
    },
    {'type': 'LAPTOP', 'name': 'Laptop', 'brands': <Object>[]},
  ];

  test(
    'Handphone comes from Raja Gadai, other categories from the admin catalog',
    () async {
      final categories = CatalogValuationRepository.mergeSources(
        catalog,
        rgItems,
      );

      // Admin order kept, Handphone replaced in place, RG-only Laptop added last.
      expect(categories.map((c) => c.name), ['Handphone', 'Emas', 'Laptop']);

      final phoneBrands = await repository.brands(categories[0]);
      expect(phoneBrands.map((b) => b.name), [
        'OPPO',
      ]); // not the admin catalog's Apple
      expect(
        phoneBrands.single.logoAsset,
        isNotNull,
      ); // known brand keeps its Figma logo

      final models = await repository.models(categories[0], phoneBrands.single);
      expect(models.map((m) => m.label), [
        'FIND X8 5G (RAM 16 GB • ROM 512 GB)',
        'FIND X8 5G (RAM 12 GB • ROM 256 GB)',
      ]);
      expect(models.every(CatalogValuationRepository.usesCoreRg), isTrue);

      final goldBrands = await repository.brands(categories[1]);
      final gold = await repository.models(categories[1], goldBrands.single);
      expect(CatalogValuationRepository.usesCoreRg(gold.single), isFalse);
      final result = await repository.estimate(
        categories[1],
        goldBrands.single,
        gold.single,
      );
      expect(
        (result.minimum, result.maximum),
        (4500000, 5200000),
      ); // no network needed
    },
  );

  test('without the Raja Gadai list the admin catalog still works', () {
    final categories = CatalogValuationRepository.mergeSources(catalog, null);
    expect(categories.map((c) => c.name), ['Handphone', 'Emas']);
  });

  test('the test location is read from "lat,lng" and rejects nonsense', () {
    final jakarta = DeviceLocation.parse('-6.2253, 106.8090')!;
    expect((jakarta.latitude, jakarta.longitude), (-6.2253, 106.809));
    expect(jakarta.ok, isTrue);

    expect(DeviceLocation.parse(''), isNull);
    expect(DeviceLocation.parse('jakarta'), isNull);
    expect(DeviceLocation.parse('-6.2'), isNull);
    expect(DeviceLocation.parse('120,106'), isNull); // latitude out of range
    expect(DeviceLocation.testOverride, isNull); // not set in tests
  });

  test('the webview opens https, and in debug the local backend over http', () {
    expect(rgWebviewAllows(Uri.parse('https://pay.rajagadai.id/x')), isTrue);
    // Tests run as a debug build with the default API host 10.0.2.2.
    expect(
      rgWebviewAllows(Uri.parse('http://10.0.2.2:8000/fake-checkout/p1')),
      isTrue,
    );
    expect(rgWebviewAllows(Uri.parse('http://evil.example/login')), isFalse);
    expect(rgWebviewAllows(Uri.parse('javascript:alert(1)')), isFalse);

    // A local backend's link (APP_URL=http://localhost:8000) is pointed at the API host.
    expect(
      rgWebviewLocalFix(
        Uri.parse('http://localhost:8000/fake-checkout/p1'),
      ).toString(),
      'http://10.0.2.2:8000/fake-checkout/p1',
    );
    expect(
      rgWebviewLocalFix(Uri.parse('https://pay.rajagadai.id/x')).toString(),
      'https://pay.rajagadai.id/x',
    );
  });
}
