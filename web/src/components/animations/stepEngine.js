// stepEngine.js — pure logic (no React). Turns a list of "steps" into renderable frames.
//
// A step only describes what CHANGES. Actors (files, commits, boxes, pills, code panels,
// zones) are created the first time they appear, then moved / re-coloured / hidden by later
// steps. The player renders every actor once and lets CSS transitions animate the changes.

export const STAGE = { w: 1000, h: 400 }; // coordinate space used for edges (actors use % of stage)

export const DEFAULT_W = { file: 10, commit: 6, pill: 0, box: 16, code: 30, note: 0, zone: 30, vol: 12, layer: 24 };
// phone layout: widths are % of a 360px-wide canvas
export const DEFAULT_W_MOBILE = { file: 22, commit: 13, pill: 0, box: 36, code: 94, note: 0, zone: 30, vol: 26, layer: 60 };
const HALF_H = { file: 28, commit: 26, pill: 13, box: 26, note: 10, vol: 32, layer: 15 };

/** frames[i] = { actors, edges, term, termStart, say } — the complete scene at step i */
export function buildFrames(steps) {
  const first = {};
  steps.forEach((s) =>
    Object.entries(s.actors || {}).forEach(([id, p]) => {
      if (p && !first[id]) first[id] = p;
    })
  );

  let cur = {};
  let edges = [];
  let term = [];

  return steps.map((s) => {
    const patch = s.actors || {};
    const next = {};
    for (const id in first) {
      const prev = cur[id];
      const p = patch[id];
      if (p === undefined) next[id] = prev ? { ...prev, delay: 0 } : { ...first[id], hide: true, delay: 0 };
      else if (p === null) next[id] = { ...(prev || first[id]), hide: true, delay: 0 };
      else next[id] = { ...(prev || first[id]), ...p, hide: false, delay: p.delay || 0 };
    }
    cur = next;
    if (s.edges) edges = s.edges;
    if (s.clear) term = [];
    const added = s.term || [];
    const termStart = term.length;
    term = [...term, ...added];
    return { actors: next, edges, term, termStart, say: s.say };
  });
}

function halfSize(a, stage) {
  const mobile = stage.w < 600;
  if (mobile) {
    const wp = ((a.w ?? DEFAULT_W_MOBILE[a.k]) * stage.w) / 100;
    if (a.k === "pill" || a.k === "note") {
      const full = String(a.text).length * 6.2 + 24;
      const w = a.w ? wp : Math.min(full, stage.w * 0.9);
      const n = Math.max(1, Math.ceil((String(a.text).length * 6.2) / Math.max(20, w - 24)));
      return [w / 2, (n * 13 + 10) / 2];
    }
    if (a.k === "code") return [wp / 2, ((a.lines || []).length * 14 + 40) / 2];
    if (a.k === "commit") return [wp / 2, wp / 2];
    return [wp / 2, a.k === "file" ? 24 : a.k === "layer" ? 12 : a.k === "vol" ? 30 : 27];
  }
  const w = a.w ?? DEFAULT_W[a.k];
  if (a.k === "pill" || a.k === "note") return [(String(a.text).length * 7.2 + 30) / 2, HALF_H.pill];
  if (a.k === "code") return [w * 5, ((a.lines || []).length * 5 + 12) * 2];
  return [w * 5, HALF_H[a.k] || 26];
}

/** Line between two actors, trimmed so arrows stop at the actors' borders (viewBox units). */
export function edgeGeometry(a, b, stage = STAGE) {
  const sx = stage.w / 100, sy = stage.h / 100;
  const ax = a.x * sx, ay = a.y * sy, bx = b.x * sx, by = b.y * sy;
  const dx = bx - ax, dy = by - ay;
  const len = Math.hypot(dx, dy);
  if (!len) return null;
  const t = (h) => Math.min(dx ? h[0] / Math.abs(dx) : Infinity, dy ? h[1] / Math.abs(dy) : Infinity);
  const ta = t(halfSize(a, stage)), tb = t(halfSize(b, stage));
  if (ta + tb >= 0.98) return null; // actors touch: no room for a line
  const ux = dx / len, uy = dy / len, gap = stage.w < 600 ? 3 : 5;
  return {
    x1: ax + dx * ta + ux * gap, y1: ay + dy * ta + uy * gap,
    x2: bx - dx * tb - ux * gap, y2: by - dy * tb - uy * gap,
    mx: (ax + bx) / 2, my: (ay + by) / 2,
  };
}

/** Look an animation up by id ("04.5"), by "module.subtopic" numbers, or by (normalised) title. */
export function findAnimation(data, key) {
  const norm = (t) => String(t).toLowerCase().replace(/[^a-z0-9]+/g, ' ').trim();
  for (const m of data.modules)
    for (const s of m.subtopics) {
      if (s.id === key || norm(s.title) === norm(key)) return { ...s, moduleId: m.id, moduleTitle: m.title };
    }
  return null;
}
