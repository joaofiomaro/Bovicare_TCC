/* ── Navegação entre telas com transições fluidas ───────────────────────── */

// Histórico de navegação para determinar direção (push/pop)
var navStack = ['s-splash'];
var isTransitioning = false;

// Mapeamento de telas para o item ativo da bottom bar
var screenTabMap = {
  's-dash': 's-dash',
  's-rebanho': 's-rebanho',
  's-animal': 's-rebanho', // Ficha do animal é considerada parte da aba Rebanho
  's-brete': 's-brete',
  's-vets': 's-vets',
  's-perfil': 's-perfil'
};

function go(screenId) {
  // Evitar transições múltiplas simultâneas ou navegar para a mesma tela
  if (isTransitioning) return;
  
  var currentActive = document.querySelector('.screen.active');
  if (currentActive && currentActive.id === screenId) return;

  var target = document.getElementById(screenId);
  if (!target) return;

  isTransitioning = true;

  // Determinar o tipo de transição
  var transitionType = 'fade'; // Padrão
  
  var isTargetTab = screenTabMap.hasOwnProperty(screenId) && screenTabMap[screenId] === screenId;
  var isCurrentTab = currentActive && screenTabMap.hasOwnProperty(currentActive.id) && screenTabMap[currentActive.id] === currentActive.id;

  if (screenId === 's-splash' || screenId === 's-login') {
    // Telas iniciais/reset: limpa a pilha e usa crossfade
    navStack = [screenId];
    transitionType = 'fade';
  } else if (isTargetTab && isCurrentTab) {
    // Alternar entre abas principais: usa crossfade
    navStack = [screenId];
    transitionType = 'fade';
  } else {
    // Navegação de fluxo (push/pop)
    var targetIndex = navStack.indexOf(screenId);
    if (targetIndex !== -1) {
      // Tela já visitada anteriormente: voltar (pop)
      navStack = navStack.slice(0, targetIndex + 1);
      transitionType = 'pop';
    } else {
      // Nova tela no fluxo: avançar (push)
      navStack.push(screenId);
      transitionType = 'push';
    }
  }

  // Atualizar a bottom navigation compartilhada
  updateSharedNav(screenId);

  // Executar a transição física das telas
  if (currentActive) {
    performTransition(currentActive, target, transitionType);
  } else {
    // Sem tela ativa anterior (ex: carga inicial)
    target.classList.add('active');
    isTransitioning = false;
  }

  // Executar ações específicas de carregamento da tela
  onScreenEnter(screenId, target);
}

function updateSharedNav(screenId) {
  var sharedNav = document.getElementById('shared-nav');
  if (!sharedNav) return;

  var activeTab = screenTabMap[screenId];
  if (activeTab) {
    // Exibe a barra de navegação inferior
    sharedNav.style.display = 'flex';
    
    // Atualiza o estado ativo
    sharedNav.querySelectorAll('.nav-item').forEach(function(item) {
      if (item.getAttribute('data-screen') === activeTab) {
        item.classList.add('active');
      } else {
        item.classList.remove('active');
      }
    });
  } else {
    // Oculta a barra nas telas onde não deve aparecer (ex: login, splash, cadastro, nova vacina, etc.)
    sharedNav.style.display = 'none';
  }
}

function performTransition(currentEl, targetEl, type) {
  // Limpar classes residuais de transições anteriores
  currentEl.className = 'screen';
  targetEl.className = 'screen';

  if (type === 'push') {
    // Prepara tela de destino à direita
    targetEl.classList.add('transitioning-in-right');
    targetEl.offsetHeight; // Força reflow do navegador

    // Inicia a animação
    targetEl.classList.remove('transitioning-in-right');
    targetEl.classList.add('active');
    currentEl.classList.add('transitioning-out-left');
  } 
  else if (type === 'pop') {
    // Prepara tela de destino à esquerda (parallax)
    targetEl.classList.add('transitioning-in-left');
    targetEl.offsetHeight; // Força reflow do navegador

    // Inicia a animação
    targetEl.classList.remove('transitioning-in-left');
    targetEl.classList.add('active');
    currentEl.classList.add('transitioning-out-right');
  } 
  else {
    // Transição de Crossfade (Abas e telas especiais)
    targetEl.classList.add('transitioning-in-fade');
    targetEl.offsetHeight; // Força reflow do navegador

    targetEl.classList.remove('transitioning-in-fade');
    targetEl.classList.add('active');
    currentEl.classList.add('transitioning-out-fade');
  }

  // Finalização e limpeza após o término da transição de 400ms
  setTimeout(function() {
    currentEl.classList.remove('active', 'transitioning-out-left', 'transitioning-out-right', 'transitioning-out-fade');
    isTransitioning = false;
  }, 400);
}

function onScreenEnter(screenId, target) {
  /* Rolar para o topo */
  var scrollEl = target.querySelector('.scroll');
  if (scrollEl) scrollEl.scrollTop = 0;

  // Lógicas específicas de carregamento/atualização ao entrar na tela
  if (screenId === 's-dash') {
    if (typeof updateGreeting === 'function') updateGreeting();
    if (typeof animateCounters === 'function') animateCounters();
  }

  if (screenId === 's-rebanho') {
    var skeleton = document.getElementById('rebanho-skeleton');
    var content = document.getElementById('rebanho-content');
    if (skeleton && content) {
      // Adicionar suporte à transição suave
      skeleton.style.transition = 'opacity 0.25s ease';
      content.style.transition = 'opacity 0.25s ease';

      // Mostrar esqueleto
      skeleton.classList.remove('hidden');
      skeleton.style.display = 'block';
      skeleton.style.opacity = '1';

      // Ocultar conteúdo real temporariamente
      content.classList.add('hidden');
      content.style.display = 'none';
      content.style.opacity = '0';

      setTimeout(function() {
        // Esmaecer o skeleton
        skeleton.style.opacity = '0';

        setTimeout(function() {
          skeleton.classList.add('hidden');
          skeleton.style.display = 'none';

          // Fade-in suave do conteúdo real
          content.classList.remove('hidden');
          content.style.display = 'block';
          content.offsetHeight; // Reflow
          content.style.opacity = '1';
        }, 250);
      }, 600);
    }
  }

  if (screenId === 's-vets') {
    var skeleton = document.getElementById('vets-skeleton');
    var content = document.getElementById('vets-content');
    if (skeleton && content) {
      // Adicionar suporte à transição suave
      skeleton.style.transition = 'opacity 0.25s ease';
      content.style.transition = 'opacity 0.25s ease';

      // Mostrar esqueleto
      skeleton.classList.remove('hidden');
      skeleton.style.display = 'block';
      skeleton.style.opacity = '1';

      // Ocultar conteúdo real temporariamente
      content.classList.add('hidden');
      content.style.display = 'none';
      content.style.opacity = '0';

      setTimeout(function() {
        // Esmaecer o skeleton
        skeleton.style.opacity = '0';

        setTimeout(function() {
          skeleton.classList.add('hidden');
          skeleton.style.display = 'none';

          // Fade-in suave do conteúdo real
          content.classList.remove('hidden');
          content.style.display = 'block';
          content.offsetHeight; // Reflow
          content.style.opacity = '1';
        }, 250);
      }, 600);
    }
  }
}
