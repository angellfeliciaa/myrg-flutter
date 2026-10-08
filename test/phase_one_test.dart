import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:myrg/core/router/app_router.dart';
import 'package:myrg/features/auth/data/demo_session.dart';
import 'package:myrg/features/auth/presentation/pin_page.dart';
import 'package:myrg/features/auth/presentation/login_page.dart';
import 'package:myrg/features/auth/presentation/otp_page.dart';
import 'package:myrg/features/auth/presentation/create_pin_page.dart';
import 'package:myrg/features/auth/presentation/confirm_pin_page.dart';
import 'package:myrg/features/branch/data/branch_repository.dart';
import 'package:myrg/features/branch/models/branch.dart';
import 'package:myrg/features/branch/presentation/branch_page.dart';
import 'package:myrg/features/branch/presentation/branch_detail_page.dart';
import 'package:myrg/features/profile/presentation/change_password_page.dart';
import 'package:myrg/features/profile/presentation/account_page.dart';
import 'package:myrg/features/profile/presentation/security_page.dart';
import 'package:myrg/features/activity/data/activity_repository.dart';
import 'package:myrg/features/activity/presentation/activity_detail_page.dart';
import 'package:myrg/features/activity/presentation/pawn_document_page.dart';
import 'package:myrg/features/activity/models/activity_transaction.dart';
import 'package:myrg/features/payment/presentation/installment_input_page.dart';

Widget harness(Widget page) => MaterialApp(home: page);
void pixelSize(WidgetTester tester, {bool large = false}) {
  tester.view.physicalSize = large
      ? const Size(320, 640)
      : const Size(1080, 2280);
  tester.view.devicePixelRatio = large ? 1 : 2.75;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> mockSettle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 700));
  await tester.pumpAndSettle();
}

class RetryBranches extends BranchRepository {
  int calls = 0;
  @override
  Future<List<Branch>> load() async {
    if (calls++ == 0) throw StateError('Demo error');
    return super.load();
  }
}

