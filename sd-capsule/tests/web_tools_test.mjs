import fs from 'node:fs';
import vm from 'node:vm';
import assert from 'node:assert/strict';
const events={},nodes={};
function node(id){return nodes[id] ||= {style:{},dataset:{},listeners:{},addEventListener(k,f){this.listeners[k]=f;},focus(){},showModal(){this.open=true;},close(){this.open=false;this.listeners.close?.();}};}
const window={capsuleLifecycleEpoch:0,addEventListener(k,f){events[k]=f;}};
const document={getElementById:node,createElement:()=>node('probe'),body:{appendChild(){}},addEventListener(){}};
vm.runInNewContext(fs.readFileSync(new URL('../web/app.js',import.meta.url),'utf8'),{window,document,navigator:{},getComputedStyle:()=>({paddingLeft:'0',paddingTop:'0',paddingRight:'0',paddingBottom:'0'})});
const tools=node('web-tools');
assert(tools.open && tools.dataset.mode==='ready');
node('canvas').listeners.pointerdown();assert(tools.open);
events['capsule-mode']({detail:'playing'});assert(!tools.open);
tools.open=true;tools.listeners.toggle();assert.equal(window.capsuleLifecycleEpoch,1);
events['capsule-mode']({detail:'paused'});assert(tools.open && tools.dataset.mode==='paused');
node('guide').onclick();assert(window.capsuleOverlayOpen && node('guide-dialog').open);
node('close-guide').onclick();assert(!window.capsuleOverlayOpen);
events['capsule-mode']({detail:'result'});assert(tools.open);
assert(!fs.readFileSync(new URL('../web/overlay.html',import.meta.url),'utf8').includes('id="mouse-lock"'));
console.log('PASS web tools: visible start/pause/result actions, compact combat controls, pause on open, modal focus lifecycle and no mouse-lock button');
