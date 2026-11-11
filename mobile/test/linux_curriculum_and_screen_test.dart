import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:devops_learning_app/core/router/app_router.dart';
import 'package:devops_learning_app/core/router/route_names.dart';
import 'package:devops_learning_app/core/theme/app_theme.dart';
import 'package:devops_learning_app/features/dashboard/models/learning_path_track.dart';
import 'package:devops_learning_app/features/dashboard/widgets/learning_track_card.dart';
import 'package:devops_learning_app/features/module/screens/linux_module_screen.dart';
import 'package:devops_learning_app/features/pathway/data/activity_service.dart';
import 'package:devops_learning_app/features/pathway/data/docker_curriculum_repository.dart';
import 'package:devops_learning_app/features/pathway/data/git_curriculum_repository.dart';
import 'package:devops_learning_app/features/pathway/data/linux_curriculum_repository.dart';
import 'package:devops_learning_app/features/pathway/data/progress_service.dart';
import 'package:devops_learning_app/features/pathway/screens/linux_pathway_screen.dart';
import 'package:devops_learning_app/features/pathway/widgets/linux_pathway_map.dart';
import 'package:devops_learning_app/models/curriculum_model.dart';
import 'package:devops_learning_app/models/user_model.dart';
import 'package:devops_learning_app/providers/auth_provider.dart';

import 'auth_provider_test.dart';

class MockLinuxApiClient extends FakeApiClient {
  MockLinuxApiClient({required super.storageService});

  final Set<String> completedModules = {};

  @override
  Future<Map<String, dynamic>> getProgress({String pathwayId = 'git'}) async {
    return {
      'success': true,
      'completedModules': completedModules.toList(),
    };
  }

  @override
  Future<Map<String, dynamic>> toggleProgress({
    required String moduleId,
    String pathwayId = 'git',
  }) async {
    if (completedModules.contains(moduleId)) {
      completedModules.remove(moduleId);
    } else {
      completedModules.add(moduleId);
    }
    return {
      'success': true,
      'completedModules': completedModules.toList(),
    };
  }

  @override
  Future<Map<String, dynamic>> logActivity({
    required String type,
    required String stopSlug,
    String pathwayId = 'git',
  }) async {
    return {'success': true};
  }

  @override
  Future<Map<String, dynamic>> getActivity({String? tz}) async {
    return {
      'success': true,
      'activities': [],
      'stats': {
        'totalLessons': 0,
        'currentStreak': 0,
        'longestStreak': 0,
      },
    };
  }
}

