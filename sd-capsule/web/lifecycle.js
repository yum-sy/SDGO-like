(() => {
  window.capsuleLifecycleEpoch = 0;
  const suspend = () => { window.capsuleLifecycleEpoch++; };
  document.addEventListener('visibilitychange', () => { if(document.hidden) suspend(); });
  window.addEventListener('pagehide', suspend);
  window.addEventListener('pageshow', event => { if(event.persisted) suspend(); });
  screen.orientation?.addEventListener?.('change', suspend);

})();
