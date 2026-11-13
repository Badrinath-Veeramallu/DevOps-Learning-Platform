import 'package:devops_learning_app/features/dashboard/models/learning_path_track.dart';
import 'package:devops_learning_app/features/dashboard/widgets/continue_learning_card.dart';
import 'package:devops_learning_app/features/dashboard/widgets/learning_track_card.dart';
import 'package:devops_learning_app/features/pathway/data/progress_service.dart';
import 'package:devops_learning_app/features/pathway/screens/docker_pathway_screen.dart';
import 'package:devops_learning_app/features/pathway/screens/linux_pathway_screen.dart';
import 'package:devops_learning_app/models/user_model.dart';
import 'package:devops_learning_app/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class MockAuthProvider extends ChangeNotifier implements AuthProvider {
  @override
  UserModel? user;

  @override
  bool get isAuthenticated => user != null;

  @override
  bool get isLoading => false;

  @override
  bool get isInitialized => true;

  @override
  String? get errorMessage => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Sequential Pathway Locking (Git -> Docker -> Linux)', () {
    late ProgressService progressService;
    const testUserId = 'test_pathway_user';

    setUp(() {
      progressService = ProgressService();
      progressService.clearCache();
    });

    test('1. Initial state: Git unlocked, Docker locked, Linux locked', () {
      expect(
        progressService.isPathwayUnlocked(pathway: 'git', userId: testUserId),
        isTrue,
        reason: 'Git must be unlocked by default',
      );
      expect(
        progressService.isPathwayUnlocked(pathway: 'docker', userId: testUserId),
        isFalse,
        reason: 'Docker must be locked by default',
      );
      expect(
        progressService.isPathwayUnlocked(pathway: 'linux', userId: testUserId),
        isFalse,
        reason: 'Linux must be locked by default',
      );
      expect(
        progressService.getPathwayLockReason(pathway: 'docker', userId: testUserId),
        contains('Complete all 7 Git modules'),
      );
    });

    test('2. Partial Git completion (6 of 7) keeps Docker and Linux locked', () {
      progressService.setCompletedModulesCache(
        testUserId,
        {'git-01', 'git-02', 'git-03', 'git-04', 'git-05', 'git-06'},
        pathway: 'git',
      );

      expect(
        progressService.isPathwayCompleted(pathway: 'git', userId: testUserId),
        isFalse,
      );
      expect(
        progressService.isPathwayUnlocked(pathway: 'docker', userId: testUserId),
        isFalse,
        reason: 'Docker must remain locked with only 6 of 7 Git modules completed',
      );
      expect(
        progressService.isPathwayUnlocked(pathway: 'linux', userId: testUserId),
        isFalse,
        reason: 'Linux must remain locked',
      );
    });

    test('3. Full Git completion unlocks Docker, but Linux remains locked', () {
      progressService.setCompletedModulesCache(
        testUserId,
        {'git-01', 'git-02', 'git-03', 'git-04', 'git-05', 'git-06', 'git-07'},
        pathway: 'git',
      );

      expect(
        progressService.isPathwayCompleted(pathway: 'git', userId: testUserId),
        isTrue,
      );
      expect(
        progressService.isPathwayUnlocked(pathway: 'docker', userId: testUserId),
        isTrue,
        reason: 'Docker must unlock when all 7 Git modules are completed',
      );
      expect(
        progressService.isPathwayUnlocked(pathway: 'linux', userId: testUserId),
        isFalse,
        reason: 'Linux must remain locked until Docker is also completed',
      );
      expect(
        progressService.getPathwayLockReason(pathway: 'linux', userId: testUserId),
        contains('Complete all 7 Docker modules'),
      );
    });

    test('4. Full Docker completion (with Git complete) unlocks Linux', () {
      progressService.setCompletedModulesCache(
        testUserId,
        {'git-01', 'git-02', 'git-03', 'git-04', 'git-05', 'git-06', 'git-07'},
        pathway: 'git',
      );
      progressService.setCompletedModulesCache(
        testUserId,
        {
          'docker-01',
          'docker-02',
          'docker-03',
          'docker-04',
          'docker-05',
          'docker-06',
          'docker-07',
        },
        pathway: 'docker',
      );

      expect(
        progressService.isPathwayCompleted(pathway: 'docker', userId: testUserId),
        isTrue,
      );
      expect(
        progressService.isPathwayUnlocked(pathway: 'linux', userId: testUserId),
        isTrue,
        reason: 'Linux must unlock when all Docker modules are completed',
      );
      expect(
        progressService.getPathwayLockReason(pathway: 'linux', userId: testUserId),
        isNull,
      );
    });

    test('5. Cascading relocking when user uncompletes Git module preserves historical progress', () {
      // Setup fully completed Git and Docker
      progressService.setCompletedModulesCache(
        testUserId,
        {'git-01', 'git-02', 'git-03', 'git-04', 'git-05', 'git-06', 'git-07'},
        pathway: 'git',
      );
      final dockerModules = {
        'docker-01',
        'docker-02',
        'docker-03',
        'docker-04',
        'docker-05',
        'docker-06',
        'docker-07',
      };
      progressService.setCompletedModulesCache(
        testUserId,
        dockerModules,
        pathway: 'docker',
      );

      expect(progressService.isPathwayUnlocked(pathway: 'docker', userId: testUserId), isTrue);
      expect(progressService.isPathwayUnlocked(pathway: 'linux', userId: testUserId), isTrue);

      // User uncompletes git-07
      progressService.setCompletedModulesCache(
        testUserId,
        {'git-01', 'git-02', 'git-03', 'git-04', 'git-05', 'git-06'},
        pathway: 'git',
      );

      // Both Docker and Linux must immediately relock!
      expect(
        progressService.isPathwayUnlocked(pathway: 'docker', userId: testUserId),
        isFalse,
        reason: 'Docker must immediately relock when Git is no longer complete',
      );
      expect(
        progressService.isPathwayUnlocked(pathway: 'linux', userId: testUserId),
        isFalse,
        reason: 'Linux must immediately relock when Git is no longer complete',
      );

      // Crucial: Historical progress in Docker must NOT be deleted!
      final preservedDocker = progressService.getCompletedModulesSync(testUserId, pathway: 'docker');
      expect(preservedDocker.length, equals(7), reason: 'Historical Docker completion records must be preserved');

      // Re-completing git-07 restores Docker and Linux access immediately
      progressService.setCompletedModulesCache(
        testUserId,
        {'git-01', 'git-02', 'git-03', 'git-04', 'git-05', 'git-06', 'git-07'},
        pathway: 'git',
      );
      expect(
        progressService.isPathwayUnlocked(pathway: 'docker', userId: testUserId),
        isTrue,
        reason: 'Docker unlocks again when Git is re-completed',
      );
      expect(
        progressService.isPathwayUnlocked(pathway: 'linux', userId: testUserId),
        isTrue,
        reason: 'Linux unlocks again because preserved Docker modules make Docker complete again',
      );
    });

    test('6. Attempting to toggle module in locked pathway returns false and does not complete', () async {
      // User has no Git progress
      final result = await progressService.toggleModuleCompletion(
        testUserId,
        'docker-01',
        pathway: 'docker',
      );

      expect(result, isFalse, reason: 'Must not allow toggling module in locked Docker pathway');
      final completed = progressService.getCompletedModulesSync(testUserId, pathway: 'docker');
      expect(completed.contains('docker-01'), isFalse);
    });

    testWidgets('7. LearningTrackCard displays locked badge and hint when locked', (tester) async {
      bool tapped = false;
      const track = LearningPathTrack(
        id: 'docker',
        title: 'Docker & Container Engineering',
        level: 'Intermediate',
        modules: '7 Modules · Interactive Pathway',
        description: 'Container isolation and Dockerfile engineering.',
        hasPathway: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LearningTrackCard(
              track: track,
              isActive: false,
              isLocked: true,
              lockReason: 'Complete all 7 Git modules to unlock the Docker pathway.',
              onSelect: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Locked'), findsWidgets);
      expect(find.byIcon(Icons.lock_outline), findsWidgets);
      expect(find.text('Complete all 7 Git modules to unlock the Docker pathway.'), findsOneWidget);

      await tester.tap(find.text('Locked').last);
      expect(tapped, isTrue);
    });

    testWidgets('8. ContinueLearningCard displays locked badge when locked', (tester) async {
      const track = LearningPathTrack(
        id: 'linux',
        title: 'Linux Essentials',
        level: 'Foundational',
        modules: '6 Lessons · Interactive Pathway',
        description: 'Terminal navigation and automation.',
        hasPathway: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContinueLearningCard(
              track: track,
              isLocked: true,
              lockReason: 'Complete all 7 Docker modules to unlock the Linux pathway.',
              onContinue: () {},
            ),
          ),
        ),
      );

      expect(find.text('Locked'), findsWidgets);
      expect(find.byIcon(Icons.lock_outline), findsWidgets);
      expect(find.text('Complete all 7 Docker modules to unlock the Linux pathway.'), findsOneWidget);
    });

    testWidgets('9. DockerPathwayScreen renders locked state when Docker is locked', (tester) async {
      final mockAuth = MockAuthProvider();

      await tester.pumpWidget(
        ChangeNotifierProvider<AuthProvider>.value(
          value: mockAuth,
          child: const MaterialApp(
            home: DockerPathwayScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pathway Locked'), findsOneWidget);
      expect(find.text('Docker & Containerization'), findsOneWidget);
      expect(find.text('Go to Git Pathway'), findsOneWidget);
      expect(find.text('Back to Dashboard'), findsOneWidget);
    });

    testWidgets('10. LinuxPathwayScreen renders locked state when Linux is locked', (tester) async {
      final mockAuth = MockAuthProvider();

      await tester.pumpWidget(
        ChangeNotifierProvider<AuthProvider>.value(
          value: mockAuth,
          child: const MaterialApp(
            home: LinuxPathwayScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pathway Locked'), findsOneWidget);
      expect(find.text('Linux Essentials'), findsOneWidget);
      expect(find.text('Go to Git Pathway'), findsOneWidget);
      expect(find.text('Back to Dashboard'), findsOneWidget);
    });
  });
}
