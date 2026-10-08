import 'package:dio/dio.dart';

/// URLs must be supplied by RG. No endpoint paths or credentials are assumed.
abstract final class RgIntegration {
  static const preview = bool.fromEnvironment('RG_PREVIEW', defaultValue: true);
  static const registrationUrl = String.fromEnvironment('RG_REGISTER_URL');
  static const conversationUrl = String.fromEnvironment('RG_CONVERSATION_URL');
  static const otherGoodsUrl = String.fromEnvironment('RG_OTHER_GOODS_URL');
  static const paymentQuoteUrl = String.fromEnvironment('RG_PAYMENT_QUOTE_URL');
  static final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );

  static Uri requireHttps(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      throw const RgUnavailable();
    }
    return uri;
  }
}

class RgUnavailable implements Exception {
  const RgUnavailable();
  @override
  String toString() =>
      'Layanan belum tersedia. Silakan coba lagi nanti atau hubungi cabang.';
}
