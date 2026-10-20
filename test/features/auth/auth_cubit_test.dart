import 'package:flutter_test/flutter_test.dart';
import 'package:dr_hair/features/auth/presentation/viewmodels/auth_cubit.dart';
import 'package:dr_hair/features/auth/presentation/viewmodels/auth_state.dart';

void main() {
  group('AuthCubit Tests', () {
    late AuthCubit cubit;

    setUp(() {
      cubit = AuthCubit();
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state has AuthStatus.initial and no user', () {
      expect(cubit.state.status, AuthStatus.initial);
      expect(cubit.state.user, isNull);
      expect(cubit.state.isAuthenticated, isFalse);
    });

    test('checkAuthStatus updates initial state to unauthenticated', () {
      cubit.checkAuthStatus();
      expect(cubit.state.status, AuthStatus.unauthenticated);
      expect(cubit.state.isAuthenticated, isFalse);
    });

    test('login sets user and transitions to authenticated', () async {
      final loginFuture = cubit.login(
        identifier: '9876543210',
        name: 'Sunil Sharma',
      );
      expect(cubit.state.status, AuthStatus.loading);
      await loginFuture;

      expect(cubit.state.status, AuthStatus.authenticated);
      expect(cubit.state.isAuthenticated, isTrue);
      expect(cubit.state.user?.name, 'Sunil Sharma');
      expect(cubit.state.user?.emailOrPhone, '9876543210');
      expect(cubit.state.isGuest, isFalse);
    });

    test('loginWithDemo sets demo patient credentials', () async {
      await cubit.loginWithDemo();

      expect(cubit.state.status, AuthStatus.authenticated);
      expect(cubit.state.isAuthenticated, isTrue);
      expect(cubit.state.user?.name, 'Yashveer Soni');
      expect(cubit.state.user?.patientId, 'DRH-2024-8849');
      expect(cubit.state.isGuest, isFalse);
    });

    test('loginAsGuest sets guest user profile', () {
      cubit.loginAsGuest();

      expect(cubit.state.status, AuthStatus.authenticated);
      expect(cubit.state.isAuthenticated, isTrue);
      expect(cubit.state.user?.name, 'Guest User');
      expect(cubit.state.isGuest, isTrue);
    });

    test('signOut clears authenticated session', () async {
      await cubit.loginWithDemo();
      expect(cubit.state.isAuthenticated, isTrue);

      cubit.signOut();
      expect(cubit.state.status, AuthStatus.unauthenticated);
      expect(cubit.state.user, isNull);
      expect(cubit.state.isAuthenticated, isFalse);
    });
  });
}
