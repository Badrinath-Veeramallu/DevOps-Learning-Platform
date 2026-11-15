import { useMemo } from "react";
import desktopData from "./cicd-animations.json";
import mobileData from "./cicd-animations.mobile.json";
import StepAnimation from "./StepAnimation";
import { findAnimation } from "./stepEngine";

/**
 * Drop-in for CI/CD lesson pages (desktop + phone layouts are chosen automatically by width):
 *   <CicdAnimation id="06.7" />
 *   <CicdAnimation id="Synchronization and Drift Detection" />   // title match also works
 */
export default function CicdAnimation({ id, fallbackTitle, onFinish, ...props }) {
  const animation = useMemo(() => {
    if (!desktopData) return null;
    let match = findAnimation(desktopData, id);
    if (!match && fallbackTitle) {
      match = findAnimation(desktopData, fallbackTitle);
    }
    return match;
  }, [id, fallbackTitle]);

  const mobileAnimation = useMemo(() => {
    if (!mobileData) return null;
    let match = findAnimation(mobileData, id);
    if (!match && fallbackTitle) {
      match = findAnimation(mobileData, fallbackTitle);
    }
    return match;
  }, [id, fallbackTitle]);

  if (!animation) return null;
  return (
    <StepAnimation
      key={animation.id}
      animation={animation}
      mobileAnimation={mobileAnimation}
      onFinish={onFinish}
      {...props}
    />
  );
}
