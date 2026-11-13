import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exceptions.dart';
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

/// Representation of an operation waiting in the serial FIFO mutation queue.
class _QueuedMutation<T> {
  final Future<T> Function() action;
  final Completer<T> completer;
  final int sessionGeneration;
  final String userId;

  _QueuedMutation({
    required this.action,
    required this.completer,
    required this.sessionGeneration,
    required this.userId,
  });
}

/// Service responsible for managing pathway module completion progress and
/// synchronizing with the backend REST API (`/api/progress/:pathwayId`).
///
/// Features:
/// - User-scoped caching matching Web's `devops_progress_${userId}_${pathway}`
/// - Explicit pending local progress change tracking (`devops_pending_${userId}_${pathway}`)
/// - Strictly serialized FIFO asynchronous queue with session-generation invalidation
/// - Safe GET-first reconciliation on connectivity recovery and offline sync
/// - Protection against stale responses and cross-account mutation leakages
/// - Never blindly retries toggles; verifies server state via safe GET
class ProgressService extends ChangeNotifier {
  static final ProgressService _instance = ProgressService._internal();
  factory ProgressService() => _instance;

  ProgressService._internal();

  ApiClient? _apiClient;
  ISecureStorageService? _storageService;

  /// Authoritative module ordering for each pathway curriculum.
  static const Map<String, List<String>> pathwayModules = {
    'git': [
      'git-01',
      'git-02',
      'git-03',
      'git-04',
      'git-05',
      'git-06',
      'git-07',
    ],
    'docker': [
      'docker-01',
      'docker-02',
      'docker-03',
      'docker-04',
      'docker-05',
      'docker-06',
      'docker-07',
    ],
    'linux': [
      'linux-01',
      'linux-02',
      'linux-03',
      'linux-04',
      'linux-05',
      'linux-06',
    ],
  };

  /// Validates whether a module is unlocked based on completed modules.
  /// The first module is always unlocked; subsequent modules require module[idx - 1] to be completed.
  static bool isModuleUnlocked({
    required String pathway,
    required String moduleId,
    required Set<String> completedModules,
  }) {
    final list = pathwayModules[pathway.toLowerCase()];
    if (list == null) return true;
    final idx = list.indexOf(moduleId);
    if (idx <= 0) return true;
    final prevId = list[idx - 1];
    return completedModules.contains(prevId);
  }

  // In-memory cache keyed by "${userId}_${pathway}" -> Set of completed module IDs
  final Map<String, Set<String>> _cache = {};

  // Explicit pending local changes keyed by "${userId}_${pathway}" -> { moduleId: desiredCompletionState }
  final Map<String, Map<String, bool>> _pendingChanges = {};

  // Track sync status keyed by "${userId}_${pathway}"
  final Map<String, SyncStatus> _status = {};

  // Session generation counter incremented on logout/clearCache to invalidate prior operations
  int _currentSessionGeneration = 0;

  // FIFO async mutation queue and processing state per session generation
  final Map<int, List<_QueuedMutation<dynamic>>> _sessionQueues = {};
  final Set<int> _activeSessionWorkers = {};
  final Map<int, Set<_QueuedMutation<dynamic>>> _activeSessionMutations = {};
  int _maxObservedConcurrent = 0;

  /// Visible for testing to verify exact concurrent mutation count is never > 1.
  int get activeMutationCount =>
      _activeSessionMutations[_currentSessionGeneration]?.length ?? 0;
  int get queuedMutationCount =>
      _sessionQueues[_currentSessionGeneration]?.length ?? 0;
  int get maxObservedConcurrent => _maxObservedConcurrent;
  int get currentSessionGeneration => _currentSessionGeneration;

  void resetMaxObservedConcurrent() {
    _maxObservedConcurrent = 0;
  }

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

  /// Strictly serializes operations in FIFO order with session invalidation support.
  Future<T> _enqueueMutation<T>({
    required String userId,
    required Future<T> Function() action,
  }) {
    final generation = _currentSessionGeneration;
    final completer = Completer<T>();
    final mutation = _QueuedMutation<T>(
      action: action,
      completer: completer,
      sessionGeneration: generation,
      userId: userId,
    );
    final queue = _sessionQueues.putIfAbsent(generation, () => []);
    queue.add(mutation);
    _processSessionQueue(generation);
    return completer.future;
  }

