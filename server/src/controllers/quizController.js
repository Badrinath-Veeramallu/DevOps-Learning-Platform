const Progress = require("../models/Progress");
const QuizProgress = require("../models/QuizProgress");
const QuizAttempt = require("../models/QuizAttempt");
const { logActivity } = require("../utils/activityLogger");
const {
  PATHWAY_PREREQUISITES,
  PASSING_SCORE,
  TOTAL_QUESTIONS_PER_QUIZ,
  getSanitizedQuestions,
  evaluateQuiz,
} = require("../data/quizQuestions");

/**
 * Checks if a user has completed all required curriculum modules for a pathway.
 */
async function checkPathwayCompletion(userId, pathwayId) {
  const normPathway = (pathwayId || "").toLowerCase();
  const requiredModules = PATHWAY_PREREQUISITES[normPathway];
  if (!requiredModules) {
    return {
      isValidPathway: false,
      isCompleted: false,
      missingModules: [],
      requiredModules: [],
      completedModules: [],
    };
  }

  const progress = await Progress.findOne({ userId, pathwayId: normPathway });
  const completedModules = progress ? progress.completedModules || [] : [];
  const completedSet = new Set(completedModules);
  const missingModules = requiredModules.filter((m) => !completedSet.has(m));

  return {
    isValidPathway: true,
    isCompleted: missingModules.length === 0,
    missingModules,
    requiredModules,
    completedModules,
  };
}

/**
 * GET /api/quiz/:pathwayId
 * Fetches sanitized quiz questions (without answers) if prerequisites are met.
 */
async function getQuiz(req, res) {
  try {
    const pathwayId = (req.params.pathwayId || "git").toLowerCase();
    const userId = req.user._id;

    const questions = getSanitizedQuestions(pathwayId);
    if (!questions) {
      return res.status(404).json({
        success: false,
        message: `Pathway "${pathwayId}" not found or has no quiz configured.`,
      });
    }

    // Check completion prerequisite
    const prereq = await checkPathwayCompletion(userId, pathwayId);
    if (!prereq.isCompleted) {
      return res.status(403).json({
        success: false,
        prerequisiteNotMet: true,
        message:
          "You must complete all modules in this learning pathway before taking the final quiz.",
        pathwayId,
        missingModules: prereq.missingModules,
        requiredModules: prereq.requiredModules,
        completedModules: prereq.completedModules,
      });
    }

    // Fetch existing quiz progress
    let quizProgress = await QuizProgress.findOne({ userId, pathwayId });
    if (!quizProgress) {
      quizProgress = {
        hasPassed: false,
        bestScore: 0,
        attemptsCount: 0,
        lastAttemptAt: null,
      };
    }

    return res.status(200).json({
      success: true,
      pathwayId,
      totalQuestions: TOTAL_QUESTIONS_PER_QUIZ,
      passingScore: PASSING_SCORE,
      questions,
      status: {
        hasPassed: quizProgress.hasPassed,
        bestScore: quizProgress.bestScore,
        attemptsCount: quizProgress.attemptsCount,
        lastAttemptAt: quizProgress.lastAttemptAt,
      },
    });
  } catch (err) {
    console.error("Error fetching quiz:", err);
    return res.status(500).json({
      success: false,
      message: "Failed to fetch quiz.",
    });
  }
}

/**
 * POST /api/quiz/:pathwayId/submit
 * Evaluates submitted answers on the backend, updates QuizProgress, and saves attempt history.
 */
