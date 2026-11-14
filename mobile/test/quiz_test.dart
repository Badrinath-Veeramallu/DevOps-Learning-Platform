import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:devops_learning_app/core/api/api_exceptions.dart';
import 'package:devops_learning_app/core/router/app_router.dart';
import 'package:devops_learning_app/core/theme/app_theme.dart';
import 'package:devops_learning_app/features/module/screens/git_module_screen.dart';
import 'package:devops_learning_app/features/pathway/data/progress_service.dart';
import 'package:devops_learning_app/features/quiz/data/quiz_service.dart';
import 'package:devops_learning_app/features/quiz/screens/pathway_quiz_screen.dart';
import 'package:devops_learning_app/models/quiz_model.dart';
import 'package:devops_learning_app/models/user_model.dart';
import 'package:devops_learning_app/providers/auth_provider.dart';

import 'auth_provider_test.dart';

class MockQuizApiClient extends FakeApiClient {
  MockQuizApiClient({required super.storageService});

  bool shouldLockPrereq = false;
  int mockScore = 15;
  bool mockPassed = true;
  bool mockHasPassedEver = true;

  bool calledGetFastTrack = false;
  bool calledSubmitFastTrack = false;
  bool calledGetStandard = false;
  bool calledSubmitStandard = false;

  @override
  Future<Map<String, dynamic>> getQuiz({required String pathwayId}) async {
    calledGetStandard = true;
    if (shouldLockPrereq) {
      throw const ApiException(
        statusCode: 403,
        message: 'You must complete all pathway modules before taking the final quiz.',
      );
    }

    final questions = List.generate(20, (i) {
      final num = i + 1;
      final qId = '$pathwayId-q${num < 10 ? "0$num" : "$num"}';
      return {
        'id': qId,
        'question': 'Sample Question $num for $pathwayId',
        'options': [
          'Option A for $qId',
          'Option B for $qId (Correct)',
          'Option C for $qId',
          'Option D for $qId',
        ],
      };
    });

    return {
      'success': true,
      'pathwayId': pathwayId,
      'totalQuestions': 20,
      'passingScore': 10,
      'questions': questions,
      'status': {
        'hasPassed': mockHasPassedEver,
        'bestScore': mockScore,
        'attemptsCount': 1,
      },
    };
  }

  @override
  Future<Map<String, dynamic>> submitQuiz({
    required String pathwayId,
    required Map<String, int> answers,
  }) async {
    calledSubmitStandard = true;
    if (shouldLockPrereq) {
      throw const ApiException(
        statusCode: 403,
        message: 'Submission rejected: modules must be complete before submitting.',
      );
    }

    final review = List.generate(20, (i) {
      final num = i + 1;
      final qId = '$pathwayId-q${num < 10 ? "0$num" : "$num"}';
      final userChoice = answers[qId];
      final isCorrect = userChoice == 1;
      return {
        'id': qId,
        'question': 'Sample Question $num for $pathwayId',
        'options': [
          'Option A for $qId',
          'Option B for $qId (Correct)',
          'Option C for $qId',
          'Option D for $qId',
        ],
        'selectedOption': userChoice,
        'correctOption': 1,
        'isCorrect': isCorrect,
        'explanation': 'Option B is the correct answer according to official curriculum.',
      };
    });

    return {
      'success': true,
      'pathwayId': pathwayId,
      'score': mockScore,
      'totalQuestions': 20,
      'percentage': ((mockScore / 20) * 100).round(),
      'passed': mockPassed,
      'hasPassedEver': mockHasPassedEver,
      'bestScore': mockScore,
      'attemptsCount': 1,
      'review': review,
    };
  }

  @override
  Future<Map<String, dynamic>> getFastTrackQuiz({required String pathwayId}) async {
    calledGetFastTrack = true;
    final questions = List.generate(20, (i) {
      final num = i + 1;
      final qId = '$pathwayId-ft-q${num < 10 ? "0$num" : "$num"}';
      return {
        'id': qId,
        'question': 'Fast Track Question $num for $pathwayId',
        'options': [
          'Option A for $qId',
          'Option B for $qId (Correct)',
          'Option C for $qId',
          'Option D for $qId',
        ],
      };
    });

    return {
      'success': true,
      'pathwayId': pathwayId,
      'isFastTrack': true,
      'totalQuestions': 20,
      'passingScore': 10,
      'questions': questions,
      'status': {
        'hasPassed': mockHasPassedEver,
        'bestScore': mockScore,
        'attemptsCount': 1,
      },
    };
  }

