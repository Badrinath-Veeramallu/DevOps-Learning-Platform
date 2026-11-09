import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:devops_learning_app/core/api/api_client.dart';
import 'package:devops_learning_app/core/api/api_exceptions.dart';
import 'package:devops_learning_app/core/auth/google_auth_service.dart';
import 'package:devops_learning_app/core/storage/secure_storage_service.dart';
import 'package:devops_learning_app/features/pathway/data/progress_service.dart';
import 'package:devops_learning_app/providers/auth_provider.dart';

/// Test storage allowing deterministic interception of token operations.
class ControllableSecureStorage implements ISecureStorageService {
  String? _token;
  int _tokenVersion = 0;
  final Map<String, String> _disk = {};

  Completer<void>? getTokenDelayCompleter;
  Completer<void>? getTokenStartedCompleter;

  @override
  int get tokenVersion => _tokenVersion;

  @override
  Future<String?> getToken() async {
    if (getTokenStartedCompleter != null &&
        !getTokenStartedCompleter!.isCompleted) {
      getTokenStartedCompleter!.complete();
    }
    if (getTokenDelayCompleter != null) {
      await getTokenDelayCompleter!.future;
    }
    return _token;
  }

  @override
  Future<void> saveToken(String token) async {
    _tokenVersion++;
    _token = token;
  }

  @override
  Future<void> deleteToken() async {
    _tokenVersion++;
    _token = null;
  }

  @override
  Future<bool> hasToken() async => _token != null && _token!.isNotEmpty;

  @override
  Future<String?> read(String key) async => _disk[key];

  @override
  Future<void> write(String key, String value) async => _disk[key] = value;

  @override
  Future<void> delete(String key) async => _disk.remove(key);
}

