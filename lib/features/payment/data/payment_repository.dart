import '../../../core/network/rg_integration.dart';
import '../../activity/models/activity_transaction.dart';

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

class PaymentRepository {
  Future<PaymentQuote> quote({
    required ActivityTransaction transaction,
    required PaymentAction action,
    int months = 1,
    int? principalAmount,
    bool usePoints = false,
    bool useVoucher = false,
  }) async {
    if (transaction.status == ActivityStatus.probation) {
      throw const RgUnavailable();
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
}
