// Estado central do agendamento
const estado = {
  servicos: [],
  data: null,
  horario: null,
};

// A partir deste dia (contando de hoje), a UI bloqueia horários por indisponibilidade.
const DIAS_LIMITE_SEM_HORARIOS = 10;

const API_BASE = '/api';

// Dados que alimentam a interface sem repetir markup no HTML.
let SERVICOS = [
  { nome: 'Cabelo', preco: 35, icone: '✂' },
  { nome: 'Sobrancelha', preco: 15, icone: '🪒' },
  { nome: 'Barba', preco: 25, icone: '🧔' },
];

function iconeServico(nome) {
  const normalizado = nome.toLowerCase();

  if (normalizado.includes('sobrancelha')) return '🪒';
  if (normalizado.includes('barba')) return '🧔';
  return '✂';
}

async function carregarServicosDaApi() {
  try {
    const response = await fetch(`${API_BASE}/servicos`);

    if (!response.ok) {
      throw new Error(`Falha ao carregar serviços (${response.status})`);
    }

    const payload = await response.json();
    const data = Array.isArray(payload?.data) ? payload.data : [];

    if (data.length) {
      SERVICOS = data.map((servico) => ({
        nome: servico.nome,
        preco: Number(servico.preco) || 0,
        icone: iconeServico(servico.nome),
      }));
      renderizarServicos();
    }
  } catch (error) {
    console.warn('Não foi possível carregar serviços da API. Mantendo a lista local.', error);
  }
}

const HORARIOS = [
  { hora: '08:00', disponivel: true },
  { hora: '08:30', disponivel: true },
  { hora: '09:00', disponivel: false },
  { hora: '09:30', disponivel: true },
  { hora: '10:00', disponivel: true },
  { hora: '10:30', disponivel: false },
  { hora: '11:00', disponivel: false },
  { hora: '11:30', disponivel: true },
  { hora: '13:00', disponivel: true },
  { hora: '13:30', disponivel: true },
  { hora: '14:00', disponivel: false },
  { hora: '14:30', disponivel: true },
  { hora: '15:00', disponivel: true },
  { hora: '15:30', disponivel: true },
  { hora: '16:00', disponivel: false },
  { hora: '16:30', disponivel: true },
  { hora: '17:00', disponivel: true },
  { hora: '17:30', disponivel: true },
];

// Campos exibidos no resumo final.
const RESUMO = [
  { chave: 'servicos', label: 'Serviços', valor: () => (estado.servicos.length ? estado.servicos.map(s => s.nome).join(', ') : '—') },
  { chave: 'data', label: 'Dia', valor: () => formatarDataBR(dom.data?.value) },
  { chave: 'horario', label: 'Horário', valor: () => estado.horario || '—' },
  { chave: 'nome', label: 'Nome', valor: () => dom.nome?.value.trim() || '—' },
  { chave: 'telefone', label: 'Telefone', valor: () => dom.tel?.value.trim() || '—' },
  { chave: 'email', label: 'E-mail', valor: () => dom.email?.value.trim() || '—' },
  { chave: 'total', label: 'Total', valor: () => formatarMoeda(estado.servicos.reduce((acc, servico) => acc + servico.preco, 0)) },
];

// Cache dos elementos usados com mais frequência na tela.
const dom = {
  form: null,
  tel: null,
  data: null,
  nome: null,
  email: null,
  obs: null,
  confirmar: null,
  sucesso: null,
  steps: null,
  stepTitle: null,
  stepTag: null,
  servicoErr: null,
  horarioErr: null,
  dataErr: null,
  nomeErr: null,
  telErr: null,
  emailErr: null,
  totalServicos: null,
  servicosGrid: null,
  horariosGrid: null,
  resServicos: null,
  resData: null,
  resHorario: null,
  resNome: null,
  resTelefone: null,
  resEmail: null,
  resTotal: null,
  resumoCorpo: null,
  resumoValores: {},
  sucNome: null,
  panel1: null,
  panels: [],
  stepIndicators: [],
  stepLines: [],
};

// Formata valores no padrão de moeda brasileira.
function formatarMoeda(valor) {
  return `R$ ${valor.toFixed(2).replace('.', ',')}`;
}

// Converte a data do input ISO para o formato BR.
function formatarDataBR(valor) {
  if (!valor) return '—';
  const [ano, mes, dia] = valor.split('-');
  return `${dia}/${mes}/${ano}`;
}

