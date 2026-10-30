const Progress = require("../models/Progress");
const { logActivity } = require("../utils/activityLogger");

/**
 * GET /api/progress/:pathwayId
 * Fetch all completed modules for the authenticated user and given pathway.
 */
async function getProgress(req, res) {
  try {
    const pathwayId = req.params.pathwayId || "git";
    const userId = req.user._id;

    let progress = await Progress.findOne({ userId, pathwayId });
    if (!progress) {
      progress = await Progress.create({
        userId,
        pathwayId,
        completedModules: [],
      });
    }

    return res.status(200).json({
      success: true,
      pathwayId,
      completedModules: progress.completedModules || [],
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

    let progress = await Progress.findOne({ userId, pathwayId });
    if (!progress) {
      progress = new Progress({
        userId,
        pathwayId,
        completedModules: [],
      });
    }

    const currentModules = progress.completedModules || [];
    const isAlreadyCompleted = currentModules.includes(moduleId);
    let isNowCompleted;

    if (isAlreadyCompleted) {
      // Un-complete stop
      progress.completedModules = currentModules.filter((id) => id !== moduleId);
      isNowCompleted = false;
      // Note: As specified, do not delete the activity event when a stop is un-completed
    } else {
      // Complete stop
      progress.completedModules = [...currentModules, moduleId];
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
};
