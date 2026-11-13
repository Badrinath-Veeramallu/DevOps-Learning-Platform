const Progress = require("../models/Progress");
const { logActivity } = require("../utils/activityLogger");

/**
 * Authoritative module sequences for DevOps pathways.
 * Guarantees exact curriculum order for sequential unlocking and progress calculation.
 */
const PATHWAY_CURRICULA = {
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
 * Helper to determine pathway unlocking and completion status for a given user.
 * Sequential rules:
 * - Git: Always unlocked by default.
 * - Docker: Locked until ALL Git modules (7) are completed.
 * - Linux: Locked until ALL Docker modules (7) are completed AND Git remains complete.
 */
async function getPathwayLockStatus(userId) {
  const gitModules = PATHWAY_CURRICULA.git;
  const dockerModules = PATHWAY_CURRICULA.docker;
  const linuxModules = PATHWAY_CURRICULA.linux;

  const [gitDoc, dockerDoc, linuxDoc] = await Promise.all([
    Progress.findOne({ userId, pathwayId: "git" }),
    Progress.findOne({ userId, pathwayId: "docker" }),
    Progress.findOne({ userId, pathwayId: "linux" }),
  ]);

  const cleanGitCompleted = [...new Set(gitDoc?.completedModules || [])].filter((id) =>
    gitModules.includes(id)
  );
  const cleanDockerCompleted = [...new Set(dockerDoc?.completedModules || [])].filter((id) =>
    dockerModules.includes(id)
  );
  const cleanLinuxCompleted = [...new Set(linuxDoc?.completedModules || [])].filter((id) =>
    linuxModules.includes(id)
  );

  const isGitComplete =
    gitModules.length > 0 &&
    gitModules.every((id) => cleanGitCompleted.includes(id));

  const isDockerComplete =
    isGitComplete &&
    dockerModules.length > 0 &&
    dockerModules.every((id) => cleanDockerCompleted.includes(id));

  const isLinuxComplete =
    isDockerComplete &&
    linuxModules.length > 0 &&
    linuxModules.every((id) => cleanLinuxCompleted.includes(id));

  return {
    git: {
      isLocked: false,
      isCompleted: isGitComplete,
      totalModules: gitModules.length,
      completedCount: cleanGitCompleted.length,
      completedModules: cleanGitCompleted,
      lockReason: null,
    },
    docker: {
      isLocked: !isGitComplete,
      isCompleted: isDockerComplete,
      totalModules: dockerModules.length,
      completedCount: cleanDockerCompleted.length,
      completedModules: cleanDockerCompleted,
      lockReason: !isGitComplete
        ? "Docker pathway is locked. Complete all Git modules to unlock."
        : null,
    },
    linux: {
      isLocked: !isDockerComplete,
      isCompleted: isLinuxComplete,
      totalModules: linuxModules.length,
      completedCount: cleanLinuxCompleted.length,
      completedModules: cleanLinuxCompleted,
      lockReason: !isGitComplete
        ? "Linux pathway is locked. Complete all Git modules first."
        : !isDockerComplete
          ? "Linux pathway is locked. Complete all Docker modules to unlock."
          : null,
    },
  };
}

/**
 * GET /api/progress/pathways/status
 * Return lock and completion status for all core pathways.
 */
async function getPathwaysStatus(req, res) {
  try {
    const userId = req.user._id;
    const pathways = await getPathwayLockStatus(userId);
    return res.status(200).json({
      success: true,
      pathways,
    });
  } catch (err) {
    console.error("Error fetching pathways status:", err);
    return res.status(500).json({
      success: false,
      message: "Failed to fetch pathways status",
    });
  }
}

/**
 * GET /api/progress/:pathwayId
 * Fetch all completed modules for the authenticated user and given pathway.
 * Returns deduplicated, valid completed module IDs.
 * Rejects access to locked pathways with 403 Forbidden.
 */
async function getProgress(req, res) {
  try {
    const pathwayId = req.params.pathwayId || "git";
    const userId = req.user._id;

    // Validate pathway-level locking
    if (pathwayId === "docker" || pathwayId === "linux") {
      const lockStatus = await getPathwayLockStatus(userId);
      if (lockStatus[pathwayId] && lockStatus[pathwayId].isLocked) {
        return res.status(403).json({
          success: false,
          pathwayId,
          isLocked: true,
          message: lockStatus[pathwayId].lockReason || `Pathway "${pathwayId}" is locked.`,
        });
      }
    }

    let progress = await Progress.findOne({ userId, pathwayId });
    if (!progress) {
      progress = await Progress.create({
        userId,
        pathwayId,
        completedModules: [],
      });
    }

    const pathwayModules = PATHWAY_CURRICULA[pathwayId];
    let uniqueModules = [...new Set(progress.completedModules || [])];
    if (pathwayModules) {
      uniqueModules = uniqueModules.filter((id) => pathwayModules.includes(id));
    }

    return res.status(200).json({
      success: true,
      pathwayId,
      completedModules: uniqueModules,
    });
  } catch (err) {
    console.error("Error fetching progress:", err);
    return res.status(500).json({
      success: false,
      message: "Failed to fetch user progress",
    });
  }
}

/**
 * POST /api/progress/:pathwayId/toggle
 * Toggle completion of a stop/module.
 * Enforces sequential pathway locking and sequential module unlocking.
 * Preceding module must be completed before a later module can be marked completed.
 * When a stop becomes completed, logs `stop_completed` server-side.
 */
async function toggleProgress(req, res) {
  try {
    const pathwayId = req.params.pathwayId || "git";
    const { moduleId } = req.body;
    const userId = req.user._id;

    if (!moduleId || typeof moduleId !== "string") {
      return res.status(400).json({
        success: false,
        message: "moduleId is required",
      });
    }

    const pathwayModules = PATHWAY_CURRICULA[pathwayId];
    if (!pathwayModules) {
      return res.status(400).json({
        success: false,
        message: `Unknown pathway: "${pathwayId}"`,
      });
    }

    // Validate pathway-level locking before allowing any module mutations
    if (pathwayId === "docker" || pathwayId === "linux") {
      const lockStatus = await getPathwayLockStatus(userId);
      if (lockStatus[pathwayId] && lockStatus[pathwayId].isLocked) {
        return res.status(403).json({
          success: false,
          pathwayId,
          moduleId,
          isLocked: true,
          message: lockStatus[pathwayId].lockReason || `Pathway "${pathwayId}" is locked.`,
        });
      }
    }

    const moduleIndex = pathwayModules.indexOf(moduleId);
    if (moduleIndex === -1) {
      return res.status(400).json({
        success: false,
        message: `Invalid moduleId "${moduleId}" for pathway "${pathwayId}"`,
      });
    }

    let progress = await Progress.findOne({ userId, pathwayId });
    if (!progress) {
      progress = new Progress({
        userId,
        pathwayId,
        completedModules: [],
      });
    }

    // Clean and deduplicate existing modules
    const currentModules = [...new Set(progress.completedModules || [])].filter((id) =>
      pathwayModules.includes(id)
    );
    const isAlreadyCompleted = currentModules.includes(moduleId);
    let isNowCompleted;

    if (isAlreadyCompleted) {
      // Un-complete stop: remove this module and any subsequent modules that depended on it
      const allowedPrefix = pathwayModules.slice(0, moduleIndex);
      progress.completedModules = currentModules.filter((id) => allowedPrefix.includes(id));
      isNowCompleted = false;
      // Note: Historical progress in subsequent pathways is NOT deleted, but pathways will be locked dynamically.
    } else {
      // Complete stop: validate sequential completion within the pathway
      if (moduleIndex > 0) {
        const precedingModuleId = pathwayModules[moduleIndex - 1];
        if (!currentModules.includes(precedingModuleId)) {
          return res.status(400).json({
            success: false,
            message: `Cannot complete module "${moduleId}" out of sequence. Preceding module "${precedingModuleId}" must be completed first.`,
          });
        }
      }

      progress.completedModules = [...new Set([...currentModules, moduleId])];
      isNowCompleted = true;

      // Log stop_completed server-side at the moment it becomes completed
      await logActivity(userId, "stop_completed", {
        pathwayId,
        stopSlug: moduleId,
      });
    }

    progress.lastUpdated = new Date();
    await progress.save();

    return res.status(200).json({
      success: true,
      pathwayId,
      moduleId,
      isCompleted: isNowCompleted,
      completedModules: progress.completedModules,
    });
  } catch (err) {
    console.error("Error toggling progress:", err);
    return res.status(500).json({
      success: false,
      message: "Failed to update progress",
    });
  }
}

module.exports = {
  getProgress,
  toggleProgress,
  getPathwaysStatus,
  getPathwayLockStatus,
  PATHWAY_CURRICULA,
};
