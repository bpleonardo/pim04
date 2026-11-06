class ApiConfig {
  // Configure com --dart-define=API_BASE_URL=...
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );
}
