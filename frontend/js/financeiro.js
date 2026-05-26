const sidebar = document.getElementById('sidebar');
const backdrop = document.getElementById('backdrop');
const menuToggle = document.getElementById('menuToggle');
const periodButtons = Array.from(document.querySelectorAll('.period-btn'));
const customRange = document.getElementById('customRange');
const customStart = document.getElementById('customStart');
const customEnd = document.getElementById('customEnd');
const indicatorsGrid = document.getElementById('indicatorsGrid');
const serviceBars = document.getElementById('serviceBars');
const transactionsBody = document.getElementById('transactionsBody');
const transactionsTotal = document.getElementById('transactionsTotal');

const periodData = {
  hoje: {
    indicadores: [
      { label: 'Faturamento total', value: 'R$ 385,00', note: 'Destaque do dia', highlight: true },
      { label: 'Total de atendimentos', value: '12', note: '2 atendimentos pendentes' },
      { label: 'Ticket médio', value: 'R$ 32,08', note: 'Ritmo abaixo da média' },
    ],
    barras: [
      { nome: 'Cabelo', valor: 'R$ 180,00', percentual: 47 },
      { nome: 'Corte + Barba', valor: 'R$ 110,00', percentual: 29 },
      { nome: 'Barba', valor: 'R$ 70,00', percentual: 18 },
      { nome: 'Sobrancelha', valor: 'R$ 25,00', percentual: 6 },
    ],
    transacoes: [
      { data: '25/05/2026', cliente: 'Ana Lima', servico: 'Cabelo', valor: 'R$ 35,00' },
      { data: '25/05/2026', cliente: 'Bruno Santos', servico: 'Barba', valor: 'R$ 25,00' },
      { data: '25/05/2026', cliente: 'Carla Souza', servico: 'Corte + Barba', valor: 'R$ 55,00' },
      { data: '25/05/2026', cliente: 'Diego Alves', servico: 'Sobrancelha', valor: 'R$ 15,00' },
      { data: '25/05/2026', cliente: 'Fernanda Rocha', servico: 'Cabelo', valor: 'R$ 35,00' },
      { data: '25/05/2026', cliente: 'Gustavo Mendes', servico: 'Barba', valor: 'R$ 25,00' },
      { data: '25/05/2026', cliente: 'Helena Costa', servico: 'Cabelo', valor: 'R$ 35,00' },
      { data: '25/05/2026', cliente: 'Igor Almeida', servico: 'Corte + Barba', valor: 'R$ 55,00' },
      { data: '25/05/2026', cliente: 'Juliana Ferreira', servico: 'Sobrancelha', valor: 'R$ 15,00' },
      { data: '25/05/2026', cliente: 'Marcos Vinicius', servico: 'Barba', valor: 'R$ 25,00' },
    ],
    total: 'R$ 385,00',
  },
  semana: {
    indicadores: [
      { label: 'Faturamento total', value: 'R$ 1.120,00', note: 'Semana em alta', highlight: true },
      { label: 'Total de atendimentos', value: '28', note: 'Média de 4 por dia' },
      { label: 'Ticket médio', value: 'R$ 40,00', note: 'Crescimento de 9%' },
    ],
    barras: [
      { nome: 'Cabelo', valor: 'R$ 470,00', percentual: 42 },
      { nome: 'Corte + Barba', valor: 'R$ 310,00', percentual: 28 },
      { nome: 'Barba', valor: 'R$ 220,00', percentual: 20 },
      { nome: 'Sobrancelha', valor: 'R$ 120,00', percentual: 10 },
    ],
    transacoes: [
      { data: '25/05/2026', cliente: 'Ana Lima', servico: 'Cabelo', valor: 'R$ 35,00' },
      { data: '24/05/2026', cliente: 'Bruno Santos', servico: 'Corte + Barba', valor: 'R$ 55,00' },
      { data: '24/05/2026', cliente: 'Carla Souza', servico: 'Barba', valor: 'R$ 25,00' },
      { data: '23/05/2026', cliente: 'Diego Alves', servico: 'Sobrancelha', valor: 'R$ 15,00' },
      { data: '23/05/2026', cliente: 'Fernanda Rocha', servico: 'Cabelo', valor: 'R$ 35,00' },
      { data: '22/05/2026', cliente: 'Gustavo Mendes', servico: 'Barba', valor: 'R$ 25,00' },
      { data: '22/05/2026', cliente: 'Helena Costa', servico: 'Cabelo', valor: 'R$ 35,00' },
      { data: '21/05/2026', cliente: 'Igor Almeida', servico: 'Corte + Barba', valor: 'R$ 55,00' },
      { data: '21/05/2026', cliente: 'Juliana Ferreira', servico: 'Sobrancelha', valor: 'R$ 15,00' },
      { data: '20/05/2026', cliente: 'Marcos Vinicius', servico: 'Barba', valor: 'R$ 25,00' },
    ],
    total: 'R$ 1.120,00',
  },
  mes: {
    indicadores: [
      { label: 'Faturamento total', value: 'R$ 2.840,00', note: 'Destaque do mês', highlight: true },
      { label: 'Total de atendimentos', value: '58', note: 'Média diária de 2 atendimentos' },
      { label: 'Ticket médio', value: 'R$ 48,97', note: 'Acima da meta mensal' },
    ],
    barras: [
      { nome: 'Cabelo', valor: 'R$ 1.260,00', percentual: 44 },
      { nome: 'Corte + Barba', valor: 'R$ 880,00', percentual: 31 },
      { nome: 'Barba', valor: 'R$ 500,00', percentual: 18 },
      { nome: 'Sobrancelha', valor: 'R$ 200,00', percentual: 7 },
    ],
    transacoes: [
      { data: '25/05/2026', cliente: 'Ana Lima', servico: 'Cabelo', valor: 'R$ 35,00' },
      { data: '24/05/2026', cliente: 'Bruno Santos', servico: 'Corte + Barba', valor: 'R$ 55,00' },
      { data: '23/05/2026', cliente: 'Carla Souza', servico: 'Barba', valor: 'R$ 25,00' },
      { data: '22/05/2026', cliente: 'Diego Alves', servico: 'Sobrancelha', valor: 'R$ 15,00' },
      { data: '21/05/2026', cliente: 'Fernanda Rocha', servico: 'Cabelo', valor: 'R$ 35,00' },
      { data: '20/05/2026', cliente: 'Gustavo Mendes', servico: 'Barba', valor: 'R$ 25,00' },
      { data: '19/05/2026', cliente: 'Helena Costa', servico: 'Cabelo', valor: 'R$ 35,00' },
      { data: '18/05/2026', cliente: 'Igor Almeida', servico: 'Corte + Barba', valor: 'R$ 55,00' },
      { data: '17/05/2026', cliente: 'Juliana Ferreira', servico: 'Sobrancelha', valor: 'R$ 15,00' },
      { data: '16/05/2026', cliente: 'Marcos Vinicius', servico: 'Barba', valor: 'R$ 25,00' },
    ],
    total: 'R$ 2.840,00',
  },
  personalizado: {
    indicadores: [
      { label: 'Faturamento total', value: 'R$ 0,00', note: 'Defina o intervalo de datas', highlight: true },
      { label: 'Total de atendimentos', value: '0', note: 'Sem dados no período' },
      { label: 'Ticket médio', value: 'R$ 0,00', note: 'Sem cálculo disponível' },
    ],
    barras: [
      { nome: 'Cabelo', valor: 'R$ 0,00', percentual: 0 },
      { nome: 'Corte + Barba', valor: 'R$ 0,00', percentual: 0 },
      { nome: 'Barba', valor: 'R$ 0,00', percentual: 0 },
      { nome: 'Sobrancelha', valor: 'R$ 0,00', percentual: 0 },
    ],
    transacoes: [],
    total: 'R$ 0,00',
  },
};

