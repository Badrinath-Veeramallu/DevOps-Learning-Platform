import { useState, useEffect } from "react";
import { Link } from "react-router-dom";
import { useAuth } from "../context/useAuth";
import { DevOpsCanvas3D } from "../components/DevOpsCanvas3D";

const CURRENT_YEAR = new Date().getFullYear();

/**
 * KagePage — Transformed DevOps Learning Platform Landing Page
 *
 * Immersive, cinematic, interactive 3D WebGL infrastructure visualization
 * paired with a professional, high-conversion developer-tools landing page.
 *
 * Prominent Login & Sign Up buttons visible above the fold and in the top nav,
 * wired directly to /login and /register via React Router.
 */
export const KagePage = () => {
  const { isAuthenticated, user } = useAuth();
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const [activeTab, setActiveTab] = useState("k8s");
  const [activePipelineStep, setActivePipelineStep] = useState(2);

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

  // 6 Core Structured Learning Paths
  const learningPaths = [
    {
      id: "linux",
      title: "Linux Systems & Automation",
      level: "Foundational",
      levelColor: "lime",
      modules: "8 Modules",
      labs: "14 Hands-on Labs",
      description:
        "Master Linux kernel fundamentals, process management, permissions, systemd services, and production bash shell automation.",
      skills: ["Bash Scripting", "Systemd", "Process Trees", "Linux Networking", "Permissions & ACLs"],
      icon: (
        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
          <polyline points="4 17 10 11 4 5" />
          <line x1="12" y1="19" x2="20" y2="19" />
        </svg>
      ),
    },
    {
      id: "git",
      title: "Git & Collaborative Workflows",
      level: "Foundational",
      levelColor: "lime",
      modules: "6 Modules",
      labs: "10 Hands-on Labs",
      description:
        "Professional version control strategies, GitOps branch patterns, interactive rebasing, merge conflicts, and commit signing.",
      skills: ["GitOps Flow", "Interactive Rebase", "Cherry-picking", "Hooks Automation", "Signed Commits"],
      icon: (
        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
          <line x1="6" y1="3" x2="6" y2="15" />
          <circle cx="18" cy="6" r="3" />
          <circle cx="6" cy="18" r="3" />
          <path d="M18 9a9 9 0 0 1-9 9" />
        </svg>
      ),
    },
    {
      id: "docker",
      title: "Docker & Container Engineering",
      level: "Intermediate",
      levelColor: "cyan",
      modules: "8 Modules",
      labs: "16 Hands-on Labs",
      description:
        "Container isolation, multi-stage Dockerfile architecture, layer caching, bridge networks, and security hardening against CVEs.",
      skills: ["Multi-Stage Builds", "cgroups & Namespaces", "Docker Compose", "Image Optimization", "Trivy Scanning"],
      icon: (
        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
          <rect x="2" y="2" width="20" height="8" rx="2" />
          <rect x="2" y="14" width="20" height="8" rx="2" />
          <line x1="6" y1="6" x2="6.01" y2="6" />
          <line x1="6" y1="18" x2="6.01" y2="18" />
        </svg>
      ),
    },
    {
      id: "kubernetes",
      title: "Kubernetes Cluster Architecture",
      level: "Advanced",
      levelColor: "cyan",
      modules: "12 Modules",
      labs: "24 Hands-on Labs",
      description:
        "Production orchestration: Deployments, StatefulSets, Ingress controllers, ConfigMaps, Helm charts, and custom resource operators.",
      skills: ["Pod Lifecycles", "Service Mesh", "Helm Blueprints", "Ingress NGINX", "Rolling Updates"],
      icon: (
        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
          <polygon points="12 2 2 7 12 12 22 7 12 2" />
          <polyline points="2 17 12 22 22 17" />
          <polyline points="2 12 12 17 22 12" />
        </svg>
      ),
    },
    {
      id: "cicd",
      title: "CI/CD & GitOps Delivery",
      level: "Intermediate",
      levelColor: "cyan",
      modules: "10 Modules",
      labs: "18 Hands-on Labs",
      description:
        "Design zero-downtime pipelines with GitHub Actions, GitLab CI, container publishing, automated tests, and ArgoCD synchronization.",
      skills: ["GitHub Actions", "ArgoCD", "Canary Deployments", "Secret Vaulting", "Artifact Registries"],
      icon: (
        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
          <circle cx="12" cy="12" r="10" />
          <polyline points="12 6 12 12 16 14" />
        </svg>
      ),
    },
    {
      id: "iac",
      title: "Cloud Infrastructure & Terraform",
      level: "Advanced",
      levelColor: "lime",
      modules: "9 Modules",
      labs: "15 Hands-on Labs",
      description:
        "Infrastructure as Code: declarative cloud provisioning on AWS and GCP, remote state management, modular architecture, and drift control.",
      skills: ["Terraform HCL", "VPC Networking", "EKS Clusters", "Remote S3 State", "Policy as Code"],
      icon: (
        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
          <path d="M17.5 19H9a7 7 0 1 1 6.71-9h1.79a4.5 4.5 0 1 1 0 9Z" />
        </svg>
      ),
    },
  ];

  // 4 Core Features
  const features = [
    {
      title: "Structured Learning Paths",
      badge: "Linear Progression",
      desc: "Step-by-step curriculum carefully sequenced from Linux command-line essentials to high-availability multi-region Kubernetes clusters.",
      icon: (
        <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
          <path d="M4 19.5v-15A2.5 2.5 0 0 1 6.5 2H20v20H6.5a2.5 2.5 0 0 1-2.5-2.5Z" />
          <path d="M6 6h10" />
          <path d="M6 10h10" />
        </svg>
      ),
    },
    {
      title: "Hands-on Labs",
      badge: "Browser Sandboxes",
      desc: "Practice with real commands and real systems. Provision ephemeral Kubernetes clusters, debug container networks, and run live pipelines.",
      icon: (
        <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
          <polyline points="4 17 10 11 4 5" />
          <line x1="12" y1="19" x2="20" y2="19" />
        </svg>
      ),
    },
    {
      title: "Progress Tracking",
      badge: "Live Telemetry",
      desc: "Visual milestone tracking with completed module verifications, hands-on lab scores, and real-time skill tree mastery indicators.",
      icon: (
        <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
          <line x1="18" y1="20" x2="18" y2="10" />
          <line x1="12" y1="20" x2="12" y2="4" />
          <line x1="6" y1="20" x2="6" y2="14" />
        </svg>
      ),
    },
    {
      title: "Real-world DevOps Skills",
      badge: "Production Ready",
      desc: "Work on genuine production failure scenarios: resolve CrashLoopBackOffs, configure blue/green rollouts, and secure sensitive credentials.",
      icon: (
        <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
          <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10" />
        </svg>
      ),
    },
  ];

  // Pipeline stages for interactive lab walkthrough
  const pipelineSteps = [
    {
      id: 0,
      title: "1. Code & Commit",
      tool: "Git & Pre-commit",
      detail: "Linting, static code analysis, and GPG commit validation triggered on git push.",
      status: "Verified",
    },
    {
      id: 1,
      title: "2. Build & Test",
      tool: "GitHub Actions CI",
      detail: "Automated unit test runners, integration tests, and build artifacts generated in 42s.",
      status: "Passed",
    },
    {
      id: 2,
      title: "3. Docker & Security",
      tool: "Multi-stage & Trivy",
      detail: "Optimized 28MB distroless container image built and scanned with 0 CVE vulnerabilities.",
      status: "Secured",
    },
    {
      id: 3,
      title: "4. GitOps Sync",
      tool: "ArgoCD & Kubernetes",
      detail: "Declarative cluster sync with automated health checks and rolling zero-downtime rollout.",
      status: "Synced",
    },
    {
      id: 4,
      title: "5. Telemetry & Health",
      tool: "Prometheus & Grafana",
      detail: "P99 latency monitored under 18ms with 100% pod availability across 3 availability zones.",
      status: "Healthy",
    },
  ];

  return (
    <div className="devops-landing-page">
      {/* 3D WebGL Background Canvas */}
      <DevOpsCanvas3D />

      {/* Subtle grid pattern & ambient gradients */}
      <div className="landing-ambient-overlay" aria-hidden="true">
        <div className="landing-grid-pattern" />
        <div className="landing-glow-cyan" />
        <div className="landing-glow-lime" />
      </div>

      {/* ========================================================
          1. TOP NAVIGATION BAR (Visible, Sticky, Responsive)
          ======================================================== */}
      <header className="devops-navbar">
        <div className="devops-nav-container">
          {/* Brand Logo */}
          <Link to="/" className="devops-brand" aria-label="DevOps Learning Platform Home">
            <div className="devops-logo-badge">
              <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
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
            <a href="#labs" onClick={(e) => scrollToSection(e, "labs")} className="nav-link">
              Architecture & Labs
            </a>
            <a href="#about" onClick={(e) => scrollToSection(e, "about")} className="nav-link">
              About
            </a>
          </nav>

          {/* Prominent Action Buttons (Desktop) */}
          <div className="devops-nav-actions">
            {isAuthenticated ? (
              <Link to="/dashboard" className="btn-nav-primary">
                <span>Dashboard ({user?.name || "User"})</span>
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
                  <polyline points="9 18 15 12 9 6" />
                </svg>
              </Link>
            ) : (
              <>
                <Link to="/login" className="btn-nav-secondary" id="nav-btn-signin">
                  Sign In
                </Link>
                <Link to="/register" className="btn-nav-primary" id="nav-btn-getstarted">
                  <span>Get Started</span>
                  <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
                    <polyline points="9 18 15 12 9 6" />
                  </svg>
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
                <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                  <line x1="18" y1="6" x2="6" y2="18" />
                  <line x1="6" y1="6" x2="18" y2="18" />
                </svg>
              ) : (
                <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
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
              <a href="#labs" onClick={(e) => scrollToSection(e, "labs")} className="mobile-link">
                Architecture & Labs
              </a>
              <a href="#about" onClick={(e) => scrollToSection(e, "about")} className="mobile-link">
                About
              </a>
            </nav>
            <div className="mobile-drawer-actions">
              {isAuthenticated ? (
                <Link
                  to="/dashboard"
                  className="btn-hero-primary w-full"
                  onClick={() => setMobileMenuOpen(false)}
                >
                  Go to Command Center
                </Link>
              ) : (
                <>
                  <Link
                    to="/register"
                    className="btn-hero-primary w-full"
                    id="mobile-btn-register"
                    onClick={() => setMobileMenuOpen(false)}
                  >
                    Get Started Free
                  </Link>
                  <Link
                    to="/login"
                    className="btn-hero-secondary w-full"
                    id="mobile-btn-login"
                    onClick={() => setMobileMenuOpen(false)}
                  >
                    Sign In
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
            2. HERO SECTION (First Viewport - Exact Copy & CTAs)
            ======================================================== */}
        <section className="hero-section" id="hero">
          <div className="hero-container">
            {/* Visual contrast shield ensuring zero animation overlap on text */}
            <div className="hero-text-shield" aria-hidden="true" />

            {/* Live Status Pill */}
            <div className="hero-eyebrow-badge">
              <span className="eyebrow-dot" />
              <span className="eyebrow-text">DevOps Learning Platform</span>
              <span className="eyebrow-separator">•</span>
              <span className="eyebrow-subtext">Hands-on Cloud Systems</span>
            </div>

            {/* Hero Headline */}
            <h1 className="hero-headline">
              Master DevOps by <br />
              <span className="headline-gradient">Building Real Systems</span>
            </h1>

            {/* Supporting Text */}
            <p className="hero-supporting-text">
              Learn Linux, Git, Docker, Kubernetes, CI/CD, cloud infrastructure, and automation through structured learning paths and hands-on practice.
            </p>

            {/* Prominent Hero Action Buttons (Above the fold) */}
            <div className="hero-cta-group">
              <Link to="/register" className="btn-hero-primary" id="hero-cta-getstarted">
                <span>Get Started</span>
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
                  <line x1="5" y1="12" x2="19" y2="12" />
                  <polyline points="12 5 19 12 12 19" />
                </svg>
              </Link>

              <Link to="/login" className="btn-hero-secondary" id="hero-cta-signin">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                  <rect width="18" height="11" x="3" y="11" rx="2" ry="2" />
                  <path d="M7 11V7a5 5 0 0 1 10 0v4" />
                </svg>
                <span>Sign In</span>
              </Link>
            </div>

            {/* Short Feature Summary Bar (Directly below hero) */}
            <div className="hero-features-summary" aria-label="Feature Overview">
              <div className="summary-pill">
                <span className="summary-icon">✦</span>
                <span className="summary-label">Structured Learning Paths</span>
              </div>
              <div className="summary-pill">
                <span className="summary-icon">⚡</span>
                <span className="summary-label">Hands-on Labs</span>
              </div>
              <div className="summary-pill">
                <span className="summary-icon">📊</span>
                <span className="summary-label">Progress Tracking</span>
              </div>
              <div className="summary-pill">
                <span className="summary-icon">🚀</span>
                <span className="summary-label">Real-world DevOps Skills</span>
              </div>
            </div>

            {/* Interactive Terminal / Cluster Console Mockup */}
            <div className="hero-console-mockup" aria-label="Live System Console">
              <div className="console-header">
                <div className="console-window-dots">
                  <span className="console-dot dot-close" />
                  <span className="console-dot dot-min" />
                  <span className="console-dot dot-max" />
                </div>

                <div className="console-tabs" role="tablist">
                  <button
                    type="button"
                    role="tab"
                    aria-selected={activeTab === "k8s"}
                    className={`console-tab ${activeTab === "k8s" ? "active" : ""}`}
                    onClick={() => setActiveTab("k8s")}
                  >
                    kubectl (k8s-cluster)
                  </button>
                  <button
                    type="button"
                    role="tab"
                    aria-selected={activeTab === "cicd"}
                    className={`console-tab ${activeTab === "cicd" ? "active" : ""}`}
                    onClick={() => setActiveTab("cicd")}
                  >
                    github-actions (ci-cd)
                  </button>
                  <button
                    type="button"
                    role="tab"
                    aria-selected={activeTab === "tf"}
                    className={`console-tab ${activeTab === "tf" ? "active" : ""}`}
                    onClick={() => setActiveTab("tf")}
                  >
                    terraform (aws-infra)
                  </button>
                </div>

                <div className="console-status-indicator">
                  <span className="status-live-dot" />
                  <span className="status-text">Production Mesh</span>
                </div>
              </div>

              <div className="console-body">
                {activeTab === "k8s" && (
                  <div className="console-content">
                    <p className="cmd-line"><span className="prompt">$</span> kubectl get pods -n devops-platform -o wide</p>
                    <p className="cmd-header"><span className="c-muted">NAME</span>                            READY   STATUS    RESTARTS   AGE    IP             NODE</p>
                    <p className="cmd-row">api-gateway-7b9d4f-x18m         1/1     <span className="c-teal">Running</span>   0          38m    10.244.1.18    worker-node-1</p>
                    <p className="cmd-row">auth-service-68fc8c-q29v        1/1     <span className="c-teal">Running</span>   0          38m    10.244.2.45    worker-node-2</p>
                    <p className="cmd-row">email-verifier-54df7e-91zp      1/1     <span className="c-teal">Running</span>   0          14m    10.244.1.92    worker-node-1</p>
                    <p className="cmd-row">cluster-db-primary-0            1/1     <span className="c-teal">Running</span>   0          2d     10.244.3.12    worker-node-3</p>
                    <p className="cmd-line mt-2"><span className="prompt">$</span> helm status platform-core --namespace devops-platform</p>
                    <p className="cmd-success">STATUS: deployed • REVISION: 4 • TEST SUITE: None • NOTES: Cluster healthy [100% OK]</p>
                  </div>
                )}

                {activeTab === "cicd" && (
                  <div className="console-content">
                    <p className="cmd-line"><span className="prompt">$</span> gh run list --workflow=deploy-production.yml --limit=1</p>
                    <p className="cmd-row"><span className="c-teal">✓</span> Lint & Code Quality (oxlint + eslint) ........... <span className="c-teal">PASS</span> (18s)</p>
                    <p className="cmd-row"><span className="c-teal">✓</span> Integration & OTP Tests (jest) ................... <span className="c-teal">PASS</span> (42s)</p>
                    <p className="cmd-row"><span className="c-teal">✓</span> Docker Multi-stage Build & Layer Cache .......... <span className="c-teal">PASS</span> (1m 12s)</p>
                    <p className="cmd-row"><span className="c-teal">✓</span> Trivy Vulnerability Scan (0 CRITICAL, 0 HIGH) ... <span className="c-teal">PASS</span> (15s)</p>
                    <p className="cmd-row"><span className="c-indigo">●</span> ArgoCD GitOps Sync to K8s Cluster (v2.4.0) ...... <span className="c-teal">SYNCED</span> (8s)</p>
                    <p className="cmd-success mt-2">✨ Pipeline succeeded in 2m 35s — All zero-downtime health gates confirmed</p>
                  </div>
                )}

                {activeTab === "tf" && (
                  <div className="console-content">
                    <p className="cmd-line"><span className="prompt">$</span> terraform apply -auto-approve</p>
                    <p className="cmd-row"><span className="c-muted">module.vpc.aws_subnet.private[0]:</span> Refreshing state... [id=subnet-0a42e]</p>
                    <p className="cmd-row"><span className="c-muted">module.eks.aws_eks_cluster.main:</span> Refreshing state... [id=devops-prod-eks]</p>
                    <p className="cmd-row"><span className="c-indigo">module.security_groups.aws_security_group.lb:</span> Modifications applied (TLS 1.3 enforced)</p>
                    <p className="cmd-success mt-2">Apply complete! Resources: 0 added, 1 changed, 0 destroyed.</p>
                    <p className="cmd-row"><span className="c-teal">Outputs:</span></p>
                    <p className="cmd-row">  cluster_endpoint = "https://B4D9721.gr7.us-east-1.eks.amazonaws.com"</p>
                    <p className="cmd-row">  telemetry_grafana = "https://dashboards.internal.devops-platform.io"</p>
                  </div>
                )}
              </div>
            </div>
          </div>
        </section>

        {/* ========================================================
            3. STRUCTURED LEARNING PATHS SECTION (#paths)
            ======================================================== */}
        <section className="landing-section" id="paths">
          <div className="section-container">
            <div className="section-header text-center">
              <span className="section-pill">Curriculum Blueprints</span>
              <h2 className="section-title">Structured Learning Paths</h2>
              <p className="section-subtitle">
                A progressive, production-aligned journey designed to take you from foundational Linux systems to enterprise Kubernetes and GitOps automation.
              </p>
            </div>

            <div className="paths-grid">
              {learningPaths.map((path) => (
                <div key={path.id} className="path-card">
                  <div className="path-card-top">
                    <div className="path-icon-container">{path.icon}</div>
                    <div className="path-badges">
                      <span className={`badge-pill badge-${path.levelColor}`}>
                        {path.level}
                      </span>
                    </div>
                  </div>

                  <h3 className="path-card-title">{path.title}</h3>
                  <p className="path-card-desc">{path.description}</p>

                  <div className="path-meta-row">
                    <span className="meta-item">
                      <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                        <rect width="18" height="18" x="3" y="3" rx="2" />
                        <line x1="9" y1="9" x2="15" y2="9" />
                        <line x1="9" y1="13" x2="15" y2="13" />
                      </svg>
                      {path.modules}
                    </span>
                    <span className="meta-item">
                      <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                        <polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2" />
                      </svg>
                      {path.labs}
                    </span>
                  </div>

                  <div className="path-skills-list">
                    {path.skills.map((skill, sIdx) => (
                      <span key={sIdx} className="skill-chip">
                        {skill}
                      </span>
                    ))}
                  </div>

                  <div className="path-card-action">
                    <Link to="/register" className="btn-path-start">
                      <span>Start Path</span>
                      <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
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
              <span className="section-pill">Engineered For Mastery</span>
              <h2 className="section-title">Core Platform Capabilities</h2>
              <p className="section-subtitle">
                Everything you need to gain real-world confidence, build production reflexes, and master DevOps architecture.
              </p>
            </div>

            <div className="features-grid">
              {features.map((feat, fIdx) => (
                <div key={fIdx} className="feature-card">
                  <div className="feature-icon-wrapper">{feat.icon}</div>
                  <span className="feature-badge">{feat.badge}</span>
                  <h3 className="feature-title">{feat.title}</h3>
                  <p className="feature-description">{feat.desc}</p>
                </div>
              ))}
            </div>
          </div>
        </section>

        {/* ========================================================
            5. ARCHITECTURE & HANDS-ON LABS SECTION (#labs)
            ======================================================== */}
        <section className="landing-section" id="labs">
          <div className="section-container">
            <div className="section-header text-center">
              <span className="section-pill">Interactive Pipeline Architecture</span>
              <h2 className="section-title">From Code Commit to Kubernetes Mesh</h2>
              <p className="section-subtitle">
                Explore an actual production deployment pipeline. Every step represents a live lab environment where you diagnose, build, and deploy.
              </p>
            </div>

            {/* Interactive Pipeline Step Selector */}
            <div className="pipeline-walkthrough">
              <div className="pipeline-steps-nav">
                {pipelineSteps.map((step) => (
                  <button
                    key={step.id}
                    type="button"
                    className={`pipeline-step-btn ${activePipelineStep === step.id ? "active" : ""}`}
                    onClick={() => setActivePipelineStep(step.id)}
                  >
                    <span className="step-num">{step.id + 1}</span>
                    <div className="step-btn-text">
                      <span className="step-name">{step.title.split(". ")[1]}</span>
                      <span className="step-tool">{step.tool}</span>
                    </div>
                  </button>
                ))}
              </div>

              {/* Active Pipeline Card Detail */}
              <div className="pipeline-detail-card">
                <div className="pipeline-detail-header">
                  <div className="detail-title-group">
                    <span className="detail-tag">{pipelineSteps[activePipelineStep].tool}</span>
                    <h3>{pipelineSteps[activePipelineStep].title}</h3>
                  </div>
                  <div className="detail-status-badge">
                    <span className="status-dot" />
                    <span>{pipelineSteps[activePipelineStep].status}</span>
                  </div>
                </div>

                <p className="pipeline-detail-desc">
                  {pipelineSteps[activePipelineStep].detail}
                </p>

                <div className="pipeline-terminal-preview">
                  <div className="preview-header">
                    <span>Terminal Output • Stage {activePipelineStep + 1} Verification</span>
                  </div>
                  <div className="preview-body">
                    {activePipelineStep === 0 && (
                      <p>
                        <span className="c-teal">➜</span> <span className="c-muted">git commit -S -m "feat(auth): add cryptographic email OTP verification"</span><br />
                        [main 4f1a28] feat(auth): add cryptographic email OTP verification<br />
                        12 files changed, 412 insertions(+), 84 deletions(-)<br />
                        <span className="c-teal">gpg: Good signature from "DevOps Core Release Key" [ultimate]</span>
                      </p>
                    )}
                    {activePipelineStep === 1 && (
                      <p>
                        <span className="c-teal">➜</span> <span className="c-muted">npm test -- --coverage</span><br />
                        PASS src/services/emailService.test.js<br />
                        PASS src/controllers/authController.test.js<br />
                        Test Suites: 8 passed, 8 total • Tests: 42 passed, 42 total<br />
                        <span className="c-teal">Coverage: Statements 98.4%, Branches 96.2%, Functions 100%</span>
                      </p>
                    )}
                    {activePipelineStep === 2 && (
                      <p>
                        <span className="c-teal">➜</span> <span className="c-muted">docker build --target production -t devops-platform/api:v2.4.0 .</span><br />
                        [+] Building 14.8s (18/18) FINISHED<br />
                        =&gt; CACHED [internal] load build definition from Dockerfile<br />
                        =&gt; export to image: devops-platform/api:v2.4.0 (28.4 MB)<br />
                        <span className="c-teal">➜ trivy image devops-platform/api:v2.4.0</span><br />
                        <span className="c-teal">Total: 0 (UNKNOWN: 0, LOW: 0, MEDIUM: 0, HIGH: 0, CRITICAL: 0)</span>
                      </p>
                    )}
                    {activePipelineStep === 3 && (
                      <p>
                        <span className="c-teal">➜</span> <span className="c-muted">argocd app sync devops-platform-prod</span><br />
                        TIMESTAMP                  GROUP        KIND   NAMESPACE  NAME           STATUS  HEALTH<br />
                        2026-10-25T00:52:10Z   apps   Deployment   devops     api-gateway    Synced  Healthy<br />
                        2026-10-25T00:52:12Z          Service      devops     api-service    Synced  Healthy<br />
                        <span className="c-teal">App 'devops-platform-prod' synced successfully. Revision: 4f1a28</span>
                      </p>
                    )}
                    {activePipelineStep === 4 && (
                      <p>
                        <span className="c-teal">➜</span> <span className="c-muted">curl -s https://metrics.devops-platform.io/healthz</span><br />
                        &#123;"status":"healthy","database":"connected","otp_service":"ready","p99_latency_ms":16.4&#125;<br />
                        <span className="c-teal">Cluster SLO: 99.99% Availability • Zero error budget burn</span>
                      </p>
                    )}
                  </div>
                </div>

                <div className="pipeline-action-bar">
                  <Link to="/register" className="btn-hero-primary">
                    Launch Interactive Lab
                  </Link>
                </div>
              </div>
            </div>
          </div>
        </section>

        {/* ========================================================
            6. ABOUT SECTION (#about)
            ======================================================== */}
        <section className="landing-section bg-surface-alt" id="about">
          <div className="section-container">
            <div className="about-grid">
              <div className="about-text-column">
                <span className="section-pill">Platform Philosophy</span>
                <h2 className="section-title">Built for Engineers, by Engineers</h2>
                <p className="about-p">
                  DevOps is not about memorizing configuration syntax — it is about understanding how distributed systems communicate, scale, recover, and deliver value safely.
                </p>
                <p className="about-p">
                  Most tutorials leave developers trapped in "tutorial hell", configuring toy examples on localhost that fail when deployed to multi-tenant Kubernetes clusters.
                </p>
                <p className="about-p">
                  The DevOps Learning Platform provides real production topologies, live sandboxes, and structured trajectories. You build real container architectures, automate real pipelines, and gain the exact skills demanded in enterprise engineering teams.
                </p>

                <div className="about-stats-row">
                  <div className="about-stat">
                    <span className="stat-number">6</span>
                    <span className="stat-caption">Structured Paths</span>
                  </div>
                  <div className="about-stat">
                    <span className="stat-number">90+</span>
                    <span className="stat-caption">Hands-on Labs</span>
                  </div>
                  <div className="about-stat">
                    <span className="stat-number">100%</span>
                    <span className="stat-caption">Real-world Practice</span>
                  </div>
                </div>
              </div>

              <div className="about-card-column">
                <div className="about-feature-box">
                  <div className="box-header">
                    <span className="box-dot" />
                    <h4>Guaranteed Learning Principles</h4>
                  </div>
                  <ul className="box-list">
                    <li>
                      <strong>Zero localhost shortcuts:</strong> Practice in real Linux environments with live network namespaces.
                    </li>
                    <li>
                      <strong>Fail-fast debugging:</strong> Deliberate outage simulations so you learn how to recover crashed systems.
                    </li>
                    <li>
                      <strong>Security baked-in:</strong> Cryptographic token verification, role-based access control, and least-privilege policies.
                    </li>
                    <li>
                      <strong>Verified credentials:</strong> Track progress towards mastery with automated lab validation.
                    </li>
                  </ul>
                </div>
              </div>
            </div>
          </div>
        </section>

        {/* ========================================================
            7. BOTTOM CALL TO ACTION
            ======================================================== */}
        <section className="bottom-cta-section">
          <div className="section-container text-center">
            <h2 className="cta-headline">Ready to Master Modern DevOps?</h2>
            <p className="cta-subtitle">
              Join developers mastering Linux, Docker, Kubernetes, and CI/CD through structured learning paths and hands-on systems.
            </p>
            <div className="hero-cta-group justify-center">
              <Link to="/register" className="btn-hero-primary" id="bottom-cta-getstarted">
                <span>Get Started Now</span>
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
                  <line x1="5" y1="12" x2="19" y2="12" />
                  <polyline points="12 5 19 12 12 19" />
                </svg>
              </Link>
              <Link to="/login" className="btn-hero-secondary" id="bottom-cta-signin">
                Sign In
              </Link>
            </div>
          </div>
        </section>
      </main>

      {/* ========================================================
          8. FOOTER
          ======================================================== */}
      <footer className="devops-footer">
        <div className="footer-container">
          <div className="footer-brand-col">
            <div className="devops-brand">
              <div className="devops-logo-badge">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
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
              Master modern cloud infrastructure and automated delivery pipelines with hands-on practice.
            </p>
          </div>

          <div className="footer-links-col">
            <h4 className="footer-heading">Navigation</h4>
            <ul className="footer-links-list">
              <li><a href="#paths" onClick={(e) => scrollToSection(e, "paths")}>Learning Paths</a></li>
              <li><a href="#features" onClick={(e) => scrollToSection(e, "features")}>Platform Features</a></li>
              <li><a href="#labs" onClick={(e) => scrollToSection(e, "labs")}>Architecture Labs</a></li>
              <li><a href="#about" onClick={(e) => scrollToSection(e, "about")}>About Platform</a></li>
            </ul>
          </div>

          <div className="footer-links-col">
            <h4 className="footer-heading">Account</h4>
            <ul className="footer-links-list">
              <li><Link to="/login">Sign In</Link></li>
              <li><Link to="/register">Create Account</Link></li>
              <li><Link to="/dashboard">Command Center</Link></li>
            </ul>
          </div>

          <div className="footer-status-col">
            <h4 className="footer-heading">System Status</h4>
            <div className="system-status-indicator">
              <span className="status-live-dot" />
              <span>All Systems Operational</span>
            </div>
            <p className="status-meta">Telemetry: 100% Availability • Cluster v2.4.0</p>
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
