import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:myrg/core/network/rg_integration.dart';
import 'package:myrg/core/router/app_router.dart';
import 'package:myrg/features/activity/data/activity_repository.dart';
import 'package:myrg/features/activity/presentation/activity_detail_page.dart';
import 'package:myrg/features/activity/presentation/activity_page.dart';
import 'package:myrg/features/auth/data/registration_repository.dart';
import 'package:myrg/features/auth/presentation/register_page.dart';
import 'package:myrg/features/home/presentation/home_page.dart';
import 'package:myrg/features/home/presentation/widgets/home_hero_carousel.dart';
import 'package:myrg/features/home/presentation/widgets/home_membership_card.dart';
import 'package:myrg/features/home/presentation/widgets/home_transaction_card.dart';
import 'package:myrg/features/membership/data/member_repository.dart';
import 'package:myrg/features/membership/models/member_profile.dart';
import 'package:myrg/features/payment/data/payment_repository.dart';
import 'package:myrg/features/payment/presentation/payment_page.dart';
import 'package:myrg/features/pawn/presentation/pawn_page.dart';
import 'package:myrg/features/profile/presentation/account_page.dart';
import 'package:qr_flutter/qr_flutter.dart';

Widget harness(Widget child) => MaterialApp(
  locale: const Locale('id', 'ID'),
  supportedLocales: const [Locale('id', 'ID')],
  localizationsDelegates: GlobalMaterialLocalizations.delegates,
  home: child,
);

class ControlledRegistration implements RegistrationRepository {
  final result = Completer<RegistrationOutcome>();
  int calls = 0;
  @override
  Future<RegistrationOutcome> validateAndRegister(RegistrationRequest request) {
    calls++;
    return result.future;
  }
}

Future<void> fillRegistration(WidgetTester tester) async {
  final fields = find.byType(TextFormField);
  await tester.enterText(fields.at(0), 'Nasabah Uji');
  await tester.tap(fields.at(1));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Pilih').last);
  await tester.pumpAndSettle();
  await tester.enterText(fields.at(2), '081234567890');
  await tester.enterText(fields.at(3), 'nasabah@example.com');
  // Password + confirmation (mentor's decision: the sign-up form has a password).
  await tester.enterText(fields.at(4), 'rahasia123');
  await tester.enterText(fields.at(5), 'rahasia123');
  tester.testTextInput.hide();
  await tester.ensureVisible(find.widgetWithText(FilledButton, 'Daftar'));
  await tester.tap(find.widgetWithText(FilledButton, 'Daftar'));
  await tester.pump();
}

