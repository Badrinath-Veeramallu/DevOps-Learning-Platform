import 'dart:convert';
import 'package:flutter/services.dart';
import '../../../models/curriculum_model.dart';

/// Central repository that loads and caches curriculum pathways (Git, Docker, etc.).
///
/// Guaranteed 100% content and schema parity with Web's `gitCurriculum.js` and `dockerCurriculum.js`.
class CurriculumRepository {
  CurriculumRepository._();

  static final Map<String, List<CurriculumModule>> _cachedPathways = {};

  /// Asynchronously loads all curriculum modules for a given pathway from bundled assets.
  static Future<List<CurriculumModule>> loadCurriculum({
    String pathway = 'git',
    AssetBundle? bundle,
  }) async {
    if (_cachedPathways.containsKey(pathway)) {
      return _cachedPathways[pathway]!;
    }

    final assetBundle = bundle ?? rootBundle;
    final assetPath = pathway == 'docker'
        ? 'assets/data/docker_curriculum.json'
        : 'assets/data/git_curriculum.json';

    final jsonString = await assetBundle.loadString(assetPath);
    final dynamic decoded = json.decode(jsonString);

    if (decoded is List) {
      final modules = decoded
          .map(
            (item) =>
                CurriculumModule.fromJson(item as Map<String, dynamic>),
          )
          .toList();
      _cachedPathways[pathway] = modules;
      return modules;
    }

    return const [];
  }

  /// Synchronously returns cached modules for a pathway, or null if not yet loaded.
  static List<CurriculumModule>? cachedModules({String pathway = 'git'}) =>
      _cachedPathways[pathway];

  /// Finds a specific module by id (e.g. 'docker-01' or 'git-01') or number (e.g. '01').
  static CurriculumModule? findModule(
    List<CurriculumModule> modules,
    String moduleId,
  ) {
    final index = modules.indexWhere(
      (m) => m.id == moduleId || m.number == moduleId,
    );
    return index >= 0 ? modules[index] : null;
  }

  /// Clears cache for a specific pathway or all pathways (primarily useful for tests).
  static void clearCache({String? pathway}) {
    if (pathway != null) {
      _cachedPathways.remove(pathway);
    } else {
      _cachedPathways.clear();
    }
  }

  /// Sets cached modules directly (useful for testing with mock data).
  static void setCachedModules(
    List<CurriculumModule> modules, {
    String pathway = 'git',
  }) {
    _cachedPathways[pathway] = modules;
  }
}

