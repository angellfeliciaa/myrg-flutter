import 'package:flutter/material.dart';
import '../../membership/data/member_api.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/flow_widgets.dart';
import '../../../shared/widgets/rg_webview_page.dart';
import '../../activity/models/activity_transaction.dart';
import '../data/payment_repository.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/backend_config.dart';
import '../../activity/data/activity_api.dart';

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
  bool _paying = false;
  DateTime _pickupDate = DateTime.now();
  OwnedVoucher? _selectedVoucher;
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
        pickupDate: _pickupDate,
      );
      if (mounted) setState(() => _quote = quote);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
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
                    items: (BackendConfig.enabled ? [1] : [1, 2, 3])
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
                    BackendConfig.enabled
                        ? 'Saat ini perpanjangan dilakukan per 1 bulan. Pilihan beberapa bulan sekaligus segera hadir.'
                        : 'Perpanjangan $_months bulan dicatat sebagai $_months transaksi terpisah setelah dikonfirmasi RG.',
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
            if (BackendConfig.enabled &&
                (widget.action == PaymentAction.redeem ||
                    widget.action == PaymentAction.pay))
              FlowSection(
                title: 'Tanggal ambil barang',
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.event_outlined),
                    title: Text(
                      DateFormat('d MMMM y', 'id').format(_pickupDate),
                    ),
                    trailing: const Text('Ubah'),
                    onTap: _loading ? null : _pickPickupDate,
                  ),
                ],
              ),
            if (BackendConfig.enabled &&
                widget.action != PaymentAction.installment)
              FlowSection(
                title: 'Voucher',
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.confirmation_number_outlined),
                    title: Text(
                      _selectedVoucher?.name ?? 'Pilih voucher (opsional)',
                    ),
                    subtitle: _selectedVoucher == null
                        ? null
                        : Text(_selectedVoucher!.code),
                    trailing: _selectedVoucher == null
                        ? const Icon(Icons.chevron_right)
                        : IconButton(
                            tooltip: 'Hapus voucher',
                            icon: const Icon(Icons.close),
                            onPressed: () =>
                                setState(() => _selectedVoucher = null),
                          ),
                    onTap: _paying ? null : _pickVoucher,
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
                  if (!BackendConfig.enabled || _quote!.storageFee > 0)
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
                isLoading: _paying,
                onPressed: BackendConfig.enabled
                    ? (_paying ? null : _payWithBackend)
                    : _quote!.paymentUrl == null
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

  // ---------- MyRG backend ----------

  Future<void> _pickPickupDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: _pickupDate,
      firstDate: today,
      lastDate: today.add(const Duration(days: 30)),
      helpText: 'Tanggal ambil barang',
    );
    if (picked == null || !mounted) return;
    setState(() {
      _pickupDate = picked;
      _quote = null;
    });
    _getQuote();
  }

  Future<void> _pickVoucher() async {
    List<OwnedVoucher> vouchers;
    try {
      vouchers = await _repository.activeVouchers();
    } on ApiException catch (e) {
      _snack(e.message);
      return;
    }
    if (!mounted) return;
    if (vouchers.isEmpty) {
      _snack('Belum ada voucher aktif. Tukar poin di menu Promo.');
      return;
    }
    final picked = await showModalBottomSheet<OwnedVoucher>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(
              title: Text(
                'Voucher Saya',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            for (final v in vouchers)
              ListTile(
                leading: const Icon(Icons.confirmation_number_outlined),
                title: Text(v.name),
                subtitle: Text(v.code),
                onTap: () => Navigator.pop(context, v),
              ),
          ],
        ),
      ),
    );
    if (picked != null && mounted) setState(() => _selectedVoucher = picked);
  }

  /// Submit at Raja Gadai -> pay in the webview -> check the result.
  Future<void> _payWithBackend() async {
    final quote = _quote;
    if (quote == null) return;
    setState(() => _paying = true);
    try {
      final link = await _repository.submit(
        transaction: widget.transaction,
        action: widget.action,
        amount: quote.total,
        months: _months,
        voucherCode: _selectedVoucher?.code,
      );
      if (!mounted) return;
      await openRgWebview(
        context,
        title: 'Pembayaran Raja Gadai',
        url: link.url,
      );
      if (!mounted) return;
      await _waitForResult(link.paymentId);
    } on ApiException catch (e) {
      if (e.code == 'BAD_REQUEST') {
        _snack('Tagihan berubah. Rincian diperbarui, silakan periksa lagi.');
        if (!mounted) return;
        setState(() => _quote = null);
        _getQuote();
      } else if (e.code != 'SUBMIT_IN_PROGRESS') {
        _snack(e.message);
      }
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  /// Checks the payment every 5 seconds for up to 1 minute after the webview closes.
  Future<void> _waitForResult(String paymentId) async {
    var status = 'PENDING';
    for (var i = 0; i < 12 && status == 'PENDING'; i++) {
      try {
        status = await _repository.status(paymentId);
      } on ApiException {
        break;
      }
      if (status == 'PENDING') {
        await Future<void>.delayed(const Duration(seconds: 5));
      }
      if (!mounted) return;
    }
    if (!mounted) return;
    final (title, message) = switch (status) {
      'PAID' => (
        'Pembayaran berhasil',
        'Terima kasih. Data gadai kamu sudah diperbarui.',
      ),
      'EXPIRED' => (
        'Pembayaran kedaluwarsa',
        'Link pembayaran sudah tidak berlaku. Silakan buat tagihan baru.',
      ),
      'FAILED' => (
        'Pembayaran gagal',
        'Pembayaran tidak berhasil. Silakan coba lagi.',
      ),
      _ => (
        'Menunggu pembayaran',
        'Pembayaran belum terkonfirmasi. Kalau sudah membayar, status akan diperbarui otomatis.',
      ),
    };
    if (status == 'PAID') {
      // Points, vouchers and the pawn list change after a payment.
      ActivityApi.load(force: true).catchError((_) {});
      MemberApi.refreshCard(force: true);
    }
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (status == 'PAID' && mounted) Navigator.of(context).pop();
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
