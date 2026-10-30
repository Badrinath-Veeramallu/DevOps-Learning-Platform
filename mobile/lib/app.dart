import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/api/api_client.dart';
import 'core/config/app_config.dart';
import 'core/router/app_router.dart';
import 'core/storage/secure_storage_service.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';

/// Root application widget.
///
/// Sets up:
/// - Dependency injection via Provider
/// - Session restoration on startup (`checkAuthStatus()`)
/// - Dynamic GoRouter with authentication guards
/// - Cyber Midnight dark theme
class DevOpsLearningApp extends StatefulWidget {
  final ISecureStorageService? storageService;
  final ApiClient? apiClient;
  final AuthProvider? authProvider;

  const DevOpsLearningApp({
    super.key,
    this.storageService,
    this.apiClient,
    this.authProvider,
  });

  @override
  State<DevOpsLearningApp> createState() => _DevOpsLearningAppState();
}

class _DevOpsLearningAppState extends State<DevOpsLearningApp> {
  late final ISecureStorageService _storageService;
  late final ApiClient _apiClient;
  late final AuthProvider _authProvider;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _storageService = widget.storageService ?? SecureStorageService();
    _apiClient = widget.apiClient ?? ApiClient(storageService: _storageService);
    _authProvider = widget.authProvider ??
        AuthProvider(
          apiClient: _apiClient,
          storageService: _storageService,
        );
    _router = AppRouter.createRouter(_authProvider);

    // Asynchronously restore previous session if token exists in KeyStore
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_authProvider.isInitialized) {
        _authProvider.checkAuthStatus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AuthProvider>.value(
      value: _authProvider,
      child: MaterialApp.router(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        routerConfig: _router,
      ),
    );
  }
}
