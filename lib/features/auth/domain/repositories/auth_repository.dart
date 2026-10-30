import 'dart:typed_data';

import '../../domain/models/user_model.dart';

class AuthVerification {
  final String token;
  final String login;
  final bool isRegistered;
  final bool isAdmin;
  final UserModel? user;

  const AuthVerification({
    required this.token,
    required this.login,
    required this.isRegistered,
    required this.isAdmin,
    this.user,
  });
}

class AuthRepositoryException implements Exception {
  final String message;
  final int? statusCode;

  const AuthRepositoryException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

abstract interface class AuthRepository {
  Future<void> requestOtp(String login);

  Future<AuthVerification> verifyOtp({
    required String login,
    required String otp,
  });

  Future<AuthVerification?> restoreSession();

  Future<UserModel> completeProfile({
    required String verifiedLogin,
    required String name,
    int? age,
    String? gender,
    String? city,
    String? occupation,
  });

  Future<UserModel> updateProfile({
    String? name,
    int? age,
    bool clearAge = false,
    String? gender,
    String? city,
    String? occupation,
    String? profileUrl,
    bool clearProfileUrl = false,
  });

  Future<String?> uploadProfilePhoto({
    required Uint8List bytes,
    required String filename,
  });

  Future<void> removeProfilePhoto();

  Future<void> clearSession();
}
