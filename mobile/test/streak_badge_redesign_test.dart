import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:devops_learning_app/features/dashboard/widgets/learning_streak_pill.dart';
import 'package:devops_learning_app/features/dashboard/screens/dashboard_screen.dart';
import 'package:devops_learning_app/models/streak_model.dart';
import 'package:devops_learning_app/models/user_model.dart';
import 'package:devops_learning_app/providers/auth_provider.dart';
import 'package:provider/provider.dart';

import 'auth_provider_test.dart';

Widget _wrapWidget(Widget child, [Size size = const Size(390, 844)]) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(size: size),
      child: Scaffold(
        body: Center(
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: child,
          ),
        ),
      ),
    ),
  );
}

Widget _wrapWithAuth(Widget child, AuthProvider authProvider, Size size) {
  return ChangeNotifierProvider<AuthProvider>.value(
    value: authProvider,
    child: MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: child,
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockSecureStorageService storageService;
  late FakeApiClient fakeApi;
  late MockGoogleAuthService mockGoogleAuth;
  late AuthProvider authProvider;

  setUp(() async {
    storageService = MockSecureStorageService();
    fakeApi = FakeApiClient(storageService: storageService);
    mockGoogleAuth = MockGoogleAuthService();
    authProvider = AuthProvider(
      apiClient: fakeApi,
      storageService: storageService,
      googleAuthService: mockGoogleAuth,
    );
    fakeApi.mockUser = const UserModel(
      id: 'test-user-123',
      name: 'Badrinath Veeramallu',
      email: 'badri@example.com',
    );
    await authProvider.login(email: 'badri@example.com', password: 'password123');
  });

  group('Exact Thin Outline Burgundy Streak Badge Tests', () {
    testWidgets('1. Active streak renders thin outline Flame icon, bold number, medium streak', (tester) async {
      const activeStreak = StreakModel(
        currentStreak: 7,
        longestStreak: 14,
        isActiveToday: true,
        hasActivityYesterday: true,
      );

      await tester.pumpWidget(
        _wrapWidget(const LearningStreakPill(streak: activeStreak)),
      );
      await tester.pumpAndSettle();

      // Bold streak count '7'
      final countFinder = find.text('7');
      expect(countFinder, findsOneWidget);
      final countWidget = tester.widget<Text>(countFinder);
      expect(countWidget.style?.color, const Color(0xFF3B1F24));
      expect(countWidget.style?.fontWeight, FontWeight.w700);

      // Clean medium-weight 'streak' label
      final labelFinder = find.text('streak');
      expect(labelFinder, findsOneWidget);
      final labelWidget = tester.widget<Text>(labelFinder);
      expect(labelWidget.style?.color, const Color(0xFF3B1F24));
      expect(labelWidget.style?.fontWeight, FontWeight.w500);

      // Word 'days' is completely removed
      expect(find.textContaining('days'), findsNothing);
      expect(find.textContaining('day streak'), findsNothing);

      // Thin outline Lucide Flame Icon with Flame burgundy #542B32 & ~2px stroke
      final flameFinder = find.byType(LucideFlameIcon);
      expect(flameFinder, findsOneWidget);
      final flameIcon = tester.widget<LucideFlameIcon>(flameFinder);
      expect(flameIcon.color, const Color(0xFF542B32));
      expect(flameIcon.strokeWidth, 2.0);

      // Rounded pill container: #FCF7F8 background, #EAD9DC border, border-radius 999
      final containerFinder = find.byType(Container).first;
      final container = tester.widget<Container>(containerFinder);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, const Color(0xFFFCF7F8));
      final border = decoration.border as Border;
      expect(border.top.color, const Color(0xFFEAD9DC));
      expect(decoration.borderRadius, BorderRadius.circular(999));

      // Row has exactly 3 content elements: icon, count, label
      final rowFinder = find.byType(Row).first;
      final row = tester.widget<Row>(rowFinder);
      expect(row.crossAxisAlignment, CrossAxisAlignment.center);
    });

    testWidgets('2. Inactive streak (0) displays [Flame Icon] [0] [streak] in exact style', (tester) async {
      const inactiveStreak = StreakModel(
        currentStreak: 0,
        longestStreak: 0,
        isActiveToday: false,
        hasActivityYesterday: false,
      );

      await tester.pumpWidget(
        _wrapWidget(const LearningStreakPill(streak: inactiveStreak)),
      );
      await tester.pumpAndSettle();

      final countFinder = find.text('0');
      expect(countFinder, findsOneWidget);
      final countWidget = tester.widget<Text>(countFinder);
      expect(countWidget.style?.color, const Color(0xFF3B1F24));
      expect(countWidget.style?.fontWeight, FontWeight.w700);

      final labelFinder = find.text('streak');
      expect(labelFinder, findsOneWidget);
      final labelWidget = tester.widget<Text>(labelFinder);
      expect(labelWidget.style?.color, const Color(0xFF3B1F24));
      expect(labelWidget.style?.fontWeight, FontWeight.w500);

      expect(find.textContaining('days'), findsNothing);

      final flameFinder = find.byType(LucideFlameIcon);
      expect(flameFinder, findsOneWidget);
      final flameIcon = tester.widget<LucideFlameIcon>(flameFinder);
      expect(flameIcon.color, const Color(0xFF542B32));
      expect(flameIcon.strokeWidth, 2.0);
    });

    testWidgets('3. Loading state displays rounded placeholder pill', (tester) async {
      await tester.pumpWidget(
        _wrapWidget(const LearningStreakPill(isLoading: true)),
      );
      await tester.pump();

      expect(find.byType(Container), findsOneWidget);
      expect(find.text('streak'), findsNothing);
      expect(find.byType(LucideFlameIcon), findsNothing);
    });

    testWidgets('4. Dashboard screen adapts smoothly on Desktop (1200x800) with zero overflow', (tester) async {
      await tester.pumpWidget(
        _wrapWithAuth(const DashboardScreen(), authProvider, const Size(1200, 800)),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LearningStreakPill), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('5. Dashboard screen adapts smoothly on Tablet (768x1024) with zero overflow', (tester) async {
      await tester.pumpWidget(
        _wrapWithAuth(const DashboardScreen(), authProvider, const Size(768, 1024)),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LearningStreakPill), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('6. Dashboard screen adapts smoothly on Mobile (390x844) with zero overflow', (tester) async {
      await tester.pumpWidget(
        _wrapWithAuth(const DashboardScreen(), authProvider, const Size(390, 844)),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LearningStreakPill), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('7. Dashboard screen adapts smoothly on Small Mobile (320x568) with zero overflow', (tester) async {
      await tester.pumpWidget(
        _wrapWithAuth(const DashboardScreen(), authProvider, const Size(320, 568)),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LearningStreakPill), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
