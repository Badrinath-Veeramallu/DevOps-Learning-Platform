import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:devops_learning_app/core/theme/app_theme.dart';
import 'package:devops_learning_app/features/animations/services/animation_loader.dart';
import 'package:devops_learning_app/features/animations/widgets/step_animation_player.dart';
import 'package:devops_learning_app/features/dashboard/widgets/learning_streak_pill.dart';
import 'package:devops_learning_app/features/module/widgets/subtopic_animation_card.dart';
import 'package:devops_learning_app/models/animation_model.dart';
import 'package:devops_learning_app/models/streak_model.dart';

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

  late List<AnimationModule> cicdDesktopModules;
  late List<AnimationModule> cicdMobileModules;
  late List<SubtopicAnimation> desktopSubtopics;
  late List<SubtopicAnimation> mobileSubtopics;

  setUpAll(() {
    final desktopJson =
        File('assets/data/cicd_animations.json').readAsStringSync();
    final Map<String, dynamic> decodedDesktop =
        json.decode(desktopJson) as Map<String, dynamic>;
    final rawDesktop = decodedDesktop['modules'] as List? ?? [];
    cicdDesktopModules = rawDesktop
        .map((m) => AnimationModule.fromJson(m as Map<String, dynamic>))
        .toList();
    desktopSubtopics = cicdDesktopModules.expand((m) => m.subtopics).toList();

    final mobileJson =
        File('assets/data/cicd_animations.mobile.json').readAsStringSync();
    final Map<String, dynamic> decodedMobile =
        json.decode(mobileJson) as Map<String, dynamic>;
    final rawMobile = decodedMobile['modules'] as List? ?? [];
    cicdMobileModules = rawMobile
        .map((m) => AnimationModule.fromJson(m as Map<String, dynamic>))
        .toList();
    mobileSubtopics = cicdMobileModules.expand((m) => m.subtopics).toList();
  });

  setUp(() {
    AnimationLoader.clearCache(pathway: 'cicd');
    AnimationLoader.setCachedModules(cicdDesktopModules, pathway: 'cicd', isMobile: false);
    AnimationLoader.setCachedModules(cicdMobileModules, pathway: 'cicd', isMobile: true);
  });

  tearDown(() {
    AnimationLoader.clearCache(pathway: 'cicd');
  });

  group('CI/CD Animation Data Package Integrity', () {
    test('1. Desktop animations package contains 7 modules, 46 subtopics, 173 steps', () {
      expect(cicdDesktopModules.length, 7);
      expect(desktopSubtopics.length, 46);

      final totalSteps = desktopSubtopics.fold<int>(
        0,
        (sum, s) => sum + s.steps.length,
      );
      expect(totalSteps, 173);

      for (final s in desktopSubtopics) {
        expect(s.stageWidth, 1000);
        expect(s.stageHeight, 400);
        expect(s.steps, isNotEmpty);
      }
    });

    test('2. Mobile animations package contains 7 modules, 46 subtopics, 173 steps with portrait stage', () {
      expect(cicdMobileModules.length, 7);
      expect(mobileSubtopics.length, 46);

      final totalSteps = mobileSubtopics.fold<int>(
        0,
        (sum, s) => sum + s.steps.length,
      );
      expect(totalSteps, 173);

      for (final s in mobileSubtopics) {
        expect(s.stageWidth, 360);
        expect(s.stageHeight, anyOf(480, 560, 640));
        expect(s.steps, isNotEmpty);
      }
    });

    test('3. Subtopic ID parity between desktop and mobile animations', () {
      final desktopIds = desktopSubtopics.map((s) => s.id).toList();
      final mobileIds = mobileSubtopics.map((s) => s.id).toList();
      expect(desktopIds, equals(mobileIds));
    });
  });

  group('AnimationLoader CI/CD Support & Lookup', () {
    test('4. AnimationLoader resolves all 46 CI/CD subtopics on desktop and mobile', () {
      for (final s in desktopSubtopics) {
        final desktopAnim = AnimationLoader.findAnimation(
          s.id,
          pathway: 'cicd',
          isMobile: false,
        );
        expect(desktopAnim, isNotNull, reason: 'Desktop anim for ${s.id} should not be null');
        expect(desktopAnim!.id, s.id);
        expect(desktopAnim.stageWidth, 1000);

        final mobileAnim = AnimationLoader.findAnimation(
          s.id,
          pathway: 'cicd',
          isMobile: true,
        );
        expect(mobileAnim, isNotNull, reason: 'Mobile anim for ${s.id} should not be null');
        expect(mobileAnim!.id, s.id);
        expect(mobileAnim.stageWidth, 360);
      }
    });

    test('5. AnimationLoader supports title and unpadded ID lookups for CI/CD', () {
      final byUnpadded = AnimationLoader.findAnimation('1.1', pathway: 'cicd', isMobile: false);
      expect(byUnpadded, isNotNull);
      expect(byUnpadded!.id, '01.1');

      final first = desktopSubtopics.first;
      final byTitle = AnimationLoader.findAnimation(first.title, pathway: 'cicd', isMobile: false);
      expect(byTitle, isNotNull);
      expect(byTitle!.id, first.id);
    });
  });

  group('SubtopicAnimationCard CI/CD Integration', () {
    testWidgets('6. SubtopicAnimationCard renders StepAnimationPlayer for CI/CD on mobile', (tester) async {
      await tester.pumpWidget(
        _wrapWidget(
          tester: tester,
          screenSize: const Size(400, 900),
          child: const SubtopicAnimationCard(
            animationKey: '01.1',
            fallbackTitle: 'Introduction to CI/CD',
            pathway: 'cicd',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(StepAnimationPlayer), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('7. SubtopicAnimationCard renders StepAnimationPlayer for CI/CD on desktop', (tester) async {
      await tester.pumpWidget(
        _wrapWidget(
          tester: tester,
          screenSize: const Size(1024, 800),
          child: const SubtopicAnimationCard(
            animationKey: '01.1',
            fallbackTitle: 'Introduction to CI/CD',
            pathway: 'cicd',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(StepAnimationPlayer), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('8. SubtopicAnimationCard returns SizedBox.shrink for unknown animation', (tester) async {
      await tester.pumpWidget(
        _wrapWidget(
          tester: tester,
          child: const SubtopicAnimationCard(
            animationKey: '99.99',
            fallbackTitle: 'Non Existent Subtopic',
            pathway: 'cicd',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(StepAnimationPlayer), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('LearningStreakPill Palette Tests', () {
    testWidgets('9. Active streak renders with approved Burgundy palette', (tester) async {
      const activeStreak = StreakModel(
        currentStreak: 5,
        longestStreak: 10,
        isActiveToday: false,
        hasActivityYesterday: true,
      );

      await tester.pumpWidget(
        _wrapWidget(
          tester: tester,
          child: const LearningStreakPill(streak: activeStreak),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('5'), findsOneWidget);
      expect(find.text('streak'), findsOneWidget);

      final containerFinder = find.byType(Container).first;
      final container = tester.widget<Container>(containerFinder);
      final decoration = container.decoration as BoxDecoration;

      // Background: #FCF7F8 (0xFFFCF7F8)
      expect(decoration.color, const Color(0xFFFCF7F8));
      // Border: #EAD9DC (0xFFEAD9DC)
      final border = decoration.border as Border;
      expect(border.top.color, const Color(0xFFEAD9DC));

      // Lucide Flame Icon: #542B32 (0xFF542B32)
      final iconFinder = find.byType(LucideFlameIcon);
      expect(iconFinder, findsOneWidget);
      final flameIcon = tester.widget<LucideFlameIcon>(iconFinder);
      expect(flameIcon.color, const Color(0xFF542B32));

      // Text: #3B1F24 (0xFF3B1F24)
      final textWidget = tester.widget<Text>(find.text('5'));
      expect(textWidget.style?.color, const Color(0xFF3B1F24));
      expect(textWidget.style?.fontWeight, FontWeight.w700);

      final labelWidget = tester.widget<Text>(find.text('streak'));
      expect(labelWidget.style?.color, const Color(0xFF3B1F24));
      expect(labelWidget.style?.fontWeight, FontWeight.w500);
    });

    testWidgets('10. Inactive streak renders with approved Burgundy palette', (tester) async {
      const inactiveStreak = StreakModel(
        currentStreak: 0,
        longestStreak: 0,
        isActiveToday: false,
        hasActivityYesterday: false,
      );

      await tester.pumpWidget(
        _wrapWidget(
          tester: tester,
          child: const LearningStreakPill(streak: inactiveStreak),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('0'), findsOneWidget);
      expect(find.text('streak'), findsOneWidget);

      final containerFinder = find.byType(Container).first;
      final container = tester.widget<Container>(containerFinder);
      final decoration = container.decoration as BoxDecoration;

      expect(decoration.color, const Color(0xFFFCF7F8));
      final border = decoration.border as Border;
      expect(border.top.color, const Color(0xFFEAD9DC));

      final iconFinder = find.byType(LucideFlameIcon);
      expect(iconFinder, findsOneWidget);
      final flameIcon = tester.widget<LucideFlameIcon>(iconFinder);
      expect(flameIcon.color, const Color(0xFF542B32));

      final textWidget = tester.widget<Text>(find.text('0'));
      expect(textWidget.style?.color, const Color(0xFF3B1F24));
    });
  });
}

