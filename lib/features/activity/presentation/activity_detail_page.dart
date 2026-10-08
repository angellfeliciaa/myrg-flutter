import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/widgets/flow_widgets.dart';
import '../../payment/data/payment_repository.dart';
import '../../payment/presentation/payment_page.dart';
import '../../pawn/models/pawn_submission.dart';
import '../../pawn/presentation/retake_page.dart';
import '../models/activity_transaction.dart';
import 'pawn_detail_page.dart';
import 'pawn_document_page.dart';

class ActivityDetailPage extends StatelessWidget {
  const ActivityDetailPage({required this.transaction, super.key});
  final ActivityTransaction transaction;

  String money(int value) =>
      'Rp ${NumberFormat.decimalPattern('id').format(value)}';

  void _payment(BuildContext context, PaymentAction action) =>
      Navigator.push<void>(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentPage(transaction: transaction, action: action),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final pawn = transaction.pawn;
    if (pawn != null && transaction.status == ActivityStatus.needsAttention) {
      return PawnDetailPage(transaction: transaction);
    }
    final probation = transaction.status == ActivityStatus.probation;
    final due = transaction.status == ActivityStatus.needsAttention;
    final status = switch (transaction.status) {
      ActivityStatus.needsAttention => 'Menunggu pembayaran',
      ActivityStatus.processing => 'Sedang diproses',
      ActivityStatus.success => 'Transaksi berhasil',
      ActivityStatus.failed => 'Transaksi gagal',
      ActivityStatus.probation => 'Masa probation • 5 hari',
    };
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Detail Transaksi')),
      bottomNavigationBar: due || probation
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                child: FilledButton.icon(
                  icon: Icon(probation ? Icons.support_agent : Icons.payment),
                  label: Text(
                    probation ? 'Hubungi CS untuk Penebusan' : 'Bayar Sekarang',
                  ),
                  onPressed: () => probation
                      ? context.push(
                          AppRoutes.support,
                          extra: transaction.reference,
                        )
                      : _payment(context, PaymentAction.pay),
                ),
              ),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
        children: [
          FlowInfo(
            status,
            warning:
                due || probation || transaction.status == ActivityStatus.failed,
          ),
          if (probation) ...[
            const SizedBox(height: 12),
            FlowInfo(
              'Barang masih dapat ditebus melalui CS atau cabang. Masa probation berakhir ${pawn?.probationEndsAt ?? 'sesuai informasi cabang'}.',
              warning: true,
            ),
          ],
          const SizedBox(height: 20),
          if (transaction.failureReason != null) ...[
            FlowSection(
              title: 'Alasan Transaksi Gagal',
              children: [
                Text(
                  transaction.failureReason!,
                  style: const TextStyle(fontSize: 14, height: 1.5),
                ),
              ],
            ),
          ],
          Row(
            children: [
              Container(
                width: 72,
                height: 96,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: transaction.title.toLowerCase().contains('iphone')
                    ? Image.asset(AppAssets.activityIphone, fit: BoxFit.contain)
                    : Icon(
                        transaction.type == ActivityType.pawn
                            ? Icons.diamond_outlined
                            : Icons.account_balance_wallet_outlined,
                        size: 36,
                        color: AppColors.primary,
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (transaction.subtitle != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        transaction.subtitle!,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                    if (pawn?.os != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        pawn!.os!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Text(
                      transaction.amount,
                      style: const TextStyle(
                        fontSize: 21,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          FlowSection(
            title: 'Ringkasan transaksi',
            children: [
              FlowValue('Nomor transaksi', transaction.reference),
              FlowValue('Tanggal transaksi', transaction.dateLabel),
              FlowValue('Status', status),
              FlowValue(
                transaction.type == ActivityType.topUp
                    ? 'Nominal top up'
                    : 'Nominal transaksi',
                transaction.amount,
              ),
            ],
          ),
          if (pawn != null) ...[
            if (pawn.imei != null || pawn.condition != null)
              FlowSection(
                title: 'Detail barang',
                children: [
                  if (pawn.imei != null) FlowValue('IMEI', pawn.imei!),
                  if (pawn.condition != null)
                    FlowValue('Kondisi', pawn.condition!),
                  if (pawn.estimatedValue != null)
                    FlowValue('Taksiran nilai', pawn.estimatedValue!),
                ],
              ),
            FlowSection(
              title: 'Informasi gadai',
              children: [
                FlowValue('Mulai gadai', pawn.startedAt),
                FlowValue('Tenor', pawn.tenor),
                if (transaction.dueDate != null)
                  FlowValue('Jatuh tempo', transaction.dueDate!),
                FlowValue('Sisa pokok', money(pawn.principal)),
                FlowValue('Cabang', pawn.branchName),
                FlowValue(
                  'Jumlah perpanjangan',
                  '${pawn.extensionEvents.length} kali',
                ),
                FlowValue(
                  'Tanggal penebusan',
                  pawn.redeemedAt ?? 'Belum ditebus',
                ),
                FlowValue(
                  'Metode penebusan',
                  pawn.redemptionMethod ?? 'Belum dipilih',
                ),
              ],
            ),
            if (pawn.extensionEvents.isNotEmpty)
              FlowSection(
                title: 'Riwayat perpanjangan',
                children: [
                  ...pawn.extensionEvents.map(
                    (event) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.event_repeat_rounded,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  event.label,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  event.date,
                                  style: const TextStyle(fontSize: 13),
                                ),
                                if (event.reference != null)
                                  Text(
                                    event.reference!,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            if (pawn.freeStorageDays != null && pawn.freeStorageDays! > 0) ...[
              FlowInfo(
                '${pawn.freeStorageDays} hari pertama bebas biaya simpan sesuai ketentuan promo aktif.',
              ),
              const SizedBox(height: 16),
            ],
            if (pawn.totalPayable != null)
              FlowSection(
                title: 'Tagihan terkini',
                children: [
                  FlowValue('Biaya simpan', money(pawn.storageFee)),
                  FlowValue(
                    'Total termasuk biaya simpan',
                    money(pawn.totalPayable!),
                  ),
                  const Text(
                    'Tagihan akhir mengikuti konfirmasi Raja Gadai.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            if (pawn.requiresRetake) ...[
              FlowInfo(
                pawn.retakeInstructions ??
                    'Petugas meminta foto ulang perangkat.',
                warning: true,
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => Navigator.push<void>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RetakePage(transaction: transaction),
                  ),
                ),
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Foto Ulang Perangkat'),
              ),
              const SizedBox(height: 16),
            ],
            if (pawn.verificationReady && pawn.formId != null) ...[
              OutlinedButton.icon(
                onPressed: () => context.push(
                  AppRoutes.support,
                  extra: transaction.reference,
                ),
                icon: const Icon(Icons.support_agent_rounded),
                label: const Text('Ajukan Banding'),
              ),
              const SizedBox(height: 10),
              FilledButton(
                onPressed: pawn.requiresRetake
                    ? null
                    : () => context.push(
                        AppRoutes.pawn,
                        extra: PawnSubmission(
                          formId: pawn.formId!,
                          transactionNumber: transaction.reference,
                          productName: transaction.title,
                          estimatedLoan: transaction.amount,
                          estimatedProcessHours:
                              pawn.estimatedProcessHours ?? 1,
                          isPreview: pawn.formId!.startsWith('DEMO-'),
                        ),
                      ),
                child: const Text('Lanjut Gadai'),
              ),
              if (pawn.requiresRetake)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Lengkapi foto ulang sebelum melanjutkan.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              const SizedBox(height: 16),
            ],
            if (pawn.pickupOfficerName != null)
              FlowSection(
                title: 'Petugas penjemputan',
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundImage: pawn.pickupOfficerPhotoUrl == null
                            ? null
                            : NetworkImage(pawn.pickupOfficerPhotoUrl!),
                        child: pawn.pickupOfficerPhotoUrl == null
                            ? const Icon(Icons.person_outline)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          pawn.pickupOfficerName!,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            if (pawn.estimatedProcessHours != null) ...[
              FlowInfo(
                'Estimasi proses: ${pawn.estimatedProcessHours} jam setelah data dan foto lengkap.',
              ),
              const SizedBox(height: 16),
            ],
            if (due && !probation)
              FlowSection(
                title: 'Kelola gadai',
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _payment(context, PaymentAction.extend),
                    icon: const Icon(Icons.event_repeat),
                    label: const Text('Perpanjang'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () =>
                        _payment(context, PaymentAction.installment),
                    icon: const Icon(Icons.payments_outlined),
                    label: const Text('Cicil Pokok'),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: () => _payment(context, PaymentAction.redeem),
                    icon: const Icon(Icons.inventory_2_outlined),
                    label: const Text('Tebus Gadai'),
                  ),
                ],
              ),
          ],
          if (pawn?.documentNumber != null &&
              transaction.status == ActivityStatus.success)
            ListTile(
              leading: Image.asset(
                'assets/icons/pawn_pdf.png',
                width: 32,
                height: 32,
              ),
              title: const Text('Surat Bukti Gadai'),
              subtitle: Text(pawn!.documentNumber!),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => PawnDocumentPage(transaction: transaction),
                ),
              ),
            ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(
              Icons.support_agent_rounded,
              color: AppColors.primary,
            ),
            title: const Text(
              'Butuh bantuan?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            subtitle: const Text(
              'Hubungi CS untuk transaksi ini.',
              style: TextStyle(fontSize: 13),
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () =>
                context.push(AppRoutes.support, extra: transaction.reference),
          ),
        ],
      ),
    );
  }
}
