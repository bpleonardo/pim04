const API_BASE = '/fake-api';

function showToast(message, type = 'info', ttl = 4000) {
  const container = document.getElementById('toast-container');
  if (!container) return;

  const toastEl = document.createElement('div');
  toastEl.className = `toast align-items-center text-bg-${type} border-0`;
  toastEl.setAttribute('role', 'alert');
  toastEl.setAttribute('aria-live', 'assertive');
  toastEl.setAttribute('aria-atomic', 'true');
  toastEl.innerHTML = `
    <div class="d-flex">
      <div class="toast-body">${message}</div>
      <button type="button" class="btn-close btn-close-white me-2 m-auto" data-bs-dismiss="toast" aria-label="Fechar"></button>
    </div>
  `;

  container.appendChild(toastEl);
  const bsToast = new bootstrap.Toast(toastEl, { delay: ttl });
  bsToast.show();
  toastEl.addEventListener('hidden.bs.toast', () => toastEl.remove());
}

function uid() {
  try { return crypto.randomUUID(); } catch { return Date.now().toString(); }
}

async function fetchServicos() {
  const tbody = document.getElementById('servicos-body');
  tbody.innerHTML = '<tr><td colspan="4">Carregando...</td></tr>';

  try {
    const res = await fetch(`${API_BASE}/servicos`);
    if (!res.ok) throw new Error('Erro ao carregar serviços');
    const payload = await res.json();
    const data = Array.isArray(payload?.data) ? payload.data : [];

    if (!data.length) {
      tbody.innerHTML = '<tr><td colspan="4">Nenhum serviço cadastrado.</td></tr>';
      return;
    }

    tbody.innerHTML = data.map(s => `
      <tr>
        <td>${s.nome}</td>
        <td>${s.descricao || ''}</td>
        <td>R$ ${Number(s.preco).toFixed(2).replace('.', ',')}</td>
        <td class="text-end"><a class="link-secondary" href="servicos.html">Editar</a> &nbsp; <a class="link-danger" href="#" data-id="${s.id}" data-delete>Excluir</a></td>
      </tr>
    `).join('');
  } catch (err) {
    tbody.innerHTML = '<tr><td colspan="4">Erro ao carregar serviços.</td></tr>';
    console.error(err);
  }
}

document.addEventListener('DOMContentLoaded', () => {
  const modal = new bootstrap.Modal(document.getElementById('modalServicos'));
  const btnNew = document.getElementById('btn-new');
  const form = document.getElementById('servico-form');

  btnNew.addEventListener('click', () => modal.show());

  form.addEventListener('submit', async (e) => {
    e.preventDefault();
    const fd = new FormData(form);
    const nome = fd.get('nome')?.toString().trim();
    const descricao = fd.get('descricao')?.toString().trim() || null;
    const preco = Number(fd.get('preco')) || 0;

    // validações simples
    form.querySelectorAll('.is-invalid').forEach(i => i.classList.remove('is-invalid'));
    if (!nome || nome.length < 3) {
      form.querySelector('[name="nome"]').classList.add('is-invalid');
      showToast('Nome do serviço deve ter ao menos 3 caracteres.', 'danger');
      return;
    }
    if (!(preco > 0)) {
      form.querySelector('[name="preco"]').classList.add('is-invalid');
      showToast('Preço deve ser maior que zero.', 'danger');
      return;
    }

    try {
      const res = await fetch(`${API_BASE}/servicos`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Nonce': uid(),
        },
        body: JSON.stringify({ nome, descricao, preco })
      });

      if (res.status === 204) {
        modal.hide();
        form.reset();
        await fetchServicos();
        showToast('Serviço criado com sucesso.', 'success');
        return;
      }

      const j = await res.json().catch(() => ({}));
      showToast(j?.error?.message || 'Falha ao criar serviço', 'danger');
    } catch (err) {
      console.error(err);
      showToast('Erro ao criar serviço', 'danger');
    }
  });

  // Delegação para exclusão (não implementa confirmação complexa)
  document.getElementById('servicos-body').addEventListener('click', async (ev) => {
    const a = ev.target.closest('[data-delete]');
    if (!a) return;
    ev.preventDefault();
    const id = a.dataset.id;
    if (!confirm('Excluir este serviço?')) return;
    try {
      const res = await fetch(`${API_BASE}/servicos/${id}`, { method: 'DELETE' });
      if (res.status === 204) {
        await fetchServicos();
        showToast('Serviço excluído.', 'success');
      } else {
        const j = await res.json().catch(() => ({}));
        showToast(j?.error?.message || 'Falha ao excluir', 'danger');
      }
    } catch (err) {
      console.error(err);
      showToast('Erro ao excluir', 'danger');
    }
  });

  void fetchServicos();
});
