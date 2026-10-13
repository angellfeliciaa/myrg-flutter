import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:myrg/core/router/app_router.dart';
import 'package:myrg/features/auth/data/demo_session.dart';
import 'package:myrg/features/membership/data/member_repository.dart';
import 'package:myrg/features/profile/data/profile_photo_picker.dart';
import 'package:myrg/features/profile/presentation/account_page.dart';
import 'package:myrg/features/profile/presentation/edit_account_page.dart';
import 'package:myrg/features/profile/presentation/widgets/profile_avatar.dart';
import 'package:myrg/features/home/presentation/widgets/home_bottom_navigation.dart';

class FakePhotoPicker implements ProfilePhotoPicker {
  Uint8List? result;
  bool fails = false;
  @override
  Future<Uint8List?> recover() async => null;
  @override
  Future<Uint8List?> pick() async {
    if (fails) throw const FormatException('File foto tidak dapat dibaca.');
    return result;
  }
}

void main() {
  final initialMember = MemberRepository.profile.value;
  setUp(() {
    MemberRepository.profile.value = initialMember;
    DemoSession.reset();
  });
  tearDown(() {
    MemberRepository.profile.value = initialMember;
    DemoSession.reset();
  });

  Future<GoRouter> open(WidgetTester tester, FakePhotoPicker picker) async {
    tester.view.physicalSize = const Size(1080, 2280);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final router = GoRouter(
      initialLocation: AppRoutes.account,
      routes: [
        GoRoute(
          path: AppRoutes.account,
          builder: (_, _) => const AccountPage(),
        ),
        GoRoute(
          path: AppRoutes.editAccount,
          builder: (_, _) => EditAccountPage(photoPicker: picker),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.tap(find.byTooltip('Edit profil'));
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets(
    'Pencil opens full Edit Akun form with prefilled fields, not a sheet',
    (tester) async {
      await open(tester, FakePhotoPicker());
      expect(find.byType(EditAccountPage), findsOneWidget);
      expect(find.text('Edit Akun'), findsOneWidget);
      expect(find.text('Ganti Foto'), findsOneWidget);
      expect(find.text('Simpan'), findsOneWidget);
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.byType(HomeBottomNavigation), findsNothing);
      final fields = tester
          .widgetList<TextFormField>(find.byType(TextFormField))
          .toList();
      expect(fields.map((f) => f.controller!.text), [
        initialMember.name,
        '+6287860709553',
        'estherhoward@gmail.com',
      ]);
      expect(
        tester.widget<ProfileAvatar>(find.byType(ProfileAvatar)).size,
        112,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Invalid data cannot save or alter demo profile', (tester) async {
    await open(tester, FakePhotoPicker());
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '');
    await tester.enterText(fields.at(1), '+62letters');
    await tester.enterText(fields.at(2), 'invalid-email');
    tester.testTextInput.hide();
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    expect(find.text('Nama lengkap wajib diisi'), findsOneWidget);
    expect(find.text('Gunakan nomor Indonesia yang valid'), findsOneWidget);
    expect(find.text('Format email tidak valid'), findsOneWidget);
    expect(MemberRepository.profile.value, same(initialMember));
    expect(DemoSession.contact.value.phone, '+6287860709553');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Save updates Account and Home member source without modifying benefits or verification',
    (tester) async {
      await open(tester, FakePhotoPicker());
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), '  Angel Felicia  ');
      await tester.enterText(fields.at(1), '081234567890');
      await tester.enterText(fields.at(2), 'angel@example.com');
      tester.testTextInput.hide();
      await tester.tap(find.text('Simpan'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(find.byType(EditAccountPage), findsNothing);
      expect(find.text('Angel Felicia'), findsOneWidget);
      expect(find.text('angel@example.com'), findsOneWidget);
      final member = MemberRepository.profile.value;
      expect(member.number, initialMember.number);
      expect(member.points, initialMember.points);
      expect(member.balance, initialMember.balance);
      expect(member.canReuseVerification, initialMember.canReuseVerification);
      expect(member.benefits, initialMember.benefits);
      expect(member.pointsValidUntil, initialMember.pointsValidUntil);
      expect(member.benefitsActive, initialMember.benefitsActive);
      expect(find.textContaining('Akun RG asli tidak diubah'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Back discards draft name and contact changes', (tester) async {
    await open(tester, FakePhotoPicker());
    await tester.enterText(find.byType(TextFormField).first, 'Discarded Name');
    tester.testTextInput.hide();
    await tester.tap(find.byTooltip('Kembali'));
    await tester.pumpAndSettle();
    expect(MemberRepository.profile.value, same(initialMember));
    expect(find.text(initialMember.name), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Selected photo stays a draft until Save, then appears in Account',
    (tester) async {
      final picker = FakePhotoPicker();
      final asset = await rootBundle.load('assets/images/profile_avatar.png');
      picker.result = asset.buffer.asUint8List();
      await open(tester, picker);
      await tester.tap(find.text('Ganti Foto'));
      await tester.pumpAndSettle();
      expect(DemoSession.contact.value.avatarBytes, isNull);
      expect(
        tester.widget<ProfileAvatar>(find.byType(ProfileAvatar)).bytes,
        same(picker.result),
      );
      await tester.tap(find.text('Simpan'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(DemoSession.contact.value.avatarBytes, same(picker.result));
      expect(
        tester.widget<ProfileAvatar>(find.byType(ProfileAvatar)).bytes,
        same(picker.result),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Photo cancellation or unreadable photo does not replace the existing avatar',
    (tester) async {
      final picker = FakePhotoPicker();
      await open(tester, picker);
      await tester.tap(find.text('Ganti Foto'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<ProfileAvatar>(find.byType(ProfileAvatar)).bytes,
        isNull,
      );
      picker.fails = true;
      await tester.tap(find.text('Ganti Foto'));
      await tester.pumpAndSettle();
      expect(find.text('File foto tidak dapat dibaca.'), findsOneWidget);
      expect(DemoSession.contact.value.avatarBytes, isNull);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Small screen, larger text and keyboard do not overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.4),
            viewInsets: const EdgeInsets.only(bottom: 240),
          ),
          child: child!,
        ),
        home: EditAccountPage(photoPicker: FakePhotoPicker()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(TextFormField).last);
    await tester.enterText(find.byType(TextFormField).last, 'test@example.com');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
