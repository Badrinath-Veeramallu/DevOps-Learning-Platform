import { useEffect, useRef, useState } from "react";
import { usePrefersReducedMotion } from "./usePrefersReducedMotion";

const TERMINAL_SNIPPETS = [
  {
    id: "git",
    label: "Git",
    cwd: "~/devops-app",
    command: "git switch -c feat/container-ci",
    output: [
      "Switched to a new branch 'feat/container-ci'",
      "Next: stage & commit workflow changes",
    ],
  },
  {
    id: "docker",
    label: "Docker",
    cwd: "~/devops-app",
    command: "docker build -t devops-web:v1 .",
    output: [
      "=> [3/3] COPY dist /usr/share/nginx/html",
      "=> naming to docker.io/library/devops-web:v1",
    ],
  },
  {
    id: "linux",
    label: "Linux",
    cwd: "prod@node-01",
    command: "systemctl status nginx --no-pager",
    output: [
      "● nginx.service - High performance web server",
      "   Active: active (running) · uptime 14d",
    ],
  },
];

/**
 * Custom connected DevOps architecture illustration for the hero right column.
 * Combines SVG nodes (Git, Docker, Linux, CI/CD, Cloud), animated connection lines,
 * a live typing terminal preview, subtle floating chips, and gentle desktop parallax.
 */
