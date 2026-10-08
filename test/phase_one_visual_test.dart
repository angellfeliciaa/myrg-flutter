// Opt-in local visual QA: flutter test test/phase_one_visual_test.dart
// --dart-define=MYRG_CAPTURE=true. Inter font files are QA-only under build/.
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myrg/core/constants/app_colors.dart';
import 'package:myrg/features/auth/data/demo_session.dart';
import 'package:myrg/features/auth/presentation/pin_page.dart';
import 'package:myrg/features/profile/presentation/account_page.dart';
import 'package:myrg/features/profile/presentation/security_page.dart';
import 'package:myrg/features/profile/presentation/change_password_page.dart';
import 'package:myrg/features/branch/data/branch_repository.dart';
import 'package:myrg/features/branch/presentation/branch_page.dart';
import 'package:myrg/features/branch/presentation/branch_detail_page.dart';
import 'package:myrg/features/activity/data/activity_repository.dart';
import 'package:myrg/features/activity/presentation/activity_detail_page.dart';
import 'package:myrg/features/activity/models/activity_transaction.dart';
import 'package:myrg/features/payment/presentation/installment_input_page.dart';
import 'package:myrg/features/simulation/presentation/simulation_page.dart';

const capture = bool.fromEnvironment('MYRG_CAPTURE');
void main() {
  setUpAll(() async {
    if (!capture) return;
    final loader = FontLoader('Inter');
    for (final face in ['Regular', 'SemiBold', 'Bold']) {
      loader.addFont(
        File(
          'build/phase-one-qa/Inter-$face.ttf',
        ).readAsBytes().then(ByteData.sublistView),
      );
    }
    await loader.load();
    final icons = FontLoader('MaterialIcons');
    icons.addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });
  testWidgets('Render phase-one pages with Inter for manual visual review', (
    tester,
  ) async {
    DemoSession.reset();
    tester.view.physicalSize = const Size(1080, 2280);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final base = ThemeData.light(useMaterial3: true);
    final theme = base.copyWith(
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
      textTheme: base.textTheme.apply(fontFamily: 'Inter'),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.fieldBackground,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
    final key = GlobalKey();
    Future<void> save(String name) async {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: name);
      await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(
          'build/phase-one-qa/$name.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }

    Future<void> show(Widget page) async {
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: theme,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(padding: const EdgeInsets.only(top: 24, bottom: 24)),
              child: child!,
            ),
            home: page,
          ),
        ),
      );
    }

    await show(const Scaffold());
    await tester.runAsync(() async {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      for (final asset in manifest.listAssets().where(
        (name) => name.endsWith('.png'),
      )) {
        await precacheImage(AssetImage(asset), key.currentContext!);
      }
    });
    final due = ActivityRepository.ongoing.first;
    for (final entry in <(String, Widget)>[
      ('01-pin', const PinPage()),
      ('02-account', const AccountPage()),
      ('03-branches', const BranchPage()),
      (
        '04-branch-detail',
        BranchDetailPage(branch: BranchRepository.fixtures[1]),
      ),
      ('05-security', const SecurityPage()),
      ('06-password', const ChangePasswordPage()),
      ('07-pawn', ActivityDetailPage(transaction: due)),
      ('08-installment', InstallmentInputPage(transaction: due)),
      (
        '09-success',
        ActivityDetailPage(
          transaction: ActivityRepository.history.firstWhere(
            (t) =>
                t.type == ActivityType.pawn &&
                t.status == ActivityStatus.success,
          ),
        ),
      ),
      (
        '10-failure',
        ActivityDetailPage(
          transaction: ActivityRepository.history.firstWhere(
            (t) => t.status == ActivityStatus.failed,
          ),
        ),
      ),
    ]) {
      await show(entry.$2);
      await save(entry.$1);
    }
    await show(const SimulationPage());
    await save('11-valuation-category');
    await tester.tap(find.text('Handphone'));
    await save('12-valuation-brand');
    await tester.tap(find.byKey(const ValueKey('valuation-brand-Apple')));
    await save('13-valuation-model');
    await tester.enterText(find.byType(TextField), 'iPhone 13');
    await tester.pumpAndSettle();
    tester.testTextInput.hide();
    await tester.tap(find.text('iPhone 13').last);
    await save('14-valuation-result');
    await tester.pumpWidget(const SizedBox.shrink());
  }, skip: !capture);
}
