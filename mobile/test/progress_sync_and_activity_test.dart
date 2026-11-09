import 'dart:async';
import 'dart:convert';
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
  int _tokenVersion = 0;
  final Map<String, String> _disk = {};

  final Map<String, Completer<void>> readCompleterByKey = {};
  final Map<String, Completer<void>> writeCompleterByKey = {};
  final Map<String, Completer<void>> deleteCompleterByKey = {};

  Completer<void>? hasTokenDelayCompleter;

  @override
  int get tokenVersion => _tokenVersion;

  @override
  Future<String?> getToken() async => _token;

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
  Future<bool> hasToken() async {
    if (hasTokenDelayCompleter != null) {
      await hasTokenDelayCompleter!.future;
    }
    return _token != null && _token!.isNotEmpty;
  }

  @override
  Future<String?> read(String key) async {
    if (readCompleterByKey.containsKey(key)) {
      await readCompleterByKey[key]!.future;
    }
    return _disk[key];
  }

  @override
  Future<void> write(String key, String value) async {
    if (writeCompleterByKey.containsKey(key)) {
      await writeCompleterByKey[key]!.future;
    }
    _disk[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    if (deleteCompleterByKey.containsKey(key)) {
      await deleteCompleterByKey[key]!.future;
    }
    _disk.remove(key);
  }
}

/// Controllable mock [ApiClient] for deterministic API synchronization testing.
class MockSyncApiClient extends ApiClient {
  final ISecureStorageService testStorage;
  MockSyncApiClient({required super.storageService})
      : testStorage = storageService;

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
  ApiException? throwOnLogActivity;
  Completer<void>? toggleDelayCompleter;
  Completer<void>? toggleStartedCompleter;
  Completer<void>? getDelayCompleter;
  Completer<void>? logActivityDelayCompleter;

  final List<String> requestHistory = [];
  final Set<String> serverCompletedModules = {};
  final Map<String, Set<String>> serverCompletedModulesByToken = {};
  final List<Map<String, dynamic>> loggedActivityPayloads = [];

  Map<String, dynamic>? Function(String pathwayId)? onGetProgress;
  Map<String, dynamic>? Function(String moduleId, String pathwayId)? onToggleProgress;

  @override
  Future<Map<String, dynamic>> getProgress({String pathwayId = 'git'}) async {
    getProgressCallCount++;
    requestHistory.add('GET:$pathwayId');
    if (getDelayCompleter != null) {
      await getDelayCompleter!.future;
    }
    if (throwOnGetProgress != null) throw throwOnGetProgress!;
    if (onGetProgress != null) {
      final res = onGetProgress!(pathwayId);
      if (res != null) return res;
    }
    final token = await testStorage.getToken() ?? 'default_user';
    final set = serverCompletedModulesByToken.putIfAbsent(
      token,
      () => Set.from(serverCompletedModules),
    );
    return mockGetProgressResponse ??
        {
          'success': true,
          'pathwayId': pathwayId,
          'completedModules': set.toList(),
        };
  }

