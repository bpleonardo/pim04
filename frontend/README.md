# Barbearia Flutter

## Fluxo mobile do barbeiro (Android/iOS)
Depois do login, o aplicativo nativo abre diretamente **Cortes de hoje**.
Mostra somente os atendimentos atribuídos ao funcionário do token, no dia atual
em America/Sao_Paulo, com cliente, horário, serviços, valor e status.
A única alteração oferecida é **Concluir corte**, com confirmação e atualização
pela API. Não há criação, cancelamento, catálogo ou dashboard nesse fluxo.
Concluídos e cancelados permanecem visíveis sem botão de conclusão.
É possível atualizar a lista e sair. Ao retornar do segundo plano, a lista é recarregada.
Não há confirmação offline; o fluxo não usa SQLite. A infraestrutura de cache de
serviços existente foi preservada e continua limitada a Android/iOS.

O roteamento diferencia a plataforma nativa; o Web continua no fluxo completo,
inclusive quando aberto no navegador de um celular. Windows/Web mantêm as funções
administrativas existentes. O projeto atual não contém o hospedeiro iOS; gerar e
compilar esse hospedeiro exige ambiente macOS/Xcode.

## API necessária
Recompile o backend depois desta alteração:
```powershell
cd C:\Users\sorte\pim04
docker compose -f docker-compose.yml -f resources/docker/docker-compose.dev.yml up -d --build backend
```
Novas rotas autenticadas:
- `GET /api/Agendamentos/meus/hoje`
- `PATCH /api/Agendamentos/meus/{id}/concluir`

A identidade vem do JWT validado pela API, não de um id escolhido na tela.
A conclusão exige proprietário correto, status agendado e data de hoje.
Registra status e data de conclusão numa operação condicional e rejeita repetição.
As rotas administrativas anteriores foram preservadas; as novas verificações de
propriedade são específicas destas duas rotas, não uma mudança global de papéis.

## Executar e validar
Na pasta frontend:
```powershell
flutter pub get
flutter analyze
flutter test
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8080
flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:8080
```
Ajuste o identificador conforme `flutter devices`. No celular físico, use o IP do
computador na mesma rede em `API_BASE_URL`; localhost aponta para o próprio celular.
No Windows, troque o destino por `-d windows`.
O Android tem permissão de internet e permite HTTP local somente no build debug.
Para distribuição, configure a API com HTTPS. O token continua apenas em memória.

## Organização
`lib/core`, `lib/data/api`, `lib/data/db`, `lib/data/repositories`, `lib/models`,
`lib/ui/telas`, `lib/main.dart`. As camadas do professor e o PostgreSQL da API
foram preservados. `test/cortes_dia_test.dart` verifica o novo fluxo e a separação
de plataformas; `test/widget_test.dart` verifica a tela inicial.
