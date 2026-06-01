/* ── Validação visual de formulários ─────────────── */
function validateForm(formContainer, onSuccess) {
  var inputs = formContainer.querySelectorAll('.form-input[required], .form-select[required]');
  var isValid = true;

  inputs.forEach(function(input) {
    input.classList.remove('input-error', 'input-success');

    if (!input.value || input.value.trim() === '') {
      input.classList.add('input-error');
      isValid = false;
    } else {
      /* Validação específica de e-mail */
      if (input.type === 'email' && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(input.value)) {
        input.classList.add('input-error');
        isValid = false;
      } else if (input.type === 'password' && input.value.length < 8) {
        input.classList.add('input-error');
        isValid = false;
      } else {
        input.classList.add('input-success');
      }
    }
  });

  if (!isValid) {
    showToast('Preencha todos os campos corretamente', 'error');
  } else if (onSuccess) {
    onSuccess();
  }

  return isValid;
}

/* Remover erro ao digitar */
document.addEventListener('DOMContentLoaded', function() {
  document.addEventListener('input', function(e) {
    if (e.target.classList.contains('form-input') || e.target.classList.contains('form-select')) {
      e.target.classList.remove('input-error');
      if (e.target.value && e.target.value.trim() !== '') {
        e.target.classList.add('input-success');
      } else {
        e.target.classList.remove('input-success');
      }
    }
  });
});
