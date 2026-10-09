import '../../../core/network/rg_integration.dart';
import '../../activity/models/activity_transaction.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/backend_config.dart';
import '../../../core/network/myrg_api.dart';

enum PaymentAction { pay, redeem, extend, installment }

extension PaymentActionLabel on PaymentAction {
  String get label => switch (this) {
    PaymentAction.pay => 'Pembayaran Gadai',
    PaymentAction.redeem => 'Tebus Gadai',
    PaymentAction.extend => 'Perpanjang Gadai',
    PaymentAction.installment => 'Cicil Pokok',
  };
}

class PaymentLine {
  const PaymentLine(this.label, this.amount);
  final String label;
  final int amount;
}

class PaymentQuote {
  const PaymentQuote({
    required this.total,
    required this.storageFee,
    required this.lines,
    this.paymentUrl,
    this.id,
    this.isPreview = false,
  });
  final int total;
  final int storageFee;
  final List<PaymentLine> lines;
  final String? paymentUrl;
  final String? id;
  final bool isPreview;
}

/// A payment link created at Raja Gadai (through the MyRG backend).
class PaymentLink {
  const PaymentLink({required this.paymentId, required this.url});
  final String paymentId;
  final String url;
}

/// One of the member's usable vouchers (Voucher Saya, status active).
class OwnedVoucher {
  const OwnedVoucher({required this.code, required this.name, this.expiresAt});
  final String code;
  final String name;
  final String? expiresAt;
}

class PaymentRepository {
  Future<PaymentQuote> quote({
    required ActivityTransaction transaction,
    required PaymentAction action,
    int months = 1,
    int? principalAmount,
    bool usePoints = false,
    bool useVoucher = false,
    DateTime? pickupDate,
  }) async {
    if (transaction.status == ActivityStatus.probation) {
      throw const RgUnavailable();
    }
    if (BackendConfig.enabled) {
      return _quoteFromBackend(
        transaction,
        action,
        months,
        pickupDate ?? DateTime.now(),
      );
    }
    if (RgIntegration.preview) {
      await Future<void>.delayed(const Duration(milliseconds: 450));
      // Fixture only: production totals and every extension transaction come from RG.
      final previewTotal = transaction.pawn?.totalPayable ?? 5700000;
      final previewStorageFee = transaction.pawn?.storageFee ?? 0;
      final lines = action == PaymentAction.extend
          ? List.generate(
              months,
              (i) => PaymentLine(
                'Perpanjangan bulan ${i + 1} • transaksi ${i + 1}',
                350000,
              ),
            )
          : [
              PaymentLine(
                action == PaymentAction.installment
                    ? 'Cicilan pokok'
                    : 'Tagihan gadai',
                action == PaymentAction.installment
                    ? principalAmount ?? 0
                    : previewTotal - previewStorageFee,
              ),
            ];
      return PaymentQuote(
        total: action == PaymentAction.extend
            ? months * 350000
            : action == PaymentAction.installment
            ? principalAmount ?? 0
            : previewTotal,
        storageFee:
            action == PaymentAction.redeem || action == PaymentAction.pay
            ? transaction.pawn?.storageFee ?? 0
            : 0,
        lines: lines,
        isPreview: true,
      );
    }
    final response = await RgIntegration.dio.postUri(
      RgIntegration.requireHttps(RgIntegration.paymentQuoteUrl),
      data: {
        'transactionId': transaction.id,
        'action': action.name,
        if (action == PaymentAction.extend) 'months': months,
        if (action == PaymentAction.installment)
          'principalAmount': principalAmount,
        'usePoints': usePoints,
        'useVoucher': useVoucher,
      },
    );
    final data = response.data as Map<String, dynamic>;
    final url = data['paymentUrl'] as String;
    RgIntegration.requireHttps(url);
    return PaymentQuote(
      total: data['total'] as int,
      storageFee: data['storageFee'] as int,
      id: data['quoteId'] as String,
      paymentUrl: url,
      lines: (data['lines'] as List)
          .map(
            (item) =>
                PaymentLine(item['label'] as String, item['amount'] as int),
          )
          .toList(),
    );
  }

  // ---------- MyRG backend (Raja Gadai computes; the backend forwards) ----------

  static String _path(ActivityTransaction tx, PaymentAction action) {
    final kind = action == PaymentAction.extend ? 'extend' : 'redeem';
    return '/transactions/${Uri.encodeComponent(tx.id)}/$kind';
  }

  Future<PaymentQuote> _quoteFromBackend(
    ActivityTransaction tx,
    PaymentAction action,
    int months,
    DateTime pickupDate,
  ) async {
    if (action == PaymentAction.installment) {
      throw const ApiException(
        code: 'NOT_AVAILABLE',
        message: 'Cicil pokok belum tersedia. Hubungi cabang untuk mencicil.',
      );
    }
    final body = action == PaymentAction.extend
        ? {'debtPayment': 0, 'months': months}
        : {'pickupDate': pickupDate.toIso8601String().split('T').first};
    final data = Map<String, dynamic>.from(
      await MyrgApi.post('${_path(tx, action)}/quote', body: body) as Map,
    );

    return PaymentQuote(
      total: (data['totalAmount'] as num).toInt(),
      storageFee: 0, // not provided by Raja Gadai yet
      lines: [
        for (final d in (data['details'] as List? ?? const []))
          PaymentLine(
            '${(d as Map)['description']}',
            (d['amount'] as num).toInt(),
          ),
      ],
    );
  }

  /// Creates the payment at Raja Gadai. [amount] must be the quote's total.
  Future<PaymentLink> submit({
    required ActivityTransaction transaction,
    required PaymentAction action,
    required int amount,
    int months = 1,
    String? voucherCode,
  }) async {
    final data = Map<String, dynamic>.from(
      await MyrgApi.post(
            '${_path(transaction, action)}/submit',
            body: {
              'amount': amount,
              if (action == PaymentAction.extend) 'months': months,
              'codeVoucher': ?voucherCode,
            },
          )
          as Map,
    );

    return PaymentLink(
      paymentId: '${data['paymentId']}',
      url: '${data['paymentLink']}',
    );
  }

  /// PENDING, PAID, EXPIRED or FAILED.
  Future<String> status(String paymentId) async {
    final data = Map<String, dynamic>.from(
      await MyrgApi.get('/payments/${Uri.encodeComponent(paymentId)}') as Map,
    );

    return '${data['paymentStatus']}';
  }

  Future<List<OwnedVoucher>> activeVouchers() async {
    final list =
        await MyrgApi.get('/loyalty/my-vouchers', query: {'status': 'active'})
            as List;

    return [
      for (final v in list)
        OwnedVoucher(
          code: '${(v as Map)['code']}',
          name: '${(v['voucher'] as Map?)?['name'] ?? v['code']}',
          expiresAt: v['expiresAt'] as String?,
        ),
    ];
  }
}
