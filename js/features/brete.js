/* ── Controle do brete ───────────────────────────── */
function doorOpen() {
  var door = document.getElementById('door');
  door.classList.add('open');
  door.style.borderColor = 'var(--brand)';
  document.getElementById('door-label').textContent = 'Porta aberta';
  document.getElementById('door-sub').textContent   = 'Animal pode entrar ou sair';
}

function doorClose() {
  var door = document.getElementById('door');
  door.classList.remove('open');
  door.style.borderColor = 'var(--brand)';
  document.getElementById('door-label').textContent = 'Porta fechada';
  document.getElementById('door-sub').textContent   = 'Travamento mecânico ativo';
}

function doorEmergency() {
  var door = document.getElementById('door');
  door.classList.add('open');
  door.style.borderColor = '#D94040';
  document.getElementById('door-label').textContent = 'Parada de emergência';
  document.getElementById('door-sub').textContent   = 'Motor parado — obstáculo detectado';
}
