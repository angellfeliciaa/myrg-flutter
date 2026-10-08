class PawnSubmission {
  const PawnSubmission({
    required this.formId,
    required this.transactionNumber,
    required this.productName,
    required this.estimatedLoan,
    required this.estimatedProcessHours,
    this.isPreview = false,
  });
  final String formId;
  final String transactionNumber;
  final String productName;
  final String estimatedLoan;
  final int estimatedProcessHours;
  final bool isPreview;
}
