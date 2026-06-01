/* ── Bottom Sheet (Modal de Confirmação) ─────────── */
function openSheet(config) {
  var overlay = document.getElementById('sheet-overlay');
  var panel = document.getElementById('sheet-panel');
  if (!overlay || !panel) return;

  /* Preencher conteúdo */
  var iconEl = panel.querySelector('.sheet-icon');
  var iconI = iconEl.querySelector('i');
  var titleEl = panel.querySelector('.sheet-title');
  var msgEl = panel.querySelector('.sheet-message');
  var confirmBtn = document.getElementById('sheet-confirm');

  iconEl.className = 'sheet-icon ' + (config.iconType || 'danger');
  iconI.className = config.icon || 'ti ti-alert-triangle';
  titleEl.textContent = config.title || 'Confirmar ação';
  msgEl.textContent = config.message || 'Tem certeza que deseja continuar?';
  confirmBtn.textContent = config.confirmText || 'Confirmar';
  confirmBtn.className = config.confirmClass || 'btn-danger';
  confirmBtn.style.width = '100%';

  /* Salvar callback */
  confirmBtn.onclick = function() {
    closeSheet();
    if (config.onConfirm) {
      setTimeout(config.onConfirm, 350);
    }
  };

  /* Abrir */
  overlay.classList.add('active');
  panel.classList.add('active');
}

function closeSheet() {
  var overlay = document.getElementById('sheet-overlay');
  var panel = document.getElementById('sheet-panel');
  if (overlay) overlay.classList.remove('active');
  if (panel) panel.classList.remove('active');
}
