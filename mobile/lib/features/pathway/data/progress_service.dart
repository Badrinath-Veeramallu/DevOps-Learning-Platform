import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../core/api/api_client.dart';
import '../../../core/storage/secure_storage_service.dart';

/// Explicit status representing synchronization with the backend REST API.
enum SyncStatus {
  /// Progress has been confirmed with a successful backend response.
  synced,

  /// A local mutation is in-flight or waiting for backend reconciliation.
  pending,

  /// Progress was modified while offline or server could not be reached.
  offline,

  /// Guest or unauthenticated session; progress is stored locally only and never synced.
  localOnly,
}

/// Service responsible for managing pathway module completion progress and
/// synchronizing with the backend REST API (`/api/progress/:pathwayId`).
///
/// Features:
/// - User-scoped caching matching Web's `devops_progress_${userId}_${pathway}`
/// - Explicit pending local progress change tracking (`devops_pending_${userId}_${pathway}`)
/// - Strictly serialized mutation queue to prevent concurrent race conditions
/// - Offline progress preservation without destructive server overrides or blind unions
/// - Safe GET reconciliation on network uncertainty (never blindly retrying toggle)
/// - Explicit SyncStatus distinguishing synced, pending, offline, and localOnly
class ProgressService extends ChangeNotifier {
  static final ProgressService _instance = ProgressService._internal();
  factory ProgressService() => _instance;

  ProgressService._internal();

  ApiClient? _apiClient;
  ISecureStorageService? _storageService;

  // In-memory cache keyed by "${userId}_${pathway}" -> Set of completed module IDs
  final Map<String, Set<String>> _cache = {};

  // Explicit pending local changes keyed by "${userId}_${pathway}" -> { moduleId: desiredCompletionState }
  final Map<String, Map<String, bool>> _pendingChanges = {};

  // Track sync status keyed by "${userId}_${pathway}"
  final Map<String, SyncStatus> _status = {};

  // Serialized mutation chain to strictly serialize all toggle and set operations
  Future<void> _lastMutation = Future.value();
  bool _isMutating = false;

  void init({
    ApiClient? apiClient,
    ISecureStorageService? storageService,
  }) {
    _apiClient = apiClient;
    _storageService = storageService;
  }

  ApiClient get _effectiveClient =>
      _apiClient ?? ApiClient(storageService: _effectiveStorage);

  static final ISecureStorageService _defaultStorage = _InMemoryStorageService();

  ISecureStorageService get _effectiveStorage =>
      _storageService ?? _defaultStorage;

  String _getStorageKey(String userId, String pathway) {
    final cleanId = userId.trim().isEmpty ? 'guest' : userId.trim();
    return 'devops_progress_${cleanId}_$pathway';
  }

  String _getPendingStorageKey(String userId, String pathway) {
    final cleanId = userId.trim().isEmpty ? 'guest' : userId.trim();
    return 'devops_pending_${cleanId}_$pathway';
  }

  String _getCacheKey(String userId, String pathway) {
    final cleanId = userId.trim().isEmpty ? 'guest' : userId.trim();
    return '${cleanId}_$pathway';
  }

  /// Serializes operations to avoid concurrent in-flight toggle requests.
  ///
  /// When idle, executes the first part synchronously up to the first await.
  /// When busy, queues operations sequentially.
  Future<T> _enqueueMutation<T>(Future<T> Function() action) {
    if (!_isMutating) {
      _isMutating = true;
      final completer = Completer<T>();
      _lastMutation = completer.future;

      try {
        final future = action();
        future.then((result) {
          _isMutating = false;
          completer.complete(result);
        }, onError: (err, st) {
          _isMutating = false;
          completer.completeError(err, st);
        });
      } catch (err, st) {
        _isMutating = false;
        completer.completeError(err, st);
      }

      return completer.future;
    } else {
      final completer = Completer<T>();
      final previous = _lastMutation;
      _lastMutation = completer.future;

      previous.whenComplete(() {
        try {
          final future = action();
          future.then((result) {
            completer.complete(result);
          }, onError: (err, st) {
            completer.completeError(err, st);
          });
        } catch (err, st) {
          completer.completeError(err, st);
        }
      });

      return completer.future;
    }
  }

  Future<void> _loadPendingFromDisk(String userId, String pathway) async {
    final cacheKey = _getCacheKey(userId, pathway);
    if (_pendingChanges.containsKey(cacheKey)) return;

    try {
      final key = _getPendingStorageKey(userId, pathway);
      final raw = await _effectiveStorage.read(key);
      if (raw != null && raw.isNotEmpty) {
        final Map<String, dynamic> decoded =
            json.decode(raw) as Map<String, dynamic>;
        _pendingChanges[cacheKey] =
            decoded.map((k, v) => MapEntry(k, v == true));
      } else {
        _pendingChanges[cacheKey] = {};
      }
    } catch (e) {
      debugPrint('[ProgressService] Error reading pending changes: $e');
      _pendingChanges[cacheKey] = {};
    }
  }

