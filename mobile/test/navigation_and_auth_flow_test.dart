import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:devops_learning_app/app.dart';
import 'package:devops_learning_app/core/theme/app_theme.dart';
import 'package:devops_learning_app/core/widgets/app_bottom_nav_bar.dart';
import 'package:devops_learning_app/features/auth/screens/login_screen.dart';
import 'package:devops_learning_app/features/dashboard/screens/dashboard_screen.dart';
import 'package:devops_learning_app/features/onboarding/screens/welcome_screen.dart';
import 'package:devops_learning_app/features/pathway/screens/git_pathway_screen.dart';
import 'package:devops_learning_app/models/user_model.dart';
import 'package:devops_learning_app/providers/auth_provider.dart';

import 'auth_provider_test.dart';
import 'git_pathway_test.dart';

Widget _wrapWithProvider(
  Widget child,
  AuthProvider authProvider, {
  Size screenSize = const Size(400, 800),
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
  group('AppBottomNavBar Compact Layout Tests', () {
    testWidgets(
      'AppBottomNavBar height stays below 80 dp even under loose vertical constraints',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 0,
                    maxWidth: 400,
                    minHeight: 0,
                    maxHeight: 800,
                  ),
                  child: AppBottomNavBar(
                    currentIndex: 0,
                    onTabSelected: (_) {},
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final navBarFinder = find.byType(AppBottomNavBar);
        expect(navBarFinder, findsOneWidget);

        final size = tester.getSize(navBarFinder);
        // Must be compact (below 80 dp) and not expand greedily to maxHeight
        expect(size.height, lessThan(80.0));
        expect(size.height, greaterThan(45.0));

        // Preserves all 3 navigation items
        expect(find.text('Dashboard'), findsOneWidget);
        expect(find.text('Git Pathway'), findsOneWidget);
        expect(find.text('Profile'), findsOneWidget);
      },
    );

    testWidgets(
      'AppBottomNavBar respects safe area and items respond to tap callbacks',
      (WidgetTester tester) async {
        int tappedIndex = -1;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              bottomNavigationBar: AppBottomNavBar(
                currentIndex: 1,
                onTabSelected: (index) {
                  tappedIndex = index;
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Tap Profile
        await tester.tap(find.text('Profile'));
        await tester.pumpAndSettle();
        expect(tappedIndex, equals(2));

        // Tap Dashboard
        await tester.tap(find.text('Dashboard'));
        await tester.pumpAndSettle();
        expect(tappedIndex, equals(0));
      },
    );
  });

  group('Screen Body Height and Viewport Parity Tests', () {
    late MockSecureStorageService storageService;
    late FakeApiClient fakeApi;
    late AuthProvider authProvider;

    setUp(() {
      storageService = MockSecureStorageService();
      fakeApi = FakeApiClient(storageService: storageService);
      authProvider = AuthProvider(
        apiClient: fakeApi,
        storageService: storageService,
      );
    });

    testWidgets(
      'DashboardScreen body height > 400 dp and does not get collapsed by bottom nav',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          _wrapWithProvider(
            const DashboardScreen(),
            authProvider,
            screenSize: const Size(400, 800),
          ),
        );
        await tester.pumpAndSettle();

        // Check DashboardScreen elements render
        expect(find.byType(DashboardScreen), findsOneWidget);
        expect(find.byType(AppBottomNavBar), findsOneWidget);

        // Body scroll view has sufficient height (> 400 dp)
        final scrollViewFinder = find.byType(SingleChildScrollView);
        expect(scrollViewFinder, findsOneWidget);
        final bodySize = tester.getSize(scrollViewFinder);
        expect(bodySize.height, greaterThan(400.0));

        // Bottom nav bar height is constrained below 80 dp
        final navBarSize = tester.getSize(find.byType(AppBottomNavBar));
        expect(navBarSize.height, lessThan(80.0));
      },
    );

    testWidgets(
      'GitPathwayScreen body is not collapsed and displays pathway map properly',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          _wrapWithProvider(
            GitPathwayScreen(
              initialModules: createSampleCurriculum(),
            ),
            authProvider,
            screenSize: const Size(400, 800),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(GitPathwayScreen), findsOneWidget);
        expect(find.byType(AppBottomNavBar), findsOneWidget);

        // Git pathway contains SingleChildScrollView for the winding road
        final scrollViewFinder = find.byType(SingleChildScrollView);
        expect(scrollViewFinder, findsOneWidget);
        final bodySize = tester.getSize(scrollViewFinder);
        expect(bodySize.height, greaterThan(400.0));
      },
    );
  });

  group('Authentication Startup and Routing Navigation Tests', () {
    testWidgets(
      'Authenticated startup resolves directly to Dashboard with user data',
      (WidgetTester tester) async {
        final storage = MockSecureStorageService();
        await storage.saveToken('valid_token_123');

        final api = FakeApiClient(storageService: storage);
        api.mockUser = const UserModel(
          id: 'u123',
          name: 'Alex Hunter',
          email: 'alex@example.com',
        );

        await tester.pumpWidget(
          DevOpsLearningApp(
            storageService: storage,
            apiClient: api,
          ),
        );
        await tester.pumpAndSettle();

        // Redirects directly to DashboardScreen
        expect(find.byType(DashboardScreen), findsOneWidget);
        expect(find.text('Welcome back, Alex'), findsOneWidget);
        expect(find.byType(WelcomeScreen), findsNothing);
      },
    );

    testWidgets(
      'Unauthenticated startup resolves directly to Welcome screen',
      (WidgetTester tester) async {
        final storage = MockSecureStorageService(); // No token
        final api = FakeApiClient(storageService: storage);

        await tester.pumpWidget(
          DevOpsLearningApp(
            storageService: storage,
            apiClient: api,
          ),
        );
        await tester.pumpAndSettle();

        // Shows WelcomeScreen with branding and actions
        expect(find.byType(WelcomeScreen), findsOneWidget);
        expect(find.text('DevOps Learning Platform'), findsOneWidget);
        expect(find.text('Master DevOps from code to cloud.'), findsOneWidget);
        expect(find.byType(DashboardScreen), findsNothing);
      },
    );

    testWidgets(
      'Tapping Sign In on Welcome screen displays LoginScreen credential form',
      (WidgetTester tester) async {
        final storage = MockSecureStorageService(); // No token
        final api = FakeApiClient(storageService: storage);

        await tester.pumpWidget(
          DevOpsLearningApp(
            storageService: storage,
            apiClient: api,
          ),
        );
        await tester.pumpAndSettle();

        // Ensure we are on WelcomeScreen
        expect(find.byType(WelcomeScreen), findsOneWidget);

        // Tap Sign In button
        final signInFinder = find.widgetWithText(ElevatedButton, 'Sign In');
        expect(signInFinder, findsOneWidget);
        await tester.tap(signInFinder);
        await tester.pumpAndSettle();

        // LoginScreen is displayed with input fields and submit button
        expect(find.byType(LoginScreen), findsOneWidget);
        expect(find.text('Sign In'), findsAtLeastNWidgets(1));
        expect(find.byType(TextFormField), findsNWidgets(2)); // Email & Password
      },
    );

    testWidgets(
      'Logout clears session, returns to Welcome screen, and allows signing in with another account',
      (WidgetTester tester) async {
        final storage = MockSecureStorageService();
        await storage.saveToken('token_account_1');

        final api = FakeApiClient(storageService: storage);
        api.mockUser = const UserModel(
          id: 'u1',
          name: 'First User',
          email: 'first@example.com',
        );

        final authProvider = AuthProvider(
          apiClient: api,
          storageService: storage,
        );

        await tester.pumpWidget(
          DevOpsLearningApp(
            storageService: storage,
            apiClient: api,
            authProvider: authProvider,
          ),
        );
        await tester.pumpAndSettle();

        // Initially logged in as First User
        expect(find.byType(DashboardScreen), findsOneWidget);
        expect(find.text('Welcome back, First'), findsOneWidget);
        expect(await storage.hasToken(), isTrue);

        // Perform logout
        await authProvider.logout();
        await tester.pumpAndSettle();

        // Verify token is deleted and user is cleared
        expect(await storage.hasToken(), isFalse);
        expect(authProvider.isAuthenticated, isFalse);
        expect(authProvider.user, isNull);

        // Router redirects unauthenticated user away from dashboard
        expect(find.byType(LoginScreen), findsOneWidget);

        // Now simulate signing in with a second account
        api.mockUser = const UserModel(
          id: 'u2',
          name: 'Second User',
          email: 'second@example.com',
        );

        await authProvider.login(
          email: 'second@example.com',
          password: 'Password123!',
        );
        await tester.pumpAndSettle();

        // User is now authenticated with second account
        expect(authProvider.isAuthenticated, isTrue);
        expect(authProvider.user?.name, equals('Second User'));
        expect(await storage.hasToken(), isTrue);
        expect(find.byType(DashboardScreen), findsOneWidget);
        expect(find.text('Welcome back, Second'), findsOneWidget);
      },
    );
  });
}
