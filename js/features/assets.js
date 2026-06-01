/* ── Ícone da vaca (caminho local) ─────────────── */
var COW_SRC = "img/cow_icon.png";

function injectCowIcons() {
  document.querySelectorAll('.cow-icon, .nav-cow').forEach(function(el) {
    el.src = COW_SRC;
  });
}
