/* ── Pull-to-Refresh ────────────────────────────── */
function initPullToRefresh() {
  var scrollEls = document.querySelectorAll('#s-dash .scroll, #s-rebanho .scroll');

  scrollEls.forEach(function(scrollEl) {
    var indicator = scrollEl.querySelector('.pull-indicator');
    if (!indicator) return;

    var startY = 0;
    var isPulling = false;

    scrollEl.addEventListener('touchstart', function(e) {
      if (scrollEl.scrollTop <= 0) {
        startY = e.touches[0].clientY;
        isPulling = true;
      }
    }, { passive: true });

    scrollEl.addEventListener('touchmove', function(e) {
      if (!isPulling) return;
      var delta = e.touches[0].clientY - startY;
      if (delta > 50 && scrollEl.scrollTop <= 0) {
        indicator.classList.add('pulling');
      }
    }, { passive: true });

    scrollEl.addEventListener('touchend', function() {
      if (!isPulling) return;
      isPulling = false;

      if (indicator.classList.contains('pulling')) {
        /* Simula recarga por 1.2s */
        setTimeout(function() {
          indicator.classList.remove('pulling');
          showToast('Dados atualizados', 'success');
        }, 1200);
      }
    });
  });
}
