import { useEffect, useRef, useState } from "react";
import { usePrefersReducedMotion } from "./usePrefersReducedMotion";

/**
 * RevealSection — Lightweight viewport entrance animation wrapper.
 * Automatically renders immediately visible when IntersectionObserver is unavailable
 * or when `prefers-reduced-motion: reduce` is enabled.
 */
export const RevealSection = ({
  children,
  className = "",
  as: Tag = "div",
  delayMs = 0,
}) => {
  const ref = useRef(null);
  const prefersReduced = usePrefersReducedMotion();
  const [isVisible, setIsVisible] = useState(() => {
    if (typeof window === "undefined") return true;
    return !("IntersectionObserver" in window);
  });

  useEffect(() => {
    if (prefersReduced || isVisible) return undefined;
    const node = ref.current;
    if (!node || !("IntersectionObserver" in window)) return undefined;

    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            setIsVisible(true);
            observer.unobserve(entry.target);
          }
        });
      },
      { threshold: 0.12, rootMargin: "0px 0px -40px 0px" }
    );

    observer.observe(node);
    return () => observer.disconnect();
  }, [prefersReduced, isVisible]);

  const revealed = prefersReduced || isVisible;

  return (
    <Tag
      ref={ref}
      className={`hp-reveal ${revealed ? "hp-reveal-visible" : ""} ${className}`}
      style={delayMs > 0 ? { transitionDelay: `${delayMs}ms` } : undefined}
    >
      {children}
    </Tag>
  );
};

export default RevealSection;