  /// Executes queued mutations for [generation] one-by-one in strict FIFO sequence.
  Future<void> _processSessionQueue(int generation) async {
    if (_activeSessionWorkers.contains(generation)) return;
    _activeSessionWorkers.add(generation);

    try {
      while (true) {
        // If session was invalidated while in the queue loop, cancel remaining queued items
        if (generation != _currentSessionGeneration) {
          final queue = _sessionQueues[generation];
          if (queue != null && queue.isNotEmpty) {
            while (queue.isNotEmpty) {
              final item = queue.removeAt(0);
              if (!item.completer.isCompleted) {
                item.completer.completeError(
                  StateError('Operation cancelled due to logout/session change'),
                );
              }
            }
          }
          break;
        }

        final queue = _sessionQueues[generation];
        if (queue == null || queue.isEmpty) {
          break;
        }

        final item = queue.removeAt(0);

        // Verify that the queued operation still belongs to the active session
        if (item.sessionGeneration != _currentSessionGeneration) {
          if (!item.completer.isCompleted) {
            item.completer.completeError(
              StateError('Operation cancelled due to logout/session change'),
            );
          }
          continue;
        }

        final activeSet =
            _activeSessionMutations.putIfAbsent(generation, () => {});
        activeSet.add(item);
        if (activeSet.length > _maxObservedConcurrent) {
          _maxObservedConcurrent = activeSet.length;
        }

        try {
          final result = await item.action();
          if (item.sessionGeneration == _currentSessionGeneration) {
            if (!item.completer.isCompleted) {
              item.completer.complete(result);
            }
          } else {
            // Session was invalidated while the operation was executing
            if (!item.completer.isCompleted) {
              item.completer.completeError(
                StateError(
                  'Operation invalidated during execution by logout/session change',
                ),
              );
            }
          }
        } catch (e, st) {
          if (!item.completer.isCompleted) {
            item.completer.completeError(e, st);
          }
        } finally {
          _activeSessionMutations[generation]?.remove(item);
        }
      }
    } finally {
      _activeSessionWorkers.remove(generation);
      _sessionQueues.remove(generation);
      _activeSessionMutations.remove(generation);
    }
  }

  // Per-key write queues to serialize writes and deletes per storage key
  final Map<String, Future<void>> _keyWriteQueues = {};

  Future<void> _runWithKeyLock(
    String key,
    int sessionGeneration,
    Future<void> Function() writeAction,
  ) {
    if (sessionGeneration != _currentSessionGeneration) {
      return Future.value();
    }

    final prev = _keyWriteQueues[key] ?? Future.value();
    final completer = Completer<void>();
    _keyWriteQueues[key] = completer.future;

    return prev.whenComplete(() async {
      try {
        if (sessionGeneration != _currentSessionGeneration) {
          return;
        }
        await writeAction();
      } catch (e) {
        debugPrint('[ProgressService] Storage write error for key $key: $e');
      } finally {
        completer.complete();
        if (_keyWriteQueues[key] == completer.future) {
          _keyWriteQueues.remove(key);
        }
      }
    });
  }

  Future<void> _loadPendingFromDisk(
    String userId,
    String pathway, {
    int? sessionGeneration,
  }) async {
    final generation = sessionGeneration ?? _currentSessionGeneration;
    if (generation != _currentSessionGeneration) return;

    final cacheKey = _getCacheKey(userId, pathway);
    if (_pendingChanges.containsKey(cacheKey)) return;

    try {
      final key = _getPendingStorageKey(userId, pathway);
      final raw = await _effectiveStorage.read(key);
      if (generation != _currentSessionGeneration) return;

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
      if (generation == _currentSessionGeneration) {
        _pendingChanges[cacheKey] = {};
      }
    }
  }

  Future<void> _savePendingToDisk(
    String userId,
    String pathway, {
    int? sessionGeneration,
  }) {
    final generation = sessionGeneration ?? _currentSessionGeneration;
    if (generation != _currentSessionGeneration) {
      return Future.value();
    }

    final cacheKey = _getCacheKey(userId, pathway);
    final key = _getPendingStorageKey(userId, pathway);
    final map = _pendingChanges[cacheKey] ?? {};
    final bool isEmpty = map.isEmpty;
    final String? raw = isEmpty ? null : json.encode(map);

    return _runWithKeyLock(key, generation, () async {
      if (raw == null) {
        await _effectiveStorage.delete(key);
      } else {
        await _effectiveStorage.write(key, raw);
      }
    });
  }

  Future<void> _ensureLoaded(
    String userId,
    String pathway, {
    int? sessionGeneration,
  }) async {
    final generation = sessionGeneration ?? _currentSessionGeneration;
    if (generation != _currentSessionGeneration) return;

    final cacheKey = _getCacheKey(userId, pathway);
    if (!_pendingChanges.containsKey(cacheKey)) {
      await _loadPendingFromDisk(
        userId,
        pathway,
        sessionGeneration: generation,
      );
    }
    if (generation != _currentSessionGeneration) return;

    if (!_cache.containsKey(cacheKey)) {
      await getCompletedModules(
        userId,
        pathway: pathway,
        sessionGeneration: generation,
      );
    }
  }

