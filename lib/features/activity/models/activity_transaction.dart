enum ActivityType { pawn, payment, disbursement, topUp }

enum ActivityStatus { needsAttention, processing, success, failed, probation }

class PawnEvent {
  const PawnEvent(this.label, this.date, {this.reference});
  final String label;
  final String date;
  final String? reference;
}

class PawnDetails {
  const PawnDetails({
    required this.startedAt,
    required this.tenor,
    required this.principal,
    this.imei,
    this.condition,
    this.estimatedValue,
    this.os,
    this.extensionEvents = const [],
    this.redeemedAt,
    this.redemptionMethod,
    this.storageFee = 0,
    this.totalPayable,
    this.freeStorageDays,
    this.probationEndsAt,
    this.formId,
    this.verificationReady = false,
    this.requiresRetake = false,
    this.retakeInstructions,
    this.pickupOfficerName,
    this.pickupOfficerPhotoUrl,
    this.estimatedProcessHours,
    this.branchName = 'Raja Gadai Kemang',
    this.documentNumber,
    this.fees = 0,
  });
  final String startedAt;
  final String tenor;
  final int principal;
  final String? imei;
  final String? condition;
  final String? estimatedValue;
  final String? os;
  final List<PawnEvent> extensionEvents;
  final String? redeemedAt;
  final String? redemptionMethod;
  final int storageFee;
  final int? totalPayable;

  /// Null or zero hides the promotion. RG determines this period.
  final int? freeStorageDays;
  final String? probationEndsAt;
  final String? formId;
  final bool verificationReady;
  final bool requiresRetake;
  final String? retakeInstructions;
  final String? pickupOfficerName;
  final String? pickupOfficerPhotoUrl;
  final int? estimatedProcessHours;
  final String branchName;
  final String? documentNumber;
  final int fees;
}

class ActivityTransaction {
  const ActivityTransaction({
    required this.id,
    required this.title,
    required this.reference,
    required this.type,
    required this.status,
    required this.dateLabel,
    required this.amount,
    this.subtitle,
    this.dueDate,
    this.attentionLabel,
    this.isIncome = false,
    this.pawn,
    this.dateIso,
    this.failureReason,
  });

  final String id;
  final String title;
  final String reference;
  final ActivityType type;
  final ActivityStatus status;
  final String dateLabel;
  final String amount;
  final String? subtitle;
  final String? dueDate;
  final String? attentionLabel;
  final bool isIncome;
  final PawnDetails? pawn;
  final String? dateIso;
  final String? failureReason;
}
