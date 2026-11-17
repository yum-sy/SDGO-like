"""Reproducible Godot export + offline PWA, no external runtime CDN."""
import argparse, hashlib, json, os, struct, subprocess, zlib
from pathlib import Path
root = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument('--godot', default=os.environ.get('GODOT_BIN', str(root.parent / '.tools/Godot.app/Contents/MacOS/Godot')))
args = parser.parse_args()
dist = root / 'dist'
dist.mkdir(exist_ok=True)
(dist/'.gdignore').touch()
for old in dist.glob('*.import'): old.unlink()
subprocess.run([args.godot,'--headless','--path',str(root),'--export-release','Web'],check=True)
html = (dist/'index.html').read_text()
html = html.replace('"serviceWorker":"index.service.worker.js"','"serviceWorker":""')
html = html.replace('src="index.png" alt=""','src="index.png" alt="니세 건담 — SDGO-like"')
html = html.replace("'onProgress': function (current, total) {", """'onProgress': function (current, total) {
 document.getElementById('status').setAttribute('data-loading-label', total <= 0 ? '게임 데이터 준비 중…' : current < total ? '게임 데이터 준비 ' + Math.floor(current/total*100) + '% · 첫 실행은 시간이 걸릴 수 있습니다' : '다운로드 완료 · 엔진과 3D 기체 준비 중');""")
html = html.replace('<div id="status">','<div id="status" data-loading-label="게임 시작 준비 중…">')
html = html.replace('</head>', '<meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover,user-scalable=no"><meta name="theme-color" content="#172537"></head>')
html = html.replace('</body>',(root/'web/overlay.html').read_text()+'</body>')
(dist/'index.html').write_text(html.rstrip()+'\n')
for name in ('showcase.html','showcase-preview.jpg'):
    source=root/'web'/name
    if source.exists(): (dist/name).write_bytes(source.read_bytes())
(dist/'app.js').write_text((root/'web/app.js').read_text())
(dist/'lifecycle.js').write_text((root/'web/lifecycle.js').read_text())
(dist/'install.js').write_text((root/'web/install.js').read_text())
(dist/'CREDITS.txt').write_text((root/'CREDITS.txt').read_text())
(dist/'.nojekyll').touch()
# Pre-rendered Nise Gundam artwork; runtime/export needs no imaging dependency.
brand = root/'web/branding'
for size in (144,180,192,512):
    (dist/f'index.{size}x{size}.png').write_bytes((brand/f'nise-{size}.png').read_bytes())
(dist/'index.apple-touch-icon.png').write_bytes((brand/'nise-180.png').read_bytes())
(dist/'index.icon.png').write_bytes((brand/'nise-32.png').read_bytes())
(dist/'index.png').write_bytes((brand/'nise-512.png').read_bytes())
(dist/'index.maskable-512.png').write_bytes((brand/'nise-maskable-512.png').read_bytes())
manifest=json.loads((dist/'index.manifest.json').read_text())
manifest['icons']=[{'src':'index.192x192.png','sizes':'192x192','type':'image/png','purpose':'any'},{'src':'index.512x512.png','sizes':'512x512','type':'image/png','purpose':'any'}]
manifest['icons'].append({'src':'index.maskable-512.png','sizes':'512x512','type':'image/png','purpose':'maskable'})
manifest.update(name='SDGO-like',short_name='SDGO-like',id='./',scope='./',start_url='./index.html',description='RX78 vs Zaku · 3D action fan demo',theme_color='#172537')
(dist/'index.manifest.json').write_text(json.dumps(manifest))
assets=sorted(p.name for p in dist.iterdir() if p.is_file() and p.name not in ('index.service.worker.js','.DS_Store','.gdignore','.nojekyll'))
hash_value=hashlib.sha256(b'precache-reload-v2'+b''.join((dist/n).read_bytes() for n in assets)).hexdigest()[:16]
worker='''const CACHE="sdgo-like-__VERSION__";
const FILES=__FILES__;
self.addEventListener('install',e=>e.waitUntil(caches.open(CACHE).then(c=>c.addAll(FILES.map(file=>new Request(file,{cache:'reload'}))))));
self.addEventListener('activate',e=>e.waitUntil(Promise.all([caches.keys().then(keys=>Promise.all(keys.filter(k=>k.startsWith('sdgo-like-')&&k!==CACHE).map(k=>caches.delete(k)))),self.clients.claim()])));
self.addEventListener('message',e=>{if(e.data?.type==='SKIP_WAITING')self.skipWaiting();});
self.addEventListener('fetch',e=>{
 if(e.request.method!=='GET'||new URL(e.request.url).origin!==self.location.origin)return;
 e.respondWith(caches.open(CACHE).then(async c=>{
   const cached=await c.match(e.request,{ignoreSearch:true});
   if(cached)return cached;
   if(e.request.mode==='navigate')return (await c.match('index.html'))||fetch(e.request);
   return fetch(e.request);
 }));
});
'''.replace('__VERSION__',hash_value).replace('__FILES__',json.dumps(assets))
(dist/'index.service.worker.js').write_text(worker)
print('PWA VERSION',hash_value,'FILES',len(assets),'BYTES',sum(p.stat().st_size for p in dist.iterdir() if p.is_file()))
