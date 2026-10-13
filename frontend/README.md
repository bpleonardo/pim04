# Barbearia — Flutter starter

Estrutura inicial com tema preto e branco, roteamento e tela visual de login. **O login ainda não envia requisições nem autentica usuários.**

## Como iniciar

1. Instale o Flutter SDK e habilite as plataformas desejadas.
2. Na pasta deste projeto, execute `flutter create --platforms=android,web,windows .` (no macOS, acrescente `ios,macos` conforme necessário).
3. Execute `flutter pub get`.
4. Execute `flutter run -d chrome` ou `flutter run -d windows`.

Para configurar a URL da API futuramente, execute com `--dart-define=API_BASE_URL=http://localhost:5000` (substitua pela URL real).

O endpoint confirmado de login da API é `POST /api/Login`, com `Login` e `Senha`. O tratamento do token, autenticação e controle de acesso serão feitos na etapa seguinte.

**Atenção:** a pasta `flutter create` gera arquivos nativos; este pacote contém apenas o código inicial compartilhado.
