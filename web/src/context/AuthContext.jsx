import { useState, useEffect, useCallback } from "react";
import { authAPI, tokenStorage } from "../services/api";
import { AuthContext } from "./authContextInstance";


export const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);
  const [authError, setAuthError] = useState(null);

  // Restore authenticated session on application startup
  const checkAuthStatus = useCallback(async () => {
    const token = tokenStorage.get();

    if (!token) {
      setUser(null);
      setLoading(false);
      return;
    }

    try {
      const response = await authAPI.getMe();
      if (response && response.user) {
        setUser(response.user);
      } else {
        tokenStorage.remove();
        setUser(null);
      }
    } catch {
      // Token is invalid, expired, or server returned 401
      tokenStorage.remove();
      setUser(null);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    let isMounted = true;
    (async () => {
      const token = tokenStorage.get();
      if (!token) {
        if (isMounted) {
          setUser(null);
          setLoading(false);
        }
        return;
      }

      try {
        const response = await authAPI.getMe();
        if (isMounted && response?.user) {
          setUser(response.user);
        }
      } catch {
        tokenStorage.remove();
        if (isMounted) {
          setUser(null);
        }
      } finally {
        if (isMounted) {
          setLoading(false);
        }
      }
    })();

    return () => {
      isMounted = false;
    };
  }, []);

  // Login action
  const login = async (email, password) => {
    setAuthError(null);
    try {
      const response = await authAPI.login({ email, password });
      if (response.token && response.user) {
        tokenStorage.set(response.token);
        setUser(response.user);
        return { success: true, user: response.user };
      }
      throw new Error("Invalid response from server");
    } catch (err) {
      const message = err.message || "Failed to log in";
      setAuthError(message);
      throw err;
    }
  };

  // Register action (creates unverified account & triggers OTP dispatch)
  const register = async (name, email, password) => {
    setAuthError(null);
    try {
      const response = await authAPI.register({ name, email, password });
      return {
        success: true,
        requireOtp: response.requireOtp ?? true,
        email: response.email || email,
        message: response.message,
      };
    } catch (err) {
      const message = err.message || "Registration failed";
      setAuthError(message);
      throw err;
    }
  };

  // Verify Email action (verifies OTP, saves token, authenticates session)
  const verifyEmail = async (email, otp) => {
    setAuthError(null);
    try {
      const response = await authAPI.verifyEmail({ email, otp });
      if (response.token && response.user) {
        tokenStorage.set(response.token);
        setUser(response.user);
        return { success: true, user: response.user, message: response.message };
      }
      return response;
    } catch (err) {
      const message = err.message || "Verification failed";
      setAuthError(message);
      throw err;
    }
  };

  // Resend OTP action
  const resendOtp = async (email) => {
    setAuthError(null);
    try {
      const response = await authAPI.resendOtp({ email });
      return response;
    } catch (err) {
      const message = err.message || "Failed to resend verification code";
      setAuthError(message);
      throw err;
    }
  };

  // Google Login action
  const googleLogin = async (idToken) => {
    setAuthError(null);
    try {
      const response = await authAPI.googleLogin(idToken);
      if (response.token && response.user) {
        tokenStorage.set(response.token);
        setUser(response.user);
        return { success: true, user: response.user };
      }
      throw new Error("Invalid response from server during Google sign-in");
    } catch (err) {
      const message = err.message || "Google sign-in failed";
      setAuthError(message);
      throw err;
    }
  };

  // Logout action
  const logout = () => {
    tokenStorage.remove();
    setUser(null);
    setAuthError(null);
  };

  // Update Profile action (updates user name)
  const updateProfile = async (name) => {
    setAuthError(null);
    try {
      const response = await authAPI.updateProfile({ name });
      if (response.user) {
        setUser((prev) => ({ ...prev, ...response.user }));
        return response.user;
      }
      throw new Error("Invalid response from server");
    } catch (err) {
      const message = err.message || "Failed to update profile";
      setAuthError(message);
      throw err;
    }
  };

  const value = {
    user,
    loading,
    authError,
    isAuthenticated: !!user,
    login,
    register,
    verifyEmail,
    resendOtp,
    googleLogin,
    logout,
    updateProfile,
    checkAuthStatus,
  };


  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
};
