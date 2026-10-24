import { Link } from "react-router-dom";
import { useAuth } from "../context/useAuth";
import { BackgroundGrid } from "../components/BackgroundGrid";
import { Badge } from "../components/Badge";
import { Card } from "../components/Card";

export const Home = () => {
  const { isAuthenticated, user } = useAuth();

  const features = [
    {
      title: "Email OTP Verification",
      desc: "Cryptographically secure 6-digit confirmation codes with anti-tamper single-use guarantees and brute-force lockouts.",
      tag: "Security",
      icon: (
        <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
          <rect width="20" height="16" x="2" y="4" rx="2" />
          <path d="m22 7-8.97 5.7a1.94 1.94 0 0 1-2.06 0L2 7" />
        </svg>
      ),
    },
    {
      title: "Interactive Kubernetes Labs",
      desc: "Multi-node sandbox clusters to deploy deployments, ingress controllers, statefulsets, and configmaps in real time.",
      tag: "Cloud Native",
      icon: (
        <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
          <polygon points="12 2 2 7 12 12 22 7 12 2" />
          <polyline points="2 17 12 22 22 17" />
          <polyline points="2 12 12 17 22 12" />
        </svg>
      ),
    },
    {
      title: "Automated CI/CD Workflows",
      desc: "End-to-end pipeline creation with automated unit test runners, Docker layer caching, and GitOps rollouts.",
      tag: "Automation",
      icon: (
        <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
          <circle cx="12" cy="12" r="10" />
          <polyline points="12 6 12 12 16 14" />
        </svg>
      ),
    },
    {
      title: "Google OAuth 2.0 Integration",
      desc: "Hardware-token validated identity federation alongside traditional bcrypt credentials and safe account linking.",
      tag: "Identity",
      icon: (
        <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
          <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10" />
        </svg>
      ),
    },
  ];

  return (
    <BackgroundGrid className="home-wrapper">
      <div className="home-hero-container">
        {/* Status Pill */}
        <div className="hero-badge-wrap">
          <Badge variant="teal" dot>
            Next-Gen DevOps Platform
          </Badge>
          <Badge variant="indigo">
            CI/CD • Kubernetes • Terraform
          </Badge>
        </div>

        {/* Hero Title */}
        <h1 className="hero-main-title">
          Master Modern DevOps <br />
          <span className="gradient-text-indigo-teal">From Code to Production</span>
        </h1>

        <p className="hero-description">
          Hands-on cloud sandboxes, automated pipeline blueprints, and production-ready architectures.
          Engineered for developers who build, automate, and scale.
        </p>

        {/* Call to Actions */}
        <div className="hero-action-buttons">
          {isAuthenticated ? (
            <Link to="/dashboard" className="btn-primary-glow">
              <span>Go to Command Center</span>
              <span className="btn-user-label">({user?.name})</span>
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                <line x1="5" y1="12" x2="19" y2="12" />
                <polyline points="12 5 19 12 12 19" />
              </svg>
            </Link>
          ) : (
            <>
              <Link to="/register" className="btn-primary-glow">
                <span>Start Learning Free</span>
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                  <line x1="5" y1="12" x2="19" y2="12" />
                  <polyline points="12 5 19 12 12 19" />
                </svg>
              </Link>
              <Link to="/login" className="btn-secondary-clean">
                <span>Sign In to Account</span>
              </Link>
            </>
          )}
        </div>

        {/* Terminal Visual Mockup */}
        <div className="hero-terminal-mockup" aria-label="Terminal demonstration">
          <div className="terminal-header">
            <span className="terminal-dot dot-red" />
            <span className="terminal-dot dot-yellow" />
            <span className="terminal-dot dot-green" />
            <span className="terminal-title">bash — kubectl get deployments,pods,services</span>
          </div>
          <div className="terminal-body">
            <p className="terminal-line"><span className="term-prompt">$</span> kubectl get pods -n devops-platform</p>
            <p className="terminal-line term-output"><span className="term-teal">NAME</span>                               READY   STATUS    RESTARTS   AGE</p>
            <p className="terminal-line term-output">api-gateway-6d8b5c98bc-7xk2q         1/1     <span className="term-teal">Running</span>   0          42m</p>
            <p className="terminal-line term-output">auth-service-589fc78c77-4r9mt        1/1     <span className="term-teal">Running</span>   0          42m</p>
            <p className="terminal-line term-output">otp-verifier-76b9fcd6f9-p8b5d        1/1     <span className="term-teal">Running</span>   0          18m</p>
            <p className="terminal-line"><span className="term-prompt">$</span> helm status platform-prod-v2 --show-resources <span className="term-indigo">[OK]</span></p>
          </div>
        </div>

        {/* Features Grid */}
        <section className="features-grid-section" aria-label="Key Platform Capabilities">
          <div className="features-header">
            <h2>Built with Enterprise-Grade Rigor</h2>
            <p>Every component is crafted for security, scale, and performance.</p>
          </div>

          <div className="features-cards-grid">
            {features.map((feat, idx) => (
              <Card key={idx} hoverable className="feature-card">
                <div className="feature-card-header">
                  <div className="feature-icon-box">{feat.icon}</div>
                  <Badge variant="teal" size="sm">{feat.tag}</Badge>
                </div>
                <h3>{feat.title}</h3>
                <p>{feat.desc}</p>
              </Card>
            ))}
          </div>
        </section>
      </div>
    </BackgroundGrid>
  );
};

export default Home;
