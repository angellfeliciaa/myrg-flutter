import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/phase_one_widgets.dart';
import '../../../shared/widgets/flow_widgets.dart';
import '../../../core/network/backend_config.dart';
import '../../payment/data/payment_repository.dart';
import '../../payment/presentation/installment_input_page.dart';
import '../../payment/presentation/payment_page.dart';
import '../data/activity_api.dart';
import '../models/activity_transaction.dart';
import 'pawn_document_page.dart';
import 'widgets/pawn_item_summary.dart';

class PawnDetailPage extends StatefulWidget {
  const PawnDetailPage({required this.transaction, super.key});
  final ActivityTransaction transaction;

  @override
  State<PawnDetailPage> createState() => _PawnDetailPageState();
}

class _PawnDetailPageState extends State<PawnDetailPage> {
  /// Reloaded after Perpanjang / Tebus: the new history line and due date show on return.
  late ActivityTransaction transaction = widget.transaction;

  @override
  void didUpdateWidget(PawnDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The page opens with the list item; the full detail (extension history, redeem date)
    // arrives a moment later from ActivityDetailRoute and must replace it.
    if (widget.transaction != oldWidget.transaction) {
      transaction = widget.transaction;
    }
  }

  String money(int value) =>
      'Rp ${NumberFormat.decimalPattern('id').format(value)}';
  @override
  Widget build(BuildContext context) {
    final pawn = transaction.pawn!;
    return PhaseOneScaffold(
      title: 'Detail Gadai',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        children: [
          PawnItemSummary(
            transaction: transaction,
            label: 'Nominal Pembayaran',
            amount: transaction.amount,
            showAttention: true,
          ),
          const SizedBox(height: 24),
          PhaseOneCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Ringkasan Gadai',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 20),
                FlowValue('Pokok Pinjaman', money(pawn.principal)),
                FlowValue('Biaya', money(pawn.fees)),
                FlowValue('Cabang', pawn.branchName),
                FlowValue(
                  'No. Transaksi',
                  transaction.reference,
                  copyText: transaction.id,
                ),
                if (pawn.storageFee > 0)
                  FlowValue('Biaya simpan', money(pawn.storageFee)),
                if (pawn.totalPayable != null)
                  FlowValue('Total tagihan', money(pawn.totalPayable!)),
              ],
            ),
          ),
          if (!BackendConfig.enabled) ...[
            const SizedBox(height: 24),
            const Text(
              'Surat Bukti Gadai',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            PhaseOneCard(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => PawnDocumentPage(transaction: transaction),
                ),
              ),
              child: Row(
                children: [
                  ClipRect(
                    child: SizedBox(
                      width: 30,
                      height: 34,
                      child: OverflowBox(
                        maxWidth: 50.4,
                        maxHeight: 50.2,
                        child: Image.asset(
                          'assets/icons/pawn_pdf.png',
                          width: 50.4,
                          height: 50.2,
                          fit: BoxFit.fill,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pawn.documentNumber ?? 'DEMO-SBG-${transaction.id}',
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Lihat pratinjau dokumen FE',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          const Text(
            'Pilih Tindakan',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          _action(
            'Perpanjang',
            'Perpanjang masa gadai & bayar bunga',
            'pawn_extend',
            BackendConfig.enabled
                ? () => _pay(context, PaymentAction.extend)
                : () => showPhaseTwoNotice(context, 'Perpanjang Gadai'),
            phaseTwo: !BackendConfig.enabled,
          ),
          const SizedBox(height: 16),
          // Cicil pokok is not available at Raja Gadai yet: demo only.
          if (!BackendConfig.enabled) ...[
            _action(
              'Cicil Pokok',
              'Bayar sebagian pokok pinjaman',
              'pawn_installment',
              () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) =>
                      InstallmentInputPage(transaction: transaction),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          _action(
            'Tebus',
            'Lunasi & ambil kembali barang',
            'pawn_redeem',
            BackendConfig.enabled
                ? () => _pay(context, PaymentAction.redeem)
                : () => showPhaseTwoNotice(context, 'Tebus Barang'),
            phaseTwo: !BackendConfig.enabled,
          ),
          const SizedBox(height: 24),
          FlowSection(
            title: 'Informasi Gadai',
            children: [
              FlowValue('Mulai gadai', pawn.startedAt),
              FlowValue('Tenor', pawn.tenor),
              FlowValue(
                'Tanggal penebusan',
                pawn.redeemedAt ?? 'Belum ditebus',
              ),
              FlowValue(
                'Metode penebusan',
                pawn.redemptionMethod ?? 'Belum dipilih',
              ),
              if (pawn.imei != null) FlowValue('IMEI', pawn.imei!),
              if (pawn.condition != null) FlowValue('Kondisi', pawn.condition!),
            ],
          ),
          if (pawn.extensionEvents.isNotEmpty)
            FlowSection(
              title: 'Riwayat perpanjangan',
              children: [
                // Same layout as the activity detail: one left-aligned block per extension, so
                // the date and amount never break across a narrow right column.
                for (final (i, event) in pawn.extensionEvents.indexed)
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: i == pawn.extensionEvents.length - 1 ? 0 : 16,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.event_repeat_rounded,
                          color: AppColors.primary,
                          size: 22,
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
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                event.date,
                                style: const TextStyle(fontSize: 13),
                              ),
                              if (event.reference != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  event.reference!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          if (pawn.freeStorageDays != null && pawn.freeStorageDays! > 0)
            FlowInfo(
              '${pawn.freeStorageDays} hari pertama bebas biaya simpan sesuai ketentuan promo aktif.',
            ),
          if (!BackendConfig.enabled) ...[
            const SizedBox(height: 16),
            const Text(
              'Demo FE • Data tagihan dan dokumen adalah contoh. Aksi pembayaran masuk fase 2.',
              style: TextStyle(
                fontSize: 11,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Backend mode: Perpanjang / Tebus go to the real payment page.
  Future<void> _pay(BuildContext context, PaymentAction action) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentPage(transaction: transaction, action: action),
      ),
    );
    // Back from the payment: show what Core RG has now (extension line, due date, redeemed).
    try {
      final fresh = await ActivityApi.detail(transaction.id);
      if (mounted && fresh.pawn != null) setState(() => transaction = fresh);
    } catch (_) {
      // Keep what is shown; reopening the page loads it again.
    }
  }

  Widget _action(
    String title,
    String subtitle,
    String asset,
    VoidCallback onTap, {
    bool phaseTwo = false,
  }) => PhaseOneCard(
    onTap: onTap,
    child: Row(
      children: [
        // pawn_redeem.png from the design export is an empty 1x1 image: Tebus is drawn as in
        // the design (green check on a light lime circle) until the real one is exported.
        if (asset == 'pawn_redeem')
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.secondarySoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: AppColors.success,
              size: 28,
            ),
          )
        else
          Image.asset('assets/icons/$asset.png', width: 40, height: 40),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '$subtitle${phaseTwo ? ' • Fase 2' : ''}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        const Icon(
          Icons.chevron_right,
          size: 20,
          color: AppColors.textSecondary,
        ),
      ],
    ),
  );
}
