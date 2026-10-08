import 'package:flutter/material.dart';
import '../../../shared/widgets/phase_one_widgets.dart';
import '../../../shared/widgets/flow_widgets.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/utils/formatter.dart';
import '../models/activity_transaction.dart';

class PawnDocumentPage extends StatelessWidget {
  const PawnDocumentPage({required this.transaction, super.key});
  final ActivityTransaction transaction;
  @override
  Widget build(BuildContext context) => PhaseOneScaffold(
    title: 'Pratinjau Surat Bukti Gadai',
    child: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const FlowInfo(
          'Contoh tampilan dokumen FE. Bukan PDF atau Surat Bukti Gadai resmi.',
          warning: true,
        ),
        const SizedBox(height: 20),
        PhaseOneCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Image.asset(AppAssets.brandLogo, height: 48),
              const SizedBox(height: 24),
              const Text(
                'SURAT BUKTI GADAI',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                transaction.pawn?.documentNumber ??
                    'DEMO-SBG-${transaction.id}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Divider(),
              ),
              FlowValue('No. transaksi', transaction.reference),
              FlowValue('Barang', transaction.title),
              if (transaction.subtitle != null)
                FlowValue('Varian', transaction.subtitle!),
              FlowValue(
                'Cabang',
                transaction.pawn?.branchName ?? 'Contoh cabang',
              ),
              FlowValue(
                'Pokok pinjaman',
                Formatter.rupiah(transaction.pawn?.principal ?? 0),
              ),
              FlowValue('Tenor', transaction.pawn?.tenor ?? '—'),
              if (transaction.dueDate != null)
                FlowValue('Jatuh tempo', transaction.dueDate!),
              const SizedBox(height: 24),
              const Text(
                'PRATINJAU FE — TIDAK BERLAKU SEBAGAI BUKTI TRANSAKSI',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
