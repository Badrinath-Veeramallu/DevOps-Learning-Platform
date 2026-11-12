import fs from 'fs';
import { buildFrames, edgeGeometry } from './stepEngine.mjs';
const d = JSON.parse(fs.readFileSync('linux-animations.json'));
let bad = 0, total = 0;
for (const m of d.modules) for (const s of m.subtopics) {
  const frames = buildFrames(s.steps);
  frames.forEach((f, i) => f.edges.forEach(([a, b, l, st]) => {
    const A = f.actors[a], B = f.actors[b];
    if (!A || !B) { console.log(s.id, 'step', i + 1, 'edge refers to unknown actor', a, b); bad++; return; }
    if (A.hide || B.hide) return;
    total++;
    if (!edgeGeometry(A, B)) { console.log(s.id, 'step', i + 1, 'edge not drawn (shapes too close):', a, '->', b); bad++; }
  }));
}
console.log('edges checked', total, 'problems', bad);
