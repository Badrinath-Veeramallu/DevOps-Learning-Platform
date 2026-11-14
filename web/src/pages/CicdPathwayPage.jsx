import React, { useState, useEffect } from "react";
import { Link } from "react-router-dom";
import { useAuth } from "../context/useAuth";
import { CicdPathwayMap } from "../components/pathway/CicdPathwayMap";
import { cicdCurriculum } from "../data/cicdCurriculum";
import {
  getCompletedModules,
  fetchUserProgress,
  isPathwayUnlocked,
  isPathwayCompleted,
  getPathwayLockReason,
} from "../services/progressService";

export const CicdPathwayPage = () => {
  const { user } = useAuth();
  const userId = user?._id || user?.id || user?.email || "guest";
  const [completedIds, setCompletedIds] = useState(() =>
    getCompletedModules(userId, "cicd")
  );
  const [, setProgressTick] = useState(0);

  // Sync state from server on mount and if module is marked completed anywhere
  useEffect(() => {
    fetchUserProgress(userId, "cicd").then((ids) => {
      if (Array.isArray(ids)) setCompletedIds([...new Set(ids)]);
    });

    const handleProgressUpdate = (e) => {
      setProgressTick((t) => t + 1);
      if (e?.detail?.pathway && e.detail.pathway !== "cicd") return;
      if (e?.detail?.allCompleted && Array.isArray(e.detail.allCompleted)) {
        setCompletedIds([...new Set(e.detail.allCompleted)]);
      } else {
        setCompletedIds(getCompletedModules(userId, "cicd"));
      }
    };

    window.addEventListener("devops_progress_updated", handleProgressUpdate);
    return () =>
      window.removeEventListener("devops_progress_updated", handleProgressUpdate);
  }, [userId]);

  const isUnlocked = isPathwayUnlocked(userId, "cicd");
  const lockReason = getPathwayLockReason(userId, "cicd");

  // Pathway-level Route Guard
  if (!isUnlocked) {
    const isDockerDone = isPathwayCompleted(userId, "docker");
    const isLinuxDone = isPathwayCompleted(userId, "linux");
    const targetLink = !isLinuxDone ? "/pathways/linux" : !isDockerDone ? "/pathways/docker" : "/pathways/git";
    const targetLabel = !isLinuxDone ? "Go to Linux Pathway \u2192" : !isDockerDone ? "Go to Docker Pathway \u2192" : "Go to Git Pathway \u2192";

    return (
      <div className="pathway-page-wrapper">
        <div className="pathway-page-container">
          <div className="pathway-back-nav">
            <Link to="/dashboard" className="back-link">
              <svg
                width="16"
                height="16"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                strokeWidth="2.5"
                aria-hidden="true"
              >
                <polyline points="15 18 9 12 15 6" />
              </svg>
              <span>Back to Dashboard</span>
            </Link>
          </div>

          <div className="pathway-locked-container">
            <div className="pathway-locked-card">
              <div className="locked-icon-bubble">
                <svg
                  width="36"
                  height="36"
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="currentColor"
                  strokeWidth="2.2"
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  aria-hidden="true"
                >
                  <rect x="3" y="11" width="18" height="11" rx="2" ry="2" />
                  <path d="M7 11V7a5 5 0 0 1 10 0v4" />
                </svg>
              </div>
              <span className="badge-pill badge-locked">Pathway Locked</span>
              <h1 className="locked-card-title">CI/CD & GitOps Delivery Pathway</h1>
              <p className="locked-card-desc">
                {lockReason || "Complete all Docker modules to unlock the CI/CD pathway."}
              </p>
              <div className="locked-card-actions">
                <Link to={targetLink} className="btn-locked-action-primary">
                  {targetLabel}
                </Link>
                <Link to="/dashboard" className="btn-locked-action-secondary">
                  Return to Dashboard
                </Link>
              </div>
            </div>
          </div>
        </div>
      </div>
    );
  }

  const pathwayModuleIds = new Set(cicdCurriculum.map((m) => m.id));
  const validCompletedIds = [...new Set(Array.isArray(completedIds) ? completedIds : [])].filter((id) =>
    pathwayModuleIds.has(id)
  );
  const totalModules = cicdCurriculum.length;
  const completedCount = validCompletedIds.length;
  const progressPercent = totalModules > 0 ? Math.round((completedCount / totalModules) * 100) : 0;
  const nextUncompletedModule = cicdCurriculum.find((m) => !validCompletedIds.includes(m.id));

  return (
    <div className="pathway-page-wrapper">
      <div className="pathway-page-container">
        {/* Top Navigation */}
        <div className="pathway-back-nav">
          <Link to="/dashboard" className="back-link">
            <svg
              width="16"
              height="16"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              strokeWidth="2.5"
              aria-hidden="true"
            >
              <polyline points="15 18 9 12 15 6" />
            </svg>
            <span>Back to Dashboard</span>
          </Link>
        </div>

        {/* Pathway Hero Header */}
        <header className="pathway-header-card">
          <div className="pathway-badge-row">
            <span className="badge-pill badge-intermediate">
              Intermediate Pathway
            </span>
            <span className="badge-pill badge-modules">
              {totalModules} Stops
            </span>
          </div>

          <h1 className="pathway-title">CI/CD & GitOps Delivery Pathway</h1>
          <p className="pathway-description">
            A progressive, step-by-step interactive roadmap mastering automated build pipelines,
            Jenkins, GitHub Actions, testing automation, deployment strategies, and GitOps with Argo CD.
          </p>

          {/* Progress Overview Meter */}
          <div className="pathway-progress-panel">
            <div className="progress-panel-stats">
              <span className="progress-stat-label">Pathway Progress</span>
              <span className="progress-stat-fraction">
                <strong>{completedCount}</strong> of {totalModules} Completed (
                {progressPercent}%)
              </span>
            </div>

            <div
              className="progress-meter-track"
              role="progressbar"
              aria-valuenow={progressPercent}
              aria-valuemin="0"
              aria-valuemax="100"
              aria-label="CI/CD pathway progress"
            >
              <div
                className="progress-meter-fill"
                style={{ width: `${progressPercent}%` }}
              />
            </div>

            <div className="progress-panel-foot">
              <span className="progress-hint">
                {completedCount === totalModules
                  ? "🎉 You have completed all stops in this pathway! Excellent work."
                  : nextUncompletedModule
                  ? `Next up: Stop ${nextUncompletedModule.order} · ${nextUncompletedModule.shortTitle}`
                  : "Click on Stop 1 below to start your journey."}
              </span>
            </div>
          </div>

          {/* Fast-Track Quiz Banner — hidden once pathway is 100% complete */}
          {completedCount < totalModules && (
            <div className="pathway-fasttrack-banner">
              <div className="fasttrack-banner-content">
                <div className="fasttrack-banner-text">
                  <strong>Already familiar with CI/CD &amp; GitOps Delivery?</strong>
                  <span>Test your knowledge and skip to the next pathway by passing the assessment.</span>
                </div>
                <Link
                  to="/pathways/cicd/quiz?fastTrack=true"
                  className="btn-fasttrack-quiz"
                >
                  <svg width="15" height="15" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
                    <path d="M13 2L4.09 12.97 11 13l-2 9 8.91-10.97L11 11l2-9z"/>
                  </svg>
                  Attempt Pathway Quiz
                </Link>
              </div>
            </div>
          )}
        </header>

        {/* Interactive Road / Pathway Visualization */}
        <section aria-label="Learning Pathway Interactive Map">
          <CicdPathwayMap
            modules={cicdCurriculum}
            completedIds={validCompletedIds}
            completedModuleIds={validCompletedIds}
          />
        </section>
      </div>
    </div>
  );
};

export default CicdPathwayPage;
