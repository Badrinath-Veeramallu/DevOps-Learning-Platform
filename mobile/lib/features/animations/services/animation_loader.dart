import 'dart:convert';
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

  /// Loads all animation modules for a given pathway from bundled JSON asset.
  static Future<List<AnimationModule>> loadAnimations({
    String pathway = 'git',
    AssetBundle? bundle,
  }) async {
    if (_cachedPathwayModules.containsKey(pathway)) {
      return _cachedPathwayModules[pathway]!;
    }

    final assetBundle = bundle ?? rootBundle;
    final assetPath = pathway == 'docker'
        ? 'assets/data/docker_animations.json'
        : 'assets/data/git_animations.json';

    final jsonString = await assetBundle.loadString(assetPath);
    final Map<String, dynamic> decoded =
        json.decode(jsonString) as Map<String, dynamic>;

    final rawModules = decoded['modules'] as List? ?? [];
    final List<AnimationModule> modules = rawModules
        .map((m) => AnimationModule.fromJson(m as Map<String, dynamic>))
        .toList();

    _cachedPathwayModules[pathway] = modules;
    _buildIndex(pathway, modules);
    return modules;
  }

  static void _buildIndex(String pathway, List<AnimationModule> modules) {
    final idMap = <String, SubtopicAnimation>{};
    final titleMap = <String, SubtopicAnimation>{};

    for (final m in modules) {
      for (final s in m.subtopics) {
        idMap[s.id] = s;
        titleMap[_normalize(s.title)] = s;
      }
    }

    _idIndexByPathway[pathway] = idMap;
    _titleIndexByPathway[pathway] = titleMap;
  }

  static String _normalize(String input) {
    return input.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
  }

  /// Finds an animation by subtopic id (e.g. "01.1", "04.5") or by normalized title within a pathway.
  static SubtopicAnimation? findAnimation(String key, {String pathway = 'git'}) {
    final idMap = _idIndexByPathway[pathway];
    if (idMap != null && idMap.containsKey(key)) {
      return idMap[key];
    }
    final norm = _normalize(key);
    final titleMap = _titleIndexByPathway[pathway];
    if (titleMap != null && titleMap.containsKey(norm)) {
      return titleMap[norm];
    }
    return null;
  }

  /// Clears in-memory cache for a pathway or all pathways (primarily useful for tests).
  static void clearCache({String? pathway}) {
    if (pathway != null) {
      _cachedPathwayModules.remove(pathway);
      _idIndexByPathway.remove(pathway);
      _titleIndexByPathway.remove(pathway);
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
  }) {
    _cachedPathwayModules[pathway] = modules;
    _buildIndex(pathway, modules);
  }

  /// Synchronously returns cached modules for a pathway, or null if not yet loaded.
  static List<AnimationModule>? cachedModules({String pathway = 'git'}) =>
      _cachedPathwayModules[pathway];
}
