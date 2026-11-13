import React, { useState, useEffect } from "react";
import { Link } from "react-router-dom";
import { useAuth } from "../context/useAuth";
import { LinuxPathwayMap } from "../components/pathway/LinuxPathwayMap";
import { linuxCurriculum } from "../data/linuxCurriculum";
import {
  getCompletedModules,
  fetchUserProgress,
  isPathwayUnlocked,
  isPathwayCompleted,
  getPathwayLockReason,
} from "../services/progressService";

export const LinuxPathwayPage = () => {
  const { user } = useAuth();
  const userId = user?._id || user?.id || user?.email || "guest";
  const [completedIds, setCompletedIds] = useState(() =>
    getCompletedModules(userId, "linux")
  );
  const [, setProgressTick] = useState(0);

  // Sync state from server on mount and if module is marked completed anywhere
  useEffect(() => {
    fetchUserProgress(userId, "linux").then((ids) => {
      if (Array.isArray(ids)) setCompletedIds([...new Set(ids)]);
    });

    const handleProgressUpdate = (e) => {
      setProgressTick((t) => t + 1);
      if (e?.detail?.pathway && e.detail.pathway !== "linux") return;
      if (e?.detail?.allCompleted && Array.isArray(e.detail.allCompleted)) {
        setCompletedIds([...new Set(e.detail.allCompleted)]);
      } else {
        setCompletedIds(getCompletedModules(userId, "linux"));
      }
    };

    window.addEventListener("devops_progress_updated", handleProgressUpdate);
    return () => window.removeEventListener("devops_progress_updated", handleProgressUpdate);
  }, [userId]);

  const isUnlocked = isPathwayUnlocked(userId, "linux");
  const lockReason = getPathwayLockReason(userId, "linux");

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
              <h1 className="locked-card-title">Linux Essentials Pathway</h1>
              <p className="locked-card-desc">
                {lockReason || "Complete all prerequisite pathways to unlock Linux."}
              </p>
              <div className="locked-card-actions">
                <Link
                  to={!isGitDone ? "/pathways/git" : "/pathways/docker"}
                  className="btn-locked-action-primary"
                >
                  {!isGitDone ? "Go to Git Pathway \u2192" : "Go to Docker Pathway \u2192"}
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

  const pathwayModuleIds = new Set(linuxCurriculum.map((m) => m.id));
  const validCompletedIds = [...new Set(Array.isArray(completedIds) ? completedIds : [])].filter((id) =>
    pathwayModuleIds.has(id)
  );
  const totalModules = linuxCurriculum.length;
  const completedCount = validCompletedIds.length;
  const progressPercent = totalModules > 0 ? Math.round((completedCount / totalModules) * 100) : 0;
  const nextUncompletedModule = linuxCurriculum.find((m) => !validCompletedIds.includes(m.id));

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
            <span className="badge-pill badge-foundational">
              Foundational Pathway
            </span>
            <span className="badge-pill badge-modules">
              {totalModules} Lessons
            </span>
          </div>

          <h1 className="pathway-title">Linux Essentials Pathway</h1>
          <p className="pathway-description">
            A comprehensive, hands-on path from absolute terminal basics to
            production system administration, shell automation, permissions,
            and networking.
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
              aria-label="Linux pathway progress"
            >
              <div
                className="progress-meter-fill"
                style={{ width: `${progressPercent}%` }}
              />
            </div>

            <div className="progress-panel-foot">
              <span className="progress-hint">
                {completedCount === totalModules
                  ? "🎉 You have completed all lessons in this pathway! Excellent work."
                  : nextUncompletedModule
                  ? `Next up: Lesson ${nextUncompletedModule.order} · ${nextUncompletedModule.shortTitle}`
                  : "Click on Lesson 1 below to start your journey."}
              </span>
            </div>
          </div>
        </header>

        {/* Interactive Road / Pathway Visualization */}
        <section aria-label="Learning Pathway Interactive Map">
          <LinuxPathwayMap
            modules={linuxCurriculum}
            completedIds={validCompletedIds}
            completedModuleIds={validCompletedIds}
          />
        </section>
      </div>
    </div>
  );
};

export default LinuxPathwayPage;
