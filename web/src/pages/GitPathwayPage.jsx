import React, { useState, useEffect } from "react";
import { Link } from "react-router-dom";
import { useAuth } from "../context/useAuth";
import { GitPathwayMap } from "../components/pathway/GitPathwayMap";
import { gitCurriculum } from "../data/gitCurriculum";
import { getCompletedModules, fetchUserProgress } from "../services/progressService";

export const GitPathwayPage = () => {
  const { user } = useAuth();
  const userId = user?._id || user?.id || user?.email || "guest";
  const [completedIds, setCompletedIds] = useState(() =>
    getCompletedModules(userId, "git")
  );

  // Sync state from server on mount and if module is marked completed anywhere
  useEffect(() => {
    fetchUserProgress(userId, "git").then((ids) => {
      if (Array.isArray(ids)) setCompletedIds(ids);
    });

    const handleProgressUpdate = () => {
      setCompletedIds(getCompletedModules(userId, "git"));
    };

    window.addEventListener("devops_progress_updated", handleProgressUpdate);
    return () => window.removeEventListener("devops_progress_updated", handleProgressUpdate);
  }, [userId]);

  const totalModules = gitCurriculum.length;
  const completedCount = completedIds.length;
  const progressPercent = Math.round((completedCount / totalModules) * 100);

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
            <span className="badge-pill badge-foundational">Foundational Pathway</span>
            <span className="badge-pill badge-modules">{totalModules} Stops</span>
          </div>

          <h1 className="pathway-title">Git & GitHub Pathway</h1>
          <p className="pathway-description">
            A progressive, step-by-step interactive map guiding you through professional
            version control, collaborative workflows, and DevOps pipeline integration.
          </p>

          {/* Progress Overview Meter */}
          <div className="pathway-progress-panel">
            <div className="progress-panel-stats">
              <span className="progress-stat-label">Pathway Progress</span>
              <span className="progress-stat-fraction">
                <strong>{completedCount}</strong> of {totalModules} Completed ({progressPercent}%)
              </span>
            </div>

            <div
              className="progress-meter-track"
              role="progressbar"
              aria-valuenow={progressPercent}
              aria-valuemin="0"
              aria-valuemax="100"
              aria-label="Git pathway progress"
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
                  : completedCount === 0
                  ? "Click on Stop 1 below to start your journey."
                  : `Next up: Stop ${completedCount + 1}`}
              </span>
            </div>
          </div>
        </header>

        {/* Interactive Road / Pathway Visualization */}
        <section aria-label="Learning Pathway Interactive Map">
          <GitPathwayMap
            modules={gitCurriculum}
            completedIds={completedIds}
          />
        </section>
      </div>
    </div>
  );
};

export default GitPathwayPage;
