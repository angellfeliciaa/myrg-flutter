import 'package:flutter/material.dart';
import '../../../core/network/rg_integration.dart';
import '../models/pawn_submission.dart';

/// RG's native library owns checks 1–9, photo upload and Form ID generation.
/// Inject the vendor adapter here when the SDK and callback contract arrive.
abstract interface class DeviceInspector {
  Future<PawnSubmission?> inspect(BuildContext context, {String? formId});
}

class UnavailableDeviceInspector implements DeviceInspector {
  const UnavailableDeviceInspector();
  @override
  Future<PawnSubmission?> inspect(
    BuildContext context, {
    String? formId,
  }) async => throw const RgUnavailable();
}

abstract final class PawnPreview {
  static PawnSubmission submission(String category) => PawnSubmission(
    formId: 'DEMO-FORM-87231',
    transactionNumber: 'DEMO-RG87231',
    productName: category == 'HP'
        ? 'Apple iPhone 13 • 128 GB'
        : '$category • contoh perangkat',
    estimatedLoan: 'Rp 4.500.000 – Rp 5.200.000',
    estimatedProcessHours: 1,
    isPreview: true,
  );
}
