import 'dart:typed_data';

import 'package:dr_hair/features/auth/domain/models/user_model.dart';
import 'package:dr_hair/features/auth/domain/repositories/auth_repository.dart';

/// Offline API-boundary fake for authentication widget and Cubit tests.
class FakeAuthRepository implements AuthRepository {
  final String? testOtp;
  final bool registered;
  String? lastRequestedLogin;
  String? lastVerifiedLogin;
  String? lastVerifiedOtp;
  int requestCount = 0;
  int verifyCount = 0;
  bool sessionCleared = false;

  FakeAuthRepository({this.testOtp = '123456', this.registered = true});

  UserModel _user(String login) => UserModel(
    id: '12',
    name: 'Sunil Sharma',
    emailOrPhone: login,
    phone: login,
    patientId: 'DHP0012',
    loggedInAt: DateTime.utc(2026, 1, 1),
  );

  @override
  Future<String?> requestOtp(String login) async {
    requestCount++;
    lastRequestedLogin = login;
    return testOtp;
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
  Future<AuthVerification?> restoreSession() async => null;

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
  Future<void> clearSession() async {
    sessionCleared = true;
  }
}