let periodoAtual = 'mes';

function abrirMenu() {
  sidebar.classList.add('open');
  backdrop.classList.add('open');
  backdrop.hidden = false;
  menuToggle.setAttribute('aria-expanded', 'true');
}

function fecharMenu() {
  sidebar.classList.remove('open');
  backdrop.classList.remove('open');
  backdrop.hidden = true;
  menuToggle.setAttribute('aria-expanded', 'false');
}

function alternarMenu() {
  if (sidebar.classList.contains('open')) {
    fecharMenu();
    return;
  }

  abrirMenu();
}

function formatarMoeda(valor) {
  return new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(valor);
}

function obterPeriodoCustomizado() {
  const inicio = customStart.value ? new Date(`${customStart.value}T00:00:00`) : null;
  const fim = customEnd.value ? new Date(`${customEnd.value}T00:00:00`) : null;

  if (!inicio || !fim || Number.isNaN(inicio.getTime()) || Number.isNaN(fim.getTime())) {
    return periodData.personalizado;
  }

  const dias = Math.max(1, Math.round((fim - inicio) / 86400000) + 1);
  const faturamento = dias * 82;
  const atendimentos = dias * 2;
  const ticket = faturamento / Math.max(atendimentos, 1);

  return {
    indicadores: [
      { label: 'Faturamento total', value: formatarMoeda(faturamento), note: 'Período personalizado', highlight: true },
      { label: 'Total de atendimentos', value: String(atendimentos), note: `${dias} dias selecionados` },
      { label: 'Ticket médio', value: formatarMoeda(ticket), note: 'Estimativa mockada' },
    ],
    barras: [
      { nome: 'Cabelo', valor: formatarMoeda(faturamento * 0.44), percentual: 44 },
      { nome: 'Corte + Barba', valor: formatarMoeda(faturamento * 0.31), percentual: 31 },
      { nome: 'Barba', valor: formatarMoeda(faturamento * 0.18), percentual: 18 },
      { nome: 'Sobrancelha', valor: formatarMoeda(faturamento * 0.07), percentual: 7 },
    ],
    transacoes: Array.from({ length: 10 }, (_, index) => ({
      data: `Dia ${10 - index}`,
      cliente: ['Ana Lima', 'Bruno Santos', 'Carla Souza', 'Diego Alves', 'Fernanda Rocha', 'Gustavo Mendes', 'Helena Costa', 'Igor Almeida', 'Juliana Ferreira', 'Marcos Vinicius'][index],
      servico: ['Cabelo', 'Barba', 'Corte + Barba', 'Sobrancelha', 'Cabelo', 'Barba', 'Cabelo', 'Corte + Barba', 'Sobrancelha', 'Barba'][index],
      valor: formatarMoeda([35, 25, 55, 15, 35, 25, 35, 55, 15, 25][index] + dias),
    })),
    total: formatarMoeda(faturamento),
  };
}

