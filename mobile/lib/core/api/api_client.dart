import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../models/user_model.dart';
import '../config/app_config.dart';
import '../storage/secure_storage_service.dart';
import 'api_exceptions.dart';
import 'auth_interceptor.dart';

/// Centralized HTTP API client communicating with the Express backend.
class ApiClient {
  final Dio _dio;

  ApiClient({
    Dio? dio,
    required ISecureStorageService storageService,
    String? baseUrl,
  }) : _dio =
           dio ??
           Dio(
             BaseOptions(
               baseUrl: baseUrl ?? AppConfig.defaultBaseUrl,
               connectTimeout: const Duration(seconds: 45),
               receiveTimeout: const Duration(seconds: 30),
               headers: {
                 'Content-Type': 'application/json',
                 'Accept': 'application/json',
               },
             ),
           ) {
    _dio.interceptors.add(AuthInterceptor(storageService: storageService));
  }

  /// Register a new user account.
  ///
  /// Calls `POST /api/auth/register`.
  /// Returns a map with `{ "requireOtp": true, "email": "...", "message": "..." }`.
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/register',
        data: {
          'name': name.trim(),
          'email': email.trim().toLowerCase(),
          'password': password,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Verify email using the 6-digit OTP.
  ///
  /// Calls `POST /api/auth/verify-email`.
  /// Returns `{ "token": "...", "user": UserModel }`.
  Future<({String token, UserModel user})> verifyEmail({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/verify-email',
        data: {'email': email.trim().toLowerCase(), 'otp': otp.trim()},
      );

      final data = response.data as Map<String, dynamic>;
      final token = data['token'] as String;
      final userJson = data['user'] as Map<String, dynamic>;
      final user = UserModel.fromJson(userJson);

      return (token: token, user: user);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Resend a 6-digit OTP code.
  ///
  /// Calls `POST /api/auth/resend-otp`.
  Future<String> resendOtp({required String email}) async {
    try {
      final response = await _dio.post(
        '/auth/resend-otp',
        data: {'email': email.trim().toLowerCase()},
      );
      final data = response.data as Map<String, dynamic>;
      return (data['message'] ?? 'Verification code sent successfully.')
          .toString();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Authenticate user with email and password.
  ///
  /// Calls `POST /api/auth/login`.
  /// Returns `{ "token": "...", "user": UserModel }`.
  Future<({String token, UserModel user})> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {'email': email.trim().toLowerCase(), 'password': password},
      );

      final data = response.data as Map<String, dynamic>;
      final token = data['token'] as String;
      final userJson = data['user'] as Map<String, dynamic>;
      final user = UserModel.fromJson(userJson);

      return (token: token, user: user);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Fetch currently authenticated user's profile.
  ///
  /// Calls `GET /api/auth/me`.
  Future<UserModel> getMe() async {
    try {
      final response = await _dio.get('/auth/me');
      final data = response.data as Map<String, dynamic>;
      final userJson = data['user'] as Map<String, dynamic>;
      return UserModel.fromJson(userJson);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Authenticate with a verified Google ID token.
  ///
  /// Calls existing `POST /api/auth/google`.
  /// Returns `{ "token": "...", "user": UserModel }`.
  Future<({String token, UserModel user})> googleLogin({
    required String idToken,
  }) async {
    try {
      debugPrint('[ApiClient] POST /auth/google initiating with ID token...');
      final response = await _dio.post(
        '/auth/google',
        data: {'idToken': idToken},
      );
      debugPrint(
        '[ApiClient] POST /auth/google response received: status=${response.statusCode}',
      );

      final data = response.data as Map<String, dynamic>;
      final token = data['token'] as String;
      final userJson = data['user'] as Map<String, dynamic>;
      final user = UserModel.fromJson(userJson);

      return (token: token, user: user);
    } on DioException catch (e) {
      debugPrint(
        '[ApiClient] POST /auth/google DioException: status=${e.response?.statusCode}, data=${e.response?.data}',
      );
      throw ApiException.fromDioException(e);
    }
  }

  /// Update the authenticated user's profile name.
  ///
  /// Calls `PUT /api/auth/profile`.
  /// Returns the updated [UserModel].
  Future<UserModel> updateProfile({required String name}) async {
    try {
      final response = await _dio.put(
        '/auth/profile',
        data: {'name': name.trim()},
      );
      final data = response.data as Map<String, dynamic>;
      final userJson = data['user'] as Map<String, dynamic>;
      return UserModel.fromJson(userJson);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
