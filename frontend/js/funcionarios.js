
const API_BASE = '/api';

function uid() {
  try { return crypto.randomUUID(); } catch { return Date.now().toString(); }
}

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

function formatPhone(v) {
  const digits = v.replace(/\D/g, '').slice(0, 11);
  if (digits.length <= 10) return digits.replace(/^(\d{2})(\d{4})(\d{0,4})/, '($1) $2-$3').trim();
  return digits.replace(/^(\d{2})(\d{5})(\d{0,4})/, '($1) $2-$3').trim();
}

async function fetchFuncionarios() {
  const tbody = document.getElementById('funcionarios-body');
  tbody.innerHTML = '<tr><td colspan="4">Carregando...</td></tr>';

  try {
    const res = await fetch(`${API_BASE}/funcionarios`);
    if (!res.ok) throw new Error('Erro ao carregar funcionários');
    const payload = await res.json();
    const data = Array.isArray(payload?.data) ? payload.data : [];

    if (!data.length) {
      tbody.innerHTML = '<tr><td colspan="4">Nenhum funcionário cadastrado.</td></tr>';
      return;
    }

    tbody.innerHTML = data.map(f => `
      <tr>
        <td>${f.nome}</td>
        <td>${f.telefone || ''}</td>
        <td>${f.email || ''}</td>
        <td class="text-end"><a class="link-secondary" href="funcionarios.html">Perfil</a></td>
      </tr>
    `).join('');
  } catch (err) {
    tbody.innerHTML = '<tr><td colspan="4">Erro ao carregar funcionários.</td></tr>';
    console.error(err);
  }
}

document.addEventListener('DOMContentLoaded', () => {
  const modal = new bootstrap.Modal(document.getElementById('modalFuncionario'));
  const btnNew = document.getElementById('btn-new-func');
  const form = document.getElementById('funcionario-form');

  btnNew.addEventListener('click', () => modal.show());

  // máscara simples de telefone enquanto digita
  const telInput = form.querySelector('[name="telefone"]');
  if (telInput) {
    telInput.addEventListener('input', () => {
      telInput.value = formatPhone(telInput.value);
    });
  }

  form.addEventListener('submit', async (e) => {
    e.preventDefault();
    const fd = new FormData(form);
    const nome = fd.get('nome')?.toString().trim();
    const telefone = fd.get('telefone')?.toString().trim();
    const email = fd.get('email')?.toString().trim() || null;
    const endereco = fd.get('endereco')?.toString().trim();

    // validações
    form.querySelectorAll('.is-invalid').forEach(i => i.classList.remove('is-invalid'));
    if (!nome || nome.length < 3) {
      form.querySelector('[name="nome"]').classList.add('is-invalid');
      showToast('Nome deve ter ao menos 3 caracteres.', 'danger');
      return;
    }
    const telDigits = telefone.replace(/\D/g, '');
    if (!telDigits || telDigits.length < 10) {
      form.querySelector('[name="telefone"]').classList.add('is-invalid');
      showToast('Telefone inválido.', 'danger');
      return;
    }

    try {
      const res = await fetch(`${API_BASE}/funcionarios`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Nonce': uid(),
        },
        body: JSON.stringify({ nome, telefone, cpf: null, email, endereco })
      });

      if (res.status === 204) {
        modal.hide();
        form.reset();
        await fetchFuncionarios();
        showToast('Funcionário criado.', 'success');
        return;
      }

      const j = await res.json().catch(() => ({}));
      showToast(j?.error?.message || 'Falha ao criar funcionário', 'danger');
    } catch (err) {
      console.error(err);
      showToast('Erro ao criar funcionário', 'danger');
    }
  });

  void fetchFuncionarios();
});
