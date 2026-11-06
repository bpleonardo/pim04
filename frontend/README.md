# Barbearia Flutter

## Fluxo mobile do barbeiro (Android/iOS)
Depois do login, o aplicativo nativo abre diretamente **Cortes de hoje**.
Mostra somente os atendimentos atribuídos ao funcionário do token, no dia atual
em America/Sao_Paulo, com cliente, horário, serviços, valor e status.
A ação **Concluir corte** pede confirmação e registra a alteração em SQLite
antes de enviá-la à API. Se a conexão falhar, a tela mostra a agenda salva
e indica a conclusão pendente. As pendências ficam separadas por funcionário
e endereço da API. O app tenta sincronizá-las ao atualizar, ao voltar ao
primeiro plano e a cada 30 segundos enquanto houver pendências na tela.
Uma conclusão recusada pela API aparece como falha para conferência.

O roteamento diferencia a plataforma nativa; o Web continua no fluxo completo,
inclusive quando aberto no navegador de um celular. Windows/Web mantêm as funções
administrativas de consulta e criação. A edição de status exige que o usuário seja responsável pelo agendamento. O projeto atual não contém o hospedeiro iOS; gerar e
compilar esse hospedeiro exige ambiente macOS/Xcode.

## API necessária
Defina `JWT_KEY` no `.env` da raiz com uma chave aleatória de pelo menos 32 bytes.
A mesma chave é usada para assinar e validar o JWT. A configuração de desenvolvimento
repassa a variável ao backend. Recompile a API após a alteração.

```powershell
docker compose -f docker-compose.yml -f resources/docker/docker-compose.dev.yml up -d --build backend
```

- `GET /api/agendamentos?date=AAAA-MM-DD&mine=true` lista os agendamentos do usuário autenticado.
- `GET /api/agendamentos/{id}` consulta um agendamento. A flag `mine` também pode ser usada nesse caminho.
- `mine=false` ou a ausência da flag mantém a listagem geral.
- `PATCH /api/agendamentos/{id}` atualiza o status somente se o usuário for responsável pelo agendamento. A repetição de uma conclusão já aceita retorna sucesso, preservando a data registrada.

A API registra a hora da conclusão quando recebe a alteração. A fila pode
sincronizar conclusões de dias anteriores.

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
`lib/ui/screens`, `lib/main.dart`. As camadas do professor e o PostgreSQL da API
foram preservados. `test/daily_appointments_test.dart` verifica o novo fluxo e a separação
de plataformas; `test/widget_test.dart` verifica a tela inicial.
