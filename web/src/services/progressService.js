/**
 * Progress Service for DevOps Learning Platform
 *
 * Scopes learning module progress per authenticated user.
 * Built to be easily swapped with or backed by a future REST API (e.g. GET/POST /api/progress).
 */

const STORAGE_PREFIX = "devops_progress_";

/**
 * Returns the storage key for a user and pathway
 */
const getStorageKey = (userId = "guest", pathway = "git") => {
  const cleanId = userId ? String(userId).trim() : "guest";
  return `${STORAGE_PREFIX}${cleanId}_${pathway}`;
};

/**
 * Get completed module IDs for a user and pathway
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
 * Toggle completion status of a module
 * @param {string} userId
 * @param {string} pathway
 * @param {string} moduleId
 * @returns {boolean} new completed status
 */
export const toggleModuleCompletion = (userId = "guest", pathway = "git", moduleId) => {
  try {
    const current = getCompletedModules(userId, pathway);
    let updated;
    const isNowCompleted = !current.includes(moduleId);

    if (isNowCompleted) {
      updated = [...current, moduleId];
    } else {
      updated = current.filter((id) => id !== moduleId);
    }

    localStorage.setItem(getStorageKey(userId, pathway), JSON.stringify(updated));
    // Dispatch custom event so pathway and module pages update reactively
    window.dispatchEvent(
      new CustomEvent("devops_progress_updated", {
        detail: { userId, pathway, moduleId, isCompleted: isNowCompleted, allCompleted: updated },
      })
    );
    return isNowCompleted;
  } catch (err) {
    console.error("Error updating module progress:", err);
    return false;
  }
};

/**
 * Set completion status of a module explicitly
 */
export const setModuleCompleted = (userId = "guest", pathway = "git", moduleId, completed = true) => {
  try {
    const current = getCompletedModules(userId, pathway);
    const has = current.includes(moduleId);
    if ((completed && has) || (!completed && !has)) return completed;

    const updated = completed ? [...current, moduleId] : current.filter((id) => id !== moduleId);
    localStorage.setItem(getStorageKey(userId, pathway), JSON.stringify(updated));
    window.dispatchEvent(
      new CustomEvent("devops_progress_updated", {
        detail: { userId, pathway, moduleId, isCompleted: completed, allCompleted: updated },
      })
    );
    return completed;
  } catch (err) {
    console.error("Error setting module progress:", err);
    return false;
  }
};
