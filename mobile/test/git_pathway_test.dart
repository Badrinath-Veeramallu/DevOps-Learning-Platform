import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:devops_learning_app/core/theme/app_theme.dart';
import 'package:devops_learning_app/features/pathway/screens/git_pathway_screen.dart';
import 'package:devops_learning_app/features/pathway/widgets/git_pathway_map.dart';
import 'package:devops_learning_app/features/pathway/widgets/milestone_monument.dart';
import 'package:devops_learning_app/features/pathway/widgets/pathway_header_card.dart';
import 'package:devops_learning_app/features/pathway/widgets/pathway_stop_node.dart';
import 'package:devops_learning_app/models/curriculum_model.dart';
import 'package:devops_learning_app/models/user_model.dart';
import 'package:devops_learning_app/providers/auth_provider.dart';

import 'auth_provider_test.dart';

List<CurriculumModule> createSampleCurriculum() {
  return const [
    CurriculumModule(
      id: 'git-01',
      order: 1,
      number: '01',
      title: 'DevOps Foundations & Git Core Architecture',
      shortTitle: 'DevOps & Git Foundations',
      summary:
          'Explore why Git is the foundation of modern DevOps and CI/CD pipelines.',
      estimatedMinutes: 15,
      objectives: ['Obj 1', 'Obj 2', 'Obj 3', 'Obj 4'],
      sections: [],
    ),
    CurriculumModule(
      id: 'git-02',
      order: 2,
      number: '02',
      title: 'Working Directory, Staging & Commits',
      shortTitle: 'Working Tree, Staging & Commits',
      summary: 'Master the three-tier architecture of Git.',
      estimatedMinutes: 20,
      objectives: ['Obj 1', 'Obj 2', 'Obj 3', 'Obj 4'],
      sections: [],
    ),
    CurriculumModule(
      id: 'git-03',
      order: 3,
      number: '03',
      title: 'Git Under the Hood: Objects & SHA-1 Hashes',
      shortTitle: 'Git Under the Hood: Objects & Hashes',
      summary: "Unpack Git's content-addressable database.",
      estimatedMinutes: 25,
      objectives: ['Obj 1', 'Obj 2', 'Obj 3', 'Obj 4'],
      sections: [],
    ),
    CurriculumModule(
      id: 'git-04',
      order: 4,
      number: '04',
      title: 'Branching, Switching & Merging Strategies',
      shortTitle: 'Branching & Merging Strategies',
      summary: 'Learn lightweight branch pointers and fast-forward merges.',
      estimatedMinutes: 25,
      objectives: ['Obj 1', 'Obj 2', 'Obj 3', 'Obj 4'],
      sections: [],
    ),
    CurriculumModule(
      id: 'git-05',
      order: 5,
      number: '05',
      title: 'Remote Repositories & Distributed Team Collaboration',
      shortTitle: 'Remote Repositories & Team Workflows',
      summary: 'Connect local workspaces to GitHub remotes.',
      estimatedMinutes: 30,
      objectives: ['Obj 1', 'Obj 2', 'Obj 3', 'Obj 4'],
      sections: [],
    ),
    CurriculumModule(
      id: 'git-06',
      order: 6,
      number: '06',
      title: 'Rebasing, Cherry-Picking & History Rewriting',
      shortTitle: 'Rebasing, Cherry-Picking & Clean History',
      summary: 'Craft pristine git histories with rebase.',
      estimatedMinutes: 30,
      objectives: ['Obj 1', 'Obj 2', 'Obj 3', 'Obj 4'],
      sections: [],
    ),
    CurriculumModule(
      id: 'git-07',
      order: 7,
      number: '07',
      title: 'Conflict Resolution, Tagging & DevOps Release Workflows',
      shortTitle: 'Merge Conflicts, Tagging & Delivery',
      summary: 'Resolve conflicts and automate tags in DevOps pipelines.',
      estimatedMinutes: 35,
      objectives: ['Obj 1', 'Obj 2', 'Obj 3', 'Obj 4'],
      sections: [],
    ),
  ];
}

Widget _wrapPathway(Widget child, AuthProvider authProvider) {
  return ChangeNotifierProvider<AuthProvider>.value(
    value: authProvider,
    child: MaterialApp(theme: AppTheme.darkTheme, home: child),
  );
}

