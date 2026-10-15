import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myrg/features/activity/models/activity_transaction.dart';
import 'package:myrg/features/activity/presentation/pawn_detail_page.dart';

ActivityTransaction _pawn(List<PawnEvent> extensions) => ActivityTransaction(
  id: '070251015101288',
  title: 'S23 FE',
  reference: '#070251015101288',
  type: ActivityType.pawn,
  status: ActivityStatus.needsAttention,
  dateLabel: '25 September 2026',
  amount: 'Rp 2.500.000',
  pawn: PawnDetails(
    startedAt: '25 September 2026',
    tenor: '-',
    principal: 2500000,
    extensionEvents: extensions,
  ),
);

void main() {
  testWidgets(
    'the full detail that arrives after the list item replaces it (extension history shows)',
    (tester) async {
      final holder = ValueNotifier(_pawn(const []));
      await tester.pumpWidget(
        MaterialApp(
          home: ValueListenableBuilder(
            valueListenable: holder,
            builder: (_, tx, _) => PawnDetailPage(transaction: tx),
          ),
        ),
      );
      expect(find.text('Riwayat perpanjangan'), findsNothing);

      holder.value = _pawn(const [
        PawnEvent(
          'Perpanjangan ke-1',
          '15 Oktober 2026 • Rp 175.000',
          reference: 'Jatuh tempo baru 25 November 2026',
        ),
      ]);
      await tester.pump();
      await tester.scrollUntilVisible(find.text('Perpanjangan ke-1'), 200);
      expect(find.text('Riwayat perpanjangan'), findsOneWidget);
      expect(find.text('Jatuh tempo baru 25 November 2026'), findsOneWidget);
    },
  );
}
