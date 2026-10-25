import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../storage/secure_storage_service.dart';

/// Interceptor that attaches the Bearer token to outgoing HTTP requests
/// and redacts sensitive parameters from logs.
class AuthInterceptor extends Interceptor {
  final ISecureStorageService storageService;

  AuthInterceptor({required this.storageService});

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // 1. Attach Bearer token from secure storage if present
    final token = await storageService.getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    // 2. Safe debugging log that strictly REDACTS sensitive fields
    if (kDebugMode) {
      final sanitizedData = _sanitizeBody(options.data);
      debugPrint(
        '[API REQUEST] ${options.method} ${options.uri} | Data: $sanitizedData',
      );
    }

    return handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      final sanitizedResponse = _sanitizeBody(response.data);
      debugPrint(
        '[API RESPONSE] ${response.statusCode} ${response.requestOptions.uri} | Data: $sanitizedResponse',
      );
    }
    return handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint(
        '[API ERROR] ${err.response?.statusCode} ${err.requestOptions.uri} | Message: ${err.message}',
      );
    }
    return handler.next(err);
  }

  /// Recursively scrubs sensitive credential fields (password, token, otp) from logs
  dynamic _sanitizeBody(dynamic data) {
    if (data is Map<String, dynamic>) {
      final copy = Map<String, dynamic>.from(data);
      for (final key in copy.keys) {
        final lower = key.toLowerCase();
        if (lower.contains('password') ||
            lower == 'token' ||
            lower == 'idtoken' ||
            lower == 'credential' ||
            lower == 'otp' ||
            lower == 'otphash') {
          copy[key] = '***REDACTED***';
        } else if (copy[key] is Map<String, dynamic>) {
          copy[key] = _sanitizeBody(copy[key]);
        }
      }
      return copy;
    }
    return data;
  }
}
