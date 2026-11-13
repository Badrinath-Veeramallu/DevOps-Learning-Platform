import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:devops_learning_app/core/api/api_client.dart';
import 'package:devops_learning_app/core/theme/app_theme.dart';
import 'package:devops_learning_app/features/pathway/data/progress_service.dart';
import 'package:devops_learning_app/features/pathway/widgets/git_pathway_map.dart';
import 'package:devops_learning_app/features/pathway/widgets/linux_pathway_map.dart';
import 'package:devops_learning_app/features/pathway/widgets/pathway_header_card.dart';
import 'package:devops_learning_app/models/curriculum_model.dart';

import 'auth_provider_test.dart';

class MockSequentialApiClient extends ApiClient {
  MockSequentialApiClient({required super.storageService});

  final Set<String> serverModules = {};

  @override
  Future<Map<String, dynamic>> getProgress({String pathwayId = 'git'}) async {
    return {
      'success': true,
      'pathwayId': pathwayId,
      'completedModules': serverModules.toList(),
    };
  }

  @override
  Future<Map<String, dynamic>> toggleProgress({
    required String moduleId,
    String pathwayId = 'git',
  }) async {
    if (serverModules.contains(moduleId)) {
      serverModules.remove(moduleId);
    } else {
      serverModules.add(moduleId);
    }
    return {
      'success': true,
      'pathwayId': pathwayId,
      'moduleId': moduleId,
      'completedModules': serverModules.toList(),
    };
  }
}

List<CurriculumModule> createSampleGitModules() {
  return List.generate(7, (i) {
    final num = i + 1;
    return CurriculumModule(
      id: 'git-0$num',
      order: num,
      number: '0$num',
      title: 'Git Module $num Title',
      shortTitle: 'Git Module $num',
      summary: 'Summary for Git module $num',
      estimatedMinutes: 20,
      objectives: ['Obj 1', 'Obj 2'],
      sections: [],
    );
  });
}

