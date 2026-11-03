import 'package:dio/dio.dart';
import 'package:dr_hair/core/storage/app_local_cache.dart';
import 'package:dr_hair/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:dr_hair/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:dr_hair/core/storage/secure_session_store.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSessionStore implements AuthSessionStore {
  String? token;
  String? login;
  String? refreshToken;
  String? sessionId;
  bool cleared = false;

  @override
  Future<String?> readToken() async => token;

  @override
  Future<String?> readLogin() async => login;

  @override
  Future<String?> readRefreshToken() async => refreshToken;

  @override
  Future<String?> readSessionId() async => sessionId;

  @override
  Future<void> writeSession({
    required String token,
    required String login,
    String? refreshToken,
    String? sessionId,
  }) async {
    this.token = token;
    this.login = login;
    this.refreshToken = refreshToken;
    this.sessionId = sessionId;
  }

  @override
  Future<void> clear() async {
    token = null;
    login = null;
    refreshToken = null;
    sessionId = null;
    cleared = true;
  }
}

class _FakeSecretStorage implements SessionSecretStorage {
  final values = <String, String>{};

  @override
  Future<String?> read({required String key}) async => values[key];

  @override
  Future<void> write({required String key, required String value}) async {
    values[key] = value;
  }

  @override
  Future<void> delete({required String key}) async {
    values.remove(key);
  }
}

void main() {
  test('session token is mirrored to Hive and removed on logout', () async {
    final cache = AppLocalCache.inMemory();
    final store = SecureSessionStore(
      storage: _FakeSecretStorage(),
      cache: cache,
    );

    await store.writeSession(
      token: 'access-1',
      login: '9876543210',
      refreshToken: 'refresh-1',
      sessionId: 'ses-1',
    );
    expect(cache.getString('dr_hair_session_token_v1'), 'access-1');
    expect(cache.getString('dr_hair_refresh_token_v1'), 'refresh-1');

    await store.clear();
    expect(cache.getString('dr_hair_session_token_v1'), isNull);
    expect(cache.getString('dr_hair_refresh_token_v1'), isNull);
  });

  test(
    'OTP verification stores access and refresh session credentials',
    () async {
      final store = _FakeSessionStore();
      final dio = Dio(BaseOptions(baseUrl: 'https://backend.test'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) => handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              statusCode: 200,
              data: const {
                'status': 'success',
                'token': 'access-1',
                'refresh_token': 'refresh-1',
                'session_id': 'ses-1',
                'is_registered': true,
                'next_step': 'HOME',
                'data': {
                  'id': 12,
                  'name': 'Test Patient',
                  'phone': '9876543210',
                },
              },
            ),
          ),
        ),
      );

      final repository = AuthRepositoryImpl(
        remote: AuthRemoteDataSource(dio: dio),
        sessionStore: store,
      );

      final result = await repository.verifyOtp(
        login: '9876543210',
        otp: '123456',
      );

      expect(result.user?.patientId, 'DHP0012');
      expect(store.token, 'access-1');
      expect(store.refreshToken, 'refresh-1');
      expect(store.sessionId, 'ses-1');
    },
  );

  test(
    'expired access token is rotated before splash session validation',
    () async {
      final store = _FakeSessionStore()
        ..token = 'expired-access'
        ..login = '9876543210'
        ..refreshToken = 'refresh-1'
        ..sessionId = 'ses-1';
      final dio = Dio(BaseOptions(baseUrl: 'https://backend.test'));
      var sessionCalls = 0;
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path == '/api/v1/auth/session' && sessionCalls++ == 0) {
              handler.reject(
                DioException(
                  requestOptions: options,
                  response: Response(requestOptions: options, statusCode: 401),
                ),
              );
              return;
            }
            if (options.path == '/api/v1/auth/refresh') {
              handler.resolve(
                Response<Map<String, dynamic>>(
                  requestOptions: options,
                  statusCode: 200,
                  data: const {
                    'status': 'success',
                    'token': 'access-2',
                    'refresh_token': 'refresh-2',
                    'session_id': 'ses-1',
                  },
                ),
              );
              return;
            }
            handler.resolve(
              Response<Map<String, dynamic>>(
                requestOptions: options,
                statusCode: 200,
                data: const {
                  'status': 'success',
                  'data': {
                    'login': '9876543210',
                    'is_registered': true,
                    'is_admin': false,
                    'next_step': 'HOME',
                    'user': {
                      'id': 12,
                      'name': 'Test Patient',
                      'phone': '9876543210',
                    },
                  },
                },
              ),
            );
          },
        ),
      );

      final repository = AuthRepositoryImpl(
        remote: AuthRemoteDataSource(dio: dio),
        sessionStore: store,
      );

      final result = await repository.restoreSession();

      expect(result?.token, 'access-2');
      expect(store.token, 'access-2');
      expect(store.refreshToken, 'refresh-2');
    },
  );

  test('logout revokes remotely and clears the local session', () async {
    final store = _FakeSessionStore()
      ..token = 'access-1'
      ..refreshToken = 'refresh-1'
      ..sessionId = 'ses-1';
    final dio = Dio(BaseOptions(baseUrl: 'https://backend.test'));
    String? logoutPath;
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          logoutPath = options.path;
          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              statusCode: 200,
              data: const {'status': 'success'},
            ),
          );
        },
      ),
    );

    final repository = AuthRepositoryImpl(
      remote: AuthRemoteDataSource(dio: dio),
      sessionStore: store,
    );
    await repository.clearSession();

    expect(logoutPath, '/api/v1/auth/logout');
    expect(store.cleared, isTrue);
    expect(store.token, isNull);
  });
}