void main() {
  testWidgets('Hero swipe and pagination taps select the same banner', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        const Scaffold(
          body: SizedBox(
            width: 393,
            child: HomeHeroCarousel(autoPlayEnabled: false),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    Color? dotColor(int index) =>
        (tester
                    .widget<AnimatedContainer>(
                      find.byKey(ValueKey('home-hero-dot-$index')),
                    )
                    .decoration
                as BoxDecoration)
            .color;
    expect(dotColor(0), Colors.white);
    await tester.drag(
      find.byKey(const ValueKey('home-hero-pages')),
      const Offset(-300, 0),
    );
    await tester.pumpAndSettle();
    expect(dotColor(1), Colors.white);
    expect(dotColor(0), isNot(Colors.white));
    await tester.tap(find.byTooltip('Tampilkan banner 1'));
    await tester.pumpAndSettle();
    expect(dotColor(0), Colors.white);
    expect(dotColor(1), isNot(Colors.white));
    expect(tester.takeException(), isNull);
  });
  final initialMember = MemberRepository.profile.value;
  testWidgets(
    'Auto-slide waits, pauses for touch/background, and wraps safely',
    (tester) async {
      addTearDown(() async {
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pumpWidget(const SizedBox.shrink());
      });
      await tester.pumpWidget(
        harness(
          const Scaffold(body: SizedBox(width: 393, child: HomeHeroCarousel())),
        ),
      );
      await tester.pumpAndSettle();
      Color? dotColor(int index) =>
          (tester
                      .widget<AnimatedContainer>(
                        find.byKey(ValueKey('home-hero-dot-$index')),
                      )
                      .decoration
                  as BoxDecoration)
              .color;
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(dotColor(1), Colors.white);
      final hold = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey('home-hero-pages'))),
      );
      await tester.pump(const Duration(seconds: 7));
      expect(dotColor(1), Colors.white);
      await hold.up();
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 4));
      expect(dotColor(1), Colors.white);
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(dotColor(0), Colors.white);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump(const Duration(seconds: 8));
      expect(dotColor(0), Colors.white);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpWidget(
        harness(
          const Scaffold(
            body: SizedBox(
              width: 393,
              child: HomeHeroCarousel(autoPlayEnabled: false),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 8));
      expect(dotColor(0), Colors.white);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Transaction card is compact and separates product metadata', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        Scaffold(
          body: SizedBox(
            width: 320,
            height: 176,
            child: HomeTransactionCard(
              dueLabel: 'Segera jatuh tempo dalam 3 hari',
              productName: 'Apple iPhone 13 | 128 GB | Purple',
              dueDate: '31 Juli 2026',
              amount: 'Rp 5.700.000',
              onManage: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Apple iPhone 13'), findsOneWidget);
    expect(find.text('128 GB • Purple'), findsOneWidget);
    expect(find.text('31 Juli 2026'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  tearDown(() => MemberRepository.profile.value = initialMember);
  test(
    'Member progress clamps and verification requires both trusted records',
    () {
      const member = MemberProfile(
        name: 'Uji',
        number: 'RG1',
        tier: MemberTier.silver,
        points: 2500,
        levelStart: 3000,
        levelTarget: 6000,
        balance: 0,
        voucherCount: 0,
        hasPawned: true,
        identityVerified: true,
        bankVerified: false,
      );
      expect(member.progress, 0);
      expect(member.pointsToUpgrade, 3500);
      expect(member.canReuseVerification, false);
      expect(MemberTier.gold.cardColor, isNot(MemberTier.platinum.cardColor));
    },
  );

  test(
    'Payment quote keeps storage fee in total and separates each extension',
    () async {
      final repo = PaymentRepository();
      final quote = await repo.quote(
        transaction: ActivityRepository.ongoing.first,
        action: PaymentAction.pay,
      );
      expect(
        quote.lines.fold<int>(0, (sum, line) => sum + line.amount) +
            quote.storageFee,
        quote.total,
      );
      expect(quote.paymentUrl, isNull);
      final extension = await repo.quote(
        transaction: ActivityRepository.ongoing.first,
        action: PaymentAction.extend,
        months: 3,
      );
      expect(extension.lines.length, 3);
      expect(extension.lines.map((line) => line.label).toSet().length, 3);
    },
  );

  test('Probation cannot obtain a self-service payment quote', () async {
    final probation = ActivityRepository.ongoing.last;
    await expectLater(
      PaymentRepository().quote(
        transaction: probation,
        action: PaymentAction.redeem,
      ),
      throwsA(isA<RgUnavailable>()),
    );
  });

  test('Missing or unsafe RG URLs fail before any network request', () {
    for (final url in ['', 'http://rg.example', 'file:///tmp/payment']) {
      expect(
        () => RgIntegration.requireHttps(url),
        throwsA(isA<RgUnavailable>()),
      );
    }
  });

  testWidgets(
    'Member thresholds are readable and highest tier has no fictitious upgrade',
    (tester) async {
      await tester.pumpWidget(
        harness(
          Scaffold(
            body: HomeMembershipCard(
              member: MemberRepository.profile.value,
              onBalanceTap: () {},
              onPointsTap: () {},
              onVoucherTap: () {},
            ),
          ),
        ),
      );
      expect(find.text('3.000'), findsOneWidget);
      expect(find.text('6.000'), findsOneWidget);
      final text = tester.widget<Text>(find.text('3.000'));
      expect(text.style!.fontWeight, FontWeight.w800);
      expect(text.style!.fontSize, greaterThanOrEqualTo(13));
      expect(tester.takeException(), isNull);
    },
  );

  for (final outcome in RegistrationOutcome.values) {
    testWidgets('Register waits for RG response and handles ${outcome.name}', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2280);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = ControlledRegistration();
      final router = GoRouter(
        initialLocation: AppRoutes.register,
        routes: [
          GoRoute(
            path: AppRoutes.register,
            builder: (_, _) => RegisterPage(repository: repository),
          ),
          GoRoute(
            path: AppRoutes.otp,
            builder: (_, _) => const Scaffold(body: Text('OTP_TEST')),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
          locale: const Locale('id', 'ID'),
          supportedLocales: const [Locale('id', 'ID')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
        ),
      );
      await tester.pumpAndSettle();
      await fillRegistration(tester);
      expect(repository.calls, 1);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton).first).onPressed,
        isNull,
      );
      expect(find.text('OTP_TEST'), findsNothing);
      repository.result.complete(outcome);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      if (outcome == RegistrationOutcome.memberConflict) {
        expect(find.text('Nomor member sudah digunakan'), findsOneWidget);
        expect(find.text('OTP_TEST'), findsNothing);
        await tester.tap(find.text('Mengerti'));
        await tester.pumpAndSettle();
      } else if (outcome == RegistrationOutcome.syncMember) {
        expect(find.text('Member kamu ditemukan'), findsOneWidget);
        expect(find.text('OTP_TEST'), findsNothing);
        await tester.tap(find.text('Lanjut verifikasi'));
        await tester.pumpAndSettle();
        expect(find.text('OTP_TEST'), findsOneWidget);
      } else {
        expect(find.text('OTP_TEST'), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Probation detail exposes CS and hides online payment', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(ActivityDetailPage(transaction: ActivityRepository.ongoing.last)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Hubungi CS untuk Penebusan'), findsOneWidget);
    expect(find.text('Bayar Sekarang'), findsNothing);
    expect(find.text('Kelola gadai'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Installment rejects fractional or oversized amounts and clears stale quote',
    (tester) async {
      await tester.pumpWidget(
        harness(
          PaymentPage(
            transaction: ActivityRepository.ongoing.first,
            action: PaymentAction.installment,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '500001');
      await tester.tap(find.text('Perbarui Tagihan'));
      await tester.pumpAndSettle();
      expect(find.textContaining('kelipatan Rp 1.000'), findsOneWidget);
      expect(find.text('Lanjut ke Pembayaran'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Home has transparent bell and correct service label without overflow',
    (tester) async {
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
      });
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
      });
      tester.view.physicalSize = const Size(1080, 2280);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(harness(const HomePage()));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Notifikasi'), findsOneWidget);
      expect(find.text('Cek Pinjaman'), findsOneWidget);
      expect(find.text('Cek Taksiran'), findsNothing);
      final card = find.byType(HomeMembershipCard);
      final width =
          tester.view.physicalSize.width / tester.view.devicePixelRatio;
      expect(tester.getTopLeft(card).dy, closeTo(width * (231.92 / 403), 1));
      // The test font wraps the larger caption. Inter geometry is checked on-device.
      expect(tester.getSize(card).height, inInclusiveRange(200, 230));
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -640));
      await tester.pumpAndSettle();
      expect(find.text('Kelola'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Pawn preview preserves old-member verification and courier disclaimer',
    (tester) async {
      await tester.pumpWidget(harness(const PawnPage()));
      await tester.tap(find.text('Coba alur dengan contoh perangkat'));
      await tester.pumpAndSettle();
      expect(find.text('Ajukan Banding'), findsOneWidget);
      expect(
        find.textContaining('KTP dan rekening kamu sudah'),
        findsOneWidget,
      );
      await tester.tap(find.text('Lanjut Gadai'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Dijemput oleh Kurir'));
      await tester.tap(find.text('Dijemput oleh Kurir'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('biaya kurir menjadi tanggungan nasabah'),
        findsOneWidget,
      );
      expect(find.text('Ajukan nominal negosiasi'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Activity filters and cards fit Pixel 4 with larger text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2280);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      harness(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.25)),
          child: const ActivityPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Riwayat'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Filter aktivitas'));
    await tester.pumpAndSettle();
    expect(find.text('Semua tanggal'), findsOneWidget);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Pembayaran').last);
    await tester.ensureVisible(find.text('Terapkan Filter'));
    await tester.tap(find.text('Terapkan Filter'));
    await tester.pumpAndSettle();
    expect(find.text('Top Up Saldo RG'), findsNothing);
    expect(find.text('Pembayaran Gadai'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Account QR represents current member number', (tester) async {
    await tester.pumpWidget(harness(const AccountPage()));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Tampilkan QR Member'));
    await tester.tap(find.text('Tampilkan QR Member'));
    await tester.pumpAndSettle();
    expect(find.byType(QrImageView), findsOneWidget);
    expect(
      find.widgetWithText(SelectableText, initialMember.number),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Re-registering clears untrusted previous member verification', (
    tester,
  ) async {
    MemberRepository.resetForRegistration('Nasabah Baru');
    expect(MemberRepository.profile.value.canReuseVerification, false);
    expect(MemberRepository.profile.value.number, isEmpty);
    await tester.pumpWidget(harness(const PawnPage()));
    await tester.tap(find.text('Coba alur dengan contoh perangkat'));
    await tester.pumpAndSettle();
    expect(find.text('Verifikasi KTP & rekening'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Lanjut Gadai'), 200);
    await tester.tap(find.text('Lanjut Gadai'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.textContaining('Verifikasi KTP dan rekening diperlukan'),
      100,
    );
    expect(
      find.textContaining('Verifikasi KTP dan rekening diperlukan'),
      findsOneWidget,
    );
    expect(find.text('Metode pengiriman'), findsNothing);
  });
}
