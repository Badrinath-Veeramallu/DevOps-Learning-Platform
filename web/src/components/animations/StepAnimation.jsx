import { useCallback, useEffect, useId, useMemo, useRef, useState } from "react";
import { buildFrames, edgeGeometry, DEFAULT_W, DEFAULT_W_MOBILE, STAGE } from "./stepEngine";
import "./StepAnimation.css";

/* ---------- small renderers ---------- */

function Actor({ a, compact }) {
  const w = a.w ?? (compact ? DEFAULT_W_MOBILE : DEFAULT_W)[a.k];
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
  if (compact && a.k === "commit") cls.push(`side-${a.side || "r"}`);

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

function Edges({ frame, uid, stage }) {
  if (!frame || !frame.edges || !frame.actors) return null;
  const out = [];
  frame.edges.forEach(([from, to, label, style]) => {
    const a = frame.actors[from], b = frame.actors[to];
    if (!a || !b || a.hide || b.hide) return;
    const g = edgeGeometry(a, b, stage);
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
    <svg className="sa-edges" viewBox={`0 0 ${stage.w} ${stage.h}`} aria-hidden="true">
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

function getTerminalLines(term, termStart) {
  let delay = 0;
  return term.map((line, i) => {
    const isNew = i >= termStart;
    const isCmd = line.startsWith("$ ");
    const tone = !isCmd && /^[+~!]/.test(line) ? line[0] : "";
    const text = tone ? line.slice(1) : line;
    let style;
    if (isNew) {
      const ms = isCmd ? Math.min(text.length * 26, 1500) : 180;
      style = isCmd
        ? { "--n": text.length - 2, "--d": `${ms}ms`, "--delay": `${delay}ms` }
        : { "--delay": `${delay}ms` };
      delay += ms + 150;
    }
    return { key: `${i}-${text}`, isCmd, tone, isNew, text, style };
  });
}

function Terminal({ frame, step }) {
  const ref = useRef(null);
  useEffect(() => { if (ref.current) ref.current.scrollTop = ref.current.scrollHeight; }, [step]);
  if (!frame || !frame.term) return null;

  const renderedLines = getTerminalLines(frame.term, frame.termStart);

  return (
    <div className="sa-term" role="log" aria-label="Terminal">
      <div className="sa-term-bar"><i /><i /><i /><span>terminal</span></div>
      <div className="sa-term-body" ref={ref}>
        {renderedLines.map((l) => (
          <div key={l.key} className={`sa-tl ${l.isCmd ? "cmd" : "out"} ${l.tone ? "tn" + l.tone : ""} ${l.isNew ? "new" : ""}`} style={l.style}>
            {l.isCmd ? (<><span className="sa-prompt">$</span><span className="sa-typed">{l.text.slice(2)}</span></>) : l.text}
          </div>
        ))}
      </div>
    </div>
  );
}

/* ---------- player ---------- */

/** true while the component is narrower than `breakpoint` px (container-based, so it also works in narrow side panels) */
function useCompact(ref, breakpoint) {
  const [compact, setCompact] = useState(false);
  useEffect(() => {
    const el = ref.current;
    if (!el) return;
    const measure = () => setCompact(el.getBoundingClientRect().width < breakpoint);
    measure();
    if (typeof ResizeObserver === "undefined") { window.addEventListener("resize", measure); return () => window.removeEventListener("resize", measure); }
    const ro = new ResizeObserver(measure);
    ro.observe(el);
    return () => ro.disconnect();
  }, [ref, breakpoint]);
  return compact;
}

/**
/**
 * <StepAnimation animation={...} mobileAnimation={...} />
 *   animation       : one subtopic object ({ id, title, steps })
 *   mobileAnimation : the same subtopic for portrait/compact layout (optional)
 *   autoPlay        : start playing on mount (default false, skipped when the user prefers reduced motion)
 *   stepMs          : base time each step stays on screen (default 3400)
 *   showTitle       : show the card header (default true)
 *   breakpoint      : below this width (px) the phone layout is used (default 640)
 *   onFinish        : callback fired when the animation completes the last step
 */
export default function StepAnimation({
  animation,
  mobileAnimation,
  autoPlay = false,
  stepMs = 3400,
  showTitle = true,
  className = "",
  breakpoint = 640,
  onFinish,
}) {
  const uid = useId().replace(/:/g, "");
  const root = useRef(null);
  const compactWidth = useCompact(root, breakpoint);
  const compact = compactWidth && !!mobileAnimation;
  const active = compact ? mobileAnimation : animation;
  const stage = active?.stage || STAGE;

  const frames = useMemo(() => buildFrames(active?.steps || []), [active?.steps]);
  const hasTerm = frames.some((f) => f.term.length);
  const last = Math.max(0, frames.length - 1);

  const reduced = typeof window !== "undefined" && window.matchMedia?.("(prefers-reduced-motion: reduce)").matches;
  const initialPlay = autoPlay && !reduced;

  const [i, setI] = useState(0);
  const [playing, setPlaying] = useState(initialPlay);
  const [hasStarted, setHasStarted] = useState(initialPlay);
  const [isCompleted, setIsCompleted] = useState(false);
  const finishedFiredRef = useRef(false);

  // If subtopic animation ID changes, restart
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

  const safeI = Math.max(0, Math.min(last, i));
  const isAtEnd = (last > 0 && safeI >= last) || isCompleted;
  const frame = frames[safeI] || frames[0] || { actors: {}, edges: [], term: [], say: "" };

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
      finishedFiredRef.current = false;
    }
  }, [last]);

  const togglePlay = () => {
    if (playing) {
      setPlaying(false);
      return;
    }
    if (isAtEnd) {
      // Replay: reset to step 0 and start playing again
      setI(0);
      setIsCompleted(false);
      setHasStarted(true);
      setPlaying(true);
      finishedFiredRef.current = false;
      return;
    }
    if (safeI >= last) {
      setI(0);
    }
    setHasStarted(true);
    setPlaying(true);
  };

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
      return { text: "❚❚ Pause", label: "Pause" };
    }
    if (isAtEnd) {
      return { text: "↻ Replay", label: "Replay" };
    }
    if (hasStarted && safeI > 0) {
      return { text: "▶ Resume", label: "Resume" };
    }
    return { text: "▶ Play", label: "Play" };
  };

  const { text: playBtnText, label: playBtnLabel } = getPlayButtonContent();

  // swipe left / right on the stage = next / previous step (vertical scrolling is left alone)
  const touch = useRef(null);
  const onTouchStart = (e) => { const t = e.touches[0]; touch.current = [t.clientX, t.clientY]; };
  const onTouchEnd = (e) => {
    if (!touch.current) return;
    const t = e.changedTouches[0];
    const dx = t.clientX - touch.current[0], dy = t.clientY - touch.current[1];
    touch.current = null;
    if (Math.abs(dx) > 50 && Math.abs(dx) > Math.abs(dy) * 1.5) go(safeI + (dx < 0 ? 1 : -1));
  };

  return (
    <section ref={root} className={`sa ${compact ? "is-compact" : ""} ${className}`} tabIndex={0} onKeyDown={onKey} aria-label={`Animation: ${animation?.title || "Step Animation"}`}>
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
        <div className="sa-stage" style={{ aspectRatio: `${stage.w} / ${stage.h}` }} onTouchStart={onTouchStart} onTouchEnd={onTouchEnd}>
          <Edges frame={frame} uid={uid} stage={stage} />
          {Object.entries(frame.actors).map(([id, a]) => <Actor key={id} a={a} compact={compact} />)}
        </div>
      </div>

      {hasTerm && <Terminal frame={frame} step={safeI} />}

      <div className="sa-dock">
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
      </div>
    </section>
  );
}
