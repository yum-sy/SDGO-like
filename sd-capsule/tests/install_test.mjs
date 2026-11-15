import fs from 'node:fs';
import vm from 'node:vm';
import assert from 'node:assert/strict';
const source=fs.readFileSync(new URL('../web/install.js',import.meta.url),'utf8');
function setup({standalone=false,ios=false,dismissed=false,storageError=false}={}) {
 const nodes=new Map(),events={};
 function node(id) {if(!nodes.has(id)) nodes.set(id,{open:false,hidden:false,disabled:false,textContent:'',listeners:{},addEventListener(k,f){this.listeners[k]=f;},showModal(){this.open=true;},close(){this.open=false;this.listeners.close?.();},focus(){this.focused=true;}});return nodes.get(id);}
 const win={matchMedia:()=>({matches:standalone,addEventListener(){}}),addEventListener(k,f){events[k]=f;}};
 vm.runInNewContext(source,{window:win,document:{getElementById:node},navigator:{userAgent:ios?'iPhone':'Chrome',platform:'',maxTouchPoints:0},sessionStorage:{getItem(){if(storageError) throw Error();return dismissed?'1':null;},setItem(){if(storageError)throw Error();}}});
 return {node,win,events};
}
let s=setup();
assert(s.node('install-dialog').open && s.win.capsuleOverlayOpen);
await s.node('install-primary').onclick();
assert(!s.node('install-help').hidden && s.node('install-help').textContent.includes('브라우저'));
s.node('play-browser').onclick();
assert(!s.node('install-dialog').open && !s.win.capsuleOverlayOpen && s.node('canvas').focused);
s.node('install').onclick();assert(s.node('install-dialog').open);
s=setup({standalone:true});assert(!s.node('install-dialog').open && s.node('install').hidden);
s=setup({dismissed:true});assert(!s.node('install-dialog').open);
s=setup({ios:true});await s.node('install-primary').onclick();assert(s.node('install-help').textContent.includes('Safari'));
s=setup({storageError:true});assert(s.node('install-dialog').open);s.node('play-browser').onclick();
s=setup();let prompts=0,prevented=false;
s.events.beforeinstallprompt({preventDefault(){prevented=true;},async prompt(){prompts++;},userChoice:Promise.resolve({outcome:'dismissed'})});
assert(prevented && s.node('install-primary').textContent==='설치하고 플레이');
await s.node('install-primary').onclick();assert(prompts===1 && s.node('install-state').textContent.includes('나중'));
await s.node('install-primary').onclick();assert(prompts===1);
s.events.appinstalled();assert(s.node('install').hidden && !s.node('install-dialog').open);
s=setup();s.events.beforeinstallprompt({preventDefault(){},async prompt(){throw Error('unsupported');}});
await s.node('install-primary').onclick();assert(!s.node('install-primary').disabled && !s.node('install-help').hidden);
s=setup();s.events.beforeinstallprompt({preventDefault(){},async prompt(){},userChoice:Promise.resolve({outcome:'accepted'})});
await s.node('install-primary').onclick();assert(s.node('install-state').textContent.includes('요청') && s.node('install-dialog').open);
s.events.appinstalled();assert(!s.node('install-dialog').open);
console.log('PASS install flow: standalone, dismissal, help, prompt lifecycle, install and failure recovery');
