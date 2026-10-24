import { useState } from "react";
import { useAuth } from "../context/useAuth";
import { authAPI } from "../services/api";
import { Card } from "../components/Card";
import { Badge } from "../components/Badge";
import { Button } from "../components/Button";
import { Tabs } from "../components/Tabs";
import { ProgressBar } from "../components/ProgressBar";
import { BackgroundGrid } from "../components/BackgroundGrid";

export const Dashboard = () => {
  const { user, logout } = useAuth();
  const [liveCheck, setLiveCheck] = useState(null);
  const [checking, setChecking] = useState(false);
  const [activeTab, setActiveTab] = useState("k8s");

  const handleVerifySession = async () => {
    setChecking(true);
    try {
      const data = await authAPI.getMe();
      setLiveCheck({
        success: true,
        message: "GET /api/auth/me returned HTTP 200 OK. Bearer token is verified!",
        timestamp: new Date().toLocaleTimeString(),
        data: data.user,
      });
    } catch (err) {
      setLiveCheck({
        success: false,
        message: `Verification failed: ${err.message}`,
        timestamp: new Date().toLocaleTimeString(),
      });
    } finally {
      setChecking(false);
    }
  };

  const learningTracks = {
    k8s: {
      title: "Kubernetes Cloud Native Architecture",
      desc: "Deploy pods, services, ingress controllers, Helm charts, and custom resource definitions on multi-node clusters.",
      progress: 68,
      modules: [
        { name: "Cluster Architecture & Control Plane", done: true },
        { name: "Pod Deployments & DaemonSets", done: true },
        { name: "Service Mesh & Ingress Routing", done: false },
        { name: "Persistent Volumes & StatefulSets", done: false },
      ],
    },
    cicd: {
      title: "Automated CI/CD Pipelines with GitHub Actions",
      desc: "Implement automated unit testing, container build caches, security vulnerability scans, and canary deployments.",
      progress: 85,
      modules: [
        { name: "Workflow Triggers & Secret Management", done: true },
        { name: "Docker Image Multi-Stage Builds", done: true },
        { name: "Automated Linting & Test Matrix", done: true },
        { name: "Canary Rollouts & GitOps ArgoCD", done: false },
      ],
    },
    docker: {
      title: "Production Docker Containers & Registries",
      desc: "Write lightweight, secure distroless containers, optimize layer caching, and manage container networking.",
      progress: 92,
      modules: [
        { name: "Dockerfile Best Practices & Caching", done: true },
        { name: "Container Security & Non-Root Users", done: true },
        { name: "Multi-Container Docker Compose", done: true },
        { name: "Docker Healthchecks & Graceful Stops", done: true },
      ],
    },
    iac: {
      title: "Infrastructure as Code with Terraform & AWS",
      desc: "Provision AWS VPCs, EKS clusters, S3 buckets, and RDS instances with modular state locking.",
      progress: 45,
      modules: [
        { name: "HCL Syntax & Provider Config", done: true },
        { name: "State Files & Remote S3 Backend", done: true },
        { name: "Reusable VPC & Security Modules", done: false },
        { name: "Terraform Cloud & Automated Drift", done: false },
      ],
    },
  };

  const tabs = [
    { id: "k8s", label: "Kubernetes", badge: "Track 1" },
    { id: "cicd", label: "CI/CD Pipelines", badge: "Track 2" },
    { id: "docker", label: "Docker", badge: "Track 3" },
    { id: "iac", label: "Terraform & IaC", badge: "Track 4" },
  ];

  const currentTrack = learningTracks[activeTab];

  return (
    <BackgroundGrid className="dashboard-wrapper">
      <div className="dashboard-content-container">
        {/* Top Header Banner */}
        <header className="dashboard-hero-header">
          <div className="dashboard-hero-left">
            <div className="badge-group">
              <Badge variant="teal" dot>
                Live Session
              </Badge>
              <Badge variant="indigo">
                {user?.isEmailVerified ? "Verified Account" : "Registered User"}
              </Badge>
            </div>
            <h1>DevOps Command Center</h1>
            <p className="dashboard-subtitle">
              Welcome back, <strong>{user?.name}</strong>. Your cloud sandbox and automated learning pipelines are ready.
            </p>
          </div>
          <div className="dashboard-hero-actions">
            <Button
              variant="outline"
              size="sm"
              onClick={logout}
              icon={
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                  <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4" />
                  <polyline points="16 17 21 12 16 7" />
                  <line x1="21" y1="12" x2="9" y2="12" />
                </svg>
              }
            >
              Sign Out
            </Button>
          </div>
        </header>

        {/* Stats Row */}
        <section className="dashboard-stats-grid" aria-label="DevOps Stats Overview">
          <Card glow className="stat-card">
            <div className="stat-card-top">
              <span className="stat-label">Active Track</span>
              <span className="stat-icon-wrap stat-icon-teal">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                  <polygon points="12 2 2 7 12 12 22 7 12 2" />
                  <polyline points="2 17 12 22 22 17" />
                  <polyline points="2 12 12 17 22 12" />
                </svg>
              </span>
            </div>
            <div className="stat-value">{currentTrack.title.split(" ")[0]}</div>
            <p className="stat-subtext">Module 3 of 4 in progress</p>
          </Card>

          <Card glow className="stat-card">
            <div className="stat-card-top">
              <span className="stat-label">Average Completion</span>
              <span className="stat-icon-wrap stat-icon-indigo">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                  <circle cx="12" cy="12" r="10" />
                  <polyline points="12 6 12 12 16 14" />
                </svg>
              </span>
            </div>
            <div className="stat-value">72%</div>
            <p className="stat-subtext">Across 4 core tracks</p>
          </Card>

          <Card glow className="stat-card">
            <div className="stat-card-top">
              <span className="stat-label">Email Status</span>
              <span className="stat-icon-wrap stat-icon-teal">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                  <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14" />
                  <polyline points="22 4 12 14.01 9 11.01" />
                </svg>
              </span>
            </div>
            <div className="stat-value text-teal">
              {user?.isEmailVerified ? "Verified" : "Pending"}
            </div>
            <p className="stat-subtext">{user?.email}</p>
          </Card>
        </section>

        {/* Main Grid: Learning Tracks & Profile */}
        <div className="dashboard-main-grid">
          {/* Left Column: Interactive Curriculum Tabs */}
          <div className="dashboard-track-section">
            <Card className="track-card-container">
              <div className="track-card-header">
                <div>
                  <h2>Curriculum Tracks</h2>
                  <p className="card-subtext">Hands-on interactive labs and cloud environments</p>
                </div>
              </div>

              {/* 21st.dev Tabs */}
              <Tabs tabs={tabs} activeTab={activeTab} onChange={setActiveTab} />

              {/* Active Track Details */}
              <div className="active-track-content">
                <div className="track-title-row">
                  <h3>{currentTrack.title}</h3>
                  <Badge variant="teal">{currentTrack.progress}% Complete</Badge>
                </div>
                <p className="track-description">{currentTrack.desc}</p>

                <ProgressBar
                  progress={currentTrack.progress}
                  label="Track Progress"
                  className="track-progress-bar"
                />

                <div className="modules-list">
                  <h4>Curriculum Modules</h4>
                  {currentTrack.modules.map((mod, i) => (
                    <div key={i} className={`module-item ${mod.done ? "module-done" : ""}`}>
                      <span className="module-checkbox">
                        {mod.done ? (
                          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3">
                            <polyline points="20 6 9 17 4 12" />
                          </svg>
                        ) : (
                          <span className="module-number">{i + 1}</span>
                        )}
                      </span>
                      <span className="module-name">{mod.name}</span>
                      <span className="module-status-badge">
                        {mod.done ? "Completed" : "In Progress"}
                      </span>
                    </div>
                  ))}
                </div>
              </div>
            </Card>
          </div>

          {/* Right Column: User Profile & Token Verification */}
          <aside className="dashboard-sidebar-section">
            {/* User Profile Card */}
            <Card className="profile-card">
              <div className="sidebar-card-header">
                <h3>User Profile</h3>
                <Badge variant="indigo">{user?.role || "user"}</Badge>
              </div>

              <div className="profile-details-list">
                <div className="profile-item">
                  <span className="profile-key">Full Name</span>
                  <span className="profile-val">{user?.name}</span>
                </div>
                <div className="profile-item">
                  <span className="profile-key">Email Address</span>
                  <span className="profile-val">{user?.email}</span>
                </div>
                <div className="profile-item">
                  <span className="profile-key">Email Verified</span>
                  <span className="profile-val text-teal">
                    {user?.isEmailVerified ? "✓ Confirmed" : "✗ Pending"}
                  </span>
                </div>
                <div className="profile-item">
                  <span className="profile-key">Auth Provider</span>
                  <span className="profile-val">
                    {user?.googleId ? "Google OAuth 2.0" : "Email & Password"}
                  </span>
                </div>
                <div className="profile-item">
                  <span className="profile-key">User ID</span>
                  <span className="profile-val mono-val">{user?._id || user?.id}</span>
                </div>
              </div>
            </Card>

            {/* Token Diagnostic Tool */}
            <Card className="session-verify-card">
              <div className="sidebar-card-header">
                <h3>Bearer Token Inspection</h3>
                <span className="badge-chip">JWT Security</span>
              </div>
              <p className="card-subtext">
                Verify that your signed Bearer token grants protected access to <code>GET /api/auth/me</code>.
              </p>

              <Button
                variant="secondary"
                size="md"
                onClick={handleVerifySession}
                loading={checking}
                className="btn-full"
                icon={
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                    <rect width="18" height="11" x="3" y="11" rx="2" ry="2" />
                    <path d="M7 11V7a5 5 0 0 1 10 0v4" />
                  </svg>
                }
              >
                Verify Session (GET /api/auth/me)
              </Button>

              {liveCheck && (
                <div
                  className={`live-result ${
                    liveCheck.success ? "result-success" : "result-error"
                  }`}
                  role="status"
                >
                  <div className="result-header">
                    <strong>{liveCheck.success ? "✓ Valid Session" : "✗ Error"}</strong>
                    <span className="result-time">{liveCheck.timestamp}</span>
                  </div>
                  <p className="result-msg">{liveCheck.message}</p>
                </div>
              )}
            </Card>
          </aside>
        </div>
      </div>
    </BackgroundGrid>
  );
};

export default Dashboard;
