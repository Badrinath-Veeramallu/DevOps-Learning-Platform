import { Link, useLocation } from "react-router-dom";
import { useAuth } from "../context/useAuth";
import { UserProfileMenu } from "./UserProfileMenu";

export const Navbar = () => {
  const { isAuthenticated } = useAuth();
  const location = useLocation();

  const isActive = (path) => location.pathname === path;
  const isLoginPage = location.pathname === "/login";
  const isRegisterPage = location.pathname === "/register";

  return (
    <header className="navbar-wrapper">
      <div className="navbar-container">
        {/* Brand Logo */}
        <Link to="/" className="navbar-brand" aria-label="DevOps Learning Platform Home">
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
                Dashboard
              </Link>

              {/* User Profile Control with Dropdown (My Profile & Sign Out) */}
              <UserProfileMenu />
            </>
          ) : (
            <div className="nav-auth-actions">
              {/* Only show Sign In if not already on /login */}
              {!isLoginPage && (
                <Link
                  to="/login"
                  className={`nav-item ${
                    isActive("/login") ? "nav-item-active" : ""
                  }`}
                >
                  Sign In
                </Link>
              )}

              {/* Only show Get Started Free if not already on /register */}
              {!isRegisterPage && (
                <Link to="/register" className="nav-btn-primary">
                  Get Started Free
                </Link>
              )}
            </div>
          )}
        </nav>
      </div>
    </header>
  );
};

export default Navbar;