void main() {
  setUp(DemoSession.reset);
  tearDown(DemoSession.reset);
  testWidgets(
    'OTP and matching PIN complete registration without accepting wrong codes',
    (tester) async {
      pixelSize(tester);
      final router = GoRouter(
        initialLocation: AppRoutes.otp,
        routes: [
          GoRoute(
            path: AppRoutes.otp,
            builder: (_, _) => const OtpPage(phoneNumber: '081234567890'),
          ),
          GoRoute(
            path: AppRoutes.createPin,
            builder: (_, _) => const CreatePinPage(),
          ),
          GoRoute(
            path: AppRoutes.confirmPin,
            builder: (_, state) =>
                ConfirmPinPage(createdPin: state.extra! as String),
          ),
          GoRoute(
            path: AppRoutes.home,
            builder: (_, _) => const Scaffold(body: Text('Registered')),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.enterText(find.byType(TextField), '999999');
      tester.testTextInput.hide();
      await tester.ensureVisible(find.text('Konfirmasi'));
      await tester.tap(find.text('Konfirmasi'));
      await tester.pumpAndSettle();
      expect(
        find.text('Kode OTP demo tidak sesuai. Gunakan 123456.'),
        findsOneWidget,
      );
      expect(find.byType(CreatePinPage), findsNothing);
      await tester.enterText(find.byType(TextField), '123456');
      tester.testTextInput.hide();
      await tester.tap(find.text('Konfirmasi'));
      await tester.pumpAndSettle();
      expect(find.byType(CreatePinPage), findsOneWidget);
      for (final digit in '654321'.split('')) {
        await tester.tap(find.text(digit));
      }
      await tester.pumpAndSettle();
      expect(find.byType(ConfirmPinPage), findsOneWidget);
      for (int index = 0; index < 6; index++) {
        await tester.tap(find.text('5'));
      }
      await tester.pumpAndSettle();
      expect(
        find.text('PIN tidak sama. Silakan masukkan kembali.'),
        findsOneWidget,
      );
      expect(DemoSession.authenticated, isFalse);
      for (final digit in '654321'.split('')) {
        await tester.tap(find.text(digit));
      }
      await tester.pumpAndSettle();
      expect(find.text('Registered'), findsOneWidget);
      expect(DemoSession.authenticated, isTrue);
      expect(
        await tester.runAsync(() => DemoSession.verifyPin('123456')),
        isFalse,
      );
      expect(
        await tester.runAsync(() => DemoSession.verifyPin('654321')),
        isTrue,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'PIN rejects wrong digits and only unlocks after six correct digits',
    (tester) async {
      pixelSize(tester);
      final router = GoRouter(
        initialLocation: '/pin',
        routes: [
          GoRoute(path: '/pin', builder: (_, _) => const PinPage()),
          GoRoute(
            path: '/home',
            builder: (_, _) => const Scaffold(body: Text('Unlocked')),
          ),
          GoRoute(
            path: '/login',
            builder: (_, _) => const Scaffold(body: Text('Login')),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      for (int i = 0; i < 6; i++) {
        await tester.tap(find.text('9'));
      }
      await mockSettle(tester);
      expect(find.text('PIN salah. Silakan coba kembali.'), findsOneWidget);
      expect(find.text('Unlocked'), findsNothing);
      for (final digit in '12345'.split('')) {
        await tester.tap(find.text(digit));
      }
      await tester.pump();
      expect(find.text('Unlocked'), findsNothing);
      await tester.tap(find.text('6'));
      await mockSettle(tester);
      expect(find.text('Unlocked'), findsOneWidget);
      expect(DemoSession.authenticated, isTrue);
      expect(tester.takeException(), isNull);
    },
  );
  test(
    'PIN created in demo replaces its default without persistence',
    () async {
      DemoSession.createPin('654321');
      expect(await DemoSession.verifyPin('123456'), isFalse);
      expect(await DemoSession.verifyPin('654321'), isTrue);
    },
  );
  testWidgets('Login displays a failed mock response and social cancellation', (
    tester,
  ) async {
    pixelSize(tester);
    await tester.pumpWidget(harness(const LoginPage()));
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'demo@example.com');
    await tester.enterText(fields.at(1), 'wrongpassword');
    tester.testTextInput.hide();
    await tester.ensureVisible(find.text('Masuk'));
    await tester.tap(find.text('Masuk'));
    await mockSettle(tester);
    expect(find.text('Password akun demo tidak sesuai.'), findsOneWidget);
    await tester.ensureVisible(find.text('Lanjutkan dengan Google'));
    await tester.tap(find.text('Lanjutkan dengan Google'));
    await tester.pumpAndSettle();
    expect(find.text('Demo login Google'), findsOneWidget);
    await tester.tap(find.text('Simulasi Gagal'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Login Google dibatalkan'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Change password validates confirmation and wrong old password', (
    tester,
  ) async {
    pixelSize(tester);
    await tester.pumpWidget(harness(const ChangePasswordPage()));
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'wrongold');
    await tester.enterText(fields.at(1), 'newpassword123');
    await tester.enterText(fields.at(2), 'different');
    tester.testTextInput.hide();
    await tester.tap(find.text('Simpan Password'));
    await tester.pumpAndSettle();
    expect(find.text('Konfirmasi password tidak sama.'), findsOneWidget);
    await tester.enterText(fields.at(2), 'newpassword123');
    tester.testTextInput.hide();
    await tester.tap(find.text('Simpan Password'));
    await mockSettle(tester);
    expect(
      find.text('Password lama tidak sesuai dengan akun demo.'),
      findsOneWidget,
    );
    expect(
      await tester.runAsync(() => DemoSession.login('password123')),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets('Valid change password updates only the in-memory demo', (
    tester,
  ) async {
    pixelSize(tester);
    await tester.pumpWidget(harness(const ChangePasswordPage()));
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'password123');
    await tester.enterText(fields.at(1), 'newpassword123');
    await tester.enterText(fields.at(2), 'newpassword123');
    tester.testTextInput.hide();
    await tester.tap(find.text('Simpan Password'));
    await mockSettle(tester);
    expect(find.text('Password demo diperbarui'), findsOneWidget);
    expect(
      await tester.runAsync(() => DemoSession.login('password123')),
      isFalse,
    );
    expect(
      await tester.runAsync(() => DemoSession.login('newpassword123')),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'Branch search, empty state and radius filter work with mock data',
    (tester) async {
      pixelSize(tester);
      await tester.pumpWidget(harness(const BranchPage()));
      await mockSettle(tester);
      expect(find.text('Raja Gadai Tebet'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'MENTENG');
      await tester.pumpAndSettle();
      expect(find.text('Raja Gadai Menteng'), findsOneWidget);
      expect(find.text('Raja Gadai Tebet'), findsNothing);
      await tester.enterText(find.byType(TextField), 'not-found');
      await tester.pumpAndSettle();
      expect(find.text('Cabang tidak ditemukan'), findsOneWidget);
      await tester.tap(find.text('Reset pencarian'));
      tester.testTextInput.hide();
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Filter cabang'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('2 km'));
      await tester.tap(find.text('Terapkan Filter'));
      await tester.pumpAndSettle();
      expect(find.text('Raja Gadai Tebet'), findsOneWidget);
      expect(find.text('Raja Gadai Kemang'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Branch retry loads fixtures after failure', (tester) async {
    await tester.pumpWidget(harness(BranchPage(repository: RetryBranches())));
    await tester.pumpAndSettle();
    expect(find.text('Cabang belum dapat ditampilkan'), findsOneWidget);
    await tester.tap(find.text('Coba Lagi'));
    await mockSettle(tester);
    expect(find.text('Raja Gadai Tebet'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'Branch detail preserves selected address and opens mock map/contact',
    (tester) async {
      pixelSize(tester);
      final branch = BranchRepository.fixtures[1];
      await tester.pumpWidget(harness(BranchDetailPage(branch: branch)));
      expect(find.text(branch.address), findsOneWidget);
      await tester.tap(find.text('Buka Peta'));
      await tester.pumpAndSettle();
      expect(find.byType(InteractiveViewer), findsOneWidget);
      await tester.tap(find.text('Tutup Peta'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hubungi Cabang'));
      await tester.pumpAndSettle();
      expect(find.textContaining('tidak ada panggilan'), findsOneWidget);
      await tester.tap(find.text('Simulasikan Panggilan'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Tidak menghubungi cabang'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Pawn document and installment action are accessible from detail',
    (tester) async {
      pixelSize(tester);
      await tester.pumpWidget(
        harness(
          ActivityDetailPage(transaction: ActivityRepository.ongoing.first),
        ),
      );
      expect(find.text('Detail Gadai'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('DEMO-SBG-77123'), 160);
      await tester.ensureVisible(find.text('DEMO-SBG-77123'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('DEMO-SBG-77123'));
      await tester.pumpAndSettle();
      expect(find.byType(PawnDocumentPage), findsOneWidget);
      expect(find.textContaining('Bukan PDF'), findsOneWidget);
      await tester.tap(find.byTooltip('Kembali'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Cicil Pokok'), 160);
      await tester.ensureVisible(find.text('Cicil Pokok'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cicil Pokok'));
      await tester.pumpAndSettle();
      expect(find.byType(InstallmentInputPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Installment percentages validate and never alter the transaction',
    (tester) async {
      pixelSize(tester);
      final transaction = ActivityRepository.ongoing.first;
      await tester.pumpWidget(
        harness(InstallmentInputPage(transaction: transaction)),
      );
      await tester.tap(find.text('30%'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField))
            .controller!
            .text,
        '1.260.000',
      );
      await tester.tap(find.text('Cicil'));
      await tester.pumpAndSettle();
      expect(find.text('Pratinjau Cicilan Pokok'), findsOneWidget);
      expect(transaction.pawn!.principal, 4200000);
      await tester.tap(find.text('Kembali ke Input'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), '99000000');
      tester.testTextInput.hide();
      await tester.tap(find.text('Cicil'));
      await tester.pumpAndSettle();
      expect(find.textContaining('melebihi sisa pokok'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Failed transaction has a reason and no installment actions', (
    tester,
  ) async {
    pixelSize(tester);
    final failed = ActivityRepository.history.firstWhere(
      (t) => t.status == ActivityStatus.failed,
    );
    await tester.pumpWidget(harness(ActivityDetailPage(transaction: failed)));
    expect(find.text('Alasan Transaksi Gagal'), findsOneWidget);
    expect(find.text(failed.failureReason!), findsOneWidget);
    expect(find.text('Cicil Pokok'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Account navigates to security/password and confirms logout', (
    tester,
  ) async {
    pixelSize(tester);
    final router = GoRouter(
      initialLocation: '/account',
      routes: [
        GoRoute(path: '/account', builder: (_, _) => const AccountPage()),
        GoRoute(
          path: AppRoutes.security,
          builder: (_, _) => const SecurityPage(),
        ),
        GoRoute(
          path: AppRoutes.changePassword,
          builder: (_, _) => const ChangePasswordPage(),
        ),
        GoRoute(
          path: '/login',
          builder: (_, _) => const Scaffold(body: Text('Logged out')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.ensureVisible(find.text('Keamanan Akun'));
    await tester.tap(find.text('Keamanan Akun'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ganti Password'));
    await tester.pumpAndSettle();
    expect(find.byType(ChangePasswordPage), findsOneWidget);
    await tester.tap(find.byTooltip('Kembali'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Kembali'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Keluar Akun'));
    await tester.tap(find.text('Keluar Akun'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Keluar'));
    await tester.pumpAndSettle();
    expect(find.text('Logged out'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('New screens fit small devices with larger text', (tester) async {
    pixelSize(tester, large: true);
    for (final page in <Widget>[
      const PinPage(),
      const AccountPage(),
      const BranchPage(),
      BranchDetailPage(branch: BranchRepository.fixtures.first),
      const SecurityPage(),
      const ChangePasswordPage(),
      InstallmentInputPage(transaction: ActivityRepository.ongoing.first),
      ActivityDetailPage(transaction: ActivityRepository.ongoing.first),
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.4)),
            child: child!,
          ),
          home: page,
        ),
      );
      await mockSettle(tester);
      expect(
        tester.takeException(),
        isNull,
        reason: page.runtimeType.toString(),
      );
    }
  });
}