async function submitQuiz(req, res) {
  try {
    const pathwayId = (req.params.pathwayId || "git").toLowerCase();
    const userId = req.user._id;
    const { answers } = req.body;

    if (!answers || typeof answers !== "object") {
      return res.status(400).json({
        success: false,
        message: "Answers payload must be an object of { [questionId]: selectedOptionIndex }.",
      });
    }

    // Strict Prerequisite verification
    const prereq = await checkPathwayCompletion(userId, pathwayId);
    if (!prereq.isCompleted) {
      return res.status(403).json({
        success: false,
        prerequisiteNotMet: true,
        message:
          "Quiz submission rejected: all pathway modules must be verified completed before submitting answers.",
        missingModules: prereq.missingModules,
      });
    }

    // Evaluate answers strictly on the server
    const evaluation = evaluateQuiz(pathwayId, answers);

    // Save individual attempt history
    const attempt = await QuizAttempt.create({
      userId,
      pathwayId,
      score: evaluation.score,
      totalQuestions: evaluation.totalQuestions,
      percentage: evaluation.percentage,
      passed: evaluation.passed,
      answers,
    });

    // Fetch or initialize aggregate QuizProgress
    let quizProgress = await QuizProgress.findOne({ userId, pathwayId });
    const wasAlreadyPassed = quizProgress ? quizProgress.hasPassed : false;
    const isNowPassed = wasAlreadyPassed || evaluation.passed; // PRESERVE PREVIOUS PASS RESULT!

    if (!quizProgress) {
      quizProgress = new QuizProgress({
        userId,
        pathwayId,
        hasPassed: isNowPassed,
        bestScore: evaluation.score,
        totalQuestions: evaluation.totalQuestions,
        attemptsCount: 1,
        firstPassedAt: evaluation.passed ? new Date() : null,
        lastAttemptAt: new Date(),
        latestAttemptId: attempt._id,
      });
    } else {
      quizProgress.attemptsCount += 1;
      quizProgress.lastAttemptAt = new Date();
      quizProgress.latestAttemptId = attempt._id;
      quizProgress.bestScore = Math.max(quizProgress.bestScore || 0, evaluation.score);
      quizProgress.hasPassed = isNowPassed;

      if (!wasAlreadyPassed && evaluation.passed) {
        quizProgress.firstPassedAt = new Date();
      }
    }

    await quizProgress.save();

    // Log quiz_passed activity if passed for the first time
    if (!wasAlreadyPassed && evaluation.passed) {
      await logActivity(userId, "quiz_passed", {
        pathwayId,
        score: evaluation.score,
        totalQuestions: evaluation.totalQuestions,
        percentage: evaluation.percentage,
      });
    }

    return res.status(200).json({
      success: true,
      pathwayId,
      attemptId: attempt._id,
      score: evaluation.score,
      totalQuestions: evaluation.totalQuestions,
      percentage: evaluation.percentage,
      passed: evaluation.passed,
      hasPassedEver: quizProgress.hasPassed,
      bestScore: quizProgress.bestScore,
      attemptsCount: quizProgress.attemptsCount,
      review: evaluation.review,
    });
  } catch (err) {
    console.error("Error evaluating quiz:", err);
    return res.status(500).json({
      success: false,
      message: "Failed to evaluate quiz submission.",
    });
  }
}

/**
 * GET /api/quiz/:pathwayId/status
 * Fetches current quiz completion status and eligibility for the authenticated user.
 */
async function getQuizStatus(req, res) {
  try {
    const pathwayId = (req.params.pathwayId || "git").toLowerCase();
    const userId = req.user._id;

    const prereq = await checkPathwayCompletion(userId, pathwayId);
    const quizProgress = await QuizProgress.findOne({ userId, pathwayId });

    return res.status(200).json({
      success: true,
      pathwayId,
      isEligible: prereq.isCompleted,
      missingModules: prereq.missingModules,
      hasPassed: quizProgress ? quizProgress.hasPassed : false,
      bestScore: quizProgress ? quizProgress.bestScore : 0,
      totalQuestions: TOTAL_QUESTIONS_PER_QUIZ,
      passingScore: PASSING_SCORE,
      attemptsCount: quizProgress ? quizProgress.attemptsCount : 0,
      firstPassedAt: quizProgress ? quizProgress.firstPassedAt : null,
      lastAttemptAt: quizProgress ? quizProgress.lastAttemptAt : null,
    });
  } catch (err) {
    console.error("Error fetching quiz status:", err);
    return res.status(500).json({
      success: false,
      message: "Failed to fetch quiz status.",
    });
  }
}

/**
 * GET /api/quiz/:pathwayId/fast-track
 * Returns quiz questions WITHOUT requiring prerequisite module completion.
 * Respects pathway-level progression locking.
 */
async function getFastTrackQuiz(req, res) {
  try {
    const pathwayId = (req.params.pathwayId || "git").toLowerCase();
    const userId = req.user._id;

    const questions = getSanitizedQuestions(pathwayId);
    if (!questions) {
      return res.status(404).json({
        success: false,
        message: `Pathway "${pathwayId}" not found or has no quiz configured.`,
      });
    }

    // Verify pathway-level locking before allowing fast-track access
    if (pathwayId === "linux" || pathwayId === "docker" || pathwayId === "kubernetes") {
      const { getPathwayLockStatus } = require("./progressController");
      const lockStatus = await getPathwayLockStatus(userId);
      if (lockStatus[pathwayId] && lockStatus[pathwayId].isLocked) {
        return res.status(403).json({
          success: false,
          isLocked: true,
          message:
            lockStatus[pathwayId].lockReason ||
            `Pathway "${pathwayId}" is currently locked. Complete preceding pathways first.`,
        });
      }
    }

    let quizProgress = await QuizProgress.findOne({ userId, pathwayId });
    if (!quizProgress) {
      quizProgress = { hasPassed: false, bestScore: 0, attemptsCount: 0, lastAttemptAt: null };
    }

    return res.status(200).json({
      success: true,
      pathwayId,
      isFastTrack: true,
      totalQuestions: TOTAL_QUESTIONS_PER_QUIZ,
      passingScore: PASSING_SCORE,
      questions,
      status: {
        hasPassed: quizProgress.hasPassed,
        bestScore: quizProgress.bestScore,
        attemptsCount: quizProgress.attemptsCount,
        lastAttemptAt: quizProgress.lastAttemptAt,
      },
    });
  } catch (err) {
    console.error("Error fetching fast-track quiz:", err);
    return res.status(500).json({ success: false, message: "Failed to fetch quiz." });
  }
}

