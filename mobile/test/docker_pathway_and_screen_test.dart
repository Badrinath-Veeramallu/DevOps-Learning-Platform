import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:devops_learning_app/core/router/app_router.dart';
import 'package:devops_learning_app/core/router/route_names.dart';
import 'package:devops_learning_app/core/theme/app_theme.dart';
import 'package:devops_learning_app/features/animations/services/animation_loader.dart';
import 'package:devops_learning_app/features/dashboard/models/learning_path_track.dart';
import 'package:devops_learning_app/features/dashboard/widgets/continue_learning_card.dart';
import 'package:devops_learning_app/features/dashboard/widgets/learning_track_card.dart';
import 'package:devops_learning_app/features/module/screens/docker_module_screen.dart';
import 'package:devops_learning_app/features/pathway/data/activity_service.dart';
import 'package:devops_learning_app/features/pathway/data/docker_curriculum_repository.dart';
import 'package:devops_learning_app/features/pathway/data/progress_service.dart';
import 'package:devops_learning_app/features/pathway/screens/docker_pathway_screen.dart';
import 'package:devops_learning_app/models/animation_model.dart';
import 'package:devops_learning_app/models/curriculum_model.dart';
import 'package:devops_learning_app/models/user_model.dart';
import 'package:devops_learning_app/providers/auth_provider.dart';

import 'auth_provider_test.dart';

class MockDockerApiClient extends FakeApiClient {
  MockDockerApiClient({required super.storageService});

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

  late List<CurriculumModule> dockerModules;
  late List<AnimationModule> dockerAnimModules;
  late MockSecureStorageService storageService;
  late MockDockerApiClient mockApi;
  late AuthProvider authProvider;

  setUpAll(() {
    final raw =
        File('assets/data/docker_curriculum.json').readAsStringSync();
    final List<dynamic> decoded = json.decode(raw) as List<dynamic>;
    dockerModules = decoded
        .map((m) => CurriculumModule.fromJson(m as Map<String, dynamic>))
        .toList();

    final animRaw =
        File('assets/data/docker_animations.json').readAsStringSync();
    final Map<String, dynamic> decodedAnim =
        json.decode(animRaw) as Map<String, dynamic>;
    final rawModules = decodedAnim['modules'] as List? ?? [];
    dockerAnimModules = rawModules
        .map((m) => AnimationModule.fromJson(m as Map<String, dynamic>))
        .toList();
  });

