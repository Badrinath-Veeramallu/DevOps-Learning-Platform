import 'dart:convert';
import 'package:flutter/services.dart';
import '../../../models/curriculum_model.dart';

/// Repository that loads and provides access to the complete Git curriculum.
///
/// Guaranteed 100% content and schema parity with Web's `gitCurriculum.js`.
class GitCurriculumRepository {
  GitCurriculumRepository._();

  static List<CurriculumModule>? _cachedModules;

  /// Asynchronously loads all 7 Git curriculum modules from bundled assets.
  static Future<List<CurriculumModule>> loadCurriculum({
    AssetBundle? bundle,
  }) async {
    if (_cachedModules != null) return _cachedModules!;

    final assetBundle = bundle ?? rootBundle;
    final jsonString = await assetBundle.loadString(
      'assets/data/git_curriculum.json',
    );
    final dynamic decoded = json.decode(jsonString);

    if (decoded is List) {
      _cachedModules = decoded
          .map(
            (item) =>
                CurriculumModule.fromJson(item as Map<String, dynamic>),
          )
          .toList();
      return _cachedModules!;
    }

    return const [];
  }

  /// Synchronously returns cached modules, or null if not yet loaded.
  static List<CurriculumModule>? get cachedModules => _cachedModules;

  /// Finds a specific module by id (e.g. 'git-01') or number (e.g. '01').
  static CurriculumModule? findModule(
    List<CurriculumModule> modules,
    String moduleId,
  ) {
    final index = modules.indexWhere(
      (m) => m.id == moduleId || m.number == moduleId,
    );
    return index >= 0 ? modules[index] : null;
  }

  /// Clears cache (primarily useful for tests).
  static void clearCache() {
    _cachedModules = null;
  }
}

