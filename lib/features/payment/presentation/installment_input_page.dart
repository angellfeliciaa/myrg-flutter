import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/phase_one_widgets.dart';
import '../../activity/models/activity_transaction.dart';
import '../../activity/presentation/widgets/pawn_item_summary.dart';

class InstallmentInputPage extends StatefulWidget {
  const InstallmentInputPage({required this.transaction, super.key});
  final ActivityTransaction transaction;
  @override
  State<InstallmentInputPage> createState() => _InstallmentInputPageState();
}

class _InstallmentInputPageState extends State<InstallmentInputPage> {
  final _form = GlobalKey<FormState>();
  final _amount = TextEditingController();
  int? _percent;
  int get principal => widget.transaction.pawn?.principal ?? 0;
  int? get amount => int.tryParse(_amount.text.replaceAll('.', ''));
  String money(int value) =>
      'Rp ${NumberFormat.decimalPattern('id').format(value)}';
  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  void _select(int percent) {
    final value = (principal * percent ~/ 100 ~/ 1000) * 1000;
    setState(() {
      _percent = percent;
      _amount.text = NumberFormat.decimalPattern('id').format(value);
    });
    _form.currentState?.validate();
  }

  void _preview() {
    if (!_form.currentState!.validate()) return;
    FocusManager.instance.primaryFocus?.unfocus();
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Pratinjau Cicilan Pokok',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),
            Text('Nominal cicilan: ${money(amount!)}'),
            const SizedBox(height: 12),
            Text('Sisa pokok contoh: ${money(principal - amount!)}'),
            const SizedBox(height: 16),
            const Text(
              'Validasi input selesai. Biaya, quote resmi, dan pembayaran masuk fase 2. Tidak ada cicilan atau perubahan tagihan yang dikirim.',
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            PhaseOneButton(
              label: 'Kembali ke Input',
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => PhaseOneScaffold(
    title: 'Cicil Pokok',
    footer: PhaseOneButton(
      label: 'Cicil',
      onPressed: principal > 0 ? _preview : null,
    ),
    child: ListView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      children: [
        PawnItemSummary(
          transaction: widget.transaction,
          label: 'Sisa Pokok',
          amount: money(principal),
        ),
        const SizedBox(height: 32),
        const Text(
          'Masukkan Nominal Cicilan',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Form(
          key: _form,
          child: TextFormField(
            controller: _amount,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              LengthLimitingTextInputFormatter(18),
            ],
            onChanged: (_) => setState(() => _percent = null),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              prefixIcon: const Padding(
                padding: EdgeInsets.only(left: 20, right: 8),
                child: Text(
                  'Rp',
                  style: TextStyle(
                    fontSize: 20,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 52),
              hintText: '0',
              fillColor: Colors.white,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
            ),
            validator: (_) {
              final value = amount;
              if (value == null || value <= 0) {
                return 'Masukkan nominal cicilan yang valid.';
              }
              if (value % 1000 != 0) return 'Nominal harus kelipatan Rp 1.000.';
              if (value > principal) {
                return 'Nominal tidak boleh melebihi sisa pokok.';
              }
              return null;
            },
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            for (final value in [10, 30, 60, 90])
              ChoiceChip(
                label: Text('$value%', style: const TextStyle(fontSize: 12)),
                selected: _percent == value,
                showCheckmark: false,
                onSelected: (_) => _select(value),
                shape: const StadiumBorder(),
                selectedColor: AppColors.primarySoft,
                backgroundColor: Colors.white,
              ),
          ],
        ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primarySoft.withValues(alpha: .4),
            border: Border.all(color: AppColors.primary, width: .8),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Image.asset(
                  'assets/icons/installment_info.png',
                  width: 18,
                  height: 18,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Info Cicilan',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Mencicil pokok akan mengurangi bunga bulan berikutnya secara proporsional.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Simulasi FE • Nominal contoh. Perhitungan tagihan resmi tidak dilakukan di halaman ini.',
          style: TextStyle(
            fontSize: 11,
            height: 1.5,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    ),
  );
}
