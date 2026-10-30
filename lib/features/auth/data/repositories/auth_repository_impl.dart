import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../../core/storage/secure_session_store.dart';
import '../../domain/models/user_model.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remote;
  final SecureSessionStore _sessionStore;

  AuthRepositoryImpl({
    AuthRemoteDataSource? remote,
    SecureSessionStore? sessionStore,
  }) : _remote = remote ?? AuthRemoteDataSource(),
       _sessionStore = sessionStore ?? SecureSessionStore();

  @override
  Future<void> requestOtp(String login) async {
    try {
      await _remote.requestOtp(login);
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
      final token = response['token']?.toString() ?? '';
      if (token.isEmpty) {
        throw const AuthRepositoryException(
          'The server did not return a session.',
        );
      }
      final isRegistered = response['is_registered'] == true;
      await _sessionStore.writeSession(token: token, login: login);
      final profile = _mapValue(response['data']);
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
        user: user,
      );
    } on DioException catch (error) {
      throw _mapError(error, fallback: 'Could not verify the code.');
    }
  }

  @override
  Future<AuthVerification?> restoreSession() async {
    final token = await _sessionStore.readToken();
    if (token == null || token.isEmpty) return null;
    final login = await _sessionStore.readLogin() ?? '';
    try {
      final sessionResponse = await _remote.getSession(token);
      final sessionData = _mapValue(sessionResponse['data']);
      final isRegistered = sessionData?['is_registered'] == true;
      if (!isRegistered) {
        return AuthVerification(
          token: token,
          login: sessionData?['login']?.toString() ?? login,
          isRegistered: false,
          isAdmin: sessionData?['is_admin'] == true,
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
  Future<void> clearSession() => _sessionStore.clear();

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
}
