import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Abstract interface for secure key-value token storage.
///
/// Decoupling through an interface enables:
/// 1. Painless unit and widget testing with in-memory mocks.
/// 2. Switching encryption backends without affecting business logic.
abstract class ISecureStorageService {
  Future<String?> getToken();
  Future<void> saveToken(String token);
  Future<void> deleteToken();
  Future<bool> hasToken();

  // Generic key-value storage methods (with default fallbacks for mocks)
  Future<String?> read(String key) async => null;
  Future<void> write(String key, String value) async {}
  Future<void> delete(String key) async {}
}

/// Production implementation of [ISecureStorageService] using [FlutterSecureStorage].
///
/// On Android, this uses the Android KeyStore and EncryptedSharedPreferences (AES-256 GCM).
class SecureStorageService implements ISecureStorageService {
  static const String _tokenKey = 'devops_auth_jwt_token';

  final FlutterSecureStorage _storage;

  SecureStorageService({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(resetOnError: true),
          );

  @override
  Future<String?> getToken() async {
    try {
      return await _storage.read(key: _tokenKey);
    } catch (_) {
      // If decryption fails due to key invalidation or hardware change, fail gracefully
      return null;
    }
  }

  @override
  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  @override
  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  @override
  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  @override
  Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (_) {}
  }

  @override
  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (_) {}
  }
}
