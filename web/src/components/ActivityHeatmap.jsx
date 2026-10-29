import { useState, useMemo } from "react";

/**
 * Deterministic pseudo-random number generator (Mulberry32)
 * Ensures repeatable, non-random heatmap data per user seed.
 */
function createPrng(seedStr = "devops-seed-2026") {
  let h = 1779033703 ^ seedStr.length;
  for (let i = 0; i < seedStr.length; i++) {
    h = Math.imul(h ^ seedStr.charCodeAt(i), 3432918353);
    h = (h << 13) | (h >>> 19);
  }
  let a = h >>> 0;
  return () => {
    let t = (a += 0x6d2b79f5);
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

/**
 * ActivityHeatmap — GitHub/LeetCode-style 12-month calendar activity grid.
 *
 * Supports real data input via `activityData` ({ [date: string]: number })
 * or falls back to deterministic sample activity data when tracking is not yet implemented.
 */
export const ActivityHeatmap = ({
  activityData = null,
  isMock = true,
  userSeed = "devops-learner",
}) => {
  const [tooltip, setTooltip] = useState(null);
  const [currentDate] = useState(() => new Date());

  // Generate the last 52 weeks of dates up to today
  const { weeks, monthLabels, totalActivities } = useMemo(() => {
    const today = new Date(currentDate);
    // Normalize to end of today
    today.setHours(23, 59, 59, 999);

    // Calculate start date: 52 weeks ago, aligned to the previous Sunday
    const startDate = new Date(today);
    startDate.setDate(today.getDate() - 52 * 7 - today.getDay());
    startDate.setHours(0, 0, 0, 0);

    const prng = createPrng(userSeed);

    const generatedWeeks = [];
    const generatedMonthLabels = [];
    let currentMonth = -1;
    let totalCount = 0;

    const curDate = new Date(startDate);
    let currentWeek = [];

    while (curDate <= today) {
      const year = curDate.getFullYear();
      const month = String(curDate.getMonth() + 1).padStart(2, "0");
      const day = String(curDate.getDate()).padStart(2, "0");
      const dateKey = `${year}-${month}-${day}`;

      let count = 0;

      if (activityData && typeof activityData[dateKey] === "number") {
        count = activityData[dateKey];
      } else if (isMock) {
        // Deterministic realistic activity pattern:
        // ~60% inactive, ~25% light (1-2), ~10% moderate (3-5), ~5% high (6-8)
        const rand = prng();
        const dayOfWeek = curDate.getDay();
        const isWeekend = dayOfWeek === 0 || dayOfWeek === 6;

        if (isWeekend) {
          if (rand > 0.75) count = Math.floor(prng() * 4) + 1;
        } else {
          if (rand > 0.55) {
            if (rand > 0.92) {
              count = Math.floor(prng() * 4) + 6; // 6-9
            } else if (rand > 0.78) {
              count = Math.floor(prng() * 3) + 3; // 3-5
            } else {
              count = Math.floor(prng() * 2) + 1; // 1-2
            }
          }
        }
      }

      totalCount += count;

      // Activity level 0 - 4
      let level = 0;
      if (count >= 7) level = 4;
      else if (count >= 5) level = 3;
      else if (count >= 3) level = 2;
      else if (count >= 1) level = 1;

      const formattedDate = curDate.toLocaleDateString(undefined, {
        month: "short",
        day: "numeric",
        year: "numeric",
      });

      currentWeek.push({
        date: dateKey,
        formattedDate,
        count,
        level,
        dayOfWeek: curDate.getDay(),
      });

      // Track month labels when moving into a new week and month
      if (curDate.getMonth() !== currentMonth && currentWeek.length === 1) {
        currentMonth = curDate.getMonth();
        const monthName = curDate.toLocaleDateString(undefined, { month: "short" });
        generatedMonthLabels.push({
          label: monthName,
          weekIndex: generatedWeeks.length,
        });
      }

      if (currentWeek.length === 7) {
        generatedWeeks.push(currentWeek);
        currentWeek = [];
      }

      curDate.setDate(curDate.getDate() + 1);
    }

    if (currentWeek.length > 0) {
      generatedWeeks.push(currentWeek);
    }

    return {
      weeks: generatedWeeks,
      monthLabels: generatedMonthLabels,
      totalActivities: totalCount,
    };
  }, [activityData, isMock, userSeed, currentDate]);

  return (
    <div className="activity-heatmap-card">
      <div className="heatmap-header-row">
        <div>
          <div className="heatmap-title-wrap">
            <h3 className="heatmap-heading">Learning Activity</h3>
            {isMock && (
              <span className="heatmap-mock-badge" title="Displaying sample data">
                Sample activity data
              </span>
            )}
          </div>
          <p className="heatmap-subtitle">Your learning activity over the past year.</p>
        </div>

        <div className="heatmap-summary-stat">
          <span className="summary-stat-count">{totalActivities}</span>
          <span className="summary-stat-label">activities in the last year</span>
        </div>
      </div>

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

          {/* Main Grid: Days of Week on Left + 52 Columns of 7 Days */}
          <div className="heatmap-main-body">
            {/* Weekday Labels (Mon, Wed, Fri) */}
            <div className="heatmap-weekdays-col" aria-hidden="true">
              <span className="heatmap-weekday-label">Mon</span>
              <span className="heatmap-weekday-label">Wed</span>
              <span className="heatmap-weekday-label">Fri</span>
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
                    const label = `${day.count === 0 ? "No" : day.count} learning ${
                      day.count === 1 ? "activity" : "activities"
                    } on ${day.formattedDate}`;

                    return (
                      <button
                        key={day.date}
                        type="button"
                        className={`heatmap-cell level-${day.level}`}
                        aria-label={label}
                        onMouseEnter={(e) => {
                          const rect = e.currentTarget.getBoundingClientRect();
                          setTooltip({
                            text: label,
                            top: rect.top - 36,
                            left: rect.left + rect.width / 2,
                          });
                        }}
                        onMouseLeave={() => setTooltip(null)}
                        onFocus={(e) => {
                          const rect = e.currentTarget.getBoundingClientRect();
                          setTooltip({
                            text: label,
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

      {/* Floating Hover Tooltip */}
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

      {/* Legend & Footnote */}
      <div className="heatmap-footer-row">
        {isMock && (
          <span className="heatmap-disclaimer">
            * Sample activity data is displayed while automated module activity logging is being integrated.
          </span>
        )}

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
