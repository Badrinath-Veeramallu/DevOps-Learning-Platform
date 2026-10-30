import 'package:flutter_test/flutter_test.dart';
import 'package:devops_learning_app/core/api/api_client.dart';
import 'package:devops_learning_app/core/api/api_exceptions.dart';
import 'package:devops_learning_app/core/auth/google_auth_service.dart';
import 'package:devops_learning_app/core/storage/secure_storage_service.dart';
import 'package:devops_learning_app/models/user_model.dart';
import 'package:devops_learning_app/providers/auth_provider.dart';

/// In-memory implementation of [ISecureStorageService] for fast, deterministic unit testing.
class MockSecureStorageService implements ISecureStorageService {
  String? _storedToken;

  @override
  Future<String?> getToken() async => _storedToken;

  @override
  Future<void> saveToken(String token) async {
    _storedToken = token;
  }

  @override
  Future<void> deleteToken() async {
    _storedToken = null;
  }

  @override
  Future<bool> hasToken() async =>
      _storedToken != null && _storedToken!.isNotEmpty;
}

/// Mock Google Authentication Service for deterministic unit tests.
class MockGoogleAuthService implements IGoogleAuthService {
  String? mockIdToken = 'mock_google_id_token_xyz';
  bool shouldCancel = false;
  ApiException? throwException;
  bool signedOut = false;

  @override
  Future<String?> signIn() async {
    if (throwException != null) throw throwException!;
    if (shouldCancel) return null;
    return mockIdToken;
  }

  @override
  Future<void> signOut() async {
    signedOut = true;
  }
}

/// Fake ApiClient to simulate backend response contracts without network calls.
class FakeApiClient extends ApiClient {
  bool shouldThrowLogin = false;
  ApiException? loginException;
  UserModel? mockUser;
  String mockToken = 'mock_jwt_token_123';

  bool shouldThrowGetMe = false;
  ApiException? getMeException;

  bool shouldThrowGoogleLogin = false;
  ApiException? googleLoginException;

  FakeApiClient({required super.storageService});

  @override
  Future<UserModel> updateProfile({required String name}) async {
    final current = mockUser ??
        const UserModel(
          id: 'usr_orig',
          name: 'Original Name',
          email: 'user@example.com',
        );
    final updated = current.copyWith(name: name);
    mockUser = updated;
    return updated;
  }

  @override
  Future<({String token, UserModel user})> googleLogin({
    required String idToken,
  }) async {
    if (shouldThrowGoogleLogin && googleLoginException != null) {
      throw googleLoginException!;
    }
    return (
      token: mockToken,
      user:
          mockUser ??
          const UserModel(
            id: 'usr_google_1',
            name: 'Google User',
            email: 'googleuser@example.com',
            authProvider: 'google',
            isEmailVerified: true,
          ),
    );
  }

  @override
  Future<({String token, UserModel user})> login({
    required String email,
    required String password,
  }) async {
    if (shouldThrowLogin && loginException != null) {
      throw loginException!;
    }
    return (
      token: mockToken,
      user:
          mockUser ??
          UserModel(
            id: 'usr_test_1',
            name: 'Test Engineer',
            email: email,
            isEmailVerified: true,
          ),
    );
  }

  @override
  Future<({String token, UserModel user})> verifyEmail({
    required String email,
    required String otp,
  }) async {
    if (otp == '000000') {
      throw const ApiException(
        message: 'Invalid verification code. 4 attempt(s) remaining.',
        statusCode: 400,
      );
    }
    return (
      token: mockToken,
      user: UserModel(
        id: 'usr_verified_2',
        name: 'Verified User',
        email: email,
        isEmailVerified: true,
      ),
    );
  }

  @override
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    if (email == 'existing@example.com') {
      throw const ApiException(
        message: 'An account with this email address already exists',
        statusCode: 409,
      );
    }
    return {
      'success': true,
      'message': 'Verification code sent to your email.',
      'email': email,
      'requireOtp': true,
    };
  }

  @override
  Future<UserModel> getMe() async {
    if (shouldThrowGetMe && getMeException != null) {
      throw getMeException!;
    }
    return mockUser ??
        const UserModel(
          id: 'usr_restored_3',
          name: 'Restored User',
          email: 'restored@example.com',
          isEmailVerified: true,
        );
  }
}

