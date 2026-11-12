import React from "react";
import { createRoot } from "react-dom/client";
import StepAnimation from "./StepAnimation";
import data from "./linux-animations.json";
const subs = data.modules.flatMap((m) => m.subtopics);
window.__subs = subs.map((s) => s.id);
function App() {
  const [id, setId] = React.useState(subs[0].id);
  window.__setId = setId;
  const s = subs.find((x) => x.id === id);
  return <div style={{ width: 1100, margin: 0 }}><StepAnimation animation={s} autoPlay={false} /></div>;
}
createRoot(document.getElementById("root")).render(<App />);
