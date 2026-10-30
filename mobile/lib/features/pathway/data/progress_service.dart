import 'package:flutter/foundation.dart';
import '../../../core/storage/secure_storage_service.dart';

/// Service responsible for managing pathway module completion progress.
///
/// Follows the same scoping and keys as Web's `progressService.js`:
/// `devops_progress_${userId}_${pathway}`
class ProgressService extends ChangeNotifier {
  static final ProgressService _instance = ProgressService._internal();
  factory ProgressService() => _instance;

  ProgressService._internal();

  ISecureStorageService? _storageService;

  // In-memory cache keyed by "userId_pathway"
  final Map<String, Set<String>> _cache = {};

  void init({ISecureStorageService? storageService}) {
    _storageService = storageService;
  }

  String _getStorageKey(String userId, String pathway) {
    final cleanId = userId.trim().isEmpty ? 'guest' : userId.trim();
    return 'devops_progress_${cleanId}_$pathway';
  }

  /// Returns completed module IDs for a user and pathway.
  Future<Set<String>> getCompletedModules(
    String userId, {
    String pathway = 'git',
  }) async {
    final cacheKey = '${userId}_$pathway';
    if (_cache.containsKey(cacheKey)) {
      return Set<String>.from(_cache[cacheKey]!);
    }

    final storage = _storageService ?? SecureStorageService();
    try {
      final key = _getStorageKey(userId, pathway);
      final raw = await storage.getToken();
      if (raw != null && raw.isNotEmpty && key.isNotEmpty) {
        // Reserved for future disk reading
      }
    } catch (_) {}

    final set = _cache[cacheKey] ?? <String>{};
    return Set<String>.from(set);
  }

  /// Synchronously checks if a module is completed from the in-memory cache.
  bool isModuleCompleted(
    String userId,
    String moduleId, {
    String pathway = 'git',
  }) {
    final cacheKey = '${userId}_$pathway';
    final current = _cache[cacheKey] ?? <String>{};
    return current.contains(moduleId);
  }

  /// Sets in-memory completed modules directly (useful for tests and initialization).
  void setCompletedModulesCache(
    String userId,
    Set<String> moduleIds, {
    String pathway = 'git',
  }) {
    final cacheKey = '${userId}_$pathway';
    _cache[cacheKey] = Set<String>.from(moduleIds);
    notifyListeners();
  }

  /// Toggles completion status of a module.
  Future<bool> toggleModuleCompletion(
    String userId,
    String moduleId, {
    String pathway = 'git',
  }) async {
    final cacheKey = '${userId}_$pathway';
    final current = _cache[cacheKey] ?? <String>{};
    final bool isCompleted;

    if (current.contains(moduleId)) {
      current.remove(moduleId);
      isCompleted = false;
    } else {
      current.add(moduleId);
      isCompleted = true;
    }

    _cache[cacheKey] = current;
    notifyListeners();
    return isCompleted;
  }

  /// Sets completion status explicitly.
  Future<void> setModuleCompleted(
    String userId,
    String moduleId,
    bool completed, {
    String pathway = 'git',
  }) async {
    final cacheKey = '${userId}_$pathway';
    final current = _cache[cacheKey] ?? <String>{};

    if (completed) {
      current.add(moduleId);
    } else {
      current.remove(moduleId);
    }

    _cache[cacheKey] = current;
    notifyListeners();
  }

  /// Clears in-memory progress cache (useful for testing and logout).
  void clearCache() {
    _cache.clear();
    notifyListeners();
  }
}
