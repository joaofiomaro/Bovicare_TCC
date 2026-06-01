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

    // Ações específicas para cada tela
    if (screenId === 's-dash') {
      if (typeof updateGreeting === 'function') updateGreeting();
      if (typeof animateCounters === 'function') animateCounters();
    }

    if (screenId === 's-rebanho') {
      var skeleton = document.getElementById('rebanho-skeleton');
      var content = document.getElementById('rebanho-content');
      if (skeleton && content) {
        skeleton.classList.remove('hidden');
        content.classList.add('hidden');
        setTimeout(function() {
          skeleton.classList.add('hidden');
          content.classList.remove('hidden');
        }, 600);
      }
    }

    if (screenId === 's-vets') {
      var skeleton = document.getElementById('vets-skeleton');
      var content = document.getElementById('vets-content');
      if (skeleton && content) {
        skeleton.classList.remove('hidden');
        content.classList.add('hidden');
        setTimeout(function() {
          skeleton.classList.add('hidden');
          content.classList.remove('hidden');
        }, 600);
      }
    }
  }
}
