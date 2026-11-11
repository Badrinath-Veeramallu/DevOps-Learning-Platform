import { useState } from "react";
import { Link } from "react-router-dom";
import { useAuth } from "../../context/useAuth";
import { RevealSection } from "./RevealSection";

const WHAT_YOU_LEARN = [
  {
    id: "gitops",
    title: "Version Control & GitOps",
    tag: "git switch · rebase",
    description:
      "Manage repositories confidently with structured commits, safe branching strategies, clean merges, and collaborative pull requests.",
    icon: (
      <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
        <circle cx="6" cy="6" r="3" />
        <circle cx="18" cy="6" r="3" />
        <circle cx="6" cy="18" r="3" />
        <path d="M6 9v6" />
        <path d="M18 9c0 4.5-12 2.5-12 6" />
      </svg>
    ),
  },
  {
    id: "containers",
    title: "Docker & Multi-Container Apps",
    tag: "Dockerfile · compose",
    description:
      "Package applications cleanly, optimize layer caching, mount persistent volumes, and connect multi-service stacks via Docker Compose.",
    icon: (
      <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
        <rect x="3" y="10" width="5" height="5" rx="1" />
        <rect x="9.5" y="10" width="5" height="5" rx="1" />
        <rect x="16" y="10" width="5" height="5" rx="1" />
        <rect x="9.5" y="4" width="5" height="5" rx="1" />
        <path d="M2 17c1.5 2.5 5 3.5 10 3.5s8.5-1 10-3.5" />
      </svg>
    ),
  },
  {
    id: "linux",
    title: "Linux Systems & Automation",
    tag: "systemd · bash",
    description:
      "Navigate Linux file hierarchies, manage users and permissions, inspect running processes, and script repeatable operational tasks.",
    icon: (
      <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
        <polyline points="4 17 10 11 4 5" />
        <line x1="12" y1="19" x2="20" y2="19" />
      </svg>
    ),
  },
  {
    id: "delivery",
    title: "Production Delivery Habits",
    tag: "CI/CD · cloud",
    description:
      "Connect commits to automated builds, image publishing, and deployment checks used across modern DevOps engineering teams.",
    icon: (
      <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
        <path d="M17.5 19H9a7 7 0 1 1 6.71-9h1.79a4.5 4.5 0 1 1 0 9Z" />
      </svg>
    ),
  },
];

const JOURNEY_STEPS = [
  {
    step: "01",
    title: "Follow a Structured Curved Pathway",
    description:
      "Progress through curated stops in order so every concept reinforces the last instead of jumping blindly between isolated docs.",
    previewLabel: "Completed Stop",
    previewTitle: "01. Introduction to Git & Setup",
    status: "done",
  },
  {
    step: "02",
    title: "Watch Interactive Visual Diagrams",
    description:
      "Inspect step-by-step visual flows for Git trees and Docker architectures paired directly with copy-ready CLI commands.",
    previewLabel: "Active Stop",
    previewTitle: "04. Branching, Merging & Conflict Resolution",
    status: "active",
  },
  {
    step: "03",
    title: "Sync Milestones Across Web & Mobile",
    description:
      "Mark completed modules, build consistency on your activity heatmap, and pick up your pathway from anywhere.",
    previewLabel: "Next Stop",
    previewTitle: "03. Dockerfile & Custom Images",
    status: "upcoming",
  },
];

/**
 * Additional cohesive sections: What You'll Learn, Interactive Learning Journey
 * + How It Works showcase, and Final Start Learning CTA banner.
 */
export const WhatYouLearnSection = () => (
  <section
    className="hp-section hp-section-alt"
    id="what-you-learn"
    aria-labelledby="learn-heading"
  >
    <div className="hp-container">
      <RevealSection className="hp-section-header">
        <span className="hp-eyebrow">What You&apos;ll Learn</span>
        <h2 className="hp-section-title" id="learn-heading">
          Practical engineering skills, built progressively
        </h2>
        <p className="hp-section-subtitle">
          Focus on durable core tools before layering complexity — every concept connects back to real workflows.
        </p>
      </RevealSection>

      <div className="hp-learn-grid">
        {WHAT_YOU_LEARN.map((item, idx) => (
          <RevealSection key={item.id} className="hp-learn-card" delayMs={idx * 60}>
            <div className="hp-learn-top">
              <div className="hp-learn-icon" aria-hidden="true">
                {item.icon}
              </div>
              <code className="hp-learn-tag">{item.tag}</code>
            </div>
            <h3 className="hp-learn-title">{item.title}</h3>
            <p className="hp-learn-desc">{item.description}</p>
          </RevealSection>
        ))}
      </div>
    </div>
  </section>
);

