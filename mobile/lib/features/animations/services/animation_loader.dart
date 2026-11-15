import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../../models/animation_model.dart';

/// Foundation service for loading and indexing subtopic animations across pathways (Git, Docker, etc.).
///
/// Guaranteed 100% parity with Web's `findAnimation` lookup algorithm.
class AnimationLoader {
  AnimationLoader._();

  static final Map<String, List<AnimationModule>> _cachedPathwayModules = {};
  static final Map<String, Map<String, SubtopicAnimation>> _idIndexByPathway = {};
  static final Map<String, Map<String, SubtopicAnimation>> _titleIndexByPathway = {};

  static String _cacheKey(String pathway, {bool isMobile = false}) {
    final norm = pathway.toLowerCase();
    return (isMobile && norm == 'cicd') ? '${norm}_mobile' : norm;
  }

  /// Loads all animation modules for a given pathway from bundled JSON asset.
  static Future<List<AnimationModule>> loadAnimations({
    String pathway = 'git',
    bool isMobile = false,
    AssetBundle? bundle,
  }) async {
    final normalizedPathway = pathway.toLowerCase();
    final key = _cacheKey(normalizedPathway, isMobile: isMobile);
    if (_cachedPathwayModules.containsKey(key)) {
      return _cachedPathwayModules[key]!;
    }

    final assetBundle = bundle ?? rootBundle;
    final String assetPath;
    switch (normalizedPathway) {
      case 'git':
        assetPath = 'assets/data/git_animations.json';
        break;
      case 'docker':
        assetPath = 'assets/data/docker_animations.json';
        break;
      case 'linux':
        assetPath = 'assets/data/linux_animations.json';
        break;
      case 'cicd':
        assetPath = isMobile
            ? 'assets/data/cicd_animations.mobile.json'
            : 'assets/data/cicd_animations.json';
        break;
      default:
        throw ArgumentError.value(
          pathway,
          'pathway',
          'Unsupported animation pathway "$pathway". Supported pathways are git, docker, linux, cicd.',
        );
    }

    final jsonString = await assetBundle.loadString(assetPath);
    final Map<String, dynamic> decoded =
        json.decode(jsonString) as Map<String, dynamic>;

    final rawModules = decoded['modules'] as List? ?? [];
    final List<AnimationModule> modules = rawModules
        .map((m) => AnimationModule.fromJson(m as Map<String, dynamic>))
        .toList();

    _cachedPathwayModules[key] = modules;
    _buildIndex(key, modules);
    debugPrint(
      '[AnimationLoader] Successfully loaded ${modules.length} modules for pathway "$normalizedPathway" (isMobile: $isMobile)',
    );
    return modules;
  }

  static void _buildIndex(String key, List<AnimationModule> modules) {
    final idMap = <String, SubtopicAnimation>{};
    final titleMap = <String, SubtopicAnimation>{};

    for (final m in modules) {
      for (final s in m.subtopics) {
        idMap[s.id] = s;
        titleMap[_normalize(s.title)] = s;
      }
    }

    _idIndexByPathway[key] = idMap;
    _titleIndexByPathway[key] = titleMap;
  }

  static String _normalize(String input) {
    return input.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
  }

  /// Finds an animation by subtopic id (e.g. "01.1", "04.5") or by normalized title within a pathway.
  static SubtopicAnimation? findAnimation(
    String key, {
    String pathway = 'git',
    bool isMobile = false,
  }) {
    final primaryKey = _cacheKey(pathway, isMobile: isMobile);
    final fallbackKey = _cacheKey(pathway, isMobile: false);

    SubtopicAnimation? match = _lookupInIndex(primaryKey, key);
    if (match == null && isMobile && primaryKey != fallbackKey) {
      match = _lookupInIndex(fallbackKey, key);
    }
    return match;
  }

  static SubtopicAnimation? _lookupInIndex(String cacheKey, String key) {
    final idMap = _idIndexByPathway[cacheKey];
    if (idMap != null) {
      if (idMap.containsKey(key)) {
        return idMap[key];
      }
      // Padded / unpadded key fallback (e.g. "1.1" <-> "01.1")
      final parts = key.split('.');
      if (parts.length == 2) {
        final mod = parts[0];
        final sec = parts[1];
        if (mod.length == 1) {
          final padded = '0$mod.$sec';
          if (idMap.containsKey(padded)) return idMap[padded];
        } else if (mod.startsWith('0') && mod.length == 2) {
          final unpadded = '${mod.substring(1)}.$sec';
          if (idMap.containsKey(unpadded)) return idMap[unpadded];
        }
      }
    }
    final norm = _normalize(key);
    final titleMap = _titleIndexByPathway[cacheKey];
    if (titleMap != null) {
      if (titleMap.containsKey(norm)) {
        return titleMap[norm];
      }
      final stripped = norm.replaceFirst(RegExp(r'^\d+\s+'), '');
      if (stripped != norm && titleMap.containsKey(stripped)) {
        return titleMap[stripped];
      }
    }
    return null;
  }

  /// Clears in-memory cache for a pathway or all pathways (primarily useful for tests).
  static void clearCache({String? pathway}) {
    if (pathway != null) {
      final desktopKey = _cacheKey(pathway, isMobile: false);
      final mobileKey = _cacheKey(pathway, isMobile: true);
      _cachedPathwayModules.remove(desktopKey);
      _cachedPathwayModules.remove(mobileKey);
      _idIndexByPathway.remove(desktopKey);
      _idIndexByPathway.remove(mobileKey);
      _titleIndexByPathway.remove(desktopKey);
      _titleIndexByPathway.remove(mobileKey);
    } else {
      _cachedPathwayModules.clear();
      _idIndexByPathway.clear();
      _titleIndexByPathway.clear();
    }
  }

  /// Sets cached modules and builds index directly (useful for tests).
  static void setCachedModules(
    List<AnimationModule> modules, {
    String pathway = 'git',
    bool isMobile = false,
  }) {
    final key = _cacheKey(pathway, isMobile: isMobile);
    _cachedPathwayModules[key] = modules;
    _buildIndex(key, modules);
  }

  /// Synchronously returns cached modules for a pathway, or null if not yet loaded.
  static List<AnimationModule>? cachedModules({
    String pathway = 'git',
    bool isMobile = false,
  }) =>
      _cachedPathwayModules[_cacheKey(pathway, isMobile: isMobile)];
}
