import React from "react";
import { Link } from "react-router-dom";
import { dockerCurriculum } from "../../data/dockerCurriculum";

/**
 * DockerPathwayMap — Coursiv.io-inspired winding learning journey.
 *
 * Visualizes the 7 Docker & Containerization subtopics along a connected S-curved pathway
 * with alternating left/right stops, sequential locking, progress states (completed, current, locked),
 * and direct links to accessible learning modules.
 */
export const DockerPathwayMap = ({
  modules = dockerCurriculum,
  completedModuleIds = [],
  completedIds,
}) => {
  const pathwayModules = Array.isArray(modules) && modules.length > 0 ? modules : dockerCurriculum;
  const rawCompleted = Array.isArray(completedModuleIds) && completedModuleIds.length > 0
    ? completedModuleIds
    : Array.isArray(completedIds)
    ? completedIds
    : [];
  const completedSet = new Set(rawCompleted);

  const isAllCompleted = pathwayModules.length > 0 && pathwayModules.every((m) => completedSet.has(m.id));

  return (
    <div
      className="pathway-journey-container"
      role="region"
      aria-label="Docker & Containerization Learning Pathway"
    >
      {/* Visual Road / Winding Track Container */}
      <div className="pathway-track-canvas">
        {/* Background S-Curve Path SVG (Visible on Desktop / Tablet) */}
        <svg
          className="pathway-svg-curve"
          viewBox="0 0 1200 2200"
          fill="none"
          xmlns="http://www.w3.org/2000/svg"
          preserveAspectRatio="none"
          aria-hidden="true"
        >
          {/* Subtle Road Outer Cushion */}
          <path
            d="M 160,40 L 160,120 C 160,280 1040,280 1040,440 C 1040,600 160,600 160,760 C 160,920 1040,920 1040,1080 C 1040,1240 160,1240 160,1400 C 160,1560 1040,1560 1040,1720 C 1040,1880 160,1880 160,2040 L 160,2140"
            className="path-road-cushion"
          />
          {/* Base Road Track */}
          <path
            d="M 160,40 L 160,120 C 160,280 1040,280 1040,440 C 1040,600 160,600 160,760 C 160,920 1040,920 1040,1080 C 1040,1240 160,1240 160,1400 C 160,1560 1040,1560 1040,1720 C 1040,1880 160,1880 160,2040 L 160,2140"
            className="path-road-base"
          />
          {/* Dashed Center Road Line */}
          <path
            d="M 160,40 L 160,120 C 160,280 1040,280 1040,440 C 1040,600 160,600 160,760 C 160,920 1040,920 1040,1080 C 1040,1240 160,1240 160,1400 C 160,1560 1040,1560 1040,1720 C 1040,1880 160,1880 160,2040 L 160,2140"
            className="path-road-dash"
          />
        </svg>

        {/* Start Milestone Marker */}
        <div
          className="pathway-endpoint-row row-start"
          aria-label="Learning Pathway Start"
        >
          <div className="pathway-endpoint-anchor">
            <div className="pathway-endpoint-monument start-monument">
              <div
                className="endpoint-icon-circle start-circle"
                title="Pathway Start"
              >
                <svg
                  width="28"
                  height="28"
                  viewBox="0 0 28 28"
                  fill="none"
                  xmlns="http://www.w3.org/2000/svg"
                  aria-hidden="true"
                >
                  <path
                    d="M6 26V4"
                    stroke="#3b1f24"
                    strokeWidth="2.4"
                    strokeLinecap="round"
                  />
                  <circle cx="6" cy="3.5" r="2" fill="#82535d" />
                  <path
                    d="M7.5 5.5H21C22.2 5.5 22.8 6.6 22 7.6L18.5 11.5L22 15.4C22.8 16.4 22.2 17.5 21 17.5H7.5V5.5Z"
                    fill="#3b1f24"
                  />
                  <path
                    d="M8.5 11.5H18"
                    stroke="#ffffff"
                    strokeWidth="1.4"
                    strokeOpacity="0.45"
                    strokeLinecap="round"
                  />
                </svg>
              </div>
              <span className="endpoint-label start-label">START</span>
            </div>
          </div>
        </div>

        {/* 7 Pathway Stops */}
        <div className="pathway-stops-list">
          {pathwayModules.map((module, idx) => {
            const isCompleted = completedSet.has(module.id);
            const isPrecedingCompleted = idx === 0 || completedSet.has(pathwayModules[idx - 1].id);
            const isCurrent = !isCompleted && isPrecedingCompleted;
            const isLocked = !isCompleted && !isPrecedingCompleted;
            const isEven = idx % 2 === 0;

            let statusLabel = "Locked";
            if (isCompleted) statusLabel = "Completed";
            else if (isCurrent) statusLabel = "Current Stop";

            return (
              <div
                key={module.id}
                className={`pathway-stop-row ${
                  isEven ? "row-left" : "row-right"
                } ${isCompleted ? "stop-completed" : ""} ${
                  isCurrent ? "stop-current" : ""
                } ${isLocked ? "stop-locked" : ""}`}
              >
                {/* Center Node / Milestone Pin on the Pathway */}
                <div className="pathway-node-anchor">
                  <div className="node-outer-glow">
                    {isLocked ? (
                      <div
                        className="pathway-node-circle node-circle-locked"
                        aria-label={`${module.title} (Locked)`}
                        title="Complete the previous module to unlock this module."
                      >
                        <svg
                          width="20"
                          height="20"
                          viewBox="0 0 24 24"
                          fill="none"
                          stroke="currentColor"
                          strokeWidth="2.5"
                          aria-hidden="true"
                        >
                          <rect x="3" y="11" width="18" height="11" rx="2" ry="2" />
                          <path d="M7 11V7a5 5 0 0 1 10 0v4" />
                        </svg>
                      </div>
                    ) : (
                      <Link
                        to={`/pathways/docker/${module.id}`}
                        className={`pathway-node-circle ${
                          isCompleted
                            ? "node-circle-completed"
                            : "node-circle-current"
                        }`}
                        aria-label={`${module.title} (${statusLabel})`}
                      >
                        {isCompleted ? (
                          <svg
                            width="20"
                            height="20"
                            viewBox="0 0 24 24"
                            fill="none"
                            stroke="currentColor"
                            strokeWidth="3"
                            aria-hidden="true"
                          >
                            <polyline points="20 6 9 17 4 12" />
                          </svg>
                        ) : (
                          <span className="node-number">{module.order}</span>
                        )}
                      </Link>
                    )}
                  </div>
                </div>

                {/* Subtopic Card beside the Node (alternating Left / Right) */}
                <div className="pathway-stop-card-wrap">
                  <div className="pathway-stop-card">
                    <div className="card-top-row">
                      <div className="card-badge-row">
                        <span className="stop-number-badge">
                          Stop {module.order} of 7
                        </span>
                        {isCompleted && (
                          <span className="stop-status-pill pill-completed">
                            <svg
                              width="12"
                              height="12"
                              viewBox="0 0 24 24"
                              fill="none"
                              stroke="currentColor"
                              strokeWidth="3"
                              aria-hidden="true"
                            >
                              <polyline points="20 6 9 17 4 12" />
                            </svg>
                            Completed
                          </span>
                        )}
                        {isCurrent && (
                          <span className="stop-status-pill pill-current">
                            Current Focus
                          </span>
                        )}
                        {isLocked && (
                          <span className="stop-status-pill pill-locked">
                            <svg
                              width="12"
                              height="12"
                              viewBox="0 0 24 24"
                              fill="none"
                              stroke="currentColor"
                              strokeWidth="2.5"
                              aria-hidden="true"
                            >
                              <rect x="3" y="11" width="18" height="11" rx="2" ry="2" />
                              <path d="M7 11V7a5 5 0 0 1 10 0v4" />
                            </svg>
                            Locked
                          </span>
                        )}
                      </div>

                      <span className="card-est-time">
                        <svg
                          width="13"
                          height="13"
                          viewBox="0 0 24 24"
                          fill="none"
                          stroke="currentColor"
                          strokeWidth="2"
                          aria-hidden="true"
                        >
                          <circle cx="12" cy="12" r="10" />
                          <polyline points="12 6 12 12 16 14" />
                        </svg>
                        {module.estimatedMinutes} min
                      </span>
                    </div>

                    <h3 className="stop-title">
                      {isLocked ? (
                        <span>{module.shortTitle}</span>
                      ) : (
                        <Link to={`/pathways/docker/${module.id}`}>
                          {module.shortTitle}
                        </Link>
                      )}
                    </h3>

                    {isLocked && (
                      <div className="stop-locked-hint">
                        <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" aria-hidden="true">
                          <rect x="3" y="11" width="18" height="11" rx="2" ry="2" />
                          <path d="M7 11V7a5 5 0 0 1 10 0v4" />
                        </svg>
                        <span>Complete the previous module to unlock this module.</span>
                      </div>
                    )}

                    <p className="stop-desc">{module.summary}</p>

                    <div className="stop-card-footer">
                      <div className="stop-obj-count">
                        <svg
                          width="14"
                          height="14"
                          viewBox="0 0 24 24"
                          fill="none"
                          stroke="currentColor"
                          strokeWidth="2"
                          aria-hidden="true"
                        >
                          <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z" />
                          <polyline points="14 2 14 8 20 8" />
                          <line x1="16" y1="13" x2="8" y2="13" />
                          <line x1="16" y1="17" x2="8" y2="17" />
                        </svg>
                        <span>{module.objectives.length} Objectives</span>
                      </div>

                      {isLocked ? (
                        <button
                          type="button"
                          disabled
                          className="btn-stop-action btn-stop-locked"
                          aria-label="Locked: Complete the previous module to unlock this module."
                        >
                          <span>Locked</span>
                          <svg
                            width="13"
                            height="13"
                            viewBox="0 0 24 24"
                            fill="none"
                            stroke="currentColor"
                            strokeWidth="2.5"
                            aria-hidden="true"
                          >
                            <rect x="3" y="11" width="18" height="11" rx="2" ry="2" />
                            <path d="M7 11V7a5 5 0 0 1 10 0v4" />
                          </svg>
                        </button>
                      ) : (
                        <Link
                          to={`/pathways/docker/${module.id}`}
                          className={`btn-stop-action ${
                            isCurrent
                              ? "btn-stop-primary"
                              : "btn-stop-review"
                          }`}
                        >
                          <span>
                            {isCompleted
                              ? "Review Module"
                              : "Start Learning"}
                          </span>
                          <svg
                            width="14"
                            height="14"
                            viewBox="0 0 24 24"
                            fill="none"
                            stroke="currentColor"
                            strokeWidth="2.5"
                            aria-hidden="true"
                          >
                            <polyline points="9 18 15 12 9 6" />
                          </svg>
                        </Link>
                      )}
                    </div>
                  </div>
                </div>
              </div>
            );
          })}
        </div>

        {/* Finish Milestone Marker */}
        <div
          className="pathway-endpoint-row row-finish"
          aria-label="Learning Pathway Finish"
        >
          <div className="pathway-endpoint-anchor">
            {isAllCompleted ? (
              <Link
                to="/pathways/docker/quiz"
                className="pathway-endpoint-monument finish-monument is-completed-all"
                title="All modules completed! Take the Final Quiz"
                style={{ textDecoration: "none", cursor: "pointer" }}
              >
                <div
                  className="endpoint-icon-circle finish-circle"
                  title="Final Quiz Available"
                >
                  <svg
                    width="28"
                    height="28"
                    viewBox="0 0 28 28"
                    fill="none"
                    xmlns="http://www.w3.org/2000/svg"
                    aria-hidden="true"
                  >
                    <path
                      d="M5 26V4"
                      stroke="currentColor"
                      strokeWidth="2.4"
                      strokeLinecap="round"
                    />
                    <circle cx="5" cy="3.5" r="2" fill="currentColor" />
                    <g transform="translate(6, 4)">
                      <rect x="0" y="0" width="4.5" height="4.5" fill="#ffffff" />
                      <rect
                        x="4.5"
                        y="0"
                        width="4.5"
                        height="4.5"
                        fill="currentColor"
                      />
                      <rect x="9" y="0" width="4.5" height="4.5" fill="#ffffff" />
                      <rect
                        x="13.5"
                        y="0"
                        width="4.5"
                        height="4.5"
                        fill="currentColor"
                      />

                      <rect
                        x="0"
                        y="4.5"
                        width="4.5"
                        height="4.5"
                        fill="currentColor"
                      />
                      <rect
                        x="4.5"
                        y="4.5"
                        width="4.5"
                        height="4.5"
                        fill="#ffffff"
                      />
                      <rect
                        x="9"
                        y="4.5"
                        width="4.5"
                        height="4.5"
                        fill="currentColor"
                      />
                      <rect
                        x="13.5"
                        y="4.5"
                        width="4.5"
                        height="4.5"
                        fill="#ffffff"
                      />

                      <rect x="0" y="9" width="4.5" height="4.5" fill="#ffffff" />
                      <rect
                        x="4.5"
                        y="9"
                        width="4.5"
                        height="4.5"
                        fill="currentColor"
                      />
                      <rect x="9" y="9" width="4.5" height="4.5" fill="#ffffff" />
                      <rect
                        x="13.5"
                        y="9"
                        width="4.5"
                        height="4.5"
                        fill="currentColor"
                      />
                    </g>
                  </svg>
                </div>
                <span className="endpoint-label finish-label" style={{ background: "#15803d", borderColor: "#15803d" }}>
                  FINAL QUIZ
                </span>
              </Link>
            ) : (
              <div
                className="pathway-endpoint-monument finish-monument"
              >
                <div
                  className="endpoint-icon-circle finish-circle"
                  title="Pathway Finish"
                >
                  <svg
                    width="28"
                    height="28"
                    viewBox="0 0 28 28"
                    fill="none"
                    xmlns="http://www.w3.org/2000/svg"
                    aria-hidden="true"
                  >
                    <path
                      d="M5 26V4"
                      stroke="currentColor"
                      strokeWidth="2.4"
                      strokeLinecap="round"
                    />
                    <circle cx="5" cy="3.5" r="2" fill="currentColor" />
                    <g transform="translate(6, 4)">
                      <rect x="0" y="0" width="4.5" height="4.5" fill="#ffffff" />
                      <rect
                        x="4.5"
                        y="0"
                        width="4.5"
                        height="4.5"
                        fill="currentColor"
                      />
                      <rect x="9" y="0" width="4.5" height="4.5" fill="#ffffff" />
                      <rect
                        x="13.5"
                        y="0"
                        width="4.5"
                        height="4.5"
                        fill="currentColor"
                      />

                      <rect
                        x="0"
                        y="4.5"
                        width="4.5"
                        height="4.5"
                        fill="currentColor"
                      />
                      <rect
                        x="4.5"
                        y="4.5"
                        width="4.5"
                        height="4.5"
                        fill="#ffffff"
                      />
                      <rect
                        x="9"
                        y="4.5"
                        width="4.5"
                        height="4.5"
                        fill="currentColor"
                      />
                      <rect
                        x="13.5"
                        y="4.5"
                        width="4.5"
                        height="4.5"
                        fill="#ffffff"
                      />

                      <rect x="0" y="9" width="4.5" height="4.5" fill="#ffffff" />
                      <rect
                        x="4.5"
                        y="9"
                        width="4.5"
                        height="4.5"
                        fill="currentColor"
                      />
                      <rect x="9" y="9" width="4.5" height="4.5" fill="#ffffff" />
                      <rect
                        x="13.5"
                        y="9"
                        width="4.5"
                        height="4.5"
                        fill="currentColor"
                      />
                    </g>
                  </svg>
                </div>
                <span className="endpoint-label finish-label">FINISH</span>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};

export default DockerPathwayMap;
