/// Configuration for backend API connectivity across mobile environments.
///
/// Networking & Base URLs:
/// - Default production deployed backend: `https://devops-learning-platform-a4yy.onrender.com/api`
/// - You can override this at compile-time for local development using:
///   `flutter run -d <DEVICE_ID> --dart-define=API_URL=http://<YOUR_IP>:5000/api`
class AppConfig {
  AppConfig._();

  /// Production deployed backend URL on Render
  static const String defaultProductionUrl =
      'https://devops-learning-platform-a4yy.onrender.com/api';

  /// Legacy local development LAN URL fallback
  static const String defaultLanBaseUrl = 'http://172.16.4.29:5000/api';

  /// Compile-time environment override using `--dart-define=API_URL=http://.../api`
  static const String _envApiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: defaultProductionUrl,
  );

  /// Resolves the active API base URL
  static String get defaultBaseUrl {
    if (_envApiUrl.isNotEmpty) {
      return _envApiUrl;
    }
    return defaultProductionUrl;
  }

  /// App name identifier
  static const String appName = 'DevOps Learning Platform';

  /// App version
  static const String appVersion = '1.0.0';

  /// Web Client ID used by the backend and serverClientId in Google Sign-In.
  static const String defaultGoogleClientId =
      '958415885728-9pi8volbfam54kav5hj5akvn8eq2f1uj.apps.googleusercontent.com';

  /// Compile-time environment override using `--dart-define=GOOGLE_CLIENT_ID=...`
  static const String _envGoogleClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
    defaultValue: defaultGoogleClientId,
  );

  /// Resolves the active Google Web Client ID for ID token audience
  static String get googleClientId {
    if (_envGoogleClientId.isNotEmpty) {
      return _envGoogleClientId;
    }
    return defaultGoogleClientId;
  }
}
