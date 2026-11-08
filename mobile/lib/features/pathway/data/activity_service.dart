import 'package:flutter/foundation.dart';

import '../../../core/api/api_client.dart';
import '../../../core/storage/secure_storage_service.dart';

/// Centralized service for user activity telemetry.
///
/// Dispatches `lesson_viewed` and `animation_finished` activity events to the
/// backend (`POST /api/activity/log`) while preventing duplicate submissions
/// from widget rebuilds or fast navigation.
///
/// Note: `stop_completed` events are generated server-side exclusively by the
/// module toggle endpoint (`/api/progress/:pathwayId/toggle`).
class ActivityService {
  static final ActivityService _instance = ActivityService._internal();
  factory ActivityService() => _instance;

  ActivityService._internal();

  ApiClient? _apiClient;
  ISecureStorageService? _storageService;

  // In-memory deduplication set: "$userId:$type:$stopSlug:$todayDate"
  final Set<String> _loggedEvents = {};

  /// Initialize service with dependencies.
  void init({ApiClient? apiClient, ISecureStorageService? storageService}) {
    _apiClient = apiClient;
    _storageService = storageService;
  }

  static final ISecureStorageService _defaultStorage = _InMemoryStorageService();

  ISecureStorageService get _effectiveStorage =>
      _storageService ?? _defaultStorage;

  ApiClient get _effectiveClient =>
      _apiClient ?? ApiClient(storageService: _effectiveStorage);

  String _buildEventKey(String userId, String type, String stopSlug) {
    final today = DateTime.now().toUtc().toIso8601String().substring(0, 10);
    return '$userId:$type:$stopSlug:$today';
  }

  /// Records a `lesson_viewed` activity event.
  ///
  /// Only logs once per user, per stop, per UTC calendar day.
  /// Fails silently on network error without interrupting user experience.
  Future<bool> logLessonViewed({
    required String userId,
    required String stopSlug,
    String pathwayId = 'git',
  }) async {
    if (userId.trim().isEmpty || userId == 'guest') {
      return false;
    }

    if (!await _effectiveStorage.hasToken()) {
      return false;
    }

    final key = _buildEventKey(userId, 'lesson_viewed', stopSlug);
    if (_loggedEvents.contains(key)) {
      return false; // Already recorded today
    }

    _loggedEvents.add(key);

    try {
      final res = await _effectiveClient.logActivity(
        type: 'lesson_viewed',
        stopSlug: stopSlug,
        pathwayId: pathwayId,
      );
      return res['logged'] == true || res['success'] == true;
    } catch (e) {
      debugPrint('[ActivityService] lesson_viewed error (ignored): $e');
      return false;
    }
  }

  /// Records an `animation_finished` activity event when an animation finishes.
  ///
  /// Only logs once per user, per stop, per UTC calendar day.
  /// Fails silently on network error without interrupting user experience.
  Future<bool> logAnimationFinished({
    required String userId,
    required String stopSlug,
    String pathwayId = 'git',
  }) async {
    if (userId.trim().isEmpty || userId == 'guest') {
      return false;
    }

    if (!await _effectiveStorage.hasToken()) {
      return false;
    }

    final key = _buildEventKey(userId, 'animation_finished', stopSlug);
    if (_loggedEvents.contains(key)) {
      return false; // Already recorded today
    }

    _loggedEvents.add(key);

    try {
      final res = await _effectiveClient.logActivity(
        type: 'animation_finished',
        stopSlug: stopSlug,
        pathwayId: pathwayId,
      );
      return res['logged'] == true || res['success'] == true;
    } catch (e) {
      debugPrint('[ActivityService] animation_finished error (ignored): $e');
      return false;
    }
  }

  /// Checks if an event was already logged today in memory.
  bool hasLoggedEvent({
    required String userId,
    required String type,
    required String stopSlug,
  }) {
    final key = _buildEventKey(userId, type, stopSlug);
    return _loggedEvents.contains(key);
  }

  /// Clears in-memory deduplication cache (useful for logout and tests).
  void clearCache() {
    _loggedEvents.clear();
  }
}

class _InMemoryStorageService implements ISecureStorageService {
  String? _token;
  final Map<String, String> _map = {};

  @override
  Future<String?> getToken() async => _token;

  @override
  Future<void> saveToken(String token) async => _token = token;

  @override
  Future<void> deleteToken() async => _token = null;

  @override
  Future<bool> hasToken() async => _token != null && _token!.isNotEmpty;

  @override
  Future<String?> read(String key) async => _map[key];

  @override
  Future<void> write(String key, String value) async => _map[key] = value;

  @override
  Future<void> delete(String key) async => _map.remove(key);
}
