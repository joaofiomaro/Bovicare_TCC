/* ── Init e Lógica de Splash ────────────────────────── */
window.addEventListener('DOMContentLoaded', function() {
  // Injeta os ícones dinâmicos nas imagens
  injectCowIcons();

  // Gerenciamento da tela de Splash
  var splash = document.getElementById('s-splash');
  if (splash) {
    // Aguarda 1.8s para a animação da logo antes do fade-out
    setTimeout(function() {
      splash.classList.add('fade-out');

      // Aguarda 400ms (duração da transição do CSS) para mudar para a tela de login
      setTimeout(function() {
        go('s-login');
      }, 400);
    }, 1800);
  }
});
