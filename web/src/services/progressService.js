/**
 * Progress Service for DevOps Learning Platform
 *
 * Scopes learning module progress per authenticated user.
 * Seamlessly backed by REST API (/api/progress) with instant localStorage caching.
 * Enforces both sequential module unlocking and sequential pathway progression (Git -> Docker -> Linux).
 */

import { progressAPI, tokenStorage } from "./api";

const STORAGE_PREFIX = "devops_progress_";

/**
 * Authoritative module sequences for DevOps pathways
 */
export const PATHWAY_CURRICULA = {
  git: [
    "git-01",
    "git-02",
    "git-03",
    "git-04",
    "git-05",
    "git-06",
    "git-07",
  ],
  docker: [
    "docker-01",
    "docker-02",
    "docker-03",
    "docker-04",
    "docker-05",
    "docker-06",
    "docker-07",
  ],
  linux: [
    "linux-01",
    "linux-02",
    "linux-03",
    "linux-04",
    "linux-05",
    "linux-06",
  ],
};

/**
 * Returns the storage key for a user and pathway
 */
const getStorageKey = (userId = "guest", pathway = "git") => {
  const cleanId = userId ? String(userId).trim() : "guest";
  return `${STORAGE_PREFIX}${cleanId}_${pathway}`;
};

/**
 * Get completed module IDs for a user and pathway synchronously from local cache
 * @param {string} userId
 * @param {string} pathway
 * @returns {string[]} array of completed module IDs (e.g. ['git-01', 'git-02'])
 */
export const getCompletedModules = (userId = "guest", pathway = "git") => {
  try {
    const raw = localStorage.getItem(getStorageKey(userId, pathway));
    if (!raw) return [];
    const parsed = JSON.parse(raw);
    const validIds = PATHWAY_CURRICULA[pathway];
    const unique = Array.isArray(parsed) ? [...new Set(parsed)] : [];
    return validIds ? unique.filter((id) => validIds.includes(id)) : unique;
  } catch (err) {
    console.error("Error reading module progress from storage:", err);
    return [];
  }
};

/**
 * Check if a specific module is completed
 */
export const isModuleCompleted = (userId = "guest", pathway = "git", moduleId) => {
  const completed = getCompletedModules(userId, pathway);
  return completed.includes(moduleId);
};

/**
 * Checks whether an entire pathway is fully completed
 */
export const isPathwayCompleted = (userId = "guest", pathway = "git") => {
  if (pathway === "git") {
    const completed = getCompletedModules(userId, "git");
    return PATHWAY_CURRICULA.git.every((id) => completed.includes(id));
  }
  if (pathway === "docker") {
    if (!isPathwayCompleted(userId, "git")) return false;
    const completed = getCompletedModules(userId, "docker");
    return PATHWAY_CURRICULA.docker.every((id) => completed.includes(id));
  }
  if (pathway === "linux") {
    if (!isPathwayCompleted(userId, "docker")) return false;
    const completed = getCompletedModules(userId, "linux");
    return PATHWAY_CURRICULA.linux.every((id) => completed.includes(id));
  }
  return false;
};

/**
 * Checks whether a pathway is unlocked based on prerequisite pathways:
 * Progression: Git -> Docker -> Linux
 * - Git: Always unlocked by default.
 * - Docker: Unlocked only after ALL Git modules are completed.
 * - Linux: Unlocked only after ALL Docker modules are completed (and Git remains complete).
 */
export const isPathwayUnlocked = (userId = "guest", pathway = "git") => {
  if (pathway === "git") return true;
  if (pathway === "docker") return isPathwayCompleted(userId, "git");
  if (pathway === "linux") return isPathwayCompleted(userId, "docker");
  return false;
};

/**
 * Returns human-readable explanation if pathway is locked, or null if unlocked
 */
export const getPathwayLockReason = (userId = "guest", pathway = "git") => {
  if (pathway === "git") return null;
  if (pathway === "docker") {
    if (!isPathwayCompleted(userId, "git")) {
      return "Complete all 7 Git modules to unlock the Docker pathway.";
    }
    return null;
  }
  if (pathway === "linux") {
    if (!isPathwayCompleted(userId, "git")) {
      return "Complete all 7 Git modules first.";
    }
    if (!isPathwayCompleted(userId, "docker")) {
      return "Complete all 7 Docker modules to unlock the Linux pathway.";
    }
    return null;
  }
  return "Pathway coming soon.";
};

/**
 * Checks whether a module is unlocked based on sequential completion of preceding modules.
 * The first module of each pathway is accessible by default (if pathway is unlocked).
 * Every subsequent module requires the immediately preceding module to be completed.
 */
export const isModuleUnlocked = (userId = "guest", pathway = "git", moduleId, curriculum = []) => {
  if (!isPathwayUnlocked(userId, pathway)) return false;
  if (!Array.isArray(curriculum) || curriculum.length === 0) return true;
  const index = curriculum.findIndex((m) => m.id === moduleId || m.number === moduleId);
  if (index <= 0) return true; // First module is always unlocked if pathway is unlocked
  const precedingModuleId = curriculum[index - 1].id;
  const completed = getCompletedModules(userId, pathway);
  return completed.includes(precedingModuleId);
};

/**
 * Fetch latest progress from backend API and sync with local cache
 */
