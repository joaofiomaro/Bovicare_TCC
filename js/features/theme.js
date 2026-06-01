/* ── Dark Mode Toggle ────────────────────────────── */
function toggleTheme() {
  var html = document.documentElement;
  var toggle = document.getElementById('theme-toggle');
  var isDark = html.getAttribute('data-theme') === 'dark';

  if (isDark) {
    html.removeAttribute('data-theme');
    if (toggle) toggle.classList.remove('active');
    localStorage.setItem('bovicare-theme', 'light');
  } else {
    html.setAttribute('data-theme', 'dark');
    if (toggle) toggle.classList.add('active');
    localStorage.setItem('bovicare-theme', 'dark');
  }
}

/* Restaurar tema salvo */
function initTheme() {
  var saved = localStorage.getItem('bovicare-theme');
  var toggle = document.getElementById('theme-toggle');
  if (saved === 'dark') {
    document.documentElement.setAttribute('data-theme', 'dark');
    if (toggle) toggle.classList.add('active');
  }
}