  setUp(() async {
    DockerCurriculumRepository.setCachedModules(dockerModules);
    AnimationLoader.setCachedModules(dockerAnimModules, pathway: 'docker');

    storageService = MockSecureStorageService();
    mockApi = MockDockerApiClient(storageService: storageService);
    mockApi.mockUser = const UserModel(
      id: 'test-user-123',
      name: 'Docker Learner',
      email: 'docker@example.com',
    );
    authProvider = AuthProvider(
      apiClient: mockApi,
      storageService: storageService,
    );
    await authProvider.login(
      email: 'docker@example.com',
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

  group('Docker Pathway & Screen UI Tests', () {
    testWidgets('1. DockerPathwayScreen renders header, badges, and 7 stops',
        (tester) async {
      await tester.pumpWidget(
        _wrapScreen(
          authProvider: authProvider,
          child: DockerPathwayScreen(
            initialModules: dockerModules,
            initialCompletedIds: const {'docker-01'},
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Header card
      expect(
        find.text('Docker & Container Learning Pathway'),
        findsOneWidget,
      );
      expect(find.text('Containerization Pathway'), findsOneWidget);
      expect(find.text('7 Interactive Stops'), findsOneWidget);
      expect(find.text('1 of 7 Completed (14%)'), findsOneWidget);

      // Verify Stops are rendered
      expect(find.text('Stop 1 of 7'), findsWidgets);
      expect(find.text('Journey Kickoff'), findsOneWidget);
      expect(find.text('Pathway Milestone Finish'), findsOneWidget);
    });

    testWidgets(
        '2. DockerModuleScreen renders module metadata, objectives, and content',
        (tester) async {
      final mod1 = dockerModules.first;

      await tester.pumpWidget(
        _wrapScreen(
          authProvider: authProvider,
          child: DockerModuleScreen(
            moduleId: 'docker-01',
            initialModules: dockerModules,
            initialCompletedIds: const {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Module Title and Badges
      expect(find.text(mod1.title), findsOneWidget);
      expect(find.text('Stop 1 of 7'), findsOneWidget);
      expect(find.text('Objectives'), findsOneWidget);

      // Verify Subtopics navigation pills
      for (final sec in mod1.sections) {
        final cleanTitle = sec.title.replaceFirst(RegExp(r'^\d+\.\s*'), '');
        expect(find.text(cleanTitle), findsWidgets);
      }

      // Verify completion toggle button
      expect(find.text('Mark Stop as Completed'), findsOneWidget);
    });

    testWidgets(
        '3. Docker module completion toggles state and isolates from Git progress',
        (tester) async {
      final ps = ProgressService();
      const userId = 'test-user-123';

      await tester.pumpWidget(
        _wrapScreen(
          authProvider: authProvider,
          child: DockerModuleScreen(
            moduleId: 'docker-01',
            initialModules: dockerModules,
            initialCompletedIds: const {},
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

      // Verify button updated
      expect(find.text('Completed (Click to Undo)'), findsOneWidget);

      // Verify ProgressService state for docker vs git
      expect(ps.isModuleCompleted(userId, 'docker-01', pathway: 'docker'), isTrue);
      expect(ps.isModuleCompleted(userId, 'docker-01', pathway: 'git'), isFalse);
      expect(ps.isModuleCompleted(userId, 'git-01', pathway: 'git'), isFalse);

      final dockerProgress =
          await ps.getCompletedModules(userId, pathway: 'docker');
      final gitProgress =
          await ps.getCompletedModules(userId, pathway: 'git');

      expect(dockerProgress, contains('docker-01'));
      expect(gitProgress.contains('docker-01'), isFalse);
      expect(gitProgress.isEmpty, isTrue);
    });
  });

  group('Dashboard & AppRouter Docker Integration Tests', () {
    test('1. LearningPathTrack.defaultTracks configures Docker with interactive pathway',
        () {
      final dockerTrack = LearningPathTrack.defaultTracks.firstWhere(
        (t) => t.id == 'docker',
      );

      expect(dockerTrack.hasPathway, isTrue);
      expect(dockerTrack.title, 'Docker & Container Engineering');
      expect(dockerTrack.level, 'Intermediate');
      expect(dockerTrack.modules, '7 Modules · Interactive Pathway');
    });

    testWidgets('2. LearningTrackCard and ContinueLearningCard show pathway button for Docker',
        (tester) async {
      final dockerTrack = LearningPathTrack.defaultTracks.firstWhere(
        (t) => t.id == 'docker',
      );

      bool continued = false;
      bool selected = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  ContinueLearningCard(
                    track: dockerTrack,
                    onContinue: () => continued = true,
                  ),
                  LearningTrackCard(
                    track: dockerTrack,
                    isActive: true,
                    onSelect: () => selected = true,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // ContinueLearningCard
      expect(find.text('Open Pathway'), findsOneWidget);
      expect(find.text('Interactive Pathway Active'), findsOneWidget);
      await tester.tap(find.text('Open Pathway'));
      expect(continued, isTrue);

      // LearningTrackCard
      expect(find.text('View Pathway'), findsOneWidget);
      await tester.tap(find.text('View Pathway'));
      expect(selected, isTrue);
    });

    testWidgets('3. AppRouter protects /pathways/docker against unauthenticated users',
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

      // Attempt navigation to /pathways/docker
      router.go(RouteNames.dockerPathway);
      await tester.pumpAndSettle();

      // Guard should redirect to /login
      expect(router.state.matchedLocation, RouteNames.login);

      // Attempt navigation to /pathways/docker/docker-01
      router.go('/pathways/docker/docker-01');
      await tester.pumpAndSettle();

      // Guard should redirect to /login
      expect(router.state.matchedLocation, RouteNames.login);
    });
  });
}
