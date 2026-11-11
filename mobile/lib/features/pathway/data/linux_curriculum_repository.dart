import 'package:flutter/services.dart';
import '../../../models/curriculum_model.dart';
import 'curriculum_repository.dart';

/// Repository that loads and provides access to the complete Linux curriculum.
///
/// Guaranteed 100% content and schema parity with Web's `linuxCurriculum.js`.
class LinuxCurriculumRepository {
  LinuxCurriculumRepository._();

  /// Asynchronously loads all 6 Linux curriculum modules from bundled assets.
  static Future<List<CurriculumModule>> loadCurriculum({
    AssetBundle? bundle,
  }) {
    return CurriculumRepository.loadCurriculum(
      pathway: 'linux',
      bundle: bundle,
    );
  }

  /// Synchronously returns cached modules, or null if not yet loaded.
  static List<CurriculumModule>? get cachedModules =>
      CurriculumRepository.cachedModules(pathway: 'linux');

  /// Finds a specific module by id (e.g. 'linux-01') or number (e.g. '01').
  static CurriculumModule? findModule(
    List<CurriculumModule> modules,
    String moduleId,
  ) {
    return CurriculumRepository.findModule(modules, moduleId);
  }

  /// Clears cache (primarily useful for tests).
  static void clearCache() {
    CurriculumRepository.clearCache(pathway: 'linux');
  }

  /// Sets cached modules directly (useful for testing with mock data).
  static void setCachedModules(List<CurriculumModule> modules) {
    CurriculumRepository.setCachedModules(modules, pathway: 'linux');
  }
}

