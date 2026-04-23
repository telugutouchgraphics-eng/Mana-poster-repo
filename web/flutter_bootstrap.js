{{flutter_js}}
{{flutter_build_config}}

if (!window._flutter) {
  window._flutter = {};
}

(async function () {
  if ('serviceWorker' in navigator) {
    try {
      const registrations = await navigator.serviceWorker.getRegistrations();
      await Promise.all(registrations.map((registration) => registration.unregister()));
    } catch (_) {}
  }

  _flutter.loader.load({});
})();
