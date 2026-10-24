/**
 * 21st.dev inspired Button
 * Variants:
 * - "primary": Indigo (#4F46E5)
 * - "secondary": Teal (#0D9488)
 * - "outline": Subtle border with hover glow
 * - "ghost": Minimalist hover state
 */
export const Button = ({
  children,
  type = "button",
  variant = "primary",
  size = "md",
  loading = false,
  disabled = false,
  onClick,
  className = "",
  icon,
  ...props
}) => {
  return (
    <button
      type={type}
      disabled={disabled || loading}
      onClick={onClick}
      className={`devops-btn devops-btn-${variant} devops-btn-${size} ${
        loading ? "devops-btn-loading" : ""
      } ${className}`}
      {...props}
    >
      {loading ? (
        <span className="btn-spinner-wrapper">
          <span className="btn-spinner" aria-hidden="true" />
          <span>Please wait...</span>
        </span>
      ) : (
        <span className="btn-content">
          {icon && <span className="btn-icon">{icon}</span>}
          {children}
        </span>
      )}
    </button>
  );
};

export default Button;
