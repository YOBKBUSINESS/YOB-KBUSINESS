class ApiConfig {
  ApiConfig._();

  // Change this for production
  static const String baseUrl = 'http://localhost:8080';
  static const String apiPath = '/api/v1';
  static String get apiUrl => '$baseUrl$apiPath';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
