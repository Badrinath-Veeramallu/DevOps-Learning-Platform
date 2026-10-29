import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { useAuth } from "../context/useAuth";

export const Dashboard = () => {
  const { user } = useAuth();
  const navigate = useNavigate();
  const [activeTrackId, setActiveTrackId] = useState(() => {
    return localStorage.getItem("devops_active_track") || "git";
  });

  const firstName = user?.name ? user.name.trim().split(" ")[0] : "Learner";

  // 6 Core Learning Paths from actual application data
  const learningPaths = [
    {
      id: "git",
      title: "Git & Collaborative Workflows",
      level: "Foundational",
      modules: "7 Modules · Interactive Pathway",
      description:
        "Version control strategies, GitOps branch patterns, interactive rebasing, merge conflict resolution, and commit workflows.",
      hasPathway: true,
    },
    {
      id: "linux",
      title: "Linux Systems & Automation",
      level: "Foundational",
      modules: "8 Modules",
      description:
        "Linux kernel fundamentals, process management, permissions, systemd services, and bash shell automation.",
      hasPathway: false,
    },
    {
      id: "docker",
      title: "Docker & Container Engineering",
      level: "Intermediate",
      modules: "8 Modules",
      description:
        "Container isolation, multi-stage Dockerfile architecture, layer caching, container networking, and security best practices.",
      hasPathway: false,
    },
    {
      id: "kubernetes",
      title: "Kubernetes Cluster Architecture",
      level: "Advanced",
      modules: "12 Modules",
      description:
        "Workload orchestration: Deployments, StatefulSets, Services, Ingress controllers, ConfigMaps, and Helm charts.",
      hasPathway: false,
    },
    {
      id: "cicd",
      title: "CI/CD & GitOps Delivery",
      level: "Intermediate",
      modules: "10 Modules",
      description:
        "Automated deployment pipelines using GitHub Actions, container registries, test automation, and GitOps synchronization.",
      hasPathway: false,
    },
    {
      id: "iac",
      title: "Cloud Infrastructure & Terraform",
      level: "Advanced",
      modules: "9 Modules",
      description:
        "Infrastructure as Code: declarative cloud provisioning, modular configurations, remote state management, and cloud networking.",
      hasPathway: false,
    },
  ];

  const handleSelectTrack = (trackId) => {
    setActiveTrackId(trackId);
    localStorage.setItem("devops_active_track", trackId);
    if (trackId === "git") {
      navigate("/pathways/git");
    }
  };

  const handleContinue = (path) => {
    if (path.id === "git") {
      navigate("/pathways/git");
    } else {
      alert(`Continuing ${path.title}`);
    }
  };

  const activePath = learningPaths.find((p) => p.id === activeTrackId);

  return (
    <div className="dashboard-wrapper">
      <div className="dashboard-content-container">
        {/* Welcome Section */}
        <header className="dashboard-welcome-header">
          <h1>Welcome back, {firstName}</h1>
          <p className="dashboard-subtitle">
            Continue learning or choose a learning path to get started.
          </p>
        </header>

        {/* Continue Learning Section */}
        <section className="dashboard-continue-section" aria-label="Current Learning Progress">
          <h2 className="section-heading">Continue Learning</h2>

          {activePath ? (
            <div className="continue-learning-card">
              <div className="continue-card-body">
                <div className="continue-card-meta">
                  <span className={`badge-pill badge-${activePath.level.toLowerCase()}`}>
                    {activePath.level}
                  </span>
                  <span className="continue-module-label">
                    {activePath.id === "git" ? "Interactive Pathway Active" : "Module in progress"}
                  </span>
                </div>
                <h3 className="continue-track-title">{activePath.title}</h3>
                <p className="continue-track-desc">{activePath.description}</p>
              </div>

              <div className="continue-card-actions">
                <button
                  type="button"
                  className="btn-continue-primary"
                  onClick={() => handleContinue(activePath)}
                >
                  <span>{activePath.id === "git" ? "Open Pathway" : "Continue"}</span>
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" aria-hidden="true">
                    <polyline points="9 18 15 12 9 6" />
                  </svg>
                </button>
              </div>
            </div>
          ) : (
            <div className="empty-learning-prompt">
              <p>You haven't started a learning path yet.</p>
              <a href="#available-paths" className="btn-select-path">
                Choose a learning path below
              </a>
            </div>
          )}
        </section>

        {/* Available Learning Paths */}
        <section className="dashboard-tracks-section" id="available-paths" aria-label="Available Learning Paths">
          <div className="tracks-header">
            <h2 className="section-heading">Available Learning Paths</h2>
            <p className="tracks-subtext">
              Select a path to build practical skills across the DevOps lifecycle.
            </p>
          </div>

          <div className="dashboard-paths-grid">
            {learningPaths.map((path) => {
              const isActive = path.id === activeTrackId;
              const isGit = path.id === "git";

              return (
                <div key={path.id} className={`dashboard-path-card ${isActive ? "active-path-card" : ""}`}>
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

                    <button
                      type="button"
                      onClick={() => handleSelectTrack(path.id)}
                      className={`btn-path-action ${isGit ? "btn-path-highlight" : ""} ${isActive ? "btn-active-track" : ""}`}
                    >
                      <span>
                        {isGit ? "View Pathway" : isActive ? "Active Path" : "Start Learning"}
                      </span>
                      <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" aria-hidden="true">
                        <polyline points="9 18 15 12 9 6" />
                      </svg>
                    </button>
                  </div>
                </div>
              );
            })}
          </div>
        </section>
      </div>
    </div>
  );
};

export default Dashboard;
