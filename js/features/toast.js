/* ── Toast / Snackbar ────────────────────────────── */
function showToast(message, type) {
  type = type || 'success';
  var container = document.getElementById('toast-container');
  if (!container) return;

  var icons = {
    success: 'ti ti-check',
    error: 'ti ti-x',
    info: 'ti ti-info-circle'
  };

  /* Monta o DOM sem innerHTML: a mensagem entra como texto puro, então
     nunca é interpretada como HTML (evita XSS caso venha de dados externos). */
  var toast = document.createElement('div');
  toast.className = 'toast ' + type;

  var icon = document.createElement('i');
  icon.className = icons[type] || icons.success;
  icon.setAttribute('aria-hidden', 'true');

  var text = document.createElement('span');
  text.textContent = String(message);

  toast.appendChild(icon);
  toast.appendChild(text);
  container.appendChild(toast);

  setTimeout(function() {
    toast.classList.add('toast-out');
    setTimeout(function() {
      if (toast.parentNode) toast.parentNode.removeChild(toast);
    }, 300);
  }, 2500);
}
