class ApiEndpoints {
  ApiEndpoints._();

  static const String baseUrl = 'https://api.drhair.com/v1';
  static const int connectTimeout = 15000;
  static const int receiveTimeout = 15000;

  static const String services = '/services';
  static const String doctors = '/doctors';
  static const String profile = '/profile';
}
