(() => {
  const note = document.getElementById('pwa-note');
  const install = document.getElementById('install');
  const update = document.getElementById('update');
  const canvas = document.getElementById('canvas');
  let prompt, waiting;
  canvas.addEventListener('contextmenu', e => e.preventDefault());
  canvas.addEventListener('pointerdown', () => canvas.focus());
  window.addEventListener('beforeinstallprompt', e => {
    e.preventDefault(); prompt = e; install.hidden = false;
  });
  install.onclick = async () => {
    if (prompt) { await prompt.prompt(); await prompt.userChoice; prompt = null; install.hidden = true; }
    else note.textContent = 'iPhone/iPad: Safari 공유 → 홈 화면에 추가';
  };
  if (/iPad|iPhone/.test(navigator.userAgent)) install.hidden = false;
  window.addEventListener('appinstalled', () => {note.textContent = '설치 완료'; install.hidden = true;});
  document.getElementById('fullscreen').onclick = async () => {
    try {
      if (document.fullscreenElement) await document.exitFullscreen();
      else { await document.documentElement.requestFullscreen(); await screen.orientation?.lock?.('landscape').catch(()=>{}); }
    } catch { note.textContent = '전체화면은 홈 화면 설치 또는 브라우저 메뉴를 사용하세요.'; }
  };
  document.getElementById('mouse-lock').onclick = async () => {
    try {
      if (document.pointerLockElement) document.exitPointerLock();
      else await canvas.requestPointerLock();
    } catch { note.textContent = '마우스 잠금 미지원: 화면을 드래그해 시점을 돌리세요.'; }
    canvas.focus();
  };
  document.addEventListener('pointerlockchange', () => {
    document.getElementById('mouse-lock').textContent = document.pointerLockElement ? '잠금 해제' : '마우스 잠금';
  });
  if ('serviceWorker' in navigator) {
    navigator.serviceWorker.register('./index.service.worker.js').then(reg => {
      const offer = () => { if(reg.waiting && navigator.serviceWorker.controller) {waiting=reg.waiting;update.hidden=false;} };
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
  document.getElementById('credits').onclick = () => document.getElementById('credit-dialog').showModal();
  document.getElementById('close-credits').onclick = () => document.getElementById('credit-dialog').close();
})();
