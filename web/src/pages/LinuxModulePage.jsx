import React, { useState, useEffect } from "react";
import { useParams, Link } from "react-router-dom";
import { useAuth } from "../context/useAuth";
import { linuxCurriculum } from "../data/linuxCurriculum";
import {
  isModuleCompleted,
  toggleModuleCompletion,
} from "../services/progressService";
import { activityAPI } from "../services/api";
import LinuxAnimation from "../components/animations/LinuxAnimation";

/**
 * Formats inline code strings like `ls -la` inside text into styled <code> elements.
 */
function renderFormattedText(text) {
  if (!text || typeof text !== "string") return text;
  if (!text.includes("`")) return text;
  const parts = text.split(/(`[^`]+`)/g);
  return parts.map((part, i) => {
    if (part.startsWith("`") && part.endsWith("`")) {
      return (
        <code key={i} className="content-inline-code">
          {part.slice(1, -1)}
        </code>
      );
    }
    return part;
  });
}

export const LinuxModulePage = () => {
  const { moduleId } = useParams();
  const { user } = useAuth();

  const userId = user?._id || user?.id || user?.email || "guest";

  // Find module in curriculum
  const moduleIndex = linuxCurriculum.findIndex(
    (m) => m.id === moduleId || m.number === moduleId || String(m.order) === moduleId
  );
  const validIndex = moduleIndex >= 0 ? moduleIndex : 0;
  const currentModule = linuxCurriculum[validIndex];

  const [, setProgressVersion] = useState(0);
  const completed = isModuleCompleted(userId, "linux", currentModule.id);
  const [copiedSnippet, setCopiedSnippet] = useState(null);

  // Scroll to top when navigating to another module
  useEffect(() => {
    window.scrollTo({ top: 0, behavior: "smooth" });
  }, [currentModule.id]);

  // Record lesson_viewed activity event for authenticated user
  useEffect(() => {
    if (user && currentModule?.id) {
      activityAPI
        .logActivity({
          type: "lesson_viewed",
          pathwayId: "linux",
          stopSlug: currentModule.id,
        })
        .then((res) => {
          if (res && res.logged) {
            window.dispatchEvent(
              new CustomEvent("devops_activity_updated", {
                detail: { type: "lesson_viewed", stopSlug: currentModule.id },
              })
            );
          }
        })
        .catch((err) => {
          console.warn("Could not record lesson view activity:", err.message);
        });
    }
  }, [user, currentModule?.id]);

  const handleAnimationFinish = () => {
    if (user && currentModule?.id) {
      activityAPI
        .logActivity({
          type: "animation_finished",
          pathwayId: "linux",
          stopSlug: currentModule.id,
        })
        .then((res) => {
          if (res && res.logged) {
            window.dispatchEvent(
              new CustomEvent("devops_activity_updated", {
                detail: {
                  type: "animation_finished",
                  stopSlug: currentModule.id,
                },
              })
            );
          }
        })
        .catch((err) => {
          console.warn(
            "Could not record animation finished activity:",
            err.message
          );
        });
    }
  };

  // Synchronize if progress is updated in another tab or window
  useEffect(() => {
    const handleProgressUpdate = () => {
      setProgressVersion((v) => v + 1);
    };
    window.addEventListener("devops_progress_updated", handleProgressUpdate);
    return () =>
      window.removeEventListener(
        "devops_progress_updated",
        handleProgressUpdate
      );
  }, []);

  const handleToggleComplete = () => {
    toggleModuleCompletion(userId, "linux", currentModule.id);
    setProgressVersion((v) => v + 1);
  };

  const handleCopyCode = (text, id) => {
    navigator.clipboard.writeText(text);
    setCopiedSnippet(id);
    setTimeout(() => setCopiedSnippet(null), 2000);
  };

  const prevModule =
    validIndex > 0 ? linuxCurriculum[validIndex - 1] : null;
  const nextModule =
    validIndex < linuxCurriculum.length - 1
      ? linuxCurriculum[validIndex + 1]
      : null;

  return (
    <div className="module-page-wrapper" key={currentModule.id}>
      <div className="module-page-container">
        {/* Top Breadcrumb & Quick Actions */}
        <div className="module-top-nav">
          <Link to="/pathways/linux" className="back-link">
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
            <span>Back to Pathway</span>
          </Link>
        </div>

        {/* Module Title & Metadata Header */}
        <header className="module-header-card">
          <div className="module-meta-row">
            <span className="stop-number-badge">
              Stop {currentModule.order} of {linuxCurriculum.length}
            </span>
            <span className="module-time-badge">
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
              {currentModule.estimatedMinutes} min read
            </span>
            {completed && (
              <span className="status-badge-verified">
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
                Done
              </span>
            )}
          </div>

          <h1 className="module-title">{currentModule.title}</h1>
          <p className="module-summary">{currentModule.summary}</p>
        </header>

        {/* Learning Objectives Box */}
        <section
          className="module-objectives-card"
          aria-label="Learning Objectives"
        >
          <div className="objectives-header">
            <div className="objectives-icon-wrap" aria-hidden="true">
              <svg
                width="18"
                height="18"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                strokeWidth="2.5"
              >
                <path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z" />
              </svg>
            </div>
            <h2 className="objectives-title">Objectives</h2>
          </div>
          <ul className="objectives-list">
            {currentModule.objectives.map((obj, i) => (
              <li key={i} className="objective-item">
                <svg
                  width="16"
                  height="16"
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="currentColor"
                  strokeWidth="2.5"
                  aria-hidden="true"
                >
                  <polyline points="20 6 9 17 4 12" />
                </svg>
                <span>{renderFormattedText(obj)}</span>
              </li>
            ))}
          </ul>
        </section>

        {/* Module Content Sections */}
        <main className="module-content-article">
          <div className="content-badge-title">Content</div>

          {currentModule.sections.map((section) => {
            const sectionKey = `${currentModule.id}-sec-${section.number}`;
            const snippetId = `${currentModule.id}-${section.number}`;

            return (
              <section key={sectionKey} className="content-section-block">
                <h3 className="section-title-heading">{section.title}</h3>

                {/* Paragraphs */}
                {section.paragraphs &&
                  section.paragraphs.map((p, pIdx) => (
                    <p key={pIdx} className="content-paragraph">
                      {renderFormattedText(p)}
                    </p>
                  ))}

                {/* Optional Official Link */}
                {section.link && (
                  <p className="content-link-wrap">
                    <a
                      href={section.link.url}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="official-external-link"
                    >
                      {section.link.text}
                      <svg
                        width="12"
                        height="12"
                        viewBox="0 0 24 24"
                        fill="none"
                        stroke="currentColor"
                        strokeWidth="2"
                        aria-hidden="true"
                      >
                        <path d="M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6" />
                        <polyline points="15 3 21 3 21 9" />
                        <line x1="10" y1="14" x2="21" y2="3" />
                      </svg>
                    </a>
                  </p>
                )}

                {/* After Link Paragraphs */}
                {section.afterLinkParagraphs &&
                  section.afterLinkParagraphs.map((p, pIdx) => (
                    <p key={pIdx} className="content-paragraph">
                      {renderFormattedText(p)}
                    </p>
                  ))}

                {/* Code Snippet 1 */}
                {section.codeSnippet && (
                  <div className="code-block-container">
                    <div className="code-block-header">
                      <span className="code-lang-label">
                        {section.codeSnippet.language}
                      </span>
                      <button
                        type="button"
                        onClick={() =>
                          handleCopyCode(
                            section.codeSnippet.code,
                            `${snippetId}-1`
                          )
                        }
                        className="btn-copy-code"
                        aria-label="Copy code to clipboard"
                      >
                        {copiedSnippet === `${snippetId}-1` ? (
                          <>
                            <svg
                              width="13"
                              height="13"
                              viewBox="0 0 24 24"
                              fill="none"
                              stroke="currentColor"
                              strokeWidth="3"
                              aria-hidden="true"
                            >
                              <polyline points="20 6 9 17 4 12" />
                            </svg>
                            <span>Copied!</span>
                          </>
                        ) : (
                          <>
                            <svg
                              width="13"
                              height="13"
                              viewBox="0 0 24 24"
                              fill="none"
                              stroke="currentColor"
                              strokeWidth="2"
                              aria-hidden="true"
                            >
                              <rect
                                width="14"
                                height="14"
                                x="8"
                                y="8"
                                rx="2"
                                ry="2"
                              />
                              <path d="M4 16c-1.1 0-2-.9-2-2V4c0-1.1.9-2 2-2h10c1.1 0 2 .9 2 2" />
                            </svg>
                            <span>Copy</span>
                          </>
                        )}
                      </button>
                    </div>
                    <pre className="code-block-pre">
                      <code>{section.codeSnippet.code}</code>
                    </pre>
                  </div>
                )}

                {/* Post Snippet Paragraphs */}
                {section.postSnippetParagraphs &&
                  section.postSnippetParagraphs.map((p, pIdx) => (
                    <p key={pIdx} className="content-paragraph">
                      {renderFormattedText(p)}
                    </p>
                  ))}

                {/* Second Code Snippet */}
                {section.secondSnippet && (
                  <div className="code-block-container">
                    <div className="code-block-header">
                      <span className="code-lang-label">
                        {section.secondSnippet.language}
                      </span>
                      <button
                        type="button"
                        onClick={() =>
                          handleCopyCode(
                            section.secondSnippet.code,
                            `${snippetId}-2`
                          )
                        }
                        className="btn-copy-code"
                        aria-label="Copy code to clipboard"
                      >
                        {copiedSnippet === `${snippetId}-2` ? (
                          <>
                            <svg
                              width="13"
                              height="13"
                              viewBox="0 0 24 24"
                              fill="none"
                              stroke="currentColor"
                              strokeWidth="3"
                              aria-hidden="true"
                            >
                              <polyline points="20 6 9 17 4 12" />
                            </svg>
                            <span>Copied!</span>
                          </>
                        ) : (
                          <>
                            <svg
                              width="13"
                              height="13"
                              viewBox="0 0 24 24"
                              fill="none"
                              stroke="currentColor"
                              strokeWidth="2"
                              aria-hidden="true"
                            >
                              <rect
                                width="14"
                                height="14"
                                x="8"
                                y="8"
                                rx="2"
                                ry="2"
                              />
                              <path d="M4 16c-1.1 0-2-.9-2-2V4c0-1.1.9-2 2-2h10c1.1 0 2 .9 2 2" />
                            </svg>
                            <span>Copy</span>
                          </>
                        )}
                      </button>
                    </div>
                    <pre className="code-block-pre">
                      <code>{section.secondSnippet.code}</code>
                    </pre>
                  </div>
                )}

                {/* Middle Paragraphs */}
                {section.middleParagraphs &&
                  section.middleParagraphs.map((p, pIdx) => (
                    <p key={pIdx} className="content-paragraph">
                      {renderFormattedText(p)}
                    </p>
                  ))}

                {/* Table Rendering */}
                {section.table && (
                  <div className="content-table-wrapper">
                    <table className="content-table">
                      <thead>
                        <tr>
                          {section.table.headers.map((h, hIdx) => (
                            <th key={hIdx}>{h}</th>
                          ))}
                        </tr>
                      </thead>
                      <tbody>
                        {section.table.rows.map((row, rIdx) => (
                          <tr key={rIdx}>
                            {row.map((cell, cIdx) => (
                              <td key={cIdx}>{renderFormattedText(cell)}</td>
                            ))}
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                )}

                {/* Third Code Snippet */}
                {section.thirdSnippet && (
                  <div className="code-block-container">
                    <div className="code-block-header">
                      <span className="code-lang-label">
                        {section.thirdSnippet.language}
                      </span>
                      <button
                        type="button"
                        onClick={() =>
                          handleCopyCode(
                            section.thirdSnippet.code,
                            `${snippetId}-3`
                          )
                        }
                        className="btn-copy-code"
                      >
                        {copiedSnippet === `${snippetId}-3`
                          ? "Copied!"
                          : "Copy"}
                      </button>
                    </div>
                    <pre className="code-block-pre">
                      <code>{section.thirdSnippet.code}</code>
                    </pre>
                  </div>
                )}

                {/* After Third Snippet Paragraphs */}
                {section.afterThirdParagraphs &&
                  section.afterThirdParagraphs.map((p, pIdx) => (
                    <p key={pIdx} className="content-paragraph">
                      {renderFormattedText(p)}
                    </p>
                  ))}

                {/* Fourth Snippet */}
                {section.fourthSnippet && (
                  <div className="code-block-container">
                    <div className="code-block-header">
                      <span className="code-lang-label">
                        {section.fourthSnippet.language}
                      </span>
                      <button
                        type="button"
                        onClick={() =>
                          handleCopyCode(
                            section.fourthSnippet.code,
                            `${snippetId}-4`
                          )
                        }
                        className="btn-copy-code"
                      >
                        {copiedSnippet === `${snippetId}-4`
                          ? "Copied!"
                          : "Copy"}
                      </button>
                    </div>
                    <pre className="code-block-pre">
                      <code>{section.fourthSnippet.code}</code>
                    </pre>
                  </div>
                )}

                {/* Bullet List Items */}
                {section.listItems && (
                  <ul className="content-bullet-list">
                    {section.listItems.map((item, lIdx) => (
                      <li key={lIdx} className="content-list-item">
                        {renderFormattedText(item)}
                      </li>
                    ))}
                  </ul>
                )}

                {/* Closing Paragraphs */}
                {section.closingParagraphs &&
                  section.closingParagraphs.map((p, pIdx) => (
                    <p key={pIdx} className="content-paragraph">
                      {renderFormattedText(p)}
                    </p>
                  ))}

                {/* Step-by-Step Interactive Animation */}
                <div className="section-animation-container">
                  <LinuxAnimation
                    key={`${currentModule.id}-anim-${section.number}`}
                    id={section.subtopicId || `${currentModule.number}.${section.number}`}
                    fallbackTitle={
                      section.title
                        ? section.title.replace(/^\d+\.\s*/, "")
                        : undefined
                    }
                    onFinish={handleAnimationFinish}
                  />
                </div>
              </section>
            );
          })}

          {/* Module Completion Highlight Box */}
          {currentModule.moduleCompletion && (
            <section className="module-completion-card" aria-label="Module Completion">
              <div className="completion-card-header">
                <div className="completion-badge-icon" aria-hidden="true">
                  <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
                    <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14" />
                    <polyline points="22 4 12 14.01 9 11.01" />
                  </svg>
                </div>
                <h3 className="completion-card-title">{currentModule.moduleCompletion.title}</h3>
              </div>
              {currentModule.moduleCompletion.paragraphs.map((p, pIdx) => (
                <p key={pIdx} className="content-paragraph completion-card-text">
                  {renderFormattedText(p)}
                </p>
              ))}
            </section>
          )}
        </main>

        {/* Bottom Completion & Module Navigation Footer */}
        <footer className="module-footer-nav">
          <div className="module-footer-completion">
            <div className="completion-info">
              <h4>Ready to advance?</h4>
              <p>
                {completed
                  ? "You have completed this stop! Proceed to the next module or return to the pathway."
                  : "Mark this module as completed to record your progress along the learning pathway."}
              </p>
            </div>

            <button
              type="button"
              onClick={handleToggleComplete}
              className={`btn-completion-large ${
                completed ? "btn-completed-large" : "btn-mark-large"
              }`}
            >
              {completed ? (
                <>
                  <svg
                    width="18"
                    height="18"
                    viewBox="0 0 24 24"
                    fill="none"
                    stroke="currentColor"
                    strokeWidth="3"
                    aria-hidden="true"
                  >
                    <polyline points="20 6 9 17 4 12" />
                  </svg>
                  <span>Completed (Click to Undo)</span>
                </>
              ) : (
                <>
                  <svg
                    width="18"
                    height="18"
                    viewBox="0 0 24 24"
                    fill="none"
                    stroke="currentColor"
                    strokeWidth="2.5"
                    aria-hidden="true"
                  >
                    <polyline points="20 6 9 17 4 12" />
                  </svg>
                  <span>Mark Stop as Completed</span>
                </>
              )}
            </button>
          </div>

          <div className="module-navigation-buttons">
            {prevModule ? (
              <Link
                to={`/pathways/linux/${prevModule.id}`}
                className="btn-nav-module btn-prev-module"
              >
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
                <span>
                  Previous: Stop {prevModule.order}
                </span>
              </Link>
            ) : (
              <div />
            )}

            <Link to="/pathways/linux" className="btn-return-pathway">
              <span>View Pathway Map</span>
            </Link>

            {nextModule ? (
              <Link
                to={`/pathways/linux/${nextModule.id}`}
                className="btn-nav-module btn-next-module"
              >
                <span>
                  Next: Stop {nextModule.order}
                </span>
                <svg
                  width="16"
                  height="16"
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="currentColor"
                  strokeWidth="2.5"
                  aria-hidden="true"
                >
                  <polyline points="9 18 15 12 9 6" />
                </svg>
              </Link>
            ) : (
              <Link
                to="/pathways/linux"
                className="btn-nav-module btn-finish-pathway"
              >
                <span>Complete Pathway</span>
                <svg
                  width="16"
                  height="16"
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="currentColor"
                  strokeWidth="2.5"
                  aria-hidden="true"
                >
                  <polyline points="20 6 9 17 4 12" />
                </svg>
              </Link>
            )}
          </div>
        </footer>
      </div>
    </div>
  );
};

export default LinuxModulePage;

