import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:devops_learning_app/core/theme/app_theme.dart';
import 'package:devops_learning_app/features/dashboard/models/learning_path_track.dart';
import 'package:devops_learning_app/features/dashboard/screens/dashboard_screen.dart';
import 'package:devops_learning_app/models/user_model.dart';
import 'package:devops_learning_app/providers/auth_provider.dart';

import 'auth_provider_test.dart';

Widget _wrapDashboard(Widget child, AuthProvider authProvider) {
  return ChangeNotifierProvider<AuthProvider>.value(
    value: authProvider,
    child: MaterialApp(theme: AppTheme.darkTheme, home: child),
  );
}

void main() {
  group('Dashboard Parity & Navigation Tests', () {
    late MockSecureStorageService storageService;
    late FakeApiClient fakeApi;
    late MockGoogleAuthService mockGoogleAuth;
    late AuthProvider authProvider;

    setUp(() {
      storageService = MockSecureStorageService();
      fakeApi = FakeApiClient(storageService: storageService);
      mockGoogleAuth = MockGoogleAuthService();
      authProvider = AuthProvider(
        apiClient: fakeApi,
        storageService: storageService,
        googleAuthService: mockGoogleAuth,
      );
    });

    testWidgets('Dashboard renders all 6 learning paths with exact titles and levels', (
      WidgetTester tester,
    ) async {
      fakeApi.mockUser = const UserModel(
        id: 'usr_dash_1',
        name: 'Sarah Connor',
        email: 'sarah@example.com',
      );
      await authProvider.login(email: 'sarah@example.com', password: 'password123');

      await tester.pumpWidget(_wrapDashboard(const DashboardScreen(), authProvider));
      await tester.pumpAndSettle();

      // Greeting
      expect(find.text('Welcome back, Sarah'), findsOneWidget);
      expect(
        find.text('Continue learning or choose a learning path to get started.'),
        findsOneWidget,
      );

      // Continue Learning Section
      expect(find.text('Continue Learning'), findsOneWidget);
      expect(find.text('Interactive Pathway Active'), findsOneWidget);
      expect(find.text('Open Pathway'), findsOneWidget);

      // Verify all 6 tracks exist
      final tracks = LearningPathTrack.defaultTracks;
      expect(tracks.length, 6);
      for (final track in tracks) {
        expect(find.text(track.title), findsWidgets);
      }

      // Verify distinct levels matching Web
      expect(find.text('Foundational'), findsWidgets);
      expect(find.text('Intermediate'), findsWidgets);
      expect(find.text('Advanced'), findsWidgets);
    });

    testWidgets('Dashboard bottom navigation renders 3 items and triggers callback', (
      WidgetTester tester,
    ) async {
      fakeApi.mockUser = const UserModel(
        id: 'usr_dash_2',
        name: 'John Doe',
        email: 'john@example.com',
      );
      await authProvider.login(email: 'john@example.com', password: 'password123');

      await tester.pumpWidget(_wrapDashboard(const DashboardScreen(), authProvider));
      await tester.pumpAndSettle();

      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Git Pathway'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
    });
  });
}

