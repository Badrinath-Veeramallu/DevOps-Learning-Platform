import React from "react";

/**
 * Dedicated Animation Placeholder for CI/CD Subtopics.
 *
 * Reserves dedicated vertical space for future interactive step-by-step
 * animations while remaining visually clean, responsive, and identifiable.
 */
export const CicdAnimationPlaceholder = ({ id }) => {
  return (
    <div
      id={id}
      className="cicd-animation-placeholder"
      data-animation-id={id}
      aria-hidden="true"
    />
  );
};

export default CicdAnimationPlaceholder;
