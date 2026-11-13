/**
 * LearningStreak Component
 *
 * Clean, minimal streak statistics display inspired by LeetCode:
 *   Current Streak: 3 days     Max Streak: 3 days
 *
 * Completely text-based without card backgrounds, borders, flames, or extra badges.
 */
export const LearningStreak = ({
  streak = null,
  loading = false,
  variant = "inline",
  className = "",
}) => {
  const currentStreak = streak?.currentStreak ?? 0;
  const longestStreak = streak?.longestStreak ?? 0;
  const isActiveToday = Boolean(streak?.isActiveToday);
  const hasActivityYesterday = Boolean(streak?.hasActivityYesterday);

  // Compact pill variant (for Dashboard header)
  if (variant === "pill") {
    if (loading) {
      return (
        <div className={`streak-pill streak-pill-loading ${className}`} aria-label="Loading streak">
          <div className="streak-pill-skeleton" />
        </div>
      );
    }

    return (
      <div
        className={`streak-pill ${currentStreak > 0 ? "streak-active" : "streak-inactive"} ${className}`}
        title={`Current streak: ${currentStreak} ${currentStreak === 1 ? "day" : "days"} (Max: ${longestStreak} ${longestStreak === 1 ? "day" : "days"})`}
        role="status"
        aria-label={`Current learning streak: ${currentStreak} ${currentStreak === 1 ? "day" : "days"}`}
      >
        <span className="streak-pill-count">{currentStreak}</span>
        <span className="streak-pill-label">
          {currentStreak === 1 ? "day streak" : "days streak"}
        </span>
        {currentStreak > 0 && !isActiveToday && hasActivityYesterday && (
          <span
            className="streak-pill-dot pending"
            title="Active yesterday — complete an activity today to maintain your streak!"
            aria-hidden="true"
          />
        )}
      </div>
    );
  }

  // Minimal text-based statistics layout for Learning Activity Heatmap (LeetCode style)
  return (
    <div
      className={`heatmap-streak-stats ${className}`}
      role="region"
      aria-label="Learning streak statistics"
    >
      <div className="streak-stat-item">
        <span className="streak-stat-label">Current Streak:</span>
        <strong className="streak-stat-value">
          {loading && !streak
            ? "—"
            : `${currentStreak} ${currentStreak === 1 ? "day" : "days"}`}
        </strong>
      </div>

      <div className="streak-stat-item">
        <span className="streak-stat-label">Max Streak:</span>
        <strong className="streak-stat-value">
          {loading && !streak
            ? "—"
            : `${longestStreak} ${longestStreak === 1 ? "day" : "days"}`}
        </strong>
      </div>
    </div>
  );
};

export default LearningStreak;
