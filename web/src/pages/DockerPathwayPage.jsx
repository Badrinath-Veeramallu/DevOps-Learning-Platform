import React, { useState, useEffect } from "react";
import { Link } from "react-router-dom";
import { useAuth } from "../context/useAuth";
import { DockerPathwayMap } from "../components/pathway/DockerPathwayMap";
import { dockerCurriculum } from "../data/dockerCurriculum";
import {
  getCompletedModules,
  fetchUserProgress,
  isPathwayUnlocked,
  isPathwayCompleted,
  getPathwayLockReason,
} from "../services/progressService";

export const DockerPathwayPage = () => {
  const { user } = useAuth();
  const userId = user?._id || user?.id || user?.email || "guest";
  const [completedIds, setCompletedIds] = useState(() =>
    getCompletedModules(userId, "docker")
  );
  const [, setProgressTick] = useState(0);

  // Sync state from server on mount and if module is marked completed anywhere
  useEffect(() => {
    fetchUserProgress(userId, "docker").then((ids) => {
      if (Array.isArray(ids)) setCompletedIds([...new Set(ids)]);
    });

    const handleProgressUpdate = (e) => {
      setProgressTick((t) => t + 1);
      if (e?.detail?.pathway && e.detail.pathway !== "docker") return;
      if (e?.detail?.allCompleted && Array.isArray(e.detail.allCompleted)) {
        setCompletedIds([...new Set(e.detail.allCompleted)]);
      } else {
        setCompletedIds(getCompletedModules(userId, "docker"));
      }
    };

    window.addEventListener("devops_progress_updated", handleProgressUpdate);
    return () =>
      window.removeEventListener("devops_progress_updated", handleProgressUpdate);
  }, [userId]);

  const isUnlocked = isPathwayUnlocked(userId, "docker");
  const lockReason = getPathwayLockReason(userId, "docker");

  // Pathway-level Route Guard
  if (!isUnlocked) {
    const isGitDone = isPathwayCompleted(userId, "git");
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
              <h1 className="locked-card-title">Docker & Containerization Pathway</h1>
              <p className="locked-card-desc">
                {lockReason || "Complete all prerequisite pathways to unlock Docker."}
              </p>
              <div className="locked-card-actions">
                <Link
                  to={!isGitDone ? "/pathways/git" : "/pathways/linux"}
                  className="btn-locked-action-primary"
                >
                  {!isGitDone ? "Go to Git Pathway \u2192" : "Go to Linux Pathway \u2192"}
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

  const pathwayModuleIds = new Set(dockerCurriculum.map((m) => m.id));
  const validCompletedIds = [...new Set(Array.isArray(completedIds) ? completedIds : [])].filter((id) =>
    pathwayModuleIds.has(id)
  );
  const totalModules = dockerCurriculum.length;
  const completedCount = validCompletedIds.length;
  const progressPercent = totalModules > 0 ? Math.round((completedCount / totalModules) * 100) : 0;
  const nextUncompletedModule = dockerCurriculum.find((m) => !validCompletedIds.includes(m.id));

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

          <h1 className="pathway-title">Docker & Containerization Pathway</h1>
          <p className="pathway-description">
            A progressive, step-by-step interactive roadmap mastering containerization,
            client-server architecture, Dockerfile engineering, persistent storage, Compose,
            and automated DevOps deployment pipelines.
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
              aria-label="Docker pathway progress"
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
                  <strong>Already familiar with Docker &amp; Containerization?</strong>
                  <span>Test your knowledge and skip to the next pathway by passing the assessment.</span>
                </div>
                <Link
                  to="/pathways/docker/quiz?fastTrack=true"
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
          <DockerPathwayMap
            modules={dockerCurriculum}
            completedIds={validCompletedIds}
            completedModuleIds={validCompletedIds}
          />
        </section>
      </div>
    </div>
  );
};

export default DockerPathwayPage;
