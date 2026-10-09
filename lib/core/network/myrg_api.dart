import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';

import '../session/session_store.dart';
import 'api_exception.dart';
import 'backend_config.dart';

/// The one HTTP client for the MyRG backend.
///
/// - Unwraps `{success, data}` and returns `data`; error answers become [ApiException].
/// - Sends the access token; on TOKEN_EXPIRED refreshes once (one refresh at a time for the whole
///   app) and repeats the request.
/// - When the session is over (replaced by another phone, revoked, expired) it clears the stored
///   session and calls [onSessionEnded] so the app can go back to the login page.
abstract final class MyrgApi {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: BackendConfig.baseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 40),
      // Error answers are read, not thrown by Dio.
      validateStatus: (_) => true,
      headers: {'Accept': 'application/json'},
    ),
  );

  /// Set by the app (navigate to login with a message).
  static void Function(ApiException reason)? onSessionEnded;

  static const _sessionOver = {
    'SESSION_REPLACED',
    'SESSION_REVOKED',
    'SESSION_EXPIRED',
    'INVALID_REFRESH_TOKEN',
    'UNAUTHORIZED',
  };

  static Future<void>? _refreshing;
  static final _random = Random();

  static Future<dynamic> get(
    String path, {
    Map<String, dynamic>? query,
    bool auth = true,
  }) => _send('GET', path, query: query, auth: auth);

  static Future<dynamic> post(String path, {Object? body, bool auth = true}) =>
      _send('POST', path, body: body, auth: auth);

  static Future<dynamic> put(String path, {Object? body, bool auth = true}) =>
      _send('PUT', path, body: body, auth: auth);

  static Future<dynamic> delete(
    String path, {
    Object? body,
    bool auth = true,
  }) => _send('DELETE', path, body: body, auth: auth);

  static Future<dynamic> _send(
    String method,
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    required bool auth,
    bool retried = false,
  }) async {
    final headers = <String, dynamic>{'X-Request-Id': _requestId()};
    final token = auth ? SessionStore.accessToken : null;
    if (token != null) headers['Authorization'] = 'Bearer $token';

    final Response<dynamic> res;
    try {
      res = await _dio.request<dynamic>(
        path,
        data: body,
        queryParameters: query?..removeWhere((_, v) => v == null),
        options: Options(method: method, headers: headers),
      );
    } on DioException {
      throw ApiException.network;
    }

    final status = res.statusCode ?? 0;
    final data = res.data;
    if (status >= 200 && status < 300) {
      return data is Map ? data['data'] : data;
    }

    final error = ApiException.fromResponse(
      status,
      data,
      res.headers.value('retry-after'),
    );
    if (auth && error.code == 'TOKEN_EXPIRED' && !retried) {
      // Another request may have refreshed while this one was on the way.
      if (SessionStore.accessToken == token) await _refreshOnce();
      // A multipart body is consumed by the first attempt; send a fresh copy.
      final again = body is FormData ? body.clone() : body;
      return _send(
        method,
        path,
        body: again,
        query: query,
        auth: auth,
        retried: true,
      );
    }
    if (auth && _sessionOver.contains(error.code)) {
      await _endSession(error);
    }
    throw error;
  }

  /// All requests that found an expired token wait for the same refresh.
  static Future<void> _refreshOnce() {
    return _refreshing ??= _refresh().whenComplete(() => _refreshing = null);
  }

  static Future<void> _refresh() async {
    final refreshToken = SessionStore.refreshToken;
    if (refreshToken == null) {
      const error = ApiException(
        code: 'SESSION_EXPIRED',
        message: 'Sesi berakhir. Silakan masuk lagi.',
        status: 401,
      );
      await _endSession(error);
      throw error;
    }
    try {
      final data = await _send(
        'POST',
        '/auth/refresh',
        body: {'refreshToken': refreshToken},
        auth: false,
      );
      await SessionStore.saveTokens(Map<String, dynamic>.from(data as Map));
    } on ApiException catch (e) {
      if (e.code == 'REFRESH_CONFLICT') {
        // Another refresh (e.g. a second app process) already stored new tokens.
        await SessionStore.reloadTokens();
        return;
      }
      if (_sessionOver.contains(e.code) || e.status == 401) {
        await _endSession(e);
      }
      rethrow;
    }
  }

  static Future<void> _endSession(ApiException reason) async {
    await SessionStore.clear();
    onSessionEnded?.call(reason);
  }

  static String _requestId() => List.generate(
    16,
    (_) => _random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
}