  /// Returns completed module IDs for a user and pathway.
  ///
  /// Checks in-memory cache first, then disk storage, and replays any pending local changes.
  Future<Set<String>> getCompletedModules(
    String userId, {
    String pathway = 'git',
    int? sessionGeneration,
  }) async {
    final generation = sessionGeneration ?? _currentSessionGeneration;
    if (generation != _currentSessionGeneration) {
      return <String>{};
    }

    final cacheKey = _getCacheKey(userId, pathway);
    await _loadPendingFromDisk(
      userId,
      pathway,
      sessionGeneration: generation,
    );

    if (generation != _currentSessionGeneration) {
      return <String>{};
    }

    if (_cache.containsKey(cacheKey)) {
      return Set<String>.from(_cache[cacheKey]!);
    }

    // Attempt to restore from persistent storage
    Set<String> set = <String>{};
    try {
      final key = _getStorageKey(userId, pathway);
      final raw = await _effectiveStorage.read(key);
      if (generation != _currentSessionGeneration) {
        return <String>{};
      }

      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> decoded = json.decode(raw) as List<dynamic>;
        set = decoded.map((e) => e.toString()).toSet();
      }
    } catch (e) {
      debugPrint('[ProgressService] Error reading stored progress: $e');
      if (generation != _currentSessionGeneration) {
        return <String>{};
      }
    }

    if (generation != _currentSessionGeneration) {
      return <String>{};
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

    if (generation != _currentSessionGeneration) {
      return <String>{};
    }

    _cache[cacheKey] = set;
    return Set<String>.from(set);
  }

  /// Synchronously returns cached completed module IDs.
  Set<String> getCompletedModulesSync(
    String userId, {
    String pathway = 'git',
  }) {
    final cacheKey = _getCacheKey(userId, pathway);
    return Set<String>.from(_cache[cacheKey] ?? <String>{});
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

  /// Checks whether an entire pathway is fully completed.
  /// Sequential rules:
  /// - Git: all 7 Git modules completed.
  /// - Docker: Git is completed AND all 7 Docker modules completed.
  /// - Linux: Docker is completed AND all 6 Linux modules completed.
  bool isPathwayCompleted({
    required String pathway,
    required String userId,
  }) {
    final cleanPathway = pathway.toLowerCase();
    if (cleanPathway == 'git') {
      final completed = getCompletedModulesSync(userId, pathway: 'git');
      final gitModules = pathwayModules['git'] ?? [];
      return gitModules.isNotEmpty && gitModules.every((id) => completed.contains(id));
    }
    if (cleanPathway == 'docker') {
      if (!isPathwayCompleted(pathway: 'git', userId: userId)) return false;
      final completed = getCompletedModulesSync(userId, pathway: 'docker');
      final dockerModules = pathwayModules['docker'] ?? [];
      return dockerModules.isNotEmpty && dockerModules.every((id) => completed.contains(id));
    }
    if (cleanPathway == 'linux') {
      if (!isPathwayCompleted(pathway: 'docker', userId: userId)) return false;
      final completed = getCompletedModulesSync(userId, pathway: 'linux');
      final linuxModules = pathwayModules['linux'] ?? [];
      return linuxModules.isNotEmpty && linuxModules.every((id) => completed.contains(id));
    }
    return false;
  }

  /// Checks whether a pathway is unlocked based on prerequisite pathways:
  /// Progression: Git -> Docker -> Linux
  /// - Git: always unlocked.
  /// - Docker: unlocked if Git is fully completed.
  /// - Linux: unlocked if Docker is fully completed (which requires Git to be completed).
  bool isPathwayUnlocked({
    required String pathway,
    required String userId,
  }) {
    final cleanPathway = pathway.toLowerCase();
    if (cleanPathway == 'git') return true;
    if (cleanPathway == 'docker') return isPathwayCompleted(pathway: 'git', userId: userId);
    if (cleanPathway == 'linux') return isPathwayCompleted(pathway: 'docker', userId: userId);
    return false;
  }

  /// Returns lock explanation if locked, or null if unlocked.
  String? getPathwayLockReason({
    required String pathway,
    required String userId,
  }) {
    final cleanPathway = pathway.toLowerCase();
    if (cleanPathway == 'git') return null;
    if (cleanPathway == 'docker') {
      if (!isPathwayCompleted(pathway: 'git', userId: userId)) {
        return 'Complete all 7 Git modules to unlock the Docker pathway.';
      }
      return null;
    }
    if (cleanPathway == 'linux') {
      if (!isPathwayCompleted(pathway: 'git', userId: userId)) {
        return 'Complete all 7 Git modules first.';
      }
      if (!isPathwayCompleted(pathway: 'docker', userId: userId)) {
        return 'Complete all 7 Docker modules to unlock the Linux pathway.';
      }
      return null;
    }
    return 'Pathway coming soon.';
  }

  /// Sync lock and completion status for all core pathways from the server.
  Future<Map<String, dynamic>?> fetchAllPathwaysStatus(String userId) async {
    if (userId.trim().isEmpty || userId == 'guest') return null;
    final hasToken = await _effectiveStorage.hasToken();
    if (!hasToken) return null;

    try {
      final res = await _effectiveClient.getPathwaysStatus();
      if (res['success'] == true && res['pathways'] is Map) {
        final pathwaysMap = res['pathways'] as Map<String, dynamic>;
        for (final entry in pathwaysMap.entries) {
          final pId = entry.key;
          final pData = entry.value;
          if (pData is Map && pData['completedModules'] is List) {
            final modules = (pData['completedModules'] as List)
                .map((e) => e.toString())
                .toSet();
            final cacheKey = _getCacheKey(userId, pId);
            _cache[cacheKey] = modules;
            await _saveToDisk(userId, pId, modules, sessionGeneration: _currentSessionGeneration);
          }
        }
        notifyListeners();
        return pathwaysMap;
      }
    } catch (e) {
      debugPrint('[ProgressService] fetchAllPathwaysStatus error: $e');
    }
    return null;
  }

  /// Checks whether local progress is confirmed to be synchronized with the backend.
  ///
  /// Always returns `false` for guest, unauthenticated, pending, or offline states.
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
    _saveToDisk(userId, pathway, moduleIds, sessionGeneration: _currentSessionGeneration);
    _savePendingToDisk(userId, pathway, sessionGeneration: _currentSessionGeneration);
    notifyListeners();
  }

