import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stores the bearer token separately from ordinary, non-sensitive app cache.
class SecureSessionStore {
  static const String _tokenKey = 'dr_hair_session_token_v1';
  static const String _loginKey = 'dr_hair_session_login_v1';

  final FlutterSecureStorage _storage;

  SecureSessionStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  Future<String?> readToken() => _storage.read(key: _tokenKey);

  Future<String?> readLogin() => _storage.read(key: _loginKey);

  Future<void> writeSession({
    required String token,
    required String login,
  }) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _loginKey, value: login);
  }

  Future<void> clear() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _loginKey);
  }
}
