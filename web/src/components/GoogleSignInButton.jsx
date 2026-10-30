import { useEffect, useRef, useState } from "react";
import { useAuth } from "../context/useAuth";
import { useNavigate, useLocation } from "react-router-dom";

/**
 * Google Sign-In Component using Google Identity Services (GIS)
 * Verifies ID token on the Express backend without trusting client-side profile data.
 */
export const GoogleSignInButton = ({ text = "continue_with" }) => {
  const { googleLogin } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();
  const buttonRef = useRef(null);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);
  const [isWakingUp, setIsWakingUp] = useState(false);

  const googleClientId = import.meta.env.VITE_GOOGLE_CLIENT_ID;
  const from = location.state?.from?.pathname || "/dashboard";

  useEffect(() => {
    // If no client ID configured yet, don't attempt to load GIS
    if (!googleClientId || googleClientId.includes("your_google_client_id")) {
      return;
    }

    const handleCredentialResponse = async (response) => {
      setError("");
      setLoading(true);
      const slowTimer = setTimeout(() => {
        setIsWakingUp(true);
      }, 1500);

      try {
        if (!response.credential) {
          throw new Error("No credential received from Google");
        }
        await googleLogin(response.credential);
        navigate(from, { replace: true });
      } catch (err) {
        setError(err.message || "Google sign-in failed");
      } finally {
        clearTimeout(slowTimer);
        setLoading(false);
        setIsWakingUp(false);
      }
    };

    const initializeGoogleSignIn = () => {
      if (window.google?.accounts?.id && buttonRef.current) {
        try {
          window.google.accounts.id.initialize({
            client_id: googleClientId,
            callback: handleCredentialResponse,
            auto_select: false,
            cancel_on_tap_outside: true,
          });

          window.google.accounts.id.renderButton(buttonRef.current, {
            theme: "filled_black",
            size: "large",
            width: 380,
            text,
            shape: "rectangular",
          });
        } catch (e) {
          console.error("Failed to render Google Sign-In button", e);
        }
      }
    };

    // Load GIS script if not present
    if (!window.google?.accounts?.id) {
      const script = document.createElement("script");
      script.src = "https://accounts.google.com/gsi/client";
      script.async = true;
      script.defer = true;
      script.onload = initializeGoogleSignIn;
      document.body.appendChild(script);
    } else {
      initializeGoogleSignIn();
    }
  }, [googleClientId, googleLogin, navigate, from, text]);

  // If Client ID is placeholder or missing, show informative banner for the developer
  if (!googleClientId || googleClientId.includes("your_google_client_id")) {
    return (
      <div className="google-auth-notice">
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
          <circle cx="12" cy="12" r="10" />
          <line x1="12" y1="16" x2="12" y2="12" />
          <line x1="12" y1="8" x2="12.01" y2="8" />
        </svg>
        <span>
          To enable Google Sign-In, add your <code>VITE_GOOGLE_CLIENT_ID</code> in <code>web/.env</code> and <code>server/.env</code>.
        </span>
      </div>
    );
  }

  return (
    <div className="google-auth-wrapper">
      {error && (
        <div className="alert-error" style={{ marginBottom: "0.75rem" }}>
          <span>{error}</span>
        </div>
      )}
      {loading && (
        <div className="google-loading-text">
          {isWakingUp
            ? "Connecting to secure cloud server (waking up backend)..."
            : "Verifying Google account with server..."}
        </div>
      )}
      <div ref={buttonRef} className="google-btn-container"></div>
    </div>
  );
};

export default GoogleSignInButton;
