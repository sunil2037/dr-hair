import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiEndpoints {
  ApiEndpoints._();

  static const String baseUrl = 'https://api.drhair.com/v1';

  /// Returns the configured backend Base URL:
  /// Priority:
  /// 1. dart-define flag (DRHAIR_BACKEND_URL), for explicit build overrides
  /// 2. flutter_dotenv (.env file: DRHAIR_BACKEND_URL or API_BASE_URL)
  /// 3. Live production fallback (https://backend-ten-kappa-69.vercel.app)
  static const String _buildBackendUrl = String.fromEnvironment(
    'DRHAIR_BACKEND_URL',
  );

  static String get backendBaseUrl {
    if (_buildBackendUrl.trim().isNotEmpty) {
      return _buildBackendUrl.trim().replaceAll(RegExp(r'/+$'), '');
    }

    final envUrl = dotenv.isInitialized
        ? (dotenv.env['DRHAIR_BACKEND_URL'] ?? dotenv.env['API_BASE_URL'])
        : null;
    if (envUrl != null && envUrl.trim().isNotEmpty) {
      return envUrl.trim().replaceAll(RegExp(r'/+$'), '');
    }
    return 'https://backend-ten-kappa-69.vercel.app';
  }

  static const int connectTimeout = 15000;
  static const int receiveTimeout = 15000;

  static const String services = '/services';
  static const String doctors = '/doctors';
  static const String profile = '/profile';
}