  @override
  Future<Map<String, dynamic>> submitFastTrackQuiz({
    required String pathwayId,
    required Map<String, int> answers,
  }) async {
    calledSubmitFastTrack = true;
    return {
      'success': true,
      'pathwayId': pathwayId,
      'isFastTrack': true,
      'score': mockScore,
      'totalQuestions': 20,
      'percentage': ((mockScore / 20) * 100).round(),
      'passed': mockPassed,
      'hasPassedEver': mockHasPassedEver,
      'bestScore': mockScore,
      'attemptsCount': 1,
      'completedModules': ['$pathwayId-01', '$pathwayId-02'],
      'review': [],
    };
  }

  @override
  Future<Map<String, dynamic>> getQuizStatus({required String pathwayId}) async {
    return {
      'success': true,
      'pathwayId': pathwayId,
      'isEligible': !shouldLockPrereq,
      'hasPassed': mockHasPassedEver,
      'bestScore': mockScore,
      'totalQuestions': 20,
      'passingScore': 10,
      'attemptsCount': 1,
    };
  }

  @override
  Future<Map<String, dynamic>> getProgress({String pathwayId = 'git'}) async {
    return {
      'success': true,
      'completedModules': ['git-01', 'git-02', 'git-03', 'git-04', 'git-05', 'git-06', 'git-07'],
    };
  }
}

