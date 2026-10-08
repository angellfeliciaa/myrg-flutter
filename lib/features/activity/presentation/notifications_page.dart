import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/widgets/flow_widgets.dart';
import '../data/activity_repository.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Notifikasi')),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Update pengajuan kamu',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 20),
        ...ActivityRepository.ongoing
            .where((item) => item.pawn?.requiresRetake == true)
            .map(
              (item) => FlowSection(
                title: 'Foto perangkat perlu diulang',
                children: [
                  Text(
                    item.pawn!.retakeInstructions!,
                    style: const TextStyle(fontSize: 14, height: 1.5),
                  ),
                  const SizedBox(height: 12),
                  Text('No. ${item.reference}'),
                  TextButton(
                    onPressed: () =>
                        context.push(AppRoutes.activityDetail, extra: item),
                    child: const Text('Lihat pengajuan'),
                  ),
                ],
              ),
            ),
        const FlowInfo(
          'Pratinjau notifikasi. Update petugas penjemputan dan permintaan foto ulang akan mengikuti data Raja Gadai.',
        ),
      ],
    ),
  );
}