export const fetchUserProgress = async (userId = "guest", pathway = "git") => {
  const token = tokenStorage.get();
  if (!token) return getCompletedModules(userId, pathway);

  // If pathway is locked client-side, do not spam API unless syncing
  if (!isPathwayUnlocked(userId, pathway)) {
    return getCompletedModules(userId, pathway);
  }

  try {
    const res = await progressAPI.getProgress(pathway);
    if (res && res.success && Array.isArray(res.completedModules)) {
      const cleanModules = [...new Set(res.completedModules)];
      localStorage.setItem(getStorageKey(userId, pathway), JSON.stringify(cleanModules));
      window.dispatchEvent(
        new CustomEvent("devops_progress_updated", {
          detail: { userId, pathway, allCompleted: cleanModules },
        })
      );
      return cleanModules;
    }
  } catch (err) {
    if (err.status !== 403) {
      console.error("Error syncing progress with server:", err);
    }
  }
  return getCompletedModules(userId, pathway);
};

/**
 * Sync status of all pathways from server (useful on dashboard load)
 */
export const fetchAllPathwaysStatus = async (userId = "guest") => {
  const token = tokenStorage.get();
  if (!token) return null;

  try {
    const res = await progressAPI.getPathwaysStatus();
    if (res && res.success && res.pathways) {
      // Sync completed modules into local cache
      for (const [pId, pData] of Object.entries(res.pathways)) {
        if (Array.isArray(pData.completedModules)) {
          const clean = [...new Set(pData.completedModules)];
          localStorage.setItem(getStorageKey(userId, pId), JSON.stringify(clean));
        }
      }
      window.dispatchEvent(
        new CustomEvent("devops_progress_updated", {
          detail: { userId, allPathways: res.pathways },
        })
      );
      return res.pathways;
    }
  } catch (err) {
    console.error("Error fetching pathways status from server:", err);
  }
  return null;
};

/**
 * Toggle completion status of a module.
 * Optimistically updates cache and commits to backend /api/progress/:pathwayId/toggle,
 * which logs stop_completed on the server.
 *
 * @param {string} userId
 * @param {string} pathway
 * @param {string} moduleId
 * @param {Array} [curriculum] - Optional authoritative curriculum for sequential validation
 * @returns {Promise<boolean>|boolean} new completed status
 */
export const toggleModuleCompletion = async (userId = "guest", pathway = "git", moduleId, curriculum = []) => {
  try {
    // Prevent modifying locked pathway
    if (!isPathwayUnlocked(userId, pathway)) {
      console.warn(`Cannot complete module in locked pathway "${pathway}".`);
      return false;
    }

    const current = getCompletedModules(userId, pathway);
    const isNowCompleted = !current.includes(moduleId);

    // If attempting to complete, validate sequential unlocking within the pathway
    if (isNowCompleted && Array.isArray(curriculum) && curriculum.length > 0) {
      const index = curriculum.findIndex((m) => m.id === moduleId || m.number === moduleId);
      if (index > 0) {
        const precedingModuleId = curriculum[index - 1].id;
        if (!current.includes(precedingModuleId)) {
          console.warn(`Cannot complete locked module ${moduleId}: preceding module ${precedingModuleId} not completed.`);
          return false;
        }
      }
    }

    let updated;
    if (isNowCompleted) {
      updated = [...new Set([...current, moduleId])];
    } else {
      if (Array.isArray(curriculum) && curriculum.length > 0) {
        const index = curriculum.findIndex((m) => m.id === moduleId || m.number === moduleId);
        const allowed = curriculum.slice(0, index).map((m) => m.id);
        updated = current.filter((id) => allowed.includes(id));
      } else {
        updated = current.filter((id) => id !== moduleId);
      }
    }

    // Optimistically update localStorage
    localStorage.setItem(getStorageKey(userId, pathway), JSON.stringify(updated));

    // Dispatch custom event so pathway and module pages update reactively
    window.dispatchEvent(
      new CustomEvent("devops_progress_updated", {
        detail: { userId, pathway, moduleId, isCompleted: isNowCompleted, allCompleted: updated },
      })
    );

    // Also notify activity consumers (like the heat map) to refresh
    window.dispatchEvent(
      new CustomEvent("devops_activity_updated", {
        detail: { userId, type: "stop_completed", stopSlug: moduleId },
      })
    );

    // If authenticated, persist to server
    const token = tokenStorage.get();
    if (token) {
      try {
        const res = await progressAPI.toggleProgress(pathway, moduleId);
        if (res && res.success && Array.isArray(res.completedModules)) {
          const serverModules = [...new Set(res.completedModules)];
          localStorage.setItem(getStorageKey(userId, pathway), JSON.stringify(serverModules));
          window.dispatchEvent(
            new CustomEvent("devops_progress_updated", {
              detail: { userId, pathway, moduleId, isCompleted: res.isCompleted, allCompleted: serverModules },
            })
          );
          window.dispatchEvent(
            new CustomEvent("devops_activity_updated", {
              detail: { userId, type: "stop_completed", stopSlug: moduleId },
            })
          );
          return res.isCompleted;
        }
      } catch (apiErr) {
        console.error("Server progress toggle failed:", apiErr);
        // Revert optimistic update on failure
        localStorage.setItem(getStorageKey(userId, pathway), JSON.stringify(current));
        window.dispatchEvent(
          new CustomEvent("devops_progress_updated", {
            detail: { userId, pathway, moduleId, isCompleted: !isNowCompleted, allCompleted: current },
          })
        );
        return !isNowCompleted;
      }
    }

    return isNowCompleted;
  } catch (err) {
    console.error("Error updating module progress:", err);
    return false;
  }
};
