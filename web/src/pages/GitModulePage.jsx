import React, { useState, useEffect } from "react";
import { useParams, Link } from "react-router-dom";
import { useAuth } from "../context/useAuth";
import { gitCurriculum } from "../data/gitCurriculum";
import {
  isModuleCompleted,
  toggleModuleCompletion,
} from "../services/progressService";
import { activityAPI } from "../services/api";
import GitAnimation from "../components/animations/GitAnimation";

export const GitModulePage = () => {
  const { moduleId } = useParams();
  const { user } = useAuth();

  const userId = user?._id || user?.id || user?.email || "guest";

  // Find module in curriculum
  const moduleIndex = gitCurriculum.findIndex(
    (m) => m.id === moduleId || m.number === moduleId
  );
  const validIndex = moduleIndex >= 0 ? moduleIndex : 0;
  const currentModule = gitCurriculum[validIndex];

  const [, setProgressVersion] = useState(0);
  const completed = isModuleCompleted(userId, "git", currentModule.id);
  const [copiedSnippet, setCopiedSnippet] = useState(null);

  // Scroll to top when navigating to another module
  useEffect(() => {
    window.scrollTo({ top: 0, behavior: "smooth" });
  }, [currentModule.id]);

  // Record lesson_viewed activity event for authenticated user (at most once per user per lesson per day)
  useEffect(() => {
    if (user && currentModule?.id) {
      activityAPI
        .logActivity({
          type: "lesson_viewed",
          pathwayId: "git",
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
          pathwayId: "git",
          stopSlug: currentModule.id,
        })
        .then((res) => {
          if (res && res.logged) {
            window.dispatchEvent(
              new CustomEvent("devops_activity_updated", {
                detail: { type: "animation_finished", stopSlug: currentModule.id },
              })
            );
          }
        })
        .catch((err) => {
          console.warn("Could not record animation finished activity:", err.message);
        });
    }
  };

  // Synchronize if progress is updated in another tab or window
  useEffect(() => {
    const handleProgressUpdate = () => {
      setProgressVersion((v) => v + 1);
    };
    window.addEventListener("devops_progress_updated", handleProgressUpdate);
    return () => window.removeEventListener("devops_progress_updated", handleProgressUpdate);
  }, []);

  const handleToggleComplete = () => {
    toggleModuleCompletion(userId, "git", currentModule.id);
    setProgressVersion((v) => v + 1);
  };

  const handleCopyCode = (text, id) => {
    navigator.clipboard.writeText(text);
    setCopiedSnippet(id);
    setTimeout(() => setCopiedSnippet(null), 2000);
  };

  const prevModule = validIndex > 0 ? gitCurriculum[validIndex - 1] : null;
  const nextModule =
    validIndex < gitCurriculum.length - 1
      ? gitCurriculum[validIndex + 1]
      : null;

  return (
    <div className="module-page-wrapper" key={currentModule.id}>
      <div className="module-page-container">
        {/* Top Breadcrumb & Quick Actions */}
        <div className="module-top-nav">
          <Link to="/pathways/git" className="back-link">
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
            <span className="stop-number-badge">Stop {currentModule.order} of 7</span>
            <span className="module-time-badge">
              <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" aria-hidden="true">
                <circle cx="12" cy="12" r="10" />
                <polyline points="12 6 12 12 16 14" />
              </svg>
              {currentModule.estimatedMinutes} min read
            </span>
            {completed && (
              <span className="status-badge-verified">
                <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3" aria-hidden="true">
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
        <section className="module-objectives-card" aria-label="Learning Objectives">
          <div className="objectives-header">
            <div className="objectives-icon-wrap" aria-hidden="true">
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
                <path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z" />
              </svg>
            </div>
            <h2 className="objectives-title">Objectives</h2>
          </div>
          <ul className="objectives-list">
            {currentModule.objectives.map((obj, i) => (
              <li key={i} className="objective-item">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" aria-hidden="true">
                  <polyline points="20 6 9 17 4 12" />
                </svg>
                <span>{obj}</span>
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
                      {p}
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
                      <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" aria-hidden="true">
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
                      {p}
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
                          handleCopyCode(section.codeSnippet.code, `${snippetId}-1`)
                        }
                        className="btn-copy-code"
                        aria-label="Copy code to clipboard"
                      >
                        {copiedSnippet === `${snippetId}-1` ? (
                          <>
                            <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3" aria-hidden="true">
                              <polyline points="20 6 9 17 4 12" />
                            </svg>
                            <span>Copied!</span>
                          </>
                        ) : (
                          <>
                            <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" aria-hidden="true">
                              <rect width="14" height="14" x="8" y="8" rx="2" ry="2" />
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
                      {p}
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
                          handleCopyCode(section.secondSnippet.code, `${snippetId}-2`)
                        }
                        className="btn-copy-code"
                        aria-label="Copy code to clipboard"
                      >
                        {copiedSnippet === `${snippetId}-2` ? (
                          <>
                            <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3" aria-hidden="true">
                              <polyline points="20 6 9 17 4 12" />
                            </svg>
                            <span>Copied!</span>
                          </>
                        ) : (
                          <>
                            <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" aria-hidden="true">
                              <rect width="14" height="14" x="8" y="8" rx="2" ry="2" />
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
                      {p}
                    </p>
                  ))}

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
                          handleCopyCode(section.thirdSnippet.code, `${snippetId}-3`)
                        }
                        className="btn-copy-code"
                      >
                        {copiedSnippet === `${snippetId}-3` ? "Copied!" : "Copy"}
                      </button>
                    </div>
                    <pre className="code-block-pre">
                      <code>{section.thirdSnippet.code}</code>
                    </pre>
                  </div>
                )}

                {/* After Third Snippet */}
                {section.afterThirdParagraphs &&
                  section.afterThirdParagraphs.map((p, pIdx) => (
                    <p key={pIdx} className="content-paragraph">
                      {p}
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
                          handleCopyCode(section.fourthSnippet.code, `${snippetId}-4`)
                        }
                        className="btn-copy-code"
                      >
                        {copiedSnippet === `${snippetId}-4` ? "Copied!" : "Copy"}
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
                        {item}
                      </li>
                    ))}
                  </ul>
                )}

                {/* Closing Paragraphs */}
                {section.closingParagraphs &&
                  section.closingParagraphs.map((p, pIdx) => (
                    <p key={pIdx} className="content-paragraph">
                      {p}
                    </p>
                  ))}

                {/* Step-by-Step Interactive Animation (Rendered after Example) */}
                <div className="section-animation-container">
                  <GitAnimation
                    key={`${currentModule.id}-anim-${section.number}`}
                    id={`${currentModule.number}.${section.number}`}
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
                  <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3" aria-hidden="true">
                    <polyline points="20 6 9 17 4 12" />
                  </svg>
                  <span>Completed (Click to Undo)</span>
                </>
              ) : (
                <>
                  <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" aria-hidden="true">
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
                to={`/pathways/git/${prevModule.id}`}
                className="btn-nav-module btn-prev-module"
              >
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" aria-hidden="true">
                  <polyline points="15 18 9 12 15 6" />
                </svg>
                <div className="nav-module-text">
                  <span className="nav-sub">Previous Stop</span>
                  <span className="nav-title">{prevModule.shortTitle}</span>
                </div>
              </Link>
            ) : (
              <div className="nav-module-spacer" />
            )}

            <Link to="/pathways/git" className="btn-return-pathway">
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" aria-hidden="true">
                <rect width="7" height="7" x="3" y="3" rx="1" />
                <rect width="7" height="7" x="14" y="3" rx="1" />
                <rect width="7" height="7" x="14" y="14" rx="1" />
                <rect width="7" height="7" x="3" y="14" rx="1" />
              </svg>
              <span>Pathway Overview</span>
            </Link>

            {nextModule ? (
              <Link
                to={`/pathways/git/${nextModule.id}`}
                className="btn-nav-module btn-next-module"
              >
                <div className="nav-module-text">
                  <span className="nav-sub">Next Stop</span>
                  <span className="nav-title">{nextModule.shortTitle}</span>
                </div>
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" aria-hidden="true">
                  <polyline points="9 18 15 12 9 6" />
                </svg>
              </Link>
            ) : (
              <div className="nav-module-spacer" />
            )}
          </div>
        </footer>
      </div>
    </div>
  );
};

export default GitModulePage;
