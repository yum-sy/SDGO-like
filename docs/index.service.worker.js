const CACHE="capsule-da441ebb042f01f0";
const FILES=["CREDITS.txt", "app.js", "index.144x144.png", "index.180x180.png", "index.192x192.png", "index.512x512.png", "index.apple-touch-icon.png", "index.audio.position.worklet.js", "index.audio.worklet.js", "index.html", "index.icon.png", "index.js", "index.manifest.json", "index.offline.html", "index.pck", "index.png", "index.wasm", "showcase-preview.jpg", "showcase.html"];
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
