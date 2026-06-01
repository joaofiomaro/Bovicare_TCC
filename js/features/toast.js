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

  var toast = document.createElement('div');
  toast.className = 'toast ' + type;
  toast.innerHTML = '<i class="' + (icons[type] || icons.success) + '"></i><span>' + message + '</span>';
  container.appendChild(toast);

  setTimeout(function() {
    toast.classList.add('toast-out');
    setTimeout(function() {
      if (toast.parentNode) toast.parentNode.removeChild(toast);
    }, 300);
  }, 2500);
}
