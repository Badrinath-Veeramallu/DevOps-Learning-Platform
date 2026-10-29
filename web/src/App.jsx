import { BrowserRouter as Router, Routes, Route, Navigate, useLocation } from "react-router-dom";
import { AuthProvider } from "./context/AuthContext";
import { Navbar } from "./components/Navbar";
import { ProtectedRoute } from "./components/ProtectedRoute";
import { KagePage } from "./pages/KagePage";
import { Login } from "./pages/Login";
import { Register } from "./pages/Register";
import { VerifyEmail } from "./pages/VerifyEmail";
import { Dashboard } from "./pages/Dashboard";
import { Profile } from "./pages/Profile";
import "./App.css";

/**
 * Inner layout wrapper — hides the app Navbar on the root Kage landing page
 * (Kage has its own built-in navigation) but shows it on all application pages.
 */
function AppLayout() {
  const location = useLocation();
  const isKageLanding = location.pathname === "/";

  return (
    <div className={isKageLanding ? "app-layout-kage" : "app-layout"}>
      {!isKageLanding && <Navbar />}
      <main className={isKageLanding ? "kage-main" : "main-content"}>
        <Routes>
          {/* Public Routes */}
          <Route path="/" element={<KagePage />} />
          <Route path="/login" element={<Login />} />
          <Route path="/register" element={<Register />} />
          <Route path="/verify-email" element={<VerifyEmail />} />

          {/* Protected Routes */}
          <Route
            path="/dashboard"
            element={
              <ProtectedRoute>
                <Dashboard />
              </ProtectedRoute>
            }
          />
          <Route
            path="/profile"
            element={
              <ProtectedRoute>
                <Profile />
              </ProtectedRoute>
            }
          />

          {/* Catch-all fallback */}
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </main>
    </div>
  );
}

function App() {
  return (
    <Router>
      <AuthProvider>
        <AppLayout />
      </AuthProvider>
    </Router>
  );
}

export default App;
