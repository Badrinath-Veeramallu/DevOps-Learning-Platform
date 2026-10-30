import { useState } from "react";
import { Link } from "react-router-dom";
import { useAuth } from "../context/useAuth";
import { ActivityHeatmap } from "../components/ActivityHeatmap";

export const Profile = () => {
  const { user, updateProfile } = useAuth();
  const [isEditing, setIsEditing] = useState(false);
  const [nameInput, setNameInput] = useState(user?.name || "");
  const [isSaving, setIsSaving] = useState(false);
  const [successMessage, setSuccessMessage] = useState("");
  const [errorMessage, setErrorMessage] = useState("");

  const handleStartEdit = () => {
    setNameInput(user?.name || "");
    setErrorMessage("");
    setSuccessMessage("");
    setIsEditing(true);
  };

  const handleCancelEdit = () => {
    setIsEditing(false);
    setNameInput(user?.name || "");
    setErrorMessage("");
  };

  const handleSaveProfile = async (e) => {
    e.preventDefault();
    const trimmed = nameInput.trim();

    if (!trimmed) {
      setErrorMessage("Full name is required.");
      return;
    }

    if (trimmed.length < 2) {
      setErrorMessage("Name must be at least 2 characters long.");
      return;
    }

    setIsSaving(true);
    setErrorMessage("");
    setSuccessMessage("");

    try {
      await updateProfile(trimmed);
      setSuccessMessage("Profile name updated successfully.");
      setIsEditing(false);
    } catch (err) {
      setErrorMessage(err.message || "Failed to update profile name.");
    } finally {
      setIsSaving(false);
    }
  };

  const formattedDate = user?.createdAt
    ? new Date(user.createdAt).toLocaleDateString(undefined, {
        year: "numeric",
        month: "long",
        day: "numeric",
      })
    : null;

  const authMethod =
    user?.googleId || user?.authProvider === "google"
      ? "Google Account"
      : "Email & Password";

  return (
    <div className="profile-page-wrapper">
      <div className="profile-page-container">
        {/* Navigation Breadcrumb */}
        <div className="profile-back-nav">
          <Link to="/dashboard" className="back-link">
            <svg
              width="16"
              height="16"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              strokeWidth="2.5"
              aria-hidden="true"
            >
              <polyline points="15 18 9 12 15 6" />
            </svg>
            <span>Back to Dashboard</span>
          </Link>
        </div>

        {/* Page Header */}
        <header className="profile-page-header">
          <h1>My Profile</h1>
          <p className="profile-page-desc">Your account and learning activity.</p>
        </header>

        {/* Feedback Alerts */}
        {successMessage && (
          <div className="alert-success" role="status">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" aria-hidden="true">
              <polyline points="20 6 9 17 4 12" />
            </svg>
            <span>{successMessage}</span>
          </div>
        )}

        {errorMessage && (
          <div className="alert-error" role="alert">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" aria-hidden="true">
              <circle cx="12" cy="12" r="10" />
              <line x1="12" y1="8" x2="12" y2="12" />
              <line x1="12" y1="16" x2="12.01" y2="16" />
            </svg>
            <span>{errorMessage}</span>
          </div>
        )}

        {/* Profile Details Card */}
        <div className="profile-card-container">
          {/* Card Top: Avatar & Name */}
          <div className="profile-card-header">
            <div className="profile-avatar-wrap">
              {user?.avatar ? (
                <img
                  src={user.avatar}
                  alt={user?.name || "User Avatar"}
                  className="profile-avatar-img"
                />
              ) : (
                <div className="profile-avatar-placeholder" aria-hidden="true">
                  {user?.name ? user.name.charAt(0).toUpperCase() : "U"}
                </div>
              )}
            </div>

            <div className="profile-header-meta">
              <h2>{user?.name}</h2>
              <span className="profile-email-badge">{user?.email}</span>
            </div>

            {!isEditing && (
              <div className="profile-header-actions">
                <button
                  type="button"
                  className="btn-edit-profile"
                  onClick={handleStartEdit}
                >
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" aria-hidden="true">
                    <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7" />
                    <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z" />
                  </svg>
                  <span>Edit Profile</span>
                </button>
              </div>
            )}
          </div>

          {/* Edit Name Form */}
          {isEditing && (
            <form onSubmit={handleSaveProfile} className="profile-edit-form">
              <div className="edit-form-group">
                <label htmlFor="fullName">Full Name</label>
                <input
                  type="text"
                  id="fullName"
                  value={nameInput}
                  onChange={(e) => setNameInput(e.target.value)}
                  disabled={isSaving}
                  className="profile-input"
                  placeholder="Enter your full name"
                  maxLength={50}
                  required
                />
                <span className="form-hint">
                  Email address cannot be changed through this form.
                </span>
              </div>

              <div className="edit-form-buttons">
                <button
                  type="submit"
                  className="btn-save-profile"
                  disabled={isSaving}
                >
                  {isSaving ? "Saving..." : "Save Changes"}
                </button>
                <button
                  type="button"
                  className="btn-cancel-profile"
                  onClick={handleCancelEdit}
                  disabled={isSaving}
                >
                  Cancel
                </button>
              </div>
            </form>
          )}

          {/* Personal Information Section */}
          <div className="profile-section">
            <h3 className="profile-section-title">Personal Information</h3>
            <div className="profile-info-grid">
              <div className="info-row">
                <span className="info-label">Full Name</span>
                <span className="info-value">{user?.name}</span>
              </div>
              <div className="info-row">
                <span className="info-label">Email Address</span>
                <span className="info-value">{user?.email}</span>
              </div>
            </div>
          </div>

          {/* Account Information Section */}
          <div className="profile-section">
            <h3 className="profile-section-title">Account Information</h3>
            <div className="profile-info-grid">
              <div className="info-row">
                <span className="info-label">Verification Status</span>
                <span className="info-value">
                  {user?.isEmailVerified ? (
                    <span className="status-badge-verified">
                      <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3" aria-hidden="true">
                        <polyline points="20 6 9 17 4 12" />
                      </svg>
                      Verified
                    </span>
                  ) : (
                    <span className="status-badge-pending">Pending Verification</span>
                  )}
                </span>
              </div>

              <div className="info-row">
                <span className="info-label">Sign-in Method</span>
                <span className="info-value">{authMethod}</span>
              </div>

              {formattedDate && (
                <div className="info-row">
                  <span className="info-label">Member Since</span>
                  <span className="info-value">{formattedDate}</span>
                </div>
              )}
            </div>
          </div>
        </div>

        {/* Section 6: Learning Activity Heatmap (GitHub/LeetCode style) */}
        <ActivityHeatmap />
      </div>
    </div>
  );
};

export default Profile;