  /// Fetches authoritative progress from backend API and synchronizes pending changes.
  ///
  /// Serialized through the mutation queue to guarantee coordination with ongoing mutations.
  Future<Set<String>> fetchUserProgress(
    String userId, {
    String pathway = 'git',
  }) {
    final generation = _currentSessionGeneration;
    return _enqueueMutation<Set<String>>(
      userId: userId,
      action: () async {
        return _fetchAndReconcileInternal(
          userId: userId,
          pathway: pathway,
          generation: generation,
        );
      },
    );
  }

  /// Internal implementation of authoritative progress fetching and offline pending synchronization.
  Future<Set<String>> _fetchAndReconcileInternal({
    required String userId,
    required String pathway,
    required int generation,
  }) async {
    final cacheKey = _getCacheKey(userId, pathway);

    if (generation != _currentSessionGeneration) {
      return <String>{};
    }

    await _loadPendingFromDisk(
      userId,
      pathway,
      sessionGeneration: generation,
    );

    if (generation != _currentSessionGeneration) {
      return <String>{};
    }

    // Unauthenticated/guest users rely exclusively on local cache
    if (userId.trim().isEmpty || userId == 'guest') {
      if (generation == _currentSessionGeneration) {
        _status[cacheKey] = SyncStatus.localOnly;
        return getCompletedModules(
          userId,
          pathway: pathway,
          sessionGeneration: generation,
        );
      }
      return <String>{};
    }

    final hasToken = await _effectiveStorage.hasToken();
    if (generation != _currentSessionGeneration) {
      return <String>{};
    }
    if (!hasToken) {
      _status[cacheKey] = SyncStatus.localOnly;
      return getCompletedModules(
        userId,
        pathway: pathway,
        sessionGeneration: generation,
      );
    }

    // 1. Fetch authoritative server progress (GET /api/progress/:pathwayId)
    Set<String>? authoritativeServerSet;
    bool isServerLocked = false;
    try {
      final res = await _effectiveClient.getProgress(pathwayId: pathway);
      if (generation != _currentSessionGeneration) {
        return <String>{};
      }

      if (res['success'] == true && res['completedModules'] is List) {
        authoritativeServerSet = (res['completedModules'] as List)
            .map((e) => e.toString())
            .toSet();
      }
    } catch (e) {
      if (e is ApiException && e.statusCode == 403) {
        isServerLocked = true;
      }
      debugPrint('[ProgressService] fetchUserProgress GET network error: $e');
    }

    if (generation != _currentSessionGeneration) {
      return <String>{};
    }

    if (isServerLocked) {
      // Pathway is locked on server! Purge any pending changes and return local cached progress.
      _pendingChanges[cacheKey]?.clear();
      await _savePendingToDisk(userId, pathway, sessionGeneration: generation);
      _status[cacheKey] = SyncStatus.synced;
      notifyListeners();
      return getCompletedModules(
        userId,
        pathway: pathway,
        sessionGeneration: generation,
      );
    }

    // Server unreachable or returned error: preserve local progress and mark offline
    if (authoritativeServerSet == null) {
      if (generation == _currentSessionGeneration) {
        _status[cacheKey] = SyncStatus.offline;
        return getCompletedModules(
          userId,
          pathway: pathway,
          sessionGeneration: generation,
        );
      }
      return <String>{};
    }

    // 2. Load all pending desired states
    final pending = _pendingChanges[cacheKey] ?? {};
    var currentServerSet = Set<String>.from(authoritativeServerSet);

    // 3-8. Reconcile pending local changes sequentially using safe GET-first logic
    if (pending.isNotEmpty) {
      final pendingEntries = Map<String, bool>.from(pending).entries.toList();
      final curriculumList = pathwayModules[pathway.toLowerCase()];
      if (curriculumList != null) {
        pendingEntries.sort((a, b) {
          final idxA = curriculumList.indexOf(a.key);
          final idxB = curriculumList.indexOf(b.key);
          if (idxA != -1 && idxB != -1) return idxA.compareTo(idxB);
          if (idxA != -1) return -1;
          if (idxB != -1) return 1;
          return a.key.compareTo(b.key);
        });
      }

      for (final entry in pendingEntries) {
        final moduleId = entry.key;
        final desiredState = entry.value;

        if (generation != _currentSessionGeneration) {
          return <String>{};
        }

        // 3. Compare pending module's desired state with current server state
        final bool serverAlreadyMatches =
            currentServerSet.contains(moduleId) == desiredState;

        // 4. If they already match, remove that pending entry
        if (serverAlreadyMatches) {
          pending.remove(moduleId);
          continue;
        }

        // Validate sequential unlocking rule:
        // If desiredState is true and module is locked based on currentServerSet, discard the pending mutation.
        if (desiredState &&
            !isModuleUnlocked(
              pathway: pathway,
              moduleId: moduleId,
              completedModules: currentServerSet,
            )) {
          debugPrint(
            '[ProgressService] Discarding invalid out-of-order pending completion for $moduleId',
          );
          pending.remove(moduleId);
          continue;
        }

        // 5. If they differ, issue exactly one toggle request for that module
        bool toggleConfirmed = false;
        try {
          final toggleRes = await _effectiveClient.toggleProgress(
            moduleId: moduleId,
            pathwayId: pathway,
          );

          if (generation != _currentSessionGeneration) {
            return <String>{};
          }

          // 6. Validate the response including actual completedModules state
          if (toggleRes['success'] == true &&
              toggleRes['completedModules'] is List) {
            final updatedServerSet = (toggleRes['completedModules'] as List)
                .map((e) => e.toString())
                .toSet();
            currentServerSet = updatedServerSet;

            // Confirm that server state actually matches desiredState
            if (updatedServerSet.contains(moduleId) == desiredState) {
              pending.remove(moduleId);
              toggleConfirmed = true;
            }
          }
        } catch (toggleErr) {
          debugPrint(
            '[ProgressService] Reconciliation toggle error ($toggleErr).',
          );
        }

        if (generation != _currentSessionGeneration) {
          return <String>{};
        }

        // 7. If result is uncertain or toggle didn't confirm, perform safe GET
        if (!toggleConfirmed) {
          try {
            final getRes =
                await _effectiveClient.getProgress(pathwayId: pathway);
            if (generation != _currentSessionGeneration) {
              return <String>{};
            }

            if (getRes['success'] == true &&
                getRes['completedModules'] is List) {
              final verifiedServerSet = (getRes['completedModules'] as List)
                  .map((e) => e.toString())
                  .toSet();
              currentServerSet = verifiedServerSet;

              // 8. Remove pending entry only after server is confirmed to match
              if (verifiedServerSet.contains(moduleId) == desiredState) {
                pending.remove(moduleId);
              }
            }
          } catch (getErr) {
            debugPrint(
              '[ProgressService] Reconciliation verification GET failed: $getErr',
            );
          }
        }
      }
    }

    if (generation != _currentSessionGeneration) {
      return <String>{};
    }

    // Save pruned pending changes to persistent storage
    await _savePendingToDisk(
      userId,
      pathway,
      sessionGeneration: generation,
    );
    if (generation != _currentSessionGeneration) {
      return <String>{};
    }

    // Compute active reconciled set by replaying any remaining pending changes onto currentServerSet
    final reconciledSet = Set<String>.from(currentServerSet);
    for (final entry in pending.entries) {
      if (entry.value) {
        reconciledSet.add(entry.key);
      } else {
        reconciledSet.remove(entry.key);
      }
    }

    if (generation != _currentSessionGeneration) {
      return <String>{};
    }

    _cache[cacheKey] = reconciledSet;
    _status[cacheKey] =
        pending.isEmpty ? SyncStatus.synced : SyncStatus.pending;

    await _saveToDisk(
      userId,
      pathway,
      reconciledSet,
      sessionGeneration: generation,
    );
    if (generation != _currentSessionGeneration) {
      return <String>{};
    }
    notifyListeners();

    return reconciledSet;
  }

