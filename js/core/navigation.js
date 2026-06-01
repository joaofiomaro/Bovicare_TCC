/* ── Navegação entre telas ───────────────────────── */
function go(screenId) {
  document.querySelectorAll('.screen').forEach(function(s) {
    s.classList.remove('active');
  });
  var target = document.getElementById(screenId);
  if (target) {
    target.classList.add('active');
    /* Rolar para o topo */
    var scrollEl = target.querySelector('.scroll');
    if (scrollEl) scrollEl.scrollTop = 0;
  }
}
