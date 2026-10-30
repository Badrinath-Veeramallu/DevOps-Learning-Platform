const Activity = require("../models/Activity");
const { logActivity } = require("../utils/activityLogger");

/**
 * Validates timezone and returns standard formatter or UTC fallback
 */
function getDateFormatter(timeZone) {
  try {
    return new Intl.DateTimeFormat("en-CA", {
      timeZone: timeZone || "UTC",
      year: "numeric",
      month: "2-digit",
      day: "2-digit",
    });
  } catch {
    return new Intl.DateTimeFormat("en-CA", {
      timeZone: "UTC",
      year: "numeric",
      month: "2-digit",
      day: "2-digit",
    });
  }
}

/**
 * GET /api/activity
 * Fetch aggregated daily activity counts over the last 365 days ending today.
 */
async function getActivity(req, res) {
  try {
    const userId = req.user._id;
    const requestedTz = (req.query.tz || "").trim();
    const formatter = getDateFormatter(requestedTz);

    // Get today's date string in the requested timezone
    const now = new Date();
    const todayDateStr = formatter.format(now);

    // Calculate calendar cutoff 365 days ending today (today + previous 364 calendar days)
    // To be safe with timezone offsets, query MongoDB for the past 370 days
    const queryCutoff = new Date(now.getTime() - 370 * 24 * 60 * 60 * 1000);

    const activities = await Activity.find({
      userId,
      createdAt: { $gte: queryCutoff, $lte: now },
    }).sort({ createdAt: 1 });

    // Derive 365-day range in requested timezone: [minDateStr, todayDateStr]
    // Parse today's year, month, day in tz
    const [tY, tM, tD] = todayDateStr.split("-").map(Number);
    const todayUtc = new Date(Date.UTC(tY, tM - 1, tD, 12, 0, 0));
    const minDateUtc = new Date(todayUtc.getTime() - 364 * 24 * 60 * 60 * 1000);
    const minDateStr = formatter.format(minDateUtc);

    const dayCounts = {};

    for (const act of activities) {
      const dateKey = formatter.format(act.createdAt);
      // Only include dates within the 365-day window ending today
      if (dateKey >= minDateStr && dateKey <= todayDateStr) {
        dayCounts[dateKey] = (dayCounts[dateKey] || 0) + 1;
      }
    }

    const days = Object.entries(dayCounts)
      .filter(([, count]) => count > 0)
      .map(([date, count]) => ({ date, count }))
      .sort((a, b) => a.date.localeCompare(b.date));

    const total = days.reduce((sum, d) => sum + d.count, 0);

    return res.status(200).json({
      total,
      days,
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
 * POST /api/activity/log
 * Authenticated endpoint to log lesson_viewed and animation_finished events.
 * stop_completed is exclusively logged server-side by progressController.
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
  logClientActivity,
};
