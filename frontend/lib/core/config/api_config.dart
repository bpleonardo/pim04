class ApiConfig {
  // Configure em tempo de execução com --dart-define=API_BASE_URL=...
  static const baseUrl = String.fromEnvironment('API_BASE_URL');
}
