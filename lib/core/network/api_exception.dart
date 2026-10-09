/// An error answer from the MyRG backend: `{success:false, message, errors:{code}}`.
/// Decide on [code], show [message] (already in Indonesian). See docs/error-codes.md in the backend.
class ApiException implements Exception {
  const ApiException({
    required this.code,
    required this.message,
    this.status = 0,
    this.fieldErrors = const {},
    this.retryAfterSeconds,
  });

  /// e.g. TOKEN_EXPIRED, INVALID_CREDENTIALS. VALIDATION for 422 field errors, NETWORK when the
  /// server could not be reached.
  final String code;
  final String message;
  final int status;

  /// 422 only: field name -> first message.
  final Map<String, String> fieldErrors;

  /// From the Retry-After header (429): seconds to wait.
  final int? retryAfterSeconds;

  static const network = ApiException(
    code: 'NETWORK',
    message: 'Tidak dapat terhubung ke server. Periksa koneksi internet kamu.',
  );

  factory ApiException.fromResponse(
    int status,
    Object? body,
    String? retryAfter,
  ) {
    final map = body is Map ? body : const {};
    final errors = map['errors'];
    final message =
        (map['message'] as String?) ?? 'Terjadi kesalahan. Coba lagi.';
    if (status == 422 && errors is Map && errors['code'] == null) {
      return ApiException(
        code: 'VALIDATION',
        message: message,
        status: status,
        fieldErrors: errors.map(
          (key, value) => MapEntry(
            '$key',
            value is List && value.isNotEmpty ? '${value.first}' : '$value',
          ),
        ),
      );
    }
    return ApiException(
      code: errors is Map && errors['code'] is String
          ? errors['code'] as String
          : 'HTTP_$status',
      message: message,
      status: status,
      retryAfterSeconds: int.tryParse(retryAfter ?? ''),
    );
  }

  /// First field error, or the general message: what a form shows under the button.
  String get displayMessage =>
      fieldErrors.isNotEmpty ? fieldErrors.values.first : message;

  @override
  String toString() => message;
}
