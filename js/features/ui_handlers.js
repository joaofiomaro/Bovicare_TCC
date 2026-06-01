/* ── Seleção de perfil no cadastro ──────────────── */
function selPerfil(tipo) {
  var prod = document.getElementById('tp-prod');
  var vet  = document.getElementById('tp-vet');
  if (tipo === 'prod') {
    prod.style.background    = 'var(--brand-pale)';
    prod.style.borderColor   = 'rgba(28,107,58,.35)';
    vet.style.background     = 'var(--card)';
    vet.style.borderColor    = 'rgba(15,31,22,.08)';
  } else {
    vet.style.background     = 'var(--brand-pale)';
    vet.style.borderColor    = 'rgba(28,107,58,.35)';
    prod.style.background    = 'var(--card)';
    prod.style.borderColor   = 'rgba(15,31,22,.08)';
  }
}

document.addEventListener('DOMContentLoaded', function() {
  /* ── Chips interativos ───────────────────────────── */
  document.querySelectorAll('.chips').forEach(function(group) {
    group.querySelectorAll('.chip').forEach(function(chip) {
      chip.addEventListener('click', function() {
        group.querySelectorAll('.chip').forEach(function(c) { c.classList.remove('active'); });
        chip.classList.add('active');
      });
    });
  });

  /* ── Tabs interativas ────────────────────────────── */
  document.querySelectorAll('.tabs').forEach(function(group) {
    group.querySelectorAll('.tab').forEach(function(tab) {
      tab.addEventListener('click', function() {
        group.querySelectorAll('.tab').forEach(function(t) { t.classList.remove('active'); });
        tab.classList.add('active');
      });
    });
  });
});
