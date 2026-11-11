import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:devops_learning_app/core/theme/app_colors.dart';
import 'package:devops_learning_app/core/theme/app_theme.dart';
import 'package:devops_learning_app/core/widgets/app_button.dart';
import 'package:devops_learning_app/core/widgets/cyber_background.dart';
import 'package:devops_learning_app/core/widgets/status_badge.dart';
import 'package:devops_learning_app/features/dashboard/widgets/level_badge.dart';
import 'package:devops_learning_app/features/pathway/screens/docker_pathway_screen.dart';
import 'package:devops_learning_app/features/pathway/screens/git_pathway_screen.dart';
import 'package:devops_learning_app/features/pathway/widgets/git_pathway_map.dart';
import 'package:devops_learning_app/features/pathway/widgets/pathway_track_painter.dart';
import 'package:devops_learning_app/models/curriculum_model.dart';
import 'package:devops_learning_app/models/user_model.dart';
import 'package:devops_learning_app/providers/auth_provider.dart';

import 'auth_provider_test.dart';

List<CurriculumModule> _buildTestModules({bool varyHeights = false}) {
  return List<CurriculumModule>.generate(7, (index) {
    final order = index + 1;
    final summary = varyHeights && index.isEven
        ? 'Extended overview for module $order covering multi-branch workflows, '
            'object internals, pull requests, continuous integration checks, '
            'and clean commit hygiene across distributed engineering teams.'
        : 'Concise summary for module $order.';

    return CurriculumModule(
      id: 'mod-0$order',
      order: order,
      number: '0$order',
      title: 'Module $order Full Title',
      shortTitle: varyHeights && index == 2
          ? 'Stop $order With An Extraordinarily Long Responsive Title Wrapping Cleanly'
          : 'Module Stop $order',
      summary: summary,
      estimatedMinutes: 15 + (index * 5),
      objectives: const ['Obj 1', 'Obj 2', 'Obj 3'],
      sections: const [],
    );
  });
}