Widget _wrapWidget({
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

  late MockSecureStorageService storageService;
  late MockQuizApiClient mockApi;
  late AuthProvider authProvider;
  late QuizService quizService;

  setUp(() async {
    storageService = MockSecureStorageService();
    mockApi = MockQuizApiClient(storageService: storageService);
    mockApi.mockUser = const UserModel(
      id: 'usr_quiz_tester',
      name: 'Quiz Master',
      email: 'quiz@devops.com',
    );
    authProvider = AuthProvider(
      apiClient: mockApi,
      storageService: storageService,
    );
    await authProvider.login(
      email: 'quiz@devops.com',
      password: 'password123',
    );

    quizService = QuizService();
    quizService.init(apiClient: mockApi);
    quizService.clearCache();

    ProgressService().init(apiClient: mockApi, storageService: storageService);
    ProgressService().clearCache();
  });

  tearDown(() {
    quizService.clearCache();
    ProgressService().clearCache();
  });

  group('Final Quiz System Tests', () {
    test('1. Quiz models serialize and deserialize accurately', () {
      final q = QuizQuestion.fromJson({
        'id': 'git-q01',
        'question': 'What is git init?',
        'options': ['A', 'B', 'C', 'D'],
      });
      expect(q.id, 'git-q01');
      expect(q.options.length, 4);

      final res = QuizResult.fromJson({
        'pathwayId': 'git',
        'score': 15,
        'totalQuestions': 20,
        'percentage': 75,
        'passed': true,
        'hasPassedEver': true,
        'bestScore': 15,
        'attemptsCount': 1,
        'review': [
          {
            'id': 'git-q01',
            'question': 'What is git init?',
            'options': ['A', 'B', 'C', 'D'],
            'selectedOption': 1,
            'correctOption': 1,
            'isCorrect': true,
            'explanation': 'Creates a repo.',
          }
        ],
      });
      expect(res.score, 15);
      expect(res.passed, isTrue);
      expect(res.review.first.isCorrect, isTrue);
    });

    test('2. QuizService fetches questions and handles 403 lock', () async {
      mockApi.shouldLockPrereq = false;
      final data = await quizService.fetchQuiz('git');
      expect(data.questions.length, 20);
      expect(data.status.isEligible, isTrue);

      mockApi.shouldLockPrereq = true;
      expect(
        () => quizService.fetchQuiz('git'),
        throwsA(isA<QuizPrerequisiteException>()),
      );
    });

    testWidgets('3. PathwayQuizScreen renders Quiz Introduction and transitions on Start Quiz',
        (tester) async {
      mockApi.shouldLockPrereq = false;

      await tester.pumpWidget(
        _wrapWidget(
          authProvider: authProvider,
          child: const PathwayQuizScreen(pathwayId: 'git'),
        ),
      );
      await tester.pumpAndSettle();

      // Introduction view assertions
      expect(find.text('GIT & GITHUB'), findsOneWidget);
      expect(find.text('Final Comprehensive Quiz'), findsOneWidget);
      expect(find.text('20 Questions'), findsOneWidget);
      expect(find.text('10 / 20 (50%)'), findsOneWidget);
      expect(find.text('Start Quiz'), findsOneWidget);

      // Tap Start Quiz
      await tester.ensureVisible(find.text('Start Quiz'));
      await tester.tap(find.text('Start Quiz'));
      await tester.pumpAndSettle();

      // Active Question Interface
      expect(find.text('QUESTION 1 OF 20'), findsOneWidget);
      expect(find.text('Sample Question 1 for git'), findsOneWidget);
      expect(find.text('Exit Quiz'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
      expect(find.text('Submit'), findsOneWidget);
    });

    testWidgets('4. Selecting an option updates selection and answer count',
        (tester) async {
      mockApi.shouldLockPrereq = false;

      await tester.pumpWidget(
        _wrapWidget(
          authProvider: authProvider,
          child: const PathwayQuizScreen(pathwayId: 'git', autoStart: true),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Answered: 0/20'), findsWidgets);

      // Tap option B
      await tester.tap(find.text('Option B for git-q01 (Correct)'));
      await tester.pumpAndSettle();

      expect(find.text('Answered: 1/20'), findsWidgets);
    });

    testWidgets('5. Next and Prev navigate cleanly between questions',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      mockApi.shouldLockPrereq = false;

      await tester.pumpWidget(
        _wrapWidget(
          authProvider: authProvider,
          child: const PathwayQuizScreen(pathwayId: 'git', autoStart: true),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Next to go to Question 2
      await tester.ensureVisible(find.text('Next'));
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('QUESTION 2 OF 20'), findsOneWidget);
      expect(find.text('Sample Question 2 for git'), findsOneWidget);

      // Tap Prev to return to Question 1
      await tester.ensureVisible(find.text('Prev'));
      await tester.tap(find.text('Prev'));
      await tester.pumpAndSettle();

      expect(find.text('QUESTION 1 OF 20'), findsOneWidget);
    });

    testWidgets('6. Submitting quiz renders passing result and detailed answer review',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      mockApi.shouldLockPrereq = false;
      mockApi.mockScore = 18;
      mockApi.mockPassed = true;

      await tester.pumpWidget(
        _wrapWidget(
          authProvider: authProvider,
          child: const PathwayQuizScreen(pathwayId: 'git', autoStart: true),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Submit button -> opens confirmation modal
      await tester.ensureVisible(find.text('Submit'));
      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();

      expect(find.text('Submit Final Quiz?'), findsOneWidget);

      // Tap confirm Submit Quiz in bottom sheet
      final submitModalBtn = find.widgetWithText(ElevatedButton, 'Submit Quiz');
      await tester.tap(submitModalBtn);
      await tester.pumpAndSettle();

      // Result screen
      expect(find.text('Congratulations! You Passed!'), findsOneWidget);
      expect(find.text('18 / 20'), findsOneWidget);
      expect(find.text('90% Score (Passing: 10/20)'), findsOneWidget);
      expect(find.text('Return to Pathway Map'), findsOneWidget);
      expect(find.text('Continue to Linux Essentials →'), findsOneWidget);

      // Toggle Review
      await tester.ensureVisible(find.text('Review Answers'));
      await tester.tap(find.text('Review Answers'));
      await tester.pumpAndSettle();

      expect(find.text('Detailed Answer Review'), findsOneWidget);
    });

    testWidgets('7. Submitting quiz renders failing result with retake instructions',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      mockApi.shouldLockPrereq = false;
      mockApi.mockScore = 8;
      mockApi.mockPassed = false;

      await tester.pumpWidget(
        _wrapWidget(
          authProvider: authProvider,
          child: const PathwayQuizScreen(pathwayId: 'git', autoStart: true),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Submit'));
      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();

      final submitModalBtn = find.widgetWithText(ElevatedButton, 'Submit Quiz');
      await tester.tap(submitModalBtn);
      await tester.pumpAndSettle();

      expect(find.text('Keep Practicing!'), findsOneWidget);
      expect(find.text('8 / 20'), findsOneWidget);
      expect(find.text('40% Score (Passing: 10/20)'), findsOneWidget);
      expect(find.text('Retake Quiz'), findsOneWidget);
    });

    testWidgets('8. Prerequisite locked screen displays when modules incomplete',
        (tester) async {
      mockApi.shouldLockPrereq = true;

      await tester.pumpWidget(
        _wrapWidget(
          authProvider: authProvider,
          child: const PathwayQuizScreen(pathwayId: 'git'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Final Quiz Locked'), findsOneWidget);
      expect(find.text('Return to Pathway'), findsOneWidget);
    });

    testWidgets('9. All 4 pathways (Git, Linux, Docker, CI/CD) load their quizzes with correct titles',
        (tester) async {
      for (final pId in ['git', 'linux', 'docker', 'cicd']) {
        await tester.pumpWidget(
          _wrapWidget(
            authProvider: authProvider,
            child: PathwayQuizScreen(pathwayId: pId, autoStart: true),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('QUESTION 1 OF 20'), findsOneWidget);
        expect(find.text('Sample Question 1 for $pId'), findsOneWidget);
      }
    });

    testWidgets('10. Fast-track and standard quizzes use separate API endpoints',
        (tester) async {
      // Standard quiz
      await tester.pumpWidget(
        _wrapWidget(
          authProvider: authProvider,
          child: const PathwayQuizScreen(pathwayId: 'git', isFastTrack: false, autoStart: true),
        ),
      );
      await tester.pumpAndSettle();
      expect(mockApi.calledGetStandard, isTrue);
      expect(mockApi.calledGetFastTrack, isFalse);

      // Fast-track quiz
      await tester.pumpWidget(
        _wrapWidget(
          authProvider: authProvider,
          child: const PathwayQuizScreen(pathwayId: 'docker', isFastTrack: true, autoStart: true),
        ),
      );
      await tester.pumpAndSettle();
      expect(mockApi.calledGetFastTrack, isTrue);
    });

    testWidgets('11. Final Quiz route navigation is not shadowed by :moduleId',
        (tester) async {
      final router = AppRouter.createRouter(authProvider);

      await tester.pumpWidget(
        ChangeNotifierProvider<AuthProvider>.value(
          value: authProvider,
          child: MaterialApp.router(
            theme: AppTheme.darkTheme,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to /pathways/git/quiz
      router.go('/pathways/git/quiz');
      await tester.pumpAndSettle();

      // Must render PathwayQuizScreen, NOT GitModuleScreen
      expect(find.byType(PathwayQuizScreen), findsOneWidget);
      expect(find.text('GIT & GITHUB'), findsOneWidget);
      expect(find.text('Final Comprehensive Quiz'), findsOneWidget);
      expect(find.byType(GitModuleScreen), findsNothing);

      // Navigate to /pathways/docker/quiz
      router.go('/pathways/docker/quiz');
      await tester.pumpAndSettle();
      expect(find.byType(PathwayQuizScreen), findsOneWidget);
      expect(find.text('DOCKER & CONTAINERS'), findsOneWidget);

      // Navigate to /pathways/linux/quiz
      router.go('/pathways/linux/quiz');
      await tester.pumpAndSettle();
      expect(find.byType(PathwayQuizScreen), findsOneWidget);
      expect(find.text('LINUX ESSENTIALS'), findsOneWidget);

      // Navigate to /pathways/cicd/quiz
      router.go('/pathways/cicd/quiz');
      await tester.pumpAndSettle();
      expect(find.byType(PathwayQuizScreen), findsOneWidget);
      expect(find.text('CI/CD & GITOPS DELIVERY'), findsOneWidget);
    });
  });
}
