const sidebar = document.getElementById('sidebar');
const backdrop = document.getElementById('backdrop');
const menuToggle = document.getElementById('menuToggle');
const selectedDate = document.getElementById('selectedDate');
const prevDateButton = document.getElementById('prevDate');
const nextDateButton = document.getElementById('nextDate');
const agendaList = document.getElementById('agendaList');
const modal = document.getElementById('appointmentModal');
const modalBackdrop = document.getElementById('modalBackdrop');
const closeModalButton = document.getElementById('closeModal');
const modalBody = document.getElementById('modalBody');
const modalFooter = document.getElementById('modalFooter');
const filterButtons = Array.from(document.querySelectorAll('.status-filter'));

const estadoLabels = {
  pending: 'Pendente',
  done: 'Concluído',
  canceled: 'Cancelado',
};

const agendaMock = [
  { id: 1, cliente: 'Ana Lima', telefone: '(11) 98888-1001', servico: 'Corte de Cabelo', horario: '08:30', status: 'pending', total: 35 },
  { id: 2, cliente: 'Bruno Santos', telefone: '(11) 98888-1002', servico: 'Barba', horario: '09:00', status: 'done', total: 25 },
  { id: 3, cliente: 'Carla Souza', telefone: '(11) 98888-1003', servico: 'Sobrancelha', horario: '09:30', status: 'canceled', total: 15 },
  { id: 4, cliente: 'Diego Alves', telefone: '(11) 98888-1004', servico: 'Corte + Barba', horario: '10:00', status: 'pending', total: 55 },
  { id: 5, cliente: 'Fernanda Rocha', telefone: '(11) 98888-1005', servico: 'Corte de Cabelo', horario: '10:30', status: 'done', total: 35 },
  { id: 6, cliente: 'Gustavo Mendes', telefone: '(11) 98888-1006', servico: 'Barba', horario: '11:00', status: 'pending', total: 25 },
  { id: 7, cliente: 'Helena Costa', telefone: '(11) 98888-1007', servico: 'Sobrancelha', horario: '11:30', status: 'done', total: 15 },
  { id: 8, cliente: 'Igor Almeida', telefone: '(11) 98888-1008', servico: 'Corte de Cabelo', horario: '13:00', status: 'canceled', total: 35 },
  { id: 9, cliente: 'Juliana Ferreira', telefone: '(11) 98888-1009', servico: 'Corte + Barba', horario: '13:30', status: 'pending', total: 55 },
  { id: 10, cliente: 'Kevin Martins', telefone: '(11) 98888-1010', servico: 'Barba', horario: '14:00', status: 'done', total: 25 },
  { id: 11, cliente: 'Larissa Nunes', telefone: '(11) 98888-1011', servico: 'Sobrancelha', horario: '15:00', status: 'pending', total: 15 },
  { id: 12, cliente: 'Marcos Vinicius', telefone: '(11) 98888-1012', servico: 'Corte de Cabelo', horario: '16:00', status: 'canceled', total: 35 },
];

let dataAtual = new Date();
let filtroAtual = 'all';
let agendamentoSelecionadoId = null;

function normalizarData(data) {
  const ano = data.getFullYear();
  const mes = String(data.getMonth() + 1).padStart(2, '0');
  const dia = String(data.getDate()).padStart(2, '0');
  return `${ano}-${mes}-${dia}`;
}

function formatarData(data) {
  return data.toLocaleDateString('pt-BR', {
    weekday: 'long',
    day: 'numeric',
    month: 'long',
    year: 'numeric',
  });
}

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

function obterAgendamentosFiltrados() {
  if (filtroAtual === 'all') {
    return agendaMock;
  }

  return agendaMock.filter((agendamento) => agendamento.status === filtroAtual);
}

function badgeClass(status) {
  return `status-badge status-${status}`;
}

function renderizarLista() {
  const itens = obterAgendamentosFiltrados();

  if (!itens.length) {
    agendaList.innerHTML = '<div class="empty-state">Nenhum agendamento encontrado para este filtro.</div>';
    return;
  }

  agendaList.innerHTML = itens
    .map(
      (agendamento) => `
        <button class="appointment-card" type="button" data-id="${agendamento.id}">
          <div class="appointment-time">${agendamento.horario}</div>
          <div class="appointment-divider"></div>
          <div class="appointment-main">
            <span class="appointment-client">${agendamento.cliente}</span>
            <span class="appointment-service">${agendamento.servico}</span>
          </div>
          <div class="appointment-price">R$ ${agendamento.total.toFixed(2).replace('.', ',')}</div>
          <div class="appointment-status">
            <span class="${badgeClass(agendamento.status)}">${estadoLabels[agendamento.status]}</span>
          </div>
        </button>
      `,
    )
    .join('');
}

