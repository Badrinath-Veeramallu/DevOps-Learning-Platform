import { useMemo } from "react";
import data from "./linux-animations.json";
import StepAnimation from "./StepAnimation";
import { findAnimation } from "./stepEngine";

/**
 * Drop-in for Linux lesson pages:
 *   <LinuxAnimation id="01.1" onFinish={...} />
 *   <LinuxAnimation id="Introduction to Linux" /> // title match also works
 */
export default function LinuxAnimation({ id, fallbackTitle, onFinish, ...props }) {
  const animation = useMemo(() => {
    if (!data || !Array.isArray(data.modules)) return null;
    let match = findAnimation(data, id);
    if (!match && fallbackTitle) {
      match = findAnimation(data, fallbackTitle);
    }
    return match;
  }, [id, fallbackTitle]);

  if (!animation) return null;
  return <StepAnimation key={animation.id} animation={animation} onFinish={onFinish} {...props} />;
}