void main() {
  group('White + Burgundy Light Theme & Curved Roadmap Consistency Tests', () {
    test('Theme tokens match exact website White + Burgundy palette', () {
      expect(AppColors.primary, const Color(0xFF3B1F24));
      expect(AppColors.secondary, const Color(0xFF60343D));
      expect(AppColors.accent, const Color(0xFF82535D));
      expect(AppColors.lightAccent, const Color(0xFFB88A91));
      expect(AppColors.paleBlush, const Color(0xFFE7D4D7));
      expect(AppColors.background, const Color(0xFFFFFFFF));
      expect(AppColors.surfaceAlt, const Color(0xFFFCF8F9));
      expect(AppColors.surface, const Color(0xFFFFFFFF));
      expect(AppColors.borderDefault, const Color(0xFFE8DDE0));
      expect(AppColors.textMain, const Color(0xFF171521));
      expect(AppColors.textMuted, const Color(0xFF454252));

      final theme = AppTheme.lightTheme;
      expect(theme.brightness, Brightness.light);
      expect(theme.scaffoldBackgroundColor, const Color(0xFFFFFFFF));
      expect(theme.colorScheme.brightness, Brightness.light);
      expect(theme.colorScheme.primary, const Color(0xFF3B1F24));
      expect(theme.colorScheme.onPrimary, Colors.white);
      expect(theme.colorScheme.onSurface, const Color(0xFF171521));
    });

    testWidgets(
      'AppButton primary uses solid burgundy background with crisp white text',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: CyberBackground(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      AppButton(
                        text: 'Continue Learning',
                        onPressed: () {},
                      ),
                      const SizedBox(height: 12),
                      AppButton(
                        text: 'Secondary Action',
                        variant: ButtonVariant.secondary,
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final primaryText = tester.widget<Text>(find.text('Continue Learning'));
        expect(primaryText.style?.color, Colors.white);

        final secondaryText = tester.widget<Text>(find.text('Secondary Action'));
        expect(secondaryText.style?.color, AppColors.primary);
      },
    );

    testWidgets(
      'LevelBadge and StatusBadge render readable light-theme text colors',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              body: Column(
                children: [
                  LevelBadge(level: 'Foundational'),
                  LevelBadge(level: 'Intermediate'),
                  LevelBadge(level: 'Advanced'),
                  StatusBadge(label: 'Active Pill', variant: BadgeVariant.cyan),
                  StatusBadge(label: 'Error Pill', variant: BadgeVariant.error),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          tester.widget<Text>(find.text('Foundational')).style?.color,
          AppColors.primary,
        );
        expect(
          tester.widget<Text>(find.text('Intermediate')).style?.color,
          AppColors.secondary,
        );
        expect(
          tester.widget<Text>(find.text('Advanced')).style?.color,
          Colors.white,
        );
        expect(
          tester.widget<Text>(find.text('Active Pill')).style?.color,
          AppColors.primary,
        );
        expect(
          tester.widget<Text>(find.text('Error Pill')).style?.color,
          AppColors.errorText,
        );
      },
    );

    testWidgets(
      'GitPathwayMap renders continuous cubic-Bezier road behind cards in Stack',
      (WidgetTester tester) async {
        final modules = _buildTestModules(varyHeights: true);
        String? tappedId;

        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.devicePixelRatio = 1.0;
        });

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GitPathwayMap(
                  modules: modules,
                  completedModuleIds: const {'mod-01', 'mod-02'},
                  onSelectModule: (id) => tappedId = id,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Road CustomPaint exists and sits in the first (background) Stack layer
        final roadFinder = find.byKey(const Key('pathway_road_painter'));
        expect(roadFinder, findsOneWidget);

        final customPaint = tester.widget<CustomPaint>(roadFinder);
        expect(customPaint.painter, isA<PathwayTrackPainter>());

        final stackFinder = find.ancestor(
          of: roadFinder,
          matching: find.byType(Stack),
        );
        final roadmapStack = tester.widget<Stack>(stackFinder.first);
        expect(
          roadmapStack.children.first,
          isA<Positioned>(),
        );

        // 2. Painter uses pale blush road + muted burgundy dashed center line
        final painter = customPaint.painter! as PathwayTrackPainter;
        expect(painter.points.length, modules.length + 2);
        expect(painter.baseColor, AppColors.paleBlush);
        expect(painter.cushionColor, AppColors.roadCushion);
        expect(painter.dashColor, AppColors.roadDash);

        // 3. Points alternate left & right horizontally while increasing vertically
        for (int i = 0; i < painter.points.length - 1; i++) {
          expect(painter.points[i + 1].dy, greaterThan(painter.points[i].dy));
        }
        // Stop 1 (index 1) is left, Stop 2 (index 2) is right, Stop 3 (index 3) is left
        expect(painter.points[1].dx, lessThan(painter.points[2].dx));
        expect(painter.points[2].dx, greaterThan(painter.points[3].dx));

        // 4. Built road path uses smooth curves longer than straight line chords
        final path = painter.buildRoadPath();
        final metrics = path.computeMetrics().toList();
        expect(metrics.length, 1); // Single continuous path across entire roadmap
        double chordLength = 0;
        for (int i = 0; i < painter.points.length - 1; i++) {
          chordLength += (painter.points[i + 1] - painter.points[i]).distance;
        }
        expect(metrics.first.length, greaterThan(chordLength));

        // 5. Dynamic completion states + tap navigation still work
        expect(find.text('Completed'), findsNWidgets(2));
        expect(find.text('Current Focus'), findsOneWidget);
        expect(find.text('Upcoming'), findsNWidgets(4));

        await tester.ensureVisible(find.text('Start Learning'));
        await tester.tap(find.text('Start Learning'));
        expect(tappedId, 'mod-03');
      },
    );

    for (final width in [360.0, 375.0, 390.0, 430.0, 800.0]) {
      testWidgets(
        'GitPathwayScreen & DockerPathwayScreen adapt cleanly at ${width.toInt()}px width with no overflow',
        (WidgetTester tester) async {
          final storageService = MockSecureStorageService();
          final fakeApi = FakeApiClient(storageService: storageService)
            ..mockUser = const UserModel(
              id: 'usr_resp',
              name: 'Grace Hopper',
              email: 'grace@example.com',
            );
          final authProvider = AuthProvider(
            apiClient: fakeApi,
            storageService: storageService,
            googleAuthService: MockGoogleAuthService(),
          );
          await authProvider.login(
            email: 'grace@example.com',
            password: 'password123',
          );

          final modules = _buildTestModules(varyHeights: true);

          tester.view.physicalSize = Size(width, 844);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.devicePixelRatio = 1.0;
          });

          // Verify Git Pathway Screen at target width
          await tester.pumpWidget(
            ChangeNotifierProvider<AuthProvider>.value(
              value: authProvider,
              child: MaterialApp(
                theme: AppTheme.lightTheme,
                home: GitPathwayScreen(
                  initialModules: modules,
                  initialCompletedIds: const {'mod-01'},
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);

          // Ensure all cards fit inside viewport width cleanly
          for (final mod in modules) {
            final titleFinder = find.text(mod.shortTitle);
            expect(titleFinder, findsOneWidget);
            final rect = tester.getRect(titleFinder);
            expect(rect.left, greaterThanOrEqualTo(0));
            expect(rect.right, lessThanOrEqualTo(width));
          }

          // Scroll smoothly to bottom FINISH monument
          await tester.drag(
            find.byType(SingleChildScrollView),
            const Offset(0, -1400),
          );
          await tester.pumpAndSettle();
          expect(find.text('FINISH'), findsOneWidget);
          expect(tester.takeException(), isNull);

          // Verify Docker Pathway Screen at target width
          await tester.pumpWidget(
            ChangeNotifierProvider<AuthProvider>.value(
              value: authProvider,
              child: MaterialApp(
                theme: AppTheme.lightTheme,
                home: DockerPathwayScreen(
                  initialModules: modules,
                  initialCompletedIds: const {'mod-01', 'mod-02'},
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text('Docker & Container Learning Pathway'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  });
}
