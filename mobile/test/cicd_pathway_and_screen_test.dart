import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:devops_learning_app/core/theme/app_theme.dart';
import 'package:devops_learning_app/features/module/screens/cicd_module_screen.dart';
import 'package:devops_learning_app/features/pathway/data/cicd_curriculum_repository.dart';
import 'package:devops_learning_app/features/pathway/data/progress_service.dart';
import 'package:devops_learning_app/features/pathway/screens/cicd_pathway_screen.dart';
import 'package:devops_learning_app/features/pathway/widgets/pathway_fasttrack_banner.dart';
import 'package:devops_learning_app/models/curriculum_model.dart';
import 'package:devops_learning_app/models/user_model.dart';
import 'package:devops_learning_app/providers/auth_provider.dart';

import 'auth_provider_test.dart';

class MockCicdApiClient extends FakeApiClient {
  MockCicdApiClient({required super.storageService});

  final Map<String, Set<String>> completedByPathway = {};

  @override
  Future<Map<String, dynamic>> getProgress({String pathwayId = 'cicd'}) async {
    final list = completedByPathway[pathwayId] ?? {};
    return {
      'success': true,
      'completedModules': list.toList(),
    };
  }

  @override
  Future<Map<String, dynamic>> toggleProgress({
    required String moduleId,
    String pathwayId = 'cicd',
  }) async {
    final set = completedByPathway.putIfAbsent(pathwayId, () => {});
    if (set.contains(moduleId)) {
      set.remove(moduleId);
    } else {
      set.add(moduleId);
    }
    return {
      'success': true,
      'completedModules': set.toList(),
    };
  }

