import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:devops_learning_app/core/theme/app_theme.dart';
import 'package:devops_learning_app/features/animations/services/animation_loader.dart';
import 'package:devops_learning_app/features/animations/services/step_engine.dart';
import 'package:devops_learning_app/features/animations/widgets/actor_widget.dart';
import 'package:devops_learning_app/features/animations/widgets/animation_controls.dart';
import 'package:devops_learning_app/features/animations/widgets/stage_canvas.dart';
import 'package:devops_learning_app/features/animations/widgets/step_animation_player.dart';
import 'package:devops_learning_app/features/animations/widgets/terminal_view.dart';
import 'package:devops_learning_app/features/module/widgets/subtopic_animation_card.dart';
import 'package:devops_learning_app/models/animation_model.dart';
import 'package:devops_learning_app/models/curriculum_model.dart';

Widget _wrapWidget({
  required Widget child,
  Size screenSize = const Size(800, 1200),
}) {
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

  late List<AnimationModule> allAnimationModules;
  late List<SubtopicAnimation> allSubtopics;
  late List<CurriculumModule> realCurriculum;

  setUpAll(() {
    final animJson = File('assets/data/git_animations.json').readAsStringSync();
    final Map<String, dynamic> decoded = json.decode(animJson) as Map<String, dynamic>;
    final rawModules = decoded['modules'] as List? ?? [];
    allAnimationModules = rawModules
        .map((m) => AnimationModule.fromJson(m as Map<String, dynamic>))
        .toList();

    AnimationLoader.setCachedModules(allAnimationModules);

    allSubtopics = allAnimationModules.expand((m) => m.subtopics).toList();

    final currJson = File('assets/data/git_curriculum.json').readAsStringSync();
    final List<dynamic> decodedCurr = json.decode(currJson) as List<dynamic>;
    realCurriculum = decodedCurr
        .map((c) => CurriculumModule.fromJson(c as Map<String, dynamic>))
        .toList();
  });

  group('Phase 5: Interactive Git Animations Full Web Parity Tests', () {
    test('1. Verified all 43 animation definitions load and compile into valid frames', () {
      expect(allSubtopics.length, equals(43));

      for (final subtopic in allSubtopics) {
        expect(subtopic.id.isNotEmpty, isTrue);
        expect(subtopic.title.isNotEmpty, isTrue);
        expect(subtopic.steps.isNotEmpty, isTrue);

        final frames = StepEngine.buildFrames(subtopic.steps);
        expect(frames.length, equals(subtopic.steps.length));

        for (final frame in frames) {
          expect(frame.actors, isNotNull);
          expect(frame.edges, isNotNull);
          expect(frame.term, isNotNull);
        }
      }
    });

    test('2. Animation-to-subtopic mappings are 100% correct across all curriculum modules', () {
      for (final mod in realCurriculum) {
        for (final sec in mod.sections) {
          final animKey = '${mod.number}.${sec.number}';
          final match = allSubtopics.where((s) => s.id == animKey).firstOrNull;
          expect(
            match,
            isNotNull,
            reason: 'Missing animation for module ${mod.number} subtopic ${sec.number}',
          );
        }
      }
    });

    testWidgets('3. Initial animation states render correctly with stage, actors, and badges', (
      WidgetTester tester,
    ) async {
      final anim = allSubtopics.firstWhere((s) => s.id == '01.1');

      await tester.pumpWidget(
        _wrapWidget(
          child: StepAnimationPlayer(animation: anim),
        ),
      );
      await tester.pumpAndSettle();

      // Header title and count
      expect(find.text(anim.title), findsOneWidget);
      expect(find.text('Step 1 / ${anim.steps.length}'), findsOneWidget);
      expect(find.text('ANIMATION'), findsOneWidget);

      // Stage canvas and actors
      expect(find.byType(StageCanvas), findsOneWidget);
      expect(find.byType(ActorWidget), findsWidgets);

      // Say caption
      expect(find.text(anim.steps.first.say!), findsOneWidget);

      // Playback controls
      expect(find.byType(AnimationControls), findsOneWidget);
      expect(find.text('▶ Play'), findsOneWidget);
    });

    testWidgets('4. Previous and Next controls navigate visual steps and update counters', (
      WidgetTester tester,
    ) async {
      final anim = allSubtopics.firstWhere((s) => s.id == '01.1');

      await tester.pumpWidget(
        _wrapWidget(
          child: StepAnimationPlayer(animation: anim),
        ),
      );
      await tester.pumpAndSettle();

      // On step 1: counter says 1 / 4
      expect(find.text('Step 1 / ${anim.steps.length}'), findsOneWidget);

      // Tap Next button ›
      await tester.tap(find.text('›'));
      await tester.pumpAndSettle();

      // Step advanced to 2
      expect(find.text('Step 2 / ${anim.steps.length}'), findsOneWidget);
      expect(find.text(anim.steps[1].say!), findsOneWidget);

      // Tap Previous button ‹
      await tester.tap(find.text('‹'));
      await tester.pumpAndSettle();

      // Step restored to 1
      expect(find.text('Step 1 / ${anim.steps.length}'), findsOneWidget);
      expect(find.text(anim.steps[0].say!), findsOneWidget);
    });

    testWidgets('5. Play and Pause controls toggle playback state and update button labels', (
      WidgetTester tester,
    ) async {
      final anim = allSubtopics.firstWhere((s) => s.id == '01.1');

      await tester.pumpWidget(
        _wrapWidget(
          child: StepAnimationPlayer(
            animation: anim,
            stepMs: 500, // Accelerated for testing
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('▶ Play'), findsOneWidget);

      // Start playback
      await tester.tap(find.text('▶ Play'));
      await tester.pump();
      expect(find.text('❚❚ Pause'), findsOneWidget);

      // Pause playback
      await tester.tap(find.text('❚❚ Pause'));
      await tester.pump();
      expect(find.text('▶ Play'), findsOneWidget);
    });

    testWidgets('6. Restart restores the initial state from any step', (
      WidgetTester tester,
    ) async {
      final anim = allSubtopics.firstWhere((s) => s.id == '01.1');

      await tester.pumpWidget(
        _wrapWidget(
          child: StepAnimationPlayer(animation: anim),
        ),
      );
      await tester.pumpAndSettle();

      // Advance to step 3
      await tester.tap(find.text('›'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('›'));
      await tester.pumpAndSettle();
      expect(find.text('Step 3 / ${anim.steps.length}'), findsOneWidget);

      // Tap Restart ↺
      await tester.tap(find.text('↺'));
      await tester.pumpAndSettle();

      // Restores to step 1
      expect(find.text('Step 1 / ${anim.steps.length}'), findsOneWidget);
      expect(find.text(anim.steps[0].say!), findsOneWidget);
    });

    testWidgets('7. Step explanations update with each step progression', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      addTearDown(tester.view.resetPhysicalSize);

      final anim = allSubtopics.firstWhere((s) => s.id == '02.1');

      await tester.pumpWidget(
        _wrapWidget(
          child: StepAnimationPlayer(animation: anim),
        ),
      );
      await tester.pumpAndSettle();

      for (int i = 0; i < anim.steps.length; i++) {
        expect(find.text('Step ${i + 1} / ${anim.steps.length}'), findsOneWidget);
        if (anim.steps[i].say != null) {
          expect(find.text(anim.steps[i].say!), findsOneWidget);
        }
        if (i < anim.steps.length - 1) {
          final nextBtn = find.text('›');
          await tester.ensureVisible(nextBtn);
          await tester.tap(nextBtn);
          await tester.pumpAndSettle();
        }
      }
    });

    testWidgets('8. Final-step handling prevents out-of-bounds navigation and shows Replay', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      addTearDown(tester.view.resetPhysicalSize);

      final anim = allSubtopics.firstWhere((s) => s.id == '01.1');

      await tester.pumpWidget(
        _wrapWidget(
          child: StepAnimationPlayer(animation: anim),
        ),
      );
      await tester.pumpAndSettle();

      // Advance to final step
      for (int i = 0; i < anim.steps.length - 1; i++) {
        final nextBtn = find.text('›');
        await tester.ensureVisible(nextBtn);
        await tester.tap(nextBtn);
        await tester.pumpAndSettle();
      }

      expect(find.text('Step ${anim.steps.length} / ${anim.steps.length}'), findsOneWidget);
      expect(find.text('↻ Replay'), findsOneWidget);

      // Tap Replay button to start over
      final replayBtn = find.text('↻ Replay');
      await tester.ensureVisible(replayBtn);
      await tester.tap(replayBtn);
      await tester.pump();

      // Restored to step 1
      expect(find.text('Step 1 / ${anim.steps.length}'), findsOneWidget);
    });

    testWidgets('9. Single-step animations render cleanly without playback errors', (
      WidgetTester tester,
    ) async {
      const singleStepAnim = SubtopicAnimation(
        id: '99.1',
        title: 'Single Step Test Animation',
        steps: [
          AnimationStep(
            say: 'One and only step description',
            actors: {
              'box1': {'k': 'box', 'x': 50.0, 'y': 50.0, 'text': 'Git Architecture'},
            },
          ),
        ],
      );

      await tester.pumpWidget(
        _wrapWidget(
          child: const StepAnimationPlayer(animation: singleStepAnim),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Step 1 / 1'), findsOneWidget);
      expect(find.text('One and only step description'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('10. Switching between subtopics resets player state cleanly', (
      WidgetTester tester,
    ) async {
      final anim1 = allSubtopics.firstWhere((s) => s.id == '01.1');
      final anim2 = allSubtopics.firstWhere((s) => s.id == '01.2');

      SubtopicAnimation currentAnim = anim1;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return _wrapWidget(
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: () => setState(() => currentAnim = anim2),
                    child: const Text('Switch Animation'),
                  ),
                  StepAnimationPlayer(
                    key: ValueKey(currentAnim.id),
                    animation: currentAnim,
                  ),
                ],
              ),
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      // Advance animation 1 to step 2
      await tester.tap(find.text('›'));
      await tester.pumpAndSettle();
      expect(find.text('Step 2 / ${anim1.steps.length}'), findsOneWidget);

      // Switch to animation 2
      await tester.tap(find.text('Switch Animation'));
      await tester.pumpAndSettle();

      // Animation 2 starts fresh at Step 1
      expect(find.text(anim2.title), findsOneWidget);
      expect(find.text('Step 1 / ${anim2.steps.length}'), findsOneWidget);
    });

    testWidgets('11. All supported animation operations and actor kinds render (files, commits, zones, code, terminal)', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      addTearDown(tester.view.resetPhysicalSize);

      // 01.5 has code, zone, box, and terminal commands on step 0
      final animTerm = allSubtopics.firstWhere((s) => s.id == '01.5');

      await tester.pumpWidget(
        _wrapWidget(
          child: StepAnimationPlayer(animation: animTerm),
        ),
      );
      await tester.pumpAndSettle();

      // Stage canvas, actors, and terminal
      expect(find.byType(StageCanvas), findsOneWidget);
      expect(find.byType(ActorWidget), findsWidgets);
      expect(find.byType(TerminalView), findsWidgets);

      // Also verify commits and branches in 02.2
      final animCommits = allSubtopics.firstWhere((s) => s.id == '02.2');
      await tester.pumpWidget(
        _wrapWidget(
          child: StepAnimationPlayer(
            key: const ValueKey('02.2'),
            animation: animCommits,
          ),
        ),
      );
      await tester.pumpAndSettle();

      for (int i = 0; i < animCommits.steps.length - 1; i++) {
        final nextBtn = find.text('›');
        await tester.ensureVisible(nextBtn);
        await tester.tap(nextBtn);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('12. Terminal commands and code snippets with long labels do not overflow', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      addTearDown(tester.view.resetPhysicalSize);

      // 04.5 has merge conflict markers, code diff lines, and commands
      final animConflict = allSubtopics.firstWhere((s) => s.id == '04.5');

      await tester.pumpWidget(
        _wrapWidget(
          child: StepAnimationPlayer(animation: animConflict),
        ),
      );
      await tester.pumpAndSettle();

      for (int i = 0; i < animConflict.steps.length - 1; i++) {
        final nextBtn = find.text('›');
        await tester.ensureVisible(nextBtn);
        await tester.tap(nextBtn);
        await tester.pumpAndSettle();
      }

      expect(tester.takeException(), isNull);
    });

    testWidgets('13. Small-screen layout (320 x 640) renders player without RenderFlex overflow', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final anim = allSubtopics.firstWhere((s) => s.id == '04.1');

      await tester.pumpWidget(
        _wrapWidget(
          child: StepAnimationPlayer(animation: anim),
          screenSize: const Size(320, 640),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(StepAnimationPlayer), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('14. Completion telemetry fires exactly once when final step is reached', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      addTearDown(tester.view.resetPhysicalSize);

      final anim = allSubtopics.firstWhere((s) => s.id == '01.1');
      int completionCount = 0;

      await tester.pumpWidget(
        _wrapWidget(
          child: StepAnimationPlayer(
            animation: anim,
            onFinish: () => completionCount++,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(completionCount, equals(0));

      final nextBtn = find.text('›');
      final prevBtn = find.text('‹');

      // Navigate to final step
      for (int i = 0; i < anim.steps.length - 1; i++) {
        await tester.ensureVisible(nextBtn);
        await tester.tap(nextBtn);
        await tester.pumpAndSettle();
      }

      // Fired exactly once upon reaching final step
      expect(completionCount, equals(1));

      // Stepping back and forth does not re-trigger completion repeatedly
      await tester.ensureVisible(prevBtn);
      await tester.tap(prevBtn);
      await tester.pumpAndSettle();
      expect(completionCount, equals(1));

      await tester.ensureVisible(nextBtn);
      await tester.tap(nextBtn);
      await tester.pumpAndSettle();
      expect(completionCount, equals(1));
    });

    testWidgets('15. SubtopicAnimationCard embeds StepAnimationPlayer seamlessly', (
      WidgetTester tester,
    ) async {
      AnimationLoader.setCachedModules(allAnimationModules);

      // Test SubtopicAnimationCard
      await tester.pumpWidget(
        _wrapWidget(
          child: const SubtopicAnimationCard(
            animationKey: '01.1',
            fallbackTitle: 'Why Do We Need Version Control?',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Embeds the interactive StepAnimationPlayer
      expect(find.byType(StepAnimationPlayer), findsOneWidget);
      expect(find.byType(StageCanvas), findsOneWidget);
      expect(find.text('ANIMATION'), findsOneWidget);
    });
  });
}
