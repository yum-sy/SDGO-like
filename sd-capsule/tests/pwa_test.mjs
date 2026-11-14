// Execute the generated worker against a stale HTTP cache and an offline network.
import fs from 'node:fs';
import vm from 'node:vm';
import assert from 'node:assert/strict';
const handlers = {}, stores = new Map([['capsule-old',new Map()],['unrelated-cache',new Map()]]);
let claimed = false;
const key = value => new URL(typeof value === 'string' ? value : value.url,'https://example.test/game/').pathname;
const caches = {
 async open(name) {
  if (!stores.has(name)) stores.set(name,new Map());
  const store=stores.get(name);
  return {
   async addAll(requests) {
    // Default fetch would reuse an obsolete, still-fresh browser HTTP response.
    for (const request of requests) store.set(key(request),request.cache === 'reload' ? 'new-build' : 'old-http-build');
   },
   async match(request) { return store.get(key(request)); }
  };
 },
 async keys(){return [...stores.keys()];},
 async delete(name){return stores.delete(name);}
};
const self={location:{origin:'https://example.test'},clients:{async claim(){claimed=true;}},addEventListener(type,handler){handlers[type]=handler;},skipWaiting(){}};
const context=vm.createContext({self,caches,URL,Promise,Request:class {constructor(url,options){this.url=url;Object.assign(this,options);}},fetch(){throw new Error('network offline');}});
vm.runInContext(fs.readFileSync(new URL('../dist/index.service.worker.js',import.meta.url),'utf8'),context);
let pending;
handlers.install({waitUntil(p){pending=p;}}); await pending;
handlers.activate({waitUntil(p){pending=p;}}); await pending;
assert.equal(claimed,true);
assert.equal(stores.has('capsule-old'),false);
assert.equal(stores.has('unrelated-cache'),true);
handlers.fetch({request:{method:'GET',url:'https://example.test/game/index.pck',mode:'cors'},respondWith(p){pending=p;}});
assert.equal(await pending,'new-build');
handlers.fetch({request:{method:'GET',url:'https://example.test/game/',mode:'navigate'},respondWith(p){pending=p;}});
assert.equal(await pending,'new-build');
console.log('PASS PWA: fresh precache, scoped cleanup, offline package and navigation');