  Future<void> _savePendingToDisk(String userId, String pathway) async {
    try {
      final cacheKey = _getCacheKey(userId, pathway);
      final key = _getPendingStorageKey(userId, pathway);
      final map = _pendingChanges[cacheKey] ?? {};
      if (map.isEmpty) {
        await _effectiveStorage.delete(key);
      } else {
        final raw = json.encode(map);
        await _effectiveStorage.write(key, raw);
      }
    } catch (e) {
      debugPrint('[ProgressService] Error persisting pending changes: $e');
    }
  }

  Future<void> _ensureLoaded(String userId, String pathway) async {
    final cacheKey = _getCacheKey(userId, pathway);
    if (!_pendingChanges.containsKey(cacheKey)) {
      await _loadPendingFromDisk(userId, pathway);
    }
    if (!_cache.containsKey(cacheKey)) {
      await getCompletedModules(userId, pathway: pathway);
    }
  }

  /// Returns completed module IDs for a user and pathway.
  ///
  /// Checks in-memory cache first, then disk storage, and replays any pending local changes.
  Future<Set<String>> getCompletedModules(
    String userId, {
    String pathway = 'git',
  }) async {
    final cacheKey = _getCacheKey(userId, pathway);
    await _loadPendingFromDisk(userId, pathway);

    if (_cache.containsKey(cacheKey)) {
      return Set<String>.from(_cache[cacheKey]!);
    }

    // Attempt to restore from persistent storage
    Set<String> set = <String>{};
    try {
      final key = _getStorageKey(userId, pathway);
      final raw = await _effectiveStorage.read(key);
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> decoded = json.decode(raw) as List<dynamic>;
        set = decoded.map((e) => e.toString()).toSet();
      }
    } catch (e) {
      debugPrint('[ProgressService] Error reading stored progress: $e');
    }

    // Replay any pending local changes on top of stored progress
    final pending = _pendingChanges[cacheKey];
    if (pending != null && pending.isNotEmpty) {
      for (final entry in pending.entries) {
        if (entry.value) {
          set.add(entry.key);
        } else {
          set.remove(entry.key);
        }
      }
    }

