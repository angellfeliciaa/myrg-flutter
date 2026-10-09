import 'dart:convert';
import 'dart:typed_data';

import '../../../core/network/myrg_api.dart';
import '../../../core/utils/formatter.dart';
import '../models/pawn_submission.dart';

/// The 7 sides Raja Gadai needs, in the order the app asks for them.
const photoSides = {
  'front': 'Depan',
  'back': 'Belakang',
  'top': 'Atas',
  'bottom': 'Bawah',
  'left': 'Kiri',
  'right': 'Kanan',
  'screen': 'Layar menyala',
};

/// Estimate after the device check or after the photos.
class PawnRange {
  const PawnRange({
    required this.formId,
    required this.modelName,
    required this.minimum,
    required this.maximum,
    this.manualReviewRequired = false,
  });

  factory PawnRange.fromApi(Map<String, dynamic> json, {String? formId}) =>
      PawnRange(
        formId: '${json['valuationId'] ?? formId ?? ''}',
        modelName: '${json['modelName'] ?? ''}',
        minimum: (json['minAmount'] as num? ?? 0).toInt(),
        maximum: (json['maxAmount'] as num? ?? 0).toInt(),
        manualReviewRequired: json['manualReviewRequired'] == true,
      );

  final String formId, modelName;
  final int minimum, maximum;

  /// Photos from the same phone: the branch checks the item again (estimate already reduced).
  final bool manualReviewRequired;

  String get label =>
      '${Formatter.rupiah(minimum)} – ${Formatter.rupiah(maximum)}';

  PawnSubmission toSubmission() => PawnSubmission(
    formId: formId,
    transactionNumber: formId,
    productName: modelName,
    estimatedLoan: label,
    estimatedProcessHours: 1,
  );
}

/// The one-time photo link for a second phone.
class PhotoLink {
  const PhotoLink({required this.captureUrl, required this.expiresAt});
  final String captureUrl;
  final DateTime expiresAt;
  bool get expired => DateTime.now().isAfter(expiresAt);
}

class PhotoProgress {
  const PhotoProgress({
    required this.uploaded,
    required this.complete,
    required this.submitted,
    required this.expiresAt,
  });

  factory PhotoProgress.fromApi(Map<String, dynamic> json) => PhotoProgress(
    uploaded: {for (final l in json['uploaded'] as List? ?? const []) '$l'},
    complete: json['complete'] == true,
    submitted: json['submitted'] == true,
    expiresAt:
        DateTime.tryParse('${json['expiresAt']}')?.toLocal() ?? DateTime.now(),
  );

  final Set<String> uploaded;
  final bool complete, submitted;
  final DateTime expiresAt;
}

/// Gadai Online at MyRG (docs/integrasi-flutter.md 4.8). Part 1 (device check) needs RG's
/// device-check SDK; part 2 (photos) works now.
abstract final class OnlinePawnApi {
  /// Part 1: the SDK's result -> Form ID + estimate. Uses one of today's taksiran slots.
  static Future<PawnRange> submitDiagnostic(
    Map<String, dynamic> payload,
  ) async => PawnRange.fromApi(
    Map<String, dynamic>.from(
      await MyrgApi.post('/valuations/smart/diagnostic', body: payload) as Map,
    ),
  );

  /// Part 2, two phones: link for the second phone (QR). A new link disables the previous one.
  static Future<PhotoLink> createPhotoLink(String formId) async {
    final data = Map<String, dynamic>.from(
      await MyrgApi.post('/valuations/smart/${_id(formId)}/photo-session')
          as Map,
    );
    return PhotoLink(
      captureUrl: '${data['captureUrl']}',
      expiresAt:
          DateTime.tryParse('${data['expiresAt']}')?.toLocal() ??
          DateTime.now(),
    );
  }

  static Future<PhotoProgress> photoProgress(String formId) async =>
      PhotoProgress.fromApi(
        Map<String, dynamic>.from(
          await MyrgApi.get('/valuations/smart/${_id(formId)}/photo-session')
              as Map,
        ),
      );

  /// Sends the second phone's photos to Raja Gadai (all 7 must be in).
  static Future<PawnRange> submitPhotoLink(String formId) async =>
      PawnRange.fromApi(
        Map<String, dynamic>.from(
          await MyrgApi.post(
                '/valuations/smart/${_id(formId)}/photo-session/submit',
              )
              as Map,
        ),
        formId: formId,
      );

  /// Part 2, one phone: all 7 sides from this phone. The estimate is reduced and the branch
  /// checks the item (manualReviewRequired).
  static Future<PawnRange> submitPhotos(
    String formId,
    Map<String, Uint8List> photos,
  ) async => PawnRange.fromApi(
    Map<String, dynamic>.from(
      await MyrgApi.post(
            '/valuations/smart/${_id(formId)}/photos',
            body: {
              'photos': [
                for (final e in photos.entries)
                  {'label': e.key, 'image': base64Encode(e.value)},
              ],
            },
          )
          as Map,
    ),
    formId: formId,
  );

  static String _id(String formId) => Uri.encodeComponent(formId);
}