// Helpers pequenos para escrever texto e controlar visibilidade de erros.
function setTexto(el, valor) {
  if (el) el.textContent = valor;
}

function setVisibilidade(el, visivel) {
  if (el) el.style.display = visivel ? 'block' : 'none';
}

function normalizarData(valor) {
  if (!valor) return null;

  const [ano, mes, dia] = valor.split('-').map(Number);
  const data = new Date(ano, mes - 1, dia);

  const dataRealValida =
    data.getFullYear() === ano &&
    data.getMonth() === mes - 1 &&
    data.getDate() === dia;

  if (!dataRealValida) return null;

  data.setHours(0, 0, 0, 0);
  return data;
}

function dataAnteriorAHoje(valor) {
  const data = normalizarData(valor);
  if (!data) return false;

  const hoje = new Date();
  hoje.setHours(0, 0, 0, 0);

  return data < hoje;
}

function dataSemHorarios(valor) {
  const data = normalizarData(valor);
  if (!data) return false;

  const hoje = new Date();
  hoje.setHours(0, 0, 0, 0);

  const dataSemHorario = new Date(hoje);
  dataSemHorario.setDate(dataSemHorario.getDate() + DIAS_LIMITE_SEM_HORARIOS);

  return data > dataSemHorario;
}

function bloquearHorariosPorData(valor) {
  if (!valor) return false;
  return dataAnteriorAHoje(valor) || dataSemHorarios(valor);
}

// Valida se a data é real, não está no passado e não excede 10 dias.
function dataValida(valor) {
  const data = normalizarData(valor);
  if (!data) return false;

  const hoje = new Date();
  hoje.setHours(0, 0, 0, 0);

  const dataMaxima = new Date(hoje);
  dataMaxima.setDate(dataMaxima.getDate() + DIAS_LIMITE_SEM_HORARIOS);

  return data >= hoje && data <= dataMaxima;
}

// Gera os cards de serviço diretamente a partir dos dados acima.
function renderizarServicos() {
  if (!dom.servicosGrid) return;

  dom.servicosGrid.innerHTML = SERVICOS.map(
    servico => `
      <div class="col">
        <button
          class="servico-card btn btn-outline-secondary w-100 h-100 text-start p-3"
          type="button"
          data-servico
          data-nome="${servico.nome}"
          data-preco="${servico.preco}"
        >
          <div class="servico-icon fs-3 mb-2">${servico.icone}</div>
          <div class="servico-nome fw-semibold">${servico.nome}</div>
          <div class="servico-preco">R$ ${servico.preco},00</div>
        </button>
      </div>
    `
  ).join('');
}

// Gera os horários disponíveis/indisponíveis a partir de uma lista única.
function renderizarHorarios() {
  if (!dom.horariosGrid) return;

  const bloquearTodos = bloquearHorariosPorData(dom.data?.value);

  dom.horariosGrid.innerHTML = HORARIOS.map(
    horario => `
      <div class="col">
        <button
          class="horario-btn btn btn-outline-secondary w-100${horario.disponivel && !bloquearTodos ? '' : ' indisponivel'}"
          type="button"
          data-horario="${horario.hora}"
          ${horario.disponivel && !bloquearTodos ? '' : 'disabled'}
        >
          ${horario.hora}
        </button>
      </div>
    `
  ).join('');
}

// Recalcula o total de serviços sempre que a seleção muda.
function atualizarTotal() {
  const total = estado.servicos.reduce((acc, servico) => acc + servico.preco, 0);
  setTexto(dom.totalServicos, formatarMoeda(total));
  setTexto(dom.resTotal, formatarMoeda(total));
}

// Monta o resumo final com os dados já preenchidos nas etapas anteriores.
function atualizarResumo() {
  RESUMO.forEach(item => {
    setTexto(dom.resumoValores[item.chave], item.valor());
  });

  atualizarTotal();
}

// Atualiza o estado visual dos cards de serviço.
function sincronizarServicos() {
  if (!dom.servicosGrid) return;

  dom.servicosGrid.querySelectorAll('[data-servico]').forEach(card => {
    const nome = card.dataset.nome;
    const selecionado = estado.servicos.some(servico => servico.nome === nome);
    card.classList.toggle('selected', selecionado);
  });
}

// Atualiza o estado visual do horário selecionado.
function sincronizarHorario() {
  if (!dom.horariosGrid) return;

  dom.horariosGrid.querySelectorAll('.horario-btn').forEach(btn => {
    btn.classList.toggle('selected', btn.dataset.horario === estado.horario);
  });
}

