/**
 * 21st.dev inspired BackgroundGrid
 * Subtle developer grid with Deep Burgundy radial glow
 */
export const BackgroundGrid = ({ children, className = "" }) => {
  return (
    <div className={`grid-background-wrapper ${className}`}>
      <div className="grid-overlay" aria-hidden="true" />
      <div className="radial-glow-primary" aria-hidden="true" />
      <div className="radial-glow-secondary" aria-hidden="true" />
      <div className="grid-content">{children}</div>
    </div>
  );
};

export default BackgroundGrid;