void main() {
  group('Git Pathway Journey Screen & Winding Track Map Tests', () {
    late MockSecureStorageService storageService;
    late FakeApiClient fakeApi;
    late MockGoogleAuthService mockGoogleAuth;
    late AuthProvider authProvider;
    late List<CurriculumModule> sampleModules;

    setUp(() {
      storageService = MockSecureStorageService();
      fakeApi = FakeApiClient(storageService: storageService);
      mockGoogleAuth = MockGoogleAuthService();
      authProvider = AuthProvider(
        apiClient: fakeApi,
        storageService: storageService,
        googleAuthService: mockGoogleAuth,
      );
      sampleModules = createSampleCurriculum();
    });

    testWidgets(
      'PathwayHeaderCard renders badges, title, description and progress calculation',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: PathwayHeaderCard(
                completedCount: 2,
                totalCount: 7,
                modules: sampleModules,
                completedIds: const {'git-01', 'git-02'},
                onBack: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Badges
        expect(find.text('Back to Dashboard'), findsOneWidget);
        expect(find.text('Foundational Pathway'), findsOneWidget);
        expect(find.text('7 Interactive Stops'), findsOneWidget);

        // Title and description
        expect(find.text('Git & GitHub Learning Pathway'), findsOneWidget);
        expect(
          find.text(
            'A structured, visual journey from fundamental version control commands to team collaboration, conflict resolution, and automated DevOps delivery pipelines.',
          ),
          findsOneWidget,
        );

        // Progress calculation: 2 of 7 is 29%
        expect(find.text('PATHWAY PROGRESS'), findsOneWidget);
        expect(find.textContaining('2 of 7 Completed (29%)'), findsOneWidget);

        // Next stop hint: Stop 3
        expect(
          find.text(
            'Next: Stop 3 · Git Under the Hood: Objects & Hashes',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'GitPathwayMap renders START and FINISH monuments',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: SingleChildScrollView(
                child: GitPathwayMap(
                  modules: sampleModules,
                  completedModuleIds: const {},
                  onSelectModule: (_) {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('START'), findsOneWidget);
        expect(find.text('FINISH'), findsOneWidget);
        expect(find.text('Journey Kickoff'), findsOneWidget);
        expect(find.text('Pathway Milestone Finish'), findsOneWidget);
      },
    );

    testWidgets(
      'GitPathwayMap renders all 7 module stops in exact curriculum order',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: SingleChildScrollView(
                child: GitPathwayMap(
                  modules: sampleModules,
                  completedModuleIds: const {'git-01'},
                  onSelectModule: (_) {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verify stop badges Stop 1 of 7 through Stop 7 of 7
        for (int i = 1; i <= 7; i++) {
          expect(find.text('Stop $i of 7'), findsOneWidget);
        }

        // Verify exact titles
        for (final mod in sampleModules) {
          expect(find.text(mod.shortTitle), findsOneWidget);
        }

        // Check completion states
        expect(find.text('Completed'), findsOneWidget); // git-01
        expect(find.text('Review Module'), findsOneWidget); // git-01 button

        expect(find.text('Current Focus'), findsOneWidget); // git-02
        expect(find.text('Start Learning'), findsOneWidget); // git-02 button

        expect(find.text('Upcoming'), findsNWidgets(5)); // git-03 through git-07
        expect(find.text('Explore Stop'), findsNWidgets(5));
      },
    );

    testWidgets(
      'MilestoneMonument updates appearance when all 7 stops are completed',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: const Scaffold(
              body: Column(
                children: [
                  MilestoneMonument(
                    type: MilestoneMonumentType.finish,
                    isAllCompleted: false,
                  ),
                  MilestoneMonument(
                    type: MilestoneMonumentType.finish,
                    isAllCompleted: true,
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('FINISH'), findsNWidgets(2));
      },
    );

    testWidgets(
      'PathwayStopNode triggers onSelectModule callback when action button or title is tapped',
      (WidgetTester tester) async {
        String? tappedModuleId;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: PathwayStopNode(
                module: sampleModules.first,
                status: StopStatus.current,
                onSelectModule: (id) => tappedModuleId = id,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Tap the action button "Start Learning"
        await tester.tap(find.text('Start Learning'));
        expect(tappedModuleId, 'git-01');

        // Tap the title
        tappedModuleId = null;
        await tester.tap(find.text('DevOps & Git Foundations'));
        expect(tappedModuleId, 'git-01');
      },
    );

    testWidgets(
      'GitPathwayScreen renders full view and adapts responsively to narrow mobile width',
      (WidgetTester tester) async {
        fakeApi.mockUser = const UserModel(
          id: 'usr_pathway_1',
          name: 'Linus Torvalds',
          email: 'linus@example.com',
        );
        await authProvider.login(
          email: 'linus@example.com',
          password: 'password123',
        );

        // Simulate narrow phone screen (360 x 800)
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.devicePixelRatio = 1.0;
        });

        await tester.pumpWidget(
          _wrapPathway(
            GitPathwayScreen(
              initialModules: sampleModules,
              initialCompletedIds: const {'git-01'},
            ),
            authProvider,
          ),
        );
        await tester.pumpAndSettle();

        // Screen headers and learning journey section
        expect(find.text('Learning Journey'), findsOneWidget);
        expect(
          find.text(
            'Click any stop along the path to open its complete educational module, commands, and interactive visual slots.',
          ),
          findsOneWidget,
        );

        // Bottom nav is on Git Pathway (index 1)
        expect(find.text('Git Pathway'), findsWidgets);

        // Verify no Flutter layout overflow occurred
        expect(tester.takeException(), isNull);
      },
    );
  });
}