function atualizarFeedbackDataEHorarios() {
  const dataValor = dom.data?.value;
  if (!dataValor) return;

  if (dataAnteriorAHoje(dataValor) || !normalizarData(dataValor)) {
    setTexto(dom.dataErr, 'Data inválida.');
    setVisibilidade(dom.dataErr, true);
    setVisibilidade(dom.horarioErr, false);
  } else if (dataSemHorarios(dataValor)) {
    limparErroDom(dom.data, dom.dataErr);
    setTexto(dom.horarioErr, 'Não há horários disponíveis para essa data.');
    setVisibilidade(dom.horarioErr, true);
  } else {
    limparErroDom(dom.data, dom.dataErr);
    setTexto(dom.horarioErr, 'Selecione um horário');
    setVisibilidade(dom.horarioErr, false);
  }

  if (bloquearHorariosPorData(dataValor)) {
    estado.horario = null;
    sincronizarHorario();
  }

  renderizarHorarios();
}

// Renderiza o resumo final a partir dos dados definidos acima.
function renderizarResumo() {
  if (!dom.resumoCorpo) return;

  dom.resumoCorpo.innerHTML = RESUMO.map(
    item => `
      <div class="resumo-linha d-flex justify-content-between align-items-center px-4 py-3 border-bottom border-secondary">
        <span class="resumo-label">${item.label}</span>
        <span class="resumo-valor" data-resumo="${item.chave}">—</span>
      </div>
    `
  ).join('');

  dom.resumoValores = Object.fromEntries(
    Array.from(dom.resumoCorpo.querySelectorAll('[data-resumo]')).map(el => [el.dataset.resumo, el])
  );
}

// Helpers para aplicar e remover estado de erro dos campos.
function limparErroDom(inputEl, errorEl) {
  if (!inputEl || !errorEl) return;
  inputEl.classList.remove('input-error');
  errorEl.style.display = 'none';
}

function mostrarErroDom(inputEl, errorEl) {
  if (!inputEl || !errorEl) return;
  inputEl.classList.add('input-error');
  errorEl.style.display = 'block';
}

// Garante que a navegação por TAB fique restrita ao painel ativo.
function focaveisNoPainel(panel) {
  return Array.from(
    panel.querySelectorAll('a, button, input, select, textarea, [tabindex]')
  ).filter(el => !el.classList.contains('indisponivel'));
}

function desabilitarTab(panel) {
  focaveisNoPainel(panel).forEach(el => {
    if (!el.hasAttribute('data-tabindex')) {
      el.setAttribute('data-tabindex', el.getAttribute('tabindex') ?? '');
    }
    el.setAttribute('tabindex', '-1');
  });
}

function habilitarTab(panel) {
  focaveisNoPainel(panel).forEach(el => {
    const anterior = el.getAttribute('data-tabindex');
    if (anterior === '') {
      el.removeAttribute('tabindex');
    } else if (anterior != null) {
      el.setAttribute('tabindex', anterior);
    } else {
      el.removeAttribute('tabindex');
    }
    el.removeAttribute('data-tabindex');
  });
}

function focarPrimeiro(panel) {
  const primeiro = panel.querySelector('input, select, textarea, button, a');
  if (primeiro) primeiro.focus();
}

