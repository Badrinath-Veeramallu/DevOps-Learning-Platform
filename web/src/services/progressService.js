/**
 * Progress Service for DevOps Learning Platform
 *
 * Scopes learning module progress per authenticated user.
 * Seamlessly backed by REST API (/api/progress) with instant localStorage caching.
 */

import { progressAPI, tokenStorage } from "./api";

const STORAGE_PREFIX = "devops_progress_";

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
    return Array.isArray(parsed) ? parsed : [];
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
 * Fetch latest progress from backend API and sync with local cache
 */
export const fetchUserProgress = async (userId = "guest", pathway = "git") => {
  const token = tokenStorage.get();
  if (!token) return getCompletedModules(userId, pathway);

  try {
    const res = await progressAPI.getProgress(pathway);
    if (res && res.success && Array.isArray(res.completedModules)) {
      localStorage.setItem(getStorageKey(userId, pathway), JSON.stringify(res.completedModules));
      window.dispatchEvent(
        new CustomEvent("devops_progress_updated", {
          detail: { userId, pathway, allCompleted: res.completedModules },
        })
      );
      return res.completedModules;
    }
  } catch (err) {
    console.error("Error syncing progress with server:", err);
  }
  return getCompletedModules(userId, pathway);
};

/**
 * Toggle completion status of a module.
 * Optimistically updates cache and commits to backend /api/progress/:pathwayId/toggle,
 * which logs stop_completed on the server.
 *
 * @param {string} userId
 * @param {string} pathway
 * @param {string} moduleId
 * @returns {Promise<boolean>|boolean} new completed status
 */
export const toggleModuleCompletion = async (userId = "guest", pathway = "git", moduleId) => {
  try {
    const current = getCompletedModules(userId, pathway);
    const isNowCompleted = !current.includes(moduleId);

    const updated = isNowCompleted
      ? [...current, moduleId]
      : current.filter((id) => id !== moduleId);

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
          localStorage.setItem(getStorageKey(userId, pathway), JSON.stringify(res.completedModules));
          window.dispatchEvent(
            new CustomEvent("devops_progress_updated", {
              detail: { userId, pathway, moduleId, isCompleted: res.isCompleted, allCompleted: res.completedModules },
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
      }
    }

    return isNowCompleted;
  } catch (err) {
    console.error("Error updating module progress:", err);
    return false;
  }
};
