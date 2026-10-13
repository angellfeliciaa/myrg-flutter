import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myrg/features/auth/presentation/register_page.dart';

/// The sign-up form only complains about empty fields after "Daftar", and stops complaining
/// as soon as a field is filled in, however the text got there.
void main() {
  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 4000);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('id', 'ID'),
        supportedLocales: [Locale('id', 'ID')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: RegisterPage(),
      ),
    );
  }

  testWidgets('picking a birth date does not mark other fields as missing', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(find.byType(TextFormField).at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pilih').last);
    await tester.pumpAndSettle();

    expect(find.textContaining('wajib diisi'), findsNothing);
  });

  testWidgets('after Daftar, pasted text clears the error like typed text', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Daftar'));
    await tester.pump();
    expect(find.text('Nomor telepon wajib diisi'), findsOneWidget);

    // A paste or autofill changes the controller without a key press.
    final phone = tester
        .widget<TextFormField>(find.byType(TextFormField).at(2))
        .controller!;
    phone.text = '081355556666';
    await tester.pump();
    await tester.pump();

    expect(find.text('Nomor telepon wajib diisi'), findsNothing);
  });
}