// Inicialização geral da tela.
document.addEventListener('DOMContentLoaded', () => {
  dom.form = document.getElementById('agendamento-form');
  dom.tel = document.getElementById('telefone');
  dom.data = document.getElementById('data');
  dom.nome = document.getElementById('nome');
  dom.email = document.getElementById('email');
  dom.obs = document.getElementById('obs');
  dom.confirmar = document.getElementById('btn-confirmar');
  dom.sucesso = document.getElementById('sucesso');
  dom.steps = document.querySelector('.steps');
  dom.stepTitle = document.querySelector('.page-title');
  dom.stepTag = document.querySelector('.page-tag');
  dom.servicoErr = document.getElementById('servico-err');
  dom.horarioErr = document.getElementById('horario-err');
  dom.dataErr = document.getElementById('data-err');
  dom.nomeErr = document.getElementById('nome-err');
  dom.telErr = document.getElementById('tel-err');
  dom.emailErr = document.getElementById('email-err');
  dom.totalServicos = document.getElementById('total-servicos');
  dom.servicosGrid = document.getElementById('servicos-grid');
  dom.horariosGrid = document.getElementById('horarios-grid');
  dom.resServicos = document.getElementById('res-servicos');
  dom.resData = document.getElementById('res-data');
  dom.resHorario = document.getElementById('res-horario');
  dom.resNome = document.getElementById('res-nome');
  dom.resTelefone = document.getElementById('res-telefone');
  dom.resEmail = document.getElementById('res-email');
  dom.resTotal = document.getElementById('res-total');
  dom.sucNome = document.getElementById('suc-nome');
  dom.resumoCorpo = document.getElementById('resumo-corpo');
  dom.panel1 = document.getElementById('panel-1');
  dom.panels = Array.from(document.querySelectorAll('.step-panel'));
  dom.stepIndicators = Array.from(document.querySelectorAll('.step'));
  dom.stepLines = [
    document.getElementById('line-1'),
    document.getElementById('line-2'),
    document.getElementById('line-3'),
  ];

  // Renderiza os blocos repetitivos a partir dos arrays de dados.
  renderizarHorarios();
  renderizarServicos();
  renderizarResumo();
  void carregarServicosDaApi();

  const hoje = new Date();
  hoje.setHours(0, 0, 0, 0);

  const hojeStr = hoje.toISOString().split('T')[0];
  const dataMaxima = new Date(hoje);
  dataMaxima.setDate(dataMaxima.getDate() + DIAS_LIMITE_SEM_HORARIOS);
  const dataMaximaStr = dataMaxima.toISOString().split('T')[0];

  // Configura a janela permitida no próprio input para reforçar a validação.
  if (dom.data) {
    dom.data.min = hojeStr;
    dom.data.max = dataMaximaStr;

    dom.data.addEventListener('change', () => {
      atualizarFeedbackDataEHorarios();
    });
  }

  // Máscara simples de telefone para melhorar a digitação.
  if (dom.tel) {
    dom.tel.addEventListener('input', () => {
      let v = dom.tel.value.replace(/\D/g, '').slice(0, 11);
      if (v.length <= 10) {
        v = v.replace(/^(\d{2})(\d{4})(\d{0,4})/, '($1) $2-$3');
      } else {
        v = v.replace(/^(\d{2})(\d{5})(\d{0,4})/, '($1) $2-$3');
      }
      dom.tel.value = v;
    });
  }

  // Remove mensagens de erro assim que o usuário volta a editar o campo.
  [
    ['nome', dom.nome, dom.nomeErr],
    ['telefone', dom.tel, dom.telErr],
    ['email', dom.email, dom.emailErr],
    ['obs', dom.obs, null],
    ['data', dom.data, dom.dataErr],
  ].forEach(([id, inputEl, errorEl]) => {
    if (!inputEl) return;
    inputEl.addEventListener('keydown', () => {
      if (errorEl) limparErroDom(inputEl, errorEl);
      if (id === 'telefone') inputEl.classList.remove('input-error');
    });
  });

  // Usa delegação de eventos porque os cards são renderizados dinamicamente.
  dom.servicosGrid?.addEventListener('click', event => {
    const card = event.target.closest('[data-servico]');
    if (!card || !dom.servicosGrid.contains(card)) return;
    toggleServico(card);
  });

  dom.horariosGrid?.addEventListener('click', event => {
    const btn = event.target.closest('.horario-btn');
    if (!btn || btn.disabled || btn.classList.contains('indisponivel')) return;
    selecionarHorario(btn);
  });

  // Botões com data-step controlam a navegação entre etapas.
  document.querySelectorAll('[data-step]').forEach(btn => {
    btn.addEventListener('click', () => {
      const step = Number(btn.dataset.step);
      irParaStep(step);
    });
  });

  // Botão final de confirmação do agendamento.
  if (dom.confirmar) {
    dom.confirmar.addEventListener('click', confirmarAgendamento);
  }

  // Só a primeira etapa começa navegável por teclado.
  dom.panels.forEach(panel => {
    panel.id === 'panel-1' ? habilitarTab(panel) : desabilitarTab(panel);
  });
  focarPrimeiro(dom.panel1);
});

// Seleciona ou remove um serviço da lista atual.
function toggleServico(card) {
  const nome = card.dataset.nome;
  const preco = Number(card.dataset.preco);

  const jaSelecionado = estado.servicos.some(s => s.nome === nome);

  if (jaSelecionado) {
    estado.servicos = estado.servicos.filter(s => s.nome !== nome);
  } else {
    estado.servicos.push({ nome, preco });
  }

  sincronizarServicos();

  atualizarTotal();
  setVisibilidade(dom.servicoErr, false);
}

