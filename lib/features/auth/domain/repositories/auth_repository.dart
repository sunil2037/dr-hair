import 'dart:typed_data';

import '../../domain/models/user_model.dart';

class AuthVerification {
  final String token;
  final String login;
  final bool isRegistered;
  final bool isAdmin;
  final UserModel? user;
  final bool hasCompletedAssessment;
  final String? nextStep;
  final Map<String, dynamic>? latestAssessment;

  const AuthVerification({
    required this.token,
    required this.login,
    required this.isRegistered,
    required this.isAdmin,
    this.user,
    this.hasCompletedAssessment = false,
    this.nextStep,
    this.latestAssessment,
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
  /// Returns a local development OTP only when the backend explicitly opts in.
  Future<String?> requestOtp(String login);

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

  Future<void> deleteAccount();

  Future<void> clearSession();
}
