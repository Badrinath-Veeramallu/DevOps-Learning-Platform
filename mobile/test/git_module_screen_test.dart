import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:devops_learning_app/core/theme/app_theme.dart';
import 'package:devops_learning_app/features/module/screens/git_module_screen.dart';
import 'package:devops_learning_app/features/module/widgets/code_block_view.dart';
import 'package:devops_learning_app/features/module/widgets/module_header_card.dart';
import 'package:devops_learning_app/features/module/widgets/module_objectives_card.dart';
import 'package:devops_learning_app/features/module/widgets/subtopic_nav_bar.dart';
import 'package:devops_learning_app/features/module/widgets/subtopic_nav_footer.dart';
import 'package:devops_learning_app/features/pathway/data/progress_service.dart';
import 'package:devops_learning_app/models/animation_model.dart';
import 'package:devops_learning_app/models/curriculum_model.dart';
import 'package:devops_learning_app/models/user_model.dart';
import 'package:devops_learning_app/providers/auth_provider.dart';

import 'auth_provider_test.dart';

Widget _wrapModuleScreen({
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

  late List<CurriculumModule> realModules;
  late MockSecureStorageService storageService;
  late FakeApiClient fakeApi;
  late AuthProvider authProvider;

  setUpAll(() {
    final curriculumRaw = File('assets/data/git_curriculum.json').readAsStringSync();
    final List<dynamic> decodedCurriculum = json.decode(curriculumRaw) as List<dynamic>;
    realModules = decodedCurriculum
        .map((m) => CurriculumModule.fromJson(m as Map<String, dynamic>))
        .toList();

    final animRaw = File('assets/data/git_animations.json').readAsStringSync();
    final Map<String, dynamic> decodedAnim = json.decode(animRaw) as Map<String, dynamic>;
    final rawModules = decodedAnim['modules'] as List? ?? [];
    rawModules
        .map((m) => AnimationModule.fromJson(m as Map<String, dynamic>))
        .toList();
  });

  setUp(() async {
    storageService = MockSecureStorageService();
    fakeApi = FakeApiClient(storageService: storageService);
    fakeApi.mockUser = const UserModel(
      id: 'test_student_1',
      name: 'Test Student',
      email: 'student@example.com',
    );
    authProvider = AuthProvider(
      apiClient: fakeApi,
      storageService: storageService,
    );
    await authProvider.login(
      email: 'student@example.com',
      password: 'password123',
    );
    ProgressService().clearCache();
  });

  tearDown(() {
    ProgressService().clearCache();
  });

  group('Phase 4: Git Module Screen Full Web Parity Tests', () {
    test('1. Verified exactly seven modules loaded with correct properties', () {
      expect(realModules.length, equals(7));
      for (int i = 0; i < 7; i++) {
        expect(realModules[i].order, equals(i + 1));
        expect(realModules[i].id, equals('git-0${i + 1}'));
      }
    });

    testWidgets('1. All seven modules load dynamically using their IDs', (
      WidgetTester tester,
    ) async {
      for (int i = 0; i < 7; i++) {
        final mod = realModules[i];

        await tester.pumpWidget(
          _wrapModuleScreen(
            child: GitModuleScreen(
              moduleId: mod.id,
              initialModules: realModules,
            ),
            authProvider: authProvider,
          ),
        );
        await tester.pumpAndSettle();

        // Verify module stop badge and title render
        expect(find.text('Stop ${mod.order} of 7'), findsOneWidget);
        expect(find.text(mod.title), findsOneWidget);
        expect(find.byType(GitModuleScreen), findsOneWidget);
      }
    });

    testWidgets('2. Correct module title, summary, and objectives appear', (
      WidgetTester tester,
    ) async {
      final module1 = realModules[0];

      await tester.pumpWidget(
        _wrapModuleScreen(
          child: GitModuleScreen(
            moduleId: module1.id,
            initialModules: realModules,
          ),
          authProvider: authProvider,
        ),
      );
      await tester.pumpAndSettle();

      // Module header elements
      expect(find.byType(ModuleHeaderCard), findsOneWidget);
      expect(find.text(module1.title), findsOneWidget);
      expect(find.text(module1.summary), findsOneWidget);
      expect(find.text('${module1.estimatedMinutes} min read'), findsOneWidget);

      // Objectives card
      expect(find.byType(ModuleObjectivesCard), findsOneWidget);
      expect(find.text('Objectives'), findsOneWidget);
      for (final obj in module1.objectives) {
        expect(find.text(obj), findsOneWidget);
      }
    });

    testWidgets('3. Subtopics display in the correct curriculum order', (
      WidgetTester tester,
    ) async {
      final module1 = realModules[0];

      await tester.pumpWidget(
        _wrapModuleScreen(
          child: GitModuleScreen(
            moduleId: module1.id,
            initialModules: realModules,
          ),
          authProvider: authProvider,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SubtopicNavBar), findsOneWidget);
      expect(find.text('SUBTOPICS'), findsOneWidget);
      expect(find.text('1 of ${module1.sections.length}'), findsOneWidget);

      // Verify each section number is visible
      for (int i = 0; i < module1.sections.length; i++) {
        expect(find.text('${module1.sections[i].number}'), findsWidgets);
      }
    });

    testWidgets('4. Selecting a subtopic displays the correct educational content', (
      WidgetTester tester,
    ) async {
      final module1 = realModules[0];

      await tester.pumpWidget(
        _wrapModuleScreen(
          child: GitModuleScreen(
            moduleId: module1.id,
            initialModules: realModules,
          ),
          authProvider: authProvider,
        ),
      );
      await tester.pumpAndSettle();

      // Initially on subtopic 1: "1. Why Do We Need Version Control?"
      expect(find.text(module1.sections[0].title), findsOneWidget);
      expect(
        find.textContaining(RegExp('without version control', caseSensitive: false)),
        findsOneWidget,
      );

      // Tap on Subtopic 2: "2. Git vs GitHub"
      final subtopic2Chip = find.text('Git vs GitHub');
      expect(subtopic2Chip, findsOneWidget);
      await tester.ensureVisible(subtopic2Chip);
      await tester.tap(subtopic2Chip);
      await tester.pumpAndSettle();

      // Now subtopic 2 title and paragraphs are visible
      expect(find.text(module1.sections[1].title), findsOneWidget);
      expect(
        find.textContaining(RegExp('Git and GitHub are closely related', caseSensitive: false)),
        findsOneWidget,
      );
      expect(find.text('2 of ${module1.sections.length}'), findsOneWidget);
    });

    testWidgets('5. Previous and next subtopic navigation buttons work', (
      WidgetTester tester,
    ) async {
      final module1 = realModules[0];

      await tester.pumpWidget(
        _wrapModuleScreen(
          child: GitModuleScreen(
            moduleId: module1.id,
            initialModules: realModules,
          ),
          authProvider: authProvider,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SubtopicNavFooter), findsOneWidget);

      // On subtopic 1: "Prev" is disabled
      final prevBtn = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Prev'),
      );
      expect(prevBtn.onPressed, isNull);

      // Tap Next button
      final nextFinder = find.widgetWithText(TextButton, 'Next');
      await tester.ensureVisible(nextFinder);
      await tester.tap(nextFinder);
      await tester.pumpAndSettle();

      // Now on subtopic 2
      expect(find.text('Subtopic 2 of ${module1.sections.length}'), findsOneWidget);
      expect(find.text(module1.sections[1].title), findsOneWidget);

      // Tap Previous button
      final prevFinder = find.widgetWithText(TextButton, 'Prev');
      await tester.ensureVisible(prevFinder);
      await tester.tap(prevFinder);
      await tester.pumpAndSettle();

      // Back on subtopic 1
      expect(find.text('Subtopic 1 of ${module1.sections.length}'), findsOneWidget);
      expect(find.text(module1.sections[0].title), findsOneWidget);
    });

    testWidgets('6. Code blocks render with language badge, copy action, and scrollability', (
      WidgetTester tester,
    ) async {
      final module1 = realModules[0];

      // Jump directly to subtopic 3 (Install Git, which has codeSnippet "git --version")
      await tester.pumpWidget(
        _wrapModuleScreen(
          child: GitModuleScreen(
            moduleId: module1.id,
            initialModules: realModules,
            initialSubtopicIndex: 2, // 3rd section
          ),
          authProvider: authProvider,
        ),
      );
      await tester.pumpAndSettle();

      // Verify CodeBlockView is rendered
      expect(find.byType(CodeBlockView), findsOneWidget);
      expect(find.text('BASH'), findsOneWidget);
      expect(find.text('git --version'), findsOneWidget);
      expect(find.text('Copy'), findsOneWidget);

      // Tap Copy button
      final copyFinder = find.text('Copy');
      await tester.ensureVisible(copyFinder);
      await tester.tap(copyFinder);
      await tester.pump();
      expect(find.text('Copied!'), findsOneWidget);

      // Settle the 2-second revert timer
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('7. Long technical content scrolls smoothly without crashes', (
      WidgetTester tester,
    ) async {
      final module1 = realModules[0];

      await tester.pumpWidget(
        _wrapModuleScreen(
          child: GitModuleScreen(
            moduleId: module1.id,
            initialModules: realModules,
          ),
          authProvider: authProvider,
        ),
      );
      await tester.pumpAndSettle();

      final scrollFinder = find.byType(SingleChildScrollView).first;
      expect(scrollFinder, findsOneWidget);

      // Drag to scroll down
      await tester.drag(scrollFinder, const Offset(0, -400));
      await tester.pumpAndSettle();

      // Verify no exceptions were thrown during scrolling
      expect(tester.takeException(), isNull);
    });

    testWidgets('8. Module completion updates ProgressService and UI status', (
      WidgetTester tester,
    ) async {
      final module1 = realModules[0];
      final userId = authProvider.user!.id;

      expect(ProgressService().isModuleCompleted(userId, module1.id), isFalse);

      await tester.pumpWidget(
        _wrapModuleScreen(
          child: GitModuleScreen(
            moduleId: module1.id,
            initialModules: realModules,
          ),
          authProvider: authProvider,
        ),
      );
      await tester.pumpAndSettle();

      // Initially incomplete
      expect(find.text('Mark Stop as Completed'), findsOneWidget);
      expect(find.text('Done'), findsNothing);

      // Tap completion button
      final completeFinder = find.text('Mark Stop as Completed');
      await tester.ensureVisible(completeFinder);
      await tester.tap(completeFinder);
      await tester.pumpAndSettle();

      // Progress updated in service
      expect(ProgressService().isModuleCompleted(userId, module1.id), isTrue);

      // UI reflects completion
      expect(find.text('Completed (Click to Undo)'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
    });

    testWidgets('9. Existing progress is preserved across module views', (
      WidgetTester tester,
    ) async {
      final userId = authProvider.user!.id;
      // Pre-mark git-01 and git-03 as completed
      ProgressService().setCompletedModulesCache(userId, {'git-01', 'git-03'});

      await tester.pumpWidget(
        _wrapModuleScreen(
          child: GitModuleScreen(
            moduleId: 'git-01',
            initialModules: realModules,
            initialCompletedIds: {'git-01', 'git-03'},
          ),
          authProvider: authProvider,
        ),
      );
      await tester.pumpAndSettle();

      // git-01 shows as Done
      expect(find.text('Done'), findsOneWidget);
      expect(find.text('Completed (Click to Undo)'), findsOneWidget);

      // Verify git-03 remains preserved in ProgressService
      expect(ProgressService().isModuleCompleted(userId, 'git-03'), isTrue);
    });

    testWidgets('10. Small-screen mobile layout (320 x 640) renders without RenderFlex overflow', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final module4 = realModules[3]; // git-04 has complex branching sections and code snippets

      await tester.pumpWidget(
        _wrapModuleScreen(
          child: GitModuleScreen(
            moduleId: module4.id,
            initialModules: realModules,
          ),
          authProvider: authProvider,
          screenSize: const Size(320, 640),
        ),
      );
      await tester.pumpAndSettle();

      final error = tester.takeException();
      if (error is FlutterError) {
        for (final node in error.diagnostics) {
          debugPrint('NODE: ${node.toStringDeep()}');
        }
      }
      expect(error, isNull);
    });
  });
}
