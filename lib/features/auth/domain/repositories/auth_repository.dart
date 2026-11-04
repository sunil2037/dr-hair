import 'dart:typed_data';

import '../../domain/models/user_model.dart';

class AuthVerification {
  final String token;
  final String login;
  final bool isRegistered;
  final bool isAdmin;
  final String? refreshToken;
  final String? sessionId;
  final UserModel? user;
  final bool hasCompletedAssessment;
  final String? nextStep;
  final Map<String, dynamic>? latestAssessment;
  final bool requiresPhoneVerification;
  final String? tempToken;
  final String? socialEmail;
  final String? socialName;
  final String? socialProvider;

  const AuthVerification({
    required this.token,
    required this.login,
    required this.isRegistered,
    required this.isAdmin,
    this.refreshToken,
    this.sessionId,
    this.user,
    this.hasCompletedAssessment = false,
    this.nextStep,
    this.latestAssessment,
    this.requiresPhoneVerification = false,
    this.tempToken,
    this.socialEmail,
    this.socialName,
    this.socialProvider,
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
  /// Requests a real SMS OTP. The code is never returned to the client.
  Future<void> requestOtp(String login);

  Future<AuthVerification> verifyOtp({
    required String login,
    required String otp,
  });

  /// Authenticate with email and password
  Future<AuthVerification> loginWithPassword({
    required String email,
    required String password,
  });

  /// Requests a real 6-digit signup verification OTP for a mobile number
  Future<void> sendSignupOtp(String phone);

  /// Registers a new patient with Name, Email, Password, Phone, and verified OTP
  Future<AuthVerification> registerWithPassword({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String otp,
  });

  /// Social Login with Google or Apple
  Future<AuthVerification> socialLogin({
    required String provider,
    required String idToken,
    String? email,
    String? name,
  });

  /// Complete social signup with verified phone number and OTP
  Future<AuthVerification> verifySocialSignup({
    required String phone,
    required String otp,
    required String tempToken,
  });

  /// Request password reset code
  Future<void> forgotPassword(String login);

  /// Reset password with verified code
  Future<void> resetPassword({
    required String login,
    required String otp,
    required String newPassword,
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
