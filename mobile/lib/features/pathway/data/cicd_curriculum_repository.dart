import 'package:flutter/services.dart';
import '../../../models/curriculum_model.dart';
import 'curriculum_repository.dart';

/// Repository that loads and provides access to the complete CI/CD curriculum.
///
/// Guaranteed 100% content and schema parity with Web's `cicdCurriculum.js`.
class CicdCurriculumRepository {
  CicdCurriculumRepository._();

  /// Asynchronously loads all 7 CI/CD curriculum modules from bundled assets.
  static Future<List<CurriculumModule>> loadCurriculum({
    AssetBundle? bundle,
  }) {
    return CurriculumRepository.loadCurriculum(
      pathway: 'cicd',
      bundle: bundle,
    );
  }

  /// Synchronously returns cached modules, or null if not yet loaded.
  static List<CurriculumModule>? get cachedModules =>
      CurriculumRepository.cachedModules(pathway: 'cicd');

  /// Finds a specific module by id (e.g. 'cicd-01') or number (e.g. '01').
  static CurriculumModule? findModule(
    List<CurriculumModule> modules,
    String moduleId,
  ) {
    return CurriculumRepository.findModule(modules, moduleId);
  }

  /// Clears cache (primarily useful for tests).
  static void clearCache() {
    CurriculumRepository.clearCache(pathway: 'cicd');
  }

  /// Sets cached modules directly (useful for testing with mock data).
  static void setCachedModules(List<CurriculumModule> modules) {
    CurriculumRepository.setCachedModules(modules, pathway: 'cicd');
  }
}
