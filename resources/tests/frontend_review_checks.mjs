import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import vm from 'node:vm';

const source = readFileSync(new URL('../../front_web/js/agendamento.js', import.meta.url), 'utf8');
function page(fetch, timers = globalThis) {
  const context = vm.createContext({
    document: { addEventListener() {} }, console, fetch, AbortController, URLSearchParams,
    setTimeout: timers.setTimeout.bind(timers), clearTimeout: timers.clearTimeout.bind(timers),
  });
  vm.runInContext(source, context);
  return context;
}
const httpError = page(async () => ({ ok: false, status: 409, json: async () => ({ error: 'Horário indisponível.' }) }));
await assert.rejects(vm.runInContext("requestJson('/agendamentos')", httpError), error => error.status === 409 && error.message === 'Horário indisponível.');

let deadline;
let cleared = false;
const timeoutPage = page((_, { signal }) => new Promise((resolve, reject) => {
  signal.addEventListener('abort', () => reject(new Error('Aborted')));
}), { setTimeout(callback) { deadline = callback; return 1; }, clearTimeout() { cleared = true; } });
const timedRequest = vm.runInContext("requestJson('/servicos')", timeoutPage);
deadline();
await assert.rejects(timedRequest, /demorou para responder/);
assert.ok(cleared, 'O temporizador precisa ser limpo.');

const replies = [];
const racing = page(() => new Promise(resolve => replies.push(resolve)));
vm.runInContext(`
  renderizarHorarios = () => {};
  atualizarFeedbackDataEHorarios = () => {};
  bloquearHorariosPorData = () => false;
  dom.data = { value: '2099-11-15' };
  dom.funcionario = { value: 'barber-a' };
  dom.horarioErr = { style: {}, textContent: '' };
`, racing);
const previous = vm.runInContext("carregarHorarios('2099-11-15')", racing);
vm.runInContext("dom.funcionario.value = 'barber-b'", racing);
const latest = vm.runInContext("carregarHorarios('2099-11-15')", racing);
const response = slot => ({ ok: true, json: async () => ({ data: [{ slot, available: true }] }) });
replies[1](response('11:00'));
await latest;
replies[0](response('10:00'));
await previous;
assert.equal(vm.runInContext('horarios[0].hora', racing), '11:00', 'Resposta antiga substituiu os horários do barbeiro atual.');

const validation = page(async () => ({ ok: true, json: async () => ({}) }));
vm.runInContext(`
  const field = value => ({ value, classList: { add() {}, remove() {} } });
  dom.nome = field('Cliente');
  dom.tel = field('(11) 9999-9999');
  dom.email = { ...field(''), checkValidity: () => true };
  dom.nomeErr = { style: {} };
  dom.telErr = { style: {} };
  dom.emailErr = { style: {} };
  if (validarStep1()) throw new Error('Telefone de 10 dígitos foi aceito.');
  dom.tel.value = '(11) 99999-9999';
  if (!validarStep1()) throw new Error('Telefone de 11 dígitos foi rejeitado.');
`, validation);
console.log('PASS: mensagens da API, timeout com liberação e resposta antiga ao trocar profissional.');
