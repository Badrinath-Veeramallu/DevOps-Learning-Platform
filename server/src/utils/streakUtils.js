/**
 * Streak Calculation Utilities for DevOps Learning Platform
 *
 * Implements deterministic calendar-day streak calculations in the user's local timezone.
 * Handles:
 * - Consecutive calendar days (yesterday -> today)
 * - Preservation of yesterday's streak when user has not yet completed activity today
 * - Reset to 0 when last activity was 2 or more days ago
 * - Historical longest streak tracking (never decreases on streak breaks)
 * - Safe date arithmetic across month, year, and leap year boundaries
 * - Deduplication of multiple events on the same calendar date
 */

/**
 * Validates timezone and returns standard formatter or UTC fallback
 * @param {string} [timeZone]
 * @returns {Intl.DateTimeFormat}
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
 * Computes the previous calendar date in YYYY-MM-DD format.
 * Uses UTC noon to safely avoid any daylight saving transitions.
 * @param {string} dateStr - Date string in "YYYY-MM-DD"
 * @returns {string} Previous calendar date in "YYYY-MM-DD"
 */
function getPreviousDateStr(dateStr) {
  const [y, m, d] = dateStr.split("-").map(Number);
  const dt = new Date(Date.UTC(y, m - 1, d, 12, 0, 0));
  dt.setUTCDate(dt.getUTCDate() - 1);
  return dt.toISOString().slice(0, 10);
}

/**
 * Calculates current streak, longest streak, and streak state metadata
 * from a list of activity dates in the specified timezone.
 *
 * @param {Array<Date|string|number>} activityDates - List of activity timestamps
 * @param {string} [timeZone='UTC'] - User's local timezone
 * @param {Date} [referenceNow=new Date()] - Current timestamp reference
 * @returns {{
 *   currentStreak: number,
 *   longestStreak: number,
 *   isActiveToday: boolean,
 *   hasActivityYesterday: boolean,
 *   lastActiveDate: string|null,
 *   totalActiveDays: number,
 *   todayDateStr: string,
 *   yesterdayDateStr: string
 * }}
 */
function calculateStreaks(activityDates = [], timeZone = "UTC", referenceNow = new Date()) {
  const formatter = getDateFormatter(timeZone);
  const todayDateStr = formatter.format(referenceNow);
  const yesterdayDateStr = getPreviousDateStr(todayDateStr);

  // Group into a set of unique local date strings: "YYYY-MM-DD"
  const uniqueDatesSet = new Set();
  for (const dateItem of activityDates) {
    if (!dateItem) continue;
    const dt = dateItem instanceof Date ? dateItem : new Date(dateItem);
    if (!isNaN(dt.getTime())) {
      const dateStr = formatter.format(dt);
      // Only include dates up to today (filter out any accidental future records)
      if (dateStr <= todayDateStr) {
        uniqueDatesSet.add(dateStr);
      }
    }
  }

  const sortedDates = Array.from(uniqueDatesSet).sort(); // Ascending "YYYY-MM-DD"
  const totalActiveDays = sortedDates.length;

  if (totalActiveDays === 0) {
    return {
      currentStreak: 0,
      longestStreak: 0,
      isActiveToday: false,
      hasActivityYesterday: false,
      lastActiveDate: null,
      totalActiveDays: 0,
      todayDateStr,
      yesterdayDateStr,
    };
  }

  const lastActiveDate = sortedDates[sortedDates.length - 1];

  // 1. Calculate Longest Streak across all historical unique active calendar days
  let maxStreak = 0;
  let currentRun = 0;
  let prevDate = null;

  for (const dateStr of sortedDates) {
    if (!prevDate) {
      currentRun = 1;
    } else {
      if (getPreviousDateStr(dateStr) === prevDate) {
        currentRun += 1;
      } else {
        currentRun = 1;
      }
    }
    if (currentRun > maxStreak) {
      maxStreak = currentRun;
    }
    prevDate = dateStr;
  }

  // 2. Calculate Current Streak:
  // - If user has completed activity today: count backwards starting from today.
  // - If user has no activity today, but was active yesterday: preserve yesterday's streak until today ends.
  // - If user was last active before yesterday: current streak is 0 (broken).
  const isActiveToday = uniqueDatesSet.has(todayDateStr);
  const hasActivityYesterday = uniqueDatesSet.has(yesterdayDateStr);

  let currentStreak = 0;

  if (isActiveToday) {
    let checkDate = todayDateStr;
    while (uniqueDatesSet.has(checkDate)) {
      currentStreak++;
      checkDate = getPreviousDateStr(checkDate);
    }
  } else if (hasActivityYesterday) {
    let checkDate = yesterdayDateStr;
    while (uniqueDatesSet.has(checkDate)) {
      currentStreak++;
      checkDate = getPreviousDateStr(checkDate);
    }
  } else {
    currentStreak = 0;
  }

  // Longest streak must never be lower than the current streak
  const longestStreak = Math.max(maxStreak, currentStreak);

  return {
    currentStreak,
    longestStreak,
    isActiveToday,
    hasActivityYesterday,
    lastActiveDate,
    totalActiveDays,
    todayDateStr,
    yesterdayDateStr,
  };
}

module.exports = {
  getDateFormatter,
  getPreviousDateStr,
  calculateStreaks,
};

