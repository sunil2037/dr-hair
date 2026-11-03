import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'app_local_cache.dart';

abstract interface class AuthSessionStore {
  Future<String?> readToken();
  Future<String?> readLogin();
  Future<String?> readRefreshToken();
  Future<String?> readSessionId();

  Future<void> writeSession({
    required String token,
    required String login,
    String? refreshToken,
    String? sessionId,
  });

  Future<void> clear();
}

/// Stores the bearer token primarily in secure storage and mirrors the
/// authenticated session in Hive for reliable app bootstrap/web persistence.
class SecureSessionStore implements AuthSessionStore {
  static const String _tokenKey = 'dr_hair_session_token_v1';
  static const String _loginKey = 'dr_hair_session_login_v1';
  static const String _refreshTokenKey = 'dr_hair_refresh_token_v1';
  static const String _sessionIdKey = 'dr_hair_session_id_v1';

  final FlutterSecureStorage _storage;
  final AppLocalCache _cache;

  SecureSessionStore({FlutterSecureStorage? storage, AppLocalCache? cache})
    : _storage = storage ?? const FlutterSecureStorage(),
      _cache = cache ?? AppLocalCache.instance;

  Future<String?> readToken() async =>
      await _storage.read(key: _tokenKey) ??
      _cache.getString(_tokenKey);

  Future<String?> readLogin() async =>
      await _storage.read(key: _loginKey) ??
      _cache.getString(_loginKey);

  /// Hive mirrors the session so app bootstrap and web builds have a durable
  /// local record, while secure storage remains the preferred token store.
  Future<String?> readRefreshToken() async =>
      await _storage.read(key: _refreshTokenKey) ??
      _cache.getString(_refreshTokenKey);

  Future<String?> readSessionId() async =>
      await _storage.read(key: _sessionIdKey) ??
      _cache.getString(_sessionIdKey);

  Future<void> writeSession({
    required String token,
    required String login,
    String? refreshToken,
    String? sessionId,
  }) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _loginKey, value: login);
    await _cache.put(_tokenKey, token);
    await _cache.put(_loginKey, login);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await _storage.write(key: _refreshTokenKey, value: refreshToken);
      await _cache.put(_refreshTokenKey, refreshToken);
    } else {
      await _storage.delete(key: _refreshTokenKey);
      await _cache.remove(_refreshTokenKey);
    }
    if (sessionId != null && sessionId.isNotEmpty) {
      await _storage.write(key: _sessionIdKey, value: sessionId);
      await _cache.put(_sessionIdKey, sessionId);
    } else {
      await _storage.delete(key: _sessionIdKey);
      await _cache.remove(_sessionIdKey);
    }
  }

  Future<void> clear() async {
    await Future.wait([
      _storage.delete(key: _tokenKey),
      _storage.delete(key: _loginKey),
      _storage.delete(key: _refreshTokenKey),
      _storage.delete(key: _sessionIdKey),
      _cache.remove(_tokenKey),
      _cache.remove(_loginKey),
      _cache.remove(_refreshTokenKey),
      _cache.remove(_sessionIdKey),
    ]);
  }
}