function obterDadosPeriodo(periodo) {
  if (periodo === 'personalizado') {
    return obterPeriodoCustomizado();
  }

  return periodData[periodo];
}

function renderIndicadores(periodo) {
  const dados = obterDadosPeriodo(periodo);

  indicatorsGrid.innerHTML = dados.indicadores
    .map(
      (item) => `
        <article class="metric-card ${item.highlight ? 'metric-card-highlight' : ''}">
          <span class="metric-label">${item.label}</span>
          <strong class="metric-value">${item.value}</strong>
          <span class="metric-note">${item.note}</span>
        </article>
      `,
    )
    .join('');
}

function renderBarras(periodo) {
  const dados = obterDadosPeriodo(periodo);

  serviceBars.innerHTML = dados.barras
    .map(
      (item) => `
        <div class="popular-item">
          <div class="popular-meta">
            <span class="popular-name">${item.nome}</span>
            <span class="popular-count">${item.valor} • ${item.percentual}%</span>
          </div>
          <div class="progress progress-track" role="progressbar" aria-label="${item.nome}" aria-valuenow="${item.percentual}" aria-valuemin="0" aria-valuemax="100">
            <div class="progress-bar progress-bar-gold" style="width: ${item.percentual}%"></div>
          </div>
        </div>
      `,
    )
    .join('');
}

function renderTransacoes(periodo) {
  const dados = obterDadosPeriodo(periodo);

  if (!dados.transacoes.length) {
    transactionsBody.innerHTML = `
      <tr>
        <td colspan="4">
          <div class="empty-state">Nenhuma transação encontrada para este período.</div>
        </td>
      </tr>
    `;
    transactionsTotal.textContent = dados.total;
    return;
  }

  transactionsBody.innerHTML = dados.transacoes
    .map(
      (transacao) => `
        <tr>
          <td>${transacao.data}</td>
          <td>${transacao.cliente}</td>
          <td>${transacao.servico}</td>
          <td>${transacao.valor}</td>
        </tr>
      `,
    )
    .join('');

  transactionsTotal.textContent = dados.total;
}

function atualizarPeriodo(periodo) {
  periodoAtual = periodo;
  periodButtons.forEach((button) => {
    button.classList.toggle('active', button.dataset.period === periodo);
  });
  customRange.hidden = periodo !== 'personalizado';
  renderIndicadores(periodo);
  renderBarras(periodo);
  renderTransacoes(periodo);
}

// TODO: integrar com GET /financeiro?periodo=X quando back-end estiver pronto
periodButtons.forEach((button) => {
  button.addEventListener('click', () => atualizarPeriodo(button.dataset.period));
});

menuToggle.addEventListener('click', alternarMenu);
backdrop.addEventListener('click', fecharMenu);
customStart.addEventListener('change', () => {
  if (periodoAtual === 'personalizado') {
    renderIndicadores('personalizado');
    renderBarras('personalizado');
    renderTransacoes('personalizado');
  }
});
customEnd.addEventListener('change', () => {
  if (periodoAtual === 'personalizado') {
    renderIndicadores('personalizado');
    renderBarras('personalizado');
    renderTransacoes('personalizado');
  }
});

atualizarPeriodo('mes');

window.addEventListener('resize', () => {
  if (window.innerWidth > 900) {
    fecharMenu();
  }
});
