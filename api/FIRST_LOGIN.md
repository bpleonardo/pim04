# Cadastro e primeiro acesso de funcionários

O painel Flutter mantém os dados pessoais na primeira etapa e solicita login e senha inicial na segunda. Somente ao salvar a segunda etapa ele envia `POST /api/funcionarios`, com os campos pessoais existentes, `login` e `initialPassword`. A API exige as credenciais para novos cadastros e grava funcionário e conta na mesma transação; um login duplicado retorna `409 LOGIN_ALREADY_EXISTS`, sem deixar funcionário órfão. A edição de dados pessoais continua sem modificar as credenciais.

A migração `RequireInitialPasswordChange` adiciona `Usuarios.password_expired`. As contas já existentes recebem `false`, preservando o acesso. As contas cadastradas pelo painel recebem `true`. Esse campo não pode ser definido pelo cliente.

1. `POST /api/login` recebe `login` e `senha`. Senha incorreta retorna `401 INVALID_CREDENTIALS`. Credenciais corretas com senha inicial pendente retornam `403 PASSWORD_CHANGE_REQUIRED`, sem access token, refresh token ou sessão criada.
2. O Flutter exibe os campos de nova senha e confirmação. A nova senha deve ter de 6 a 128 caracteres e ser diferente da inicial.
3. `POST /api/login/initial-password` recebe `login`, `senha` (inicial) e `newPassword`. Não exige JWT, pois nenhum foi emitido, mas verifica novamente as credenciais e o estado da conta. A atualização é condicional: apenas uma tentativa concorrente consegue substituir a senha inicial. O endpoint também invalida sessões de refresh preexistentes e responde `204`, sem emitir tokens.
4. O Flutter autentica novamente usando a nova senha. Só então a API emite os tokens e o aplicativo salva a sessão pelo mecanismo existente. A senha inicial deixa de funcionar; o endpoint de primeiro acesso não pode ser reutilizado após a troca.

O refresh também recusa contas com `password_expired=true` e funcionários excluídos. Novas senhas são armazenadas com `PasswordHasher<Usuario>` do ASP.NET Core (hash com salt). As contas legadas continuam compatíveis e sua senha é convertida para hash após autenticação bem-sucedida. Nenhuma senha faz parte das respostas ou do cache SQLite.

O cadastro e a definição inicial da senha precisam de conexão. Depois do primeiro acesso concluído, o funcionamento offline no Android/iOS continua seguindo `frontend/OFFLINE.md`.

## Validação

- Testes Flutter: `flutter test test/employees_screen_test.dart test/initial_password_test.dart`.
- Integração PostgreSQL: configure `PIM_TEST_DB_CONNECTION` para um banco **descartável**, com nome iniciado por `pim_auth_test_`, e execute `dotnet run --project resources/tests/InitialPasswordChecks`. O teste aplica as migrações, verifica cadastro atômico, login duplicado, bloqueio antes da troca, senha incorreta/curta/igual, concorrência, persistência, refresh e compatibilidade legada, removendo os registros fictícios ao terminar.
- Para conferir manualmente: cadastre um funcionário; entre com a senha inicial; verifique a exigência de troca; defina outra senha; saia; confira que somente a nova senha funciona.

Reinicie a API para aplicar a migração pelo fluxo já existente de inicialização. Para execução com Docker em desenvolvimento, use `task start:api`. Reabra o Flutter para carregar as novas telas.
