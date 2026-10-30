const Activity = require("../models/Activity");

/**
 * Log an activity event for an authenticated user.
 *
 * @param {string|import('mongoose').Types.ObjectId} userId - User ID
 * @param {'stop_completed'|'lesson_viewed'|'animation_finished'} type - Event type
 * @param {Object} meta - Additional metadata
 * @param {string} [meta.pathwayId='git'] - Pathway or topic ID
 * @param {string} meta.stopSlug - Stop ID or lesson slug
 * @param {Date|number} [meta.timestamp] - Optional timestamp (defaults to now)
 * @returns {Promise<Activity|null>} Newly created activity or null if deduplicated
 */
async function logActivity(userId, type, meta = {}) {
  try {
    const { pathwayId = "git", stopSlug, timestamp } = meta;
    if (!userId || !type || !stopSlug) {
      return null;
    }

    const eventTime = timestamp ? new Date(timestamp) : new Date();

    // 1. stop_completed:
    // Logged only from server-side when a stop becomes completed.
    // Do not log again if the stop was already completed previously.
    if (type === "stop_completed") {
      const alreadyCompleted = await Activity.findOne({
        userId,
        type: "stop_completed",
        stopSlug,
      });

      if (alreadyCompleted) {
        return null; // Already logged previously; do not log duplicate
      }
    }

    // 2. lesson_viewed & 3. animation_finished:
    // Log at most once per user per lesson per day.
    if (type === "lesson_viewed" || type === "animation_finished") {
      const startOfDay = new Date(eventTime);
      startOfDay.setUTCHours(0, 0, 0, 0);
      const endOfDay = new Date(eventTime);
      endOfDay.setUTCHours(23, 59, 59, 999);

      const existingToday = await Activity.findOne({
        userId,
        type,
        stopSlug,
        createdAt: { $gte: startOfDay, $lte: endOfDay },
      });

      if (existingToday) {
        return null; // Already logged today
      }
    }

    const activity = new Activity({
      userId,
      type,
      pathwayId,
      stopSlug,
      createdAt: eventTime,
    });

    await activity.save();
    return activity;
  } catch (err) {
    console.error("Error logging user activity:", err.message);
    return null;
  }
}

module.exports = { logActivity };
