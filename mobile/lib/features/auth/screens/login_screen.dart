import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/api/api_exceptions.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/cyber_background.dart';
import '../../../core/widgets/google_sign_in_button.dart';
import '../../../providers/auth_provider.dart';

/// Minimal, focused Login Screen.
///
/// Contains only:
/// - Email & Password inputs with visibility toggle
/// - Submit button ("Sign In")
/// - Link to Registration
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  String? _localError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() => _localError = null);

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = context.read<AuthProvider>();

    try {
      await authProvider.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        context.go(RouteNames.dashboard);
      }
    } on ApiException catch (e) {
      if (mounted) {
        // If account is unverified, route to OTP screen
        if (!e.isEmailVerified && e.email != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.message),
              backgroundColor: AppColors.warning,
            ),
          );
          context.push(
            '${RouteNames.verifyOtp}?email=${Uri.encodeComponent(e.email!)}',
          );
          return;
        }

        setState(() {
          _localError = e.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _localError = 'An unexpected error occurred. Please try again.';
        });
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    debugPrint('[LoginScreen] Continue with Google button pressed');
    setState(() => _localError = null);
    final authProvider = context.read<AuthProvider>();

    try {
      final success = await authProvider.loginWithGoogle();
      debugPrint(
        '[LoginScreen] loginWithGoogle returned: success=$success, mounted=$mounted',
      );
      if (success && mounted) {
        debugPrint('[LoginScreen] Auth successful. Routing to dashboard...');
        context.go(RouteNames.dashboard);
      } else if (!success && mounted) {
        debugPrint(
          '[LoginScreen] Google Sign-In dismissed by user without selecting account.',
        );
      }
    } on ApiException catch (e) {
      debugPrint('[LoginScreen] Caught ApiException: ${e.message}');
      if (mounted) {
        setState(() {
          _localError = e.message;
        });
      }
    } catch (e, stack) {
      debugPrint(
        '[LoginScreen] Caught generic error during Google sign-in: $e\n$stack',
      );
      if (mounted) {
        setState(() {
          _localError = 'Google sign-in was interrupted. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isLoading = authProvider.isLoading;
    final errorMessage = _localError ?? authProvider.errorMessage;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign In'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(RouteNames.welcome);
            }
          },
        ),
      ),
      body: CyberBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Minimal Title
                  const Text(
                    'Sign In',
                    style: AppTypography.displayMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Login Form Card
                  AppCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Error Banner if present
                        if (errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.errorBg,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.errorBorder,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  color: AppColors.error,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    errorMessage,
                                    style: AppTypography.bodySmall.copyWith(
                                      color: const Color(0xFFFCA5A5),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Email Field
                        AppTextField(
                          label: 'Email Address',
                          hint: 'developer@example.com',
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          prefixIcon: const Icon(
                            Icons.email_outlined,
                            size: 20,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Email address is required';
                            }
                            final emailRegex = RegExp(
                              r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                            );
                            if (!emailRegex.hasMatch(value.trim())) {
                              return 'Please enter a valid email address';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Password Field
                        AppTextField(
                          label: 'Password',
                          hint: '••••••••',
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          prefixIcon: const Icon(
                            Icons.lock_outline_rounded,
                            size: 20,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: 20,
                              color: AppColors.textMuted,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                          onFieldSubmitted: (_) => _handleLogin(),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Password is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // Submit Button
                        AppButton(
                          text: 'Sign In',
                          variant: ButtonVariant.primary,
                          isLoading: isLoading,
                          onPressed: isLoading ? null : _handleLogin,
                        ),
                        const SizedBox(height: 18),

                        // Divider
                        const AuthDivider(),
                        const SizedBox(height: 18),

                        // Google Sign-In Button
                        GoogleSignInButton(
                          isLoading: isLoading,
                          onPressed: isLoading ? null : _handleGoogleSignIn,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Link to Register
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          authProvider.clearError();
                          context.push(RouteNames.register);
                        },
                        child: Text(
                          'Create one',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