// Marca apenas um horário por vez.
function selecionarHorario(btn) {
  estado.horario = btn.dataset.horario;
  sincronizarHorario();
  setVisibilidade(dom.horarioErr, false);
}

// Etapa 1: nome, telefone e e-mail.
function validarStep1() {
  const nome = dom.nome.value.trim();
  const telefone = dom.tel.value.trim();
  const email = dom.email.value.trim();
  const emailInput = dom.email;

  let valido = true;

  limparErroDom(dom.nome, dom.nomeErr);
  limparErroDom(dom.tel, dom.telErr);
  limparErroDom(dom.email, dom.emailErr);

  if (!nome) {
    mostrarErroDom(dom.nome, dom.nomeErr);
    valido = false;
  }

  if (!telefone || telefone.length < 14) {
    mostrarErroDom(dom.tel, dom.telErr);
    valido = false;
  }

  if (email && !emailInput.checkValidity()) {
    mostrarErroDom(dom.email, dom.emailErr);
    valido = false;
  }

  return valido;
}

// Etapa 2: data e horário.
function validarStep2() {
  const dataValor = dom.data.value;
  let valido = true;

  if (dataAnteriorAHoje(dataValor) || !normalizarData(dataValor)) {
    setTexto(dom.dataErr, 'Data inválida.');

    mostrarErroDom(dom.data, dom.dataErr);
    estado.horario = null;
    sincronizarHorario();
    renderizarHorarios();
    valido = false;
    return valido;
  }

  if (dataSemHorarios(dataValor) || !dataValida(dataValor)) {
    limparErroDom(dom.data, dom.dataErr);
    setTexto(dom.horarioErr, 'Não há horários disponíveis para essa data.');
    setVisibilidade(dom.horarioErr, true);
    estado.horario = null;
    sincronizarHorario();
    renderizarHorarios();
    valido = false;
    return valido;
  }

  limparErroDom(dom.data, dom.dataErr);

  setTexto(dom.horarioErr, 'Selecione um horário');

  if (!estado.horario) {
    setVisibilidade(dom.horarioErr, true);
    valido = false;
  } else {
    setVisibilidade(dom.horarioErr, false);
  }

  return valido;
}

// Etapa 3: pelo menos um serviço precisa estar selecionado.
function validarStep3() {
  if (!estado.servicos.length) {
    setVisibilidade(dom.servicoErr, true);
    return false;
  }
  setVisibilidade(dom.servicoErr, false);
  return true;
}

// Navegação entre steps
function irParaStep(step) {
  if (step === 2 && !validarStep1()) return;
  if (step === 3 && !validarStep2()) return;
  if (step === 4 && !validarStep3()) return;

  if (step === 4) atualizarResumo();

  dom.panels.forEach(p => p.classList.remove('active'));
  const painelAtivo = document.getElementById(`panel-${step}`);
  painelAtivo.classList.add('active');

  // Atualiza TAB: só o painel ativo
  dom.panels.forEach(panel => {
    panel.id === `panel-${step}` ? habilitarTab(panel) : desabilitarTab(panel);
  });

  // Indicadores
  dom.stepIndicators.forEach((stepEl, index) => {
    const currentStep = index + 1;
    stepEl.classList.remove('active', 'done');
    if (currentStep < step) stepEl.classList.add('done');
    if (currentStep === step) stepEl.classList.add('active');
  });

  dom.stepLines.forEach((line, index) => {
    if (line) line.classList.toggle('done', index + 1 < step);
  });

  focarPrimeiro(painelAtivo);
  window.scrollTo({ top: 0, behavior: 'smooth' });
}

// Confirmação final (mock)
function confirmarAgendamento() {
  const nome = dom.nome.value.trim();

  // TODO: substituir pelo fetch para POST /agendamento quando o back-end estiver pronto

  dom.panels.forEach(p => p.classList.remove('active'));
  setVisibilidade(dom.steps, false);
  setVisibilidade(dom.stepTitle, false);
  setVisibilidade(dom.stepTag, false);

  setTexto(dom.sucNome, nome);
  dom.sucesso.classList.add('active');

  window.scrollTo({ top: 0, behavior: 'smooth' });
}