  @override
  Future<Map<String, dynamic>> logActivity({
    required String type,
    required String stopSlug,
    String pathwayId = 'cicd',
  }) async {
    return {'success': true};
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

  late List<CurriculumModule> cicdModules;
  late MockSecureStorageService storageService;
  late MockCicdApiClient mockApi;
  late AuthProvider authProvider;

  setUpAll(() {
    final raw = File('assets/data/cicd_curriculum.json').readAsStringSync();
    final List<dynamic> decoded = json.decode(raw) as List<dynamic>;
    cicdModules = decoded
        .map((m) => CurriculumModule.fromJson(m as Map<String, dynamic>))
        .toList();
  });

  setUp(() async {
    CicdCurriculumRepository.setCachedModules(cicdModules);

    storageService = MockSecureStorageService();
    mockApi = MockCicdApiClient(storageService: storageService);
    mockApi.mockUser = const UserModel(
      id: 'test-cicd-user-123',
      name: 'CI/CD Learner',
      email: 'cicd@example.com',
    );
    authProvider = AuthProvider(
      apiClient: mockApi,
      storageService: storageService,
    );
    await authProvider.login(
      email: 'cicd@example.com',
      password: 'password123',
    );

    ProgressService().init(
      apiClient: mockApi,
      storageService: storageService,
    );
    ProgressService().clearCache();
  });

  tearDown(() {
    ProgressService().clearCache();
  });

  group('CI/CD Curriculum Data Parity', () {
    test('Loads exactly 7 curriculum modules matching Web cicdCurriculum.js', () {
      expect(cicdModules.length, equals(7));
      expect(cicdModules[0].id, equals('cicd-01'));
      expect(cicdModules[0].title, equals('01. CI/CD Fundamentals'));
      expect(cicdModules[1].id, equals('cicd-02'));
      expect(cicdModules[1].title, equals('02. Jenkins & Pipeline Automation'));
      expect(cicdModules[2].id, equals('cicd-03'));
      expect(cicdModules[2].title, equals('03. GitHub Actions'));
      expect(cicdModules[3].id, equals('cicd-04'));
      expect(cicdModules[3].title, equals('04. Automated Testing & Code Quality'));
      expect(cicdModules[4].id, equals('cicd-05'));
      expect(cicdModules[4].title, equals('05. Deployment Strategies & Release Management'));
      expect(cicdModules[5].id, equals('cicd-06'));
      expect(cicdModules[5].title, equals('06. GitOps & Argo CD'));
      expect(cicdModules[6].id, equals('cicd-07'));
      expect(cicdModules[6].title, equals('07. Production CI/CD Pipeline Project'));
    });

    test('Every module has learning objectives, sections, and content', () {
      for (final module in cicdModules) {
        expect(module.objectives.isNotEmpty, isTrue, reason: '${module.id} has objectives');
        expect(module.sections.isNotEmpty, isTrue, reason: '${module.id} has sections');
        for (final sec in module.sections) {
          expect(sec.title.isNotEmpty, isTrue);
          expect(sec.paragraphs.isNotEmpty, isTrue);
        }
      }
    });

    test('Sequential module unlocking within CI/CD pathway', () {
      final completed = <String>{};
      expect(
        ProgressService.isModuleUnlocked(
          pathway: 'cicd',
          moduleId: 'cicd-01',
          completedModules: completed,
        ),
        isTrue,
        reason: 'cicd-01 is always unlocked first',
      );
      expect(
        ProgressService.isModuleUnlocked(
          pathway: 'cicd',
          moduleId: 'cicd-02',
          completedModules: completed,
        ),
        isFalse,
        reason: 'cicd-02 requires cicd-01 to be completed',
      );

      completed.add('cicd-01');
      expect(
        ProgressService.isModuleUnlocked(
          pathway: 'cicd',
          moduleId: 'cicd-02',
          completedModules: completed,
        ),
        isTrue,
        reason: 'cicd-02 unlocks after cicd-01 is complete',
      );
    });
  });

  group('CI/CD Pathway Screen Widgets & Interactions', () {
    testWidgets('Renders unlocked CI/CD pathway when prerequisites are met', (tester) async {
      final gitModules = {'git-01', 'git-02', 'git-03', 'git-04', 'git-05', 'git-06', 'git-07'};
      final linuxModules = {'linux-01', 'linux-02', 'linux-03', 'linux-04', 'linux-05', 'linux-06'};
      final dockerModules = {'docker-01', 'docker-02', 'docker-03', 'docker-04', 'docker-05', 'docker-06', 'docker-07'};

      mockApi.completedByPathway['git'] = gitModules;
      mockApi.completedByPathway['linux'] = linuxModules;
      mockApi.completedByPathway['docker'] = dockerModules;

      ProgressService().setCompletedModulesCache('test-cicd-user-123', gitModules, pathway: 'git');
      ProgressService().setCompletedModulesCache('test-cicd-user-123', linuxModules, pathway: 'linux');
      ProgressService().setCompletedModulesCache('test-cicd-user-123', dockerModules, pathway: 'docker');

      await tester.pumpWidget(
        _wrapScreen(
          child: const CicdPathwayScreen(),
          authProvider: authProvider,
        ),
      );
      await tester.pumpAndSettle();

      // Check header and titles
      expect(find.text('CI/CD & GitOps Delivery Pathway'), findsOneWidget);
      expect(find.byType(PathwayFastTrackBanner), findsOneWidget);
      expect(find.text('Attempt Pathway Quiz'), findsOneWidget);

      // Check all 7 modules render by shortTitle
      for (final module in cicdModules) {
        expect(find.text(module.shortTitle), findsWidgets);
      }

      // Check milestone monument shows progress finish
      expect(find.text('Pathway Milestone Finish'), findsOneWidget);
    });

    testWidgets('Renders all-completed monument when all 7 CI/CD modules are completed', (tester) async {
      final gitModules = {'git-01', 'git-02', 'git-03', 'git-04', 'git-05', 'git-06', 'git-07'};
      final linuxModules = {'linux-01', 'linux-02', 'linux-03', 'linux-04', 'linux-05', 'linux-06'};
      final dockerModules = {'docker-01', 'docker-02', 'docker-03', 'docker-04', 'docker-05', 'docker-06', 'docker-07'};
      final cicdAll = {'cicd-01', 'cicd-02', 'cicd-03', 'cicd-04', 'cicd-05', 'cicd-06', 'cicd-07'};

      mockApi.completedByPathway['git'] = gitModules;
      mockApi.completedByPathway['linux'] = linuxModules;
      mockApi.completedByPathway['docker'] = dockerModules;
      mockApi.completedByPathway['cicd'] = cicdAll;

      ProgressService().setCompletedModulesCache('test-cicd-user-123', gitModules, pathway: 'git');
      ProgressService().setCompletedModulesCache('test-cicd-user-123', linuxModules, pathway: 'linux');
      ProgressService().setCompletedModulesCache('test-cicd-user-123', dockerModules, pathway: 'docker');
      ProgressService().setCompletedModulesCache('test-cicd-user-123', cicdAll, pathway: 'cicd');

      await tester.pumpWidget(
        _wrapScreen(
          child: const CicdPathwayScreen(),
          authProvider: authProvider,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('CI/CD & GitOps Delivery Mastered!'), findsOneWidget);
    });
  });

  group('CI/CD Module Screen Content & Navigation', () {
    testWidgets('Renders CI/CD module screen with sections and navigation', (tester) async {
      // Unlock CI/CD pathway
      final gitModules = {'git-01', 'git-02', 'git-03', 'git-04', 'git-05', 'git-06', 'git-07'};
      final linuxModules = {'linux-01', 'linux-02', 'linux-03', 'linux-04', 'linux-05', 'linux-06'};
      final dockerModules = {'docker-01', 'docker-02', 'docker-03', 'docker-04', 'docker-05', 'docker-06', 'docker-07'};

      mockApi.completedByPathway['git'] = gitModules;
      mockApi.completedByPathway['linux'] = linuxModules;
      mockApi.completedByPathway['docker'] = dockerModules;

      ProgressService().setCompletedModulesCache('test-cicd-user-123', gitModules, pathway: 'git');
      ProgressService().setCompletedModulesCache('test-cicd-user-123', linuxModules, pathway: 'linux');
      ProgressService().setCompletedModulesCache('test-cicd-user-123', dockerModules, pathway: 'docker');

      await tester.pumpWidget(
        _wrapScreen(
          child: const CicdModuleScreen(moduleId: 'cicd-01'),
          authProvider: authProvider,
        ),
      );
      await tester.pumpAndSettle();

      // Verify module title and header
      expect(find.text('01. CI/CD Fundamentals'), findsWidgets);
      expect(find.text('Objectives'), findsOneWidget);

      // Verify subtopic navigation chips (clean title without number prefix)
      final firstModule = cicdModules.first;
      for (final sec in firstModule.sections) {
        final cleanTitle = sec.title.replaceFirst(RegExp(r'^\d+\.\s*'), '');
        expect(find.text(cleanTitle), findsWidgets);
      }

      // Verify Back to Pathway button
      expect(find.text('Back to CI/CD Pathway'), findsOneWidget);
    });
  });
}
