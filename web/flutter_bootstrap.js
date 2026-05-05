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

  _flutter.loader.load({
    onEntrypointLoaded: async function (engineInitializer) {
      const appRunner = await engineInitializer.initializeEngine();
      await appRunner.runApp();

      requestAnimationFrame(function () {
        requestAnimationFrame(function () {
          const loader = document.getElementById('flutter-loader');
          if (loader) {
            loader.remove();
          }
        });
      });
    },
  });
})();
