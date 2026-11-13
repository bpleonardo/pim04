// Controla o foco dos links do menu para não deixar TAB em itens escondidos no mobile.
document.addEventListener('DOMContentLoaded', () => {
  const navCollapse = document.getElementById('navPrincipal');
  if (!navCollapse) return;

  // Links que precisam ficar navegáveis apenas quando o menu estiver visível.
  const navLinks = Array.from(navCollapse.querySelectorAll('a'));
  const media = window.matchMedia('(min-width: 768px)');

  // Aplica ou remove o TAB dos links do menu.
  function setNavTab(enabled) {
    navLinks.forEach(link => {
      link.setAttribute('tabindex', enabled ? '0' : '-1');
    });
  }

  // No desktop, o menu é sempre navegável.
  // No mobile, só liberamos o TAB quando o collapse estiver aberto.
  function atualizarTabMenu() {
    if (media.matches) {
      setNavTab(true);
    } else {
      setNavTab(navCollapse.classList.contains('show'));
    }
  }

  // Atualiza o TAB junto com os eventos nativos do Bootstrap collapse.
  navCollapse.addEventListener('shown.bs.collapse', () => setNavTab(true));
  navCollapse.addEventListener('hidden.bs.collapse', () => setNavTab(false));

  // Reavalia o comportamento quando a tela muda de tamanho.
  media.addEventListener('change', atualizarTabMenu);

  atualizarTabMenu();
});