List<CurriculumModule> createSampleLinuxModules() {
  return List.generate(6, (i) {
    final num = i + 1;
    return CurriculumModule(
      id: 'linux-0$num',
      order: num,
      number: '0$num',
      title: 'Linux Module $num Title',
      shortTitle: 'Linux Module $num',
      summary: 'Summary for Linux module $num',
      estimatedMinutes: 20,
      objectives: ['Obj 1', 'Obj 2'],
      sections: [],
    );
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Part 1: Pathway Progress Calculation Tests (Git & Linux)', () {
    late List<CurriculumModule> gitModules;
    late List<CurriculumModule> linuxModules;

    setUp(() {
      gitModules = createSampleGitModules();
      linuxModules = createSampleLinuxModules();
    });

    testWidgets('0 of 7 completed = 0%', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: PathwayHeaderCard(
              completedCount: 0,
              totalCount: 7,
              modules: gitModules,
              completedIds: const {},
              onBack: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('0 of 7 Completed (0%)'), findsOneWidget);
      expect(find.text('Next: Stop 1 · Git Module 1'), findsOneWidget);
    });

    testWidgets('1 of 7 completed = 14%', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: PathwayHeaderCard(
              completedCount: 1,
              totalCount: 7,
              modules: gitModules,
              completedIds: const {'git-01'},
              onBack: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('1 of 7 Completed (14%)'), findsOneWidget);
      expect(find.text('Next: Stop 2 · Git Module 2'), findsOneWidget);
    });

    testWidgets('3 of 7 completed = 43% (User Request Scenario)', (tester) async {
      // User scenario: Stop 1, 2, 3 completed, Stop 4 current focus, 5-7 not completed.
      // Must display 3 of 7 Completed (43%), NOT 4 of 7 Completed (57%)!
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: PathwayHeaderCard(
              completedCount: 3,
              totalCount: 7,
              modules: gitModules,
              completedIds: const {'git-01', 'git-02', 'git-03'},
              onBack: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('3 of 7 Completed (43%)'), findsOneWidget);
      expect(find.textContaining('4 of 7 Completed'), findsNothing);
      expect(find.text('Next: Stop 4 · Git Module 4'), findsOneWidget);
    });

    testWidgets('4 of 7 completed = 57%', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: PathwayHeaderCard(
              completedCount: 4,
              totalCount: 7,
              modules: gitModules,
              completedIds: const {'git-01', 'git-02', 'git-03', 'git-04'},
              onBack: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('4 of 7 Completed (57%)'), findsOneWidget);
      expect(find.text('Next: Stop 5 · Git Module 5'), findsOneWidget);
    });

    testWidgets('7 of 7 completed = 100%', (tester) async {
      final allCompleted = gitModules.map((m) => m.id).toSet();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: PathwayHeaderCard(
              completedCount: 7,
              totalCount: 7,
              modules: gitModules,
              completedIds: allCompleted,
              onBack: () {},
              allDoneText: "🎉 You've completed all 7 Git stops!",
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('7 of 7 Completed (100%)'), findsOneWidget);
      expect(find.text("🎉 You've completed all 7 Git stops!"), findsOneWidget);
    });

    testWidgets('Linux pathway progress: 3 of 6 = 50%', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: PathwayHeaderCard(
              completedCount: 3,
              totalCount: 6,
              modules: linuxModules,
              completedIds: const {'linux-01', 'linux-02', 'linux-03'},
              onBack: () {},
              title: 'Linux Essentials Pathway',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('3 of 6 Completed (50%)'), findsOneWidget);
      expect(find.text('Next: Stop 4 · Linux Module 4'), findsOneWidget);
    });
  });

  group('Part 2: Sequential Unlocking Tests', () {
    late List<CurriculumModule> gitModules;

    setUp(() {
      gitModules = createSampleGitModules();
    });

    test('isModuleUnlocked helper correctly validates unlocking sequence', () {
      // Initially: only git-01 is unlocked
      expect(
        ProgressService.isModuleUnlocked(
          pathway: 'git',
          moduleId: 'git-01',
          completedModules: {},
        ),
        isTrue,
      );
      expect(
        ProgressService.isModuleUnlocked(
          pathway: 'git',
          moduleId: 'git-02',
          completedModules: {},
        ),
        isFalse,
      );
      expect(
        ProgressService.isModuleUnlocked(
          pathway: 'git',
          moduleId: 'git-03',
          completedModules: {},
        ),
        isFalse,
      );

      // Completing git-01 unlocks git-02, but git-03 remains locked
      expect(
        ProgressService.isModuleUnlocked(
          pathway: 'git',
          moduleId: 'git-02',
          completedModules: {'git-01'},
        ),
        isTrue,
      );
      expect(
        ProgressService.isModuleUnlocked(
          pathway: 'git',
          moduleId: 'git-03',
          completedModules: {'git-01'},
        ),
        isFalse,
      );

      // Completing git-02 unlocks git-03
      expect(
        ProgressService.isModuleUnlocked(
          pathway: 'git',
          moduleId: 'git-03',
          completedModules: {'git-01', 'git-02'},
        ),
        isTrue,
      );
    });

    testWidgets('GitPathwayMap renders Module 1 as Current Focus and Modules 2-7 as Locked initially', (tester) async {
      String? tappedId;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: GitPathwayMap(
                modules: gitModules,
                completedModuleIds: const {},
                onSelectModule: (id) => tappedId = id,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Stop 1: Current Focus
      expect(find.text('Current Focus'), findsOneWidget);
      expect(find.text('Start Learning'), findsOneWidget);

      // Stops 2-7: Locked (6 stops * (1 status pill + 1 action button) = 12 'Locked' text widgets)
      expect(find.text('Locked'), findsNWidgets(12));
      expect(
        find.text('Complete the previous module to unlock this module.'),
        findsNWidgets(6),
      );

      // Tapping locked module 2 shows snackbar and does NOT invoke onSelectModule
      await tester.ensureVisible(find.text('Git Module 2'));
      await tester.tap(find.text('Git Module 2'));
      await tester.pumpAndSettle();

      expect(tappedId, isNull);
      expect(
        find.text('Complete the previous module to unlock this module.'),
        findsWidgets,
      );

      // Tapping Stop 1 calls onSelectModule
      await tester.ensureVisible(find.text('Start Learning'));
      await tester.tap(find.text('Start Learning'));
      expect(tappedId, equals('git-01'));
    });

    testWidgets('After completing Module 1: Module 1 is Review, Module 2 is Current, Modules 3-7 are Locked', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: GitPathwayMap(
                modules: gitModules,
                completedModuleIds: const {'git-01'},
                onSelectModule: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Stop 1: Completed
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('Review Module'), findsOneWidget);

      // Stop 2: Current Focus
      expect(find.text('Current Focus'), findsOneWidget);
      expect(find.text('Start Learning'), findsOneWidget);

      // Stops 3-7: Locked (5 stops * 2 = 10)
      expect(find.text('Locked'), findsNWidgets(10));
    });

    testWidgets('LinuxPathwayMap applies identical sequential unlocking for 6 stops', (tester) async {
      final linuxModules = createSampleLinuxModules();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: LinuxPathwayMap(
                modules: linuxModules,
                completedModuleIds: const {'linux-01', 'linux-02'},
                onSelectModule: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Stops 1 and 2: Completed
      expect(find.text('Completed'), findsNWidgets(2));
      expect(find.text('Review Module'), findsNWidgets(2));

      // Stop 3: Current Focus
      expect(find.text('Current Focus'), findsOneWidget);
      expect(find.text('Start Learning'), findsOneWidget);

      // Stops 4-6: Locked (3 stops * 2 = 6)
      expect(find.text('Locked'), findsNWidgets(6));
    });
  });

  group('Part 3: Cross-Platform Offline Reconciliation Sequential Validation', () {
    late MockSecureStorageService storage;
    late MockSequentialApiClient mockApi;
    late ProgressService progressService;

    setUp(() async {
      storage = MockSecureStorageService();
      mockApi = MockSequentialApiClient(storageService: storage);
      progressService = ProgressService();
      progressService.init(apiClient: mockApi, storageService: storage);
      progressService.clearCache();
      await storage.saveToken('token_test');
    });

    test('Reconciliation discards out-of-order pending completion if preceding module is not completed on server', () async {
      // Server currently has no modules completed
      mockApi.serverModules.clear();

      // User has an out-of-order pending completion for git-03 (e.g. injected or corrupted offline state)
      progressService.recordPendingChangeForTesting('user_test', 'git', 'git-03', true);

      // fetchUserProgress runs: fetches server state ([]), discovers git-03 is locked, and discards it!
      final reconciled = await progressService.fetchUserProgress('user_test', pathway: 'git');

      // git-03 was NOT marked completed and was pruned from pending changes
      expect(reconciled.contains('git-03'), isFalse);
      expect(progressService.getPendingChanges('user_test', pathway: 'git'), isEmpty);
    });

    test('Reconciliation accepts sequential pending completions in order', () async {
      // Server currently has git-01 completed
      mockApi.serverModules.add('git-01');

      // User has pending completion for git-02 (which is unlocked because git-01 is completed)
      progressService.recordPendingChangeForTesting('user_test', 'git', 'git-02', true);

      final reconciled = await progressService.fetchUserProgress('user_test', pathway: 'git');

      // git-02 was successfully uploaded and confirmed!
      expect(reconciled, containsAll(['git-01', 'git-02']));
      expect(progressService.getPendingChanges('user_test', pathway: 'git'), isEmpty);
    });
  });
}
