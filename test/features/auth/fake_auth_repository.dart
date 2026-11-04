import 'dart:typed_data';

import 'package:dr_hair/features/auth/domain/models/user_model.dart';
import 'package:dr_hair/features/auth/domain/repositories/auth_repository.dart';

/// Offline API-boundary fake for authentication widget and Cubit tests.
class FakeAuthRepository implements AuthRepository {
  final String? testOtp;
  final bool registered;
  final UserModel? initialUser;
  String? lastRequestedLogin;
  String? lastVerifiedLogin;
  String? lastVerifiedOtp;
  int requestCount = 0;
  int verifyCount = 0;
  bool sessionCleared = false;

  FakeAuthRepository({
    this.testOtp = '123456',
    this.registered = true,
    this.initialUser,
  });

  UserModel _user(String login) =>
      initialUser ??
      UserModel(
        id: '12',
        name: 'Sunil Sharma',
        emailOrPhone: login,
        phone: login,
        patientId: 'DHP0012',
        loggedInAt: DateTime.utc(2026, 1, 1),
      );

  @override
  Future<void> requestOtp(String login) async {
    requestCount++;
    lastRequestedLogin = login;
  }

  @override
  Future<AuthVerification> verifyOtp({
    required String login,
    required String otp,
  }) async {
    verifyCount++;
    lastVerifiedLogin = login;
    lastVerifiedOtp = otp;
    if (testOtp != null && otp != testOtp) {
      throw const AuthRepositoryException('Invalid OTP code.');
    }
    return AuthVerification(
      token: 'unit-test-token',
      login: login,
      isRegistered: registered,
      isAdmin: false,
      user: registered ? _user(login) : null,
      hasCompletedAssessment: registered,
      nextStep: registered ? 'HOME' : 'COMPLETE_PROFILE',
    );
  }

  @override
  Future<AuthVerification> loginWithPassword({
    required String email,
    required String password,
  }) async {
    if (password.length < 6) {
      throw const AuthRepositoryException('Invalid email or password.');
    }
    lastRequestedLogin = email;
    return AuthVerification(
      token: 'unit-test-token',
      login: email,
      isRegistered: registered,
      isAdmin: false,
      user: registered ? _user(email) : null,
      hasCompletedAssessment: registered,
      nextStep: registered ? 'HOME' : 'COMPLETE_PROFILE',
    );
  }

  @override
  Future<void> sendSignupOtp(String phone) async {
    requestCount++;
    lastRequestedLogin = phone;
  }

  @override
  Future<AuthVerification> registerWithPassword({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String otp,
  }) async {
    verifyCount++;
    lastVerifiedLogin = phone;
    lastVerifiedOtp = otp;
    return AuthVerification(
      token: 'unit-test-token',
      login: email,
      isRegistered: registered,
      isAdmin: false,
      user: registered
          ? UserModel(
              id: '12',
              name: name,
              emailOrPhone: email,
              email: email,
              phone: phone,
              patientId: 'DHP0012',
              loggedInAt: DateTime.utc(2026, 1, 1),
            )
          : null,
      hasCompletedAssessment: registered,
      nextStep: registered ? 'HOME' : 'COMPLETE_PROFILE',
    );
  }

  @override
  Future<AuthVerification> socialLogin({
    required String provider,
    required String idToken,
    String? email,
    String? name,
  }) async {
    final login = email ?? 'social-user@drhair.com';
    return AuthVerification(
      token: 'unit-test-token',
      login: login,
      isRegistered: true,
      isAdmin: false,
      user: _user(login),
      hasCompletedAssessment: registered,
      nextStep: registered ? 'HOME' : 'ASSESSMENT',
    );
  }

  @override
  Future<AuthVerification> verifySocialSignup({
    required String phone,
    required String otp,
    required String tempToken,
  }) async {
    return AuthVerification(
      token: 'unit-test-token',
      login: phone,
      isRegistered: true,
      isAdmin: false,
      user: _user(phone),
      hasCompletedAssessment: false,
      nextStep: 'ASSESSMENT',
    );
  }

  @override
  Future<void> forgotPassword(String login) async {
    requestCount++;
    lastRequestedLogin = login;
  }

  @override
  Future<void> resetPassword({
    required String login,
    required String otp,
    required String newPassword,
  }) async {
    verifyCount++;
    lastVerifiedLogin = login;
    lastVerifiedOtp = otp;
  }

  @override
  Future<AuthVerification?> restoreSession() async {
    if (initialUser == null) return null;
    final user = initialUser!;
    final login = user.emailOrPhone;
    return AuthVerification(
      token: 'restored-token',
      login: login,
      isRegistered: true,
      isAdmin: false,
      user: user,
      hasCompletedAssessment: true,
      nextStep: 'HOME',
    );
  }

  @override
  Future<UserModel> completeProfile({
    required String verifiedLogin,
    required String name,
    int? age,
    String? gender,
    String? city,
    String? occupation,
  }) async => _user(verifiedLogin).copyWith(
    name: name,
    age: age,
    gender: gender,
    city: city,
    occupation: occupation,
  );

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
  }) async => _user('9876543210').copyWith(
    name: name,
    age: clearAge ? null : age,
    gender: gender,
    city: city,
    occupation: occupation,
    photoUrl: profileUrl,
    clearPhotoUrl: clearProfileUrl,
  );

  @override
  Future<String?> uploadProfilePhoto({
    required Uint8List bytes,
    required String filename,
  }) async => 'https://example.test/profile.jpg';

  @override
  Future<void> removeProfilePhoto() async {}

  @override
  Future<void> deleteAccount() async {
    sessionCleared = true;
  }

  @override
  Future<void> clearSession() async {
    sessionCleared = true;
  }
}
