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
html = html.replace('</head>', '<meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover,user-scalable=no"><meta name="theme-color" content="#172537"></head>')
html = html.replace('</body>',(root/'web/overlay.html').read_text()+'</body>')
(dist/'index.html').write_text(html.rstrip()+'\n')
for name in ('showcase.html','showcase-preview.jpg'):
    source=root/'web'/name
    if source.exists(): (dist/name).write_bytes(source.read_bytes())
(dist/'app.js').write_text((root/'web/app.js').read_text())
(dist/'CREDITS.txt').write_text((root/'CREDITS.txt').read_text())
(dist/'.nojekyll').touch()
# Tiny code-native launcher mark; avoids shipping the engine's default icon.
def icon(size):
    pixels = bytearray()
    for y in range(size):
        pixels.append(0)
        for x in range(size):
            u,v=x/size,y/size
            accent=(.2<u<.8 and .23<v<.35) or (.2<u<.33 and .23<v<.76) or (.2<u<.65 and .64<v<.76) or (.5<u<.8 and .45<v<.56)
            pixels.extend((80,235,202) if accent else (23,37,55))
    def chunk(t,d):return struct.pack('>I',len(d))+t+d+struct.pack('>I',zlib.crc32(t+d)&0xffffffff)
    return b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('>IIBBBBB',size,size,8,2,0,0,0))+chunk(b'IDAT',zlib.compress(bytes(pixels)))+chunk(b'IEND',b'')
for size in (144,180,192,512): (dist/f'index.{size}x{size}.png').write_bytes(icon(size))
(dist/'index.apple-touch-icon.png').write_bytes(icon(180))
(dist/'index.icon.png').write_bytes(icon(144))
manifest=json.loads((dist/'index.manifest.json').read_text())
manifest['icons']=[{'src':'index.192x192.png','sizes':'192x192','type':'image/png','purpose':'any'},{'src':'index.512x512.png','sizes':'512x512','type':'image/png','purpose':'any maskable'}]
manifest.update(name='Capsule Sortie',short_name='Capsule',id='./',scope='./',start_url='./index.html',description='RX78 vs Zaku · 3D action fan demo',theme_color='#172537')
(dist/'index.manifest.json').write_text(json.dumps(manifest))
assets=sorted(p.name for p in dist.iterdir() if p.is_file() and p.name not in ('index.service.worker.js','.DS_Store','.gdignore','.nojekyll'))
hash_value=hashlib.sha256(b'precache-reload-v2'+b''.join((dist/n).read_bytes() for n in assets)).hexdigest()[:16]
worker='''const CACHE="capsule-__VERSION__";
const FILES=__FILES__;
self.addEventListener('install',e=>e.waitUntil(caches.open(CACHE).then(c=>c.addAll(FILES.map(file=>new Request(file,{cache:'reload'}))))));
self.addEventListener('activate',e=>e.waitUntil(Promise.all([caches.keys().then(keys=>Promise.all(keys.filter(k=>k.startsWith('capsule-')&&k!==CACHE).map(k=>caches.delete(k)))),self.clients.claim()])));
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
