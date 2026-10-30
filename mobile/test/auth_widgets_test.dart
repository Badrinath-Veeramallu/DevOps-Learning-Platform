import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:devops_learning_app/core/theme/app_theme.dart';
import 'package:devops_learning_app/features/auth/screens/login_screen.dart';
import 'package:devops_learning_app/features/auth/screens/register_screen.dart';
import 'package:devops_learning_app/features/auth/screens/verify_otp_screen.dart';
import 'package:devops_learning_app/features/dashboard/screens/dashboard_screen.dart';
import 'package:devops_learning_app/features/profile/widgets/user_profile_sheet.dart';
import 'package:devops_learning_app/models/user_model.dart';
import 'package:devops_learning_app/providers/auth_provider.dart';

import 'auth_provider_test.dart';

Widget _wrapWithProvider(Widget child, AuthProvider authProvider) {
  return ChangeNotifierProvider<AuthProvider>.value(
    value: authProvider,
    child: MaterialApp(theme: AppTheme.darkTheme, home: child),
  );
}

void main() {
  group('Auth Form Widgets Validation Tests', () {
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

    testWidgets('LoginScreen shows validation error for invalid email', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _wrapWithProvider(const LoginScreen(), authProvider),
      );
      await tester.pumpAndSettle();

      // Enter invalid email
      await tester.enterText(find.byType(TextFormField).first, 'invalid-email');
      await tester.enterText(find.byType(TextFormField).last, 'Password123!');

      // Tap Sign In button
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
      await tester.pumpAndSettle();

      // Expect validation error
      expect(find.text('Please enter a valid email address'), findsOneWidget);
    });

    testWidgets('LoginScreen shows error when required fields are empty', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _wrapWithProvider(const LoginScreen(), authProvider),
      );
      await tester.pumpAndSettle();

      // Tap Sign In without entering any data
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
      await tester.pumpAndSettle();

      expect(find.text('Email address is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
    });

    testWidgets(
      'RegisterScreen validates short password and password mismatch',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          _wrapWithProvider(const RegisterScreen(), authProvider),
        );
        await tester.pumpAndSettle();

        final textFields = find.byType(TextFormField);

        // Name
        await tester.enterText(textFields.at(0), 'Alex Mercer');
        // Email
        await tester.enterText(textFields.at(1), 'alex@example.com');
        // Password (too short, < 8 chars)
        await tester.enterText(textFields.at(2), 'short');
        // Confirm Password (mismatch)
        await tester.enterText(textFields.at(3), 'mismatch123');

        // Submit
        await tester.tap(find.widgetWithText(ElevatedButton, 'Create Account'));
        await tester.pumpAndSettle();

        expect(
          find.text('Password must be at least 8 characters long'),
          findsOneWidget,
        );
        expect(find.text('Passwords do not match'), findsOneWidget);
      },
    );

    testWidgets('VerifyOtpScreen renders email and countdown cooldown timer', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _wrapWithProvider(
          const VerifyOtpScreen(email: 'dev@example.com'),
          authProvider,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('dev@example.com'), findsOneWidget);
      expect(find.text('Verify Your Email'), findsOneWidget);
      expect(find.textContaining('Resend code in'), findsOneWidget);
    });

    testWidgets('DashboardScreen renders dynamic greeting and profile menu', (
      WidgetTester tester,
    ) async {
      fakeApi.mockUser = const UserModel(
        id: 'user_123',
        name: 'Badrinath',
        email: 'badrinath@example.com',
        role: 'user',
        isEmailVerified: true,
      );
      await authProvider.login(
        email: 'badrinath@example.com',
        password: 'Password123!',
      );

      await tester.pumpWidget(
        _wrapWithProvider(const DashboardScreen(), authProvider),
      );
      await tester.pumpAndSettle();

      // Check dynamic greeting for Badrinath matching Web
      expect(find.text('Welcome back, Badrinath'), findsOneWidget);
      expect(find.text('Continue Learning'), findsOneWidget);
      expect(find.text('Available Learning Paths'), findsOneWidget);
      expect(find.text('Git & Collaborative Workflows'), findsWidgets);

      // Tap user profile avatar to open menu sheet
      UserProfileSheet.show(
        tester.element(find.byType(DashboardScreen)),
        user: fakeApi.mockUser!,
        authProvider: authProvider,
      );
      await tester.pumpAndSettle();

      // Check user details and sign out action in profile menu
      expect(find.text('badrinath@example.com'), findsOneWidget);
      expect(find.text('My Profile'), findsOneWidget);
      expect(find.text('Sign Out'), findsOneWidget);
    });

    testWidgets(
      'DashboardScreen extracts first name dynamically for other users',
      (WidgetTester tester) async {
        fakeApi.mockUser = const UserModel(
          id: 'user_456',
          name: 'Alex Mercer',
          email: 'alex@example.com',
          role: 'user',
          isEmailVerified: true,
        );
        await authProvider.login(
          email: 'alex@example.com',
          password: 'Password123!',
        );

        await tester.pumpWidget(
          _wrapWithProvider(const DashboardScreen(), authProvider),
        );
        await tester.pumpAndSettle();

        // Greets other user by dynamic name matching Web
        expect(find.text('Welcome back, Alex'), findsOneWidget);
      },
    );

    testWidgets(
      'LoginScreen renders Continue with Google button and OR divider',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          _wrapWithProvider(const LoginScreen(), authProvider),
        );
        await tester.pumpAndSettle();

        expect(find.text('Continue with Google'), findsOneWidget);
        expect(find.text('OR'), findsOneWidget);
      },
    );

    testWidgets(
      'RegisterScreen renders Continue with Google button and OR divider',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          _wrapWithProvider(const RegisterScreen(), authProvider),
        );
        await tester.pumpAndSettle();

        expect(find.text('Continue with Google'), findsOneWidget);
        expect(find.text('OR'), findsOneWidget);
      },
    );
  });
}
