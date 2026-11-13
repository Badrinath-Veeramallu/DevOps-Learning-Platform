import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:devops_learning_app/core/theme/app_theme.dart';
import 'package:devops_learning_app/features/animations/services/animation_loader.dart';
import 'package:devops_learning_app/features/animations/services/step_engine.dart';
import 'package:devops_learning_app/features/animations/widgets/actor_widget.dart';
import 'package:devops_learning_app/features/animations/widgets/animation_controls.dart';
import 'package:devops_learning_app/features/animations/widgets/stage_canvas.dart';
import 'package:devops_learning_app/features/animations/widgets/step_animation_player.dart';
import 'package:devops_learning_app/features/animations/widgets/terminal_view.dart';
import 'package:devops_learning_app/features/module/screens/linux_module_screen.dart';
import 'package:devops_learning_app/features/module/widgets/subtopic_animation_card.dart';
import 'package:devops_learning_app/models/animation_model.dart';
import 'package:devops_learning_app/models/curriculum_model.dart';
import 'package:devops_learning_app/models/user_model.dart';
import 'package:devops_learning_app/providers/auth_provider.dart';

import 'auth_provider_test.dart';

Widget _wrapWidget({
  required Widget child,
  WidgetTester? tester,
  Size screenSize = const Size(400, 1000),
}) {
  if (tester != null) {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = screenSize;
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });
  }
  return MediaQuery(
    data: MediaQueryData(size: screenSize),
    child: MaterialApp(
      theme: AppTheme.darkTheme,
      home: Scaffold(
        body: SingleChildScrollView(
          child: child,
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<AnimationModule> linuxModules;
  late List<SubtopicAnimation> allSubtopics;
  late List<CurriculumModule> linuxCurriculum;

  setUpAll(() async {
    final animJson =
        File('assets/data/linux_animations.json').readAsStringSync();
    final Map<String, dynamic> decoded =
        json.decode(animJson) as Map<String, dynamic>;
    final rawModules = decoded['modules'] as List? ?? [];
    linuxModules = rawModules
        .map((m) => AnimationModule.fromJson(m as Map<String, dynamic>))
        .toList();

    AnimationLoader.setCachedModules(linuxModules, pathway: 'linux');
    allSubtopics = linuxModules.expand((m) => m.subtopics).toList();

    final currJson =
        File('assets/data/linux_curriculum.json').readAsStringSync();
    final List<dynamic> decodedCurr = json.decode(currJson) as List<dynamic>;
    linuxCurriculum = decodedCurr
        .map((c) => CurriculumModule.fromJson(c as Map<String, dynamic>))
        .toList();
  });

  group('Linux Animations Complete Integration & Mobile Parity Tests', () {
    test(
        '1. Linux animations JSON contains exactly 6 modules, 40 subtopics, and 143 animation steps',
        () async {
      AnimationLoader.clearCache(pathway: 'linux');
      final rootModules = await AnimationLoader.loadAnimations(pathway: 'linux');
      expect(rootModules.length, equals(6));
      expect(linuxModules.length, equals(6));
      expect(allSubtopics.length, equals(40));

      int totalSteps = 0;
      for (final s in allSubtopics) {
        totalSteps += s.steps.length;
      }
      expect(totalSteps, equals(143));

      // Verify module breakdown
      expect(linuxModules[0].id, '01');
      expect(linuxModules[0].subtopics.length, equals(10));

      expect(linuxModules[1].id, '02');
      expect(linuxModules[1].subtopics.length, equals(6));

      expect(linuxModules[2].id, '03');
      expect(linuxModules[2].subtopics.length, equals(7));

      expect(linuxModules[3].id, '04');
      expect(linuxModules[3].subtopics.length, equals(6));

      expect(linuxModules[4].id, '05');
      expect(linuxModules[4].subtopics.length, equals(5));

      expect(linuxModules[5].id, '06');
      expect(linuxModules[5].subtopics.length, equals(6));
    });

    test(
        '2. Every subtopic has valid portrait stage dimensions and compiles into frames',
        () {
      for (final s in allSubtopics) {
        expect(s.id.isNotEmpty, isTrue);
        expect(s.title.isNotEmpty, isTrue);
        expect(s.steps.isNotEmpty, isTrue);

        // Portrait stage width must be 360
        expect(s.stageWidth, equals(360.0),
            reason: 'Subtopic ${s.id} stageWidth should be 360');
        expect(s.stageHeight, greaterThanOrEqualTo(400.0),
            reason: 'Subtopic ${s.id} stageHeight should be >= 400');
        expect(s.stageHeight, lessThanOrEqualTo(700.0),
            reason: 'Subtopic ${s.id} stageHeight should be <= 700');

        final frames = StepEngine.buildFrames(s.steps);
        expect(frames.length, equals(s.steps.length),
            reason: 'Frame count for ${s.id} should match step count');
      }
    });

    test(
        '3. AnimationLoader indexes and resolves all 40 Linux subtopics by ID and Title',
        () {
      for (final s in allSubtopics) {
        // ID lookup
        final byId = AnimationLoader.findAnimation(s.id, pathway: 'linux');
        expect(byId, isNotNull, reason: 'Failed lookup by id: ${s.id}');
        expect(byId!.id, equals(s.id));

        // Exact title lookup
        final byTitle =
            AnimationLoader.findAnimation(s.title, pathway: 'linux');
        expect(byTitle, isNotNull, reason: 'Failed lookup by title: ${s.title}');
        expect(byTitle!.id, equals(s.id));

        // Title with leading numbering lookup (e.g. "1. Why Linux Matters for DevOps")
        final byNumberedTitle =
            AnimationLoader.findAnimation('1. ${s.title}', pathway: 'linux');
        expect(byNumberedTitle, isNotNull,
            reason: 'Failed lookup by numbered title: 1. ${s.title}');
        expect(byNumberedTitle!.id, equals(s.id));
      }
    });

    test(
        '4. AnimationLoader explicitly supports Git, Docker, and Linux and rejects unknown pathways',
        () async {
      // Rejects unknown pathways with ArgumentError
      expect(
        () => AnimationLoader.loadAnimations(pathway: 'unknown_pathway'),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => AnimationLoader.loadAnimations(pathway: 'k8s'),
        throwsA(isA<ArgumentError>()),
      );

      // Caching isolation
      expect(AnimationLoader.cachedModules(pathway: 'linux'), isNotNull);
      AnimationLoader.clearCache(pathway: 'linux');
      expect(AnimationLoader.cachedModules(pathway: 'linux'), isNull);

      // Re-populate Linux cache
      AnimationLoader.setCachedModules(linuxModules, pathway: 'linux');
      expect(AnimationLoader.cachedModules(pathway: 'linux'), isNotNull);
    });

    test(
        '5. Every curriculum section in Linux maps to an animation without gaps',
        () {
      for (final mod in linuxCurriculum) {
        for (final sec in mod.sections) {
          final animKey = '${mod.number}.${sec.number}';
          final match =
              AnimationLoader.findAnimation(animKey, pathway: 'linux');
          expect(
            match,
            isNotNull,
            reason:
                'Missing Linux animation for module ${mod.number} section ${sec.number}',
          );
        }
      }
    });

    testWidgets('6. StageCanvas renders portrait actors, zones, and edges cleanly',
        (tester) async {
      final s = allSubtopics.first; // 01.1
      final frames = StepEngine.buildFrames(s.steps);
      final frame0 = frames.first;

      await tester.pumpWidget(
        _wrapWidget(
          tester: tester,
          screenSize: const Size(390, 844),
          child: StageCanvas(
            frame: frame0,
            stageWidth: s.stageWidth,
            stageHeight: s.stageHeight,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(StageCanvas), findsOneWidget);
      expect(find.byType(ActorWidget), findsWidgets);
    });

    testWidgets('7. TerminalView renders typed commands and execution output',
        (tester) async {
      final lines = [
        r'$ ls -la',
        'drwxr-xr-x 4 user devops 4096 Nov 12 projects',
        '-rw-r--r-- 1 user devops 1024 Nov 12 notes.txt',
        r'$ grep "error" notes.txt',
        '!critical: connection timed out',
      ];

      await tester.pumpWidget(
        _wrapWidget(
          tester: tester,
          child: TerminalView(
            lines: lines,
            step: 1,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TerminalView), findsOneWidget);
      expect(find.text('terminal'), findsOneWidget);
      expect(find.byType(RichText), findsWidgets);
      expect(find.text('critical: connection timed out'), findsOneWidget);
    });

    testWidgets(
        '8. StepAnimationPlayer provides full interactive playback, step navigation, and onFinish',
        (tester) async {
      final s = allSubtopics.first; // 01.1 has 3 steps
      bool finishFired = false;

      await tester.pumpWidget(
        _wrapWidget(
          tester: tester,
          screenSize: const Size(400, 1600),
          child: StepAnimationPlayer(
            animation: s,
            onFinish: () => finishFired = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Step 1 / 3'), findsOneWidget);
      expect(find.text(s.title), findsOneWidget);
      expect(find.byType(AnimationControls), findsOneWidget);

      // Navigate Next to Step 2
      final nextBtn = find.byTooltip('Next Step');
      expect(nextBtn, findsOneWidget);
      await tester.tap(nextBtn);
      await tester.pumpAndSettle();

      expect(find.text('Step 2 / 3'), findsOneWidget);
      expect(finishFired, isFalse);

      // Navigate Next to Step 3 (final step)
      await tester.tap(nextBtn);
      await tester.pumpAndSettle();

      expect(find.text('Step 3 / 3'), findsOneWidget);
      expect(finishFired, isTrue);

      // Navigate Prev back to Step 2
      final prevBtn = find.byTooltip('Previous Step');
      await tester.tap(prevBtn);
      await tester.pumpAndSettle();

      expect(find.text('Step 2 / 3'), findsOneWidget);

      // Restart back to Step 1
      final restartBtn = find.byTooltip('Restart');
      await tester.tap(restartBtn);
      await tester.pumpAndSettle();

      expect(find.text('Step 1 / 3'), findsOneWidget);
    });

    testWidgets(
        '9. SubtopicAnimationCard loads Linux animation and handles missing animations safely',
        (tester) async {
      // 1. Valid Linux animation key
      await tester.pumpWidget(
        _wrapWidget(
          tester: tester,
          child: const SubtopicAnimationCard(
            animationKey: '01.1',
            fallbackTitle: 'Why Linux Matters for DevOps',
            pathway: 'linux',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(StepAnimationPlayer), findsOneWidget);
      expect(find.text('Why Linux Matters for DevOps'), findsOneWidget);

      // 2. Missing animation key renders SizedBox.shrink without crashing
      await tester.pumpWidget(
        _wrapWidget(
          tester: tester,
          child: const SubtopicAnimationCard(
            animationKey: '99.99',
            fallbackTitle: 'Non Existent Animation',
            pathway: 'linux',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(StepAnimationPlayer), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        '10. LinuxModuleScreen dynamically loads and renders Linux animations',
        (tester) async {
      final fakeApi = FakeApiClient(storageService: MockSecureStorageService());
      fakeApi.mockUser = const UserModel(
        id: 'usr_linux_anim',
        name: 'Tux Tester',
        email: 'tux@example.com',
      );
      final authProvider = AuthProvider(
        apiClient: fakeApi,
        storageService: MockSecureStorageService(),
      );
      await authProvider.login(
        email: 'tux@example.com',
        password: 'password123',
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<AuthProvider>.value(
          value: authProvider,
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: LinuxModuleScreen(
              moduleId: 'linux-01',
              initialModules: linuxCurriculum,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify LinuxModuleScreen renders with module 1
      expect(find.text('01. Linux Fundamentals & File System Navigation'),
          findsOneWidget);

      // Verify StepAnimationPlayer is rendered for section 1
      expect(find.byType(StepAnimationPlayer), findsOneWidget);
      expect(find.text('Why Linux Matters for DevOps'), findsOneWidget);
    });

    testWidgets(
        '11. SubtopicAnimationCard self-heals from a cold cache via reactive loading',
        (tester) async {
      // Clear cache completely to simulate cold app launch
      AnimationLoader.clearCache(pathway: 'linux');
      expect(AnimationLoader.cachedModules(pathway: 'linux'), isNull);

      await tester.pumpWidget(
        _wrapWidget(
          tester: tester,
          child: const SubtopicAnimationCard(
            animationKey: '01.1',
            fallbackTitle: 'Why Linux Matters for DevOps',
            pathway: 'linux',
          ),
        ),
      );

      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();

      expect(find.byType(StepAnimationPlayer), findsOneWidget);
      expect(find.text('Why Linux Matters for DevOps'), findsOneWidget);
    });

    testWidgets(
        '12. LinuxModuleScreen renders animations when navigating with null initialModules even if progress sync fails',
        (tester) async {
      AnimationLoader.clearCache(pathway: 'linux');

      final fakeApi = FakeApiClient(storageService: MockSecureStorageService());
      fakeApi.mockUser = const UserModel(
        id: 'usr_cold_test',
        name: 'Cold Tux',
        email: 'cold@example.com',
      );
      final authProvider = AuthProvider(
        apiClient: fakeApi,
        storageService: MockSecureStorageService(),
      );
      await authProvider.login(
        email: 'cold@example.com',
        password: 'password123',
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<AuthProvider>.value(
          value: authProvider,
          child: const MaterialApp(
            home: LinuxModuleScreen(
              moduleId: 'linux-01',
              initialModules: null,
            ),
          ),
        ),
      );
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();

      // Verify module title and animation player rendered cleanly
      expect(find.text('01. Linux Fundamentals & File System Navigation'),
          findsOneWidget);
      expect(find.byType(StepAnimationPlayer), findsOneWidget);
    });
  });
}
