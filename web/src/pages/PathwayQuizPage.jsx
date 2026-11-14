import React, { useState, useEffect } from "react";
import { useParams, Link, useLocation } from "react-router-dom";
import { quizAPI } from "../services/api";
import { useAuth } from "../context/useAuth";
import { fetchAllPathwaysStatus } from "../services/progressService";

const PATHWAY_NAMES = {
  git: "Git & GitHub",
  docker: "Docker & Containers",
  linux: "Linux Essentials",
};

const NEXT_PATHWAY = { git: "linux", linux: "docker", docker: "kubernetes", kubernetes: null };
const NEXT_PATHWAY_LABEL = { git: "Linux Essentials", linux: "Docker & Containerization", docker: "Kubernetes Cluster Architecture", kubernetes: null };

export const PathwayQuizPage = ({ pathwayId: propPathwayId }) => {
  const { pathwayId: paramPathwayId } = useParams();
  const location = useLocation();
  const pathDerivedId = location.pathname.split("/")[2];
  const pathwayId = (propPathwayId || paramPathwayId || pathDerivedId || "git").toLowerCase();

  // Detect fast-track mode from query param
  const isFastTrack = new URLSearchParams(location.search).get("fastTrack") === "true";

  const { user } = useAuth();
  const userId = user?._id || user?.id || user?.email || "guest";

  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [prereqError, setPrereqError] = useState(null);

  const [quizData, setQuizData] = useState(null);
  const [currentIndex, setCurrentIndex] = useState(0);
  const [answers, setAnswers] = useState({});

  const [isSubmitting, setIsSubmitting] = useState(false);
  const [showConfirmModal, setShowConfirmModal] = useState(false);
  const [result, setResult] = useState(null);
  const [showReview, setShowReview] = useState(false);

  const pathwayTitle = PATHWAY_NAMES[pathwayId.toLowerCase()] || pathwayId.toUpperCase();

  useEffect(() => {
    loadQuiz();
  }, [pathwayId]);

  const loadQuiz = async () => {
    setLoading(true);
    setError(null);
    setPrereqError(null);
    setResult(null);
    setAnswers({});
    setCurrentIndex(0);

    try {
      const data = isFastTrack
        ? await quizAPI.getFastTrackQuiz(pathwayId)
        : await quizAPI.getQuiz(pathwayId);
      setQuizData(data);
    } catch (err) {
      if (!isFastTrack && err.data && err.data.prerequisiteNotMet) {
        setPrereqError(err.data);
      } else {
        setError(err.message || "Failed to load quiz.");
      }
    } finally {
      setLoading(false);
    }
  };

  const handleSelectOption = (optionIndex) => {
    if (!quizData?.questions) return;
    const currentQ = quizData.questions[currentIndex];
    setAnswers((prev) => ({
      ...prev,
      [currentQ.id]: optionIndex,
    }));
  };

  const handleNext = () => {
    if (!quizData?.questions) return;
    if (currentIndex < quizData.questions.length - 1) {
      setCurrentIndex((prev) => prev + 1);
    } else {
      setShowConfirmModal(true);
    }
  };

  const handlePrev = () => {
    if (currentIndex > 0) {
      setCurrentIndex((prev) => prev - 1);
    }
  };

  const handleConfirmSubmit = async () => {
    setShowConfirmModal(false);
    setIsSubmitting(true);
    try {
      const res = isFastTrack
        ? await quizAPI.submitFastTrackQuiz(pathwayId, answers)
        : await quizAPI.submitQuiz(pathwayId, answers);
      setResult(res);

      // If fast-track pass: sync localStorage + notify all pathway pages
      if (isFastTrack && res.passed && Array.isArray(res.completedModules) && res.completedModules.length > 0) {
        localStorage.setItem(
          `devops_progress_${userId}_${pathwayId}`,
          JSON.stringify(res.completedModules)
        );
        window.dispatchEvent(
          new CustomEvent("devops_progress_updated", {
            detail: {
              userId,
              pathway: pathwayId,
              allCompleted: res.completedModules,
            },
          })
        );
        // Refresh all pathway statuses to unlock next pathway in dashboard
        try {
          await fetchAllPathwaysStatus(userId);
        } catch {
          // non-critical — dashboard will refresh on next visit
        }
      }

      window.scrollTo({ top: 0, behavior: "smooth" });
    } catch (err) {
      alert(err.message || "Failed to submit quiz. Please try again.");
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleRetake = () => {
    setResult(null);
    setAnswers({});
    setCurrentIndex(0);
    setShowReview(false);
    window.scrollTo({ top: 0, behavior: "smooth" });
  };

  // 1. Loading State
  if (loading) {
    return (
      <div className="quiz-wrapper">
        <div className="quiz-container">
          <div className="quiz-header-card" style={{ textAlign: "center", padding: "4rem 2rem" }}>
            <h2 className="quiz-title">Loading Final Quiz...</h2>
            <p className="quiz-subtitle">Preparing questions for {pathwayTitle}</p>
          </div>
        </div>
      </div>
    );
  }

  // 2. Prerequisite Error (Modules not completed)
  if (prereqError) {
    return (
      <div className="quiz-wrapper">
        <div className="quiz-container">
          <div className="quiz-top-nav">
            <Link to={`/pathways/${pathwayId}`} className="back-link">
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
                <polyline points="15 18 9 12 15 6" />
              </svg>
              <span>Back to Pathway</span>
            </Link>
          </div>

          <div className="quiz-header-card" style={{ textAlign: "center", padding: "3.5rem 2rem" }}>
            <div
              style={{
                width: 64,
                height: 64,
                borderRadius: "50%",
                background: "#fef3c7",
                color: "#b45309",
                margin: "0 auto 1.5rem",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                fontSize: "1.8rem",
              }}
            >
              🔒
            </div>
            <h2 className="quiz-title">Final Quiz Locked</h2>
            <p className="quiz-subtitle" style={{ maxWidth: 520, margin: "0 auto 2rem" }}>
              {prereqError.message}
            </p>
            <Link to={`/pathways/${pathwayId}`} className="quiz-btn quiz-btn-primary">
              Return to Learning Pathway
            </Link>
          </div>
        </div>
      </div>
    );
  }

  // 3. General Error State
  if (error || !quizData?.questions?.length) {
    return (
      <div className="quiz-wrapper">
        <div className="quiz-container">
          <div className="quiz-top-nav">
            <Link to={`/pathways/${pathwayId}`} className="back-link">
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
                <polyline points="15 18 9 12 15 6" />
              </svg>
              <span>Back to Pathway</span>
            </Link>
          </div>
          <div className="quiz-header-card" style={{ textAlign: "center", padding: "3rem" }}>
            <h2 className="quiz-title" style={{ color: "var(--color-error)" }}>
              Unable to Load Quiz
            </h2>
            <p className="quiz-subtitle">{error || "No questions available."}</p>
            <button onClick={loadQuiz} className="quiz-btn quiz-btn-primary">
              Retry
            </button>
          </div>
        </div>
      </div>
    );
  }

  const questions = quizData.questions;
  const currentQ = questions[currentIndex];
  const totalQuestions = questions.length;
  const answeredCount = Object.keys(answers).length;
  const progressPercent = Math.round(((currentIndex + 1) / totalQuestions) * 100);

  // 4. Result Screen
  if (result) {
    const isPass = result.passed;
    return (
      <div className="quiz-wrapper">
        <div className="quiz-container">
          {/* Top navigation */}
          <div className="quiz-top-nav">
            <Link to={`/pathways/${pathwayId}`} className="back-link">
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
                <polyline points="15 18 9 12 15 6" />
              </svg>
              <span>Return to Pathway Map</span>
            </Link>
          </div>

          {/* Hero Result Card */}
          <div className="quiz-result-hero">
            <div className={`quiz-result-icon ${isPass ? "is-pass" : "is-fail"}`}>
              {isPass ? "🏆" : "📝"}
            </div>

            <h1 className={`quiz-result-title ${isPass ? "is-pass" : "is-fail"}`}>
              {isPass ? "Congratulations! You Passed!" : "Keep Practicing!"}
            </h1>

            <div className="quiz-result-score-box">
              <span className="quiz-result-score-num">
                {result.score} / {result.totalQuestions}
              </span>
              <span className="quiz-result-score-label">
                {result.percentage}% Score (Passing: {quizData.passingScore || 10}/20)
              </span>
            </div>

            <p className="quiz-result-desc">
              {isPass
                ? isFastTrack
                  ? `Outstanding! You have demonstrated prior mastery of ${pathwayTitle}. All stops have been marked complete${NEXT_PATHWAY_LABEL[pathwayId] ? ` and ${NEXT_PATHWAY_LABEL[pathwayId]} is now unlocked!` : "."}`
                  : `You have demonstrated mastery of ${pathwayTitle}. Your final quiz completion is officially recorded!`
                : `You scored ${result.score} out of ${result.totalQuestions}. A score of at least 10 (50%) is required to pass. You can retake the quiz anytime!`}
            </p>

            <div className="quiz-result-actions">
              <button
                onClick={() => setShowReview(!showReview)}
                className="quiz-btn quiz-btn-secondary"
              >
                {showReview ? "Hide Answer Review" : "Review All Answers"}
              </button>

              <button onClick={handleRetake} className="quiz-btn quiz-btn-primary">
                Retake Quiz
              </button>

              <Link to={`/pathways/${pathwayId}`} className="quiz-btn quiz-btn-primary">
                Back to Roadmap
              </Link>

              {isPass && NEXT_PATHWAY[pathwayId] && (
                <Link
                  to={`/pathways/${NEXT_PATHWAY[pathwayId]}`}
                  className="quiz-btn quiz-btn-primary"
                  style={{ background: "#15803d" }}
                >
                  Continue to {NEXT_PATHWAY_LABEL[pathwayId]} &rarr;
                </Link>
              )}
            </div>
          </div>

          {/* Answer Review Section */}
          {showReview && (
            <div className="quiz-review-section">
              <h2 className="quiz-review-title">Detailed Answer Review</h2>
              {result.review.map((item, idx) => {
                const optLetters = ["A", "B", "C", "D"];
                const isAttempted =
                  typeof item.isAttempted === "boolean"
                    ? item.isAttempted
                    : typeof item.selectedOption === "number" &&
                      item.selectedOption >= 0 &&
                      item.selectedOption < item.options.length;
                const statusClass = item.isCorrect
                  ? "is-correct"
                  : isAttempted
                  ? "is-wrong"
                  : "is-unattempted";
                const statusLabel = item.isCorrect
                  ? "✓ Correct"
                  : isAttempted
                  ? "✕ Incorrect"
                  : "NOT ATTEMPTED";

                return (
                  <div
                    key={item.id}
                    className={`quiz-review-card ${statusClass}`}
                  >
                    <div className="quiz-review-q-header">
                      <span className="quiz-question-number">Question {idx + 1}</span>
                      <span className={`quiz-review-status-tag ${statusClass}`}>
                        {statusLabel}
                      </span>
                    </div>

                    <h3 style={{ fontSize: "1.05rem", fontWeight: 700, margin: "0 0 1rem" }}>
                      {item.question}
                    </h3>

                    <div style={{ display: "flex", flexDirection: "column", gap: "0.5rem" }}>
                      {item.options.map((opt, oIdx) => {
                        const isCorrectChoice = oIdx === item.correctOption;
                        const isUserChoice = isAttempted && oIdx === item.selectedOption;
                        let itemBorder = "var(--color-border)";
                        let itemBg = "#ffffff";

                        if (isCorrectChoice) {
                          itemBorder = "#15803d";
                          itemBg = "#f0fdf4";
                        } else if (isUserChoice && !item.isCorrect) {
                          itemBorder = "#dc2626";
                          itemBg = "#fef2f2";
                        }

                        return (
                          <div
                            key={oIdx}
                            style={{
                              padding: "0.75rem 1rem",
                              borderRadius: 8,
                              border: `1.5px solid ${itemBorder}`,
                              background: itemBg,
                              display: "flex",
                              alignItems: "center",
                              gap: "0.75rem",
                              fontSize: "0.9rem",
                            }}
                          >
                            <span
                              style={{
                                fontWeight: 700,
                                width: 24,
                                height: 24,
                                display: "flex",
                                alignItems: "center",
                                justifyContent: "center",
                                borderRadius: 4,
                                background: isCorrectChoice
                                  ? "#15803d"
                                  : isUserChoice
                                  ? "#dc2626"
                                  : "#e8dde0",
                                color: isCorrectChoice || isUserChoice ? "#ffffff" : "#171521",
                              }}
                            >
                              {optLetters[oIdx]}
                            </span>
                            <span style={{ flex: 1 }}>{opt}</span>
                            {isCorrectChoice && (
                              <span style={{ color: "#15803d", fontWeight: 700, fontSize: "0.8rem" }}>
                                (Correct Answer)
                              </span>
                            )}
                            {isUserChoice && !isCorrectChoice && (
                              <span style={{ color: "#dc2626", fontWeight: 700, fontSize: "0.8rem" }}>
                                (Your Answer)
                              </span>
                            )}
                          </div>
                        );
                      })}
                    </div>

                    {item.explanation && (
                      <div className="quiz-review-explanation">
                        <strong>Explanation: </strong>
                        {item.explanation}
                      </div>
                    )}
                  </div>
                );
              })}
            </div>
          )}
        </div>
      </div>
    );
  }

  // 5. Active Quiz Interface
  const optionLetters = ["A", "B", "C", "D"];
  const selectedOption = answers[currentQ.id];

  return (
    <div className="quiz-wrapper">
      <div className="quiz-container">
        {/* Top Breadcrumb & Link */}
        <div className="quiz-top-nav">
          <Link to={`/pathways/${pathwayId}`} className="back-link">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
              <polyline points="15 18 9 12 15 6" />
            </svg>
            <span>Exit Quiz</span>
          </Link>

          <span style={{ fontSize: "0.85rem", color: "var(--color-text-muted)" }}>
            Answered: <strong>{answeredCount}</strong> / {totalQuestions}
          </span>
        </div>

        {/* Header Card */}
        <div className="quiz-header-card">
          <div className="quiz-badge-row">
            <span className="quiz-pathway-badge">{pathwayTitle}</span>
            {quizData.status?.hasPassed && (
              <span className="quiz-status-badge is-passed">✓ Previously Passed</span>
            )}
          </div>

          <h1 className="quiz-title">{isFastTrack ? "Pathway Assessment" : "Final Comprehensive Quiz"}</h1>
          <p className="quiz-subtitle">
            {isFastTrack
              ? `Demonstrate your existing knowledge of ${pathwayTitle}. Score 10/20 (50%) or higher to pass and skip to the next pathway!`
              : "Test your complete knowledge across all modules. Score 10/20 (50%) or higher to pass!"}
          </p>

          {/* Progress Bar */}
          <div className="quiz-progress-section">
            <div className="quiz-progress-labels">
              <span>Question {currentIndex + 1} of {totalQuestions}</span>
              <span>{progressPercent}% Complete</span>
            </div>
            <div className="quiz-progress-track">
              <div
                className="quiz-progress-fill"
                style={{ width: `${progressPercent}%` }}
              />
            </div>
          </div>
        </div>

        {/* Quick Question Navigator Pills */}
        <div className="quiz-pills-bar" aria-label="Question Navigation Pills">
          {questions.map((q, idx) => {
            const isAnswered = typeof answers[q.id] === "number";
            const isActive = idx === currentIndex;
            return (
              <button
                key={q.id}
                onClick={() => setCurrentIndex(idx)}
                className={`quiz-pill-btn ${isActive ? "is-active" : ""} ${
                  isAnswered ? "is-answered" : ""
                }`}
                title={`Go to Question ${idx + 1}`}
              >
                {idx + 1}
              </button>
            );
          })}
        </div>

        {/* Active Question Card */}
        <div className="quiz-question-card">
          <div className="quiz-question-number">Question {currentIndex + 1} of {totalQuestions}</div>
          <h2 className="quiz-question-text">{currentQ.question}</h2>

          <div className="quiz-options-grid">
            {currentQ.options.map((optionText, optIdx) => {
              const isSelected = selectedOption === optIdx;
              return (
                <button
                  key={optIdx}
                  type="button"
                  onClick={() => handleSelectOption(optIdx)}
                  className={`quiz-option-button ${isSelected ? "is-selected" : ""}`}
                >
                  <span className="quiz-option-letter">{optionLetters[optIdx]}</span>
                  <span className="quiz-option-text">{optionText}</span>
                </button>
              );
            })}
          </div>
        </div>

        {/* Navigation / Action Bar */}
        <div className="quiz-controls-bar">
          <button
            type="button"
            onClick={handlePrev}
            disabled={currentIndex === 0}
            className="quiz-btn quiz-btn-secondary"
          >
            ← Previous
          </button>

          <div style={{ display: "flex", gap: "0.75rem" }}>
            <button
              type="button"
              onClick={() => setShowConfirmModal(true)}
              className="quiz-btn quiz-btn-submit"
            >
              Submit Quiz
            </button>

            {currentIndex < totalQuestions - 1 && (
              <button
                type="button"
                onClick={handleNext}
                className="quiz-btn quiz-btn-primary"
              >
                Next →
              </button>
            )}
          </div>
        </div>

        {/* Confirmation Modal */}
        {showConfirmModal && (
          <div className="quiz-modal-backdrop" onClick={() => setShowConfirmModal(false)}>
            <div className="quiz-modal-card" onClick={(e) => e.stopPropagation()}>
              <h3 className="quiz-modal-title">Ready to Submit?</h3>
              <p className="quiz-modal-text">
                You have answered <strong>{answeredCount}</strong> of{" "}
                <strong>{totalQuestions}</strong> questions.
                {answeredCount < totalQuestions && (
                  <span style={{ display: "block", marginTop: "0.5rem", color: "#dc2626" }}>
                    Warning: You still have {totalQuestions - answeredCount} unanswered questions!
                  </span>
                )}
              </p>
              <div className="quiz-modal-actions">
                <button
                  type="button"
                  onClick={() => setShowConfirmModal(false)}
                  className="quiz-btn quiz-btn-secondary"
                >
                  Keep Reviewing
                </button>
                <button
                  type="button"
                  onClick={handleConfirmSubmit}
                  disabled={isSubmitting}
                  className="quiz-btn quiz-btn-submit"
                >
                  {isSubmitting ? "Evaluating..." : "Confirm & Submit"}
                </button>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default PathwayQuizPage;
