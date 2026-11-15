(() => {
  const probe = document.createElement('div');
  probe.style.cssText = 'position:fixed;visibility:hidden;pointer-events:none;padding:env(safe-area-inset-top) env(safe-area-inset-right) env(safe-area-inset-bottom) env(safe-area-inset-left)';
  document.body.appendChild(probe);
  const safe = () => { const css=getComputedStyle(probe); window.capsuleSafeInsets=[css.paddingLeft,css.paddingTop,css.paddingRight,css.paddingBottom].map(v=>parseFloat(v)||0); };
  safe(); window.addEventListener('resize',safe);
  const note = document.getElementById('pwa-note');
  const update = document.getElementById('update');
  const canvas = document.getElementById('canvas');
  const toolbox = document.getElementById('web-tools');
  window.capsuleOverlayOpen = false;
  let mode = 'ready';
  toolbox.dataset.mode = mode;
  toolbox.open = true;
  window.addEventListener('capsule-mode', event => {
    mode = event.detail;
    toolbox.dataset.mode = mode;
    toolbox.open = mode !== 'playing';
  });
  toolbox.addEventListener('toggle', () => {
    if(toolbox.open && mode === 'playing') window.capsuleLifecycleEpoch++;
  });
  let waiting;
  canvas.addEventListener('contextmenu', e => e.preventDefault());
  canvas.addEventListener('pointerdown', () => {canvas.focus();if(mode === "playing") toolbox.open=false;});
  document.getElementById('fullscreen').onclick = async () => {
    try {
      if (document.fullscreenElement) await document.exitFullscreen();
      else { await document.documentElement.requestFullscreen(); await screen.orientation?.lock?.('landscape').catch(()=>{}); }
    } catch { note.textContent = '전체화면은 홈 화면 설치 또는 브라우저 메뉴를 사용하세요.'; }
  };
  if ('serviceWorker' in navigator) {
    navigator.serviceWorker.register('./index.service.worker.js').then(reg => {
      const offer = () => { if(reg.waiting && navigator.serviceWorker.controller) {waiting=reg.waiting;update.hidden=false;if(mode !== "playing") toolbox.open=true;} };
      offer();
      reg.addEventListener('updatefound', () => { const worker=reg.installing; worker?.addEventListener('statechange',offer); });
      return navigator.serviceWorker.ready;
    }).then(() => { note.textContent = '오프라인 준비 완료'; })
      .catch(() => { note.textContent = '오프라인 저장 실패 · 온라인 플레이 가능'; });
    let refreshing = false;
    navigator.serviceWorker.addEventListener('controllerchange', () => {
      if(waiting && !refreshing) {refreshing=true;location.reload();}
    });
    update.onclick = () => waiting?.postMessage({type:'SKIP_WAITING'});
  } else note.textContent='온라인 모드';
  for (const name of ['credits','guide']) {
    const dialog = document.getElementById(name === 'credits' ? 'credit-dialog' : 'guide-dialog');
    document.getElementById(name).onclick = () => {
      window.capsuleOverlayOpen = true;
      if(document.pointerLockElement) document.exitPointerLock();
      dialog.showModal();
    };
    document.getElementById('close-'+name).onclick = () => dialog.close();
    dialog.addEventListener('close', () => {window.capsuleOverlayOpen=false;canvas.focus();});
  }
})();
