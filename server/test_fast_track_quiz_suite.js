/**
 * Test Suite: Pathway-Level Quiz Fast Track
 * Tests server-side evaluation, scoring threshold, module completion,
 * pathway unlock progression, and idempotency.
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
const {
  getFastTrackQuiz,
  submitFastTrackQuiz,
  getQuiz,
  submitQuiz,
} = require("./src/controllers/quizController");

function runFastTrackTests() {
  console.log("=== RUNNING FAST-TRACK QUIZ SYSTEM TESTS ===");

  // 1. Controller function exports
  assert.strictEqual(typeof getFastTrackQuiz, "function", "getFastTrackQuiz must be exported");
  assert.strictEqual(typeof submitFastTrackQuiz, "function", "submitFastTrackQuiz must be exported");
  assert.strictEqual(typeof getQuiz, "function", "getQuiz must remain exported");
  assert.strictEqual(typeof submitQuiz, "function", "submitQuiz must remain exported");
  console.log("✓ Controller exports verified");

  // 2. Server-side evaluation & scoring integrity
  for (const pathway of ["git", "docker", "linux"]) {
    const rawBank = QUIZ_BANKS[pathway];
    const sanitized = getSanitizedQuestions(pathway);

    // Sanitization check: no answers or explanations exposed
    assert.strictEqual(sanitized.length, TOTAL_QUESTIONS_PER_QUIZ);
    for (const q of sanitized) {
      assert.strictEqual(q.correctOption, undefined, "Sanitized questions must not contain correctOption");
      assert.strictEqual(q.explanation, undefined, "Sanitized questions must not contain explanation");
    }

    // Full score submission (20/20)
    const fullAnswers = {};
    rawBank.forEach((q) => {
      fullAnswers[q.id] = q.correctOption;
    });
    const fullResult = evaluateQuiz(pathway, fullAnswers);
    assert.strictEqual(fullResult.score, TOTAL_QUESTIONS_PER_QUIZ);
    assert.strictEqual(fullResult.passed, true);
    assert.strictEqual(fullResult.percentage, 100);

    // Minimum passing score submission (10/20)
    const thresholdAnswers = {};
    rawBank.forEach((q, idx) => {
      thresholdAnswers[q.id] = idx < PASSING_SCORE ? q.correctOption : (q.correctOption + 1) % 4;
    });
    const thresholdResult = evaluateQuiz(pathway, thresholdAnswers);
    assert.strictEqual(thresholdResult.score, PASSING_SCORE);
    assert.strictEqual(thresholdResult.passed, true);
    assert.strictEqual(thresholdResult.percentage, 50);

    // Failing score submission (9/20 - one below threshold)
    const failingAnswers = {};
    rawBank.forEach((q, idx) => {
      failingAnswers[q.id] = idx < (PASSING_SCORE - 1) ? q.correctOption : (q.correctOption + 1) % 4;
    });
    const failingResult = evaluateQuiz(pathway, failingAnswers);
    assert.strictEqual(failingResult.score, PASSING_SCORE - 1);
    assert.strictEqual(failingResult.passed, false);
    assert.strictEqual(failingResult.percentage, 45);

    // Zero score submission (0/20)
    const zeroAnswers = {};
    rawBank.forEach((q) => {
      zeroAnswers[q.id] = (q.correctOption + 1) % 4;
    });
    const zeroResult = evaluateQuiz(pathway, zeroAnswers);
    assert.strictEqual(zeroResult.score, 0);
    assert.strictEqual(zeroResult.passed, false);
    assert.strictEqual(zeroResult.percentage, 0);

    console.log(`✓ ${pathway} evaluation thresholds: 20/20 PASS, 10/20 PASS, 9/20 FAIL, 0/20 FAIL`);
  }

  // 3. Module curriculum completeness for fast-track pass
  assert.deepStrictEqual(
    PATHWAY_PREREQUISITES.git,
    ["git-01", "git-02", "git-03", "git-04", "git-05", "git-06", "git-07"]
  );
  assert.deepStrictEqual(
    PATHWAY_PREREQUISITES.docker,
    ["docker-01", "docker-02", "docker-03", "docker-04", "docker-05", "docker-06", "docker-07"]
  );
  assert.deepStrictEqual(
    PATHWAY_PREREQUISITES.linux,
    ["linux-01", "linux-02", "linux-03", "linux-04", "linux-05", "linux-06"]
  );
  console.log("✓ Curriculum stops for all pathways match requirements");

  // 4. Progress collection simulation: idempotency and partial preservation
  const simulateFastTrackPass = (existingModules, pathwayId) => {
    const requiredModules = PATHWAY_PREREQUISITES[pathwayId];
    const existingSet = new Set(existingModules);
    const newModules = requiredModules.filter((m) => !existingSet.has(m));
    const finalModules = [...new Set([...existingSet, ...requiredModules])];
    return { newModules, finalModules };
  };

  // Case A: User has 0 lessons completed, passes Git fast-track
  const caseA = simulateFastTrackPass([], "git");
  assert.strictEqual(caseA.newModules.length, 7);
  assert.strictEqual(caseA.finalModules.length, 7);

  // Case B: User has 3 lessons completed, passes Git fast-track
  const caseB = simulateFastTrackPass(["git-01", "git-02", "git-03"], "git");
  assert.strictEqual(caseB.newModules.length, 4);
  assert.deepStrictEqual(caseB.newModules, ["git-04", "git-05", "git-06", "git-07"]);
  assert.strictEqual(caseB.finalModules.length, 7);

  // Case C: User already completed all 7, retakes and passes
  const caseC = simulateFastTrackPass(PATHWAY_PREREQUISITES.git, "git");
  assert.strictEqual(caseC.newModules.length, 0); // No new module events
  assert.strictEqual(caseC.finalModules.length, 7);

  console.log("✓ Module progression upsert and idempotency verified");

  // 5. Answer Review Three-State Discrimination (Correct, Incorrect, Not Attempted)
  for (const pathway of ["git", "docker", "linux"]) {
    const rawBank = QUIZ_BANKS[pathway];
    const mixedAnswers = {};

    // Q0: Option A (index 0) selected, check correct/incorrect and attempted
    const q0 = rawBank[0];
    mixedAnswers[q0.id] = 0; // Option A

    // Q1: Explicitly correct answer
    const q1 = rawBank[1];
    mixedAnswers[q1.id] = q1.correctOption;

    // Q2: Explicitly incorrect answer
    const q2 = rawBank[2];
    mixedAnswers[q2.id] = (q2.correctOption + 1) % 4;

    // Q3 through Q19: Skipped / unattempted (do not set in mixedAnswers)

    const evalResult = evaluateQuiz(pathway, mixedAnswers);
    assert.strictEqual(evalResult.review.length, TOTAL_QUESTIONS_PER_QUIZ);

    // Review Q0: index 0 must be recognized as attempted
    const rev0 = evalResult.review[0];
    assert.strictEqual(rev0.selectedOption, 0, "Option index 0 must be preserved");
    assert.strictEqual(rev0.isAttempted, true, "Option index 0 must be marked attempted");

    // Review Q1: Correct
    const rev1 = evalResult.review[1];
    assert.strictEqual(rev1.selectedOption, q1.correctOption);
    assert.strictEqual(rev1.isAttempted, true);
    assert.strictEqual(rev1.isCorrect, true);

    // Review Q2: Incorrect
    const rev2 = evalResult.review[2];
    assert.strictEqual(rev2.selectedOption, (q2.correctOption + 1) % 4);
    assert.strictEqual(rev2.isAttempted, true);
    assert.strictEqual(rev2.isCorrect, false);

    // Review Q3: Not Attempted (skipped)
    const rev3 = evalResult.review[3];
    assert.strictEqual(rev3.selectedOption, null, "Skipped question selectedOption must be null");
    assert.strictEqual(rev3.isAttempted, false, "Skipped question isAttempted must be false");
    assert.strictEqual(rev3.isCorrect, false, "Skipped question isCorrect must be false");
    assert.ok(typeof rev3.correctOption === "number", "Correct answer must still be provided for learning");
    assert.ok(rev3.explanation && rev3.explanation.length > 0, "Explanation must still be provided for learning");

    // Check all unattempted questions in the review
    for (let i = 3; i < TOTAL_QUESTIONS_PER_QUIZ; i++) {
      const rev = evalResult.review[i];
      assert.strictEqual(rev.selectedOption, null);
      assert.strictEqual(rev.isAttempted, false);
      assert.strictEqual(rev.isCorrect, false);
    }

    console.log(`✓ ${pathway} answer review correctly distinguishes Correct, Incorrect, and Not Attempted`);
  }

  console.log("=== ALL FAST-TRACK QUIZ TESTS PASSED SUCCESSFULLY ===");
}

runFastTrackTests();
