/* ── Controle do brete ───────────────────────────── */
function doorOpen() {
  var door = document.getElementById('door');
  door.classList.remove('pulse');
  void door.offsetWidth; // Força reflow para reiniciar a animação
  door.classList.add('open', 'pulse');
  door.style.borderColor = 'var(--brand)';
  document.getElementById('door-label').textContent = 'Porta aberta';
  document.getElementById('door-sub').textContent   = 'Animal pode entrar ou sair';
}

function doorClose() {
  var door = document.getElementById('door');
  door.classList.remove('open', 'pulse');
  void door.offsetWidth; // Força reflow para reiniciar a animação
  door.classList.add('pulse');
  door.style.borderColor = 'var(--brand)';
  document.getElementById('door-label').textContent = 'Porta fechada';
  document.getElementById('door-sub').textContent   = 'Travamento mecânico ativo';
}

function doorEmergency() {
  var door = document.getElementById('door');
  door.classList.remove('pulse');
  void door.offsetWidth; // Força reflow para reiniciar a animação
  door.classList.add('open', 'pulse');
  door.style.borderColor = '#D94040';
  document.getElementById('door-label').textContent = 'Parada de emergência';
  document.getElementById('door-sub').textContent   = 'Motor parado — obstáculo detectado';
}
