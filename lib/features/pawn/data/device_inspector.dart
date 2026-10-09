import 'dart:math';

import 'package:flutter/material.dart';
import '../../../core/network/backend_config.dart';
import '../../../core/network/rg_integration.dart';
import '../models/pawn_submission.dart';
import 'online_pawn_api.dart';

/// RG's native library owns checks 1–9, photo upload and Form ID generation.
/// Inject the vendor adapter here when the SDK and callback contract arrive.
abstract interface class DeviceInspector {
  Future<PawnSubmission?> inspect(BuildContext context, {String? formId});

  /// RG's SDK is not in the app yet. For testing the rest of Gadai Online against a backend in
  /// CORE_RG_MODE=fake, build with --dart-define=MYRG_SAMPLE_INSPECTION=true.
  static DeviceInspector forApp() =>
      BackendConfig.enabled && SampleDeviceInspector.enabled
      ? const SampleDeviceInspector()
      : const UnavailableDeviceInspector();
}

class UnavailableDeviceInspector implements DeviceInspector {
  const UnavailableDeviceInspector();
  @override
  Future<PawnSubmission?> inspect(
    BuildContext context, {
    String? formId,
  }) async => throw const RgUnavailable();
}

/// Testing only (fake Core RG): sends a made-up device-check result, as the SDK would, so the
/// photo steps can be tried. Never enable it against the real Core RG.
class SampleDeviceInspector implements DeviceInspector {
  const SampleDeviceInspector();
  static const enabled = bool.fromEnvironment('MYRG_SAMPLE_INSPECTION');

  static String _uuid() {
    final r = Random.secure();
    final hex = List.generate(
      32,
      (_) => r.nextInt(16).toRadixString(16),
    ).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-'
        '${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  @override
  Future<PawnSubmission?> inspect(
    BuildContext context, {
    String? formId,
  }) async {
    final range = await OnlinePawnApi.submitDiagnostic({
      'inspection_result': {
        'id': formId ?? _uuid(),
        'ram': 8,
        'rom': 128,
        'deviceBrand': 'vivo',
        'deviceModel': 'V2352',
        'osType': 'android',
        'osVersion': '14',
        'rawData': {
          'tests': [
            {'testCode': 'TOUCH', 'status': 'PASS'},
            {'testCode': 'CAMERA', 'status': 'PASS'},
          ],
          'deviceInfo': {'ram': 8, 'rom': 128},
        },
      },
      'inspection_request': {'id': _uuid(), 'status': 'COMPLETED'},
    });
    return range.toSubmission();
  }
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
