# Barbearia Flutter — SQLite apenas no mobile

Estrutura: `lib/core`, `lib/data/api`, `lib/data/db`, `lib/data/repositories`, `lib/models`, `lib/ui/telas`, `lib/main.dart`.

## Estratégia de persistência
- Android/iOS: cache de serviços em SQLite via `sqflite`, com fallback offline se houver dados armazenados.
- Windows/Web: acesso direto à API .NET,.
- PostgreSQL na API é a fonte oficial. Nenhum agendamento é confirmado offline.

## Execução
Na pasta do projeto:
```powershell
flutter pub get
flutter analyze
flutter test
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8080
```
Para Windows, use `-d windows`; para emulador Android use `-d emulator-5554` (ajuste conforme `flutter devices`) e `--dart-define=API_BASE_URL=http://10.0.2.2:8080`.

## Pendências importantes
- Verificar em execução os contratos reais dos DTOs e o formato das respostas HTTP, inclusive horário, token e status.
- JWT fica apenas em memória; falta armazenamento seguro e renovação de sessão.
- Autenticação do cliente ainda não confirmada; login atual é administrativo.
- CORS, permissões e validação JWT do back-end precisam de testes.
- Não foi executado build/teste Flutter neste ambiente.
- Build nativo iOS requer macOS/Xcode.
