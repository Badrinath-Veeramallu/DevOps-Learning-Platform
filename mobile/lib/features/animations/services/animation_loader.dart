import 'dart:convert';
import 'package:flutter/services.dart';
import '../../../models/animation_model.dart';

/// Foundation service for loading and indexing Git subtopic animations.
///
/// Guaranteed 100% parity with Web's `findAnimation` lookup algorithm.
class AnimationLoader {
  AnimationLoader._();

  static List<AnimationModule>? _cachedModules;
  static Map<String, SubtopicAnimation>? _idIndex;
  static Map<String, SubtopicAnimation>? _normalizedTitleIndex;

  /// Loads all 7 modules and 43 subtopics from bundled JSON asset.
  static Future<List<AnimationModule>> loadAnimations({
    AssetBundle? bundle,
  }) async {
    if (_cachedModules != null) return _cachedModules!;

    final assetBundle = bundle ?? rootBundle;
    final jsonString = await assetBundle.loadString(
      'assets/data/git_animations.json',
    );
    final Map<String, dynamic> decoded =
        json.decode(jsonString) as Map<String, dynamic>;

    final rawModules = decoded['modules'] as List? ?? [];
    final List<AnimationModule> modules = rawModules
        .map((m) => AnimationModule.fromJson(m as Map<String, dynamic>))
        .toList();

    _cachedModules = modules;
    _buildIndex(modules);
    return modules;
  }

  static void _buildIndex(List<AnimationModule> modules) {
    final idMap = <String, SubtopicAnimation>{};
    final titleMap = <String, SubtopicAnimation>{};

    for (final m in modules) {
      for (final s in m.subtopics) {
        idMap[s.id] = s;
        titleMap[_normalize(s.title)] = s;
      }
    }

    _idIndex = idMap;
    _normalizedTitleIndex = titleMap;
  }

  static String _normalize(String input) {
    return input.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
  }

  /// Finds an animation by subtopic id (e.g. "01.1", "04.5") or by normalized title.
  static SubtopicAnimation? findAnimation(String key) {
    if (_idIndex != null && _idIndex!.containsKey(key)) {
      return _idIndex![key];
    }
    final norm = _normalize(key);
    if (_normalizedTitleIndex != null &&
        _normalizedTitleIndex!.containsKey(norm)) {
      return _normalizedTitleIndex![norm];
    }
    return null;
  }

  /// Clears in-memory cache (primarily useful for tests).
  static void clearCache() {
    _cachedModules = null;
    _idIndex = null;
    _normalizedTitleIndex = null;
  }

  /// Sets cached modules and builds index directly (useful for tests).
  static void setCachedModules(List<AnimationModule> modules) {
    _cachedModules = modules;
    _buildIndex(modules);
  }
}

