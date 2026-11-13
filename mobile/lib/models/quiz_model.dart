/// Data models representing the Final Quiz System across all learning pathways.
library;

class QuizQuestion {
  final String id;
  final String question;
  final List<String> options;

  const QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      id: (json['id'] ?? '').toString(),
      question: (json['question'] ?? '').toString(),
      options: (json['options'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'question': question,
        'options': options,
      };
}

class QuizReviewItem {
  final String id;
  final String question;
  final List<String> options;
  final int? selectedOption;
  final int correctOption;
  final bool isCorrect;
  final String? explanation;

  const QuizReviewItem({
    required this.id,
    required this.question,
    required this.options,
    this.selectedOption,
    required this.correctOption,
    required this.isCorrect,
    this.explanation,
  });

  factory QuizReviewItem.fromJson(Map<String, dynamic> json) {
    return QuizReviewItem(
      id: (json['id'] ?? '').toString(),
      question: (json['question'] ?? '').toString(),
      options: (json['options'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
      selectedOption: json['selectedOption'] as int?,
      correctOption: (json['correctOption'] as num?)?.toInt() ?? 0,
      isCorrect: json['isCorrect'] == true,
      explanation: json['explanation']?.toString(),
    );
  }
}

class QuizResult {
  final String pathwayId;
  final int score;
  final int totalQuestions;
  final int percentage;
  final bool passed;
  final bool hasPassedEver;
  final int bestScore;
  final int attemptsCount;
  final List<QuizReviewItem> review;

  const QuizResult({
    required this.pathwayId,
    required this.score,
    required this.totalQuestions,
    required this.percentage,
    required this.passed,
    required this.hasPassedEver,
    required this.bestScore,
    required this.attemptsCount,
    required this.review,
  });

  factory QuizResult.fromJson(Map<String, dynamic> json) {
    final rawReview = json['review'] as List? ?? [];
    return QuizResult(
      pathwayId: (json['pathwayId'] ?? '').toString(),
      score: (json['score'] as num?)?.toInt() ?? 0,
      totalQuestions: (json['totalQuestions'] as num?)?.toInt() ?? 20,
      percentage: (json['percentage'] as num?)?.toInt() ?? 0,
      passed: json['passed'] == true,
      hasPassedEver: json['hasPassedEver'] == true,
      bestScore: (json['bestScore'] as num?)?.toInt() ?? 0,
      attemptsCount: (json['attemptsCount'] as num?)?.toInt() ?? 0,
      review: rawReview
          .map((r) => QuizReviewItem.fromJson(r as Map<String, dynamic>))
          .toList(),
    );
  }
}

class QuizStatus {
  final String pathwayId;
  final bool isEligible;
  final List<String> missingModules;
  final bool hasPassed;
  final int bestScore;
  final int totalQuestions;
  final int passingScore;
  final int attemptsCount;

  const QuizStatus({
    required this.pathwayId,
    required this.isEligible,
    this.missingModules = const [],
    required this.hasPassed,
    required this.bestScore,
    this.totalQuestions = 20,
    this.passingScore = 10,
    required this.attemptsCount,
  });

  factory QuizStatus.fromJson(Map<String, dynamic> json) {
    return QuizStatus(
      pathwayId: (json['pathwayId'] ?? '').toString(),
      isEligible: json['isEligible'] == true,
      missingModules: (json['missingModules'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
      hasPassed: json['hasPassed'] == true,
      bestScore: (json['bestScore'] as num?)?.toInt() ?? 0,
      totalQuestions: (json['totalQuestions'] as num?)?.toInt() ?? 20,
      passingScore: (json['passingScore'] as num?)?.toInt() ?? 10,
      attemptsCount: (json['attemptsCount'] as num?)?.toInt() ?? 0,
    );
  }
}
