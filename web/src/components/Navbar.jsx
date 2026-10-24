import { Link, useNavigate, useLocation } from "react-router-dom";
import { useAuth } from "../context/useAuth";

export const Navbar = () => {
  const { user, isAuthenticated, logout } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();

  const handleLogout = () => {
    logout();
    navigate("/login");
  };

  const isActive = (path) => location.pathname === path;

  return (
    <header className="navbar-wrapper">
      <div className="navbar-container">
        {/* Brand Logo */}
        <Link to="/" className="navbar-brand">
          <div className="brand-logo-icon" aria-hidden="true">
            <svg
              width="20"
              height="20"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              strokeWidth="2.5"
              strokeLinecap="round"
              strokeLinejoin="round"
            >
              <polyline points="4 17 10 11 4 5" />
              <line x1="12" y1="19" x2="20" y2="19" />
            </svg>
          </div>
          <span className="brand-title">DevOps</span>
          <span className="brand-subtitle">Platform</span>
        </Link>

        {/* Navigation Links */}
        <nav className="navbar-nav" aria-label="Main Navigation">
          <Link
            to="/"
            className={`nav-item ${isActive("/") ? "nav-item-active" : ""}`}
          >
            Home
          </Link>

          {isAuthenticated ? (
            <>
              <Link
                to="/dashboard"
                className={`nav-item ${
                  isActive("/dashboard") ? "nav-item-active" : ""
                }`}
              >
                Command Center
              </Link>

              <div className="nav-user-profile">
                <span className="nav-avatar-circle" aria-hidden="true">
                  {user?.name ? user.name.charAt(0).toUpperCase() : "U"}
                </span>
                <div className="nav-user-meta">
                  <span className="nav-user-name">{user?.name}</span>
                  {user?.isEmailVerified && (
                    <span className="nav-verified-badge" title="Verified Account">
                      ✓ Verified
                    </span>
                  )}
                </div>
              </div>

              <button
                type="button"
                onClick={handleLogout}
                className="nav-btn-logout"
                title="Sign out of your account"
              >
                Sign Out
              </button>
            </>
          ) : (
            <div className="nav-auth-actions">
              <Link
                to="/login"
                className={`nav-item ${
                  isActive("/login") ? "nav-item-active" : ""
                }`}
              >
                Sign In
              </Link>
              <Link to="/register" className="nav-btn-primary">
                Get Started Free
              </Link>
            </div>
          )}
        </nav>
      </div>
    </header>
  );
};

export default Navbar;
