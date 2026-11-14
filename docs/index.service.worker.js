const CACHE="capsule-860c82c3a8e87995";
const FILES=[".nojekyll", "CREDITS.txt", "app.js", "index.144x144.png", "index.144x144.png.import", "index.180x180.png", "index.180x180.png.import", "index.512x512.png", "index.512x512.png.import", "index.apple-touch-icon.png", "index.apple-touch-icon.png.import", "index.audio.position.worklet.js", "index.audio.worklet.js", "index.html", "index.icon.png", "index.icon.png.import", "index.js", "index.manifest.json", "index.offline.html", "index.pck", "index.png", "index.png.import", "index.wasm"];
self.addEventListener('install',e=>e.waitUntil(caches.open(CACHE).then(c=>c.addAll(FILES))));
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