  @override
  Future<Map<String, dynamic>> toggleProgress({
    required String moduleId,
    String pathwayId = 'git',
  }) async {
    toggleProgressCallCount++;
    requestHistory.add('POST:$moduleId:$pathwayId');
    if (toggleStartedCompleter != null && !toggleStartedCompleter!.isCompleted) {
      toggleStartedCompleter!.complete();
    }
    final token = await testStorage.getToken() ?? 'default_user';
    if (toggleDelayCompleter != null) {
      await toggleDelayCompleter!.future;
    }
    if (throwOnToggle != null) throw throwOnToggle!;
    if (onToggleProgress != null) {
      final res = onToggleProgress!(moduleId, pathwayId);
      if (res != null) return res;
    }
    if (mockToggleProgressResponse != null) {
      return mockToggleProgressResponse!;
    }
    final set = serverCompletedModulesByToken.putIfAbsent(
      token,
      () => Set.from(serverCompletedModules),
    );
    final bool isCompleted = !set.contains(moduleId);
    if (isCompleted) {
      set.add(moduleId);
    } else {
      set.remove(moduleId);
    }
    return {
      'success': true,
      'pathwayId': pathwayId,
      'moduleId': moduleId,
      'isCompleted': isCompleted,
      'completedModules': set.toList(),
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
    if (logActivityDelayCompleter != null) {
      await logActivityDelayCompleter!.future;
    }
    if (throwOnLogActivity != null) {
      throw throwOnLogActivity!;
    }
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
    mockApi.toggleStartedCompleter = null;
    mockApi.toggleDelayCompleter = null;
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
      mockApi.mockToggleProgressResponse = null;
      mockApi.serverCompletedModulesByToken.clear();

      // Dispatch two concurrent calls on different modules
      final f1 = progressService
          .toggleModuleCompletion('user_abc', 'git-01')
          .then((val) {
        executionOrder.add('first');
        return val;
      });
      final f2 = progressService
          .toggleModuleCompletion('user_abc', 'git-02')
          .then((val) {
        executionOrder.add('second');
        return val;
      });

      await Future.wait([f1, f2]);

      // Serialized order guaranteed
      expect(executionOrder, equals(['first', 'second']));
      expect(mockApi.toggleProgressCallCount, equals(2));

      // setModuleCompleted no-ops if already in desired state with no pending
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
      expect(progressService.getSyncStatus('user_offline'), equals(SyncStatus.synced));
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

  group('Phase 6 Final: Queue Concurrency, Session Invalidation & Response Validation Tests', () {
    test('1. Queue: 4 operations strictly serialized, 3rd arrives while 2nd is running, max concurrency == 1', () async {
      progressService.resetMaxObservedConcurrent();
      final List<String> executionOrder = [];
      final c1 = Completer<void>();
      final c2 = Completer<void>();

      // Operation 1
      mockApi.toggleDelayCompleter = c1;
      final f1 = progressService.toggleModuleCompletion('user_q', 'git-01').then((val) {
        executionOrder.add('op1');
        return val;
      });

      // Operation 2 queued while Op 1 is running
      final f2 = progressService.toggleModuleCompletion('user_q', 'git-02').then((val) {
        executionOrder.add('op2');
        return val;
      });

      // Finish Op 1, Op 2 will start running
      mockApi.toggleDelayCompleter = c2;
      c1.complete();

      // Small async tick so Op 2 begins running
      await Future.delayed(const Duration(milliseconds: 10));

      // Operation 3 arrives while Op 2 is actively running!
      final f3 = progressService.toggleModuleCompletion('user_q', 'git-03').then((val) {
        executionOrder.add('op3');
        return val;
      });

      // Operation 4 queued behind Op 3
      final f4 = progressService.toggleModuleCompletion('user_q', 'git-04').then((val) {
        executionOrder.add('op4');
        return val;
      });

      // Finish Op 2, then Op 3 and 4 can complete
      mockApi.toggleDelayCompleter = null;
      c2.complete();

      await Future.wait([f1, f2, f3, f4]);

      expect(executionOrder, equals(['op1', 'op2', 'op3', 'op4']));
      expect(progressService.maxObservedConcurrent, equals(1));
      expect(progressService.activeMutationCount, equals(0));
      expect(progressService.queuedMutationCount, equals(0));
    });

    test('2. Queue: Exception in an operation does not block subsequent queued operations', () async {
      progressService.resetMaxObservedConcurrent();
      final List<String> executionOrder = [];

      // Op 1 succeeds
      final f1 = progressService.toggleModuleCompletion('user_err_q', 'git-01').then((_) {
        executionOrder.add('op1');
      });

      // Op 2 encounters server error
      mockApi.throwOnToggle = const ApiException(message: 'Fatal network error', statusCode: 500);
      mockApi.throwOnGetProgress = const ApiException(message: 'Fatal network error', statusCode: 500);
      final f2 = progressService.toggleModuleCompletion('user_err_q', 'git-02').then((_) {
        executionOrder.add('op2');
      });

      // Op 3 succeeds after Op 2
      final f3 = progressService.toggleModuleCompletion('user_err_q', 'git-03').then((_) {
        executionOrder.add('op3');
      });

      mockApi.throwOnToggle = null;
      mockApi.throwOnGetProgress = null;

      await Future.wait([f1, f2, f3]);

      expect(executionOrder, equals(['op1', 'op2', 'op3']));
      expect(progressService.maxObservedConcurrent, equals(1));
    });

    test('3. Session: Logout while an operation is running invalidates operation and prevents mutating new state', () async {
      final c1 = Completer<void>();
      mockApi.toggleDelayCompleter = c1;

      // Op starts under User A
      final f1 = progressService.toggleModuleCompletion('user_A', 'git-01');

      await Future.delayed(const Duration(milliseconds: 5));

      // User A logs out while Op 1 is waiting on network
      progressService.clearCache();

      // Op 1 network response finally arrives
      c1.complete();
      mockApi.toggleDelayCompleter = null;

      // The caller of the old operation receives an invalidation error
      await expectLater(f1, throwsA(isA<StateError>()));

      // In-memory cache remains empty and does not contain git-01
      expect(progressService.isModuleCompleted('user_A', 'git-01'), isFalse);
    });

    test('4. Session: Logout while several operations are queued cancels queued operations without executing them', () async {
      final c1 = Completer<void>();
      mockApi.toggleDelayCompleter = c1;

      final f1 = progressService.toggleModuleCompletion('user_A', 'git-01');
      final f2 = progressService.toggleModuleCompletion('user_A', 'git-02');
      final f3 = progressService.toggleModuleCompletion('user_A', 'git-03');

      final check1 = expectLater(f1, throwsA(isA<StateError>()));
      final check2 = expectLater(f2, throwsA(isA<StateError>()));
      final check3 = expectLater(f3, throwsA(isA<StateError>()));

      // Allow Op 1 to reach network completer while Op 2 and Op 3 remain queued
      await Future.delayed(const Duration(milliseconds: 5));

      // Logout cancels everything
      progressService.clearCache();

      c1.complete();
      mockApi.toggleDelayCompleter = null;

      await Future.wait([check1, check2, check3]);

      // Op 2 and Op 3 never made API requests (only Op 1 started before logout)
      expect(mockApi.toggleProgressCallCount, equals(1));
    });

    test('5. Session: Account B logging in while operation from Account A is pending does not cross-pollute', () async {
      mockApi.serverCompletedModules.clear();
      mockApi.serverCompletedModulesByToken.clear();
      await storage.saveToken('token_user_A');

      final cA = Completer<void>();
      mockApi.toggleDelayCompleter = cA;

      // Account A queues Op A1
      final fA = progressService.toggleModuleCompletion('user_A', 'git-01');
      final checkA = expectLater(fA, throwsA(isA<StateError>()));

      await Future.delayed(const Duration(milliseconds: 5));

      // Account A logs out
      progressService.clearCache();
      await storage.deleteToken();

      // Account B logs in
      await storage.saveToken('token_user_B');
      final fB = progressService.toggleModuleCompletion('user_B', 'git-02');

      // Op A finishes its HTTP call
      cA.complete();
      mockApi.toggleDelayCompleter = null;

      // Op A was rejected due to invalidation
      await checkA;

      // Op B completes cleanly
      final resultB = await fB;
      expect(resultB, isTrue);

      // Account B only has git-02, NOT git-01
      expect(progressService.isModuleCompleted('user_B', 'git-02'), isTrue);
      expect(progressService.isModuleCompleted('user_B', 'git-01'), isFalse);
      expect(progressService.isModuleCompleted('user_A', 'git-01'), isFalse);
    });

    test('6. Session: Old responses arriving after logout are ignored and do not update cache or disk', () async {
      final c1 = Completer<void>();
      mockApi.toggleDelayCompleter = c1;
      mockApi.mockToggleProgressResponse = {
        'success': true,
        'pathwayId': 'git',
        'moduleId': 'git-01',
        'isCompleted': true,
        'completedModules': ['git-01'],
      };

      final f1 = progressService.toggleModuleCompletion('user_stale', 'git-01');
      await Future.delayed(const Duration(milliseconds: 5));

      // Logout occurs before server responds
      progressService.clearCache();

      c1.complete();
      mockApi.toggleDelayCompleter = null;

      await expectLater(f1, throwsA(isA<StateError>()));

      // In-memory cache must not be updated by the stale server response
      expect(progressService.isModuleCompleted('user_stale', 'git-01'), isFalse);
    });

    test('7. Session: Stale operation attempting fallback GET after logout aborts without extra API call', () async {
      // Toggle fails
      mockApi.throwOnToggle = const ApiException(message: 'Timeout', statusCode: 408);
      final c1 = Completer<void>();
      mockApi.toggleDelayCompleter = c1;

      final f1 = progressService.toggleModuleCompletion('user_abort', 'git-01');
      await Future.delayed(const Duration(milliseconds: 5));

      // User logs out while toggle is waiting
      progressService.clearCache();

      c1.complete();
      mockApi.toggleDelayCompleter = null;

      await expectLater(f1, throwsA(isA<StateError>()));

      // The fallback GET was NEVER initiated because session generation changed
      expect(mockApi.getProgressCallCount, equals(0));
    });

    test('8. Response Validation: success: false is treated as unconfirmed and triggers safe GET reconciliation', () async {
      mockApi.mockToggleProgressResponse = {
        'success': false,
        'message': 'Module locked',
      };
      // Fallback GET succeeds and reveals git-01 was completed
      mockApi.mockGetProgressResponse = {
        'success': true,
        'pathwayId': 'git',
        'completedModules': ['git-01'],
      };

      final isDone = await progressService.toggleModuleCompletion('user_val', 'git-01');
      expect(isDone, isTrue);
      expect(progressService.isModuleCompleted('user_val', 'git-01'), isTrue);
      expect(mockApi.toggleProgressCallCount, equals(1));
      expect(mockApi.getProgressCallCount, equals(1)); // Safe GET was called!
      expect(progressService.getSyncStatus('user_val'), equals(SyncStatus.synced));
    });

    test('9. Response Validation: Missing completedModules is treated as unconfirmed and triggers safe GET', () async {
      mockApi.mockToggleProgressResponse = {
        'success': true,
        'isCompleted': true,
        // completedModules is missing!
      };
      mockApi.mockGetProgressResponse = {
        'success': true,
        'pathwayId': 'git',
        'completedModules': ['git-01'],
      };

      final isDone = await progressService.toggleModuleCompletion('user_val', 'git-01');
      expect(isDone, isTrue);
      expect(mockApi.getProgressCallCount, equals(1)); // Verified via safe GET
      expect(progressService.getSyncStatus('user_val'), equals(SyncStatus.synced));
    });

    test('10. Response Validation: Malformed response is treated as unconfirmed', () async {
      mockApi.mockToggleProgressResponse = {
        'status': 'ok', // malformed schema
      };
      mockApi.mockGetProgressResponse = {
        'success': true,
        'pathwayId': 'git',
        'completedModules': ['git-01'],
      };

      final isDone = await progressService.toggleModuleCompletion('user_val', 'git-01');
      expect(isDone, isTrue);
      expect(mockApi.getProgressCallCount, equals(1));
      expect(progressService.getSyncStatus('user_val'), equals(SyncStatus.synced));
    });

    test('11. Response Validation: Failed GET reconciliation after unsuccessful response preserves local intent and marks offline', () async {
      mockApi.mockToggleProgressResponse = {
        'success': false,
        'message': 'Internal Server Error',
      };
      mockApi.throwOnGetProgress = const ApiException(message: 'Server unreachable', statusCode: 503);

      final isDone = await progressService.toggleModuleCompletion('user_val_fail', 'git-01');
      // Local optimistic intent is preserved!
      expect(isDone, isTrue);
      expect(progressService.isModuleCompleted('user_val_fail', 'git-01'), isTrue);
      // Status is marked offline, NEVER claimed as synced!
      expect(progressService.getSyncStatus('user_val_fail'), equals(SyncStatus.offline));
      expect(progressService.isSynced('user_val_fail'), isFalse);
    });
  });

  group('Phase 6: Final Progress Synchronization & Deterministic Race-Condition Tests', () {
    test('1. A fetch response arriving after logout cannot restore stale progress', () async {
      mockApi.serverCompletedModulesByToken.clear();
      mockApi.serverCompletedModulesByToken['token_user_A'] = {'git-01', 'git-02'};
      await storage.saveToken('token_user_A');

      final cGet = Completer<void>();
      mockApi.getDelayCompleter = cGet;

      // Start fetch for user_A
      final fFetch = progressService.fetchUserProgress('user_A');
      final checkFetch = expectLater(fFetch, throwsA(isA<StateError>()));

      await Future.delayed(const Duration(milliseconds: 5));

      // User logs out while fetch is waiting on the network
      progressService.clearCache();
      await storage.deleteToken();

      // Server finally responds
      cGet.complete();
      mockApi.getDelayCompleter = null;

      // Caller receives cancellation error
      await checkFetch;

      // Verify user_A progress was NOT restored in memory
      expect(progressService.isModuleCompleted('user_A', 'git-01'), isFalse);
      expect(progressService.isModuleCompleted('user_A', 'git-02'), isFalse);
    });

    test('2. A fetch response arriving after account switching cannot modify the new account', () async {
      mockApi.serverCompletedModulesByToken.clear();
      mockApi.serverCompletedModulesByToken['token_user_A'] = {'git-01'};
      mockApi.serverCompletedModulesByToken['token_user_B'] = {'git-05'};
      await storage.saveToken('token_user_A');

      final cGetA = Completer<void>();
      mockApi.getDelayCompleter = cGetA;

      // User A starts fetch
      final fFetchA = progressService.fetchUserProgress('user_A');
      final checkFetchA = expectLater(fFetchA, throwsA(isA<StateError>()));

      // Allow User A fetch to reach network completer
      await Future.delayed(const Duration(milliseconds: 5));

      // User A logs out
      progressService.clearCache();
      await storage.deleteToken();

      // Delayed network response for User A arrives after logout
      cGetA.complete();
      mockApi.getDelayCompleter = null;
      await checkFetchA;

      // User B logs in and fetches progress
      await storage.saveToken('token_user_B');
      final setB = await progressService.fetchUserProgress('user_B');
      expect(setB, contains('git-05'));
      expect(setB, isNot(contains('git-01')));

      // Account B still only has git-05, NEVER git-01
      expect(progressService.isModuleCompleted('user_B', 'git-05'), isTrue);
      expect(progressService.isModuleCompleted('user_B', 'git-01'), isFalse);
      expect(progressService.isModuleCompleted('user_A', 'git-01'), isFalse);
    });

    test('3. A fetch overlapping a mutation cannot overwrite newer progress', () async {
      mockApi.serverCompletedModulesByToken.clear();
      mockApi.serverCompletedModulesByToken['valid_test_jwt_token'] = {'git-01'};

      final cGet = Completer<void>();
      mockApi.getDelayCompleter = cGet;

      // 1. Fetch started (server currently has git-01 completed)
      final fFetch = progressService.fetchUserProgress('user_race_overlap');

      // 2. User unmarks git-01 (desiredState: false)
      final fToggle = progressService.toggleModuleCompletion('user_race_overlap', 'git-01');

      // Release the fetch response
      cGet.complete();
      mockApi.getDelayCompleter = null;

      await Future.wait([fFetch, fToggle]);

      // git-01 must reflect the newer mutation (false), not the stale fetch (true)!
      expect(progressService.isModuleCompleted('user_race_overlap', 'git-01'), isFalse);
    });

    test('4. Offline completion is uploaded after connectivity returns', () async {
      mockApi.serverCompletedModulesByToken.clear();
      mockApi.serverCompletedModulesByToken['token_offline'] = <String>{};
      await storage.saveToken('token_offline');

      // Go offline
      mockApi.throwOnToggle = const ApiException(message: 'Offline', statusCode: 503);
      mockApi.throwOnGetProgress = const ApiException(message: 'Offline', statusCode: 503);

      // User marks git-01 complete offline
      final isDone = await progressService.toggleModuleCompletion('user_off_sync', 'git-01');
      expect(isDone, isTrue);
      expect(progressService.isModuleCompleted('user_off_sync', 'git-01'), isTrue);
      expect(progressService.getSyncStatus('user_off_sync'), equals(SyncStatus.offline));
      expect(progressService.getPendingChanges('user_off_sync')['git-01'], isTrue);

      // Connectivity returns!
      mockApi.throwOnToggle = null;
      mockApi.throwOnGetProgress = null;

      // fetchUserProgress runs: fetches server state ([]), discovers pending git-01, and uploads it
      final reconciled = await progressService.fetchUserProgress('user_off_sync');

      expect(reconciled, contains('git-01'));
      expect(progressService.isModuleCompleted('user_off_sync', 'git-01'), isTrue);
      // Pending change was successfully uploaded and confirmed!
      expect(progressService.getPendingChanges('user_off_sync'), isEmpty);
      expect(progressService.getSyncStatus('user_off_sync'), equals(SyncStatus.synced));
      expect(progressService.isSynced('user_off_sync'), isTrue);
      // Server DB now contains git-01
      expect(mockApi.serverCompletedModulesByToken['token_offline'], contains('git-01'));
    });

    test('5. Offline incompletion is uploaded after connectivity returns', () async {
      mockApi.serverCompletedModulesByToken.clear();
      mockApi.serverCompletedModulesByToken['token_offline_2'] = {'git-01'};
      await storage.saveToken('token_offline_2');

      // User starts with git-01 cached
      progressService.setCompletedModulesCache('user_off_unmark', {'git-01'});

      // Go offline
      mockApi.throwOnToggle = const ApiException(message: 'Offline', statusCode: 503);
      mockApi.throwOnGetProgress = const ApiException(message: 'Offline', statusCode: 503);

      // User unmarks git-01 offline
      final isDone = await progressService.toggleModuleCompletion('user_off_unmark', 'git-01');
      expect(isDone, isFalse);
      expect(progressService.isModuleCompleted('user_off_unmark', 'git-01'), isFalse);
      expect(progressService.getPendingChanges('user_off_unmark')['git-01'], isFalse);

      // Connectivity returns!
      mockApi.throwOnToggle = null;
      mockApi.throwOnGetProgress = null;

      // fetchUserProgress runs: discovers server has git-01 but local pending desires false, uploads toggle
      final reconciled = await progressService.fetchUserProgress('user_off_unmark');

      expect(reconciled, isNot(contains('git-01')));
      expect(progressService.isModuleCompleted('user_off_unmark', 'git-01'), isFalse);
      expect(progressService.getPendingChanges('user_off_unmark'), isEmpty);
      expect(progressService.getSyncStatus('user_off_unmark'), equals(SyncStatus.synced));
      // Server DB no longer contains git-01
      expect(mockApi.serverCompletedModulesByToken['token_offline_2'], isNot(contains('git-01')));
    });

    test('6. A pending change is removed only after server confirmation', () async {
      mockApi.serverCompletedModulesByToken.clear();
      mockApi.serverCompletedModulesByToken['valid_test_jwt_token'] = <String>{};

      // Toggle throws error
      mockApi.throwOnToggle = const ApiException(message: 'Internal Error', statusCode: 500);
      // Fallback GET also throws
      mockApi.throwOnGetProgress = const ApiException(message: 'Internal Error', statusCode: 500);

      await progressService.toggleModuleCompletion('user_pend_guard', 'git-02');

      // Must remain in pending!
      expect(progressService.getPendingChanges('user_pend_guard')['git-02'], isTrue);
      expect(progressService.getSyncStatus('user_pend_guard'), equals(SyncStatus.offline));
      expect(progressService.isSynced('user_pend_guard'), isFalse);
    });

    test('7. A successful but contradictory toggle response does not incorrectly mark progress synced', () async {
      // User requests git-01: true, but server mock buggy response returns completedModules: []
      mockApi.mockToggleProgressResponse = {
        'success': true,
        'pathwayId': 'git',
        'moduleId': 'git-01',
        'isCompleted': false,
        'completedModules': <String>[],
      };
      // Fallback GET also returns []
      mockApi.mockGetProgressResponse = {
        'success': true,
        'pathwayId': 'git',
        'completedModules': <String>[],
      };

      await progressService.toggleModuleCompletion('user_contradict', 'git-01');

      // Local optimistic intent preserved
      expect(progressService.isModuleCompleted('user_contradict', 'git-01'), isTrue);
      // Still pending because server contradictory response did NOT match desiredState
      expect(progressService.getPendingChanges('user_contradict')['git-01'], isTrue);
      expect(progressService.getSyncStatus('user_contradict'), equals(SyncStatus.pending));
      expect(progressService.isSynced('user_contradict'), isFalse);
    });

    test('8. A malformed toggle response triggers safe GET reconciliation', () async {
      mockApi.mockToggleProgressResponse = {
        'malformed': true,
      };
      mockApi.mockGetProgressResponse = {
        'success': true,
        'pathwayId': 'git',
        'completedModules': ['git-01'],
      };

      await progressService.toggleModuleCompletion('user_malform', 'git-01');

      expect(progressService.isModuleCompleted('user_malform', 'git-01'), isTrue);
      expect(mockApi.getProgressCallCount, equals(1)); // Safe GET was called!
      expect(progressService.getSyncStatus('user_malform'), equals(SyncStatus.synced));
    });

    test('9. An uncertain toggle outcome never triggers a blind retry', () async {
      mockApi.throwOnToggle = const ApiException(message: 'Timeout', statusCode: 408);
      mockApi.throwOnGetProgress = const ApiException(message: 'Server error', statusCode: 500);

      await progressService.toggleModuleCompletion('user_no_retry', 'git-01');

      expect(mockApi.toggleProgressCallCount, equals(1)); // NEVER retried toggle!
      expect(mockApi.getProgressCallCount, equals(1)); // Only safe GET attempted
    });

    test('10. setModuleCompleted() reconciles an already-matching local state when a pending change exists', () async {
      mockApi.serverCompletedModulesByToken.clear();
      mockApi.serverCompletedModulesByToken['valid_test_jwt_token'] = <String>{};

      // Module git-01 was completed locally offline (pending: true)
      mockApi.throwOnToggle = const ApiException(message: 'Offline', statusCode: 503);
      mockApi.throwOnGetProgress = const ApiException(message: 'Offline', statusCode: 503);
      await progressService.toggleModuleCompletion('user_idemp_recon', 'git-01');
      expect(progressService.getPendingChanges('user_idemp_recon')['git-01'], isTrue);

      // Now back online
      mockApi.throwOnToggle = null;
      mockApi.throwOnGetProgress = null;

      // Calling setModuleCompleted with already-matching true must NOT blind-return;
      // it must safely reconcile the pending change!
      await progressService.setModuleCompleted('user_idemp_recon', 'git-01', true);

      expect(progressService.isModuleCompleted('user_idemp_recon', 'git-01'), isTrue);
      expect(progressService.getPendingChanges('user_idemp_recon'), isEmpty);
      expect(progressService.getSyncStatus('user_idemp_recon'), equals(SyncStatus.synced));
      expect(mockApi.serverCompletedModulesByToken['valid_test_jwt_token'], contains('git-01'));
    });

    test('11. Multiple pending changes reconcile sequentially', () async {
      mockApi.serverCompletedModulesByToken.clear();
      mockApi.serverCompletedModulesByToken['valid_test_jwt_token'] = <String>{};

      // Offline: mark git-01 and git-02 complete
      mockApi.throwOnToggle = const ApiException(message: 'Offline', statusCode: 503);
      mockApi.throwOnGetProgress = const ApiException(message: 'Offline', statusCode: 503);

      await progressService.toggleModuleCompletion('user_multi_pend', 'git-01');
      await progressService.toggleModuleCompletion('user_multi_pend', 'git-02');

      expect(progressService.getPendingChanges('user_multi_pend').length, equals(2));

      // Back online
      mockApi.throwOnToggle = null;
      mockApi.throwOnGetProgress = null;
      mockApi.requestHistory.clear();

      final reconciled = await progressService.fetchUserProgress('user_multi_pend');
      expect(reconciled, containsAll(['git-01', 'git-02']));
      expect(progressService.getPendingChanges('user_multi_pend'), isEmpty);
      expect(progressService.getSyncStatus('user_multi_pend'), equals(SyncStatus.synced));

      // Verifies GET was done first, then sequential POST toggles
      expect(mockApi.requestHistory, contains('GET:git'));
      expect(mockApi.requestHistory, contains('POST:git-01:git'));
      expect(mockApi.requestHistory, contains('POST:git-02:git'));
    });

    test('12. Failed reconciliation preserves pending changes across cache clearing and reload', () async {
      mockApi.throwOnToggle = const ApiException(message: 'Offline', statusCode: 503);
      mockApi.throwOnGetProgress = const ApiException(message: 'Offline', statusCode: 503);

      await progressService.toggleModuleCompletion('user_persist_pend', 'git-04');
      expect(progressService.getPendingChanges('user_persist_pend')['git-04'], isTrue);

      // Memory cache wiped (e.g. app killed / restarted)
      progressService.clearCache();

      // Reloading from storage restores pending changes
      final restored = await progressService.getCompletedModules('user_persist_pend');
      expect(restored, contains('git-04'));
      expect(progressService.getPendingChanges('user_persist_pend')['git-04'], isTrue);
    });

    test('13. A stale operation cannot write progress to disk after session invalidation', () async {
      final cToggle = Completer<void>();
      mockApi.toggleDelayCompleter = cToggle;

      final fOp = progressService.toggleModuleCompletion('user_stale_disk', 'git-01');

      // Logout occurs while toggle is awaiting
      progressService.clearCache();

      // Network returns
      cToggle.complete();
      mockApi.toggleDelayCompleter = null;

      await expectLater(fOp, throwsA(isA<StateError>()));

      // Read disk storage directly: must NOT have recorded git-01
      final raw = await storage.read('devops_progress_user_stale_disk_git');
      expect(raw == null || !raw.contains('git-01'), isTrue);
    });

    test('14. Repeated reconciliation does not toggle modules unnecessarily', () async {
      mockApi.serverCompletedModulesByToken.clear();
      mockApi.serverCompletedModulesByToken['valid_test_jwt_token'] = {'git-01'};

      // Sync user progress
      await progressService.fetchUserProgress('user_idemp_check');
      expect(progressService.isModuleCompleted('user_idemp_check', 'git-01'), isTrue);
      expect(progressService.getPendingChanges('user_idemp_check'), isEmpty);

      // Now call setModuleCompleted with already-synced git-01: true
      final beforeToggleCalls = mockApi.toggleProgressCallCount;
      await progressService.setModuleCompleted('user_idemp_check', 'git-01', true);

      // Zero new toggle calls made!
      expect(mockApi.toggleProgressCallCount, equals(beforeToggleCalls));
    });
  });

  group('Phase 6 Final: Session-Safe Storage & Completer Regression Tests', () {
    test('1. Pending-storage read completes after logout: no stale pending state is restored', () async {
      final key = 'devops_pending_user_reg1_git';
      await storage.write(key, json.encode({'git-01': true}));

      final cRead = Completer<void>();
      storage.readCompleterByKey[key] = cRead;

      // Start loading pending changes in session 0
      final fRead = progressService.loadPendingFromDisk('user_reg1', 'git');

      // Logout occurs while read is waiting in storage
      progressService.clearCache();

      // Read from storage finally completes
      cRead.complete();
      await fRead;

      // In-memory pending changes were NOT restored
      expect(progressService.getPendingChanges('user_reg1'), isEmpty);
    });

    test('2. Progress-storage read completes after logout: no stale cache is restored', () async {
      final key = 'devops_progress_user_reg2_git';
      await storage.write(key, json.encode(['git-01', 'git-02']));

      final cRead = Completer<void>();
      storage.readCompleterByKey[key] = cRead;

      // Start reading completed modules in session 0
      final fRead = progressService.getCompletedModules('user_reg2');

      // Logout occurs while read is paused in storage
      progressService.clearCache();

      // Read from storage completes
      cRead.complete();
      final result = await fRead;

      // Returns empty set and does NOT populate cache
      expect(result, isEmpty);
      expect(progressService.isModuleCompleted('user_reg2', 'git-01'), isFalse);
      expect(progressService.isModuleCompleted('user_reg2', 'git-02'), isFalse);
    });

    test('3. Fetch becomes stale while loading pending changes: no cache/status mutation', () async {
      final key = 'devops_pending_user_reg3_git';
      await storage.write(key, json.encode({'git-01': true}));
      await storage.saveToken('token_user_reg3');
      mockApi.serverCompletedModulesByToken['token_user_reg3'] = {'git-01'};

      final cRead = Completer<void>();
      storage.readCompleterByKey[key] = cRead;

      // Start fetchUserProgress
      final fFetch = progressService.fetchUserProgress('user_reg3');
      final checkFetch = expectLater(fFetch, throwsA(isA<StateError>()));

      // Logout occurs while fetch is awaiting disk read of pending changes
      progressService.clearCache();
      await storage.deleteToken();

      // Storage read completes
      cRead.complete();
      await checkFetch;

      // Verify no cache, pending, or status mutation
      expect(progressService.isModuleCompleted('user_reg3', 'git-01'), isFalse);
      expect(progressService.getPendingChanges('user_reg3'), isEmpty);
      expect(progressService.getSyncStatus('user_reg3'), equals(SyncStatus.offline));
      expect(mockApi.getProgressCallCount, equals(0));
    });

    test('4. A pending-storage write started before logout cannot overwrite newer-session storage', () async {
      final key = 'devops_pending_user_reg4_git';
      final cWrite0 = Completer<void>();
      storage.writeCompleterByKey[key] = cWrite0;

      // Session 0 prepares pending change and starts saving
      final session0Gen = progressService.currentSessionGeneration;
      progressService.recordPendingChangeForTesting('user_reg4', 'git', 'git-01', true);
      final fSave0 = progressService.savePendingToDisk('user_reg4', 'git', sessionGeneration: session0Gen);

      // Logout occurs (session generation increments)
      progressService.clearCache();
      final session1Gen = progressService.currentSessionGeneration;

      // In Session 1, newer pending data arrives (git-02: true) and saves
      progressService.recordPendingChangeForTesting('user_reg4', 'git', 'git-02', true);
      final fSave1 = progressService.savePendingToDisk('user_reg4', 'git', sessionGeneration: session1Gen);

      // Release Session 0 paused write
      cWrite0.complete();

      await Future.wait([fSave0, fSave1]);

      // Verify actual stored value: must contain git-02 and NOT git-01
      final raw = await storage.read(key);
      expect(raw, isNotNull);
      final Map<String, dynamic> decoded = json.decode(raw!);
      expect(decoded.containsKey('git-02'), isTrue);
      expect(decoded.containsKey('git-01'), isFalse);
    });

    test('5. A progress-storage write started before logout cannot overwrite newer-session storage', () async {
      final key = 'devops_progress_user_reg5_git';
      final cWrite0 = Completer<void>();
      storage.writeCompleterByKey[key] = cWrite0;

      // Session 0 starts saving progress {'git-01'}
      final session0Gen = progressService.currentSessionGeneration;
      final fSave0 = progressService.saveToDisk('user_reg5', 'git', {'git-01'}, sessionGeneration: session0Gen);

      // Logout occurs
      progressService.clearCache();
      final session1Gen = progressService.currentSessionGeneration;

      // Session 1 saves newer progress {'git-05'}
      final fSave1 = progressService.saveToDisk('user_reg5', 'git', {'git-05'}, sessionGeneration: session1Gen);

      // Release Session 0 write
      cWrite0.complete();

      await Future.wait([fSave0, fSave1]);

      // Verify actual stored value: must contain git-05 and NOT git-01
      final raw = await storage.read(key);
      expect(raw, isNotNull);
      final List<dynamic> decoded = json.decode(raw!);
      expect(decoded, contains('git-05'));
      expect(decoded, isNot(contains('git-01')));
    });

    test('6. A stale operation cannot delete a newer pending-storage value', () async {
      final key = 'devops_pending_user_reg6_git';
      final cDelete0 = Completer<void>();
      storage.deleteCompleterByKey[key] = cDelete0;

      // In session 0, pending is empty, so savePendingToDisk calls delete
      final session0Gen = progressService.currentSessionGeneration;
      final fDelete0 = progressService.savePendingToDisk('user_reg6', 'git', sessionGeneration: session0Gen);

      // Logout occurs
      progressService.clearCache();
      final session1Gen = progressService.currentSessionGeneration;

      // In Session 1, a new pending change is recorded (git-03: true) and saved
      progressService.recordPendingChangeForTesting('user_reg6', 'git', 'git-03', true);
      final fSave1 = progressService.savePendingToDisk('user_reg6', 'git', sessionGeneration: session1Gen);

      // Release Session 0 delete
      cDelete0.complete();

      await Future.wait([fDelete0, fSave1]);

      // Storage must NOT be deleted: it must contain git-03
      final raw = await storage.read(key);
      expect(raw, isNotNull);
      final Map<String, dynamic> decoded = json.decode(raw!);
      expect(decoded['git-03'], isTrue);
    });

    test('7. A stale operation cannot delete or overwrite another account\'s data', () async {
      final keyA = 'devops_progress_user_A_git';
      final keyB = 'devops_progress_user_B_git';

      final cWriteA = Completer<void>();
      storage.writeCompleterByKey[keyA] = cWriteA;

      // User A initiates write in session 0
      final session0Gen = progressService.currentSessionGeneration;
      final fSaveA = progressService.saveToDisk('user_A', 'git', {'git-01'}, sessionGeneration: session0Gen);

      // Logout occurs
      progressService.clearCache();
      final session1Gen = progressService.currentSessionGeneration;

      // User B logs in (session 1) and writes progress {'git-07'}
      final fSaveB = progressService.saveToDisk('user_B', 'git', {'git-07'}, sessionGeneration: session1Gen);
      await fSaveB;

      // Release User A's paused write
      cWriteA.complete();
      await fSaveA;

      // User B's storage must be intact and match git-07, not git-01
      final rawB = await storage.read(keyB);
      expect(rawB, isNotNull);
      final List<dynamic> decodedB = json.decode(rawB!);
      expect(decodedB, contains('git-07'));
      expect(decodedB, isNot(contains('git-01')));
    });
  });

  group('Phase 6 Audit: Listener & Session Race Condition Tests', () {
    test('1. Guest mutation: logout during _savePendingToDisk does not notify listeners or restore state', () async {
      int notifyCount = 0;
      void listener() {
        notifyCount++;
      }
      progressService.addListener(listener);

      final pendingKey = 'devops_pending_guest_git';
      final cWrite = Completer<void>();
      storage.writeCompleterByKey[pendingKey] = cWrite;

      // Start guest toggle
      final fToggle = progressService.toggleModuleCompletion('guest', 'git-01');
      final checkError = expectLater(fToggle, throwsA(isA<StateError>()));

      // Logout occurs while guest _savePendingToDisk is in flight
      progressService.clearCache();
      final countAfterClear = notifyCount;

      // Complete storage write
      cWrite.complete();
      storage.writeCompleterByKey.remove(pendingKey);

      await checkError;

      // Stale operation did NOT notify listeners after clearCache
      expect(notifyCount, equals(countAfterClear));
      // In-memory cache and status were wiped and not restored
      expect(progressService.isModuleCompleted('guest', 'git-01'), isFalse);
      progressService.removeListener(listener);
    });

    test('2. No-token mutation: logout during _savePendingToDisk does not notify listeners or modify state', () async {
      int notifyCount = 0;
      void listener() {
        notifyCount++;
      }
      progressService.addListener(listener);

      await storage.deleteToken(); // unauthenticated user
      final pendingKey = 'devops_pending_user_notoken_git';
      final cWrite = Completer<void>();
      storage.writeCompleterByKey[pendingKey] = cWrite;

      final fToggle = progressService.toggleModuleCompletion('user_notoken', 'git-01');
      final checkError = expectLater(fToggle, throwsA(isA<StateError>()));

      // Logout occurs while write is in flight
      progressService.clearCache();
      final countAfterClear = notifyCount;

      cWrite.complete();
      storage.writeCompleterByKey.remove(pendingKey);

      await checkError;

      expect(notifyCount, equals(countAfterClear));
      expect(progressService.isModuleCompleted('user_notoken', 'git-01'), isFalse);
      progressService.removeListener(listener);
    });

    test('3. Reconcile server response: logout during _saveToDisk does not notify listeners', () async {
      int notifyCount = 0;
      void listener() {
        notifyCount++;
      }
      progressService.addListener(listener);

      await storage.saveToken('token_recon');
      mockApi.serverCompletedModulesByToken['token_recon'] = <String>{};
      mockApi.mockToggleProgressResponse = {
        'success': true,
        'pathwayId': 'git',
        'moduleId': 'git-01',
        'isCompleted': true,
        'completedModules': ['git-01'],
      };

      final progressKey = 'devops_progress_user_recon_git';
      final cWrite = Completer<void>();
      storage.writeCompleterByKey[progressKey] = cWrite;

      final fToggle = progressService.toggleModuleCompletion('user_recon', 'git-01');
      final checkError = expectLater(fToggle, throwsA(isA<StateError>()));

      // Logout occurs while _saveToDisk in _reconcileServerResponse is in flight
      progressService.clearCache();
      final countAfterClear = notifyCount;

      cWrite.complete();
      storage.writeCompleterByKey.remove(progressKey);

      await checkError;

      expect(notifyCount, equals(countAfterClear));
      expect(progressService.isModuleCompleted('user_recon', 'git-01'), isFalse);
      progressService.removeListener(listener);
    });

    test('4. Reconcile server response: logout during _savePendingToDisk does not notify listeners', () async {
      int notifyCount = 0;
      void listener() {
        notifyCount++;
      }
      progressService.addListener(listener);

      await storage.saveToken('token_recon2');
      mockApi.serverCompletedModulesByToken['token_recon2'] = <String>{};
      mockApi.mockToggleProgressResponse = {
        'success': true,
        'pathwayId': 'git',
        'moduleId': 'git-01',
        'isCompleted': true,
        'completedModules': ['git-01'],
      };

      final pendingKey = 'devops_pending_user_recon2_git';
      final cWrite = Completer<void>();
      storage.writeCompleterByKey[pendingKey] = cWrite;

      final fToggle = progressService.toggleModuleCompletion('user_recon2', 'git-01');
      final checkError = expectLater(fToggle, throwsA(isA<StateError>()));

      // Logout occurs while _savePendingToDisk in _reconcileServerResponse is in flight
      progressService.clearCache();
      final countAfterClear = notifyCount;

      cWrite.complete();
      storage.writeCompleterByKey.remove(pendingKey);

      await checkError;

      expect(notifyCount, equals(countAfterClear));
      expect(progressService.isModuleCompleted('user_recon2', 'git-01'), isFalse);
      progressService.removeListener(listener);
    });

    test('5. Fetch: logout during _saveToDisk does not notify listeners or return stale result', () async {
      int notifyCount = 0;
      void listener() {
        notifyCount++;
      }
      progressService.addListener(listener);

      await storage.saveToken('token_fetch_recon');
      mockApi.serverCompletedModulesByToken['token_fetch_recon'] = {'git-01', 'git-02'};

      final progressKey = 'devops_progress_user_fetch_recon_git';
      final cWrite = Completer<void>();
      storage.writeCompleterByKey[progressKey] = cWrite;

      final fFetch = progressService.fetchUserProgress('user_fetch_recon');
      final checkError = expectLater(fFetch, throwsA(isA<StateError>()));

      // Logout occurs while _saveToDisk in _fetchAndReconcileInternal is in flight
      progressService.clearCache();
      final countAfterClear = notifyCount;

      cWrite.complete();
      storage.writeCompleterByKey.remove(progressKey);

      await checkError;

      expect(notifyCount, equals(countAfterClear));
      expect(progressService.isModuleCompleted('user_fetch_recon', 'git-01'), isFalse);
      progressService.removeListener(listener);
    });
  });

  group('Phase 6: ActivityService Session-Safety & Retry Tests', () {
    test('1. Logout/account switch while hasToken() is pending returns false without making request', () async {
      storage.hasTokenDelayCompleter = Completer<void>();

      final fLog = activityService.logLessonViewed(userId: 'user_hastoken', stopSlug: 'module-1');

      // Logout occurs while hasToken is pending
      activityService.clearCache();
      await storage.deleteToken();

      storage.hasTokenDelayCompleter!.complete();
      storage.hasTokenDelayCompleter = null;

      final result = await fLog;
      expect(result, isFalse);
      expect(mockApi.logActivityCallCount, equals(0));
      expect(activityService.hasLoggedEvent(userId: 'user_hastoken', type: 'lesson_viewed', stopSlug: 'module-1'), isFalse);
    });

    test('2. Logout/account switch while logActivity() is pending returns false and discards result', () async {
      mockApi.logActivityDelayCompleter = Completer<void>();

      final fLog = activityService.logLessonViewed(userId: 'user_pending', stopSlug: 'module-1');

      // Allow request to reach logActivity
      await Future.delayed(const Duration(milliseconds: 5));

      // Request was sent
      expect(mockApi.logActivityCallCount, equals(1));

      // Logout occurs while logActivity is pending
      activityService.clearCache();
      await storage.deleteToken();

      mockApi.logActivityDelayCompleter!.complete();
      mockApi.logActivityDelayCompleter = null;

      final result = await fLog;
      expect(result, isFalse);
      expect(activityService.hasLoggedEvent(userId: 'user_pending', type: 'lesson_viewed', stopSlug: 'module-1'), isFalse);
    });

    test('3. Failed lesson event removes key to allow later retry', () async {
      mockApi.throwOnLogActivity = const ApiException(message: 'Connection failed', statusCode: 503);

      // First attempt fails due to network error
      final res1 = await activityService.logLessonViewed(userId: 'user_retry_lesson', stopSlug: 'module-1');
      expect(res1, isFalse);
      expect(mockApi.logActivityCallCount, equals(1));
      expect(activityService.hasLoggedEvent(userId: 'user_retry_lesson', type: 'lesson_viewed', stopSlug: 'module-1'), isFalse);

      // Network recovers
      mockApi.throwOnLogActivity = null;

      // Retry attempt succeeds
      final res2 = await activityService.logLessonViewed(userId: 'user_retry_lesson', stopSlug: 'module-1');
      expect(res2, isTrue);
      expect(mockApi.logActivityCallCount, equals(2));
      expect(activityService.hasLoggedEvent(userId: 'user_retry_lesson', type: 'lesson_viewed', stopSlug: 'module-1'), isTrue);
    });

    test('4. Failed animation event removes key to allow later retry', () async {
      mockApi.mockLogActivityResponse = {'success': false, 'logged': false};

      // First attempt receives unsuccessful response from server
      final res1 = await activityService.logAnimationFinished(userId: 'user_retry_anim', stopSlug: 'module-2');
      expect(res1, isFalse);
      expect(mockApi.logActivityCallCount, equals(1));
      expect(activityService.hasLoggedEvent(userId: 'user_retry_anim', type: 'animation_finished', stopSlug: 'module-2'), isFalse);

      // Server succeeds
      mockApi.mockLogActivityResponse = {'success': true, 'logged': true};

      // Retry attempt succeeds
      final res2 = await activityService.logAnimationFinished(userId: 'user_retry_anim', stopSlug: 'module-2');
      expect(res2, isTrue);
      expect(mockApi.logActivityCallCount, equals(2));
      expect(activityService.hasLoggedEvent(userId: 'user_retry_anim', type: 'animation_finished', stopSlug: 'module-2'), isTrue);
    });

    test('5. Successful event remains deduplicated and avoids redundant requests', () async {
      mockApi.mockLogActivityResponse = {'success': true, 'logged': true};

      final res1 = await activityService.logLessonViewed(userId: 'user_dedup_test', stopSlug: 'module-3');
      expect(res1, isTrue);
      expect(mockApi.logActivityCallCount, equals(1));
      expect(activityService.hasLoggedEvent(userId: 'user_dedup_test', type: 'lesson_viewed', stopSlug: 'module-3'), isTrue);

      // Same event called again on the same day
      final res2 = await activityService.logLessonViewed(userId: 'user_dedup_test', stopSlug: 'module-3');
      expect(res2, isFalse);
      expect(mockApi.logActivityCallCount, equals(1)); // No second request made!
    });

    test('6. Old-session request completing after account switch does not pollute new session', () async {
      mockApi.logActivityDelayCompleter = Completer<void>();

      // User A initiates event in session 0
      final fUserA = activityService.logLessonViewed(userId: 'user_A', stopSlug: 'module-4');

      // Allow User A's call to reach logActivity
      await Future.delayed(const Duration(milliseconds: 5));

      // User A logs out and User B logs in (session 1)
      activityService.clearCache();
      await storage.saveToken('token_user_B');

      // User B logs event for module-4
      final fUserB = activityService.logLessonViewed(userId: 'user_B', stopSlug: 'module-4');

      // User A's network request returns
      mockApi.logActivityDelayCompleter!.complete();
      mockApi.logActivityDelayCompleter = null;

      final resA = await fUserA;
      final resB = await fUserB;

      expect(resA, isFalse); // Old session operation rejected
      expect(resB, isTrue); // New session operation succeeds
      expect(activityService.hasLoggedEvent(userId: 'user_B', type: 'lesson_viewed', stopSlug: 'module-4'), isTrue);
      expect(activityService.hasLoggedEvent(userId: 'user_A', type: 'lesson_viewed', stopSlug: 'module-4'), isFalse);
    });
  });

  group('Phase 6: Session-Aware Mutation Queue Lifecycle Tests', () {
    test('User B mutation completes without waiting for User A in-flight await, active & queued callers cancel immediately', () async {
      mockApi.serverCompletedModulesByToken.clear();
      mockApi.serverCompletedModulesByToken['token_user_A'] = <String>{};
      mockApi.serverCompletedModulesByToken['token_user_B'] = <String>{};
      mockApi.requestHistory.clear();
      await storage.saveToken('token_user_A');

      final cA1 = Completer<void>();
      final startedA1 = Completer<void>();
      mockApi.toggleDelayCompleter = cA1;
      mockApi.toggleStartedCompleter = startedA1;

      // 1. User A starts Op A1 (will block on cA1)
      final fA1 = progressService.toggleModuleCompletion('user_A', 'git-01');

      // Deterministically await signal that mockApi.toggleProgress has started processing
      await startedA1.future;
      mockApi.toggleStartedCompleter = null;

      // 2. User A also queues Op A2 (remains queued in session A)
      final fA2 = progressService.toggleModuleCompletion('user_A', 'git-02');

      // Register cancellation expectations for both active (A1) and queued (A2) callers
      final checkA1 = expectLater(fA1, throwsA(isA<StateError>()));
      final checkA2 = expectLater(fA2, throwsA(isA<StateError>()));

      // 3. Clear session (User A logs out)
      progressService.clearCache();
      await storage.deleteToken();

      // CRITICAL ASSERTION: BOTH active caller A1 and queued caller A2 MUST cancel immediately!
      // cA1 is NOT completed yet!
      expect(cA1.isCompleted, isFalse);
      await checkA1;
      await checkA2;

      // 4. Switch to User B (session 1)
      await storage.saveToken('token_user_B');
      mockApi.toggleDelayCompleter = null; // Do NOT delay User B!

      // 5. User B queues two mutations: B1 then B2
      final fB1 = progressService.toggleModuleCompletion('user_B', 'git-03');
      final fB2 = progressService.toggleModuleCompletion('user_B', 'git-04');

      // CRITICAL ASSERTION: User B's mutations MUST complete cleanly WITHOUT waiting for cA1!
      final resB1 = await fB1;
      final resB2 = await fB2;
      expect(resB1, isTrue);
      expect(resB2, isTrue);

      // Verify FIFO ordering within User B's session
      final userBRequests = mockApi.requestHistory
          .where((r) => r.startsWith('POST:git-03') || r.startsWith('POST:git-04'))
          .toList();
      expect(userBRequests, equals(['POST:git-03:git', 'POST:git-04:git']));

      // Verify User B's state
      expect(progressService.isModuleCompleted('user_B', 'git-03'), isTrue);
      expect(progressService.isModuleCompleted('user_B', 'git-04'), isTrue);

      // 6. Complete User A's old delayed request afterward
      cA1.complete();

      // Ensure no double completion or uncaught asynchronous errors occur
      await Future.delayed(const Duration(milliseconds: 10));

      // 7. Verify User A's old request CANNOT affect User B
      expect(progressService.isModuleCompleted('user_B', 'git-01'), isFalse);
      expect(progressService.isModuleCompleted('user_B', 'git-02'), isFalse);
      expect(progressService.isModuleCompleted('user_A', 'git-01'), isFalse);
      expect(progressService.isModuleCompleted('user_A', 'git-02'), isFalse);
      expect(progressService.activeMutationCount, equals(0));
      expect(progressService.queuedMutationCount, equals(0));
    });

    test('User A active caller is cancelled immediately, and subsequent network failure in old session does not throw unhandled error or affect User B', () async {
      mockApi.serverCompletedModulesByToken.clear();
      mockApi.serverCompletedModulesByToken['token_user_A'] = <String>{};
      mockApi.serverCompletedModulesByToken['token_user_B'] = <String>{};
      mockApi.requestHistory.clear();
      await storage.saveToken('token_user_A');

      final cA1 = Completer<void>();
      final startedA1 = Completer<void>();
      mockApi.toggleDelayCompleter = cA1;
      mockApi.toggleStartedCompleter = startedA1;

      // 1. User A starts Op A1 (will block on cA1)
      final fA1 = progressService.toggleModuleCompletion('user_A', 'git-01');

      // Deterministically await signal that mockApi.toggleProgress has started processing
      await startedA1.future;
      mockApi.toggleStartedCompleter = null;

      final checkA1 = expectLater(fA1, throwsA(isA<StateError>()));

      // 2. Clear session (User A logs out)
      progressService.clearCache();
      await storage.deleteToken();

      // Active caller A1 receives cancellation immediately before cA1 completes!
      expect(cA1.isCompleted, isFalse);
      await checkA1;

      // 3. User B logs in and performs mutations
      await storage.saveToken('token_user_B');
      mockApi.toggleDelayCompleter = null;
      final fB = await progressService.toggleModuleCompletion('user_B', 'git-05');
      expect(fB, isTrue);

      // 4. Release cA1 with an exception
      cA1.completeError(const ApiException(message: 'Socket timeout', statusCode: 504));

      // Wait a tick to ensure no unhandled asynchronous errors or state corruptions occur
      await Future.delayed(const Duration(milliseconds: 10));

      expect(progressService.isModuleCompleted('user_B', 'git-05'), isTrue);
      expect(progressService.isModuleCompleted('user_B', 'git-01'), isFalse);
      expect(progressService.isModuleCompleted('user_A', 'git-01'), isFalse);
      expect(progressService.activeMutationCount, equals(0));
      expect(progressService.queuedMutationCount, equals(0));
    });
  });
}
