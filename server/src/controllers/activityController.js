const Activity = require("../models/Activity");
const { logActivity } = require("../utils/activityLogger");
const { getPathwayLockStatus } = require("./progressController");
const { calculateStreaks, getDateFormatter } = require("../utils/streakUtils");

/**
 * GET /api/activity
 * Fetch aggregated daily activity counts over the last 365 days ending today,
 * along with the user's current and longest streaks.
 */
async function getActivity(req, res) {
  try {
    const userId = req.user._id;
    const requestedTz = (req.query.tz || "").trim();
    const formatter = getDateFormatter(requestedTz);

    const now = new Date();
    const todayDateStr = formatter.format(now);

    const queryCutoff = new Date(now.getTime() - 370 * 24 * 60 * 60 * 1000);

    const activities = await Activity.find({
      userId,
      createdAt: { $gte: queryCutoff, $lte: now },
    }).sort({ createdAt: 1 });

    const [tY, tM, tD] = todayDateStr.split("-").map(Number);
    const todayUtc = new Date(Date.UTC(tY, tM - 1, tD, 12, 0, 0));
    const minDateUtc = new Date(todayUtc.getTime() - 364 * 24 * 60 * 60 * 1000);
    const minDateStr = formatter.format(minDateUtc);

    const dayCounts = {};

    for (const act of activities) {
      const dateKey = formatter.format(act.createdAt);
      if (dateKey >= minDateStr && dateKey <= todayDateStr) {
        dayCounts[dateKey] = (dayCounts[dateKey] || 0) + 1;
      }
    }

    const days = Object.entries(dayCounts)
      .filter(([, count]) => count > 0)
      .map(([date, count]) => ({ date, count }))
      .sort((a, b) => a.date.localeCompare(b.date));

    const total = days.reduce((sum, d) => sum + d.count, 0);

    const allUserActivities = await Activity.find({ userId })
      .select("createdAt")
      .lean();

    const streak = calculateStreaks(
      allUserActivities.map((a) => a.createdAt),
      requestedTz,
      now
    );

    return res.status(200).json({
      total,
      days,
      streak,
    });
  } catch (err) {
    console.error("Error fetching activity data:", err);
    return res.status(500).json({
      success: false,
      message: "Failed to fetch activity data",
    });
  }
}

/**
 * GET /api/activity/streak
 */
async function getStreak(req, res) {
  try {
    const userId = req.user._id;
    const requestedTz = (req.query.tz || "").trim();

    const allUserActivities = await Activity.find({ userId })
      .select("createdAt")
      .lean();

    const streak = calculateStreaks(
      allUserActivities.map((a) => a.createdAt),
      requestedTz
    );

    return res.status(200).json({
      success: true,
      streak,
    });
  } catch (err) {
    console.error("Error fetching streak data:", err);
    return res.status(500).json({
      success: false,
      message: "Failed to fetch streak data",
    });
  }
}

/**
 * POST /api/activity/log
 * Rejects activity logging for locked pathways.
 */
async function logClientActivity(req, res) {
  try {
    const userId = req.user._id;
    const { type, pathwayId = "git", stopSlug } = req.body;

    if (!type || (type !== "lesson_viewed" && type !== "animation_finished")) {
      return res.status(400).json({
        success: false,
        message: "Invalid activity type. Allowed: lesson_viewed, animation_finished",
      });
    }

    if (!stopSlug || typeof stopSlug !== "string") {
      return res.status(400).json({
        success: false,
        message: "stopSlug is required",
      });
    }

    if (pathwayId === "docker" || pathwayId === "linux") {
      const lockStatus = await getPathwayLockStatus(userId);
      if (lockStatus[pathwayId] && lockStatus[pathwayId].isLocked) {
        return res.status(403).json({
          success: false,
          isLocked: true,
          message: lockStatus[pathwayId].lockReason || `Cannot log activity for locked pathway "${pathwayId}".`,
        });
      }
    }

    const activity = await logActivity(userId, type, {
      pathwayId,
      stopSlug,
    });

    return res.status(200).json({
      success: true,
      logged: !!activity,
    });
  } catch (err) {
    console.error("Error logging client activity:", err);
    return res.status(500).json({
      success: false,
      message: "Failed to record activity",
    });
  }
}

module.exports = {
  getActivity,
  getStreak,
  logClientActivity,
};
