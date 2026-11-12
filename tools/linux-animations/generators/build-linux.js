// node build-linux.js  ->  ../linux-animations.json (desktop / landscape layout, same schema as git-animations.json)
const fs = require('fs'), path = require('path');
const mods = ['m1', 'm2', 'm3', 'm4', 'm5', 'm6'].map((f) => require('./' + f));
const out = {
  course: 'Linux Essentials', version: 1, stage: { width: 1000, height: 400 },
  modules: mods.map((m) => ({ id: m.id, title: m.title, subtopics: m.subs.map((s) => ({ id: s.id, title: s.title, steps: s.steps })) })),
};
fs.writeFileSync(path.join(__dirname, '..', 'linux-animations.json'), JSON.stringify(out, null, 1));
const subs = out.modules.flatMap((m) => m.subtopics);
console.log(`${out.modules.length} modules, ${subs.length} subtopics, ${subs.reduce((a, s) => a + s.steps.length, 0)} steps`);
