/**
 * Automated Test Suite for DevOps Learning Platform Final Quiz System
 */
const assert = require("assert");
const {
  PATHWAY_PREREQUISITES,
  PASSING_SCORE,
  TOTAL_QUESTIONS_PER_QUIZ,
  QUIZ_BANKS,
  getSanitizedQuestions,
  evaluateQuiz,
} = require("./src/data/quizQuestions");

function runTests() {
  console.log("=== RUNNING FINAL QUIZ SYSTEM TESTS ===");

  const seenIds = new Set();
  let totalQuestionsCount = 0;

  // 1. Verify all pathways have 20 questions and meet all schema integrity rules
  for (const pathway of ["git", "docker", "linux"]) {
    const rawBank = QUIZ_BANKS[pathway];
    assert.ok(Array.isArray(rawBank), `${pathway} bank must be an array`);
    assert.strictEqual(
      rawBank.length,
      TOTAL_QUESTIONS_PER_QUIZ,
      `${pathway} must have exactly ${TOTAL_QUESTIONS_PER_QUIZ} questions`
    );

    const validModules = new Set(PATHWAY_PREREQUISITES[pathway]);

    for (const q of rawBank) {
      // Unique question IDs across all pathways
      assert.ok(q.id, `Question must have an ID: ${JSON.stringify(q)}`);
      assert.ok(!seenIds.has(q.id), `Duplicate question ID detected: ${q.id}`);
      seenIds.add(q.id);
      totalQuestionsCount += 1;

      // Module ID reference
      assert.ok(
        q.moduleId && validModules.has(q.moduleId),
        `Question ${q.id} has invalid moduleId: ${q.moduleId} for pathway ${pathway}`
      );

      // Question text and options
      assert.ok(typeof q.question === "string" && q.question.trim().length > 0);
      assert.strictEqual(
        q.options.length,
        4,
        `Question ${q.id} must have exactly 4 options`
      );
      for (const opt of q.options) {
        assert.ok(
          typeof opt === "string" && opt.trim().length > 0,
          `Question ${q.id} contains empty option`
        );
      }

      // Valid correctOption
      assert.ok(
        Number.isInteger(q.correctOption) &&
          q.correctOption >= 0 &&
          q.correctOption < 4,
        `Question ${q.id} has invalid correctOption: ${q.correctOption}`
      );

      // Explanation
      assert.ok(
        typeof q.explanation === "string" && q.explanation.trim().length > 0,
        `Question ${q.id} missing explanation`
      );
    }
    console.log(`✓ ${pathway} has exactly 20 valid questions with correct module bindings`);

    // Verify sanitized structure
    const sanitized = getSanitizedQuestions(pathway);
    assert.strictEqual(sanitized.length, 20);
    for (const sq of sanitized) {
      assert.strictEqual(sq.correctOption, undefined, "Sanitized question must NEVER leak correctOption");
      assert.strictEqual(sq.explanation, undefined, "Sanitized question must NEVER leak explanation");
      assert.strictEqual(sq.options.length, 4);
    }
    console.log(`✓ ${pathway} questions are securely sanitized`);
  }

  // 2. Verify global uniqueness count
  assert.strictEqual(totalQuestionsCount, 60, "Expected exactly 60 total questions across all 3 pathways");
  assert.strictEqual(seenIds.size, 60, "All 60 question IDs must be globally unique");
  console.log("✓ All 60 question IDs are verified globally unique");

  // 3. Verify pathway prerequisites
  assert.strictEqual(PATHWAY_PREREQUISITES.git.length, 7, "Git must require 7 modules");
  assert.strictEqual(PATHWAY_PREREQUISITES.docker.length, 7, "Docker must require 7 modules");
  assert.strictEqual(PATHWAY_PREREQUISITES.linux.length, 6, "Linux must require 6 modules");
  console.log("✓ Pathway prerequisite requirements verified");

  // 4. Verify evaluateQuiz passing criteria (passing score: 10/20 = 50%)
  assert.strictEqual(PASSING_SCORE, 10);
  assert.strictEqual(TOTAL_QUESTIONS_PER_QUIZ, 20);

  for (const pathway of ["git", "docker", "linux"]) {
    const bank = QUIZ_BANKS[pathway];

    // Perfect 20/20
    const perfectAnswers = {};
    bank.forEach((q) => {
      perfectAnswers[q.id] = q.correctOption;
    });
    const perfectResult = evaluateQuiz(pathway, perfectAnswers);
    assert.strictEqual(perfectResult.score, 20);
    assert.strictEqual(perfectResult.percentage, 100);
    assert.strictEqual(perfectResult.passed, true);

    // Exact threshold 10/20 (50%)
    const thresholdAnswers = {};
    bank.forEach((q, idx) => {
      if (idx < 10) {
        thresholdAnswers[q.id] = q.correctOption;
      } else {
        thresholdAnswers[q.id] = (q.correctOption + 1) % 4; // intentionally wrong
      }
    });
    const thresholdResult = evaluateQuiz(pathway, thresholdAnswers);
    assert.strictEqual(thresholdResult.score, 10);
    assert.strictEqual(thresholdResult.percentage, 50);
    assert.strictEqual(thresholdResult.passed, true);

    // Failing 9/20 (45%)
    const failingAnswers = {};
    bank.forEach((q, idx) => {
      if (idx < 9) {
        failingAnswers[q.id] = q.correctOption;
      } else {
        failingAnswers[q.id] = (q.correctOption + 1) % 4; // intentionally wrong
      }
    });
    const failingResult = evaluateQuiz(pathway, failingAnswers);
    assert.strictEqual(failingResult.score, 9);
    assert.strictEqual(failingResult.percentage, 45);
    assert.strictEqual(failingResult.passed, false);

    // Verify review payload contents
    assert.strictEqual(failingResult.review.length, 20);
    const reviewItem = failingResult.review[0];
    assert.strictEqual(typeof reviewItem.correctOption, "number");
    assert.ok(reviewItem.explanation && reviewItem.explanation.length > 0);
  }

  console.log("✓ Full score (20/20), threshold (10/20), and failing (9/20) evaluated correctly for all pathways");
  console.log("✓ Post-submission review payload verified across all pathways");

  console.log("=== ALL QUIZ BACKEND TESTS PASSED SUCCESSFULLY ===");
}

runTests();
