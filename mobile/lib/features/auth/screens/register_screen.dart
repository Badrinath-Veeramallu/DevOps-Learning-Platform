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

/// Minimal, focused Registration Screen.
///
/// Contains only:
/// - Full Name, Email, Password, and Confirm Password fields
/// - Submit button ("Create Account")
/// - Link to Sign In
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _localError;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    setState(() => _localError = null);

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = context.read<AuthProvider>();

    try {
      final email = _emailController.text.trim();
      final response = await authProvider.register(
        name: _nameController.text.trim(),
        email: email,
        password: _passwordController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response['message'] as String? ??
                  'Verification code sent to your email.',
            ),
            backgroundColor: AppColors.secondary,
          ),
        );

        // Navigate to OTP verification screen passing the registered email
        context.push(
          '${RouteNames.verifyOtp}?email=${Uri.encodeComponent(email)}',
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _localError = e.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _localError = 'An unexpected error occurred during registration.';
        });
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    debugPrint('[RegisterScreen] Continue with Google button pressed');
    setState(() => _localError = null);
    final authProvider = context.read<AuthProvider>();

    try {
      final success = await authProvider.loginWithGoogle();
      debugPrint(
        '[RegisterScreen] loginWithGoogle returned: success=$success, mounted=$mounted',
      );
      if (success && mounted) {
        debugPrint('[RegisterScreen] Auth successful. Routing to dashboard...');
        context.go(RouteNames.dashboard);
      } else if (!success && mounted) {
        debugPrint(
          '[RegisterScreen] Google Sign-In dismissed by user without selecting account.',
        );
      }
    } on ApiException catch (e) {
      debugPrint('[RegisterScreen] Caught ApiException: ${e.message}');
      if (mounted) {
        setState(() {
          _localError = e.message;
        });
      }
    } catch (e, stack) {
      debugPrint(
        '[RegisterScreen] Caught generic error during Google sign-in: $e\n$stack',
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
        title: const Text('Create Account'),
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
                    'Create Account',
                    style: AppTypography.displayMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Registration Card
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

                        // Name Field
                        AppTextField(
                          label: 'Full Name',
                          hint: 'Alex Mercer',
                          controller: _nameController,
                          keyboardType: TextInputType.name,
                          textInputAction: TextInputAction.next,
                          prefixIcon: const Icon(
                            Icons.person_outline_rounded,
                            size: 20,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Full name is required';
                            }
                            if (value.trim().length < 2) {
                              return 'Name must be at least 2 characters long';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

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
                          label: 'Password (min. 8 characters)',
                          hint: '••••••••',
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.next,
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
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Password is required';
                            }
                            if (value.length < 8) {
                              return 'Password must be at least 8 characters long';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Confirm Password Field
                        AppTextField(
                          label: 'Confirm Password',
                          hint: '••••••••',
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          textInputAction: TextInputAction.done,
                          prefixIcon: const Icon(
                            Icons.lock_reset_rounded,
                            size: 20,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: 20,
                              color: AppColors.textMuted,
                            ),
                            onPressed: () => setState(
                              () => _obscureConfirmPassword =
                                  !_obscureConfirmPassword,
                            ),
                          ),
                          onFieldSubmitted: (_) => _handleRegister(),
                          validator: (value) {
                            if (value != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // Submit Button
                        AppButton(
                          text: 'Create Account',
                          variant: ButtonVariant.primary,
                          isLoading: isLoading,
                          onPressed: isLoading ? null : _handleRegister,
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

                  // Link to Sign In
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          authProvider.clearError();
                          context.push(RouteNames.login);
                        },
                        child: Text(
                          'Sign In',
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
