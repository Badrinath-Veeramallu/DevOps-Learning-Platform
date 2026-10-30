import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:devops_learning_app/core/api/api_client.dart';
import 'package:devops_learning_app/core/api/api_exceptions.dart';
import 'package:devops_learning_app/core/storage/secure_storage_service.dart';
import 'package:devops_learning_app/core/theme/app_theme.dart';
import 'package:devops_learning_app/features/pathway/data/activity_service.dart';
import 'package:devops_learning_app/features/pathway/data/progress_service.dart';
import 'package:devops_learning_app/features/profile/widgets/activity_heatmap.dart';
import 'package:devops_learning_app/models/activity_model.dart';
import 'package:devops_learning_app/models/progress_model.dart';

/// Test in-memory storage implementing [ISecureStorageService].
class TestSecureStorage implements ISecureStorageService {
  String? _token = 'valid_test_jwt_token';
  final Map<String, String> _disk = {};

  @override
  Future<String?> getToken() async => _token;

  @override
  Future<void> saveToken(String token) async => _token = token;

  @override
  Future<void> deleteToken() async => _token = null;

  @override
  Future<bool> hasToken() async => _token != null && _token!.isNotEmpty;

  @override
  Future<String?> read(String key) async => _disk[key];

  @override
  Future<void> write(String key, String value) async => _disk[key] = value;

  @override
  Future<void> delete(String key) async => _disk.remove(key);
}

/// Controllable mock [ApiClient] for deterministic API synchronization testing.
class MockSyncApiClient extends ApiClient {
  MockSyncApiClient({required super.storageService});

  Map<String, dynamic>? mockGetProgressResponse;
  Map<String, dynamic>? mockToggleProgressResponse;
  Map<String, dynamic>? mockActivityResponse;
  Map<String, dynamic>? mockLogActivityResponse;

  int getProgressCallCount = 0;
  int toggleProgressCallCount = 0;
  int logActivityCallCount = 0;
  int getActivityCallCount = 0;

  ApiException? throwOnToggle;
  ApiException? throwOnGetProgress;
  Completer<void>? toggleDelayCompleter;

  final Set<String> serverCompletedModules = {};
  final List<Map<String, dynamic>> loggedActivityPayloads = [];

  @override
  Future<Map<String, dynamic>> getProgress({String pathwayId = 'git'}) async {
    getProgressCallCount++;
    if (throwOnGetProgress != null) throw throwOnGetProgress!;
    return mockGetProgressResponse ??
        {
          'success': true,
          'pathwayId': pathwayId,
          'completedModules': serverCompletedModules.toList(),
        };
  }

  @override
  Future<Map<String, dynamic>> toggleProgress({
    required String moduleId,
    String pathwayId = 'git',
  }) async {
    toggleProgressCallCount++;
    if (toggleDelayCompleter != null) {
      await toggleDelayCompleter!.future;
    }
    if (throwOnToggle != null) throw throwOnToggle!;
    if (mockToggleProgressResponse != null) {
      return mockToggleProgressResponse!;
    }
    final bool isCompleted = !serverCompletedModules.contains(moduleId);
    if (isCompleted) {
      serverCompletedModules.add(moduleId);
    } else {
      serverCompletedModules.remove(moduleId);
    }
    return {
      'success': true,
      'pathwayId': pathwayId,
      'moduleId': moduleId,
      'isCompleted': isCompleted,
      'completedModules': serverCompletedModules.toList(),
    };
  }

  @override
  Future<Map<String, dynamic>> logActivity({
    required String type,
    required String stopSlug,
    String pathwayId = 'git',
  }) async {
    logActivityCallCount++;
    loggedActivityPayloads.add({
      'type': type,
      'stopSlug': stopSlug,
      'pathwayId': pathwayId,
    });
    return mockLogActivityResponse ?? {'success': true, 'logged': true};
  }

