/**
 * 21st.dev inspired Badge
 * Variants: "burgundy" / "indigo" (primary), "secondary" / "teal", "success", "warning", "neutral"
 */
export const Badge = ({
  children,
  variant = "burgundy",
  size = "md",
  dot = false,
  className = "",
}) => {
  return (
    <span className={`devops-badge devops-badge-${variant} devops-badge-${size} ${className}`}>
      {dot && <span className="devops-badge-dot" aria-hidden="true" />}
      {children}
    </span>
  );
};

export default Badge;
