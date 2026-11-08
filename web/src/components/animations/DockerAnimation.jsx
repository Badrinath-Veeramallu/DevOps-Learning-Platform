import { useMemo } from "react";
import data from "./docker-animations.json";
import StepAnimation from "./StepAnimation";
import { findAnimation } from "./stepEngine";

/**
 * Drop-in for Docker lesson pages:
 *   <DockerAnimation id="01.1" onFinish={...} />
 *   <DockerAnimation id="Understand Docker Architecture" /> // title match also works
 */
export default function DockerAnimation({ id, fallbackTitle, onFinish, ...props }) {
  const animation = useMemo(() => {
    if (!data) return null;
    let match = findAnimation(data, id);
    if (!match && fallbackTitle) {
      match = findAnimation(data, fallbackTitle);
    }
    return match;
  }, [id, fallbackTitle]);

  if (!animation) return null;
  return <StepAnimation key={animation.id} animation={animation} onFinish={onFinish} {...props} />;
}

