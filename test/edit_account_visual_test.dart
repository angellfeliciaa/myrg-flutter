// Opt-in capture: flutter test test/edit_account_visual_test.dart
// --dart-define=MYRG_CAPTURE=true. Uses QA-only Inter fonts under build/.
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:myrg/features/membership/data/member_repository.dart';
import 'package:myrg/features/profile/presentation/widgets/member_information_card.dart';
import 'package:myrg/features/profile/presentation/edit_account_page.dart';
import 'edit_account_test.dart' show FakePhotoPicker;

const captureEdit = bool.fromEnvironment('MYRG_CAPTURE');

void main() {
  setUpAll(() async {
    if (!captureEdit) return;
    await initializeDateFormatting('id');
    final font = FontLoader('Inter');
    for (final face in ['Regular', 'SemiBold', 'Bold']) {
      font.addFont(
        File(
          'build/phase-one-qa/Inter-$face.ttf',
        ).readAsBytes().then(ByteData.sublistView),
      );
    }
    await font.load();
    final icons = FontLoader('MaterialIcons');
    icons.addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });
  testWidgets('Edit Akun visual reference at Figma viewport', (tester) async {
    tester.view.physicalSize = const Size(402, 874);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final boundaryKey = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundaryKey,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(useMaterial3: true, fontFamily: 'Inter'),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(padding: const EdgeInsets.only(top: 44, bottom: 34)),
            child: child!,
          ),
          home: EditAccountPage(photoPicker: FakePhotoPicker()),
        ),
      ),
    );
    await tester.runAsync(() async {
      await precacheImage(
        const AssetImage('assets/images/profile_avatar.png'),
        boundaryKey.currentContext!,
      );
      await precacheImage(
        const AssetImage('assets/icons/phase1_back.png'),
        boundaryKey.currentContext!,
      );
    });
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.runAsync(() async {
      final boundary =
          boundaryKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      final rendered = await boundary.toImage(pixelRatio: 2);
      final data = await rendered.toByteData(format: ui.ImageByteFormat.png);
      await File(
        'build/phase-one-qa/edit-account.png',
      ).writeAsBytes(data!.buffer.asUint8List());
      rendered.dispose();
    });
  }, skip: !captureEdit);
  testWidgets('Expanded member information visual reference', (tester) async {
    tester.view.physicalSize = const Size(402, 330);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(useMaterial3: true, fontFamily: 'Inter'),
          home: Scaffold(
            backgroundColor: const Color(0xFFFAFAFA),
            body: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Informasi Member',
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  MemberInformationCard(member: MemberRepository.profile.value),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('member-information-toggle')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final rendered = await boundary.toImage(pixelRatio: 2);
      final bytes = await rendered.toByteData(format: ui.ImageByteFormat.png);
      await File(
        'build/phase-one-qa/member-information.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
      rendered.dispose();
    });
  }, skip: !captureEdit);
}
