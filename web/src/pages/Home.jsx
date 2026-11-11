import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { useAuth } from "../context/useAuth";
import { UserProfileMenu } from "../components/UserProfileMenu";
import { HeroDevOpsIllustration } from "../components/home/HeroDevOpsIllustration";
import { LearningPathsBento } from "../components/home/LearningPathsBento";
import {
  FinalCtaSection,
  LearningJourneySection,
  WhatYouLearnSection,
} from "../components/home/LearningJourneySection";
import { gitCurriculum } from "../data/gitCurriculum";
import { dockerCurriculum } from "../data/dockerCurriculum";
import "../styles/home.css";

const CURRENT_YEAR = new Date().getFullYear();

/**
 * DevOps Learning Platform Homepage — White + Deep Burgundy light editorial design
 * featuring a split hero with live DevOps illustration, asymmetric Bento learning paths,
 * capability overview, interactive pathway preview, and conversion CTA.
 */
export const Home = () => {
  const { isAuthenticated, user, logout } = useAuth();
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

  const liveModuleCount = gitCurriculum.length + dockerCurriculum.length;

  useEffect(() => {
    const handleResize = () => {
      if (window.innerWidth > 768) {
        setMobileMenuOpen(false);
      }
    };
    const handleKeyDown = (event) => {
      if (event.key === "Escape") {
        setMobileMenuOpen(false);
      }
    };
    window.addEventListener("resize", handleResize);
    window.addEventListener("keydown", handleKeyDown);
    return () => {
      window.removeEventListener("resize", handleResize);
      window.removeEventListener("keydown", handleKeyDown);
    };
  }, []);

  const scrollToSection = (event, sectionId) => {
    event.preventDefault();
    setMobileMenuOpen(false);
    const element = document.getElementById(sectionId);
    if (element) {
      element.scrollIntoView({ behavior: "smooth" });
    }
  };

  return (
    <div className="hp-page">
      {/* ========================================================
          1. NAVIGATION HEADER
          ======================================================== */}
      <header className="devops-navbar">
        <div className="devops-nav-container">
          <Link to="/" className="devops-brand" aria-label="DevOps Learning Platform Home">
            <div className="devops-logo-badge" aria-hidden="true">
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
                <polyline points="4 17 10 11 4 5" />
                <line x1="12" y1="19" x2="20" y2="19" />
              </svg>
            </div>
            <div className="devops-brand-text">
              <span className="brand-primary-text">DevOps</span>
              <span className="brand-secondary-text">Platform</span>
            </div>
          </Link>

          <nav className="devops-nav-links" aria-label="Primary Navigation">
            <a
              href="#paths"
              onClick={(e) => scrollToSection(e, "paths")}
              className="nav-link"
            >
              Learning Paths
            </a>
            <a
              href="#what-you-learn"
              onClick={(e) => scrollToSection(e, "what-you-learn")}
              className="nav-link"
            >
              What You&apos;ll Learn
            </a>
            <a
              href="#how-it-works"
              onClick={(e) => scrollToSection(e, "how-it-works")}
              className="nav-link"
            >
              How It Works
            </a>
          </nav>

          <div className="devops-nav-actions">
            {isAuthenticated ? (
              <>
                <Link to="/dashboard" className="btn-nav-primary">
                  <span>Dashboard</span>
                  <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" aria-hidden="true">
                    <polyline points="9 18 15 12 9 6" />
                  </svg>
                </Link>
                <UserProfileMenu />
              </>
            ) : (
              <>
                <Link to="/login" className="btn-nav-secondary" id="nav-btn-signin">
                  Sign In
                </Link>
                <Link to="/register" className="btn-nav-primary" id="nav-btn-getstarted">
                  <span>Get Started Free</span>
                </Link>
              </>
            )}

            <button
              type="button"
              className="mobile-hamburger-btn"
              onClick={() => setMobileMenuOpen((prev) => !prev)}
              aria-expanded={mobileMenuOpen}
              aria-label="Toggle navigation menu"
            >
              {mobileMenuOpen ? (
                <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                  <line x1="18" y1="6" x2="6" y2="18" />
                  <line x1="6" y1="6" x2="18" y2="18" />
                </svg>
              ) : (
                <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                  <line x1="3" y1="12" x2="21" y2="12" />
                  <line x1="3" y1="6" x2="21" y2="6" />
                  <line x1="3" y1="18" x2="21" y2="18" />
                </svg>
              )}
            </button>
          </div>
        </div>

        {mobileMenuOpen && (
          <div className="mobile-nav-drawer" role="dialog" aria-modal="true" aria-label="Mobile menu">
            <nav className="mobile-drawer-links">
              <a href="#paths" onClick={(e) => scrollToSection(e, "paths")} className="mobile-link">
                Learning Paths
              </a>
              <a href="#what-you-learn" onClick={(e) => scrollToSection(e, "what-you-learn")} className="mobile-link">
                What You&apos;ll Learn
              </a>
              <a href="#how-it-works" onClick={(e) => scrollToSection(e, "how-it-works")} className="mobile-link">
                How It Works
              </a>
            </nav>

            <div className="mobile-drawer-actions">
              {isAuthenticated ? (
                <>
                  <Link
                    to="/dashboard"
                    className="btn-hero-primary"
                    onClick={() => setMobileMenuOpen(false)}
                  >
                    Dashboard ({user?.name || "Learner"})
                  </Link>
                  <Link
                    to="/profile"
                    className="btn-hero-secondary"
                    onClick={() => setMobileMenuOpen(false)}
                  >
                    My Profile
                  </Link>
                  <button
                    type="button"
                    className="btn-hero-secondary"
                    onClick={() => {
                      setMobileMenuOpen(false);
                      logout();
                    }}
                  >
                    Sign Out
                  </button>
                </>
              ) : (
                <>
                  <Link
                    to="/login"
                    className="btn-hero-secondary"
                    id="mobile-btn-login"
                    onClick={() => setMobileMenuOpen(false)}
                  >
                    Sign In
                  </Link>
                  <Link
                    to="/register"
                    className="btn-hero-primary"
                    id="mobile-btn-register"
                    onClick={() => setMobileMenuOpen(false)}
                  >
                    Get Started Free
                  </Link>
                </>
              )}
            </div>
          </div>
        )}
      </header>

      {/* ========================================================
          2. MAIN HOMEPAGE CONTENT
          ======================================================== */}
      <main className="hp-main">
        {/* HERO SECTION */}
        <section className="hp-hero" id="hero">
          <div className="hp-hero-backdrop" aria-hidden="true">
            <div className="hp-hero-grid" />
            <div className="hp-hero-orb hp-hero-orb-1" />
            <div className="hp-hero-orb hp-hero-orb-2" />
          </div>

          <div className="hp-container hp-hero-inner">
            {/* Hero Left Copy */}
            <div className="hp-hero-copy">
              <div className="hp-hero-pill">
                <span className="hp-live-dot" aria-hidden="true" />
                <span>Hands-On DevOps Learning Platform</span>
              </div>

              <h1 className="hp-hero-title">
                Build Your DevOps Skills.{" "}
                <span className="hp-hero-accent">One Step at a Time.</span>
              </h1>

              <p className="hp-hero-desc">
                Learn Git &amp; GitHub, Docker containers, Linux fundamentals, and delivery workflows through guided interactive roadmaps, visual step animations, and practical command-line labs.
              </p>

              <div className="hp-hero-actions">
                <Link
                  to={isAuthenticated ? "/dashboard" : "/register"}
                  className="btn-hero-primary"
                  id="hero-cta-start"
                >
                  <span>Start Learning</span>
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" aria-hidden="true">
                    <line x1="5" y1="12" x2="19" y2="12" />
                    <polyline points="12 5 19 12 12 19" />
                  </svg>
                </Link>

                <a
                  href="#paths"
                  onClick={(e) => scrollToSection(e, "paths")}
                  className="btn-hero-secondary"
                  id="hero-cta-explore"
                >
                  <span>Explore Learning Paths</span>
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.3" aria-hidden="true">
                    <line x1="12" y1="5" x2="12" y2="19" />
                    <polyline points="19 12 12 19 5 12" />
                  </svg>
                </a>
              </div>

              {/* Honest factual capability strip */}
              <div className="hp-hero-facts" aria-label="Platform highlights">
                <div className="hp-fact-item">
                  <span className="hp-fact-icon" aria-hidden="true">
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.3">
                      <polyline points="20 6 9 17 4 12" />
                    </svg>
                  </span>
                  <span>{liveModuleCount} Guided Pathway Stops</span>
                </div>

                <div className="hp-fact-item">
                  <span className="hp-fact-icon" aria-hidden="true">
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.3">
                      <polyline points="4 17 10 11 4 5" />
                      <line x1="12" y1="19" x2="20" y2="19" />
                    </svg>
                  </span>
                  <span>Real CLI Workflows</span>
                </div>

                <div className="hp-fact-item">
                  <span className="hp-fact-icon" aria-hidden="true">
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.3">
                      <circle cx="12" cy="12" r="9" />
                      <polyline points="12 7 12 12 15 14" />
                    </svg>
                  </span>
                  <span>Progress Synced Automatically</span>
                </div>
              </div>
            </div>

            {/* Hero Right Connected Illustration */}
            <HeroDevOpsIllustration />
          </div>
        </section>

        {/* BENTO LEARNING PATHS */}
        <LearningPathsBento />

        {/* WHAT YOU'LL LEARN */}
        <WhatYouLearnSection />

        {/* LEARNING JOURNEY + HOW IT WORKS */}
        <LearningJourneySection />

        {/* FINAL CALL TO ACTION */}
        <FinalCtaSection />
      </main>

      {/* ========================================================
          3. FOOTER
          ======================================================== */}
      <footer className="devops-footer">
        <div className="footer-container">
          <div className="footer-brand-col">
            <div className="devops-brand">
              <div className="devops-logo-badge" aria-hidden="true">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
                  <polyline points="4 17 10 11 4 5" />
                  <line x1="12" y1="19" x2="20" y2="19" />
                </svg>
              </div>
              <div className="devops-brand-text">
                <span className="brand-primary-text">DevOps</span>
                <span className="brand-secondary-text">Platform</span>
              </div>
            </div>
            <p className="footer-tagline">
              Structured interactive pathways, visual architecture diagrams, and hands-on command exercises for modern DevOps.
            </p>
          </div>

          <div className="footer-links-col">
            <h4 className="footer-heading">Platform</h4>
            <ul className="footer-links-list">
              <li>
                <a href="#paths" onClick={(e) => scrollToSection(e, "paths")}>
                  Learning Paths
                </a>
              </li>
              <li>
                <a href="#what-you-learn" onClick={(e) => scrollToSection(e, "what-you-learn")}>
                  What You&apos;ll Learn
                </a>
              </li>
              <li>
                <a href="#how-it-works" onClick={(e) => scrollToSection(e, "how-it-works")}>
                  How It Works
                </a>
              </li>
            </ul>
          </div>

          <div className="footer-links-col">
            <h4 className="footer-heading">Explore &amp; Account</h4>
            <ul className="footer-links-list">
              <li>
                <Link
                  to={isAuthenticated ? "/pathways/git" : "/login"}
                  state={!isAuthenticated ? { from: { pathname: "/pathways/git" } } : undefined}
                >
                  Git &amp; GitHub Pathway
                </Link>
              </li>
              <li>
                <Link
                  to={isAuthenticated ? "/pathways/docker" : "/login"}
                  state={!isAuthenticated ? { from: { pathname: "/pathways/docker" } } : undefined}
                >
                  Docker Pathway
                </Link>
              </li>
              {isAuthenticated ? (
                <li><Link to="/dashboard">Dashboard</Link></li>
              ) : (
                <li><Link to="/register">Create Account</Link></li>
              )}
            </ul>
          </div>
        </div>

        <div className="footer-bottom-bar">
          <p>&copy; {CURRENT_YEAR} DevOps Learning Platform. All rights reserved.</p>
        </div>
      </footer>
    </div>
  );
};

export default Home;
