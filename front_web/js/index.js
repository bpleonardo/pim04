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

const servicePrice = new Intl.NumberFormat('pt-BR', {
  style: 'currency',
  currency: 'BRL',
});

async function renderizarServicosIndex() {
  const container = document.getElementById('servicos-grid');
  if (!container) return;

  try {
    const response = await fetch('/api/servicos', { cache: 'no-store' });
    if (!response.ok) throw new Error('Falha ao carregar serviços.');
    const { data } = await response.json();
    const services = data.filter(service => service.ativo !== false);

    if (!services.length) {
      container.textContent = 'Nenhum serviço disponível no momento.';
      return;
    }

    for (const service of services) {
      const card = document.createElement('article');
      card.className = 'col';
      card.innerHTML = `
        <div class="card h-100 bg-transparent border-secondary">
          <div class="card-body p-4">
            <div class="card-icon fs-2 mb-3" aria-hidden="true">✂</div>
            <h3 class="card-title h5"></h3>
            <p class="card-desc mb-3"></p>
            <p class="card-price mb-0"></p>
          </div>
        </div>`;
      card.querySelector('.card-title').textContent = service.nome;
      card.querySelector('.card-desc').textContent = service.descricao ?? '';
      card.querySelector('.card-price').textContent = servicePrice.format(service.preco);
      container.append(card);
    }
  } catch {
    container.textContent = 'Não foi possível carregar os serviços. Tente novamente em instantes.';
  }
}

document.addEventListener('DOMContentLoaded', renderizarServicosIndex);
