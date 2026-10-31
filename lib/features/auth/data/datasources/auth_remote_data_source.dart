import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/media/data/media_upload_api.dart';
import '../../../../core/network/dio_client.dart';

class AuthRemoteDataSource {
  final Dio _dio;
  late final MediaUploadApi _mediaUploadApi = MediaUploadApi(dio: _dio);

  AuthRemoteDataSource({Dio? dio})
    : _dio = dio ?? DioClient(baseUrl: ApiEndpoints.backendBaseUrl).dio;

  Future<Map<String, dynamic>> requestOtp(String login) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/auth/send_login_otp',
      data: {'login': login},
      options: Options(extra: const {'sensitive': true}),
    );
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> verifyOtp({
    required String login,
    required String otp,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/auth/verify_login_otp',
      data: {'login': login, 'otp': otp},
      options: Options(extra: const {'sensitive': true}),
    );
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> getProfile(String token) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/users/get_profile',
      options: _authorized(token),
    );
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> getSession(String token) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/auth/session',
      options: _authorized(token),
    );
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> register({
    required String token,
    required String verifiedLogin,
    required String name,
    int? age,
    String? gender,
    String? city,
    String? occupation,
  }) async {
    final login = verifiedLogin.trim();
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/users/loginSignup',
      data: {
        'name': name,
        if (login.contains('@')) 'email': login,
        if (!login.contains('@')) 'phone': login,
        'age': ?age,
        if (gender?.isNotEmpty == true) 'gender': gender,
        if (city?.isNotEmpty == true) 'city': city,
        if (occupation?.isNotEmpty == true) 'occupation': occupation,
        'platform': 'app',
      },
      options: _authorized(token),
    );
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> updateProfile({
    required String token,
    String? name,
    int? age,
    bool clearAge = false,
    String? gender,
    String? city,
    String? occupation,
    String? profileUrl,
    bool clearProfileUrl = false,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/users/updateProfile',
      data: {
        'name': ?name,
        'age': ?age,
        if (clearAge) 'age': null,
        'gender': ?gender,
        'city': ?city,
        'occupation': ?occupation,
        'profile_url': ?profileUrl,
        if (clearProfileUrl) 'profile_url': null,
      },
      options: _authorized(token),
    );
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> uploadProfilePhoto({
    required String token,
    required List<int> bytes,
    required String filename,
  }) async {
    final items = await _mediaUploadApi.uploadFiles(
      token: token,
      purpose: 'profile',
      files: [MultipartFile.fromBytes(bytes, filename: filename)],
    );
    return {'status': 'success', 'data': items.first};
  }

  Future<Map<String, dynamic>> removeProfilePhoto(String token) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/users/updateProfile',
      data: {'profile_url': null},
      options: _authorized(token),
    );
    return _asMap(response.data);
  }

  Options _authorized(String token) => Options(
    headers: {'Authorization': 'Bearer $token'},
    extra: const {'sensitive': true},
  );

  Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return const {};
  }
}
