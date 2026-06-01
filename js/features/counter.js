/* ── Contador animado dos KPIs ────────────────────── */
function animateCounters() {
  var counters = document.querySelectorAll('.kpi-value[data-target]');
  counters.forEach(function(el) {
    var target = parseInt(el.getAttribute('data-target'), 10);
    if (isNaN(target)) return;

    var duration = 800;
    var start = null;

    function step(timestamp) {
      if (!start) start = timestamp;
      var progress = Math.min((timestamp - start) / duration, 1);
      /* Curva de ease-out para desaceleração natural */
      var eased = 1 - Math.pow(1 - progress, 3);
      el.textContent = Math.floor(eased * target);
      if (progress < 1) {
        requestAnimationFrame(step);
      } else {
        el.textContent = target;
      }
    }

    el.textContent = '0';
    requestAnimationFrame(step);
  });
}
