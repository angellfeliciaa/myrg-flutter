import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:myrg/core/router/app_router.dart';
import 'package:myrg/features/home/presentation/home_page.dart';
import 'package:myrg/features/pawn/presentation/pawn_page.dart';
import 'package:myrg/features/simulation/data/valuation_repository.dart';
import 'package:myrg/features/simulation/models/valuation.dart';
import 'package:myrg/features/simulation/presentation/simulation_page.dart';

Widget harness({
  ValuationRepository repository = const MockValuationRepository(),
}) => MaterialApp(home: SimulationPage(repository: repository));

Future<void> settleMock(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 700));
  await tester.pumpAndSettle();
}

Future<void> chooseApple(WidgetTester tester) async {
  await tester.tap(find.text('Handphone'));
  await settleMock(tester);
  await tester.tap(find.byKey(const ValueKey('valuation-brand-Apple')));
  await settleMock(tester);
}

class FailingBrandsRepository extends MockValuationRepository {
  int attempts = 0;
  @override
  Future<List<ValuationBrand>> brands(ValuationCategory category) async {
    if (attempts++ == 0) throw StateError('Simulated failure');
    return super.brands(category);
  }
}

class PendingBrandsRepository extends MockValuationRepository {
  final pending = Completer<List<ValuationBrand>>();
  @override
  Future<List<ValuationBrand>> brands(ValuationCategory category) =>
      pending.future;
}

void main() {
  testWidgets('All six categories match Figma and open their own catalogs', (
    tester,
  ) async {
    await tester.pumpWidget(harness());
    expect(find.text('Pilih Kategori Barang'), findsOneWidget);
    for (final category in MockValuationRepository.categories) {
      await tester.ensureVisible(find.text(category.name));
      await tester.tap(find.text(category.name));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await settleMock(tester);
      expect(find.text('Pilih Merk Perangkat'), findsOneWidget);
      expect(
        find.text('Pilih merk ${category.name.toLowerCase()} anda'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('simulation-back')));
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Search is case insensitive, clearable and survives back navigation',
    (tester) async {
      await tester.pumpWidget(harness());
      await tester.tap(find.text('Handphone'));
      await settleMock(tester);
      await tester.enterText(find.byType(TextField), ' aPpLe ');
      await tester.pumpAndSettle();
      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('ASUS'), findsNothing);
      await tester.tap(find.text('Apple'));
      await settleMock(tester);
      await tester.enterText(find.byType(TextField), 'IPHONE 13');
      await tester.pumpAndSettle();
      await tester.tap(find.text('iPhone 13'));
      await settleMock(tester);
      expect(find.text('Apple iPhone 13'), findsOneWidget);
      expect(find.text('128 GB'), findsOneWidget);
      expect(find.text('Rp 4.500.000'), findsOneWidget);
      expect(find.textContaining('Simulasi FE'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('simulation-back')));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'IPHONE 13',
      );
      await tester.tap(find.byKey(const ValueKey('simulation-back')));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        ' aPpLe ',
      );
      await tester.tap(find.byTooltip('Hapus pencarian'));
      await tester.pumpAndSettle();
      expect(find.text('Merk Popular'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Empty search and Cek Ulang reset cleanly', (tester) async {
    await tester.pumpWidget(harness());
    await chooseApple(tester);
    await tester.enterText(find.byType(TextField), 'not-in-catalog');
    await tester.pumpAndSettle();
    expect(find.text('Model tidak ditemukan'), findsOneWidget);
    await tester.tap(find.text('Hapus pencarian'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('iPhone 17 Pro Max'));
    await settleMock(tester);
    expect(find.text('Apple iPhone 17 Pro Max'), findsOneWidget);
    await tester.tap(find.text('Cek Ulang'));
    await tester.pumpAndSettle();
    expect(find.text('Pilih Kategori Barang'), findsOneWidget);
    await tester.tap(find.text('Laptop'));
    await settleMock(tester);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
    expect(find.text('HP'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Failed mock load can retry without losing the category', (
    tester,
  ) async {
    await tester.pumpWidget(harness(repository: FailingBrandsRepository()));
    await tester.tap(find.text('Tablet'));
    await tester.pumpAndSettle();
    expect(find.text('Simulasi belum dapat ditampilkan'), findsOneWidget);
    await tester.tap(find.text('Coba Lagi'));
    await settleMock(tester);
    expect(find.text('Pilih merk tablet anda'), findsOneWidget);
    expect(find.text('Merk Popular'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Back during loading ignores a late response', (tester) async {
    final repository = PendingBrandsRepository();
    await tester.pumpWidget(harness(repository: repository));
    await tester.tap(find.text('Handphone'));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('simulation-back')));
    await tester.pumpAndSettle();
    repository.pending.complete(const [ValuationBrand('Late response')]);
    await tester.pumpAndSettle();
    expect(find.text('Pilih Kategori Barang'), findsOneWidget);
    expect(find.text('Late response'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Small screen and large text keep list and footer usable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.4)),
          child: child!,
        ),
        home: const SimulationPage(),
      ),
    );
    await chooseApple(tester);
    await tester.tap(find.text('iPhone 17 Pro Max'));
    await settleMock(tester);
    expect(find.text('Lanjut Gadai').hitTestable(), findsOneWidget);
    expect(find.text('Cek Ulang').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Home opens simulation and selection reaches pawn without bypassing checks',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2280);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          GoRoute(path: '/home', builder: (_, _) => const HomePage()),
          GoRoute(
            path: AppRoutes.simulation,
            builder: (_, _) => const SimulationPage(),
          ),
          GoRoute(
            path: AppRoutes.pawn,
            builder: (_, state) =>
                PawnPage(estimate: state.extra as ValuationResult),
          ),
        ],
      );
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        router.dispose();
      });
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Cek Pinjaman'));
      await tester.tap(find.text('Cek Pinjaman'));
      await tester.pumpAndSettle();
      expect(find.text('Pilih Kategori Barang'), findsOneWidget);
      await chooseApple(tester);
      await tester.tap(find.text('iPhone 17 Pro Max'));
      await settleMock(tester);
      await tester.tap(find.text('Lanjut Gadai'));
      await tester.pumpAndSettle();
      expect(find.text('Apple iPhone 17 Pro Max'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Mulai Pemeriksaan Perangkat'), 200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Mulai Pemeriksaan Perangkat'), findsOneWidget);
      expect(find.text('Verifikasi pengajuan'), findsNothing);
      await tester.scrollUntilVisible(
        find.text('Coba alur dengan contoh perangkat'), 150,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('Coba alur dengan contoh perangkat'));
      await tester.pumpAndSettle();
      expect(find.text('Apple iPhone 17 Pro Max • 256 GB'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
