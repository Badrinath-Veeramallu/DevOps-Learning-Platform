import 'package:dio/dio.dart';

/// Centralized exception class representing API errors from the backend.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? code;
  final bool isEmailVerified;
  final String? email;
  final int? retryAfter;

  const ApiException({
    required this.message,
    this.statusCode,
    this.code,
    this.isEmailVerified = true,
    this.email,
    this.retryAfter,
  });

  /// Factory constructor to parse Dio exceptions into clear, actionable [ApiException]s.
  factory ApiException.fromDioException(DioException dioException) {
    switch (dioException.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException(
          message: 'Connection timed out. Verify your phone and Mac are on the same Wi-Fi network and the server is running on port 5000.',
          statusCode: 408,
        );

      case DioExceptionType.connectionError:
        return const ApiException(
          message: 'Cannot connect to backend server. Make sure the Node.js server is running (`npm start` in server/) and reachable on your Mac LAN IP.',
          statusCode: 503,
        );

      case DioExceptionType.badResponse:
        final response = dioException.response;
        final statusCode = response?.statusCode;
        final data = response?.data;
        final serverHeader =
            response?.headers.value('server')?.toLowerCase() ?? '';

        // Detect macOS AirTunes / AirPlay Receiver port collision
        if (serverHeader.contains('airtunes') ||
            (statusCode == 403 && (data == null || data == ''))) {
          return const ApiException(
            message: 'Port 5000 is blocked by macOS AirPlay Receiver. Please turn off AirPlay Receiver in Mac System Settings > General > AirDrop & AirPlay.',
            statusCode: 403,
            code: 'AIRPLAY_COLLISION',
          );
        }

        if (data is Map<String, dynamic>) {
          final message =
              data['message'] as String? ??
              'An unexpected server error occurred.';
          final code = data['code'] as String?;
          final isEmailVerified = data['isEmailVerified'] ?? true;
          final email = data['email'] as String?;
          final retryAfter = data['retryAfter'] is int
              ? data['retryAfter'] as int
              : (data['retryAfter'] != null
                    ? int.tryParse(data['retryAfter'].toString())
                    : null);

          return ApiException(
            message: message,
            statusCode: statusCode,
            code: code,
            isEmailVerified: isEmailVerified == true,
            email: email,
            retryAfter: retryAfter,
          );
        }

        return ApiException(
          message: 'Server returned error status $statusCode.',
          statusCode: statusCode,
        );

      case DioExceptionType.cancel:
        return const ApiException(message: 'Request was cancelled.');

      case DioExceptionType.badCertificate:
        return const ApiException(
          message: 'Secure connection certificate verification failed.',
        );

      case DioExceptionType.unknown:
      default:
        return ApiException(
          message:
              dioException.message ?? 'A network communication error occurred.',
        );
    }
  }

  @override
  String toString() => message;
}