    _cache[cacheKey] = set;
    return Set<String>.from(set);
  }

  /// Synchronously checks if a module is completed from the in-memory cache.
  bool isModuleCompleted(
    String userId,
    String moduleId, {
    String pathway = 'git',
  }) {
    final cacheKey = _getCacheKey(userId, pathway);
    final current = _cache[cacheKey] ?? <String>{};
    return current.contains(moduleId);
  }

  /// Checks whether local progress is confirmed to be synchronized with the backend.
  ///
  /// Always returns `false` for guest or unauthenticated sessions.
  bool isSynced(
    String userId, {
    String pathway = 'git',
  }) {
    final cacheKey = _getCacheKey(userId, pathway);
    return _status[cacheKey] == SyncStatus.synced;
  }

  /// Gets the explicit synchronization status for a user pathway.
  SyncStatus getSyncStatus(
    String userId, {
    String pathway = 'git',
  }) {
    final cacheKey = _getCacheKey(userId, pathway);
    if (_status.containsKey(cacheKey)) {
      return _status[cacheKey]!;
    }
    if (userId.trim().isEmpty || userId == 'guest') {
      return SyncStatus.localOnly;
    }
    return SyncStatus.offline;
  }

  /// Returns a copy of currently pending local changes for testing and debugging.
  Map<String, bool> getPendingChanges(
    String userId, {
    String pathway = 'git',
  }) {
    final cacheKey = _getCacheKey(userId, pathway);
    return Map<String, bool>.from(_pendingChanges[cacheKey] ?? {});
  }

  /// Directly populates in-memory cache (useful for tests and mock environments).
  void setCompletedModulesCache(
    String userId,
    Set<String> moduleIds, {
    String pathway = 'git',
    bool synced = true,
  }) {
    final cacheKey = _getCacheKey(userId, pathway);
    _cache[cacheKey] = Set<String>.from(moduleIds);
    _pendingChanges[cacheKey] = {};
    if (userId.trim().isEmpty || userId == 'guest') {
      _status[cacheKey] = SyncStatus.localOnly;
    } else {
      _status[cacheKey] = synced ? SyncStatus.synced : SyncStatus.offline;
    }
    _saveToDisk(userId, pathway, moduleIds);
    _savePendingToDisk(userId, pathway);
    notifyListeners();
  }

  /// Fetches authoritative progress from backend API and reconciles with local state.
  ///
  /// CRITICAL SAFETY GUARANTEE (Issue 1):
  /// Never deletes pending local offline completions or incompletions.
  /// Reconciles pending changes onto server data rather than blindly wiping the local cache.
  Future<Set<String>> fetchUserProgress(
    String userId, {
    String pathway = 'git',
  }) async {
    final cacheKey = _getCacheKey(userId, pathway);
    await _loadPendingFromDisk(userId, pathway);

    // Unauthenticated/guest users rely exclusively on local cache
    if (userId.trim().isEmpty || userId == 'guest') {
      _status[cacheKey] = SyncStatus.localOnly;
      return getCompletedModules(userId, pathway: pathway);
    }

    final hasToken = await _effectiveStorage.hasToken();
    if (!hasToken) {
      _status[cacheKey] = SyncStatus.localOnly;
      return getCompletedModules(userId, pathway: pathway);
    }

    try {
      final res = await _effectiveClient.getProgress(pathwayId: pathway);
      if (res['success'] == true && res['completedModules'] is List) {
        final serverSet = (res['completedModules'] as List)
            .map((e) => e.toString())
            .toSet();

        final pending = _pendingChanges[cacheKey] ?? {};
        final reconciledSet = Set<String>.from(serverSet);

        if (pending.isNotEmpty) {
          final resolvedModules = <String>[];
          for (final entry in pending.entries) {
            final modId = entry.key;
            final desired = entry.value;

            if (serverSet.contains(modId) == desired) {
              // Server state now matches our desired state; pending change is fulfilled
              resolvedModules.add(modId);
            } else {
              // Server does not yet reflect our pending change; preserve local intent
              if (desired) {
                reconciledSet.add(modId);
              } else {
                reconciledSet.remove(modId);
              }
            }
          }

          for (final resolved in resolvedModules) {
            pending.remove(resolved);
          }
          await _savePendingToDisk(userId, pathway);
        }

        _cache[cacheKey] = reconciledSet;
        _status[cacheKey] =
            pending.isEmpty ? SyncStatus.synced : SyncStatus.pending;
        await _saveToDisk(userId, pathway, reconciledSet);
        notifyListeners();
        return reconciledSet;
      }
    } catch (e) {
      debugPrint('[ProgressService] fetchUserProgress network error: $e');
      _status[cacheKey] = SyncStatus.offline;
    }

    return getCompletedModules(userId, pathway: pathway);
  }

  /// Safely toggles completion of a module on the backend.
  ///
  /// CRITICAL SAFETY GUARANTEES:
  /// 1. Entire mutation lifecycle is inside [_enqueueMutation] to prevent stale state reads.
  /// 2. Never blindly retries a toggle on timeout or network error.
  /// 3. If a toggle outcome is uncertain, executes a safe GET request to reconcile server state.
  /// 4. Optimistically updates local cache and preserves progress during offline usage.
  /// 5. Stale responses arriving while newer mutations are in flight are safely reconciled.
  Future<bool> toggleModuleCompletion(
    String userId,
    String moduleId, {
    String pathway = 'git',
  }) {
    return _enqueueMutation(() async {
      await _ensureLoaded(userId, pathway);
      final cacheKey = _getCacheKey(userId, pathway);
      final current = _cache[cacheKey] ?? <String>{};
      final bool wasCompleted = current.contains(moduleId);
      final bool desiredState = !wasCompleted;

      return _executeMutation(
        userId: userId,
        pathway: pathway,
        moduleId: moduleId,
        desiredState: desiredState,
      );
    });
  }

  /// Explicitly sets a module to completed or incomplete.
  ///
  /// Serialized and idempotent: no-ops if already in desired state inside the queue.
  Future<void> setModuleCompleted(
    String userId,
    String moduleId,
    bool completed, {
    String pathway = 'git',
  }) {
    return _enqueueMutation(() async {
      await _ensureLoaded(userId, pathway);
      final cacheKey = _getCacheKey(userId, pathway);
      final current = _cache[cacheKey] ?? <String>{};
      final bool isCurrentlyCompleted = current.contains(moduleId);

      if (isCurrentlyCompleted == completed) {
        return; // Idempotent: already matches desired state
      }

      await _executeMutation(
        userId: userId,
        pathway: pathway,
        moduleId: moduleId,
        desiredState: completed,
      );
    });
  }

  /// Internal worker executing the mutation inside the serialized queue.
  Future<bool> _executeMutation({
    required String userId,
    required String pathway,
    required String moduleId,
    required bool desiredState,
  }) async {
    final cacheKey = _getCacheKey(userId, pathway);

    // 1. Explicitly record pending local change
    _pendingChanges.putIfAbsent(cacheKey, () => {})[moduleId] = desiredState;

    // 2. Immediate optimistic update to in-memory cache
    final current = Set<String>.from(_cache[cacheKey] ?? <String>{});
    if (desiredState) {
      current.add(moduleId);
    } else {
      current.remove(moduleId);
    }
    _cache[cacheKey] = current;
    _status[cacheKey] = SyncStatus.pending;
    notifyListeners();

    await _savePendingToDisk(userId, pathway);
    await _saveToDisk(userId, pathway, current);

    // 3. Guest / unauthenticated users store progress locally only
    if (userId.trim().isEmpty || userId == 'guest') {
      _status[cacheKey] = SyncStatus.localOnly;
      _pendingChanges[cacheKey]?.remove(moduleId);
      await _savePendingToDisk(userId, pathway);
      notifyListeners();
      return desiredState;
    }

    final hasToken = await _effectiveStorage.hasToken();
    if (!hasToken) {
      _status[cacheKey] = SyncStatus.localOnly;
      _pendingChanges[cacheKey]?.remove(moduleId);
      await _savePendingToDisk(userId, pathway);
      notifyListeners();
      return desiredState;
    }

    // 4. Commit mutation to backend API
    try {
      final res = await _effectiveClient.toggleProgress(
        moduleId: moduleId,
        pathwayId: pathway,
      );

      if (res['success'] == true && res['completedModules'] is List) {
        final serverSet = (res['completedModules'] as List)
            .map((e) => e.toString())
            .toSet();

        await _reconcileServerResponse(
          userId: userId,
          pathway: pathway,
          moduleId: moduleId,
          desiredState: desiredState,
          serverSet: serverSet,
        );
        return desiredState;
      }
    } catch (err) {
      debugPrint(
        '[ProgressService] Toggle error ($err). Attempting safe GET reconciliation...',
      );

      // 5. Outcome is uncertain — NEVER retry toggle! Safely query current server state
      try {
        final getRes = await _effectiveClient.getProgress(pathwayId: pathway);
        if (getRes['success'] == true && getRes['completedModules'] is List) {
          final serverSet = (getRes['completedModules'] as List)
              .map((e) => e.toString())
              .toSet();

          await _reconcileServerResponse(
            userId: userId,
            pathway: pathway,
            moduleId: moduleId,
            desiredState: desiredState,
            serverSet: serverSet,
          );
          return desiredState;
        }
      } catch (getErr) {
        debugPrint(
          '[ProgressService] Safe GET reconciliation also failed: $getErr',
        );
      }

      // 6. Network unavailable / offline: keep optimistic change, mark status offline
      _status[cacheKey] = SyncStatus.offline;
      notifyListeners();
    }

    return desiredState;
  }

  /// Safely reconciles server response without overwriting newer local state or other pending changes.
  Future<void> _reconcileServerResponse({
    required String userId,
    required String pathway,
    required String moduleId,
    required bool desiredState,
    required Set<String> serverSet,
  }) async {
    final cacheKey = _getCacheKey(userId, pathway);
    final pending = _pendingChanges[cacheKey] ?? {};

    // The backend confirmed our toggle request for this module:
    // Remove it from pending unless a newer mutation has since changed its desiredState
    if (pending[moduleId] == desiredState) {
      pending.remove(moduleId);
    }

    // Replay any OTHER unresolved pending changes onto serverSet
    final reconciledSet = Set<String>.from(serverSet);
    final resolvedModules = <String>[];
    for (final entry in pending.entries) {
      final mod = entry.key;
      final des = entry.value;
      if (serverSet.contains(mod) == des) {
        resolvedModules.add(mod);
      } else {
        if (des) {
          reconciledSet.add(mod);
        } else {
          reconciledSet.remove(mod);
        }
      }
    }
    for (final r in resolvedModules) {
      pending.remove(r);
    }

    _cache[cacheKey] = reconciledSet;
    _status[cacheKey] =
        pending.isEmpty ? SyncStatus.synced : SyncStatus.pending;
    await _saveToDisk(userId, pathway, reconciledSet);
    await _savePendingToDisk(userId, pathway);
    notifyListeners();
  }

  Future<void> _saveToDisk(
    String userId,
    String pathway,
    Set<String> moduleIds,
  ) async {
    try {
      final key = _getStorageKey(userId, pathway);
      final raw = json.encode(moduleIds.toList());
      await _effectiveStorage.write(key, raw);
    } catch (e) {
      debugPrint('[ProgressService] Error persisting progress to disk: $e');
    }
  }

  /// Clears in-memory progress cache, pending changes, and sync state (called on logout).
  void clearCache() {
    _cache.clear();
    _pendingChanges.clear();
    _status.clear();
    _isMutating = false;
    _lastMutation = Future.value();
    notifyListeners();
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