export const HeroDevOpsIllustration = () => {
  const prefersReduced = usePrefersReducedMotion();
  const stageRef = useRef(null);
  const rafRef = useRef(null);

  const [tabIndex, setTabIndex] = useState(0);
  const [charCount, setCharCount] = useState(() => TERMINAL_SNIPPETS[0].command.length);
  const [showOutput, setShowOutput] = useState(true);
  const [parallax, setParallax] = useState({ x: 0, y: 0 });

  // Drive live typing sequence cleanly using chained timeouts (skipped if reduced motion)
  useEffect(() => {
    if (prefersReduced) return undefined;

    const currentCmd = TERMINAL_SNIPPETS[tabIndex].command;
    if (charCount < currentCmd.length) {
      const typeTimer = window.setTimeout(() => {
        setCharCount((prev) => prev + 1);
      }, 42);
      return () => window.clearTimeout(typeTimer);
    }

    if (!showOutput) {
      const outputTimer = window.setTimeout(() => {
        setShowOutput(true);
      }, 240);
      return () => window.clearTimeout(outputTimer);
    }

    const cycleTimer = window.setTimeout(() => {
      setTabIndex((prev) => (prev + 1) % TERMINAL_SNIPPETS.length);
      setCharCount(0);
      setShowOutput(false);
    }, 3000);

    return () => window.clearTimeout(cycleTimer);
  }, [prefersReduced, tabIndex, charCount, showOutput]);

  // Cancel any pending rAF parallax update on unmount
  useEffect(() => {
    return () => {
      if (rafRef.current) {
        window.cancelAnimationFrame(rafRef.current);
      }
    };
  }, []);

  const handleSelectSnippet = (index) => {
    setTabIndex(index);
    setCharCount(0);
    setShowOutput(false);
  };

  const handlePointerMove = (event) => {
    if (prefersReduced || event.pointerType !== "mouse") return;
    const container = stageRef.current;
    if (!container) return;

    const rect = container.getBoundingClientRect();
    const relX = (event.clientX - rect.left) / rect.width - 0.5;
    const relY = (event.clientY - rect.top) / rect.height - 0.5;

    if (rafRef.current) window.cancelAnimationFrame(rafRef.current);
    rafRef.current = window.requestAnimationFrame(() => {
      setParallax({
        x: Math.round(relX * 14 * 10) / 10,
        y: Math.round(relY * 10 * 10) / 10,
      });
    });
  };

  const handlePointerLeave = () => {
    if (rafRef.current) window.cancelAnimationFrame(rafRef.current);
    setParallax({ x: 0, y: 0 });
  };

  const activeSnippet = TERMINAL_SNIPPETS[tabIndex];
  const visibleCommand = prefersReduced
    ? activeSnippet.command
    : activeSnippet.command.slice(0, charCount);
  const outputVisible =
    prefersReduced || (showOutput && charCount >= activeSnippet.command.length);
  const activeId = activeSnippet.id;

  return (
    <div
      ref={stageRef}
      className="hp-hero-visual"
      onPointerMove={handlePointerMove}
      onPointerLeave={handlePointerLeave}
      aria-label="Interactive illustration of DevOps workflows connecting Git, CI/CD, Docker, Linux, and Cloud infrastructure"
    >
      {/* Ambient blush glow behind the architectural canvas */}
      <div className="hp-visual-glow" aria-hidden="true" />

      {/* Main Architectural Stage Frame */}
      <div className="hp-visual-stage">
        {/* Background SVG Connection Lines linking DevOps Pillars */}
        <svg
          className="hp-visual-lines"
          viewBox="0 0 560 460"
          fill="none"
          xmlns="http://www.w3.org/2000/svg"
          aria-hidden="true"
        >
          {/* Base soft rose curves */}
          <path
            d="M 105 92 C 195 92, 225 148, 280 185"
            className="hp-conn-base"
          />
          <path
            d="M 455 92 C 365 92, 335 148, 280 185"
            className="hp-conn-base"
          />
          <path
            d="M 96 364 C 185 364, 215 318, 280 282"
            className="hp-conn-base"
          />
          <path
            d="M 464 364 C 375 364, 345 318, 280 282"
            className="hp-conn-base"
          />
          <path
            d="M 105 92 L 455 92"
            className="hp-conn-base hp-conn-faint"
          />
          <path
            d="M 96 364 L 464 364"
            className="hp-conn-base hp-conn-faint"
          />

          {/* Animated dashed burgundy flow overlays */}
          <path
            d="M 105 92 C 195 92, 225 148, 280 185"
            className="hp-conn-flow"
          />
          <path
            d="M 455 92 C 365 92, 335 148, 280 185"
            className="hp-conn-flow hp-conn-flow-delay-1"
          />
          <path
            d="M 280 282 C 215 318, 185 364, 96 364"
            className="hp-conn-flow hp-conn-flow-delay-2"
          />
          <path
            d="M 280 282 C 345 318, 375 364, 464 364"
            className="hp-conn-flow hp-conn-flow-delay-3"
          />

          {/* Subtle connector junction dots */}
          <circle cx="105" cy="92" r="4" fill="#82535D" />
          <circle cx="455" cy="92" r="4" fill="#82535D" />
          <circle cx="96" cy="364" r="4" fill="#82535D" />
          <circle cx="464" cy="364" r="4" fill="#82535D" />
        </svg>

        {/* Top Node Row: Git -> CI/CD Pipeline */}
        <div
          className="hp-node-cluster hp-node-top-left hp-float-a"
          style={
            !prefersReduced
              ? { transform: `translate3d(${parallax.x * -0.4}px, ${parallax.y * -0.4}px, 0)` }
              : undefined
          }
        >
          <div className={`hp-node-card ${activeId === "git" ? "is-active" : ""}`}>
            <span className="hp-node-icon" aria-hidden="true">
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.1" strokeLinecap="round" strokeLinejoin="round">
                <circle cx="6" cy="6" r="3" />
                <circle cx="18" cy="6" r="3" />
                <circle cx="6" cy="18" r="3" />
                <path d="M6 9v6" />
                <path d="M18 9c0 4.5-12 2.5-12 6" />
              </svg>
            </span>
            <div className="hp-node-meta">
              <span className="hp-node-title">Git &amp; Branches</span>
              <span className="hp-node-sub">Version control</span>
            </div>
          </div>
        </div>

        <div
          className="hp-node-cluster hp-node-top-right hp-float-b"
          style={
            !prefersReduced
              ? { transform: `translate3d(${parallax.x * 0.4}px, ${parallax.y * -0.4}px, 0)` }
              : undefined
          }
        >
          <div className="hp-node-card">
            <span className="hp-node-icon" aria-hidden="true">
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.1" strokeLinecap="round" strokeLinejoin="round">
                <polyline points="22 12 18 12 15 21 9 3 6 12 2 12" />
              </svg>
            </span>
            <div className="hp-node-meta">
              <span className="hp-node-title">CI/CD Pipeline</span>
              <span className="hp-node-sub">Build &amp; verify</span>
            </div>
          </div>
        </div>

        {/* Center Interactive CLI Terminal Window */}
        <div
          className="hp-hero-terminal"
          style={
            !prefersReduced
              ? { transform: `translate3d(${parallax.x * 0.22}px, ${parallax.y * 0.22}px, 0)` }
              : undefined
          }
        >
          <div className="hp-terminal-bar">
            <div className="hp-terminal-dots" aria-hidden="true">
              <span />
              <span />
              <span />
            </div>
            <div className="hp-terminal-tabs" role="tablist" aria-label="Sample DevOps commands">
              {TERMINAL_SNIPPETS.map((item, idx) => (
                <button
                  key={item.id}
                  type="button"
                  role="tab"
                  aria-selected={idx === tabIndex}
                  className={`hp-term-tab ${idx === tabIndex ? "is-active" : ""}`}
                  onClick={() => handleSelectSnippet(idx)}
                >
                  {item.label}
                </button>
              ))}
            </div>
          </div>

          <div className="hp-terminal-body">
            <div className="hp-term-prompt-line">
              <span className="hp-term-cwd">{activeSnippet.cwd}</span>
              <span className="hp-term-dollar" aria-hidden="true">$</span>
              <code className="hp-term-cmd">
                {visibleCommand}
                {!prefersReduced && (
                  <span className="hp-term-cursor" aria-hidden="true" />
                )}
              </code>
            </div>

            <div
              className={`hp-term-output ${outputVisible ? "is-visible" : ""}`}
              aria-live="polite"
            >
              {activeSnippet.output.map((line, i) => (
                <div key={i} className="hp-term-out-line">
                  {line}
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* Bottom Node Row: Docker + Linux + Cloud */}
        <div
          className="hp-node-cluster hp-node-bottom-left hp-float-b"
          style={
            !prefersReduced
              ? { transform: `translate3d(${parallax.x * -0.35}px, ${parallax.y * 0.35}px, 0)` }
              : undefined
          }
        >
          <div className={`hp-node-card ${activeId === "linux" ? "is-active" : ""}`}>
            <span className="hp-node-icon" aria-hidden="true">
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.1" strokeLinecap="round" strokeLinejoin="round">
                <polyline points="4 17 10 11 4 5" />
                <line x1="12" y1="19" x2="20" y2="19" />
              </svg>
            </span>
            <div className="hp-node-meta">
              <span className="hp-node-title">Linux Shell</span>
              <span className="hp-node-sub">Processes &amp; bash</span>
            </div>
          </div>
        </div>

        <div
          className="hp-node-cluster hp-node-bottom-right hp-float-a"
          style={
            !prefersReduced
              ? { transform: `translate3d(${parallax.x * 0.35}px, ${parallax.y * 0.35}px, 0)` }
              : undefined
          }
        >
          <div className={`hp-node-card ${activeId === "docker" ? "is-active" : ""}`}>
            <span className="hp-node-icon" aria-hidden="true">
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.1" strokeLinecap="round" strokeLinejoin="round">
                <rect x="3" y="10" width="5" height="5" rx="1" />
                <rect x="9.5" y="10" width="5" height="5" rx="1" />
                <rect x="16" y="10" width="5" height="5" rx="1" />
                <rect x="9.5" y="4" width="5" height="5" rx="1" />
                <path d="M2 17c1.5 2.5 5 3.5 10 3.5s8.5-1 10-3.5" />
              </svg>
            </span>
            <div className="hp-node-meta">
              <span className="hp-node-title">Docker &amp; Cloud</span>
              <span className="hp-node-sub">Portable runtime</span>
            </div>
          </div>
        </div>

        {/* Cloud Infra Micro Pill anchored smoothly at top center */}
        <div className="hp-cloud-pill" aria-hidden="true">
          <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round">
            <path d="M17.5 19H9a7 7 0 1 1 6.71-9h1.79a4.5 4.5 0 1 1 0 9Z" />
          </svg>
          <span>Cloud Infrastructure Ready</span>
        </div>
      </div>
    </div>
  );
};

export default HeroDevOpsIllustration;
