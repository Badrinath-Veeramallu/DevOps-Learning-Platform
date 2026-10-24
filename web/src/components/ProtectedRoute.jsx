import { Navigate, useLocation, Outlet } from "react-router-dom";
import { useAuth } from "../context/useAuth";


/**
 * Reusable Protected Route wrapper.
 * Redirects unauthenticated users to /login while preserving their intended destination.
 */
export const ProtectedRoute = ({ children }) => {
  const { isAuthenticated, user, loading } = useAuth();
  const location = useLocation();

  if (loading) {
    return (
      <div className="auth-loading-screen">
        <div className="spinner"></div>
        <p>Verifying authentication session...</p>
      </div>
    );
  }

  if (!isAuthenticated) {
    return <Navigate to="/login" state={{ from: location }} replace />;
  }

  if (user && user.isEmailVerified === false) {
    return (
      <Navigate
        to={`/verify-email?email=${encodeURIComponent(user.email)}`}
        replace
      />
    );
  }

  return children ? children : <Outlet />;
};

export default ProtectedRoute;
