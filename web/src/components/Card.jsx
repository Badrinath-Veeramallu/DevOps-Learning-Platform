/**
 * 21st.dev inspired Card
 * Elevated glassmorphic container with subtle border highlights and hover depth
 */
export const Card = ({
  children,
  className = "",
  hoverable = false,
  glow = false,
  onClick,
}) => {
  return (
    <div
      onClick={onClick}
      className={`devops-card ${hoverable ? "devops-card-hover" : ""} ${
        glow ? "devops-card-glow" : ""
      } ${className}`}
    >
      {children}
    </div>
  );
};

export default Card;