  /// Safely toggles completion of a module on the backend.
  Future<bool> toggleModuleCompletion(
    String userId,
    String moduleId, {
    String pathway = 'git',
    bool validateSequence = false,
    bool validatePathwayLock = true,
  }) {
    final generation = _currentSessionGeneration;
    return _enqueueMutation<bool>(
      userId: userId,
      action: () async {
        await _ensureLoaded(
          userId,
          pathway,
          sessionGeneration: generation,
        );
        if (generation != _currentSessionGeneration) {
          return false;
        }
        final cacheKey = _getCacheKey(userId, pathway);
        final current = _cache[cacheKey] ?? <String>{};
        final bool wasCompleted = current.contains(moduleId);
        final bool desiredState = !wasCompleted;

        return _executeMutation(
          userId: userId,
          pathway: pathway,
          moduleId: moduleId,
          desiredState: desiredState,
          generation: generation,
          validateSequence: validateSequence,
          validatePathwayLock: validatePathwayLock,
        );
      },
    );
  }

  /// Explicitly sets a module to completed or incomplete.
  ///
  /// Serialized and idempotent:
  /// - If local state matches and no pending change exists, returns immediately without an API request.
  /// - If local state matches but an unresolved pending change exists, triggers safe GET-first reconciliation.
  Future<void> setModuleCompleted(
    String userId,
    String moduleId,
    bool completed, {
    String pathway = 'git',
  }) {
    final generation = _currentSessionGeneration;
    return _enqueueMutation<void>(
      userId: userId,
      action: () async {
        await _ensureLoaded(
          userId,
          pathway,
          sessionGeneration: generation,
        );
        if (generation != _currentSessionGeneration) {
          return;
        }
        final cacheKey = _getCacheKey(userId, pathway);
        final current = _cache[cacheKey] ?? <String>{};
        final bool isCurrentlyCompleted = current.contains(moduleId);
        final bool hasPending =
            _pendingChanges[cacheKey]?.containsKey(moduleId) ?? false;

        // Idempotent: already matches desired state and no pending change remains
        if (isCurrentlyCompleted == completed && !hasPending) {
          return;
        }

        // Local state matches, but an unconfirmed pending change exists:
        // Do NOT send a blind toggle! Reconcile using GET-first logic.
        if (isCurrentlyCompleted == completed && hasPending) {
          await _reconcileSingleModulePending(
            userId: userId,
            pathway: pathway,
            moduleId: moduleId,
            desiredState: completed,
            generation: generation,
          );
          return;
        }

        await _executeMutation(
          userId: userId,
          pathway: pathway,
          moduleId: moduleId,
          desiredState: completed,
          generation: generation,
        );
      },
    );
  }

