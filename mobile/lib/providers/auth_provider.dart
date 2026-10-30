import 'package:flutter/foundation.dart';

import '../core/api/api_client.dart';
import '../core/api/api_exceptions.dart';
import '../core/auth/google_auth_service.dart';
import '../core/storage/secure_storage_service.dart';
import '../models/user_model.dart';

/// Central state manager for authentication and user sessions.
///
/// Utilizes Flutter's [ChangeNotifier] to broadcast state updates to widgets.
class AuthProvider extends ChangeNotifier {
  final ApiClient apiClient;
  final ISecureStorageService storageService;
  final IGoogleAuthService googleAuthService;

  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isInitialized = false;

  AuthProvider({
    required this.apiClient,
    required this.storageService,
    IGoogleAuthService? googleAuthService,
  }) : googleAuthService = googleAuthService ?? GoogleAuthService();

  // Public Getters
  UserModel? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isInitialized => _isInitialized || _user != null;

  /// Check whether an authenticated session exists on app startup.
  Future<void> checkAuthStatus() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final hasToken = await storageService.hasToken();
      if (!hasToken) {
        _user = null;
        _isInitialized = true;
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Validate session with the backend
      final verifiedUser = await apiClient.getMe();
      _user = verifiedUser;
    } on ApiException catch (e) {
      if (e.statusCode == 401 || e.statusCode == 403) {
        // Token has expired or is invalid -> safely wipe it
        await storageService.deleteToken();
        _user = null;
      } else {
        // Network timeout / temporary connectivity failure:
        // Do NOT wipe potentially valid credentials if the server is simply offline
        _errorMessage = e.message;
      }
    } catch (_) {
      _user = null;
    } finally {
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Authenticate user credentials.
  Future<void> login({required String email, required String password}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await apiClient.login(email: email, password: password);

      // Securely persist token in Android KeyStore
      await storageService.saveToken(result.token);
      _user = result.user;
      _isInitialized = true;
      _errorMessage = null;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Register a new account (triggers OTP dispatch on backend).
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await apiClient.register(
        name: name,
        email: email,
        password: password,
      );
      _errorMessage = null;
      return response;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Verify email with the 6-digit OTP and establish session.
  Future<void> verifyEmail({required String email, required String otp}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await apiClient.verifyEmail(email: email, otp: otp);

      await storageService.saveToken(result.token);
      _user = result.user;
      _isInitialized = true;
      _errorMessage = null;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Resend a verification OTP.
  Future<String> resendOtp({required String email}) async {
    _errorMessage = null;
    notifyListeners();

    try {
      final message = await apiClient.resendOtp(email: email);
      return message;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      rethrow;
    }
  }

  /// Authenticate using Google OAuth.
  ///
  /// Returns `true` if authentication succeeded and session was saved.
  /// Returns `false` if the user dismissed the Google prompt.
  Future<bool> loginWithGoogle() async {
    debugPrint('[AuthProvider] loginWithGoogle: initiated');
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final idToken = await googleAuthService.signIn();
      if (idToken == null) {
        debugPrint(
          '[AuthProvider] loginWithGoogle: signIn returned null (cancelled)',
        );
        _isLoading = false;
        notifyListeners();
        return false;
      }

      debugPrint(
        '[AuthProvider] loginWithGoogle: sending ID token to backend...',
      );
      final result = await apiClient.googleLogin(idToken: idToken);
      debugPrint(
        '[AuthProvider] loginWithGoogle: backend response successful. user=${result.user.name}, email=${result.user.email}',
      );

      await storageService.saveToken(result.token);
      _user = result.user;
      _isInitialized = true;
      _errorMessage = null;
      debugPrint(
        '[AuthProvider] loginWithGoogle: session token saved. isAuthenticated=$isAuthenticated',
      );
      return true;
    } on ApiException catch (e) {
      debugPrint(
        '[AuthProvider] loginWithGoogle: ApiException: ${e.message} (status: ${e.statusCode})',
      );
      _errorMessage = e.message;
      rethrow;
    } catch (e, stack) {
      debugPrint(
        '[AuthProvider] loginWithGoogle: unexpected error: $e\n$stack',
      );
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
      debugPrint(
        '[AuthProvider] loginWithGoogle: finished. isLoading=$_isLoading, isAuthenticated=$isAuthenticated',
      );
    }
  }

  /// Update the authenticated user's profile name.
  Future<UserModel> updateProfile({required String name}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedUser = await apiClient.updateProfile(name: name);
      _user = updatedUser;
      _errorMessage = null;
      return updatedUser;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Log out by wiping the token from secure storage and resetting state.
  Future<void> logout() async {
    await storageService.deleteToken();
    try {
      await googleAuthService.signOut();
    } catch (_) {}
    _user = null;
    _errorMessage = null;
    _isInitialized = true;
    notifyListeners();
  }

  /// Clear any active error message.
  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }
}
