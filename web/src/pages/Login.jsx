import { useState, useEffect } from "react";
import { Link, useNavigate, useLocation } from "react-router-dom";
import { useAuth } from "../context/useAuth";
import { GoogleSignInButton } from "../components/GoogleSignInButton";
import { Button } from "../components/Button";
import { BackgroundGrid } from "../components/BackgroundGrid";

export const Login = () => {
  const [formData, setFormData] = useState({
    email: "",
    password: "",
  });

  const [formErrors, setFormErrors] = useState({});
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [serverError, setServerError] = useState("");
  const [unverifiedEmail, setUnverifiedEmail] = useState(null);

  const { login, isAuthenticated } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();

  const from = location.state?.from?.pathname || "/dashboard";

  // Redirect if already authenticated
  useEffect(() => {
    if (isAuthenticated) {
      navigate(from, { replace: true });
    }
  }, [isAuthenticated, navigate, from]);

  const validateField = (name, value) => {
    switch (name) {
      case "email":
        if (!value.trim()) return "Email address is required";
        if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value.trim())) {
          return "Please enter a valid email address";
        }
        return "";
      case "password":
        if (!value) return "Password is required";
        return "";
      default:
        return "";
    }
  };

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData((prev) => ({ ...prev, [name]: value }));

    if (serverError) setServerError("");
    if (unverifiedEmail) setUnverifiedEmail(null);

    const error = validateField(name, value);
    setFormErrors((prev) => ({ ...prev, [name]: error }));
  };

  const handleSubmit = async (e) => {
    e.preventDefault();

    const errors = {
      email: validateField("email", formData.email),
      password: validateField("password", formData.password),
    };

    setFormErrors(errors);

    const hasErrors = Object.values(errors).some((err) => err !== "");
    if (hasErrors) return;

    setIsSubmitting(true);
    setServerError("");
    setUnverifiedEmail(null);

    try {
      await login(formData.email.trim(), formData.password);
      navigate(from, { replace: true });
    } catch (err) {
      // Check if server rejected login because email is unverified
      if (err.status === 403 || err.data?.isEmailVerified === false) {
        setUnverifiedEmail(formData.email.trim());
      }
      setServerError(
        err.message || "Invalid credentials or email not verified."
      );
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <BackgroundGrid className="auth-page-wrapper">
      <div className="auth-card">
        {/* Header */}
        <div className="auth-header">
          <div className="auth-icon-badge" aria-hidden="true">
            <svg
              width="24"
              height="24"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              strokeWidth="2"
              strokeLinecap="round"
              strokeLinejoin="round"
            >
              <path d="M15 3h4a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2h-4" />
              <polyline points="10 17 15 12 10 7" />
              <line x1="15" y1="12" x2="3" y2="12" />
            </svg>
          </div>
          <h2>Welcome back</h2>
          <p>Sign in to your DevOps Learning Platform account</p>
        </div>

        {/* Server Alert */}
        {serverError && (
          <div className="alert-error" role="alert">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <circle cx="12" cy="12" r="10" />
              <line x1="12" y1="8" x2="12" y2="12" />
              <line x1="12" y1="16" x2="12.01" y2="16" />
            </svg>
            <div>
              <span>{serverError}</span>
              {unverifiedEmail && (
                <div style={{ marginTop: "0.5rem" }}>
                  <Link
                    to={`/verify-email?email=${encodeURIComponent(unverifiedEmail)}`}
                    className="verify-now-btn"
                  >
                    Verify your email now &rarr;
                  </Link>
                </div>
              )}
            </div>
          </div>
        )}

        {/* Form */}
        <form onSubmit={handleSubmit} noValidate className="auth-form">
          <div className="form-group">
            <label htmlFor="email">Email Address</label>
            <input
              type="email"
              id="email"
              name="email"
              autoComplete="email"
              placeholder="engineer@devops.example.com"
              value={formData.email}
              onChange={handleChange}
              disabled={isSubmitting}
              className={formErrors.email ? "input-error" : ""}
            />
            {formErrors.email && <span className="field-error">{formErrors.email}</span>}
          </div>

          <div className="form-group">
            <label htmlFor="password">Password</label>
            <input
              type="password"
              id="password"
              name="password"
              autoComplete="current-password"
              placeholder="••••••••••••"
              value={formData.password}
              onChange={handleChange}
              disabled={isSubmitting}
              className={formErrors.password ? "input-error" : ""}
            />
            {formErrors.password && <span className="field-error">{formErrors.password}</span>}
          </div>

          <Button
            type="submit"
            variant="primary"
            size="lg"
            loading={isSubmitting}
            className="btn-full"
          >
            Sign In
          </Button>
        </form>

        <div className="auth-divider">
          <span>OR</span>
        </div>

        <GoogleSignInButton text="signin_with" />

        <div className="auth-footer">
          <p>
            Don't have an account?{" "}
            <Link to="/register" className="auth-link">
              Create one
            </Link>
          </p>
        </div>
      </div>
    </BackgroundGrid>
  );
};

export default Login;
