import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myrg/features/activity/data/notification_api.dart';
import 'package:myrg/features/pawn/data/online_pawn_api.dart';
import 'package:myrg/features/pawn/presentation/pawn_photo_page.dart';
import 'package:myrg/features/support/presentation/support_page.dart';

/// Gadai Online part 2 (photos): backend answers -> app models, and the photo page's choices.
void main() {
  test('the device-check answer becomes a submission with the Form ID', () {
    final range = PawnRange.fromApi({
      'valuationId': '363b878e-d89e-4bd5-b638-810791b0f183',
      'modelName': 'vivo V2352',
      'minAmount': 1600000,
      'maxAmount': 2350000,
    });
    final submission = range.toSubmission();

    expect(submission.formId, '363b878e-d89e-4bd5-b638-810791b0f183');
    expect(submission.productName, 'vivo V2352');
    expect(submission.estimatedLoan, contains('1.600.000'));
    expect(submission.isPreview, isFalse);
    expect(range.manualReviewRequired, isFalse);
  });

  test(
    'photos from the same phone keep the Form ID and flag manual review',
    () {
      final range = PawnRange.fromApi({
        'minAmount': 1440000,
        'maxAmount': 2110000,
        'photoMode': 'single_device',
        'manualReviewRequired': true,
      }, formId: 'FORM-1');

      expect(range.formId, 'FORM-1');
      expect(range.manualReviewRequired, isTrue);
    },
  );

  test('photo link progress lists the sides already taken', () {
    final progress = PhotoProgress.fromApi({
      'uploaded': ['front', 'back'],
      'missing': ['top', 'bottom', 'left', 'right', 'screen'],
      'complete': false,
      'submitted': false,
      'expiresAt': '2026-10-09T10:15:00+07:00',
    });

    expect(progress.uploaded, {'front', 'back'});
    expect(progress.complete, isFalse);
    expect(photoSides, hasLength(7));
  });

  test('a FOTO_ULANG notification carries the Form ID and the sides', () {
    final n = InboxNotification.fromApi({
      'id': 3,
      'type': 'FOTO_ULANG',
      'title': 'Foto ulang diperlukan',
      'body': 'Penaksir kami butuh foto ulang (2 sisi).',
      'data': {
        'formId': 'FORM-1',
        'labels': ['left', 'screen'],
      },
      'read': false,
    });

    expect(n.formId, 'FORM-1');
    expect(n.labels, ['left', 'screen']);
  });

  testWidgets('the photo page offers another phone first and marks retakes', (
    tester,
  ) async {
    // Tall phone so the whole grid and the send button are built.
    tester.view.physicalSize = const Size(1080, 3200);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const MaterialApp(
        home: PawnPhotoPage(
          formId: 'FORM-1',
          productName: 'vivo V2352',
          retakeLabels: ['screen'],
        ),
      ),
    );

    expect(find.text('Pakai HP lain (disarankan)'), findsOneWidget);
    expect(find.text('Foto dari HP ini'), findsOneWidget);
    expect(find.textContaining('Layar menyala'), findsOneWidget);

    await tester.tap(find.text('Foto dari HP ini'));
    await tester.pumpAndSettle();
    expect(find.text('Kirim 0/7 Foto'), findsOneWidget);
    expect(find.text('Depan'), findsOneWidget);
  });

  test('opening a notification marks only that one as read', () {
    final n = InboxNotification.fromApi({
      'id': 9,
      'type': 'FOTO_ULANG',
      'title': 'Foto ulang',
      'body': '',
      'data': {
        'formId': 'FORM-1',
        'labels': ['left'],
      },
      'read': false,
    });
    final read = n.asRead();

    expect(read.read, isTrue);
    expect(read.id, 9);
    expect(read.formId, 'FORM-1');
    expect(read.labels, ['left']);
    expect(n.read, isFalse);
  });

  testWidgets('a Gadai Online banding asks for the submission number', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SupportPage(
          transactionNumber: 'FORM-1',
          referenceType: 'valuation',
        ),
      ),
    );

    expect(find.text('Nomor pengajuan'), findsOneWidget);
    expect(find.text('FORM-1'), findsOneWidget);
  });
}
