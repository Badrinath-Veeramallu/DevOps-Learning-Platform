/**
 * 21st.dev inspired ProgressBar
 * Features a Teal (#0D9488) to Indigo (#4F46E5) gradient track
 */
export const ProgressBar = ({
  progress = 0,
  max = 100,
  label,
  showValue = true,
  className = "",
}) => {
  const percentage = Math.min(100, Math.max(0, Math.round((progress / max) * 100)));

  return (
    <div className={`devops-progress-wrapper ${className}`}>
      {(label || showValue) && (
        <div className="progress-header">
          {label && <span className="progress-label">{label}</span>}
          {showValue && <span className="progress-value">{percentage}%</span>}
        </div>
      )}
      <div
        className="progress-track"
        role="progressbar"
        aria-valuenow={percentage}
        aria-valuemin={0}
        aria-valuemax={100}
      >
        <div
          className="progress-fill"
          style={{ width: `${percentage}%` }}
        />
      </div>
    </div>
  );
};

export default ProgressBar;
