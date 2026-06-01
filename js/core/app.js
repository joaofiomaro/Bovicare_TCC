/* ── Init e Lógica de Splash ────────────────────────── */
window.addEventListener('DOMContentLoaded', function() {
  // Restaurar tema salvo se houver
  if (typeof initTheme === 'function') initTheme();

  // Injeta os ícones dinâmicos nas imagens
  injectCowIcons();

  // Inicializa o Pull-to-Refresh
  if (typeof initPullToRefresh === 'function') initPullToRefresh();

  // Atualiza saudação com base no horário
  updateGreeting();

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

function updateGreeting() {
  var greetingEl = document.querySelector('.hdr-greeting');
  if (!greetingEl) return;
  var hr = new Date().getHours();
  var greeting = 'Bom dia';
  if (hr >= 12 && hr < 18) {
    greeting = 'Boa tarde';
  } else if (hr >= 18 || hr < 5) {
    greeting = 'Boa noite';
  }
  greetingEl.textContent = greeting;
}