void main() {
  group('AuthProvider State Management Tests', () {
    late MockSecureStorageService storageService;
    late FakeApiClient fakeApi;
    late MockGoogleAuthService mockGoogleAuth;
    late AuthProvider authProvider;

    setUp(() {
      storageService = MockSecureStorageService();
      fakeApi = FakeApiClient(storageService: storageService);
      mockGoogleAuth = MockGoogleAuthService();
      authProvider = AuthProvider(
        apiClient: fakeApi,
        storageService: storageService,
        googleAuthService: mockGoogleAuth,
      );
    });

    test('initial state is unauthenticated and uninitialized', () {
      expect(authProvider.isAuthenticated, isFalse);
      expect(authProvider.user, isNull);
      expect(authProvider.isLoading, isFalse);
      expect(authProvider.isInitialized, isFalse);
    });

    test(
      'successful login saves token to secure storage and sets user',
      () async {
        await authProvider.login(
          email: 'dev@example.com',
          password: 'Password123!',
        );

        expect(authProvider.isAuthenticated, isTrue);
        expect(authProvider.user?.email, 'dev@example.com');
        expect(await storageService.getToken(), 'mock_jwt_token_123');
        expect(authProvider.errorMessage, isNull);
      },
    );

    test('failed login sets error message and rethrows ApiException', () async {
      fakeApi.shouldThrowLogin = true;
      fakeApi.loginException = const ApiException(
        message: 'Invalid email or password',
        statusCode: 401,
      );

      expect(
        () => authProvider.login(
          email: 'dev@example.com',
          password: 'WrongPassword',
        ),
        throwsA(isA<ApiException>()),
      );

      // Verify token is NOT saved
      expect(await storageService.hasToken(), isFalse);
      expect(authProvider.isAuthenticated, isFalse);
    });

    test(
      'unverified account login rethrows with isEmailVerified: false',
      () async {
        fakeApi.shouldThrowLogin = true;
        fakeApi.loginException = const ApiException(
          message: 'Your email address is not verified.',
          statusCode: 403,
          isEmailVerified: false,
          email: 'unverified@example.com',
        );

        try {
          await authProvider.login(
            email: 'unverified@example.com',
            password: 'Password123!',
          );
          fail('Should have thrown ApiException');
        } on ApiException catch (e) {
          expect(e.statusCode, 403);
          expect(e.isEmailVerified, isFalse);
          expect(e.email, 'unverified@example.com');
        }

        expect(await storageService.hasToken(), isFalse);
      },
    );

    test('verifyEmail saves token and establishes session', () async {
      await authProvider.verifyEmail(email: 'new@example.com', otp: '123456');

      expect(authProvider.isAuthenticated, isTrue);
      expect(authProvider.user?.isEmailVerified, isTrue);
      expect(await storageService.getToken(), 'mock_jwt_token_123');
    });

    test(
      'verifyEmail with invalid OTP throws exception and leaves session empty',
      () async {
        expect(
          () =>
              authProvider.verifyEmail(email: 'new@example.com', otp: '000000'),
          throwsA(isA<ApiException>()),
        );

        expect(await storageService.hasToken(), isFalse);
        expect(authProvider.isAuthenticated, isFalse);
      },
    );

    test('session restoration with valid token populates user', () async {
      await storageService.saveToken('existing_valid_token');

      await authProvider.checkAuthStatus();

      expect(authProvider.isInitialized, isTrue);
      expect(authProvider.isAuthenticated, isTrue);
      expect(authProvider.user?.name, 'Restored User');
    });

    test('session restoration with expired 401 token deletes token', () async {
      await storageService.saveToken('expired_token');
      fakeApi.shouldThrowGetMe = true;
      fakeApi.getMeException = const ApiException(
        message: 'Token has expired, please log in again',
        statusCode: 401,
      );

      await authProvider.checkAuthStatus();

      expect(authProvider.isAuthenticated, isFalse);
      expect(authProvider.user, isNull);
      expect(await storageService.hasToken(), isFalse);
    });

    test(
      'session restoration with network connectivity error preserves token',
      () async {
        await storageService.saveToken('valid_token_while_offline');
        fakeApi.shouldThrowGetMe = true;
        fakeApi.getMeException = const ApiException(
          message: 'Unable to connect to the server.',
          statusCode: 503,
        );

        await authProvider.checkAuthStatus();

        // Token must NOT be deleted just because server was unreachable
        expect(await storageService.hasToken(), isTrue);
        expect(authProvider.errorMessage, contains('Unable to connect'));
      },
    );

    test('logout deletes token from secure storage and resets user', () async {
      await authProvider.login(
        email: 'dev@example.com',
        password: 'Password123!',
      );
      expect(authProvider.isAuthenticated, isTrue);

      await authProvider.logout();

      expect(authProvider.isAuthenticated, isFalse);
      expect(authProvider.user, isNull);
      expect(await storageService.hasToken(), isFalse);
      expect(mockGoogleAuth.signedOut, isTrue);
    });

    test(
      'loginWithGoogle successfully stores platform token and sets user',
      () async {
        final success = await authProvider.loginWithGoogle();

        expect(success, isTrue);
        expect(authProvider.isAuthenticated, isTrue);
        expect(authProvider.user?.name, 'Google User');
        expect(authProvider.user?.authProvider, 'google');
        expect(await storageService.getToken(), fakeApi.mockToken);
      },
    );

    test(
      'loginWithGoogle returns false and preserves state on user cancellation',
      () async {
        mockGoogleAuth.shouldCancel = true;

        final success = await authProvider.loginWithGoogle();

        expect(success, isFalse);
        expect(authProvider.isAuthenticated, isFalse);
        expect(authProvider.errorMessage, isNull);
      },
    );

    test('loginWithGoogle sets error message on failure', () async {
      mockGoogleAuth.throwException = const ApiException(
        message: 'Google Sign-In configuration error',
        statusCode: 400,
      );

      await expectLater(
        authProvider.loginWithGoogle(),
        throwsA(isA<ApiException>()),
      );
      expect(authProvider.errorMessage, 'Google Sign-In configuration error');
    });

    test('updateProfile updates user state on success', () async {
      fakeApi.mockUser = const UserModel(
        id: 'usr_orig',
        name: 'Original Name',
        email: 'user@example.com',
      );

      final updated = await authProvider.updateProfile(name: 'New Name');

      expect(updated.name, 'New Name');
      expect(authProvider.user?.name, 'New Name');
      expect(authProvider.errorMessage, isNull);
    });
  });
}