/// Controllable [HttpClientAdapter] that intercepts executed requests and allows delaying responses.
class ControllableHttpClientAdapter implements HttpClientAdapter {
  final List<RequestOptions> executedRequests = [];
  Completer<void>? fetchStartedCompleter;
  Completer<void>? responseDelayCompleter;
  ResponseBody Function(RequestOptions options)? onFetch;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    executedRequests.add(options);
    if (fetchStartedCompleter != null && !fetchStartedCompleter!.isCompleted) {
      fetchStartedCompleter!.complete();
    }
    if (responseDelayCompleter != null) {
      await responseDelayCompleter!.future;
    }
    if (onFetch != null) {
      return onFetch!(options);
    }
    return ResponseBody.fromString(
      jsonEncode({
        'success': true,
        'pathwayId': 'git',
        'completedModules': ['git-01'],
      }),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ControllableSecureStorage storage;
  late ControllableHttpClientAdapter adapter;
  late Dio dio;
  late ApiClient apiClient;

  setUp(() {
    storage = ControllableSecureStorage();
    adapter = ControllableHttpClientAdapter();
    dio = Dio(BaseOptions(baseUrl: 'https://test.api'))..httpClientAdapter = adapter;
    apiClient = ApiClient(dio: dio, storageService: storage);
  });

  group('AuthInterceptor: Normal Operation & Token Injection', () {
    test('1. Injects Authorization Bearer header when token exists', () async {
      await storage.saveToken('jwt_user_123');

      final res = await apiClient.getProgress(pathwayId: 'git');
      expect(res['success'], isTrue);

      expect(adapter.executedRequests.length, equals(1));
      final executed = adapter.executedRequests.first;
      expect(executed.headers['Authorization'], equals('Bearer jwt_user_123'));
    });

    test('2. Unauthenticated request proceeds without Authorization header when no token exists', () async {
      adapter.onFetch = (opts) => ResponseBody.fromString(
            jsonEncode({
              'token': 'new_jwt_456',
              'user': {
                'id': 'u2',
                'name': 'User 2',
                'email': 'u2@test.com',
                'isVerified': true,
              },
            }),
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );

      final result = await apiClient.login(
        email: 'u2@test.com',
        password: 'Password123!',
      );
      expect(result.token, equals('new_jwt_456'));

      expect(adapter.executedRequests.length, equals(1));
      final executed = adapter.executedRequests.first;
      expect(executed.headers.containsKey('Authorization'), isFalse);
    });
  });

  group('AuthInterceptor & AuthProvider Race Condition Tests', () {
    test('1. A request waiting for token retrieval while logout occurs is safely rejected and never sent to the network', () async {
      await storage.saveToken('token_user_A');

      final getTokenStarted = Completer<void>();
      final getTokenDelay = Completer<void>();
      storage.getTokenStartedCompleter = getTokenStarted;
      storage.getTokenDelayCompleter = getTokenDelay;

      // Start an authenticated request
      final requestFuture = apiClient.getProgress(pathwayId: 'git');

      // Wait until the request has entered AuthInterceptor.onRequest and is awaiting storage.getToken()
      await getTokenStarted.future;

      // Logout occurs while token retrieval is in flight
      await storage.deleteToken();

      // Token retrieval finishes after logout
      getTokenDelay.complete();

      // Expect request to be rejected with cancellation DioException / ApiException
      await expectLater(
        requestFuture,
        throwsA(isA<ApiException>().having(
          (e) => e.message,
          'message',
          contains('cancelled'),
        )),
      );

      // Verify the request was NEVER sent over the network
      expect(adapter.executedRequests, isEmpty);
    });

    test('2. Ensuring a request waiting for token retrieval cannot accidentally use User B\'s token after account switch', () async {
      await storage.saveToken('token_user_A');

      final getTokenStarted = Completer<void>();
      final getTokenDelay = Completer<void>();
      storage.getTokenStartedCompleter = getTokenStarted;
      storage.getTokenDelayCompleter = getTokenDelay;

      // User A initiates an authenticated progress toggle
      final requestFuture = apiClient.toggleProgress(moduleId: 'git-01');

      // Wait until AuthInterceptor is awaiting storage.getToken()
      await getTokenStarted.future;

      // User A logs out and User B logs in during token retrieval
      await storage.deleteToken();
      await storage.saveToken('token_user_B');

      // Allow the delayed getToken() call to finish
      getTokenDelay.complete();

      // Request must be rejected because storage was modified during token retrieval
      await expectLater(
        requestFuture,
        throwsA(isA<ApiException>().having(
          (e) => e.message,
          'message',
          contains('cancelled'),
        )),
      );

      // CRITICAL ASSERTION: The request was NEVER sent with User B's token!
      expect(adapter.executedRequests, isEmpty);
      for (final req in adapter.executedRequests) {
        expect(req.headers['Authorization'], isNot(equals('Bearer token_user_B')));
      }
    });

    test('3. A User A request completing after User B logs in does not throw uncaught errors', () async {
      await storage.saveToken('token_user_A');

      final fetchStarted = Completer<void>();
      final responseDelay = Completer<void>();
      adapter.fetchStartedCompleter = fetchStarted;
      adapter.responseDelayCompleter = responseDelay;

      // User A initiates a request that successfully passes AuthInterceptor and enters network adapter
      final requestFuture = apiClient.toggleProgress(moduleId: 'git-01');

      // Wait until request has reached the network adapter
      await fetchStarted.future;
      expect(adapter.executedRequests.length, equals(1));
      expect(
        adapter.executedRequests.first.headers['Authorization'],
        equals('Bearer token_user_A'),
      );

      // User A logs out and User B logs in while HTTP request is in-flight on the network
      await storage.deleteToken();
      await storage.saveToken('token_user_B');

      // The backend finally returns response for User A's HTTP call
      responseDelay.complete();

      final res = await requestFuture;
      expect(res['success'], isTrue);
      expect(res['completedModules'], contains('git-01'));
    });

    test('4. Ensuring an old request completing after account switch cannot update User B\'s local progress', () async {
      await storage.saveToken('token_user_A');

      final fetchStarted = Completer<void>();
      final responseDelay = Completer<void>();
      adapter.fetchStartedCompleter = fetchStarted;
      adapter.responseDelayCompleter = responseDelay;

      final progressService = ProgressService();
      progressService.init(apiClient: apiClient, storageService: storage);
      progressService.clearCache();

      final authProvider = AuthProvider(
        apiClient: apiClient,
        storageService: storage,
        googleAuthService: GoogleAuthService(),
      );

      // 1. User A toggles module git-01
      final fA = progressService.toggleModuleCompletion('user_A', 'git-01');
      final checkA = expectLater(fA, throwsA(isA<StateError>()));

      // 2. Wait until User A's HTTP request is actively awaiting in the network adapter
      await fetchStarted.future;
      expect(adapter.executedRequests.length, equals(1));
      expect(
        adapter.executedRequests.first.headers['Authorization'],
        equals('Bearer token_user_A'),
      );

      // 3. User A logs out via AuthProvider (invalidates session, clears caches, deletes token)
      await authProvider.logout();

      // User A's active caller is immediately cancelled
      await checkA;

      // 4. User B logs in
      await storage.saveToken('token_user_B');

      // User B checks their progress before User A's network request returns
      expect(progressService.isModuleCompleted('user_B', 'git-01'), isFalse);
      expect(await progressService.getCompletedModules('user_B'), isEmpty);

      // 5. User A's delayed server response finally arrives
      adapter.onFetch = (opts) => ResponseBody.fromString(
            jsonEncode({
              'success': true,
              'pathwayId': 'git',
              'moduleId': 'git-01',
              'isCompleted': true,
              'completedModules': ['git-01'],
            }),
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
      responseDelay.complete();

      // Allow any microtasks and event loops to settle
      await Future.delayed(const Duration(milliseconds: 15));

      // CRITICAL ASSERTION: User A's late server response CANNOT update User B's local progress!
      expect(progressService.isModuleCompleted('user_B', 'git-01'), isFalse);
      expect(await progressService.getCompletedModules('user_B'), isEmpty);
      expect(progressService.isModuleCompleted('user_A', 'git-01'), isFalse);
      expect(progressService.getPendingChanges('user_B'), isEmpty);
      expect(progressService.activeMutationCount, equals(0));
    });
  });
}
