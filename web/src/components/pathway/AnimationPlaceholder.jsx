import React from "react";

/**
 * AnimationPlaceholder — Dedicated, responsive placeholder container for future animations.
 *
 * Keeps curriculum clean and separate while reserving dedicated slots for:
 * - Git workflow (Working Directory, Staging, Local Repo, Remote)
 * - Git commits & staging transitions
 * - GitHub Remotes & Clone/Push/Pull
 * - Git Branching models
 * - Fast-forward & 3-way Merging
 * - Merge Conflict markers & resolution
 * - Git History & Reverting
 * - Team Pull Requests & Code Reviews
 * - CI/CD pipeline automation with GitHub Actions
 */
export const AnimationPlaceholder = ({
  title,
  concept,
  description,
  type = "default",
}) => {
  // SVG Schematics illustrating the future visual concept
  const renderSchematic = () => {
    switch (type) {
      case "workflow":
        return (
          <div className="animation-schematic workflow-schematic" aria-hidden="true">
            <div className="schematic-node node-working">
              <span className="node-icon">📁</span>
              <span className="node-label">Working Directory</span>
              <span className="node-sub">Modified files</span>
            </div>
            <div className="schematic-arrow">
              <span className="arrow-cmd">git add</span>
              <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                <polyline points="9 18 15 12 9 6" />
              </svg>
            </div>
            <div className="schematic-node node-staging">
              <span className="node-icon">📋</span>
              <span className="node-label">Staging Area</span>
              <span className="node-sub">Index snapshot</span>
            </div>
            <div className="schematic-arrow">
              <span className="arrow-cmd">git commit</span>
              <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                <polyline points="9 18 15 12 9 6" />
              </svg>
            </div>
            <div className="schematic-node node-local">
              <span className="node-icon">📦</span>
              <span className="node-label">Local Repo</span>
              <span className="node-sub">HEAD history</span>
            </div>
            <div className="schematic-arrow">
              <span className="arrow-cmd">git push</span>
              <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                <polyline points="9 18 15 12 9 6" />
              </svg>
            </div>
            <div className="schematic-node node-remote">
              <span className="node-icon">☁️</span>
              <span className="node-label">GitHub Remote</span>
              <span className="node-sub">origin/main</span>
            </div>
          </div>
        );

      case "branching":
        return (
          <div className="animation-schematic branching-schematic" aria-hidden="true">
            <div className="branch-line main-branch">
              <span className="branch-name">main</span>
              <div className="commit-dot c1" title="Commit A" />
              <div className="branch-connector" />
              <div className="commit-dot c2" title="Commit B" />
              <div className="commit-dot c3" title="Merge Commit" />
            </div>
            <div className="branch-line feature-branch">
              <span className="branch-name">feature/login</span>
              <div className="commit-dot c-feat-1" title="Feature 1" />
              <div className="commit-dot c-feat-2" title="Feature 2" />
            </div>
          </div>
        );

      case "conflict":
        return (
          <div className="animation-schematic conflict-schematic" aria-hidden="true">
            <div className="conflict-box local-box">
              <span className="conflict-tag">&lt;&lt;&lt;&lt;&lt;&lt;&lt; HEAD</span>
              <code>return res.status(401).json(...);</code>
            </div>
            <div className="conflict-divider">
              <span>=======</span>
            </div>
            <div className="conflict-box incoming-box">
              <code>return res.status(400).json(...);</code>
              <span className="conflict-tag">&gt;&gt;&gt;&gt;&gt;&gt;&gt; feature-branch</span>
            </div>
          </div>
        );

      case "cicd":
        return (
          <div className="animation-schematic cicd-schematic" aria-hidden="true">
            <div className="cicd-step">
              <span className="step-num">1</span>
              <span className="step-text">git push</span>
            </div>
            <span className="cicd-connector">→</span>
            <div className="cicd-step">
              <span className="step-num">2</span>
              <span className="step-text">GitHub Actions</span>
            </div>
            <span className="cicd-connector">→</span>
            <div className="cicd-step">
              <span className="step-num">3</span>
              <span className="step-text">Automated Tests</span>
            </div>
            <span className="cicd-connector">→</span>
            <div className="cicd-step">
              <span className="step-num">4</span>
              <span className="step-text">Deploy</span>
            </div>
          </div>
        );

      default:
        return (
          <div className="animation-schematic generic-schematic" aria-hidden="true">
            <svg width="36" height="36" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5">
              <polygon points="5 3 19 12 5 21 5 3" />
            </svg>
            <span className="schematic-caption">{concept || "Interactive Visual Simulation"}</span>
          </div>
        );
    }
  };

  return (
    <div className="animation-placeholder-container" role="region" aria-label={`Animation placeholder: ${title}`}>
      <div className="placeholder-top-bar">
        <div className="placeholder-badge-group">
          <span className="badge-animation-tag">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" aria-hidden="true">
              <polygon points="5 3 19 12 5 21 5 3" />
            </svg>
            Interactive Visualisation Slot
          </span>
          {concept && <span className="badge-concept-tag">{concept}</span>}
        </div>
        <span className="badge-ready-tag">Animation Ready</span>
      </div>

      <div className="placeholder-body">
        <h4 className="placeholder-title">{title}</h4>
        <p className="placeholder-desc">{description}</p>
        <div className="placeholder-canvas">{renderSchematic()}</div>
      </div>

      <div className="placeholder-footer">
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" aria-hidden="true">
          <circle cx="12" cy="12" r="10" />
          <line x1="12" y1="16" x2="12" y2="12" />
          <line x1="12" y1="8" x2="12.01" y2="8" />
        </svg>
        <span>
          Dedicated layout container reserved for interactive step-through simulation.
        </span>
      </div>
    </div>
  );
};

export default AnimationPlaceholder;
