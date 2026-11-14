import { BrowserRouter as Router, Routes, Route, Navigate, useLocation, useParams } from "react-router-dom";
import { AuthProvider } from "./context/AuthContext";
import { Navbar } from "./components/Navbar";
import { ProtectedRoute } from "./components/ProtectedRoute";
import { Home } from "./pages/Home";
import { Login } from "./pages/Login";
import { Register } from "./pages/Register";
import { VerifyEmail } from "./pages/VerifyEmail";
import { Dashboard } from "./pages/Dashboard";
import { Profile } from "./pages/Profile";
import { GitPathwayPage } from "./pages/GitPathwayPage";
import { GitModulePage } from "./pages/GitModulePage";
import { LinuxPathwayPage } from "./pages/LinuxPathwayPage";
import { LinuxModulePage } from "./pages/LinuxModulePage";
import { DockerPathwayPage } from "./pages/DockerPathwayPage";
import { DockerModulePage } from "./pages/DockerModulePage";
import { CicdPathwayPage } from "./pages/CicdPathwayPage";
import { CicdModulePage } from "./pages/CicdModulePage";
import { PathwayQuizPage } from "./pages/PathwayQuizPage";
import "./App.css";

/**
 * Redirects legacy /pathway/:pathwayId/quiz to /pathways/:pathwayId/quiz
 * using the captured pathwayId parameter.
 */
function LegacyQuizRedirect() {
  const { pathwayId } = useParams();
  return <Navigate to={`/pathways/${pathwayId}/quiz`} replace />;
}

/**
 * Redirects legacy /pathway/:pathway/:moduleId to /pathways/:pathway/:moduleId
 */
function LegacyModuleRedirect({ pathway }) {
  const { moduleId } = useParams();
  return <Navigate to={`/pathways/${pathway}/${moduleId}`} replace />;
}

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
          <Route path="/" element={<Home />} />
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

          {/* Linux Essentials Learning Pathway Routes */}
          <Route
            path="/pathways/linux"
            element={
              <ProtectedRoute>
                <LinuxPathwayPage />
              </ProtectedRoute>
            }
          />
          <Route
            path="/pathways/linux/:moduleId"
            element={
              <ProtectedRoute>
                <LinuxModulePage />
              </ProtectedRoute>
            }
          />
          {/* Aliases for convenience */}
          <Route
            path="/pathway/linux"
            element={<Navigate to="/pathways/linux" replace />}
          />
          <Route
            path="/pathway/linux/:moduleId"
            element={<Navigate to="/pathways/linux" replace />}
          />

          {/* Docker & Container Engineering Learning Pathway Routes */}
          <Route
            path="/pathways/docker"
            element={
              <ProtectedRoute>
                <DockerPathwayPage />
              </ProtectedRoute>
            }
          />
          <Route
            path="/pathways/docker/:moduleId"
            element={
              <ProtectedRoute>
                <DockerModulePage />
              </ProtectedRoute>
            }
          />
          {/* Aliases for convenience */}
          <Route
            path="/pathway/docker"
            element={<Navigate to="/pathways/docker" replace />}
          />
          <Route
            path="/pathway/docker/:moduleId"
            element={<Navigate to="/pathways/docker" replace />}
          />

          {/* CI/CD & GitOps Delivery Learning Pathway Routes */}
          <Route
            path="/pathways/cicd"
            element={
              <ProtectedRoute>
                <CicdPathwayPage />
              </ProtectedRoute>
            }
          />
          <Route
            path="/pathways/cicd/:moduleId"
            element={
              <ProtectedRoute>
                <CicdModulePage />
              </ProtectedRoute>
            }
          />
          {/* Aliases for convenience */}
          <Route
            path="/pathway/cicd"
            element={<Navigate to="/pathways/cicd" replace />}
          />
          <Route
            path="/pathway/cicd/:moduleId"
            element={<LegacyModuleRedirect pathway="cicd" />}
          />

          {/* Final Pathway Quiz Routes */}
          <Route
            path="/pathways/git/quiz"
            element={
              <ProtectedRoute>
                <PathwayQuizPage pathwayId="git" />
              </ProtectedRoute>
            }
          />
          <Route
            path="/pathways/linux/quiz"
            element={
              <ProtectedRoute>
                <PathwayQuizPage pathwayId="linux" />
              </ProtectedRoute>
            }
          />
          <Route
            path="/pathways/docker/quiz"
            element={
              <ProtectedRoute>
                <PathwayQuizPage pathwayId="docker" />
              </ProtectedRoute>
            }
          />
          <Route
            path="/pathways/cicd/quiz"
            element={
              <ProtectedRoute>
                <PathwayQuizPage pathwayId="cicd" />
              </ProtectedRoute>
            }
          />

          {/* Legacy Quiz Alias Redirect */}
          <Route
            path="/pathway/:pathwayId/quiz"
            element={<LegacyQuizRedirect />}
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