export const LearningJourneySection = () => {
  const [selectedStep, setSelectedStep] = useState(1);

  return (
    <section
      className="hp-section"
      id="how-it-works"
      aria-labelledby="journey-heading"
    >
      <div className="hp-container">
        <div className="hp-journey-layout">
          {/* Left: How the Platform Works Steps */}
          <RevealSection className="hp-journey-copy">
            <span className="hp-eyebrow">How It Works</span>
            <h2 className="hp-section-title hp-title-left" id="journey-heading">
              A calm, visual learning journey instead of scattered tutorials
            </h2>
            <p className="hp-journey-intro">
              Click any step below to see how pathways guide you from fundamentals to working operational confidence.
            </p>

            <div className="hp-steps-list">
              {JOURNEY_STEPS.map((item, index) => {
                const isSelected = index === selectedStep;
                return (
                  <button
                    key={item.step}
                    type="button"
                    className={`hp-step-item ${isSelected ? "is-selected" : ""}`}
                    onClick={() => setSelectedStep(index)}
                  >
                    <span className="hp-step-num">{item.step}</span>
                    <div className="hp-step-body">
                      <h3 className="hp-step-title">{item.title}</h3>
                      <p className="hp-step-desc">{item.description}</p>
                    </div>
                  </button>
                );
              })}
            </div>
          </RevealSection>

          {/* Right: Curved Pathway Showcase Preview */}
          <RevealSection className="hp-journey-preview" delayMs={90}>
            <div className="hp-road-card" aria-label="Interactive curved pathway preview">
              <div className="hp-road-header">
                <span className="hp-road-kicker">Interactive Roadmap View</span>
                <span className="hp-road-pill">Git &amp; Docker Pathways</span>
              </div>

              <div className="hp-road-canvas">
                <svg
                  className="hp-road-svg"
                  viewBox="0 0 420 340"
                  fill="none"
                  aria-hidden="true"
                >
                  <path
                    d="M 88 46 C 88 118, 332 104, 332 170 C 332 236, 94 222, 94 294"
                    stroke="#E7D4D7"
                    strokeWidth="26"
                    strokeLinecap="round"
                  />
                  <path
                    d="M 88 46 C 88 118, 332 104, 332 170 C 332 236, 94 222, 94 294"
                    stroke="#82535D"
                    strokeWidth="2.5"
                    strokeDasharray="7 7"
                    strokeLinecap="round"
                    className="hp-road-anim"
                  />
                </svg>

                {JOURNEY_STEPS.map((item, idx) => {
                  const isHighlighted = idx === selectedStep;
                  const alignClass = idx === 1 ? "hp-stop-right" : "hp-stop-left";
                  return (
                    <button
                      key={item.step}
                      type="button"
                      onClick={() => setSelectedStep(idx)}
                      className={`hp-road-stop ${alignClass} is-${item.status} ${
                        isHighlighted ? "is-focused" : ""
                      }`}
                    >
                      <span className="hp-stop-badge" aria-hidden="true">
                        {item.status === "done" ? (
                          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round">
                            <polyline points="20 6 9 17 4 12" />
                          </svg>
                        ) : (
                          item.step
                        )}
                      </span>
                      <span className="hp-stop-info">
                        <small>{item.previewLabel}</small>
                        <strong>{item.previewTitle}</strong>
                      </span>
                    </button>
                  );
                })}
              </div>
            </div>
          </RevealSection>
        </div>
      </div>
    </section>
  );
};

export const FinalCtaSection = () => {
  const { isAuthenticated } = useAuth();

  return (
    <section className="hp-section hp-section-cta" aria-labelledby="final-cta-heading">
      <div className="hp-container">
        <RevealSection className="hp-cta-banner">
          <div className="hp-cta-glow" aria-hidden="true" />
          <div className="hp-cta-content">
            <span className="hp-eyebrow">Ready When You Are</span>
            <h2 className="hp-cta-title" id="final-cta-heading">
              Start building real DevOps confidence today
            </h2>
            <p className="hp-cta-subtitle">
              Follow interactive pathways across Git &amp; GitHub and Docker, practice essential CLI commands, and track every completed stop.
            </p>

            <div className="hp-cta-buttons">
              <Link
                to={isAuthenticated ? "/dashboard" : "/register"}
                className="btn-hero-primary"
              >
                <span>Start Learning</span>
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.4" aria-hidden="true">
                  <line x1="5" y1="12" x2="19" y2="12" />
                  <polyline points="12 5 19 12 12 19" />
                </svg>
              </Link>

              <Link
                to={isAuthenticated ? "/pathways/git" : "/login"}
                state={!isAuthenticated ? { from: { pathname: "/pathways/git" } } : undefined}
                className="btn-hero-secondary"
              >
                <span>Explore Git Pathway</span>
              </Link>
            </div>
          </div>
        </RevealSection>
      </div>
    </section>
  );
};
