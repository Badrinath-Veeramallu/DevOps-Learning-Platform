import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/verify_otp_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/onboarding/screens/welcome_screen.dart';
import '../../providers/auth_provider.dart';
import 'route_names.dart';

/// Centralized GoRouter navigation configuration.
///
/// Supports:
/// - Android system back button navigation
/// - Parameter passing (e.g. `?email=user@example.com` for OTP verification)
/// - Authentication guards (redirecting unauthenticated users away from dashboard)
class AppRouter {
  AppRouter._();

  static GoRouter createRouter(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: RouteNames.welcome,
      refreshListenable: authProvider,
      redirect: (BuildContext context, GoRouterState state) {
        final isAuthenticated = authProvider.isAuthenticated;
        final isAuthRoute =
            state.matchedLocation == RouteNames.login ||
            state.matchedLocation == RouteNames.register ||
            state.matchedLocation == RouteNames.welcome;

        debugPrint(
          '[AppRouter] redirect check: location=${state.matchedLocation}, isAuth=$isAuthenticated, user=${authProvider.user?.name}',
        );

        // If user is authenticated and navigating to login/register, send to dashboard
        if (isAuthenticated && isAuthRoute) {
          debugPrint('[AppRouter] redirecting authenticated user to dashboard');
          return RouteNames.dashboard;
        }

        // If user is NOT authenticated and trying to access dashboard, redirect to login
        if (!isAuthenticated && state.matchedLocation == RouteNames.dashboard) {
          debugPrint(
            '[AppRouter] redirecting unauthenticated user away from dashboard to login',
          );
          return RouteNames.login;
        }

        return null;
      },
      routes: <RouteBase>[
        GoRoute(
          path: RouteNames.welcome,
          name: 'welcome',
          builder: (BuildContext context, GoRouterState state) {
            return const WelcomeScreen();
          },
        ),
        GoRoute(
          path: RouteNames.login,
          name: 'login',
          builder: (BuildContext context, GoRouterState state) {
            return const LoginScreen();
          },
        ),
        GoRoute(
          path: RouteNames.register,
          name: 'register',
          builder: (BuildContext context, GoRouterState state) {
            return const RegisterScreen();
          },
        ),
        GoRoute(
          path: RouteNames.verifyOtp,
          name: 'verifyOtp',
          builder: (BuildContext context, GoRouterState state) {
            final email = state.uri.queryParameters['email'] ?? '';
            return VerifyOtpScreen(email: email);
          },
        ),
        GoRoute(
          path: RouteNames.dashboard,
          name: 'dashboard',
          builder: (BuildContext context, GoRouterState state) {
            return const DashboardScreen();
          },
        ),
      ],
    );
  }
}
