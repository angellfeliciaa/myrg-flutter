import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:myrg/features/membership/data/member_repository.dart';
import 'package:myrg/features/membership/models/member_profile.dart';
import 'package:myrg/features/profile/presentation/account_page.dart';
import 'package:myrg/features/profile/presentation/widgets/member_information_card.dart';

void main() {
  final initial = MemberRepository.profile.value;
  setUpAll(() => initializeDateFormatting('id'));
  tearDown(() => MemberRepository.profile.value = initial);

  Future<void> show(WidgetTester tester, MemberProfile member) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: MemberInformationCard(member: member),
          ),
        ),
      ),
    );
  }

  testWidgets(
    'One accordion contains all four member details and collapses again',
    (tester) async {
      await show(tester, initial);
      expect(find.text('Detail keanggotaan kamu'), findsOneWidget);
      expect(find.text('Masa Berlaku Poin'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('member-information-toggle')));
      await tester.pumpAndSettle();
      for (final label in [
        'Nomor Member',
        'Tier Saat Ini',
        'Masa Berlaku Poin',
        'Benefit Tambahan',
      ]) {
        expect(find.text(label), findsOneWidget);
      }
      expect(find.text(initial.number), findsOneWidget);
      expect(find.text('Gold'), findsOneWidget);
      expect(find.text('31 Des 2026'), findsOneWidget);
      expect(find.text('Aktif'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('member-information-toggle')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('member-information-details')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Unverified member never displays a fake number, expiry or active benefit',
    (tester) async {
      MemberRepository.resetForRegistration('Nasabah Baru');
      await show(tester, MemberRepository.profile.value);
      await tester.tap(find.byKey(const ValueKey('member-information-toggle')));
      await tester.pumpAndSettle();
      expect(find.text('Belum tersedia'), findsNWidgets(2));
      expect(find.text('Belum aktif'), findsNWidgets(2));
      expect(find.text('Aktif'), findsNothing);
      expect(find.text('31 Des 2026'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Account uses the same live member number in card and expanded details',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2280);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const MaterialApp(home: AccountPage()));
      final toggle = find.byKey(const ValueKey('member-information-toggle'));
      await tester.ensureVisible(toggle);
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      final details = find.byKey(const ValueKey('member-information-details'));
      expect(
        find.descendant(of: details, matching: find.text(initial.number)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: details, matching: find.text('Gold')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Details remain readable on a narrow screen with larger text', (
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
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: MemberInformationCard(member: initial),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('member-information-toggle')));
    await tester.pumpAndSettle();
    expect(find.text(initial.number), findsOneWidget);
    expect(find.text('31 Des 2026'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('Renaming a profile preserves point validity and benefit status', () {
    final changed = initial.withName('Nama Baru');
    expect(changed.pointsValidUntil, initial.pointsValidUntil);
    expect(changed.benefitsActive, initial.benefitsActive);
  });
}
