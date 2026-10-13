import '../config/api_config.dart';

class ApiClient {
  const ApiClient();

  String get baseUrl => ApiConfig.baseUrl;
  // Implementar requisições após definir tratamento de sessão e erros.
}
