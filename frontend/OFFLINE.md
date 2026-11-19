# Uso offline no mobile

O modo offline é exclusivo do Android/iOS. Windows e Web continuam usando a API, sem SQLite.

## Primeiro login e sessão

Faça um novo login com internet na versão atualizada. O app prepara a agenda de hoje, serviços e grade de horários. Se a preparação falhar, apresenta um aviso: atualize a agenda com conexão antes de desconectar. Outros dias e períodos de indicadores precisam ser consultados online ao menos uma vez.

Access token, refresh token e identificação do usuário ficam no armazenamento seguro do sistema, via [flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage/versions/9.2.4). A senha não é salva. Credenciais não ficam no SQLite nem no arquivo de configuração da API.

Ao reabrir, a sessão é restaurada sem consultar a API, usando os dados salvos. Ao reconectar, a autenticação do servidor continua obrigatória. Refresh token expirada ou revogada exige novo login; a fila local é preservada para o mesmo usuário e endereço da API. Sair offline remove a sessão local; a revogação remota não pode ocorrer sem conexão.

## Recursos disponíveis

- Consultar dias de agenda já carregados e registros criados localmente.
- Criar agendamentos para o próprio barbeiro, com cliente, telefone, serviços e horário futuro.
- Editar dados e serviços de agendamentos pendentes. Remarcar exige horário futuro; corrigir dados pode manter o horário original de um agendamento antigo.
- Alterar status, concluir e cancelar, com aviso de alteração local pendente.
- Consultar serviços salvos. Criar, editar, desabilitar e excluir serviços ficam bloqueados offline.
- Consultar indicadores de períodos já carregados, com aviso de dados possivelmente desatualizados.

A grade offline mostra horários previstos de funcionamento, não reservas confirmadas. A API confere disponibilidade, serviços ativos e preços ao sincronizar. Uma data nunca consultada não ganha uma agenda fictícia: o app informa a falta de dados, mas permite abrir o cadastro com os serviços salvos.

## Fila e conflitos

Cada criação, edição ou status é salvo primeiro no SQLite, em ordem, com um Nonce persistente por requisição. A sincronização é tentada ao salvar, atualizar a agenda, voltar ao app e em verificações a cada 30 segundos com a agenda montada e o app ativo. Não há execução garantida com o app fechado pelo sistema.

Falta de rede, timeout, HTTP 408, 429 e falhas 5xx mantêm a operação pendente. Ao restaurar a sessão, o cache permite abrir o app antes da verificação da conexão. Na primeira falha ainda desconhecida, uma chamada pode aguardar o timeout de até 15 segundos.

A API persiste um identificador único de criação (clientRequestId), além do cache Redis de Nonce. Assim, perder a resposta de uma criação não cria outro agendamento ao reenviar. Edições e status levam expectedRevision; cada alteração aceita incrementa a revisão. A última mutação aceita também é identificada no banco para reconhecer seu reenvio.

Criações offline levam recordedAt. Somente um barbeiro autenticado cadastrando para si pode usá-lo. A API aceita registros dos últimos sete dias e exige que o horário fosse futuro no momento do cadastro. Isso permite sincronizar depois do horário do atendimento sem liberar cadastros anônimos retroativos. A disponibilidade também é verificada dentro de uma transação serializada por funcionário.

Horário ocupado, serviço desabilitado e revisão desatualizada geram conflito, preservando os dados e o motivo. Operações posteriores do mesmo agendamento aguardam a resolução. A lista **Alterações locais** mostra datas e conflitos. No cartão:

- **Resolver** abre a revisão dos dados e do horário. Para conflito de status, mostra o estado atual do servidor e pede confirmação antes de reaplicar apenas o status local, mantendo os outros dados do servidor.
- **Descartar alteração local** pede confirmação e mantém os dados do servidor; uma criação recusada é removida somente do aparelho.

Nada é sobrescrito automaticamente em caso de conflito. Resolver uma edição/status de um cadastro existente exige conexão para conferir a revisão atual.

## Arquivos e banco

- `lib/core/storage/app_database.dart`: criação e migração do SQLite para versão 6.
- `lib/core/storage/offline_store.dart`: cache por endereço da API e usuário.
- `lib/features/appointments/data/offline_booking_repository.dart`: fila, reenvio, vínculo de IDs locais/remotos e apresentação das alterações locais.
- `lib/features/appointments/data/appointment_repository.dart`: agenda salva, indicadores e status; preserva a fila anterior de conclusões.
- `lib/features/appointments/presentation/agendamento_screen.dart`: cadastro e edição.
- `lib/features/appointments/presentation/cortes_dia_screen.dart`: agenda, avisos, sincronização e conflitos.
- `lib/core/network/api_client.dart`: sessão segura, renovação de token e erros de conexão.
- `../api/Migrations/20261113120000_AddOfflineAppointments.cs`: identificadores de reenvio e revisão no PostgreSQL.

O arquivo continua sendo barbearia_cache.db, na pasta privada de bancos do aplicativo. As tabelas novas são offline_cache, pending_appointments e appointment_links. As tabelas anteriores são preservadas. A fila armazena os dados de envio, a prévia visual, nonce, estado e erro; não armazena senha nem tokens.

## Atualizar e testar

Na raiz, execute `task start:api`. A API atualizada aplica a migração PostgreSQL na inicialização. Pare completamente o app antes de reconstruir: foi acrescentado um plugin nativo.

Em frontend:

```powershell
flutter pub get
flutter run
```

1. Escolha o celular físico, faça login online e aguarde a agenda carregar.
2. Consulte outros dias e períodos de indicadores que deseja acessar offline.
3. Ative modo avião, feche e reabra. Confira a sessão restaurada.
4. Crie um agendamento futuro, edite dados e altere um status. Confira os avisos e o catálogo sem edição habilitada.
5. Reabra novamente: a fila deve permanecer.
6. Reconecte com o app aberto. Aguarde a verificação periódica ou puxe a agenda para atualizar.
7. Para conflito de criação, reserve pela Web o mesmo horário/funcionário antes de reconectar. Confira que o mobile preserva os dados e oferece revisão.
8. Para conflito de edição, altere no servidor o mesmo agendamento antes de sincronizar o aparelho. A edição offline deve ser recusada por revisão desatualizada.

Verificações automatizadas:

```powershell
# Em frontend:
flutter analyze
flutter test
flutter build web --base-href /admin/

# Na raiz:
dotnet run --project resources/tests/OfflineContractChecks
```

Os testes SQLite usam arquivos temporários reais no PC, sem emulador. O verificador .NET confere modelo, migração e regras de registro/autenticação sem usar o banco de produção. Esses testes não substituem a integração com PostgreSQL nem a conferência do armazenamento seguro em um aparelho físico.
