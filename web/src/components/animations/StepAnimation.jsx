import { useCallback, useEffect, useId, useMemo, useRef, useState } from "react";
import { buildFrames, edgeGeometry, DEFAULT_W, STAGE } from "./stepEngine";
import "./StepAnimation.css";

/* ---------- small renderers ---------- */

function Actor({ a }) {
  const w = a.w ?? DEFAULT_W[a.k];
  const style = {
    left: `${a.x}%`,
    top: `${a.y}%`,
    transitionDelay: a.delay ? `${a.delay}ms` : undefined,
  };
  if (w) style.width = `${w}%`;
  if (a.k === "zone") style.height = `${a.h}%`;
  const cls = ["sa-a", `sa-${a.k}`, `t-${a.tone || (a.k === "zone" ? "soft" : "plain")}`];
  if (a.hide) cls.push("is-hidden");
  if (a.glow) cls.push("is-glow");

  if (a.k === "code") {
    return (
      <div className={cls.join(" ")} style={style}>
        {a.title && <div className="sa-code-bar"><i /><i /><i /><span>{a.title}</span></div>}
        <div className="sa-code-body">
          {a.lines.map((l, i) => {
            const [text, c] = Array.isArray(l) ? l : [l, ""];
            return (
              <div key={`${i}-${text}`} className={`sa-ln ${c}`} style={{ animationDelay: `${i * 70}ms` }}>
                {text || "\u00a0"}
              </div>
            );
          })}
        </div>
      </div>
    );
  }

  return (
    <div className={cls.join(" ")} style={style}>
      {a.k === "zone" ? (
        <span className="sa-zone-label">{a.text}</span>
      ) : (
        <>
          {a.ic && <b className="sa-ic">{a.ic}</b>}
          <span className="sa-text">{a.text}</span>
          {a.sub && <small className="sa-sub">{a.sub}</small>}
          {a.bar != null && <span className="sa-bar"><i style={{ width: `${a.bar}%` }} /></span>}
        </>
      )}
    </div>
  );
}

function Edges({ frame, uid }) {
  if (!frame || !frame.edges || !frame.actors) return null;
  const out = [];
  frame.edges.forEach(([from, to, label, style]) => {
    const a = frame.actors[from], b = frame.actors[to];
    if (!a || !b || a.hide || b.hide) return;
    const g = edgeGeometry(a, b);
    if (!g) return;
    const kind = style || "base";
    out.push(
      <g key={`${from}>${to}`} className={`sa-edge e-${kind}`}>
        <line x1={g.x1} y1={g.y1} x2={g.x2} y2={g.y2} markerEnd={`url(#${uid}-${kind})`} />
        {label ? <text x={g.mx} y={g.my - 7} textAnchor="middle">{label}</text> : null}
      </g>
    );
  });
  const marker = (kind, color) => (
    <marker key={kind} id={`${uid}-${kind}`} viewBox="0 0 10 10" refX="8" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse">
      <path d="M1 1 L9 5 L1 9 z" fill={color} />
    </marker>
  );
  return (
    <svg className="sa-edges" viewBox={`0 0 ${STAGE.w} ${STAGE.h}`} aria-hidden="true">
      <defs>
        {marker("base", "var(--sa-rose)")}
        {marker("dash", "var(--sa-rose)")}
        {marker("ok", "var(--sa-ok)")}
        {marker("warn", "var(--sa-bad)")}
      </defs>
      {out}
    </svg>
  );
}

function Terminal({ frame, step }) {
  const ref = useRef(null);
  useEffect(() => { if (ref.current) ref.current.scrollTop = ref.current.scrollHeight; }, [step]);
  if (!frame || !frame.term) return null;

  let accDelay = 0;
  const lineStyles = frame.term.map((line, idx) => {
    const isNew = idx >= frame.termStart;
    if (!isNew) return null;
    const isCmd = line.startsWith("$ ");
    const ms = isCmd ? Math.min((line.length - 2) * 26, 1500) : 180;
    const style = isCmd
      ? { "--n": line.length - 2, "--d": `${ms}ms`, "--delay": `${accDelay}ms` }
      : { "--delay": `${accDelay}ms` };
    accDelay += ms + 150;
    return style;
  });

  return (
    <div className="sa-term" role="log" aria-label="Terminal">
      <div className="sa-term-bar"><i /><i /><i /><span>terminal</span></div>
      <div className="sa-term-body" ref={ref}>
        {frame.term.map((line, idx) => {
          const isNew = idx >= frame.termStart;
          const isCmd = line.startsWith("$ ");
          const tone = !isCmd && /^[+~!]/.test(line) ? line[0] : "";
          const text = tone ? line.slice(1) : line;
          return (
            <div key={`${idx}-${text}`} className={`sa-tl ${isCmd ? "cmd" : "out"} ${tone ? "tn" + tone : ""} ${isNew ? "new" : ""}`} style={lineStyles[idx] || undefined}>
              {isCmd ? (<><span className="sa-prompt">$</span><span className="sa-typed">{text.slice(2)}</span></>) : text}
            </div>
          );
        })}
      </div>
    </div>
  );
}

/* ---------- player ---------- */

/**
 * <StepAnimation animation={...} />
 *   animation : one subtopic object from git-animations.json  ({ id, title, steps })
 *   autoPlay  : start playing on mount (default false, skipped when the user prefers reduced motion)
 *   stepMs    : base time each step stays on screen (default 3400)
 *   showTitle : show the card header (default true)
 *   onFinish  : callback fired when the animation completes the last step
 */
