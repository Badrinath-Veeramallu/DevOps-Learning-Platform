// Tiny DSL for writing animations. Every helper returns a plain actor object (same shape as the Git / Docker JSON).
const opt = (o, extra) => { for (const k in extra) if (extra[k] !== undefined && extra[k] !== null && extra[k] !== '') o[k] = extra[k]; return o; };
exports.Z = (text, x, y, w, h, tone) => opt({ k: 'zone', text, x, y, w, h }, { tone });
exports.F = (text, x, y, tone, sub, w) => opt({ k: 'file', text, x, y }, { tone, sub, w });
exports.B = (text, x, y, tone, sub, w) => opt({ k: 'box', text, x, y }, { tone, sub, w });
exports.P = (text, x, y, tone, ic) => opt({ k: 'pill', text, x, y }, { tone, ic });
exports.C = (text, x, y, tone, sub, w) => opt({ k: 'commit', text, x, y }, { tone, sub, w });
exports.V = (text, x, y, tone, sub, w) => opt({ k: 'vol', text, x, y }, { tone, sub, w });
exports.L = (text, x, y, tone, sub, w) => opt({ k: 'layer', text, x, y }, { tone, sub, w });
exports.K = (title, lines, x, y, w) => opt({ k: 'code', title, lines, x, y }, { w });
// step: caption, actor patches, and optional { edges, term, clear }
exports.S = (say, actors, extra = {}) => ({ say, actors, ...extra });
