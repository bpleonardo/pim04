const sidebar = document.getElementById('sidebar');
const backdrop = document.getElementById('backdrop');
const menuToggle = document.getElementById('menuToggle');
const currentDate = document.getElementById('currentDate');

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

// TODO: integrar com GET /dashboard quando back-end estiver pronto
currentDate.textContent = new Date().toLocaleDateString('pt-BR', {
  weekday: 'long',
  day: 'numeric',
  month: 'long',
  year: 'numeric',
});

menuToggle.addEventListener('click', alternarMenu);
backdrop.addEventListener('click', fecharMenu);

window.addEventListener('resize', () => {
  if (window.innerWidth > 900) {
    fecharMenu();
  }
});
