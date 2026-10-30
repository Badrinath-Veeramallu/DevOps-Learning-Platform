import { useState, useEffect, useMemo, useCallback } from "react";
import { activityAPI } from "../services/api";

/**
 * ActivityHeatmap — Real GitHub/LeetCode-style 12-month calendar activity grid.
 *
 * Fetches real authenticated activity history from /api/activity?tz=...
 * Displays real daily counts, responsive week columns, month labels without collisions,
 * exact-pixel weekday row alignments, and reactive updates on stop/module completion.
 */
export const ActivityHeatmap = ({ className = "" }) => {
  const [activityData, setActivityData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [tooltip, setTooltip] = useState(null);

  const fetchActivity = useCallback(async () => {
    try {
      const tz =
        typeof Intl !== "undefined" && Intl.DateTimeFormat
          ? Intl.DateTimeFormat().resolvedOptions().timeZone || "UTC"
          : "UTC";

      const data = await activityAPI.getActivity(tz);
      setActivityData(data);
      setError(null);
    } catch (err) {
      console.error("Failed to load activity heatmap:", err);
      setError(err.message || "Failed to load learning activity data");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchActivity();

    // Listen to custom events dispatched when stops are completed or lessons viewed
    const handleActivityChange = () => {
      fetchActivity();
    };

    window.addEventListener("devops_progress_updated", handleActivityChange);
    window.addEventListener("devops_activity_updated", handleActivityChange);

    return () => {
      window.removeEventListener("devops_progress_updated", handleActivityChange);
      window.removeEventListener("devops_activity_updated", handleActivityChange);
    };
  }, [fetchActivity]);

  // Construct quick-lookup map: { "YYYY-MM-DD": count }
  const dayCountsMap = useMemo(() => {
    const map = {};
    if (activityData && Array.isArray(activityData.days)) {
      for (const item of activityData.days) {
        if (item && item.date && typeof item.count === "number") {
          map[item.date] = item.count;
        }
      }
    }
    return map;
  }, [activityData]);

  const totalActivities = activityData?.total ?? 0;

  // Build the 365-day grid ending today
  const { weeks, monthLabels } = useMemo(() => {
    const userTz =
      typeof Intl !== "undefined" && Intl.DateTimeFormat
        ? Intl.DateTimeFormat().resolvedOptions().timeZone || "UTC"
        : "UTC";

    // Formatter to produce standard YYYY-MM-DD in the user's timezone
    let dateFmt;
    try {
      dateFmt = new Intl.DateTimeFormat("en-CA", {
        timeZone: userTz,
        year: "numeric",
        month: "2-digit",
        day: "2-digit",
      });
    } catch {
      dateFmt = new Intl.DateTimeFormat("en-CA", {
        timeZone: "UTC",
        year: "numeric",
        month: "2-digit",
        day: "2-digit",
      });
    }

    const todayStr = dateFmt.format(new Date());
    const [tY, tM, tD] = todayStr.split("-").map(Number);
    // Use noon UTC to avoid any daylight saving transitions
    const todayUtc = new Date(Date.UTC(tY, tM - 1, tD, 12, 0, 0));

    // 365 days window: startDate is 364 days before today
    const startDateUtc = new Date(todayUtc.getTime() - 364 * 24 * 60 * 60 * 1000);
    const startDayOfWeek = startDateUtc.getUTCDay(); // 0 = Sun, 6 = Sat

    // The first column starts on the Sunday of the week that contains the date 365 days ago
    const gridStartUtc = new Date(
      startDateUtc.getTime() - startDayOfWeek * 24 * 60 * 60 * 1000
    );

    const generatedWeeks = [];
    let cur = new Date(gridStartUtc);
    let currentWeek = [];

    while (cur <= todayUtc || currentWeek.length > 0) {
      const dateStr = cur.toISOString().slice(0, 10);
      const isFuture = dateStr > todayStr;
      const count = dayCountsMap[dateStr] || 0;

      // Color levels:
      // 0: none, 1: 1 activity, 2: 2–3, 3: 4–6, 4: 7+
      let level = 0;
      if (!isFuture) {
        if (count >= 7) level = 4;
        else if (count >= 4) level = 3;
        else if (count >= 2) level = 2;
        else if (count >= 1) level = 1;
      }

      // Format for display & tooltips
      const formattedDate = cur.toLocaleDateString("en-US", {
        month: "short",
        day: "numeric",
        year: "numeric",
        timeZone: "UTC",
      });

      const tooltipText =
        count === 0
          ? `No activity on ${formattedDate}`
          : `${count} ${count === 1 ? "activity" : "activities"} on ${formattedDate}`;

      currentWeek.push({
        date: dateStr,
        formattedDate,
        isFuture,
        count,
        level,
        tooltipText,
        dayOfWeek: cur.getUTCDay(),
        dayOfMonth: cur.getUTCDate(),
        monthShort: cur.toLocaleDateString("en-US", {
          month: "short",
          timeZone: "UTC",
        }),
      });

      if (currentWeek.length === 7) {
        generatedWeeks.push(currentWeek);
        currentWeek = [];
        if (cur >= todayUtc) {
          break;
        }
      }

      cur = new Date(cur.getTime() + 24 * 60 * 60 * 1000);
    }

    // Identify month labels across week columns
    const rawMonthLabels = [];
    generatedWeeks.forEach((week, wIdx) => {
      const firstOfMonth = week.find((day) => day.dayOfMonth === 1);
      if (firstOfMonth) {
        rawMonthLabels.push({
          label: firstOfMonth.monthShort,
          weekIndex: wIdx,
        });
      } else if (wIdx === 0) {
        rawMonthLabels.push({
          label: week[0].monthShort,
          weekIndex: 0,
        });
      }
    });

    // Month label collision fix: when two adjacent labels are less than 3 columns apart, skip the second one
    const filteredMonthLabels = [];
    for (let i = 0; i < rawMonthLabels.length; i++) {
      const current = rawMonthLabels[i];
      const prev = filteredMonthLabels[filteredMonthLabels.length - 1];
      if (prev && current.weekIndex - prev.weekIndex < 3) {
        continue; // skip adjacent collision
      }
      filteredMonthLabels.push(current);
    }

    return {
      weeks: generatedWeeks,
      monthLabels: filteredMonthLabels,
    };
  }, [dayCountsMap]);

  return (
    <div className={`activity-heatmap-card ${className}`}>
      {/* Header Stat & Title */}
      <div className="heatmap-header-row">
        <div>
          <div className="heatmap-title-wrap">
            <h3 className="heatmap-heading">Learning Activity</h3>
          </div>
          <p className="heatmap-subtitle">Your learning activity over the past year.</p>
        </div>

        <div className="heatmap-summary-stat">
          <span className="summary-stat-count">
            {loading && !activityData ? "—" : totalActivities}
          </span>
          <span className="summary-stat-label">
            {totalActivities === 1
              ? "activity in the last year"
              : "activities in the last year"}
          </span>
        </div>
      </div>

      {/* Error Notice */}
      {error && (
        <div className="heatmap-error-notice" role="alert">
          <span>Failed to load activity data.</span>
          <button
            type="button"
            className="heatmap-retry-btn"
            onClick={fetchActivity}
          >
            Retry
          </button>
        </div>
      )}

      {/* Responsive Horizontal Scroll Container */}
      <div className="heatmap-scroll-container">
        <div className="heatmap-grid-wrapper">
          {/* Month Labels Bar */}
          <div className="heatmap-months-row" aria-hidden="true">
            <div className="heatmap-day-spacer" />
            <div className="heatmap-months-track">
              {monthLabels.map((m, idx) => (
                <span
                  key={idx}
                  className="heatmap-month-label"
                  style={{ left: `${m.weekIndex * 15}px` }}
                >
                  {m.label}
                </span>
              ))}
            </div>
          </div>

          {/* Main Grid: Days of Week on Left + 52-53 Columns of 7 Days */}
          <div className="heatmap-main-body">
            {/* Weekday Labels (Mon, Wed, Fri aligned to their exact row slots) */}
            <div className="heatmap-weekdays-col" aria-hidden="true">
              {/* Row 0: Sunday */}
              <div className="heatmap-weekday-slot" />
              {/* Row 1: Monday */}
              <div className="heatmap-weekday-slot">
                <span className="heatmap-weekday-label">Mon</span>
              </div>
              {/* Row 2: Tuesday */}
              <div className="heatmap-weekday-slot" />
              {/* Row 3: Wednesday */}
              <div className="heatmap-weekday-slot">
                <span className="heatmap-weekday-label">Wed</span>
              </div>
              {/* Row 4: Thursday */}
              <div className="heatmap-weekday-slot" />
              {/* Row 5: Friday */}
              <div className="heatmap-weekday-slot">
                <span className="heatmap-weekday-label">Fri</span>
              </div>
              {/* Row 6: Saturday */}
              <div className="heatmap-weekday-slot" />
            </div>

            {/* Heatmap Grid Columns */}
            <div
              className="heatmap-weeks-track"
              role="region"
              aria-label="Activity calendar grid"
            >
              {weeks.map((week, wIdx) => (
                <div key={wIdx} className="heatmap-week-column">
                  {week.map((day) => {
                    // Do not render cells for dates in the future
                    if (day.isFuture) {
                      return (
                        <div
                          key={day.date}
                          className="heatmap-cell heatmap-cell-future"
                          aria-hidden="true"
                          style={{ visibility: "hidden", pointerEvents: "none" }}
                        />
                      );
                    }

                    return (
                      <button
                        key={day.date}
                        type="button"
                        className={`heatmap-cell level-${day.level}`}
                        aria-label={day.tooltipText}
                        onMouseEnter={(e) => {
                          const rect = e.currentTarget.getBoundingClientRect();
                          setTooltip({
                            text: day.tooltipText,
                            top: rect.top - 36,
                            left: rect.left + rect.width / 2,
                          });
                        }}
                        onMouseLeave={() => setTooltip(null)}
                        onFocus={(e) => {
                          const rect = e.currentTarget.getBoundingClientRect();
                          setTooltip({
                            text: day.tooltipText,
                            top: rect.top - 36,
                            left: rect.left + rect.width / 2,
                          });
                        }}
                        onBlur={() => setTooltip(null)}
                      />
                    );
                  })}
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>

      {/* Floating Hover & Keyboard Focus Tooltip */}
      {tooltip && (
        <div
          className="heatmap-floating-tooltip"
          role="tooltip"
          style={{
            top: `${tooltip.top}px`,
            left: `${tooltip.left}px`,
          }}
        >
          {tooltip.text}
        </div>
      )}

      {/* Empty State Hint (When total is 0) */}
      {!loading && totalActivities === 0 && (
        <div className="heatmap-empty-hint" role="status">
          <svg
            width="15"
            height="15"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth="2"
            aria-hidden="true"
          >
            <circle cx="12" cy="12" r="10" />
            <line x1="12" y1="16" x2="12" y2="12" />
            <line x1="12" y1="8" x2="12.01" y2="8" />
          </svg>
          <span>Complete a stop to start your activity map.</span>
        </div>
      )}

      {/* Legend */}
      <div className="heatmap-footer-row">
        <div className="heatmap-legend" aria-label="Activity level legend">
          <span className="legend-label">Less activity</span>
          <span className="heatmap-cell level-0" aria-hidden="true" />
          <span className="heatmap-cell level-1" aria-hidden="true" />
          <span className="heatmap-cell level-2" aria-hidden="true" />
          <span className="heatmap-cell level-3" aria-hidden="true" />
          <span className="heatmap-cell level-4" aria-hidden="true" />
          <span className="legend-label">More activity</span>
        </div>
      </div>
    </div>
  );
};

export default ActivityHeatmap;
