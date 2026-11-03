import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../../core/storage/app_local_cache.dart';
import '../../../../core/storage/secure_session_store.dart';
import '../../domain/models/user_model.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remote;
  final AuthSessionStore _sessionStore;

  AuthRepositoryImpl({
    AuthRemoteDataSource? remote,
    AuthSessionStore? sessionStore,
  }) : _remote = remote ?? AuthRemoteDataSource(),
       _sessionStore = sessionStore ?? SecureSessionStore();

  @override
  Future<String?> requestOtp(String login) async {
    try {
      final response = await _remote.requestOtp(login);
      final testOtp =
          response['test_otp']?.toString() ?? response['otp']?.toString();
      return testOtp != null && RegExp(r'^\d{6}$').hasMatch(testOtp)
          ? testOtp
          : null;
    } on DioException catch (error) {
      throw _mapError(error, fallback: 'Could not send the verification code.');
    }
  }

  @override
  Future<AuthVerification> verifyOtp({
    required String login,
    required String otp,
  }) async {
    try {
      final response = await _remote.verifyOtp(login: login, otp: otp);
      final responseData = _mapValue(response['data']);
      final token = _stringValue(response, responseData, 'token');
      if (token.isEmpty) {
        throw const AuthRepositoryException(
          'The server did not return a session.',
        );
      }
      final isRegistered = _boolValue(response, responseData, 'is_registered');
      final hasCompletedAssessment = _boolValue(
        response,
        responseData,
        'has_completed_assessment',
      );
      final nextStep = _stringValue(response, responseData, 'next_step');
      final refreshToken = _stringValue(
        response,
        responseData,
        'refresh_token',
      );
      final sessionId = _stringValue(response, responseData, 'session_id');
      await _sessionStore.writeSession(
        token: token,
        login: login,
        refreshToken: refreshToken.isEmpty ? null : refreshToken,
        sessionId: sessionId.isEmpty ? null : sessionId,
      );
      if (hasCompletedAssessment) {
        await AppLocalCache.instance.put('has_completed_hair_test', true);
      }
      final profile = isRegistered ? _profileFromResponse(responseData) : null;
      var user = profile == null
          ? null
          : UserModel.fromJson(profile, fallbackLogin: login);
      if (isRegistered && user == null) {
        user = await _loadProfile(token, fallbackLogin: login);
      }
      return AuthVerification(
        token: token,
        login: login,
        isRegistered: isRegistered,
        isAdmin: response['is_admin'] == true,
        refreshToken: refreshToken.isEmpty ? null : refreshToken,
        sessionId: sessionId.isEmpty ? null : sessionId,
        user: user,
        hasCompletedAssessment: hasCompletedAssessment,
        nextStep: nextStep,
      );
    } on DioException catch (error) {
      throw _mapError(error, fallback: 'Could not verify the code.');
    }
  }

  @override
  Future<AuthVerification?> restoreSession() async {
    var token = await _sessionStore.readToken();
    final refreshToken = await _sessionStore.readRefreshToken();
    final sessionId = await _sessionStore.readSessionId();
    if ((token == null || token.isEmpty) &&
        (refreshToken == null ||
            refreshToken.isEmpty ||
            sessionId == null ||
            sessionId.isEmpty)) {
      return null;
    }
    final login = await _sessionStore.readLogin() ?? '';
    try {
      if (token == null || token.isEmpty) {
        token = await _rotateAccessToken(
          refreshToken: refreshToken,
          sessionId: sessionId,
          login: login,
        );
        if (token == null || token.isEmpty) return null;
      }
      Map<String, dynamic> sessionResponse;
      try {
        sessionResponse = await _remote.getSession(token);
      } on DioException catch (error) {
        if (error.response?.statusCode != 401) {
          rethrow;
        }
        if (refreshToken == null || refreshToken.isEmpty) {
          await _sessionStore.clear();
          return null;
        }
        token = await _rotateAccessToken(
          refreshToken: refreshToken,
          sessionId: sessionId,
          login: login,
        );
        if (token == null || token.isEmpty) return null;
        sessionResponse = await _remote.getSession(token);
      }
      final sessionData = _mapValue(sessionResponse['data']);
      final isRegistered = sessionData?['is_registered'] == true;
      final hasCompletedAssessment =
          sessionData?['has_completed_assessment'] == true;
      final nextStep = sessionData?['next_step']?.toString();
      final latestAssessment = _mapValue(sessionData?['latest_assessment']);

      if (hasCompletedAssessment) {
        await AppLocalCache.instance.put('has_completed_hair_test', true);
        if (latestAssessment != null) {
          final stage = latestAssessment['hair_loss_stage']?.toString();
          if (stage != null && stage.isNotEmpty) {
            await AppLocalCache.instance.put('hair_test_stage', stage);
          }
        }
      }

      if (!isRegistered) {
        return AuthVerification(
          token: token,
          login: sessionData?['login']?.toString() ?? login,
          isRegistered: false,
          isAdmin: sessionData?['is_admin'] == true,
          hasCompletedAssessment: hasCompletedAssessment,
          nextStep: nextStep,
          latestAssessment: latestAssessment,
          refreshToken: await _sessionStore.readRefreshToken(),
          sessionId: await _sessionStore.readSessionId(),
        );
      }
      final profile = _mapValue(sessionData?['user']);
      final user = profile == null
          ? await _loadProfile(token, fallbackLogin: login)
          : UserModel.fromJson(profile, fallbackLogin: login);
      return AuthVerification(
        token: token,
        login: sessionData?['login']?.toString() ?? login,
        isRegistered: true,
        isAdmin: sessionData?['is_admin'] == true,
        user: user,
        hasCompletedAssessment: hasCompletedAssessment,
        nextStep: nextStep,
        latestAssessment: latestAssessment,
        refreshToken: await _sessionStore.readRefreshToken(),
        sessionId: await _sessionStore.readSessionId(),
      );
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        await _sessionStore.clear();
        return null;
      }
      throw _mapError(error, fallback: 'Could not restore your session.');
    }
  }

  @override
  Future<UserModel> completeProfile({
    required String verifiedLogin,
    required String name,
    int? age,
    String? gender,
    String? city,
    String? occupation,
  }) async {
    final token = await _requireToken();
    try {
      final response = await _remote.register(
        token: token,
        verifiedLogin: verifiedLogin,
        name: name,
        age: age,
        gender: gender,
        city: city,
        occupation: occupation,
      );
      final nextToken = response['token']?.toString();
      if (nextToken?.isNotEmpty == true) {
        await _sessionStore.writeSession(
          token: nextToken!,
          login: verifiedLogin,
          refreshToken: _stringValue(
            response,
            _mapValue(response['data']),
            'refresh_token',
          ),
          sessionId: _stringValue(
            response,
            _mapValue(response['data']),
            'session_id',
          ),
        );
      }
      final profile = _mapValue(response['data']);
      if (profile == null) {
        throw const AuthRepositoryException(
          'The server saved the profile but returned no profile data.',
        );
      }
      return UserModel.fromJson(profile, fallbackLogin: verifiedLogin);
    } on DioException catch (error) {
      throw _mapError(error, fallback: 'Could not save your profile.');
    }
  }

  @override
  Future<UserModel> updateProfile({
    String? name,
    int? age,
    bool clearAge = false,
    String? gender,
    String? city,
    String? occupation,
    String? profileUrl,
    bool clearProfileUrl = false,
  }) async {
    final token = await _requireToken();
    try {
      final response = await _remote.updateProfile(
        token: token,
        name: name,
        age: age,
        clearAge: clearAge,
        gender: gender,
        city: city,
        occupation: occupation,
        profileUrl: profileUrl,
        clearProfileUrl: clearProfileUrl,
      );
      final profile = _mapValue(response['data']);
      if (profile == null) {
        throw const AuthRepositoryException(
          'The server returned no updated profile.',
        );
      }
      return UserModel.fromJson(profile);
    } on DioException catch (error) {
      throw _mapError(error, fallback: 'Could not update your profile.');
    }
  }

  @override
  Future<String?> uploadProfilePhoto({
    required Uint8List bytes,
    required String filename,
  }) async {
    final token = await _requireToken();
    try {
      final response = await _remote.uploadProfilePhoto(
        token: token,
        bytes: bytes,
        filename: filename,
      );
      final url = _mapValue(response['data'])?['url']?.toString();
      if (url == null || url.isEmpty) {
        throw const AuthRepositoryException(
          'The media service returned no uploaded file URL.',
        );
      }
      return url;
    } on DioException catch (error) {
      throw _mapError(error, fallback: 'Could not upload your profile photo.');
    }
  }

  @override
  Future<void> removeProfilePhoto() async {
    final token = await _requireToken();
    try {
      await _remote.removeProfilePhoto(token);
    } on DioException catch (error) {
      throw _mapError(error, fallback: 'Could not remove your profile photo.');
    }
  }

  @override
  Future<void> deleteAccount() async {
    final token = await _sessionStore.readToken();
    if (token != null && token.isNotEmpty) {
      try {
        await _remote.deleteAccount(token);
      } on DioException catch (error) {
        // Map error unless it's already a 404 (already deleted)
        if (error.response?.statusCode != 404) {
          throw _mapError(error, fallback: 'Could not delete your account.');
        }
      }
    }
    await _sessionStore.clear();
  }

  @override
  Future<void> clearSession() async {
    final token = await _sessionStore.readToken();
    if (token != null && token.isNotEmpty) {
      await _remote.logout(token).catchError((_) {});
    }
    await _sessionStore.clear();
  }

  Future<UserModel> _loadProfile(
    String token, {
    String fallbackLogin = '',
  }) async {
    final response = await _remote.getProfile(token);
    final profile = _mapValue(response['data']);
    if (profile == null) {
      throw const AuthRepositoryException(
        'The server returned no profile data.',
      );
    }
    return UserModel.fromJson(profile, fallbackLogin: fallbackLogin);
  }

  Future<String> _requireToken() async {
    final token = await _sessionStore.readToken();
    if (token == null || token.isEmpty) {
      throw const AuthRepositoryException(
        'Your session expired. Sign in again.',
        statusCode: 401,
      );
    }
    return token;
  }

  Future<String?> _rotateAccessToken({
    required String? refreshToken,
    required String? sessionId,
    required String login,
  }) async {
    if (refreshToken == null ||
        refreshToken.isEmpty ||
        sessionId == null ||
        sessionId.isEmpty) {
      await _sessionStore.clear();
      return null;
    }
    try {
      final refreshed = await _remote.refreshSession(
        refreshToken: refreshToken,
        sessionId: sessionId,
      );
      final refreshedData = _mapValue(refreshed['data']);
      final refreshedToken = _stringValue(refreshed, refreshedData, 'token');
      final rotatedRefresh = _stringValue(
        refreshed,
        refreshedData,
        'refresh_token',
      );
      final rotatedSession = _stringValue(
        refreshed,
        refreshedData,
        'session_id',
      );
      if (refreshedToken.isEmpty ||
          rotatedRefresh.isEmpty ||
          rotatedSession.isEmpty) {
        await _sessionStore.clear();
        return null;
      }
      await _sessionStore.writeSession(
        token: refreshedToken,
        login: login,
        refreshToken: rotatedRefresh,
        sessionId: rotatedSession,
      );
      return refreshedToken;
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        await _sessionStore.clear();
        return null;
      }
      rethrow;
    }
  }

  Map<String, dynamic>? _mapValue(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  AuthRepositoryException _mapError(
    DioException error, {
    required String fallback,
  }) {
    final response = _mapValue(error.response?.data);
    final message = response?['message']?.toString();
    return AuthRepositoryException(
      message?.isNotEmpty == true ? message! : fallback,
      statusCode: error.response?.statusCode,
    );
  }

  String _stringValue(
    Map<String, dynamic> response,
    Map<String, dynamic>? data,
    String key,
  ) => response[key]?.toString() ?? data?[key]?.toString() ?? '';

  bool _boolValue(
    Map<String, dynamic> response,
    Map<String, dynamic>? data,
    String key,
  ) => response[key] == true || data?[key] == true;

  Map<String, dynamic>? _profileFromResponse(Map<String, dynamic>? data) {
    if (data == null) return null;
    final nestedUser = _mapValue(data['user']);
    if (nestedUser != null) return nestedUser;
    if (data['id'] != null ||
        data['user_id'] != null ||
        (data['name'] != null && data['name'].toString().trim().isNotEmpty)) {
      return data;
    }
    return null;
  }
}
