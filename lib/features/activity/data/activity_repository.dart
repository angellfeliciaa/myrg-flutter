import '../../../core/network/backend_config.dart';
import '../models/activity_transaction.dart';
import 'activity_api.dart';

abstract final class ActivityRepository {
  /// Backend data when connected (BackendConfig.enabled), demo fixtures otherwise. While the
  /// backend data is loading (or failed) the lists are empty: never the demo pawns.
  static List<ActivityTransaction> get ongoing =>
      ActivityApi.ongoing.value ??
      (BackendConfig.enabled ? const [] : fixtureOngoing);
  static List<ActivityTransaction> get history =>
      ActivityApi.history.value ??
      (BackendConfig.enabled ? const [] : fixtureHistory);

  /// Backend mode, lists not there yet.
  static bool get loading =>
      BackendConfig.enabled && ActivityApi.ongoing.value == null;

  static const fixtureOngoing = <ActivityTransaction>[
    ActivityTransaction(
      id: 'RG77123',
      dateIso: '2026-07-31',
      title: 'Apple iPhone 13',
      subtitle: '128 GB  •  Purple',
      reference: '#RG77123',
      type: ActivityType.pawn,
      status: ActivityStatus.needsAttention,
      dateLabel: '31 Juli 2026',
      dueDate: '31 Juli 2026',
      attentionLabel: 'Jatuh tempo dalam 3 hari',
      amount: 'Rp 5.700.000',
      pawn: PawnDetails(
        startedAt: '2 Mei 2026',
        tenor: '90 hari',
        principal: 4200000,
        documentNumber: 'DEMO-SBG-77123',
        fees: 1500000,
        imei: '3567890654321178',
        condition: 'Baik',
        estimatedValue: 'Rp 5.000.000',
        os: 'iOS 17.4.1',
        storageFee: 70000,
        totalPayable: 5770000,
        freeStorageDays: 3,
        extensionEvents: [
          PawnEvent(
            'Perpanjangan 1 bulan',
            '2 Agustus 2026',
            reference: '#EXT77123-1',
          ),
          PawnEvent(
            'Perpanjangan 1 bulan',
            '2 September 2026',
            reference: '#EXT77123-2',
          ),
          PawnEvent(
            'Perpanjangan 1 bulan',
            '2 Oktober 2026',
            reference: '#EXT77123-3',
          ),
        ],
      ),
    ),
    ActivityTransaction(
      id: 'RG87231',
      dateIso: '2026-10-06',
      title: 'Gadai Apple iPhone 13',
      reference: '#RG87231',
      type: ActivityType.pawn,
      status: ActivityStatus.processing,
      dateLabel: 'Hari ini, 10:20',
      amount: 'Rp 5.700.000',
      pawn: PawnDetails(
        startedAt: 'Hari ini, 09:40',
        tenor: '90 hari',
        principal: 4200000,
        formId: 'DEMO-FORM87231',
        verificationReady: true,
        requiresRetake: true,
        retakeInstructions:
            'Foto tampak samping belum jelas. Ambil ulang foto dengan pencahayaan yang cukup.',
        estimatedProcessHours: 1,
      ),
    ),
    ActivityTransaction(
      id: 'PD87231',
      dateIso: '2026-10-06',
      title: 'Pencairan Dana',
      reference: '#PD87231',
      type: ActivityType.disbursement,
      status: ActivityStatus.processing,
      dateLabel: 'Hari ini, 09:45',
      amount: 'Rp 4.200.000',
      isIncome: true,
    ),
    ActivityTransaction(
      id: 'RGPROB001',
      dateIso: '2026-10-01',
      title: 'Emas Antam 5 gram',
      reference: '#RGPROB001',
      type: ActivityType.pawn,
      status: ActivityStatus.probation,
      dateLabel: '1 Oktober 2026',
      dueDate: '30 September 2026',
      attentionLabel: 'Masa probation • Penebusan melalui CS/cabang',
      amount: 'Rp 4.250.000',
      pawn: PawnDetails(
        startedAt: '1 Juli 2026',
        tenor: '90 hari',
        principal: 4000000,
        totalPayable: 4250000,
        probationEndsAt: '8 Oktober 2026',
      ),
    ),
  ];

  static const fixtureHistory = <ActivityTransaction>[
    ActivityTransaction(
      id: 'DEMO-RG-SUCCESS',
      dateIso: '2026-10-07',
      title: 'Gadai Apple iPhone 13',
      subtitle: '128 GB • Purple',
      reference: '#DEMO-RG-SUCCESS',
      type: ActivityType.pawn,
      status: ActivityStatus.success,
      dateLabel: '7 Oktober 2026',
      amount: 'Rp 4.850.000',
      isIncome: true,
      dueDate: '5 Januari 2027',
      pawn: PawnDetails(
        startedAt: '7 Oktober 2026',
        tenor: '90 hari',
        principal: 4850000,
        imei: '3567890654321178',
        condition: 'Baik',
        estimatedValue: 'Rp 5.200.000',
        os: 'iOS 17.4.1',
        documentNumber: 'DEMO-SBG-SUCCESS',
      ),
    ),
    ActivityTransaction(
      id: 'DEMO-RG-FAILED',
      dateIso: '2026-10-06',
      title: 'Gadai Apple iPhone 12',
      subtitle: '128 GB • Purple',
      reference: '#DEMO-RG-FAILED',
      type: ActivityType.pawn,
      status: ActivityStatus.failed,
      dateLabel: '6 Oktober 2026',
      amount: 'Rp 0',
      failureReason:
          'Data perangkat tidak sesuai dengan hasil verifikasi. Dana tidak dicairkan.',
      pawn: PawnDetails(
        startedAt: '6 Oktober 2026',
        tenor: '90 hari',
        principal: 0,
        imei: '3567890654321178',
        condition: 'Menunggu verifikasi',
        estimatedValue: 'Rp 5.000.000',
        os: 'iOS 17.4.1',
      ),
    ),
    ActivityTransaction(
      id: 'TUS87231',
      dateIso: '2026-10-05',
      title: 'Top Up Saldo RG',
      reference: '#TUS87231',
      type: ActivityType.topUp,
      status: ActivityStatus.success,
      dateLabel: 'Kemarin, 19:15',
      amount: 'Rp 250.000',
      isIncome: true,
    ),
    ActivityTransaction(
      id: 'PAY87231',
      dateIso: '2026-07-15',
      title: 'Pembayaran Gadai',
      reference: '#PAY87231',
      type: ActivityType.payment,
      status: ActivityStatus.success,
      dateLabel: '15 Juli 2026',
      amount: 'Rp 1.050.000',
    ),
    ActivityTransaction(
      id: 'PAY86211',
      dateIso: '2026-06-15',
      title: 'Pembayaran Gadai',
      reference: '#PAY86211',
      type: ActivityType.payment,
      status: ActivityStatus.success,
      dateLabel: '15 Juni 2026',
      amount: 'Rp 1.050.000',
    ),
  ];

  static const goldPawn = ActivityTransaction(
    id: 'RGGOLD01',
    title: 'Emas Antam',
    subtitle: '5 gram',
    reference: '#RGGOLD01',
    type: ActivityType.pawn,
    status: ActivityStatus.needsAttention,
    dateLabel: '9 Agustus 2026',
    dueDate: '9 Agustus 2026',
    amount: 'Rp 4.250.000',
    attentionLabel: 'Jatuh tempo dalam 12 hari',
    pawn: PawnDetails(
      startedAt: '9 Mei 2026',
      tenor: '90 hari',
      principal: 4000000,
      totalPayable: 4250000,
    ),
  );
}
