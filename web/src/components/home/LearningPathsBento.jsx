import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { useAuth } from "../../context/useAuth";
import { gitCurriculum } from "../../data/gitCurriculum";
import { dockerCurriculum } from "../../data/dockerCurriculum";
import {
  fetchUserProgress,
  getCompletedModules,
} from "../../services/progressService";
import { RevealSection } from "./RevealSection";

const formatDuration = (totalMinutes) => {
  const hrs = Math.floor(totalMinutes / 60);
  const mins = totalMinutes % 60;
  if (hrs === 0) return `${mins} mins`;
  return mins > 0 ? `${hrs}h ${mins}m` : `${hrs}h`;
};

const sumMinutes = (curriculum) =>
  curriculum.reduce((sum, item) => sum + (item.estimatedMinutes || 0), 0);

/**
 * LearningPathsBento — Asymmetric Bento grid featuring genuine learning paths:
 * Git & GitHub (live pathway), Docker (live pathway), and Linux Essentials (roadmap track).
 * Progress metrics only render when the user is authenticated and backed by real storage/API.
 */
export const LearningPathsBento = () => {
  const { isAuthenticated, user } = useAuth();
  const userId = user?._id || user?.id || user?.email || "guest";

  const [gitCompleted, setGitCompleted] = useState(() =>
    isAuthenticated ? getCompletedModules(userId, "git") : []
  );
  const [dockerCompleted, setDockerCompleted] = useState(() =>
    isAuthenticated ? getCompletedModules(userId, "docker") : []
  );

  useEffect(() => {
    if (!isAuthenticated) return undefined;

    let active = true;
    fetchUserProgress(userId, "git").then((ids) => {
      if (active && Array.isArray(ids)) setGitCompleted(ids);
    });
    fetchUserProgress(userId, "docker").then((ids) => {
      if (active && Array.isArray(ids)) setDockerCompleted(ids);
    });

    const handleProgressUpdate = () => {
      setGitCompleted(getCompletedModules(userId, "git"));
      setDockerCompleted(getCompletedModules(userId, "docker"));
    };

    window.addEventListener("devops_progress_updated", handleProgressUpdate);
    return () => {
      active = false;
      window.removeEventListener("devops_progress_updated", handleProgressUpdate);
    };
  }, [isAuthenticated, userId]);

  const gitCount = gitCurriculum.length;
  const gitDuration = formatDuration(sumMinutes(gitCurriculum));
  const gitCompletedCount = isAuthenticated ? gitCompleted.length : 0;
  const gitPercent = gitCount > 0 ? Math.round((gitCompletedCount / gitCount) * 100) : 0;

  const dockerCount = dockerCurriculum.length;
  const dockerDuration = formatDuration(sumMinutes(dockerCurriculum));
  const dockerCompletedCount = isAuthenticated ? dockerCompleted.length : 0;
  const dockerPercent =
    dockerCount > 0 ? Math.round((dockerCompletedCount / dockerCount) * 100) : 0;

  const gitSampleStops = [
    gitCurriculum[0]?.shortTitle,
    gitCurriculum[3]?.shortTitle,
    gitCurriculum[6]?.shortTitle,
  ].filter(Boolean);

  const dockerSampleStops = [
    dockerCurriculum[0]?.shortTitle,
    dockerCurriculum[2]?.shortTitle,
    dockerCurriculum[4]?.shortTitle,
  ].filter(Boolean);

  return (
    <section className="hp-section hp-section-bento" id="paths" aria-labelledby="paths-heading">
      <div className="hp-container">
        <RevealSection className="hp-section-header">
          <span className="hp-eyebrow">Structured Curriculum</span>
          <h2 className="hp-section-title" id="paths-heading">
            Core DevOps Learning Paths
          </h2>
          <p className="hp-section-subtitle">
            Master essential engineering workflows one guided pathway at a time — starting with version control, containers, and Linux operations.
          </p>
        </RevealSection>

        {/* Asymmetric 12-Column Bento Grid */}
        <div className="hp-bento-grid">
          {/* 1. GIT & GITHUB — Featured Wide Bento Card (7 cols) */}
          <RevealSection className="hp-bento-card hp-bento-git" delayMs={40}>
            <div className="hp-bento-git-inner">
              <div className="hp-bento-copy">
                <div className="hp-card-badges">
                  <span className="badge-pill badge-foundational">Foundational</span>
                  <span className="hp-status-chip hp-status-live">
                    <span className="hp-live-dot" aria-hidden="true" />
                    Interactive Pathway
                  </span>
                </div>

                <h3 className="hp-bento-title">Git &amp; GitHub</h3>
                <p className="hp-bento-desc">
                  Learn version control from first repository setup to branching, conflict resolution, and team GitOps workflows along a guided map.
                </p>

                <ul className="hp-topic-list" aria-label="Included Git topics">
                  {gitSampleStops.map((topic) => (
                    <li key={topic}>
                      <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.4" aria-hidden="true">
                        <polyline points="20 6 9 17 4 12" />
                      </svg>
                      <span>{topic}</span>
                    </li>
                  ))}
                </ul>

                {/* Real Curriculum Scope or Live User Progress */}
                <div className="hp-bento-progress">
                  <div className="hp-bento-meta-row">
                    <span>
                      <strong>{gitCount} Modules</strong> &middot; {gitDuration} total
                    </span>
                    {isAuthenticated && (
                      <span className="hp-progress-ratio">
                        {gitCompletedCount}/{gitCount} done ({gitPercent}%)
                      </span>
                    )}
                  </div>
                  {isAuthenticated && (
                    <div
                      className="hp-mini-meter"
                      role="progressbar"
                      aria-valuenow={gitPercent}
                      aria-valuemin="0"
                      aria-valuemax="100"
                      aria-label="Git & GitHub pathway progress"
                    >
                      <div
                        className="hp-mini-meter-fill"
                        style={{ width: `${gitPercent}%` }}
                      />
                    </div>
                  )}
                </div>

                <div className="hp-bento-actions">
                  <Link
                    to={isAuthenticated ? "/pathways/git" : "/login"}
                    state={!isAuthenticated ? { from: { pathname: "/pathways/git" } } : undefined}
                    className="hp-card-cta hp-card-cta-primary"
                  >
                    <span>Explore Path</span>
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.3" aria-hidden="true">
                      <line x1="5" y1="12" x2="19" y2="12" />
                      <polyline points="12 5 19 12 12 19" />
                    </svg>
                  </Link>
                </div>
              </div>

              {/* Mini Winding Git Pathway SVG Illustration */}
              <div className="hp-bento-visual hp-visual-git" aria-hidden="true">
                <div className="hp-visual-canvas">
                  <svg viewBox="0 0 240 250" fill="none" className="hp-svg-art">
                    {/* Winding pale-blush curve */}
                    <path
                      d="M 48 34 C 48 92, 188 80, 188 128 C 188 176, 52 164, 52 216"
                      stroke="#E7D4D7"
                      strokeWidth="22"
                      strokeLinecap="round"
                    />
                    <path
                      d="M 48 34 C 48 92, 188 80, 188 128 C 188 176, 52 164, 52 216"
                      stroke="#82535D"
                      strokeWidth="2.5"
                      strokeDasharray="6 6"
                      strokeLinecap="round"
                      className="hp-road-anim"
                    />
                    {/* Stop 1: Completed */}
                    <circle cx="48" cy="34" r="14" fill="#3B1F24" />
                    <path d="M43 34l3.5 3.5L53.5 30" stroke="#FFFFFF" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round" />
                    <rect x="72" y="21" width="128" height="26" rx="8" fill="#FFFFFF" stroke="#E8DDE0" />
                    <text x="84" y="38" fill="#171521" fontSize="10.5" fontWeight="600" fontFamily="Plus Jakarta Sans, sans-serif">
                      01 &middot; Git Setup
                    </text>

                    {/* Stop 2: Branching */}
                    <circle cx="188" cy="128" r="14" fill="#FFFFFF" stroke="#3B1F24" strokeWidth="3" />
                    <circle cx="188" cy="128" r="5" fill="#3B1F24" />
                    <rect x="26" y="114" width="136" height="28" rx="8" fill="#FFFFFF" stroke="#B88A91" />
                    <text x="38" y="132" fill="#3B1F24" fontSize="10.5" fontWeight="700" fontFamily="Plus Jakarta Sans, sans-serif">
                      04 &middot; Branch &amp; Merge
                    </text>

                    {/* Stop 3: DevOps Workflow */}
                    <circle cx="52" cy="216" r="13" fill="#FCF8F9" stroke="#B88A91" strokeWidth="2.5" />
                    <circle cx="52" cy="216" r="4" fill="#B88A91" />
                    <rect x="76" y="202" width="142" height="28" rx="8" fill="#FFFFFF" stroke="#E8DDE0" />
                    <text x="88" y="220" fill="#454252" fontSize="10.5" fontWeight="600" fontFamily="Plus Jakarta Sans, sans-serif">
                      07 &middot; DevOps GitFlow
                    </text>
                  </svg>
                </div>
              </div>
            </div>
          </RevealSection>

          {/* 2. DOCKER — Tall Accent Bento Card (5 cols) */}
          <RevealSection className="hp-bento-card hp-bento-docker" delayMs={110}>
            <div className="hp-card-top">
              <div className="hp-card-badges">
                <span className="badge-pill badge-intermediate">Intermediate</span>
                <span className="hp-status-chip hp-status-live">
                  <span className="hp-live-dot" aria-hidden="true" />
                  Interactive Pathway
                </span>
              </div>

              {/* Layered Container Architecture SVG */}
              <div className="hp-docker-diagram" aria-hidden="true">
                <div className="hp-layer-stack">
                  <div className="hp-layer-box hp-layer-top">
                    <span>App &amp; Nginx Containers</span>
                    <code>up &middot; running</code>
                  </div>
                  <div className="hp-layer-box hp-layer-mid">
                    <span>Dockerfile Image Layers</span>
                    <code>FROM node:20</code>
                  </div>
                  <div className="hp-layer-box hp-layer-bot">
                    <span>Volumes &amp; Bridge Network</span>
                    <code>compose.yml</code>
                  </div>
                </div>
              </div>

              <h3 className="hp-bento-title">Docker</h3>
              <p className="hp-bento-desc">
                Build portable container images, write multi-stage Dockerfiles, wire persistent volumes, and orchestrate multi-service apps.
              </p>

              <ul className="hp-topic-list hp-topic-compact" aria-label="Included Docker topics">
                {dockerSampleStops.map((topic) => (
                  <li key={topic}>
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.4" aria-hidden="true">
                      <polyline points="20 6 9 17 4 12" />
                    </svg>
                    <span>{topic}</span>
                  </li>
                ))}
              </ul>
            </div>

            <div className="hp-card-bottom">
              <div className="hp-bento-progress">
                <div className="hp-bento-meta-row">
                  <span>
                    <strong>{dockerCount} Modules</strong> &middot; {dockerDuration} total
                  </span>
                  {isAuthenticated && (
                    <span className="hp-progress-ratio">
                      {dockerCompletedCount}/{dockerCount} done ({dockerPercent}%)
                    </span>
                  )}
                </div>
                {isAuthenticated && (
                  <div
                    className="hp-mini-meter"
                    role="progressbar"
                    aria-valuenow={dockerPercent}
                    aria-valuemin="0"
                    aria-valuemax="100"
                    aria-label="Docker pathway progress"
                  >
                    <div
                      className="hp-mini-meter-fill"
                      style={{ width: `${dockerPercent}%` }}
                    />
                  </div>
                )}
              </div>

              <div className="hp-bento-actions">
                <Link
                  to={isAuthenticated ? "/pathways/docker" : "/login"}
                  state={!isAuthenticated ? { from: { pathname: "/pathways/docker" } } : undefined}
                  className="hp-card-cta"
                >
                  <span>Explore Path</span>
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.3" aria-hidden="true">
                    <line x1="5" y1="12" x2="19" y2="12" />
                    <polyline points="12 5 19 12 12 19" />
                  </svg>
                </Link>
              </div>
            </div>
          </RevealSection>

          {/* 3. LINUX ESSENTIALS — Panoramic Bottom Bento Card (12 cols) */}
          <RevealSection className="hp-bento-card hp-bento-linux" delayMs={160}>
            <div className="hp-bento-linux-inner">
              <div className="hp-bento-linux-copy">
                <div className="hp-card-badges">
                  <span className="badge-pill badge-foundational">Foundational</span>
                  <span className="hp-status-chip hp-status-roadmap">
                    Curriculum Track &middot; 8 Modules
                  </span>
                </div>

                <h3 className="hp-bento-title">Linux Essentials</h3>
                <p className="hp-bento-desc">
                  Understand core Linux systems administration, file permissions, process diagnostics, systemd services, and repeatable Bash shell automation.
                </p>

                <div className="hp-linux-tags" aria-label="Linux curriculum focus areas">
                  <span>Kernel &amp; Filesystem</span>
                  <span>Users &amp; Permissions</span>
                  <span>systemd Services</span>
                  <span>Bash Automation</span>
                </div>
              </div>

              {/* Shell Tree Visual */}
              <div className="hp-linux-visual" aria-hidden="true">
                <div className="hp-linux-shell-card">
                  <div className="hp-linux-shell-head">
                    <span>bash &mdash; linux essentials</span>
                    <span className="hp-shell-pill">Foundational</span>
                  </div>
                  <div className="hp-linux-shell-lines">
                    <div>
                      <span className="hp-prompt">$</span> chmod 750 deploy.sh
                    </div>
                    <div>
                      <span className="hp-prompt">$</span> ps aux | grep systemd
                    </div>
                    <div className="hp-shell-dim">
                      /etc/systemd/system/app.service &middot; enabled
                    </div>
                  </div>
                </div>
              </div>

              <div className="hp-linux-cta-col">
                <div className="hp-linux-note">
                  Included in your DevOps roadmap alongside upcoming Kubernetes, CI/CD &amp; Terraform tracks.
                </div>
                <Link
                  to={isAuthenticated ? "/dashboard" : "/register"}
                  className="hp-card-cta"
                >
                  <span>Explore Path</span>
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.3" aria-hidden="true">
                    <line x1="5" y1="12" x2="19" y2="12" />
                    <polyline points="12 5 19 12 12 19" />
                  </svg>
                </Link>
              </div>
            </div>
          </RevealSection>
        </div>
      </div>
    </section>
  );
};

export default LearningPathsBento;
