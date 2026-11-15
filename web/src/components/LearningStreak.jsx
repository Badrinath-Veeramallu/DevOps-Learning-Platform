/**
 * LearningStreak Component
 *
 * Visual streak indicator and activity statistics for DevOps Learning Platform.
 * Supports:
 *   - "pill" variant for Dashboard header: [Thin Outline Flame Icon] [0] [streak]
 *   - "inline" variant for Learning Activity Heatmap (LeetCode style text statistics)
 */
export const LearningStreak = ({
  streak = null,
  loading = false,
  variant = "inline",
  className = "",
}) => {
  const currentStreak = streak?.currentStreak ?? 0;
  const longestStreak = streak?.longestStreak ?? 0;

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
        title={`Current streak: ${currentStreak} streak (Max: ${longestStreak})`}
        role="status"
        aria-label={`Current learning streak: ${currentStreak} streak`}
      >
        <span className="streak-pill-icon" aria-hidden="true">
          <svg
            className="lucide-flame-icon"
            xmlns="http://www.w3.org/2000/svg"
            width="16"
            height="16"
            viewBox="0 0 24 24"
            fill="none"
            stroke="#542B32"
            strokeWidth="2"
            strokeLinecap="round"
            strokeLinejoin="round"
          >
            <path d="M8.5 14.5A2.5 2.5 0 0 0 11 12c0-1.38-.5-2-1-3-1.072-2.143-.224-4.054 2-6 .5 2.5 2 4.9 4 6.5 2 1.6 3 3.5 3 5.5a7 7 0 1 1-14 0c0-1.153.433-2.294 1-3a2.5 2.5 0 0 0 2.5 2.5z" />
          </svg>
        </span>
        <span className="streak-pill-count">{currentStreak}</span>
        <span className="streak-pill-label">streak</span>
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