function definirFiltro(novoFiltro) {
  filtroAtual = novoFiltro;
  filterButtons.forEach((botao) => {
    botao.classList.toggle('active', botao.dataset.filter === novoFiltro);
  });
  renderizarLista();
}

function encontrarAgendamento(id) {
  return agendaMock.find((agendamento) => agendamento.id === id);
}

function abrirModal(agendamento) {
  agendamentoSelecionadoId = agendamento.id;

  modalBody.innerHTML = `
    <div class="modal-detail"><span class="modal-detail-label">Cliente</span><span class="modal-detail-value">${agendamento.cliente}</span></div>
    <div class="modal-detail"><span class="modal-detail-label">Telefone</span><span class="modal-detail-value">${agendamento.telefone}</span></div>
    <div class="modal-detail"><span class="modal-detail-label">Serviço</span><span class="modal-detail-value">${agendamento.servico}</span></div>
    <div class="modal-detail"><span class="modal-detail-label">Horário</span><span class="modal-detail-value">${agendamento.horario}</span></div>
    <div class="modal-detail"><span class="modal-detail-label">Status</span><span class="modal-detail-value">${estadoLabels[agendamento.status]}</span></div>
    <div class="modal-detail"><span class="modal-detail-label">Total</span><span class="modal-detail-value">R$ ${agendamento.total.toFixed(2).replace('.', ',')}</span></div>
  `;

  if (agendamento.status === 'pending') {
    modalFooter.innerHTML = `
      <button class="modal-btn modal-btn-cancel" type="button" data-action="cancel">Cancelar</button>
      <button class="modal-btn modal-btn-complete" type="button" data-action="complete">Concluir</button>
    `;
  } else {
    modalFooter.innerHTML = '';
  }

  modal.classList.add('open');
  modal.setAttribute('aria-hidden', 'false');
}

function fecharModal() {
  modal.classList.remove('open');
  modal.setAttribute('aria-hidden', 'true');
  agendamentoSelecionadoId = null;
}

function atualizarStatus(novoStatus) {
  const agendamento = encontrarAgendamento(agendamentoSelecionadoId);

  if (!agendamento) {
    fecharModal();
    return;
  }

  agendamento.status = novoStatus;
  fecharModal();
  renderizarLista();
}

function manipularCliqueLista(evento) {
  const botao = evento.target.closest('.appointment-card');

  if (!botao) {
    return;
  }

  const agendamento = encontrarAgendamento(Number(botao.dataset.id));

  if (agendamento) {
    abrirModal(agendamento);
  }
}

function mudarData(deltaDias) {
  const novaData = new Date(dataAtual);
  novaData.setDate(novaData.getDate() + deltaDias);
  dataAtual = novaData;
  selectedDate.textContent = formatarData(dataAtual);
  renderizarLista();
}

// TODO: integrar com GET /agendamentos?data=X e PATCH /agendamentos/:id
selectedDate.textContent = formatarData(dataAtual);
renderizarLista();

menuToggle.addEventListener('click', alternarMenu);
backdrop.addEventListener('click', fecharMenu);
prevDateButton.addEventListener('click', () => mudarData(-1));
nextDateButton.addEventListener('click', () => mudarData(1));
filterButtons.forEach((botao) => {
  botao.addEventListener('click', () => definirFiltro(botao.dataset.filter));
});
agendaList.addEventListener('click', manipularCliqueLista);
modalBackdrop.addEventListener('click', fecharModal);
closeModalButton.addEventListener('click', fecharModal);
modalFooter.addEventListener('click', (evento) => {
  const actionButton = evento.target.closest('[data-action]');

  if (!actionButton) {
    return;
  }

  if (actionButton.dataset.action === 'complete') {
    atualizarStatus('done');
  }

  if (actionButton.dataset.action === 'cancel') {
    atualizarStatus('canceled');
  }
});

window.addEventListener('resize', () => {
  if (window.innerWidth > 900) {
    fecharMenu();
  }
});
