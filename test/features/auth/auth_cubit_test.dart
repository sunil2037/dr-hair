import 'package:flutter_test/flutter_test.dart';
import 'package:dr_hair/features/auth/presentation/viewmodels/auth_cubit.dart';
import 'package:dr_hair/features/auth/presentation/viewmodels/auth_state.dart';

import 'fake_auth_repository.dart';

void main() {
  group('AuthCubit Tests', () {
    late AuthCubit cubit;
    late FakeAuthRepository repository;

    setUp(() {
      repository = FakeAuthRepository();
      cubit = AuthCubit(repository: repository);
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state has AuthStatus.initial and no user', () {
      expect(cubit.state.status, AuthStatus.initial);
      expect(cubit.state.user, isNull);
      expect(cubit.state.isAuthenticated, isFalse);
    });

    test('checkAuthStatus updates initial state to unauthenticated', () async {
      cubit.checkAuthStatus();
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.status, AuthStatus.unauthenticated);
      expect(cubit.state.isAuthenticated, isFalse);
    });

    test(
      'OTP is requested through repository and debug code is retained',
      () async {
        expect(await cubit.sendOtp('+91 9876543210'), isTrue);
        expect(repository.requestCount, 1);
        expect(repository.lastRequestedLogin, '+91 9876543210');
        expect(cubit.state.isOtpSent, isTrue);
        expect(cubit.state.developmentOtp, '123456');
      },
    );

    test(
      'verification uses repository and creates API session state',
      () async {
        await cubit.sendOtp('9876543210');
        expect(
          await cubit.verifyOtp(otp: '123456', phoneNumber: '9876543210'),
          isTrue,
        );
        expect(repository.verifyCount, 1);
        expect(repository.lastVerifiedOtp, '123456');
        expect(cubit.state.status, AuthStatus.authenticated);
        expect(cubit.state.sessionToken, 'unit-test-token');
        expect(cubit.state.user?.patientId, 'DHP0012');
      },
    );

    test('OTP cannot be sent without a configured API repository', () async {
      final unconfigured = AuthCubit();
      expect(await unconfigured.sendOtp('9876543210'), isFalse);
      expect(unconfigured.state.isAuthenticated, isFalse);
      expect(unconfigured.state.isOtpSent, isFalse);
      await unconfigured.close();
    });

    test('signOut clears authenticated session', () async {
      await cubit.sendOtp('9876543210');
      await cubit.verifyOtp(otp: '123456', phoneNumber: '9876543210');
      expect(cubit.state.isAuthenticated, isTrue);

      cubit.signOut();
      expect(cubit.state.status, AuthStatus.unauthenticated);
      expect(cubit.state.user, isNull);
      expect(cubit.state.isAuthenticated, isFalse);
      expect(repository.sessionCleared, isTrue);
    });
  });
}
