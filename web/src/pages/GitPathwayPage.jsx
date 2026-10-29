import React, { useState, useEffect } from "react";
import { Link } from "react-router-dom";
import { useAuth } from "../context/useAuth";
import { GitPathwayMap } from "../components/pathway/GitPathwayMap";
import { gitCurriculum } from "../data/gitCurriculum";
import { getCompletedModules } from "../services/progressService";

export const GitPathwayPage = () => {
  const { user } = useAuth();
  const [completedIds, setCompletedIds] = useState(() =>
    getCompletedModules(user?.id || user?.email || "guest", "git")
  );

  // Sync state if module is marked completed in another tab or component
  useEffect(() => {
    const handleProgressUpdate = () => {
      setCompletedIds(getCompletedModules(user?.id || user?.email || "guest", "git"));
    };

    window.addEventListener("devops_progress_updated", handleProgressUpdate);
    return () => window.removeEventListener("devops_progress_updated", handleProgressUpdate);
  }, [user]);

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
          <div className="pathway-header-meta">
            <div className="pathway-badge-row">
              <span className="badge-pill badge-foundational">Foundational Pathway</span>
              <span className="pathway-track-badge">7 Interactive Stops</span>
            </div>
            <h1 className="pathway-main-title">Git & GitHub Learning Pathway</h1>
            <p className="pathway-main-desc">
              A structured, visual journey from fundamental version control commands to team collaboration, conflict resolution, and automated DevOps delivery pipelines.
            </p>
          </div>

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
                  ? "🎉 You've completed all 7 Git & GitHub stops!"
                  : `Next: Stop ${
                      gitCurriculum.findIndex((m) => !completedIds.includes(m.id)) + 1
                    } · ${
                      gitCurriculum.find((m) => !completedIds.includes(m.id))?.shortTitle || ""
                    }`}
              </span>
            </div>
          </div>
        </header>

        {/* Winding Pathway Journey Map */}
        <main className="pathway-map-section">
          <div className="pathway-section-header">
            <h2 className="pathway-section-heading">Learning Journey</h2>
            <p className="pathway-section-sub">
              Click any stop along the path to open its complete educational module, commands, and interactive visual slots.
            </p>
          </div>

          <GitPathwayMap completedModuleIds={completedIds} />
        </main>
      </div>
    </div>
  );
};

export default GitPathwayPage;