Widget _wrapScreen({
  required Widget child,
  required AuthProvider authProvider,
  Size screenSize = const Size(390, 844),
}) {
  return MediaQuery(
    data: MediaQueryData(size: screenSize),
    child: ChangeNotifierProvider<AuthProvider>.value(
      value: authProvider,
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: child,
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<CurriculumModule> linuxModules;
  late MockSecureStorageService storageService;
  late MockLinuxApiClient mockApi;
  late AuthProvider authProvider;

  setUpAll(() {
    final raw =
        File('assets/data/linux_curriculum.json').readAsStringSync();
    final List<dynamic> decoded = json.decode(raw) as List<dynamic>;
    linuxModules = decoded
        .map((m) => CurriculumModule.fromJson(m as Map<String, dynamic>))
        .toList();
  });

  setUp(() async {
    LinuxCurriculumRepository.setCachedModules(linuxModules);

    storageService = MockSecureStorageService();
    mockApi = MockLinuxApiClient(storageService: storageService);
    mockApi.mockUser = const UserModel(
      id: 'test-user-123',
      name: 'Linux Learner',
      email: 'linux@example.com',
    );
    authProvider = AuthProvider(
      apiClient: mockApi,
      storageService: storageService,
    );
    await authProvider.login(
      email: 'linux@example.com',
      password: 'password123',
    );

    ProgressService().init(
      apiClient: mockApi,
      storageService: storageService,
    );
    ProgressService().clearCache();

    ActivityService().init(
      apiClient: mockApi,
      storageService: storageService,
    );
    ActivityService().clearCache();
  });

  tearDown(() {
    ProgressService().clearCache();
    ActivityService().clearCache();
  });

  group('Linux Curriculum Integration Tests', () {
    test('1. Loads all 6 Linux modules from JSON asset with full fidelity', () {
      expect(linuxModules.length, 6);

      final expectedIds = [
        'linux-01',
        'linux-02',
        'linux-03',
        'linux-04',
        'linux-05',
        'linux-06',
      ];

      for (int i = 0; i < linuxModules.length; i++) {
        final m = linuxModules[i];
        expect(m.id, expectedIds[i]);
        expect(m.order, i + 1);
        expect(m.title, isNotEmpty);
        expect(m.shortTitle, isNotEmpty);
        expect(m.summary, isNotEmpty);
        expect(m.estimatedMinutes, greaterThan(0));
        expect(m.objectives, isNotEmpty);
        expect(m.sections, isNotEmpty);
      }
    });

    test('2. Finds module by id and order number', () {
      final m1 = LinuxCurriculumRepository.findModule(linuxModules, 'linux-01');
      expect(m1, isNotNull);
      expect(m1!.order, 1);
      expect(m1.shortTitle, 'Linux Fundamentals & File System Navigation');

      final m6 = LinuxCurriculumRepository.findModule(linuxModules, '06');
      expect(m6, isNotNull);
      expect(m6!.id, 'linux-06');
      expect(m6.order, 6);
      expect(m6.shortTitle, 'Shell Scripting & Automation');
    });

    test('3. Linux, Docker, and Git curriculum maintain isolated caches', () {
      GitCurriculumRepository.clearCache();
      DockerCurriculumRepository.clearCache();
      LinuxCurriculumRepository.setCachedModules(linuxModules);

      expect(LinuxCurriculumRepository.cachedModules, isNotNull);
      expect(LinuxCurriculumRepository.cachedModules!.length, 6);
      expect(GitCurriculumRepository.cachedModules, isNull);
      expect(DockerCurriculumRepository.cachedModules, isNull);
    });

    test('4. CurriculumSection correctly parses table data in modules 2 and 5', () {
      final m2 = LinuxCurriculumRepository.findModule(linuxModules, 'linux-02')!;
      final sec1 = m2.sections.first;
      expect(sec1.table, isNotNull);
      expect(sec1.table!.headers, ['Permission', 'Meaning']);
      expect(sec1.table!.rows.length, 3);
      expect(sec1.table!.rows[0], ['`r`', 'Read']);

      final m5 = LinuxCurriculumRepository.findModule(linuxModules, 'linux-05')!;
      final sec2 = m5.sections[1];
      expect(sec2.table, isNotNull);
      expect(sec2.table!.headers, ['Command', 'Action']);
      expect(sec2.table!.rows.length, 4);
      expect(sec2.table!.rows[0], ['`:w`', 'Save']);
    });

    test('5. CurriculumModule correctly parses moduleCompletion on module 6', () {
      final m6 = LinuxCurriculumRepository.findModule(linuxModules, 'linux-06')!;
      expect(m6.moduleCompletion, isNotNull);
      expect(m6.moduleCompletion!.title, 'Module Completion');
      expect(m6.moduleCompletion!.paragraphs, isNotEmpty);
      expect(m6.moduleCompletion!.paragraphs.first, contains('Linux Essentials'));
    });
  });

  group('Linux Pathway & Screen UI Tests', () {
    testWidgets('1. LinuxPathwayScreen renders header, badges, and 6 stops',
        (tester) async {
      await tester.pumpWidget(
        _wrapScreen(
          authProvider: authProvider,
          child: LinuxPathwayScreen(
            initialModules: linuxModules,
            initialCompletedIds: const {'linux-01'},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Linux Essentials Pathway'), findsOneWidget);
      expect(find.text('Foundational Pathway'), findsOneWidget);
      expect(find.text('6 Interactive Stops'), findsOneWidget);
      expect(find.text('1 of 6 Completed (17%)'), findsOneWidget);
      expect(find.byType(LinuxPathwayMap), findsOneWidget);

      expect(find.text('START'), findsOneWidget);
      expect(find.text('FINISH'), findsOneWidget);

      expect(find.text('Linux Fundamentals & File System Navigation'),
          findsOneWidget);
      expect(find.text('Shell Scripting & Automation'), findsOneWidget);
    });

    testWidgets('2. LinuxModuleScreen renders metadata, objectives, and table',
        (tester) async {
      final m2 = LinuxCurriculumRepository.findModule(linuxModules, 'linux-02')!;

      await tester.pumpWidget(
        _wrapScreen(
          authProvider: authProvider,
          child: LinuxModuleScreen(
            moduleId: 'linux-02',
            initialModules: linuxModules,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(m2.title), findsOneWidget);
      expect(find.text('Stop 2 of 6'), findsOneWidget);
      expect(find.text('${m2.estimatedMinutes} min read'), findsOneWidget);
      expect(find.text('Objectives'), findsOneWidget);
      expect(find.text('Permission'), findsOneWidget);
      expect(find.text('Meaning'), findsOneWidget);
      expect(find.text('Read'), findsOneWidget);
      expect(find.text('Write'), findsOneWidget);
      expect(find.text('Execute'), findsOneWidget);
    });

    testWidgets('3. LinuxModuleScreen renders Module Completion card on Module 6',
        (tester) async {
      await tester.pumpWidget(
        _wrapScreen(
          authProvider: authProvider,
          child: LinuxModuleScreen(
            moduleId: 'linux-06',
            initialModules: linuxModules,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Module Completion'), findsOneWidget);
      expect(find.textContaining('After completing Linux Essentials'), findsOneWidget);
    });

    testWidgets('4. Linux module completion toggles state and isolates from Git/Docker',
        (tester) async {
      await tester.pumpWidget(
        _wrapScreen(
          authProvider: authProvider,
          child: LinuxModuleScreen(
            moduleId: 'linux-01',
            initialModules: linuxModules,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll until completion button is visible, then tap
      final markBtn = find.text('Mark Stop as Completed');
      await tester.scrollUntilVisible(
        markBtn,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(markBtn, findsOneWidget);

      await tester.tap(markBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Completed (Click to Undo)'), findsOneWidget);

      final isLinuxDone = ProgressService().isModuleCompleted(
        'test-user-123',
        'linux-01',
        pathway: 'linux',
      );
      expect(isLinuxDone, isTrue);

      final isGitDone = ProgressService().isModuleCompleted(
        'test-user-123',
        'linux-01',
        pathway: 'git',
      );
      expect(isGitDone, isFalse);

      final isDockerDone = ProgressService().isModuleCompleted(
        'test-user-123',
        'linux-01',
        pathway: 'docker',
      );
      expect(isDockerDone, isFalse);
    });

    testWidgets('5. AppRouter protects /pathways/linux against unauthenticated users',
        (tester) async {
      final unauthStorage = MockSecureStorageService();
      final unauthProvider = AuthProvider(
        apiClient: FakeApiClient(storageService: unauthStorage),
        storageService: unauthStorage,
      );
      await unauthProvider.checkAuthStatus();

      final router = AppRouter.createRouter(unauthProvider);

      await tester.pumpWidget(
        ChangeNotifierProvider<AuthProvider>.value(
          value: unauthProvider,
          child: MaterialApp.router(
            theme: AppTheme.darkTheme,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Attempt navigation to /pathways/linux
      router.go(RouteNames.linuxPathway);
      await tester.pumpAndSettle();

      expect(router.state.matchedLocation, RouteNames.login);

      // Attempt navigation to /pathways/linux/linux-01
      router.go('/pathways/linux/linux-01');
      await tester.pumpAndSettle();

      expect(router.state.matchedLocation, RouteNames.login);
    });

    testWidgets('6. Dashboard track card for Linux links to Linux pathway',
        (tester) async {
      final linuxTrack = LearningPathTrack.defaultTracks.firstWhere(
        (t) => t.id == 'linux',
      );
      expect(linuxTrack.hasPathway, isTrue);
      expect(linuxTrack.title, 'Linux Essentials');

      bool didTap = false;
      await tester.pumpWidget(
        _wrapScreen(
          authProvider: authProvider,
          child: LearningTrackCard(
            track: linuxTrack,
            isActive: true,
            onSelect: () => didTap = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Linux Essentials'), findsOneWidget);
      expect(find.text('View Pathway'), findsOneWidget);

      await tester.tap(find.text('View Pathway'));
      expect(didTap, isTrue);
    });
  });
}
