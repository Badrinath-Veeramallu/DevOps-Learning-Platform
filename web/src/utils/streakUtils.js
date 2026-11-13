/**
 * Client-Side Streak Utilities for DevOps Learning Platform
 *
 * Implements deterministic calendar-day streak calculations in the user's local timezone.
 */

export function getUserTimeZone() {
  try {
    return (
      (typeof Intl !== "undefined" &&
        Intl.DateTimeFormat &&
        Intl.DateTimeFormat().resolvedOptions().timeZone) ||
      "UTC"
    );
  } catch {
    return "UTC";
  }
}

export function getDateFormatter(timeZone) {
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

export function getPreviousDateStr(dateStr) {
  const [y, m, d] = dateStr.split("-").map(Number);
  const dt = new Date(Date.UTC(y, m - 1, d, 12, 0, 0));
  dt.setUTCDate(dt.getUTCDate() - 1);
  return dt.toISOString().slice(0, 10);
}

/**
 * Calculates current streak and longest streak from activity records or dates.
 *
 * @param {Array<Date|string|number|{date: string, count: number}>} activityItems
 * @param {string} [timeZone]
 * @param {Date} [referenceNow=new Date()]
 */
export function calculateStreaks(activityItems = [], timeZone = getUserTimeZone(), referenceNow = new Date()) {
  const formatter = getDateFormatter(timeZone);
  const todayDateStr = formatter.format(referenceNow);
  const yesterdayDateStr = getPreviousDateStr(todayDateStr);

  const uniqueDatesSet = new Set();

  for (const item of activityItems) {
    if (!item) continue;

    // Handle { date: 'YYYY-MM-DD', count: >0 } from heatmap days array
    if (typeof item === "object" && typeof item.date === "string") {
      if (typeof item.count === "number" && item.count > 0 && item.date <= todayDateStr) {
        uniqueDatesSet.add(item.date);
      }
      continue;
    }

    const dt = item instanceof Date ? item : new Date(item);
    if (!isNaN(dt.getTime())) {
      const dateStr = formatter.format(dt);
      if (dateStr <= todayDateStr) {
        uniqueDatesSet.add(dateStr);
      }
    }
  }

  const sortedDates = Array.from(uniqueDatesSet).sort();
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

