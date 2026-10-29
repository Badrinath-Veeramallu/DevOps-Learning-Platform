import { useMemo } from "react";
import data from "./git-animations.json";
import StepAnimation from "./StepAnimation";
import { findAnimation } from "./stepEngine";

/**
 * Drop-in for your lesson page:
 *   <GitAnimation id="04.5" />
 *   <GitAnimation id="Understand Merge Conflicts" />   // title match also works
 */
export default function GitAnimation({ id, fallbackTitle, ...props }) {
  const animation = useMemo(() => {
    if (!data) return null;
    let match = findAnimation(data, id);
    if (!match && fallbackTitle) {
      match = findAnimation(data, fallbackTitle);
    }
    return match;
  }, [id, fallbackTitle]);

  if (!animation) return null;
  return <StepAnimation key={animation.id} animation={animation} {...props} />;
}