  /// Reconciles a single pending module when local state already matches desiredState.
  Future<void> _reconcileSingleModulePending({
    required String userId,
    required String pathway,
    required String moduleId,
    required bool desiredState,
    required int generation,
  }) async {
    if (generation != _currentSessionGeneration) return;

    bool serverOnline = false;
    try {
      final getRes = await _effectiveClient.getProgress(pathwayId: pathway);
      if (generation != _currentSessionGeneration) return;

      if (getRes['success'] == true && getRes['completedModules'] is List) {
        serverOnline = true;
        final serverSet = (getRes['completedModules'] as List)
            .map((e) => e.toString())
            .toSet();

        if (serverSet.contains(moduleId) == desiredState) {
          // Server already matches!
          await _reconcileServerResponse(
            userId: userId,
            pathway: pathway,
            moduleId: moduleId,
            desiredState: desiredState,
            serverSet: serverSet,
            sessionGeneration: generation,
          );
          return;
        }

        // Server does not match; issue exactly one toggle
        final toggleRes = await _effectiveClient.toggleProgress(
          moduleId: moduleId,
          pathwayId: pathway,
        );
        if (generation != _currentSessionGeneration) return;

        if (toggleRes['success'] == true &&
            toggleRes['completedModules'] is List) {
          final updatedSet = (toggleRes['completedModules'] as List)
              .map((e) => e.toString())
              .toSet();
          if (updatedSet.contains(moduleId) == desiredState) {
            await _reconcileServerResponse(
              userId: userId,
              pathway: pathway,
              moduleId: moduleId,
              desiredState: desiredState,
              serverSet: updatedSet,
              sessionGeneration: generation,
            );
            return;
          }
        }
      }
    } catch (e) {
      debugPrint('[ProgressService] _reconcileSingleModulePending error: $e');
    }

    if (generation == _currentSessionGeneration) {
      final cacheKey = _getCacheKey(userId, pathway);
      _status[cacheKey] =
          serverOnline ? SyncStatus.pending : SyncStatus.offline;
      notifyListeners();
    }
  }