export default function StepAnimation({
  animation,
  autoPlay = false,
  stepMs = 3400,
  showTitle = true,
  className = "",
  onFinish,
}) {
  const uid = useId().replace(/:/g, "");
  const frames = useMemo(() => buildFrames(animation?.steps || []), [animation?.steps]);
  const hasTerm = frames.some((f) => f.term.length);
  const last = Math.max(0, frames.length - 1);

  const reduced = typeof window !== "undefined" && window.matchMedia?.("(prefers-reduced-motion: reduce)").matches;
  const initialPlay = autoPlay && !reduced;

  const [i, setI] = useState(0);
  const [playing, setPlaying] = useState(initialPlay);
  const [hasStarted, setHasStarted] = useState(initialPlay);
  const [isCompleted, setIsCompleted] = useState(false);
  const finishedFiredRef = useRef(false);

  // If subtopic animation ID changes, reset state during render
  const [prevAnimId, setPrevAnimId] = useState(animation?.id);
  if (animation?.id !== prevAnimId) {
    setPrevAnimId(animation?.id);
    setI(0);
    setPlaying(initialPlay);
    setHasStarted(initialPlay);
    setIsCompleted(false);
  }

  useEffect(() => {
    finishedFiredRef.current = false;
  }, [animation?.id]);

  useEffect(() => {
    if (!playing) return;
    if (i >= last) {
      // Allow viewing the final frame for stepMs before marking playback as completed
      const id = setTimeout(() => {
        setPlaying(false);
        setIsCompleted(true);
      }, stepMs);
      return () => clearTimeout(id);
    }
    const f = frames[i + 1];
    if (!f) return;
    const typing = (f.term.length - f.termStart) * 700; // leave time for typed commands
    const id = setTimeout(() => setI((x) => x + 1), stepMs + typing);
    return () => clearTimeout(id);
  }, [playing, i, last, frames, stepMs]);

  const go = useCallback((n) => {
    setPlaying(false);
    const target = Math.max(0, Math.min(last, n));
    setI(target);
    if (target === 0) {
      setIsCompleted(false);
      setHasStarted(false);
      finishedFiredRef.current = false;
    } else if (target < last) {
      setIsCompleted(false);
      setHasStarted(true);
    }
  }, [last]);

  const togglePlay = () => {
    if (playing) {
      setPlaying(false);
      return;
    }
    if (isCompleted) {
      // Replay: reset to step 0 and start playing again
      setI(0);
      setIsCompleted(false);
      setHasStarted(true);
      setPlaying(true);
      finishedFiredRef.current = false;
      return;
    }
    // Resume or start Play from current step
    if (i >= last) {
      setI(0);
    }
    setHasStarted(true);
    setPlaying(true);
  };

  const safeI = Math.max(0, Math.min(last, i));
  const frame = frames[safeI] || frames[0] || { actors: {}, edges: [], term: [], say: "" };

  const onKey = (e) => {
    if (e.key === "ArrowRight") go(safeI + 1);
    if (e.key === "ArrowLeft") go(safeI - 1);
    if (e.key === " ") { e.preventDefault(); togglePlay(); }
  };

  // Trigger onFinish when playback genuinely completes
  useEffect(() => {
    if (isCompleted && !finishedFiredRef.current) {
      finishedFiredRef.current = true;
      if (typeof onFinish === "function") {
        onFinish();
      }
    }
  }, [isCompleted, onFinish]);

  const getPlayButtonContent = () => {
    if (playing) {
      return { text: "Ⅱ Pause", label: "Pause" };
    }
    if (isCompleted) {
      return { text: "↻ Replay", label: "Replay" };
    }
    if (hasStarted && safeI > 0) {
      return { text: "▶ Resume", label: "Resume" };
    }
    return { text: "▶ Play", label: "Play" };
  };

  const { text: playBtnText, label: playBtnLabel } = getPlayButtonContent();

  return (
    <section className={`sa ${className}`} tabIndex={0} onKeyDown={onKey} aria-label={`Animation: ${animation?.title || "Step Animation"}`}>
      {showTitle && (
        <header className="sa-head">
          <div>
            <span className="sa-chip"><i /> Animation</span>
            <h3>{animation?.title}</h3>
          </div>
          <span className="sa-count">Step {safeI + 1} <em>/ {frames.length}</em></span>
        </header>
      )}

      <div className="sa-scroll">
        <div className="sa-stage">
          <Edges frame={frame} uid={uid} />
          {Object.entries(frame.actors).map(([id, a]) => <Actor key={id} a={a} />)}
        </div>
      </div>

      {hasTerm && <Terminal frame={frame} step={safeI} />}

      <p className="sa-say" aria-live="polite" key={safeI}>{frame.say}</p>

      <footer className="sa-ctrl">
        <button onClick={() => go(0)} aria-label="Restart" title="Restart">↺</button>
        <button onClick={() => go(safeI - 1)} disabled={safeI === 0} aria-label="Previous step">‹</button>
        <button className="primary" onClick={togglePlay} aria-label={playBtnLabel}>{playBtnText}</button>
        <button onClick={() => go(safeI + 1)} disabled={safeI === last} aria-label="Next step">›</button>
        <div className="sa-dots">
          {frames.map((_, n) => (
            <button key={n} className={n === safeI ? "on" : n < safeI ? "done" : ""} onClick={() => go(n)} aria-label={`Go to step ${n + 1}`} />
          ))}
        </div>
      </footer>
    </section>
  );
}
