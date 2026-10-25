import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../api/api_exceptions.dart';
import '../config/app_config.dart';

/// Abstract interface for Google Sign-In interaction.
///
/// Enables seamless mocking in automated tests without requiring
/// a native Google Play Services runtime environment.
abstract class IGoogleAuthService {
  Future<String?> signIn();
  Future<void> signOut();
}

/// Production implementation of [IGoogleAuthService] using the official
/// Flutter `google_sign_in` plugin (v7.x API).
class GoogleAuthService implements IGoogleAuthService {
  final GoogleSignIn _googleSignIn;
  bool _isInitialized = false;

  GoogleAuthService({GoogleSignIn? googleSignIn})
    : _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  /// Ensures Google Sign-In is initialized with the Web Client ID exactly once.
  Future<void> ensureInitialized() async {
    if (!_isInitialized) {
      debugPrint(
        '[GoogleAuth] Initializing GoogleSignIn with serverClientId=${AppConfig.googleClientId}',
      );
      await _googleSignIn.initialize(serverClientId: AppConfig.googleClientId);
      _isInitialized = true;
      debugPrint('[GoogleAuth] GoogleSignIn initialization complete.');
    }
  }

  @override
  Future<String?> signIn() async {
    try {
      debugPrint('[GoogleAuth] signIn() requested.');
      await ensureInitialized();

      // Clear any cached credential manager state to prevent stale session conflicts
      try {
        await _googleSignIn.signOut();
      } catch (_) {}

      debugPrint('[GoogleAuth] Invoking _googleSignIn.authenticate()...');
      final GoogleSignInAccount account = await _googleSignIn.authenticate();
      debugPrint(
        '[GoogleAuth] Authenticate returned account: email=${account.email}, hasId=${account.id.isNotEmpty}',
      );

      final String? idToken = account.authentication.idToken;
      final bool hasIdToken = idToken != null && idToken.isNotEmpty;
      debugPrint(
        '[GoogleAuth] account.authentication.idToken present: $hasIdToken',
      );

      if (!hasIdToken) {
        debugPrint(
          '[GoogleAuth] No ID token received from Google Play Services for selected account.',
        );
        throw const ApiException(
          message: 'Google Sign-In returned an account without an ID token. Please verify that your Web Client ID is properly configured.',
        );
      }

      debugPrint('[GoogleAuth] Successfully obtained ID token.');
      return idToken;
    } on GoogleSignInException catch (e) {
      debugPrint(
        '[GoogleAuth] GoogleSignInException: code=${e.code.name}, description="${e.description}", details=${e.details}',
      );

      if (e.code == GoogleSignInExceptionCode.canceled) {
        final desc = e.description ?? '';
        final lowerDesc = desc.toLowerCase();

        // Check if this is an actual user voluntary dismissal vs an authentication failure
        final isAuthFailure =
            lowerDesc.contains('reauth failed') ||
            lowerDesc.contains('[16]') ||
            lowerDesc.contains('failed');

        if (isAuthFailure) {
          debugPrint(
            '[GoogleAuth] Authentication failure reported under canceled code: "$desc"',
          );
          throw ApiException(
            message:
                'Google account authentication failed ($desc). Please ensure your Google account is added as a Test User in the Google Cloud Console (project 958415885728) and the Android OAuth Client (SHA-1: 87:2C:FC:F8:AF:56:2A:88:65:7E:97:6F:72:25:EF:77:57:6F:F7:DE) is active.',
          );
        }

        debugPrint(
          '[GoogleAuth] User voluntarily cancelled or dismissed account picker.',
        );
        return null;
      }

      if (e.code == GoogleSignInExceptionCode.clientConfigurationError ||
          e.code == GoogleSignInExceptionCode.providerConfigurationError) {
        throw ApiException(
          message:
              'Google Sign-In configuration error: Please verify that your Android debug SHA-1 fingerprint (87:2C:FC:F8:AF:56:2A:88:65:7E:97:6F:72:25:EF:77:57:6F:F7:DE) is registered in the Google Cloud Console. Details: ${e.description ?? e.code.name}',
        );
      }

      throw ApiException(
        message: 'Google Sign-In failed: ${e.description ?? e.code.name}',
      );
    } catch (e, stack) {
      debugPrint(
        '[GoogleAuth] Unexpected error during Google Sign-In: $e\n$stack',
      );
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Unexpected error during Google Sign-In: $e');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      debugPrint('[GoogleAuth] signOut() called.');
      await _googleSignIn.signOut();
    } catch (_) {
      // Ignored if user was not signed in through Google
    }
  }
}
