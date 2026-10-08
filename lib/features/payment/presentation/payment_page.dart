import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/flow_widgets.dart';
import '../../../shared/widgets/rg_webview_page.dart';
import '../../activity/models/activity_transaction.dart';
import '../data/payment_repository.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({
    required this.transaction,
    required this.action,
    super.key,
  });
  final ActivityTransaction transaction;
  final PaymentAction action;
  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final _amount = TextEditingController(text: '500000');
  int _months = 1;
  bool _points = false;
  bool _voucher = false;
  bool _loading = false;
  PaymentQuote? _quote;
  String? _error;
  final _repository = PaymentRepository();
  String money(int amount) =>
      'Rp ${NumberFormat.decimalPattern('id').format(amount)}';
  @override
  void initState() {
    super.initState();
    _getQuote();
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _getQuote() async {
    if (_loading) return;
    final value = int.tryParse(_amount.text);
    if (widget.action == PaymentAction.installment &&
        (value == null ||
            value <= 0 ||
            value % 1000 != 0 ||
            value > (widget.transaction.pawn?.principal ?? 0))) {
      setState(() {
        _quote = null;
        _error =
            'Masukkan nominal kelipatan Rp 1.000, maksimal sebesar sisa pokok.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _quote = null;
    });
    try {
      final quote = await _repository.quote(
        transaction: widget.transaction,
        action: widget.action,
        months: _months,
        principalAmount: value,
        usePoints: _points,
        useVoucher: _voucher,
      );
      if (mounted) setState(() => _quote = quote);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Tagihan belum dapat dimuat. Coba lagi atau hubungi cabang.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final probation = widget.transaction.status == ActivityStatus.probation;
    return Scaffold(
      appBar: AppBar(title: Text(widget.action.label)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            widget.transaction.title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text('No. ${widget.transaction.reference}'),
          const SizedBox(height: 20),
          if (probation) ...[
            const FlowInfo(
              'Barang masih dapat ditebus selama masa probation 5 hari. Hubungi CS atau datang ke cabang untuk melanjutkan.',
              warning: true,
            ),
            const SizedBox(height: 18),
            AppButton(
              label: 'Hubungi CS',
              onPressed: () => context.push(
                AppRoutes.support,
                extra: widget.transaction.reference,
              ),
            ),
          ] else ...[
            if (widget.action == PaymentAction.extend)
              FlowSection(
                title: 'Lama perpanjangan',
                children: [
                  DropdownButtonFormField<int>(
                    initialValue: _months,
                    items: [1, 2, 3]
                        .map(
                          (v) => DropdownMenuItem(
                            value: v,
                            child: Text('$v bulan'),
                          ),
                        )
                        .toList(),
                    onChanged: _loading
                        ? null
                        : (v) {
                            setState(() {
                              _months = v!;
                              _quote = null;
                            });
                            _getQuote();
                          },
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Perpanjangan $_months bulan dicatat sebagai $_months transaksi terpisah setelah dikonfirmasi RG.',
                    style: const TextStyle(fontSize: 13, height: 1.5),
                  ),
                ],
              ),
            if (widget.action == PaymentAction.installment)
              FlowSection(
                title: 'Nominal cicilan',
                children: [
                  TextField(
                    controller: _amount,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Nominal pokok',
                      prefixText: 'Rp ',
                    ),
                    onChanged: (_) => setState(() => _quote = null),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Gunakan poin'),
                    value: _points,
                    onChanged: _loading
                        ? null
                        : (v) => setState(() {
                            _points = v;
                            _quote = null;
                          }),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Gunakan voucher'),
                    value: _voucher,
                    onChanged: _loading
                        ? null
                        : (v) => setState(() {
                            _voucher = v;
                            _quote = null;
                          }),
                  ),
                  AppButton(
                    label: 'Perbarui Tagihan',
                    isLoading: _loading,
                    onPressed: _getQuote,
                  ),
                ],
              ),
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
            if (_error != null) ...[
              FlowInfo(_error!, warning: true),
              TextButton(onPressed: _getQuote, child: const Text('Coba lagi')),
            ],
            if (_quote != null) ...[
              FlowSection(
                title: 'Rincian pembayaran',
                children: [
                  ..._quote!.lines.map(
                    (line) => FlowValue(line.label, money(line.amount)),
                  ),
                  FlowValue('Biaya simpan', money(_quote!.storageFee)),
                  const Divider(),
                  const SizedBox(height: 10),
                  FlowValue('Total yang harus dibayar', money(_quote!.total)),
                ],
              ),
              if (_quote!.isPreview)
                const FlowInfo(
                  'Ini contoh tagihan untuk pratinjau. Total, biaya simpan, serta potongan poin/voucher akan mengikuti hasil perhitungan Raja Gadai.',
                ),
              const SizedBox(height: 20),
              AppButton(
                label: 'Lanjut ke Pembayaran',
                onPressed: _quote!.paymentUrl == null
                    ? null
                    : () => openRgWebview(
                        context,
                        title: 'Pembayaran Raja Gadai',
                        url: _quote!.paymentUrl,
                      ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Pilih metode pembayaran di halaman Raja Gadai. Status transaksi diperbarui setelah pembayaran dikonfirmasi.',
                style: TextStyle(fontSize: 13, height: 1.5),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
