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

// Dados dos serviços exibidos na home — alterar aqui para atualizar a vitrine.
const INDEX_SERVICOS = [
  { titulo: 'Cabelo', descricao: 'Cortes modernos e clássicos executados com precisão.', preco: 35, icone: '✂' },
  { titulo: 'Barba', descricao: 'Modelagem e acabamento com navalha para um visual impecável.', preco: 25, icone: '🪒' },
  { titulo: 'Sobrancelha', descricao: 'Design e acabamento profissional para realçar o seu olhar.', preco: 15, icone: '👁' },
];

// Renderiza a seção de serviços na home mantendo classes Bootstrap para responsividade.
function renderizarServicosIndex() {
  const container = document.getElementById('servicos-grid');
  if (!container) return;

  container.innerHTML = INDEX_SERVICOS.map(s => `
    <article class="col">
      <div class="card h-100 bg-transparent border-secondary">
        <div class="card-body p-4">
          <div class="card-icon fs-2 mb-3">${s.icone}</div>
          <h3 class="card-title h5">${s.titulo}</h3>
          <p class="card-desc mb-3">${s.descricao}</p>
          <p class="card-price mb-0">A partir de R$ ${s.preco},00</p>
        </div>
      </div>
    </article>
  `).join('');
}

// Chama a renderização assim que o DOM principal estiver pronto.
document.addEventListener('DOMContentLoaded', () => {
  renderizarServicosIndex();
});
