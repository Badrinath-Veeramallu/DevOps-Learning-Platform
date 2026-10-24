
import { useState, useEffect } from "react";
import { useNavigate, useLocation, Link } from "react-router-dom";
import { useAuth } from "../context/useAuth";
import { OtpInput } from "../components/OtpInput";
import { Button } from "../components/Button";
import { BackgroundGrid } from "../components/BackgroundGrid";

export const VerifyEmail = () => {
  const { verifyEmail, resendOtp, isAuthenticated } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();

  // Retrieve email from navigation state, query params, or sessionStorage
  const [email, setEmail] = useState(() => {
    const fromState = location.state?.email;
    const fromParams = new URLSearchParams(location.search).get("email");
    const fromStorage = sessionStorage.getItem("pending_verify_email");
    return fromState || fromParams || fromStorage || "";
  });

  const [otp, setOtp] = useState("");
  const [isVerifying, setIsVerifying] = useState(false);
  const [isResending, setIsResending] = useState(false);
  const [errorMessage, setErrorMessage] = useState("");
  const [successMessage, setSuccessMessage] = useState(
    location.state?.message || "Verification code sent to your email."
  );

  // 60-second cooldown timer
  const [cooldown, setCooldown] = useState(60);

  // If already authenticated, redirect to dashboard
  useEffect(() => {
    if (isAuthenticated) {
      navigate("/dashboard", { replace: true });
    }
  }, [isAuthenticated, navigate]);

  // Persist email to sessionStorage so page refresh preserves it
  useEffect(() => {
    if (email) {
      sessionStorage.setItem("pending_verify_email", email);
    }
  }, [email]);

  // Cooldown countdown tick
  useEffect(() => {
    if (cooldown <= 0) return;
    const timer = setInterval(() => {
      setCooldown((prev) => Math.max(0, prev - 1));
    }, 1000);
    return () => clearInterval(timer);
  }, [cooldown]);

  const handleVerify = async (e) => {
    if (e) e.preventDefault();

    if (!email) {
      setErrorMessage("Please specify your email address to verify.");
      return;
    }

    if (otp.length !== 6 || !/^\d{6}$/.test(otp)) {
      setErrorMessage("Please enter all 6 digits of the verification code.");
      return;
    }

    setErrorMessage("");
    setSuccessMessage("");
    setIsVerifying(true);

    try {
      await verifyEmail(email, otp);
      sessionStorage.removeItem("pending_verify_email");
      navigate("/dashboard", { replace: true });
    } catch (err) {
      setErrorMessage(
        err.message || "Verification code is invalid or has expired."
      );
    } finally {
      setIsVerifying(false);
    }
  };

  const handleResend = async () => {
    if (cooldown > 0 || isResending) return;

    if (!email) {
      setErrorMessage("Email address is missing. Please enter your email.");
      return;
    }

    setErrorMessage("");
    setSuccessMessage("");
    setIsResending(true);

    try {
      const res = await resendOtp(email);
      setSuccessMessage(
        res.message || "A fresh 6-digit code has been sent to your email."
      );
      setOtp("");
      setCooldown(60); // Reset 60s cooldown
    } catch (err) {
      if (err.data?.retryAfter) {
        setCooldown(err.data.retryAfter);
      }
      setErrorMessage(
        err.message || "Failed to resend code. Please try again later."
      );
    } finally {
      setIsResending(false);
    }
  };

  return (
    <BackgroundGrid className="auth-page-wrapper">
      <div className="auth-card">
        {/* Terminal Header Icon */}
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
              <rect width="20" height="16" x="2" y="4" rx="2" />
              <path d="m22 7-8.97 5.7a1.94 1.94 0 0 1-2.06 0L2 7" />
            </svg>
          </div>
          <h2>Verify your email</h2>
          <p>
            We have sent a 6-digit verification code to{" "}
            {email ? (
              <strong className="verify-target-email">{email}</strong>
            ) : (
              "your email address"
            )}
          </p>
        </div>

        {/* Status Alerts */}
        {errorMessage && (
          <div className="alert-error" role="alert">
            <svg
              width="18"
              height="18"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              strokeWidth="2"
            >
              <circle cx="12" cy="12" r="10" />
              <line x1="12" y1="8" x2="12" y2="12" />
              <line x1="12" y1="16" x2="12.01" y2="16" />
            </svg>
            <span>{errorMessage}</span>
          </div>
        )}

        {successMessage && (
          <div className="alert-success" role="status">
            <svg
              width="18"
              height="18"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              strokeWidth="2"
            >
              <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14" />
              <polyline points="22 4 12 14.01 9 11.01" />
            </svg>
            <span>{successMessage}</span>
          </div>
        )}

        {/* Verification Form */}
        <form onSubmit={handleVerify} className="verify-form" noValidate>
          {/* Email input if missing */}
          {!email && (
            <div className="form-group" style={{ marginBottom: "1.5rem" }}>
              <label htmlFor="verify-email-input">Email Address</label>
              <input
                id="verify-email-input"
                type="email"
                placeholder="engineer@devops.example.com"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
              />
            </div>
          )}

          <div className="otp-section">
            <label className="otp-label">Enter 6-digit confirmation code</label>
            <OtpInput
              value={otp}
              onChange={(newOtp) => {
                setOtp(newOtp);
                if (errorMessage) setErrorMessage("");
              }}
              hasError={Boolean(errorMessage)}
              disabled={isVerifying}
              autoFocus
            />
            <span className="otp-helper">Code expires in 10 minutes</span>
          </div>

          <Button
            type="submit"
            variant="primary"
            size="lg"
            loading={isVerifying}
            disabled={otp.length !== 6 || isVerifying}
            className="btn-full"
          >
            Verify & Continue
          </Button>
        </form>

        {/* Resend Cooldown Section */}
        <div className="resend-container">
          <p className="resend-text">Didn't receive the code?</p>
          <button
            type="button"
            onClick={handleResend}
            disabled={cooldown > 0 || isResending}
            className="resend-action-btn"
          >
            {isResending ? (
              "Sending new code..."
            ) : cooldown > 0 ? (
              <span>
                Resend code in <strong className="cooldown-timer">{cooldown}s</strong>
              </span>
            ) : (
              "Resend Code"
            )}
          </button>
        </div>

        {/* Recovery / Switch Account */}
        <div className="auth-footer">
          <p>
            Entered the wrong email?{" "}
            <Link
              to="/register"
              className="auth-link"
              onClick={() => sessionStorage.removeItem("pending_verify_email")}
            >
              Sign up with another email
            </Link>
          </p>
          <p style={{ marginTop: "0.5rem" }}>
            Already verified?{" "}
            <Link to="/login" className="auth-link">
              Sign In
            </Link>
          </p>
        </div>
      </div>
    </BackgroundGrid>
  );
};

export default VerifyEmail;