  @override
  Future<Map<String, dynamic>> getActivity({String? tz}) async {
    getActivityCallCount++;
    return mockActivityResponse ??
        {
          'total': 0,
          'days': <Map<String, dynamic>>[],
        };
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TestSecureStorage storage;
  late MockSyncApiClient mockApi;
  late ProgressService progressService;
  late ActivityService activityService;

  setUp(() {
    storage = TestSecureStorage();
    mockApi = MockSyncApiClient(storageService: storage);
    progressService = ProgressService();
    progressService.init(apiClient: mockApi, storageService: storage);
    progressService.clearCache();

    activityService = ActivityService();
    activityService.init(apiClient: mockApi, storageService: storage);
    activityService.clearCache();
  });

  tearDown(() {
    progressService.clearCache();
    activityService.clearCache();
  });

  group('Phase 6: Progress Tracking & Backend Synchronization Tests', () {
    test('1. Parsing actual backend progress responses into ProgressModel', () {
      final backendGetResponse = {
        'success': true,
        'pathwayId': 'git',
        'completedModules': ['git-01', 'git-02', 'git-03'],
      };

      final model = ProgressModel.fromJson(backendGetResponse);
      expect(model.pathway, equals('git'));
      expect(model.completedModules, containsAll(['git-01', 'git-02', 'git-03']));
      expect(model.isCompleted('git-01'), isTrue);
      expect(model.isCompleted('git-04'), isFalse);
      expect(model.isSynced, isTrue);

      final backendToggleResponse = {
        'success': true,
        'pathwayId': 'git',
        'moduleId': 'git-04',
        'isCompleted': true,
        'completedModules': ['git-01', 'git-02', 'git-03', 'git-04'],
      };
      final toggleModel = ProgressModel.fromJson(backendToggleResponse);
      expect(toggleModel.completedModules.length, equals(4));
      expect(toggleModel.isCompleted('git-04'), isTrue);
    });

    test('2. Loading existing completed modules via fetchUserProgress', () async {
      mockApi.mockGetProgressResponse = {
        'success': true,
        'pathwayId': 'git',
        'completedModules': ['git-01', 'git-02'],
      };

      final completed = await progressService.fetchUserProgress('user_abc');
      expect(completed, containsAll(['git-01', 'git-02']));
      expect(progressService.isModuleCompleted('user_abc', 'git-01'), isTrue);
      expect(progressService.isModuleCompleted('user_abc', 'git-02'), isTrue);
      expect(progressService.isModuleCompleted('user_abc', 'git-03'), isFalse);
      expect(progressService.isSynced('user_abc'), isTrue);
      expect(mockApi.getProgressCallCount, equals(1));
    });

    test('3. Marking a module complete updates local cache and commits to backend', () async {
      mockApi.mockToggleProgressResponse = {
        'success': true,
        'pathwayId': 'git',
        'moduleId': 'git-01',
        'isCompleted': true,
        'completedModules': ['git-01'],
      };

      expect(progressService.isModuleCompleted('user_abc', 'git-01'), isFalse);

      final isDone = await progressService.toggleModuleCompletion('user_abc', 'git-01');
      expect(isDone, isTrue);
      expect(progressService.isModuleCompleted('user_abc', 'git-01'), isTrue);
      expect(mockApi.toggleProgressCallCount, equals(1));
      expect(progressService.isSynced('user_abc'), isTrue);
    });

    test('4. Marking a module incomplete removes completion', () async {
      // Pre-set git-01 as completed
      progressService.setCompletedModulesCache('user_abc', {'git-01'});
      expect(progressService.isModuleCompleted('user_abc', 'git-01'), isTrue);

      mockApi.mockToggleProgressResponse = {
        'success': true,
        'pathwayId': 'git',
        'moduleId': 'git-01',
        'isCompleted': false,
        'completedModules': <String>[],
      };

      final isDone = await progressService.toggleModuleCompletion('user_abc', 'git-01');
      expect(isDone, isFalse);
      expect(progressService.isModuleCompleted('user_abc', 'git-01'), isFalse);
      expect(mockApi.toggleProgressCallCount, equals(1));
    });

    test('5. Avoiding duplicate or concurrent toggle requests via mutation serialization', () async {
      final List<String> executionOrder = [];
      mockApi.mockToggleProgressResponse = {
        'success': true,
        'pathwayId': 'git',
        'moduleId': 'git-01',
        'isCompleted': true,
        'completedModules': ['git-01'],
      };

      // Dispatch two concurrent calls
      final f1 = progressService
          .toggleModuleCompletion('user_abc', 'git-01')
          .then((val) {
        executionOrder.add('first');
        return val;
      });
      final f2 = progressService
          .toggleModuleCompletion('user_abc', 'git-01')
          .then((val) {
        executionOrder.add('second');
        return val;
      });

      await Future.wait([f1, f2]);

      // Serialized order guaranteed
      expect(executionOrder, equals(['first', 'second']));
      expect(mockApi.toggleProgressCallCount, equals(2));

      // setModuleCompleted no-ops if already in desired state
      await progressService.setModuleCompleted('user_abc', 'git-01', true);
      expect(mockApi.toggleProgressCallCount, equals(2)); // No redundant toggle sent
    });

    test('6. Handling timeouts without blindly retrying toggle', () async {
      mockApi.throwOnToggle = const ApiException(
        message: 'Connection timed out',
        statusCode: 408,
      );

      // Safe GET reconciliation also fails (simulating server unreachable)
      mockApi.throwOnGetProgress = const ApiException(
        message: 'Server offline',
        statusCode: 503,
      );

      final isDone = await progressService.toggleModuleCompletion('user_abc', 'git-01');

      // Optimistic state was returned
      expect(isDone, isTrue);
      // Toggle was called ONCE - NEVER blindly retried
      expect(mockApi.toggleProgressCallCount, equals(1));
      // Fallback safe GET was attempted once
      expect(mockApi.getProgressCallCount, equals(1));
      // Marked as unsynced
      expect(progressService.isSynced('user_abc'), isFalse);
    });

    test('7. Reconciling uncertain request outcomes via safe GET verification', () async {
      mockApi.throwOnToggle = const ApiException(
        message: 'Gateway timeout',
        statusCode: 504,
      );

      // Server actually succeeded before timeout; GET reveals module was completed
      mockApi.mockGetProgressResponse = {
        'success': true,
        'pathwayId': 'git',
        'completedModules': ['git-01'],
      };

      final isDone = await progressService.toggleModuleCompletion('user_abc', 'git-01');

      expect(isDone, isTrue);
      expect(mockApi.toggleProgressCallCount, equals(1)); // Never retried toggle
      expect(mockApi.getProgressCallCount, equals(1)); // Safe GET verified server state
      expect(progressService.isSynced('user_abc'), isTrue);
      expect(progressService.isModuleCompleted('user_abc', 'git-01'), isTrue);
    });

    test('8. Handling offline mode preserves local changes gracefully', () async {
      mockApi.throwOnToggle = const ApiException(
        message: 'No internet connection',
        statusCode: 503,
      );
      mockApi.throwOnGetProgress = const ApiException(
        message: 'No internet connection',
        statusCode: 503,
      );

      final isDone = await progressService.toggleModuleCompletion('user_abc', 'git-02');

      // Local optimistic state preserved
      expect(isDone, isTrue);
      expect(progressService.isModuleCompleted('user_abc', 'git-02'), isTrue);
      expect(progressService.isSynced('user_abc'), isFalse);
    });

    test('9. Logging lesson activity records once per day without duplicates', () async {
      final logged1 = await activityService.logLessonViewed(
        userId: 'user_abc',
        stopSlug: 'git-01',
      );
      expect(logged1, isTrue);
      expect(mockApi.logActivityCallCount, equals(1));
      expect(mockApi.loggedActivityPayloads.first['type'], equals('lesson_viewed'));
      expect(mockApi.loggedActivityPayloads.first['stopSlug'], equals('git-01'));

      // Immediate second call on same day is deduplicated
      final logged2 = await activityService.logLessonViewed(
        userId: 'user_abc',
        stopSlug: 'git-01',
      );
      expect(logged2, isFalse);
      expect(mockApi.logActivityCallCount, equals(1)); // No duplicate API request
    });

    test('10. Logging animation completion records exactly once', () async {
      final logged = await activityService.logAnimationFinished(
        userId: 'user_abc',
        stopSlug: 'git-02',
      );
      expect(logged, isTrue);
      expect(mockApi.logActivityCallCount, equals(1));
      expect(mockApi.loggedActivityPayloads.first['type'], equals('animation_finished'));
      expect(mockApi.loggedActivityPayloads.first['stopSlug'], equals('git-02'));

      // Repeating does not log again
      final loggedAgain = await activityService.logAnimationFinished(
        userId: 'user_abc',
        stopSlug: 'git-02',
      );
      expect(loggedAgain, isFalse);
      expect(mockApi.logActivityCallCount, equals(1));
    });

    test('11. Parsing activity history model from GET /api/activity response', () {
      final json = {
        'total': 12,
        'days': [
          {'date': '2026-10-28', 'count': 3},
          {'date': '2026-10-29', 'count': 5},
          {'date': '2026-10-30', 'count': 4},
        ],
      };

      final history = ActivityHistoryModel.fromJson(json);
      expect(history.total, equals(12));
      expect(history.days.length, equals(3));
      expect(history.days[0].date, equals('2026-10-28'));
      expect(history.days[0].count, equals(3));

      final map = history.toCountsMap();
      expect(map['2026-10-29'], equals(5));
      expect(map['2026-10-30'], equals(4));
    });

    testWidgets('12. Rendering an empty heatmap without exceptions', (
      WidgetTester tester,
    ) async {
      mockApi.mockActivityResponse = {
        'total': 0,
        'days': <Map<String, dynamic>>[],
      };

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: ActivityHeatmap(
              apiClient: mockApi,
              initialTimezone: 'UTC',
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Renders title, subtitle, and 0 activities
      expect(find.text('Learning Activity'), findsOneWidget);
      expect(find.text('Your learning activity over the past year.'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
      expect(find.text('activities in the last year'), findsOneWidget);
      expect(find.text('Less'), findsOneWidget);
      expect(find.text('More'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    test('13. Preventing cached progress from leaking between different user accounts', () async {
      // User A marks git-01 and git-02 as completed
      progressService.setCompletedModulesCache('user_A', {'git-01', 'git-02'});

      expect(progressService.isModuleCompleted('user_A', 'git-01'), isTrue);
      expect(progressService.isModuleCompleted('user_A', 'git-02'), isTrue);

      // User B has no progress
      expect(progressService.isModuleCompleted('user_B', 'git-01'), isFalse);
      expect(progressService.isModuleCompleted('user_B', 'git-02'), isFalse);

      // Logout clears in-memory cache
      progressService.clearCache();
      expect(progressService.isModuleCompleted('user_A', 'git-01'), isFalse);

      // User B marks git-03
      progressService.setCompletedModulesCache('user_B', {'git-03'});
      expect(progressService.isModuleCompleted('user_B', 'git-03'), isTrue);
      expect(progressService.isModuleCompleted('user_A', 'git-03'), isFalse);
    });
  });

  group('Phase 6 Review: ProgressService Synchronization Safety Edge Cases', () {
    test('1. Offline completion followed by successful server fetch (preserves completion)', () async {
      // Simulate offline: both toggle and fallback GET fail
      mockApi.throwOnToggle = const ApiException(message: 'Offline', statusCode: 503);
      mockApi.throwOnGetProgress = const ApiException(message: 'Offline', statusCode: 503);

      final isDone = await progressService.toggleModuleCompletion('user_offline', 'git-01');
      expect(isDone, isTrue);
      expect(progressService.isModuleCompleted('user_offline', 'git-01'), isTrue);
      expect(progressService.getSyncStatus('user_offline'), equals(SyncStatus.offline));
      expect(progressService.isSynced('user_offline'), isFalse);

      // Verify pending change is tracked
      final pending = progressService.getPendingChanges('user_offline');
      expect(pending['git-01'], isTrue);

      // Now server comes back online, but server DB has not recorded git-01 yet (completedModules: [])
      mockApi.throwOnToggle = null;
      mockApi.throwOnGetProgress = null;
      mockApi.mockGetProgressResponse = {
        'success': true,
        'pathwayId': 'git',
        'completedModules': <String>[],
      };

      // fetchUserProgress must reconcile pending local changes and NOT overwrite them with []
      final completed = await progressService.fetchUserProgress('user_offline');
      expect(completed, contains('git-01'));
      expect(progressService.isModuleCompleted('user_offline', 'git-01'), isTrue);
      expect(progressService.getSyncStatus('user_offline'), equals(SyncStatus.pending));
    });

    test('2. Offline incompletion followed by successful server fetch (preserves incompletion)', () async {
      // Pre-condition: user has git-01 completed
      progressService.setCompletedModulesCache('user_offline_2', {'git-01'});
      expect(progressService.isModuleCompleted('user_offline_2', 'git-01'), isTrue);

      // Go offline
      mockApi.throwOnToggle = const ApiException(message: 'Offline', statusCode: 503);
      mockApi.throwOnGetProgress = const ApiException(message: 'Offline', statusCode: 503);

      // User marks git-01 incomplete while offline
      final isDone = await progressService.toggleModuleCompletion('user_offline_2', 'git-01');
      expect(isDone, isFalse);
      expect(progressService.isModuleCompleted('user_offline_2', 'git-01'), isFalse);

      final pending = progressService.getPendingChanges('user_offline_2');
      expect(pending['git-01'], isFalse);

      // Back online: server still holds old completed state ['git-01']
      mockApi.throwOnToggle = null;
      mockApi.throwOnGetProgress = null;
      mockApi.mockGetProgressResponse = {
        'success': true,
        'pathwayId': 'git',
        'completedModules': ['git-01'],
      };

      // fetchUserProgress must NOT blindly union and must NOT overwrite the local incompletion
      final completed = await progressService.fetchUserProgress('user_offline_2');
      expect(completed, isNot(contains('git-01')));
      expect(progressService.isModuleCompleted('user_offline_2', 'git-01'), isFalse);
    });

    test('3. Pending local changes are never silently discarded', () async {
      mockApi.throwOnToggle = const ApiException(message: 'Offline', statusCode: 503);
      mockApi.throwOnGetProgress = const ApiException(message: 'Offline', statusCode: 503);

      await progressService.toggleModuleCompletion('user_persist', 'git-02');
      expect(progressService.isModuleCompleted('user_persist', 'git-02'), isTrue);

      // Check pending changes in service
      expect(progressService.getPendingChanges('user_persist')['git-02'], isTrue);

      // Simulate app restart / memory cache wipe
      progressService.clearCache();
      expect(progressService.isModuleCompleted('user_persist', 'git-02'), isFalse);

      // Reading stored progress must re-load pending changes from disk storage
      final restored = await progressService.getCompletedModules('user_persist');
      expect(restored, contains('git-02'));
      expect(progressService.isModuleCompleted('user_persist', 'git-02'), isTrue);
    });

    test('4. Two rapid completions on different modules', () async {
      mockApi.mockToggleProgressResponse = null; // Use dynamic logic if any or default

      final f1 = progressService.toggleModuleCompletion('user_rapid', 'git-01');
      final f2 = progressService.toggleModuleCompletion('user_rapid', 'git-02');

      final results = await Future.wait([f1, f2]);
      expect(results[0], isTrue);
      expect(results[1], isTrue);

      expect(progressService.isModuleCompleted('user_rapid', 'git-01'), isTrue);
      expect(progressService.isModuleCompleted('user_rapid', 'git-02'), isTrue);
      expect(mockApi.toggleProgressCallCount, equals(2));
    });

    test('5. Two rapid operations on the same module', () async {
      // User rapidly clicks complete then undo
      final f1 = progressService.toggleModuleCompletion('user_toggle_same', 'git-01');
      final f2 = progressService.toggleModuleCompletion('user_toggle_same', 'git-01');

      final results = await Future.wait([f1, f2]);
      expect(results[0], isTrue);
      expect(results[1], isFalse);

      expect(progressService.isModuleCompleted('user_toggle_same', 'git-01'), isFalse);
      expect(mockApi.toggleProgressCallCount, equals(2));
    });

    test('6. Concurrent setModuleCompleted() calls are serialized and idempotent', () async {
      // 3 concurrent calls wanting the exact same state (completed: true)
      final f1 = progressService.setModuleCompleted('user_idemp', 'git-01', true);
      final f2 = progressService.setModuleCompleted('user_idemp', 'git-01', true);
      final f3 = progressService.setModuleCompleted('user_idemp', 'git-01', true);

      await Future.wait([f1, f2, f3]);

      expect(progressService.isModuleCompleted('user_idemp', 'git-01'), isTrue);
      // Only the first call actually triggered a toggle; the 2nd and 3rd safely no-oped
      expect(mockApi.toggleProgressCallCount, equals(1));
    });

    test('7. Server response arriving while another mutation is pending does not overwrite newer state', () async {
      // Start with git-01 completed on server and locally
      mockApi.serverCompletedModules.add('git-01');
      progressService.setCompletedModulesCache('user_race', {'git-01'});

      // Queue an unmark of git-01
      final f1 = progressService.toggleModuleCompletion('user_race', 'git-01'); // desired: false
      // Queue an addition of git-02
      final f2 = progressService.toggleModuleCompletion('user_race', 'git-02'); // desired: true

      await Future.wait([f1, f2]);

      expect(progressService.isModuleCompleted('user_race', 'git-01'), isFalse);
      expect(progressService.isModuleCompleted('user_race', 'git-02'), isTrue);
    });

    test('8. Timeout followed by successful GET reconciliation', () async {
      mockApi.throwOnToggle = const ApiException(message: 'Timeout', statusCode: 408);
      // Safe GET reveals that backend actually committed the toggle!
      mockApi.mockGetProgressResponse = {
        'success': true,
        'pathwayId': 'git',
        'completedModules': ['git-03'],
      };

      final isDone = await progressService.toggleModuleCompletion('user_timeout', 'git-03');
      expect(isDone, isTrue);
      expect(progressService.isModuleCompleted('user_timeout', 'git-03'), isTrue);
      expect(mockApi.toggleProgressCallCount, equals(1)); // Never retried toggle
      expect(mockApi.getProgressCallCount, equals(1)); // Safe GET verified server
      expect(progressService.getSyncStatus('user_timeout'), equals(SyncStatus.synced));
      expect(progressService.isSynced('user_timeout'), isTrue);
    });

    test('9. Timeout followed by failed GET keeps optimistic state and marks offline', () async {
      mockApi.throwOnToggle = const ApiException(message: 'Timeout', statusCode: 408);
      mockApi.throwOnGetProgress = const ApiException(message: 'Server error', statusCode: 500);

      final isDone = await progressService.toggleModuleCompletion('user_double_err', 'git-03');
      expect(isDone, isTrue);
      // Preserved optimistically
      expect(progressService.isModuleCompleted('user_double_err', 'git-03'), isTrue);
      expect(progressService.getSyncStatus('user_double_err'), equals(SyncStatus.offline));
      expect(progressService.isSynced('user_double_err'), isFalse);
    });

    test('10. Guest progress correctly reported as local-only', () async {
      final isDone = await progressService.toggleModuleCompletion('guest', 'git-01');
      expect(isDone, isTrue);
      expect(progressService.isModuleCompleted('guest', 'git-01'), isTrue);
      expect(progressService.getSyncStatus('guest'), equals(SyncStatus.localOnly));
      expect(progressService.isSynced('guest'), isFalse);
      expect(mockApi.toggleProgressCallCount, equals(0)); // Zero API requests made
    });

    test('11. Authenticated progress correctly reported as synced only after confirmation', () async {
      mockApi.mockToggleProgressResponse = {
        'success': true,
        'pathwayId': 'git',
        'moduleId': 'git-01',
        'isCompleted': true,
        'completedModules': ['git-01'],
      };

      final isDone = await progressService.toggleModuleCompletion('user_auth', 'git-01');
      expect(isDone, isTrue);
      expect(progressService.getSyncStatus('user_auth'), equals(SyncStatus.synced));
      expect(progressService.isSynced('user_auth'), isTrue);
    });

    test('12. Logout during queued mutations isolates pending state', () async {
      // Simulate user logging out by calling clearCache
      progressService.setCompletedModulesCache('user_logged_out', {'git-01'});
      progressService.clearCache();

      // Memory cache is clean
      expect(progressService.isModuleCompleted('user_logged_out', 'git-01'), isFalse);
      expect(progressService.isSynced('user_logged_out'), isFalse);
    });

    test('13. Account switching without cross-account state leakage', () async {
      mockApi.serverCompletedModules.clear();
      await storage.saveToken('token_user_A');

      // Account A completes git-01
      await progressService.setModuleCompleted('user_account_A', 'git-01', true);
      expect(progressService.isModuleCompleted('user_account_A', 'git-01'), isTrue);
      expect(progressService.isModuleCompleted('user_account_B', 'git-01'), isFalse);

      // Account A logs out
      progressService.clearCache();
      await storage.deleteToken();

      // Account B logs in
      mockApi.serverCompletedModules.clear();
      await storage.saveToken('token_user_B');

      // Account B completes git-02
      await progressService.setModuleCompleted('user_account_B', 'git-02', true);
      expect(progressService.isModuleCompleted('user_account_B', 'git-02'), isTrue);
      expect(progressService.isModuleCompleted('user_account_A', 'git-02'), isFalse);

      // Verify each account preserves its own distinct modules
      final setA = await progressService.getCompletedModules('user_account_A');
      final setB = await progressService.getCompletedModules('user_account_B');

      expect(setA, equals({'git-01'}));
      expect(setB, equals({'git-02'}));
    });
  });
}
