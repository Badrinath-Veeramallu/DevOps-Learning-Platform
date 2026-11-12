import json, sys, os
from playwright.sync_api import sync_playwright
os.environ.setdefault('PLAYWRIGHT_BROWSERS_PATH','/opt/pw-browsers')
W = int(sys.argv[1]) if len(sys.argv)>1 else 1100
only = sys.argv[2] if len(sys.argv)>2 else None
JS = """
() => {
  const stage = document.querySelector('.sa-stage').getBoundingClientRect();
  const out = [];
  const els = [...document.querySelectorAll('.sa-a')].filter(e => !e.classList.contains('is-hidden'));
  const info = els.map(e => {
    const r = e.getBoundingClientRect();
    const t = e.querySelector('.sa-text');
    return { id: (t ? t.textContent : e.textContent).slice(0,24), k: [...e.classList].find(c=>/^sa-(file|box|pill|commit|zone|code|vol|layer)$/.test(c)).slice(3), r: {l:r.left-stage.left,t:r.top-stage.top,r:r.right-stage.left,b:r.bottom-stage.top}, el: e };
  });
  const P = 1;
  for (const a of info) {
    if (a.r.l < -P || a.r.t < -P || a.r.r > stage.width+P || a.r.b > stage.height+P) out.push(['OUT-OF-STAGE', a.k, a.id]);
    // text clipped inside shape
    for (const n of a.el.querySelectorAll('.sa-text,.sa-sub,.sa-ln')) if (n.scrollWidth > n.clientWidth + 2 && getComputedStyle(n).display!=='inline') out.push(['TEXT-CLIP', a.k, a.id]);
    if (a.k==='file') { const t=a.el.querySelector('.sa-text'); const s=a.el.querySelector('.sa-sub'); }
  }
  // overlaps between non-zone actors (zones are containers)
  for (let i=0;i<info.length;i++) for (let j=i+1;j<info.length;j++) {
    const a=info[i], b=info[j];
    if (a.k==='zone'||b.k==='zone') continue;
    const ox = Math.min(a.r.r,b.r.r)-Math.max(a.r.l,b.r.l), oy = Math.min(a.r.b,b.r.b)-Math.max(a.r.t,b.r.t);
    if (ox>3 && oy>3) out.push(['OVERLAP', a.k+':'+a.id, b.k+':'+b.id]);
  }
  // commit subtitles (absolutely positioned below circle) vs other actors
  for (const a of info) if (a.k==='commit') { const s=a.el.querySelector('.sa-sub'); if(!s) continue; const r=s.getBoundingClientRect(); const sr={l:r.left-stage.left,t:r.top-stage.top,r:r.right-stage.left,b:r.bottom-stage.top};
    if (sr.b>stage.height||sr.r>stage.width||sr.l<0) out.push(['SUB-OUT', a.id]);
    for (const b of info) if (b!==a && b.k!=='zone') { const ox=Math.min(sr.r,b.r.r)-Math.max(sr.l,b.r.l), oy=Math.min(sr.b,b.r.b)-Math.max(sr.t,b.r.t); if(ox>3&&oy>3) out.push(['SUB-OVERLAP',a.id,b.k+':'+b.id]); } }
  // actors poking out of their zone? (non-zone actor partially inside a zone)
  const zones = info.filter(a=>a.k==='zone');
  for (const a of info) if (a.k!=='zone') for (const z of zones) {
    const ox=Math.min(a.r.r,z.r.r)-Math.max(a.r.l,z.r.l), oy=Math.min(a.r.b,z.r.b)-Math.max(a.r.t,z.r.t);
    const area=(a.r.r-a.r.l)*(a.r.b-a.r.t);
    if (ox>0&&oy>0 && ox*oy>0.1*area && ox*oy<0.97*area) out.push(['STRADDLES-ZONE', a.k+':'+a.id, z.id]);
  }
  // terminal
  const term = document.querySelector('.sa-term-body');
  // edge labels over actors
  document.querySelectorAll('.sa-edge text').forEach(tx => { const r=tx.getBoundingClientRect(); const tr={l:r.left-stage.left,t:r.top-stage.top,r:r.right-stage.left,b:r.bottom-stage.top};
    for (const b of info) if (b.k!=='zone') { const ox=Math.min(tr.r,b.r.r)-Math.max(tr.l,b.r.l), oy=Math.min(tr.b,b.r.b)-Math.max(tr.t,b.r.t); if(ox>2&&oy>2) out.push(['LABEL-OVER', tx.textContent, b.k+':'+b.id]); }
    if (tr.l<0||tr.r>stage.width) out.push(['LABEL-OUT', tx.textContent]); });
  // edge lines crossing foreign actors
  document.querySelectorAll('.sa-edge line').forEach(ln => { const x1=+ln.getAttribute('x1'),y1=+ln.getAttribute('y1'),x2=+ln.getAttribute('x2'),y2=+ln.getAttribute('y2'); const sx=stage.width/1000, sy=stage.height/400;
    for (const b of info) if (b.k!=='zone') { for (let t=0.08;t<=0.92;t+=0.04){ const px=(x1+(x2-x1)*t)*sx, py=(y1+(y2-y1)*t)*sy; if(px>b.r.l+2&&px<b.r.r-2&&py>b.r.t+2&&py<b.r.b-2){ out.push(['EDGE-CROSSES', b.k+':'+b.id]); break; } } } });
  return out;
}
"""
with sync_playwright() as p:
    br = p.chromium.launch()
    pg = br.new_page(viewport={'width': W, 'height': 900})
    pg.goto('file:///home/claude/linux/test/index.html')
    pg.add_style_tag(content='*,*::before,*::after{transition:none!important;animation:none!important}')
    ids = pg.evaluate('window.__subs')
    total = 0
    for sid in ids:
        if only and sid != only: continue
        pg.evaluate(f'window.__setId("{sid}")'); pg.wait_for_timeout(80)
        n = len(pg.query_selector_all('.sa-dots button'))
        pg.click('.sa-ctrl button[aria-label="Restart"]')
        for i in range(n):
            pg.wait_for_timeout(40)
            issues = pg.evaluate(JS)
            seen = set()
            for it in issues:
                key = tuple(it)
                if key in seen: continue
                seen.add(key); total += 1
                print(f'{sid} step {i+1}: {" | ".join(it)}')
            if i < n-1: pg.click('.sa-ctrl button[aria-label="Next step"]')
    print('TOTAL issues', total)
    br.close()
