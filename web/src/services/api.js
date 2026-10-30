/**
 * DevOps Learning Platform - API Client
 * Centralized HTTP service for backend communication.
 *
 * Security Note:
 * Tokens are stored in localStorage for Bearer authorization.
 * While practical for SPA architectures, localStorage can be accessible to XSS.
 * For highest security in production environments, HttpOnly cookies with CSRF tokens
 * can be used to prevent script access to the token.
 */

const API_BASE_URL = import.meta.env.VITE_API_URL || "http://localhost:5000/api";
const TOKEN_KEY = "devops_auth_token";

export const tokenStorage = {
  get: () => {
    try {
      return localStorage.getItem(TOKEN_KEY);
    } catch {
      return null;
    }
  },
  set: (token) => {
    try {
      localStorage.setItem(TOKEN_KEY, token);
    } catch (e) {
      console.error("Failed to store token", e);
    }
  },
  remove: () => {
    try {
      localStorage.removeItem(TOKEN_KEY);
    } catch (e) {
      console.error("Failed to remove token", e);
    }
  },
};

/**
 * Universal request wrapper
 */
async function request(endpoint, options = {}) {
  const url = `${API_BASE_URL}${endpoint}`;
  const token = tokenStorage.get();

  const headers = {
    "Content-Type": "application/json",
    ...(options.headers || {}),
  };

  if (token) {
    headers.Authorization = `Bearer ${token}`;
  }

  const response = await fetch(url, {
    ...options,
    headers,
  });

  const data = await response.json().catch(() => ({}));

  if (!response.ok) {
    // If the token is expired or invalid (401), remove it
    if (
      response.status === 401 &&
      endpoint !== "/auth/login" &&
      endpoint !== "/auth/google"
    ) {
      tokenStorage.remove();
    }
    const error = new Error(data.message || `Request failed with status ${response.status}`);
    error.status = response.status;
    error.data = data;
    throw error;
  }

  return data;
}

export const authAPI = {
  register: (userData) =>
    request("/auth/register", {
      method: "POST",
      body: JSON.stringify(userData),
    }),

  login: (credentials) =>
    request("/auth/login", {
      method: "POST",
      body: JSON.stringify(credentials),
    }),

  googleLogin: (idToken) =>
    request("/auth/google", {
      method: "POST",
      body: JSON.stringify({ idToken }),
    }),

  getMe: () =>
    request("/auth/me", {
      method: "GET",
    }),

  verifyEmail: (data) =>
    request("/auth/verify-email", {
      method: "POST",
      body: JSON.stringify(data),
    }),

  resendOtp: (data) =>
    request("/auth/resend-otp", {
      method: "POST",
      body: JSON.stringify(data),
    }),

  updateProfile: (data) =>
    request("/auth/profile", {
      method: "PUT",
      body: JSON.stringify(data),
    }),
};

export const activityAPI = {
  getActivity: (tz = "UTC") =>
    request(`/activity?tz=${encodeURIComponent(tz)}`, {
      method: "GET",
    }),

  logActivity: ({ type, pathwayId = "git", stopSlug }) =>
    request("/activity/log", {
      method: "POST",
      body: JSON.stringify({ type, pathwayId, stopSlug }),
    }),
};

export const progressAPI = {
  getProgress: (pathwayId = "git") =>
    request(`/progress/${encodeURIComponent(pathwayId)}`, {
      method: "GET",
    }),

  toggleProgress: (pathwayId = "git", moduleId) =>
    request(`/progress/${encodeURIComponent(pathwayId)}/toggle`, {
      method: "POST",
      body: JSON.stringify({ moduleId }),
    }),
};
