import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/verify_otp_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/onboarding/screens/splash_screen.dart';
import '../../features/onboarding/screens/welcome_screen.dart';
import '../../features/pathway/screens/git_pathway_screen.dart';
import '../../core/widgets/phase_placeholder_screen.dart';
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
      initialLocation: RouteNames.splash,
      refreshListenable: authProvider,
      redirect: (BuildContext context, GoRouterState state) {
        final isInitialized = authProvider.isInitialized;
        final isAuthenticated = authProvider.isAuthenticated;
        final location = state.matchedLocation;

        debugPrint(
          '[AppRouter] redirect check: location=$location, isInit=$isInitialized, isAuth=$isAuthenticated, user=${authProvider.user?.name}',
        );

        // 1. While auth status is being checked on startup, stay on Splash
        if (!isInitialized) {
          if (location != RouteNames.splash) {
            return RouteNames.splash;
          }
          return null;
        }

        // 2. Once initialized, redirect away from Splash
        if (location == RouteNames.splash) {
          return isAuthenticated ? RouteNames.dashboard : RouteNames.welcome;
        }

        // 3. If authenticated user attempts to access welcome/login/register, send to dashboard
        final isAuthRoute =
            location == RouteNames.welcome ||
            location == RouteNames.login ||
            location == RouteNames.register;

        if (isAuthenticated && isAuthRoute) {
          debugPrint('[AppRouter] redirecting authenticated user to dashboard');
          return RouteNames.dashboard;
        }

        // 4. If unauthenticated user tries to access protected routes, send to login
        final isProtectedRoute =
            location == RouteNames.dashboard ||
            location == RouteNames.gitPathway ||
            location.startsWith('/pathways/git') ||
            location == RouteNames.profile;

        if (!isAuthenticated && isProtectedRoute) {
          debugPrint(
            '[AppRouter] redirecting unauthenticated user away from $location to login',
          );
          return RouteNames.login;
        }

        return null;
      },
      routes: <RouteBase>[
        GoRoute(
          path: RouteNames.splash,
          name: 'splash',
          builder: (BuildContext context, GoRouterState state) {
            return const SplashScreen();
          },
        ),
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
        GoRoute(
          path: RouteNames.gitPathway,
          name: 'gitPathway',
          builder: (BuildContext context, GoRouterState state) {
            return const GitPathwayScreen();
          },
        ),
        GoRoute(
          path: RouteNames.gitModule,
          name: 'gitModule',
          builder: (BuildContext context, GoRouterState state) {
            final moduleId = state.pathParameters['moduleId'] ?? '';
            return PhasePlaceholderScreen(
              title: 'Module $moduleId',
              phaseDescription:
                  'Interactive module reader with animations and practical exercises.',
              comingInPhase: 'Phase 4',
              icon: Icons.menu_book_rounded,
            );
          },
        ),
        GoRoute(
          path: RouteNames.profile,
          name: 'profile',
          builder: (BuildContext context, GoRouterState state) {
            return const PhasePlaceholderScreen(
              title: 'My Profile',
              phaseDescription:
                  'Account management and 52-week activity heatmap.',
              comingInPhase: 'Phase 6',
              icon: Icons.person_rounded,
            );
          },
        ),
      ],
    );
  }
}
