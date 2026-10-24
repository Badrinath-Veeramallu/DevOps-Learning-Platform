import { useState, useEffect } from "react";
import { Link, useNavigate } from "react-router-dom";
import { useAuth } from "../context/useAuth";
import { GoogleSignInButton } from "../components/GoogleSignInButton";
import { Button } from "../components/Button";
import { BackgroundGrid } from "../components/BackgroundGrid";

export const Register = () => {
  const [formData, setFormData] = useState({
    name: "",
    email: "",
    password: "",
    confirmPassword: "",
  });

  const [formErrors, setFormErrors] = useState({});
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [serverError, setServerError] = useState("");

  const { register, isAuthenticated } = useAuth();
  const navigate = useNavigate();

  // Redirect if user is already logged in
  useEffect(() => {
    if (isAuthenticated) {
      navigate("/dashboard", { replace: true });
    }
  }, [isAuthenticated, navigate]);

  const validateField = (name, value) => {
    switch (name) {
      case "name":
        if (!value.trim()) return "Full name is required";
        if (value.trim().length < 2) return "Name must be at least 2 characters";
        return "";
      case "email":
        if (!value.trim()) return "Email address is required";
        if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value.trim())) {
          return "Please enter a valid email address";
        }
        return "";
      case "password":
        if (!value) return "Password is required";
        if (value.length < 8) return "Password must be at least 8 characters";
        return "";
      case "confirmPassword":
        if (!value) return "Please confirm your password";
        if (value !== formData.password) return "Passwords do not match";
        return "";
      default:
        return "";
    }
  };

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData((prev) => ({ ...prev, [name]: value }));

    if (serverError) setServerError("");

    const error = validateField(name, value);
    setFormErrors((prev) => ({ ...prev, [name]: error }));

    // Re-check confirmPassword if password changed
    if (name === "password" && formData.confirmPassword) {
      const confirmErr =
        value !== formData.confirmPassword ? "Passwords do not match" : "";
      setFormErrors((prev) => ({ ...prev, confirmPassword: confirmErr }));
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();

    const errors = {
      name: validateField("name", formData.name),
      email: validateField("email", formData.email),
      password: validateField("password", formData.password),
      confirmPassword: validateField("confirmPassword", formData.confirmPassword),
    };

    setFormErrors(errors);

    const hasErrors = Object.values(errors).some((err) => err !== "");
    if (hasErrors) return;

    setIsSubmitting(true);
    setServerError("");

    try {
      const result = await register(
        formData.name.trim(),
        formData.email.trim(),
        formData.password
      );

      // Navigate to OTP verification page
      navigate(`/verify-email?email=${encodeURIComponent(formData.email.trim())}`, {
        state: {
          email: formData.email.trim(),
          message: result.message || "Verification code sent to your email.",
        },
      });
    } catch (err) {
      setServerError(
        err.message || "Registration failed. Please check your details and try again."
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
              <path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2" />
              <circle cx="9" cy="7" r="4" />
              <line x1="19" y1="8" x2="19" y2="14" />
              <line x1="22" y1="11" x2="16" y2="11" />
            </svg>
          </div>
          <h2>Create your account</h2>
          <p>Start mastering Kubernetes, CI/CD, and Cloud Infrastructure</p>
        </div>

        {/* Server Alert */}
        {serverError && (
          <div className="alert-error" role="alert">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <circle cx="12" cy="12" r="10" />
              <line x1="12" y1="8" x2="12" y2="12" />
              <line x1="12" y1="16" x2="12.01" y2="16" />
            </svg>
            <span>{serverError}</span>
          </div>
        )}

        {/* Form */}
        <form onSubmit={handleSubmit} noValidate className="auth-form">
          <div className="form-group">
            <label htmlFor="name">Full Name</label>
            <input
              type="text"
              id="name"
              name="name"
              autoComplete="name"
              placeholder="Alex Chen"
              value={formData.name}
              onChange={handleChange}
              disabled={isSubmitting}
              className={formErrors.name ? "input-error" : ""}
            />
            {formErrors.name && <span className="field-error">{formErrors.name}</span>}
          </div>

          <div className="form-group">
            <label htmlFor="email">Work or Personal Email</label>
            <input
              type="email"
              id="email"
              name="email"
              autoComplete="email"
              placeholder="alex@devops.example.com"
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
              autoComplete="new-password"
              placeholder="Minimum 8 characters"
              value={formData.password}
              onChange={handleChange}
              disabled={isSubmitting}
              className={formErrors.password ? "input-error" : ""}
            />
            {formErrors.password && <span className="field-error">{formErrors.password}</span>}
          </div>

          <div className="form-group">
            <label htmlFor="confirmPassword">Confirm Password</label>
            <input
              type="password"
              id="confirmPassword"
              name="confirmPassword"
              autoComplete="new-password"
              placeholder="Re-enter your password"
              value={formData.confirmPassword}
              onChange={handleChange}
              disabled={isSubmitting}
              className={formErrors.confirmPassword ? "input-error" : ""}
            />
            {formErrors.confirmPassword && (
              <span className="field-error">{formErrors.confirmPassword}</span>
            )}
          </div>

          <Button
            type="submit"
            variant="primary"
            size="lg"
            loading={isSubmitting}
            className="btn-full"
          >
            Create Account & Verify
          </Button>
        </form>

        <div className="auth-divider">
          <span>OR</span>
        </div>

        <GoogleSignInButton text="signup_with" />

        <div className="auth-footer">
          <p>
            Already have an account?{" "}
            <Link to="/login" className="auth-link">
              Sign In
            </Link>
          </p>
        </div>
      </div>
    </BackgroundGrid>
  );
};

export default Register;
