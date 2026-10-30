import { useState, useEffect } from "react";
import { Link } from "react-router-dom";
import { useAuth } from "../context/useAuth";
import { UserProfileMenu } from "../components/UserProfileMenu";

const CURRENT_YEAR = new Date().getFullYear();

/**
 * DevOps Learning Platform — Clean, practical landing page focused on
 * structured learning paths, modules, and hands-on practice.
 */
export const KagePage = () => {
  const { isAuthenticated, user, logout } = useAuth();
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

  // Close mobile drawer on route navigation or resize
  useEffect(() => {
    const handleResize = () => {
      if (window.innerWidth > 768) setMobileMenuOpen(false);
    };
    window.addEventListener("resize", handleResize);
    return () => window.removeEventListener("resize", handleResize);
  }, []);

  // Smooth scroll handler for anchor links
  const scrollToSection = (e, id) => {
    e.preventDefault();
    setMobileMenuOpen(false);
    const element = document.getElementById(id);
    if (element) {
      element.scrollIntoView({ behavior: "smooth" });
    }
  };

  // 6 Core Structured Learning Paths from actual application data
  const learningPaths = [
    {
      id: "git",
      title: "Git & Collaborative Workflows",
      level: "Foundational",
      modules: "6 Modules",
      description:
        "Version control strategies, GitOps branch patterns, interactive rebasing, merge conflict resolution, and commit workflows.",
    },
    {
      id: "linux",
      title: "Linux Systems & Automation",
      level: "Foundational",
      modules: "8 Modules",
      description:
        "Linux kernel fundamentals, process management, permissions, systemd services, and bash shell automation.",
    },
    {
      id: "docker",
      title: "Docker & Container Engineering",
      level: "Intermediate",
      modules: "8 Modules",
      description:
        "Container isolation, multi-stage Dockerfile architecture, layer caching, container networking, and security best practices.",
    },
    {
      id: "kubernetes",
      title: "Kubernetes Cluster Architecture",
      level: "Advanced",
      modules: "12 Modules",
      description:
        "Workload orchestration: Deployments, StatefulSets, Services, Ingress controllers, ConfigMaps, and Helm charts.",
    },
    {
      id: "cicd",
      title: "CI/CD & GitOps Delivery",
      level: "Intermediate",
      modules: "10 Modules",
      description:
        "Automated deployment pipelines using GitHub Actions, container registries, test automation, and GitOps synchronization.",
    },
    {
      id: "iac",
      title: "Cloud Infrastructure & Terraform",
      level: "Advanced",
      modules: "9 Modules",
      description:
        "Infrastructure as Code: declarative cloud provisioning, modular configurations, remote state management, and cloud networking.",
    },
  ];

  // 3 Core Features representing actual platform capabilities
  const features = [
    {
      title: "Structured Learning Modules",
      desc: "Follow organized modules covering Linux, Git, containers, Kubernetes, and infrastructure as code.",
    },
    {
      title: "Practical Exercises",
      desc: "Work through step-by-step exercises and commands to reinforce core operational concepts.",
    },
    {
      title: "Progress Tracking",
      desc: "Track completed modules and monitor your learning advancement across each path.",
    },
  ];

  return (
    <div className="devops-landing-page">
      {/* ========================================================
          1. NAVIGATION BAR
          ======================================================== */}
      <header className="devops-navbar">
        <div className="devops-nav-container">
          {/* Brand Logo & Name */}
          <Link to="/" className="devops-brand" aria-label="DevOps Learning Platform Home">
            <div className="devops-logo-badge" aria-hidden="true">
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
                <polyline points="4 17 10 11 4 5" />
                <line x1="12" y1="19" x2="20" y2="19" />
              </svg>
            </div>
            <div className="devops-brand-text">
              <span className="brand-primary-text">DevOps</span>
              <span className="brand-secondary-text">Platform</span>
            </div>
          </Link>

          {/* Desktop Navigation Links */}
          <nav className="devops-nav-links" aria-label="Primary Navigation">
            <a href="#paths" onClick={(e) => scrollToSection(e, "paths")} className="nav-link">
              Learning Paths
            </a>
            <a href="#features" onClick={(e) => scrollToSection(e, "features")} className="nav-link">
              Features
            </a>
          </nav>

          {/* Navigation Action Buttons (Desktop) */}
          <div className="devops-nav-actions">
            {isAuthenticated ? (
              <>
                <Link to="/dashboard" className="btn-nav-primary">
                  <span>Dashboard</span>
                  <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
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

            {/* Mobile Hamburger Button */}
            <button
              type="button"
              className="mobile-hamburger-btn"
              onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
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

        {/* Mobile Navigation Drawer */}
        {mobileMenuOpen && (
          <div className="mobile-nav-drawer" role="dialog" aria-modal="true">
            <nav className="mobile-drawer-links">
              <a href="#paths" onClick={(e) => scrollToSection(e, "paths")} className="mobile-link">
                Learning Paths
              </a>
              <a href="#features" onClick={(e) => scrollToSection(e, "features")} className="mobile-link">
                Features
              </a>
            </nav>
            <div className="mobile-drawer-actions">
              {isAuthenticated ? (
                <>
                  <Link
                    to="/dashboard"
                    className="btn-hero-primary w-full"
                    onClick={() => setMobileMenuOpen(false)}
                  >
                    Dashboard ({user?.name || "User"})
                  </Link>
                  <Link
                    to="/profile"
                    className="btn-hero-secondary w-full"
                    onClick={() => setMobileMenuOpen(false)}
                  >
                    My Profile
                  </Link>
                  <button
                    type="button"
                    className="btn-hero-secondary w-full"
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
                    className="btn-hero-secondary w-full"
                    id="mobile-btn-login"
                    onClick={() => setMobileMenuOpen(false)}
                  >
                    Sign In
                  </Link>
                  <Link
                    to="/register"
                    className="btn-hero-primary w-full"
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

      {/* Main Content Area */}
      <main className="landing-content">
        {/* ========================================================
            2. HERO SECTION
            ======================================================== */}
        <section className="hero-section" id="hero">
          <div className="hero-container">
            <h1 className="hero-headline">
              Learn DevOps Step by Step
            </h1>

            <p className="hero-supporting-text">
              Learn Linux, Git, Docker, Kubernetes, CI/CD, and cloud infrastructure through structured modules and practical exercises.
            </p>

            <div className="hero-cta-group">
              <a
                href="#paths"
                onClick={(e) => scrollToSection(e, "paths")}
                className="btn-hero-primary"
                id="hero-cta-paths"
              >
                <span>Explore Learning Paths</span>
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
                  <line x1="12" y1="5" x2="12" y2="19" />
                  <polyline points="19 12 12 19 5 12" />
                </svg>
              </a>

              {isAuthenticated ? (
                <Link to="/dashboard" className="btn-hero-secondary" id="hero-cta-dashboard">
                  <span>Go to Dashboard</span>
                </Link>
              ) : (
                <Link to="/login" className="btn-hero-secondary" id="hero-cta-signin">
                  <span>Sign In</span>
                </Link>
              )}
            </div>
          </div>
        </section>

        {/* ========================================================
            3. STRUCTURED LEARNING PATHS SECTION (#paths)
            ======================================================== */}
        <section className="landing-section" id="paths">
          <div className="section-container">
            <div className="section-header text-center">
              <h2 className="section-title">Learning Paths</h2>
              <p className="section-subtitle">
                Structured courses designed to build operational skills step by step.
              </p>
            </div>

            <div className="paths-grid">
              {learningPaths.map((path) => (
                <div key={path.id} className="path-card">
                  <div className="path-card-body">
                    <div className="path-card-header">
                      <h3 className="path-card-title">{path.title}</h3>
                      <span className={`badge-pill badge-${path.level.toLowerCase()}`}>
                        {path.level}
                      </span>
                    </div>

                    <p className="path-card-desc">{path.description}</p>
                  </div>

                  <div className="path-card-footer">
                    <span className="meta-item">
                      <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" aria-hidden="true">
                        <rect width="18" height="18" x="3" y="3" rx="2" />
                        <line x1="9" y1="9" x2="15" y2="9" />
                        <line x1="9" y1="13" x2="15" y2="13" />
                      </svg>
                      {path.modules}
                    </span>

                    <Link
                      to={
                        path.id === "git"
                          ? isAuthenticated
                            ? "/pathways/git"
                            : "/register"
                          : isAuthenticated
                          ? "/dashboard"
                          : "/register"
                      }
                      className="btn-path-action"
                    >
                      <span>Start Learning</span>
                      <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" aria-hidden="true">
                        <polyline points="9 18 15 12 9 6" />
                      </svg>
                    </Link>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </section>

        {/* ========================================================
            4. PLATFORM FEATURES SECTION (#features)
            ======================================================== */}
        <section className="landing-section bg-surface-alt" id="features">
          <div className="section-container">
            <div className="section-header text-center">
              <h2 className="section-title">Platform Features</h2>
              <p className="section-subtitle">
                Core capabilities to support your learning process.
              </p>
            </div>

            <div className="features-grid">
              {features.map((feat, fIdx) => (
                <div key={fIdx} className="feature-card">
                  <h3 className="feature-title">{feat.title}</h3>
                  <p className="feature-description">{feat.desc}</p>
                </div>
              ))}
            </div>
          </div>
        </section>
      </main>

      {/* ========================================================
          5. FOOTER
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
              Structured modules and exercises for learning modern DevOps.
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
                <a href="#features" onClick={(e) => scrollToSection(e, "features")}>
                  Features
                </a>
              </li>
            </ul>
          </div>

          <div className="footer-links-col">
            <h4 className="footer-heading">Account</h4>
            <ul className="footer-links-list">
              <li><Link to="/login">Sign In</Link></li>
              <li><Link to="/register">Create Account</Link></li>
              {isAuthenticated && (
                <li><Link to="/dashboard">Dashboard</Link></li>
              )}
            </ul>
          </div>
        </div>

        <div className="footer-bottom-bar">
          <p>© {CURRENT_YEAR} DevOps Learning Platform. All rights reserved.</p>
        </div>
      </footer>
    </div>
  );
};

export default KagePage;
