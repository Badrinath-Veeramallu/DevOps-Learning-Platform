import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/api/api_exceptions.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/cyber_background.dart';
import '../../../providers/auth_provider.dart';

/// Minimal, focused Email OTP Verification Screen.
///
/// Contains only:
/// - Target email confirmation
/// - 6-digit OTP entry field
/// - "Verify Email" button
/// - Resend code button with 60-second cooldown timer
/// - Link to return to Sign In
class VerifyOtpScreen extends StatefulWidget {
  final String email;

  const VerifyOtpScreen({super.key, required this.email});

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final _otpController = TextEditingController();
  final _focusNode = FocusNode();

  String? _localError;
  int _cooldownSeconds = 60;
  Timer? _timer;
  bool _isResending = false;

  @override
  void initState() {
    super.initState();
    _startCooldownTimer(60);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startCooldownTimer(int seconds) {
    _timer?.cancel();
    setState(() {
      _cooldownSeconds = seconds;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cooldownSeconds <= 1) {
        timer.cancel();
        setState(() {
          _cooldownSeconds = 0;
        });
      } else {
        setState(() {
          _cooldownSeconds--;
        });
      }
    });
  }

  Future<void> _handleVerify() async {
    setState(() => _localError = null);

    final cleanOtp = _otpController.text.trim();
    if (cleanOtp.length != 6 || !RegExp(r'^\d{6}$').hasMatch(cleanOtp)) {
      setState(() => _localError = 'Please enter all 6 numeric digits');
      return;
    }

    final authProvider = context.read<AuthProvider>();

    try {
      await authProvider.verifyEmail(email: widget.email, otp: cleanOtp);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Email verified successfully! Welcome to the Command Center.',
            ),
            backgroundColor: AppColors.secondary,
          ),
        );
        context.go(RouteNames.dashboard);
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
          _localError = 'Failed to verify code. Please try again.';
        });
      }
    }
  }

  Future<void> _handleResend() async {
    if (_cooldownSeconds > 0 || _isResending) return;

    setState(() {
      _isResending = true;
      _localError = null;
    });

    final authProvider = context.read<AuthProvider>();

    try {
      final message = await authProvider.resendOtp(email: widget.email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppColors.secondary,
          ),
        );
        _startCooldownTimer(60);
      }
    } on ApiException catch (e) {
      if (mounted) {
        if (e.retryAfter != null && e.retryAfter! > 0) {
          _startCooldownTimer(e.retryAfter!);
        }
        setState(() {
          _localError = e.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _localError = 'Failed to resend verification code.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
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
        title: const Text('Verify Email'),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Minimal Title
                const Text(
                  'Verify Your Email',
                  style: AppTypography.displayMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Target Email
                Text(
                  'Code sent to:',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 2),
                Text(
                  widget.email,
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.primaryLight,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Card with OTP input
                AppCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Error banner if present
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

                      // 6-digit OTP Field
                      TextField(
                        controller: _otpController,
                        focusNode: _focusNode,
                        autofocus: true,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 6,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                        ],
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 28,
                          letterSpacing: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMain,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          hintText: '000000',
                          hintStyle: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 28,
                            letterSpacing: 12,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textSubtle.withValues(alpha: 0.4),
                          ),
                        ),
                        onChanged: (value) {
                          if (value.length == 6) {
                            _handleVerify();
                          }
                        },
                      ),
                      const SizedBox(height: 20),

                      // Verify Button
                      AppButton(
                        text: 'Verify Email',
                        variant: ButtonVariant.primary,
                        isLoading: isLoading,
                        onPressed: isLoading ? null : _handleVerify,
                      ),
                      const SizedBox(height: 16),

                      // Resend Code Action with Cooldown
                      Center(
                        child: _cooldownSeconds > 0
                            ? Text(
                                'Resend code in ${_cooldownSeconds}s',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textSubtle,
                                ),
                              )
                            : TextButton(
                                onPressed: _isResending ? null : _handleResend,
                                child: Text(
                                  _isResending ? 'Resending...' : 'Resend Code',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Return to Sign In
                Center(
                  child: TextButton(
                    onPressed: () => context.go(RouteNames.login),
                    child: Text(
                      'Wrong email? Return to sign in',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