  /// Internal worker executing the mutation inside the serialized queue.
  Future<bool> _executeMutation({
    required String userId,
    required String pathway,
    required String moduleId,
    required bool desiredState,
    required int generation,
    bool validateSequence = false,
    bool validatePathwayLock = true,
  }) async {
    final cacheKey = _getCacheKey(userId, pathway);
    final current = Set<String>.from(_cache[cacheKey] ?? <String>{});

    if (validateSequence && desiredState) {
      if (!isModuleUnlocked(
        pathway: pathway,
        moduleId: moduleId,
        completedModules: current,
      )) {
        debugPrint(
          '[ProgressService] Cannot complete locked module: $moduleId',
        );
        _pendingChanges[cacheKey]?.remove(moduleId);
        return false;
      }
    }

    // Pathway-level unlocking check
    if (validatePathwayLock && desiredState && !isPathwayUnlocked(pathway: pathway, userId: userId)) {
      debugPrint('[ProgressService] Cannot complete module in locked pathway: $pathway');
      _pendingChanges[cacheKey]?.remove(moduleId);
      return false;
    }

    // 1. Explicitly record pending local change
    _pendingChanges.putIfAbsent(cacheKey, () => {})[moduleId] = desiredState;

    // 2. Immediate optimistic update to in-memory cache
    if (desiredState) {
      current.add(moduleId);
    } else {
      current.remove(moduleId);
      final list = pathwayModules[pathway.toLowerCase()];
      if (list != null) {
        final idx = list.indexOf(moduleId);
        if (idx != -1) {
          final subsequent = list.sublist(idx + 1).toSet();
          current.removeWhere((id) => subsequent.contains(id));
          _pendingChanges[cacheKey]?.removeWhere((k, v) => subsequent.contains(k));
        }
      }
    }
    _cache[cacheKey] = current;
    _status[cacheKey] = SyncStatus.pending;
    notifyListeners();

    await _savePendingToDisk(
      userId,
      pathway,
      sessionGeneration: generation,
    );
    if (generation != _currentSessionGeneration) {
      return desiredState;
    }
    await _saveToDisk(
      userId,
      pathway,
      current,
      sessionGeneration: generation,
    );

    // Abort if session was invalidated during disk save
    if (generation != _currentSessionGeneration) {
      return desiredState;
    }

    // 3. Guest / unauthenticated users store progress locally only
    if (userId.trim().isEmpty || userId == 'guest') {
      if (generation != _currentSessionGeneration) {
        return desiredState;
      }
      _status[cacheKey] = SyncStatus.localOnly;
      _pendingChanges[cacheKey]?.remove(moduleId);
      await _savePendingToDisk(
        userId,
        pathway,
        sessionGeneration: generation,
      );
      if (generation != _currentSessionGeneration) {
        return desiredState;
      }
      notifyListeners();
      return desiredState;
    }

    final hasToken = await _effectiveStorage.hasToken();
    if (generation != _currentSessionGeneration) {
      return desiredState;
    }
    if (!hasToken) {
      _status[cacheKey] = SyncStatus.localOnly;
      _pendingChanges[cacheKey]?.remove(moduleId);
      await _savePendingToDisk(
        userId,
        pathway,
        sessionGeneration: generation,
      );
      if (generation != _currentSessionGeneration) {
        return desiredState;
      }
      notifyListeners();
      return desiredState;
    }

    // 4. Commit mutation to backend API
    bool toggleConfirmed = false;
    try {
      final res = await _effectiveClient.toggleProgress(
        moduleId: moduleId,
        pathwayId: pathway,
      );

      // Session guard: if user logged out while toggle was in-flight, ignore response
      if (generation != _currentSessionGeneration) {
        debugPrint(
          '[ProgressService] Session invalidated while toggle was in-flight. Ignoring response.',
        );
        return desiredState;
      }

      // Explicit validation of toggle response including checking actual desired state
      if (res['success'] == true && res['completedModules'] is List) {
        final serverSet = (res['completedModules'] as List)
            .map((e) => e.toString())
            .toSet();

        if (serverSet.contains(moduleId) == desiredState) {
          await _reconcileServerResponse(
            userId: userId,
            pathway: pathway,
            moduleId: moduleId,
            desiredState: desiredState,
            serverSet: serverSet,
            sessionGeneration: generation,
          );
          toggleConfirmed = true;
          return desiredState;
        } else {
          debugPrint(
            '[ProgressService] Toggle response contradicted desiredState (server: $serverSet, desired: $desiredState)',
          );
        }
      } else {
        debugPrint(
          '[ProgressService] Unsuccessful or malformed toggle response: $res',
        );
      }
    } catch (err) {
      debugPrint(
        '[ProgressService] Toggle error ($err). Attempting safe GET reconciliation...',
      );
      if (err is ApiException && (err.statusCode == 400 || err.statusCode == 403)) {
        debugPrint(
          '[ProgressService] Server rejected toggle for $moduleId with 400 Bad Request. Reverting local state.',
        );
        _pendingChanges[cacheKey]?.remove(moduleId);
        await _savePendingToDisk(userId, pathway, sessionGeneration: generation);
        try {
          final getRes = await _effectiveClient.getProgress(pathwayId: pathway);
          if (generation == _currentSessionGeneration &&
              getRes['success'] == true &&
              getRes['completedModules'] is List) {
            final serverSet = (getRes['completedModules'] as List)
                .map((e) => e.toString())
                .toSet();
            _cache[cacheKey] = serverSet;
            _status[cacheKey] = SyncStatus.synced;
            await _saveToDisk(userId, pathway, serverSet, sessionGeneration: generation);
            notifyListeners();
          }
        } catch (_) {}
        return false;
      }
    }

    // Session check before attempting any fallback GET request
    if (generation != _currentSessionGeneration) {
      return desiredState;
    }

    // 5. Outcome is uncertain — NEVER retry toggle! Safely query current server state
    if (!toggleConfirmed) {
      bool getSucceeded = false;
      try {
        final getRes = await _effectiveClient.getProgress(pathwayId: pathway);
        if (generation == _currentSessionGeneration &&
            getRes['success'] == true &&
            getRes['completedModules'] is List) {
          getSucceeded = true;
          final serverSet = (getRes['completedModules'] as List)
              .map((e) => e.toString())
              .toSet();

          if (serverSet.contains(moduleId) == desiredState) {
            await _reconcileServerResponse(
              userId: userId,
              pathway: pathway,
              moduleId: moduleId,
              desiredState: desiredState,
              serverSet: serverSet,
              sessionGeneration: generation,
            );
            return desiredState;
          }
        }
      } catch (getErr) {
        debugPrint(
          '[ProgressService] Safe GET reconciliation also failed: $getErr',
        );
      }

      // 6. Reconciliation also failed: keep optimistic local change, mark status
      if (generation == _currentSessionGeneration) {
        _status[cacheKey] =
            getSucceeded ? SyncStatus.pending : SyncStatus.offline;
        notifyListeners();
      }
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
    required int sessionGeneration,
  }) async {
    if (sessionGeneration != _currentSessionGeneration) {
      return; // Do not mutate state if session is no longer active
    }

    final cacheKey = _getCacheKey(userId, pathway);
    final pending = _pendingChanges[cacheKey] ?? {};

    // Remove from pending only if server response actually matches desiredState
    if (serverSet.contains(moduleId) == desiredState &&
        pending[moduleId] == desiredState) {
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

    if (sessionGeneration != _currentSessionGeneration) {
      return;
    }

    _cache[cacheKey] = reconciledSet;
    _status[cacheKey] =
        pending.isEmpty ? SyncStatus.synced : SyncStatus.pending;
    await _saveToDisk(
      userId,
      pathway,
      reconciledSet,
      sessionGeneration: sessionGeneration,
    );
    if (sessionGeneration != _currentSessionGeneration) {
      return;
    }
    await _savePendingToDisk(
      userId,
      pathway,
      sessionGeneration: sessionGeneration,
    );
    if (sessionGeneration != _currentSessionGeneration) {
      return;
    }
    notifyListeners();
  }

  Future<void> _saveToDisk(
    String userId,
    String pathway,
    Set<String> moduleIds, {
    int? sessionGeneration,
  }) {
    final generation = sessionGeneration ?? _currentSessionGeneration;
    if (generation != _currentSessionGeneration) {
      return Future.value();
    }

    final key = _getStorageKey(userId, pathway);
    final raw = json.encode(moduleIds.toList());

    return _runWithKeyLock(key, generation, () async {
      await _effectiveStorage.write(key, raw);
    });
  }

  @visibleForTesting
  Future<void> loadPendingFromDisk(
    String userId,
    String pathway, {
    int? sessionGeneration,
  }) =>
      _loadPendingFromDisk(
        userId,
        pathway,
        sessionGeneration: sessionGeneration,
      );

  @visibleForTesting
  Future<void> savePendingToDisk(
    String userId,
    String pathway, {
    int? sessionGeneration,
  }) =>
      _savePendingToDisk(
        userId,
        pathway,
        sessionGeneration: sessionGeneration,
      );

  @visibleForTesting
  Future<void> saveToDisk(
    String userId,
    String pathway,
    Set<String> moduleIds, {
    int? sessionGeneration,
  }) =>
      _saveToDisk(
        userId,
        pathway,
        moduleIds,
        sessionGeneration: sessionGeneration,
      );

  @visibleForTesting
  void recordPendingChangeForTesting(
    String userId,
    String pathway,
    String moduleId,
    bool desiredState,
  ) {
    final cacheKey = _getCacheKey(userId, pathway);
    _pendingChanges.putIfAbsent(cacheKey, () => {})[moduleId] = desiredState;
  }

  /// Clears in-memory progress cache, pending changes, and sync state, and invalidates active operations.
  void clearCache() {
    _currentSessionGeneration++;

    // Immediately cancel and complete all active mutations across all sessions
    for (final activeSet in _activeSessionMutations.values) {
      for (final item in activeSet) {
        if (!item.completer.isCompleted) {
          item.completer.completeError(
            StateError('Operation cancelled due to logout/session change'),
          );
        }
      }
    }
    _activeSessionMutations.clear();

    // Invalidate and cancel all pending mutations across all session queues
    for (final queue in _sessionQueues.values) {
      for (final item in queue) {
        if (!item.completer.isCompleted) {
          item.completer.completeError(
            StateError('Operation cancelled due to logout/session change'),
          );
        }
      }
      queue.clear();
    }
    _sessionQueues.clear();

    _cache.clear();
    _pendingChanges.clear();
    _status.clear();
    notifyListeners();
  }
}

class _InMemoryStorageService implements ISecureStorageService {
  String? _token;
  int _tokenVersion = 0;
  final Map<String, String> _map = {};

  @override
  int get tokenVersion => _tokenVersion;

  @override
  Future<String?> getToken() async => _token;

  @override
  Future<void> saveToken(String token) async {
    _tokenVersion++;
    _token = token;
  }

  @override
  Future<void> deleteToken() async {
    _tokenVersion++;
    _token = null;
  }

  @override
  Future<bool> hasToken() async => _token != null && _token!.isNotEmpty;

  @override
  Future<String?> read(String key) async => _map[key];

  @override
  Future<void> write(String key, String value) async => _map[key] = value;

  @override
  Future<void> delete(String key) async => _map.remove(key);
}
