import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiEndpoints {
  ApiEndpoints._();

  static const String baseUrl = 'https://api.drhair.com/v1';

  /// Returns the configured backend Base URL:
  /// Priority:
  /// 1. flutter_dotenv (.env file: DRHAIR_BACKEND_URL or API_BASE_URL)
  /// 2. dart-define flag (DRHAIR_BACKEND_URL)
  /// 3. Live production fallback (https://backend-ten-kappa-69.vercel.app)
  static String get backendBaseUrl {
    final envUrl = dotenv.env['DRHAIR_BACKEND_URL'] ?? dotenv.env['API_BASE_URL'];
    if (envUrl != null && envUrl.trim().isNotEmpty) {
      return envUrl.trim().replaceAll(RegExp(r'/+$'), '');
    }
    return const String.fromEnvironment(
      'DRHAIR_BACKEND_URL',
      defaultValue: 'https://backend-ten-kappa-69.vercel.app',
    ).replaceAll(RegExp(r'/+$'), '');
  }

  static const int connectTimeout = 15000;
  static const int receiveTimeout = 15000;

  static const String services = '/services';
  static const String doctors = '/doctors';
  static const String profile = '/profile';
}
