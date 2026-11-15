(() => {
  const dialog = document.getElementById('install-dialog');
  const primary = document.getElementById('install-primary');
  const menu = document.getElementById('install');
  const help = document.getElementById('install-help');
  const status = document.getElementById('install-state');
  const canvas = document.getElementById('canvas');
  const displayMode = window.matchMedia('(display-mode: standalone)');
  const installed = () => displayMode.matches || navigator.standalone === true;
  const apple = /iPad|iPhone/.test(navigator.userAgent) || (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1);
  let deferredPrompt = null;
  let busy = false;
  const show = () => {
    if (installed()) return;
    window.capsuleOverlayOpen = true;
    if (document.pointerLockElement) document.exitPointerLock();
    if (!dialog.open) dialog.showModal();
  };
  const close = () => {
    try { sessionStorage.setItem('sdgo-install-dismissed','1'); } catch {}
    window.capsuleOverlayOpen = false;
    canvas.focus();
  };
  dialog.addEventListener('close',close);
  document.getElementById('play-browser').onclick = () => dialog.close();
  menu.hidden = installed();
  menu.onclick = show;
  const explain = () => {
    help.hidden = false;
    help.textContent = apple
      ? 'iPhone·iPad: Safari에서 공유 버튼 → 홈 화면에 추가 → 추가를 선택하세요. 설치 후 홈 화면의 니세 건담 아이콘으로 실행하세요.'
      : '브라우저 메뉴에서 앱 설치 또는 홈 화면에 추가를 선택하세요. 설치 메뉴가 없다면 설치를 지원하는 브라우저에서 열거나 웹에서 바로 플레이할 수 있습니다.';
  };
  window.addEventListener('beforeinstallprompt',event => {
    event.preventDefault();
    if (installed()) return;
    deferredPrompt = event;
    primary.textContent = '설치하고 플레이';
    primary.disabled = false;
    menu.hidden = false;
  });
  primary.onclick = async () => {
    if (busy) return;
    if (!deferredPrompt) { explain(); return; }
    busy = true; primary.disabled = true;
    const request = deferredPrompt; deferredPrompt = null;
    try {
      await request.prompt();
      const choice = await request.userChoice;
      status.textContent = choice.outcome === 'accepted'
        ? '설치를 요청했습니다. 완료되면 홈 화면이나 앱 목록에서 실행하세요.'
        : '설치는 나중에 해도 됩니다. 웹에서 바로 플레이할 수 있어요.';
    } catch { status.textContent = '설치 창을 열 수 없습니다. 아래 설치 방법을 확인하세요.'; explain(); }
    finally { busy = false; primary.disabled = false; primary.textContent = '설치 방법 보기'; }
  };
  const hideInstalled = () => {
    menu.hidden = true; deferredPrompt = null;
    if (dialog.open) dialog.close();
  };
  window.addEventListener('appinstalled',hideInstalled);
  displayMode.addEventListener?.('change',() => { if(installed()) hideInstalled(); });
  let dismissed = false;
  try { dismissed = sessionStorage.getItem('sdgo-install-dismissed') === '1'; } catch {}
  if (!installed() && !dismissed) show();
})();
