import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../../core/notifications/firebase_push_service.dart';
import '../../domain/models/user_model.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository? repository;
  Timer? _countdownTimer;

  /// The application composition root supplies the API-backed repository.
  AuthCubit({this.repository}) : super(const AuthState());

  bool _handleAuthVerificationResult(
    AuthVerification result, {
    required String login,
  }) {
    if (result.requiresPhoneVerification) {
      emit(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          requiresPhoneVerification: true,
          tempToken: result.tempToken,
          socialEmail: result.socialEmail,
          socialName: result.socialName,
          socialProvider: result.socialProvider,
          clearError: true,
        ),
      );
      return false;
    }

    _countdownTimer?.cancel();
    emit(
      AuthState(
        status: result.isRegistered && result.user != null
            ? AuthStatus.authenticated
            : AuthStatus.profileRequired,
        user: result.user,
        sessionToken: result.token,
        isRegistered: result.isRegistered && result.user != null,
        isAdmin: result.isAdmin,
        phoneNumber: login,
        hasCompletedAssessment: result.hasCompletedAssessment,
        nextStep: result.nextStep,
        latestAssessment: result.latestAssessment,
      ),
    );
    if (result.token.isNotEmpty) {
      unawaited(
        FirebasePushService.syncDeviceTokenWithBackend(
          accessToken: result.token,
        ),
      );
    }
    return true;
  }

  Future<void> restoreSession() async {
    final repo = repository;
    if (repo == null) {
      checkAuthStatus();
      return;
    }

    emit(state.copyWith(status: AuthStatus.loading, clearError: true));
    try {
      final restored = await repo.restoreSession();
      if (restored == null) {
        emit(const AuthState(status: AuthStatus.unauthenticated));
        return;
      }
      _handleAuthVerificationResult(restored, login: restored.login);
    } catch (error) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          errorMessage: _message(error, 'Could not restore your session.'),
        ),
      );
    }
  }

  void checkAuthStatus() {
    if (state.status != AuthStatus.initial) return;
    if (repository == null) {
      emit(state.copyWith(status: AuthStatus.unauthenticated));
    } else {
      unawaited(restoreSession());
    }
  }

  Future<bool> sendOtp(String login) async {
    final normalizedLogin = login.trim();
    emit(state.copyWith(status: AuthStatus.loading, clearError: true));
    try {
      final repo = repository;
      if (repo == null) {
        throw const AuthRepositoryException(
          'Authentication is not configured.',
        );
      }
      await repo.requestOtp(normalizedLogin);

      _startCountdownTimer();
      emit(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          isOtpSent: true,
          phoneNumber: normalizedLogin,
          resendCountdown: 30,
          clearError: true,
        ),
      );
      return true;
    } catch (error) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          isOtpSent: false,
          errorMessage: _message(
            error,
            'Could not send the verification code.',
          ),
        ),
      );
      return false;
    }
  }

  Future<bool> resendOtp() async {
    final login = state.phoneNumber;
    if (state.resendCountdown > 0 || login == null || login.isEmpty) {
      return false;
    }
    return sendOtp(login);
  }

  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (isClosed) {
        timer.cancel();
        return;
      }
      final remaining = state.resendCountdown - 1;
      if (remaining <= 0) {
        timer.cancel();
        emit(state.copyWith(resendCountdown: 0));
      } else {
        emit(state.copyWith(resendCountdown: remaining));
      }
    });
  }

  Future<bool> verifyOtp({
    required String otp,
    required String phoneNumber,
  }) async {
    final login = phoneNumber.trim();
    emit(state.copyWith(status: AuthStatus.loading, clearError: true));
    try {
      final repo = repository;
      if (repo == null) {
        throw const AuthRepositoryException(
          'Authentication is not configured.',
        );
      }
      final result = await repo.verifyOtp(login: login, otp: otp.trim());
      return _handleAuthVerificationResult(result, login: login);
    } catch (error) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          errorMessage: _message(error, 'Could not verify the code.'),
        ),
      );
      return false;
    }
  }

  Future<bool> loginWithPassword({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim();
    emit(state.copyWith(status: AuthStatus.loading, clearError: true));
    try {
      final repo = repository;
      if (repo == null) {
        throw const AuthRepositoryException(
          'Authentication is not configured.',
        );
      }
      final result = await repo.loginWithPassword(
        email: cleanEmail,
        password: password,
      );
      return _handleAuthVerificationResult(result, login: cleanEmail);
    } catch (error) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          errorMessage: _message(error, 'Invalid email or password.'),
        ),
      );
      return false;
    }
  }

  Future<bool> sendSignupOtp(String phone, {String? tempToken}) async {
    final normalized = phone.trim();
    final effectiveTempToken = tempToken ?? state.tempToken;
    emit(state.copyWith(status: AuthStatus.loading, clearError: true));
    try {
      final repo = repository;
      if (repo == null) {
        throw const AuthRepositoryException(
          'Authentication is not configured.',
        );
      }
      await repo.sendSignupOtp(normalized, tempToken: effectiveTempToken);

      _startCountdownTimer();
      emit(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          isOtpSent: true,
          phoneNumber: normalized,
          resendCountdown: 30,
          clearError: true,
        ),
      );
      return true;
    } catch (error) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          isOtpSent: false,
          errorMessage: _message(
            error,
            'Could not send the signup code.',
          ),
        ),
      );
      return false;
    }
  }

  Future<bool> registerWithPassword({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String otp,
  }) async {
    final cleanEmail = email.trim();
    emit(state.copyWith(status: AuthStatus.loading, clearError: true));
    try {
      final repo = repository;
      if (repo == null) {
        throw const AuthRepositoryException(
          'Authentication is not configured.',
        );
      }
      final result = await repo.registerWithPassword(
        name: name.trim(),
        email: cleanEmail,
        password: password,
        phone: phone.trim(),
        otp: otp.trim(),
      );
      return _handleAuthVerificationResult(result, login: cleanEmail);
    } catch (error) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          errorMessage: _message(error, 'Registration could not be completed.'),
        ),
      );
      return false;
    }
  }

  Future<bool> loginWithGoogle() async {
    emit(state.copyWith(status: AuthStatus.loading, clearError: true));
    try {
      final googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
      // Always disconnect or signOut prior to prompt so Android/iOS presents the account chooser dialog
      try {
        await googleSignIn.signOut();
      } catch (_) {}

      final account = await googleSignIn.signIn();
      if (account == null) {
        emit(state.copyWith(status: AuthStatus.unauthenticated));
        return false;
      }
      final auth = await account.authentication;
      final idToken = auth.idToken ?? auth.accessToken ?? account.id;

      final repo = repository;
      if (repo == null) {
        throw const AuthRepositoryException(
          'Authentication is not configured.',
        );
      }
      final result = await repo.socialLogin(
        provider: 'google',
        idToken: idToken,
        email: account.email,
        name: account.displayName,
      );

      return _handleAuthVerificationResult(result, login: account.email);
    } catch (error) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          errorMessage: _message(
            error,
            'Google sign-in could not be completed.',
          ),
        ),
      );
      return false;
    }
  }

  Future<bool> loginWithApple() async {
    emit(state.copyWith(status: AuthStatus.loading, clearError: true));
    try {
      final isAvailable = await SignInWithApple.isAvailable();
      if (!isAvailable) {
        throw const AuthRepositoryException(
          'Apple Sign-In is not available on this device.',
        );
      }
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      final idToken =
          credential.identityToken ?? credential.userIdentifier ?? '';
      final email = credential.email;
      final name = [credential.givenName, credential.familyName]
          .where((n) => n != null && n.isNotEmpty)
          .join(' ');

      final repo = repository;
      if (repo == null) {
        throw const AuthRepositoryException(
          'Authentication is not configured.',
        );
      }
      final result = await repo.socialLogin(
        provider: 'apple',
        idToken: idToken,
        email: email?.isNotEmpty == true ? email : null,
        name: name.isNotEmpty ? name : null,
      );

      return _handleAuthVerificationResult(result, login: email ?? 'apple-user');
    } catch (error) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          errorMessage: _message(
            error,
            'Apple sign-in could not be completed.',
          ),
        ),
      );
      return false;
    }
  }

  Future<bool> verifySocialSignup({
    required String phone,
    required String otp,
  }) async {
    final tempToken = state.tempToken;
    if (tempToken == null || tempToken.isEmpty) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          errorMessage: 'Social session expired. Please sign in again.',
        ),
      );
      return false;
    }
    emit(state.copyWith(status: AuthStatus.loading, clearError: true));
    try {
      final repo = repository;
      if (repo == null) {
        throw const AuthRepositoryException(
          'Authentication is not configured.',
        );
      }
      final result = await repo.verifySocialSignup(
        phone: phone.trim(),
        otp: otp.trim(),
        tempToken: tempToken,
      );
      return _handleAuthVerificationResult(result, login: phone.trim());
    } catch (error) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          errorMessage: _message(error, 'Could not verify the code.'),
        ),
      );
      return false;
    }
  }

  void clearSocialPhoneVerification() {
    emit(state.copyWith(clearPhoneVerification: true));
  }

  Future<bool> forgotPassword(String login) async {
    emit(state.copyWith(status: AuthStatus.loading, clearError: true));
    try {
      final repo = repository;
      if (repo == null) {
        throw const AuthRepositoryException('Authentication is not configured.');
      }
      await repo.forgotPassword(login.trim());
      emit(state.copyWith(status: AuthStatus.unauthenticated, clearError: true));
      return true;
    } catch (error) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          errorMessage: _message(error, 'Could not send reset code.'),
        ),
      );
      return false;
    }
  }

  Future<bool> resetPassword({
    required String login,
    required String otp,
    required String newPassword,
  }) async {
    emit(state.copyWith(status: AuthStatus.loading, clearError: true));
    try {
      final repo = repository;
      if (repo == null) {
        throw const AuthRepositoryException('Authentication is not configured.');
      }
      await repo.resetPassword(
        login: login.trim(),
        otp: otp.trim(),
        newPassword: newPassword,
      );
      emit(state.copyWith(status: AuthStatus.unauthenticated, clearError: true));
      return true;
    } catch (error) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          errorMessage: _message(error, 'Could not reset password.'),
        ),
      );
      return false;
    }
  }

  Future<bool> completeProfile({
    required String name,
    required String verifiedLogin,
    int? age,
    String? gender,
    String? city,
    String? occupation,
  }) async {
    emit(state.copyWith(status: AuthStatus.loading, clearError: true));
    try {
      final repo = repository;
      if (repo == null) {
        throw const AuthRepositoryException(
          'Authentication is not configured.',
        );
      }

      final user = await repo.completeProfile(
        verifiedLogin: verifiedLogin,
        name: name.trim(),
        age: age,
        gender: gender,
        city: city,
        occupation: occupation,
      );
      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          isRegistered: true,
          hasCompletedAssessment: false,
          nextStep: 'ASSESSMENT',
          isOtpSent: false,
          clearError: true,
        ),
      );
      if (state.sessionToken?.isNotEmpty == true) {
        unawaited(
          FirebasePushService.syncDeviceTokenWithBackend(
            accessToken: state.sessionToken,
          ),
        );
      }
      return true;
    } catch (error) {
      emit(
        state.copyWith(
          status: AuthStatus.profileRequired,
          errorMessage: _message(error, 'Could not save your profile.'),
        ),
      );
      return false;
    }
  }

  Future<bool> updateProfile({
    String? name,
    String? email,
    String? phone,
    int? age,
    bool clearAge = false,
    String? gender,
    String? city,
    String? occupation,
    Uint8List? photoBytes,
    String? photoFilename,
    String? photoUrl,
    bool clearPhoto = false,
  }) async {
    final current = state.user;
    if (current == null) return false;
    emit(state.copyWith(clearError: true));
    try {
      final repo = repository;
      UserModel updated;
      if (repo == null) {
        throw const AuthRepositoryException(
          'Authentication is not configured.',
        );
      } else {
        String? uploadedPhotoUrl;
        if (!clearPhoto && photoBytes != null && photoFilename != null) {
          uploadedPhotoUrl = await repo.uploadProfilePhoto(
            bytes: photoBytes,
            filename: photoFilename,
          );
        }
        updated = await repo.updateProfile(
          name: name,
          age: age,
          clearAge: clearAge,
          gender: gender,
          city: city,
          occupation: occupation,
          profileUrl: uploadedPhotoUrl,
          clearProfileUrl: clearPhoto,
        );
      }
      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          user: updated,
          clearError: true,
        ),
      );
      return true;
    } catch (error) {
      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          user: current,
          errorMessage: _message(error, 'Could not update your profile.'),
        ),
      );
      return false;
    }
  }

  Future<void> refreshProfile() async {
    final repo = repository;
    if (repo == null) return;
    try {
      final restored = await repo.restoreSession();
      if (restored?.user != null) {
        emit(state.copyWith(user: restored!.user, clearError: true));
      }
    } catch (error) {
      emit(
        state.copyWith(
          errorMessage: _message(error, 'Could not refresh your profile.'),
        ),
      );
    }
  }

  void resetToPhoneStep() {
    _countdownTimer?.cancel();
    emit(
      state.copyWith(
        status: AuthStatus.unauthenticated,
        isOtpSent: false,
        resendCountdown: 0,
        phoneNumber: '',
        clearError: true,
      ),
    );
  }

  Future<void> signOut() async {
    _countdownTimer?.cancel();
    final currentToken = state.sessionToken;
    emit(const AuthState(status: AuthStatus.unauthenticated));
    if (currentToken != null && currentToken.isNotEmpty) {
      unawaited(
        FirebasePushService.unregisterDeviceToken(accessToken: currentToken),
      );
    }
    try {
      final googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();
    } catch (_) {}
    try {
      await repository?.clearSession();
    } catch (_) {
      // Local session storage must still be cleared by the repository even if
      // remote revocation is unavailable.
    }
  }

  Future<bool> deleteAccount() async {
    _countdownTimer?.cancel();
    emit(state.copyWith(status: AuthStatus.loading, clearError: true));
    try {
      final repo = repository;
      if (repo != null) {
        await repo.deleteAccount();
      }
      emit(const AuthState(status: AuthStatus.unauthenticated));
      return true;
    } catch (error) {
      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          errorMessage: _message(
            error,
            'Could not delete your account. Please try again.',
          ),
        ),
      );
      return false;
    }
  }

  String _message(Object error, String fallback) {
    if (error is AuthRepositoryException && error.message.isNotEmpty) {
      return error.message;
    }
    return fallback;
  }

  @visibleForTesting
  void emitForTesting(AuthState nextState) => emit(nextState);

  @override
  Future<void> close() {
    _countdownTimer?.cancel();
    return super.close();
  }
}
