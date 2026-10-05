// Light/dark switch. Loaded in <head> without defer, so a saved choice applies before the
// page paints. With no saved choice the page follows the system setting (see styles.css). Same script as quietsignalslab.com's theme.js.
// The choice is kept in this browser only; it is a preference, not tracking.
(function () {
    var root = document.documentElement;
    try {
        var saved = localStorage.getItem('theme');
        if (saved === 'light' || saved === 'dark') root.dataset.theme = saved;
    } catch (e) {}

    document.addEventListener('DOMContentLoaded', function () {
        var button = document.querySelector('.theme-toggle');
        if (!button) return;
        button.addEventListener('click', function () {
            var dark = root.dataset.theme
                ? root.dataset.theme === 'dark'
                : matchMedia('(prefers-color-scheme: dark)').matches;
            root.dataset.theme = dark ? 'light' : 'dark';
            try { localStorage.setItem('theme', root.dataset.theme); } catch (e) {}
        });
    });
})();
