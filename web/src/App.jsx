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
import { GitPathwayPage } from "./pages/GitPathwayPage";
import { GitModulePage } from "./pages/GitModulePage";
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

          {/* Git & GitHub Learning Pathway Routes */}
          <Route
            path="/pathways/git"
            element={
              <ProtectedRoute>
                <GitPathwayPage />
              </ProtectedRoute>
            }
          />
          <Route
            path="/pathways/git/:moduleId"
            element={
              <ProtectedRoute>
                <GitModulePage />
              </ProtectedRoute>
            }
          />
          {/* Aliases for convenience */}
          <Route
            path="/pathway/git"
            element={<Navigate to="/pathways/git" replace />}
          />
          <Route
            path="/pathway/git/:moduleId"
            element={<Navigate to="/pathways/git" replace />}
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
