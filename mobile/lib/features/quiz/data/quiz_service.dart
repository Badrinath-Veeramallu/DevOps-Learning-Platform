import 'package:flutter/foundation.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_exceptions.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../models/quiz_model.dart';

class QuizPrerequisiteException implements Exception {
  final String message;
  final List<String> missingModules;

  QuizPrerequisiteException(this.message, {this.missingModules = const []});

  @override
  String toString() => message;
}

class QuizService extends ChangeNotifier {
  static final QuizService _instance = QuizService._internal();
  factory QuizService() => _instance;
  QuizService._internal();

  ApiClient? _apiClient;
  final Map<String, QuizStatus> _cachedStatus = {};

  void init({ApiClient? apiClient}) {
    if (apiClient != null) {
      _apiClient = apiClient;
    }
  }

  ApiClient get _client =>
      _apiClient ?? ApiClient(storageService: SecureStorageService());

  QuizStatus? getCachedStatus(String pathwayId) =>
      _cachedStatus[pathwayId.toLowerCase()];

  /// Fetches quiz questions and current user status for a pathway.
  Future<({List<QuizQuestion> questions, QuizStatus status})> fetchQuiz(
    String pathwayId,
  ) async {
    final normPathway = pathwayId.toLowerCase();
    try {
      final res = await _client.getQuiz(pathwayId: normPathway);
      final rawQuestions = res['questions'] as List? ?? [];
      final questions = rawQuestions
          .map((q) => QuizQuestion.fromJson(q as Map<String, dynamic>))
          .toList();

      final statusJson = (res['status'] as Map<String, dynamic>?) ?? {};
      final status = QuizStatus(
        pathwayId: normPathway,
        isEligible: true,
        hasPassed: statusJson['hasPassed'] == true,
        bestScore: (statusJson['bestScore'] as num?)?.toInt() ?? 0,
        attemptsCount: (statusJson['attemptsCount'] as num?)?.toInt() ?? 0,
      );

      _cachedStatus[normPathway] = status;
      notifyListeners();

      return (questions: questions, status: status);
    } on ApiException catch (e) {
      if (e.statusCode == 403) {
        throw QuizPrerequisiteException(
          e.message.isNotEmpty
              ? e.message
              : 'You must complete all pathway modules before taking the final quiz.',
        );
      }
      rethrow;
    }
  }

  /// Submits quiz answers for server-side evaluation.
  Future<QuizResult> submitQuiz({
    required String pathwayId,
    required Map<String, int> answers,
  }) async {
    final normPathway = pathwayId.toLowerCase();
    try {
      final res = await _client.submitQuiz(
        pathwayId: normPathway,
        answers: answers,
      );

      final result = QuizResult.fromJson(res);

      // Update cached status
      _cachedStatus[normPathway] = QuizStatus(
        pathwayId: normPathway,
        isEligible: true,
        hasPassed: result.hasPassedEver,
        bestScore: result.bestScore,
        attemptsCount: result.attemptsCount,
      );

      notifyListeners();
      return result;
    } on ApiException catch (e) {
      if (e.statusCode == 403) {
        throw QuizPrerequisiteException(
          e.message.isNotEmpty
              ? e.message
              : 'Submission rejected: modules must be complete before submitting.',
        );
      }
      rethrow;
    }
  }

  /// Fetches the latest quiz completion status for a pathway.
  Future<QuizStatus> fetchQuizStatus(String pathwayId) async {
    final normPathway = pathwayId.toLowerCase();
    try {
      final res = await _client.getQuizStatus(pathwayId: normPathway);
      final status = QuizStatus.fromJson(res);
      _cachedStatus[normPathway] = status;
      notifyListeners();
      return status;
    } catch (e) {
      debugPrint('[QuizService] fetchQuizStatus error: $e');
      return _cachedStatus[normPathway] ??
          QuizStatus(
            pathwayId: normPathway,
            isEligible: false,
            hasPassed: false,
            bestScore: 0,
            attemptsCount: 0,
          );
    }
  }

  void clearCache() {
    _cachedStatus.clear();
    notifyListeners();
  }
}
