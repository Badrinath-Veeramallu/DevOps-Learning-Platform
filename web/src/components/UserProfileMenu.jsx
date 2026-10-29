import { useState, useRef, useEffect } from "react";
import { Link, useNavigate } from "react-router-dom";
import { useAuth } from "../context/useAuth";

export const UserProfileMenu = () => {
  const { user, logout } = useAuth();
  const [dropdownOpen, setDropdownOpen] = useState(false);
  const dropdownRef = useRef(null);
  const navigate = useNavigate();

  const handleLogout = () => {
    logout();
    navigate("/login");
  };

  useEffect(() => {
    const handleClickOutside = (event) => {
      if (dropdownRef.current && !dropdownRef.current.contains(event.target)) {
        setDropdownOpen(false);
      }
    };
    const handleKeyDown = (event) => {
      if (event.key === "Escape") {
        setDropdownOpen(false);
      }
    };

    if (dropdownOpen) {
      document.addEventListener("mousedown", handleClickOutside);
      document.addEventListener("keydown", handleKeyDown);
    }
    return () => {
      document.removeEventListener("mousedown", handleClickOutside);
      document.removeEventListener("keydown", handleKeyDown);
    };
  }, [dropdownOpen]);

  if (!user) return null;

  return (
    <div className="nav-profile-menu-container" ref={dropdownRef}>
      <button
        type="button"
        className="nav-profile-trigger"
        onClick={() => setDropdownOpen((prev) => !prev)}
        aria-expanded={dropdownOpen}
        aria-haspopup="menu"
        aria-label="User profile menu"
      >
        <span className="nav-avatar-circle" aria-hidden="true">
          {user.name ? user.name.charAt(0).toUpperCase() : "U"}
        </span>
        <span className="nav-user-name">{user.name}</span>
        <svg
          className={`nav-chevron ${dropdownOpen ? "nav-chevron-open" : ""}`}
          width="14"
          height="14"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          strokeWidth="2.5"
          aria-hidden="true"
        >
          <polyline points="6 9 12 15 18 9" />
        </svg>
      </button>

      {dropdownOpen && (
        <div className="nav-profile-dropdown" role="menu">
          <Link
            to="/profile"
            className="dropdown-item"
            role="menuitem"
            onClick={() => setDropdownOpen(false)}
          >
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" aria-hidden="true">
              <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2" />
              <circle cx="12" cy="7" r="4" />
            </svg>
            <span>My Profile</span>
          </Link>

          <button
            type="button"
            className="dropdown-item dropdown-item-danger"
            role="menuitem"
            onClick={() => {
              setDropdownOpen(false);
              handleLogout();
            }}
          >
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" aria-hidden="true">
              <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4" />
              <polyline points="16 17 21 12 16 7" />
              <line x1="21" y1="12" x2="9" y2="12" />
            </svg>
            <span>Sign Out</span>
          </button>
        </div>
      )}
    </div>
  );
};

export default UserProfileMenu;