/**
 * POST /api/quiz/:pathwayId/fast-track
 * Evaluates answers WITHOUT prerequisite module check.
 * On pass: marks all pathway modules complete in Progress collection and unlocks next pathway.
 */
async function submitFastTrackQuiz(req, res) {
  try {
    const pathwayId = (req.params.pathwayId || "git").toLowerCase();
    const userId = req.user._id;
    const { answers } = req.body;

    if (!answers || typeof answers !== "object") {
      return res.status(400).json({
        success: false,
        message: "Answers payload must be an object of { [questionId]: selectedOptionIndex }.",
      });
    }

    const questions = getSanitizedQuestions(pathwayId);
    if (!questions) {
      return res.status(404).json({
        success: false,
        message: `Pathway "${pathwayId}" not found or has no quiz.`,
      });
    }

    // Verify pathway-level locking before allowing fast-track submission
    if (pathwayId === "linux" || pathwayId === "docker" || pathwayId === "kubernetes") {
      const { getPathwayLockStatus } = require("./progressController");
      const lockStatus = await getPathwayLockStatus(userId);
      if (lockStatus[pathwayId] && lockStatus[pathwayId].isLocked) {
        return res.status(403).json({
          success: false,
          isLocked: true,
          message:
            lockStatus[pathwayId].lockReason ||
            `Pathway "${pathwayId}" is currently locked. Complete preceding pathways first.`,
        });
      }
    }

    // Server-side evaluation (scoring is never bypassed)
    const evaluation = evaluateQuiz(pathwayId, answers);

    // Save individual attempt history
    const attempt = await QuizAttempt.create({
      userId,
      pathwayId,
      score: evaluation.score,
      totalQuestions: evaluation.totalQuestions,
      percentage: evaluation.percentage,
      passed: evaluation.passed,
      answers,
    });

    // Fetch or initialize aggregate QuizProgress
    let quizProgress = await QuizProgress.findOne({ userId, pathwayId });
    const wasAlreadyPassed = quizProgress ? quizProgress.hasPassed : false;
    const isNowPassed = wasAlreadyPassed || evaluation.passed;

    if (!quizProgress) {
      quizProgress = new QuizProgress({
        userId,
        pathwayId,
        hasPassed: isNowPassed,
        bestScore: evaluation.score,
        totalQuestions: evaluation.totalQuestions,
        attemptsCount: 1,
        firstPassedAt: evaluation.passed ? new Date() : null,
        lastAttemptAt: new Date(),
        latestAttemptId: attempt._id,
      });
    } else {
      quizProgress.attemptsCount += 1;
      quizProgress.lastAttemptAt = new Date();
      quizProgress.latestAttemptId = attempt._id;
      quizProgress.bestScore = Math.max(quizProgress.bestScore || 0, evaluation.score);
      quizProgress.hasPassed = isNowPassed;
      if (!wasAlreadyPassed && evaluation.passed) {
        quizProgress.firstPassedAt = new Date();
      }
    }
    await quizProgress.save();

    // On pass: mark all pathway modules complete in Progress collection
    const requiredModules = PATHWAY_PREREQUISITES[pathwayId] || [];
    let completedModulesList = [];

    if (evaluation.passed) {
      completedModulesList = requiredModules;

      let progress = await Progress.findOne({ userId, pathwayId });
      if (!progress) {
        progress = new Progress({ userId, pathwayId, completedModules: [] });
      }
      const existingSet = new Set(progress.completedModules || []);
      const newModules = requiredModules.filter((m) => !existingSet.has(m));

      if (newModules.length > 0) {
        progress.completedModules = [...new Set([...existingSet, ...requiredModules])];
        progress.lastUpdated = new Date();
        await progress.save();

        // Log stop_completed activity for each newly completed module
        for (const moduleId of newModules) {
          await logActivity(userId, "stop_completed", { pathwayId, stopSlug: moduleId });
        }
      }

      // Log quiz_passed activity if passed for the first time
      if (!wasAlreadyPassed) {
        await logActivity(userId, "quiz_passed", {
          pathwayId,
          score: evaluation.score,
          totalQuestions: evaluation.totalQuestions,
          percentage: evaluation.percentage,
          isFastTrack: true,
        });
      }
    }

    return res.status(200).json({
      success: true,
      pathwayId,
      isFastTrack: true,
      attemptId: attempt._id,
      score: evaluation.score,
      totalQuestions: evaluation.totalQuestions,
      percentage: evaluation.percentage,
      passed: evaluation.passed,
      hasPassedEver: quizProgress.hasPassed,
      bestScore: quizProgress.bestScore,
      attemptsCount: quizProgress.attemptsCount,
      review: evaluation.review,
      completedModules: completedModulesList,
    });
  } catch (err) {
    console.error("Error evaluating fast-track quiz:", err);
    return res.status(500).json({ success: false, message: "Failed to evaluate quiz submission." });
  }
}

module.exports = {
  checkPathwayCompletion,
  getQuiz,
  submitQuiz,
  getQuizStatus,
  getFastTrackQuiz,
  submitFastTrackQuiz,
};
