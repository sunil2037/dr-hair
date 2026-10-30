import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/models/user_model.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository? repository;
  Timer? _countdownTimer;

  /// The app composition root always supplies the API repository. The no-arg
  /// path remains a local-only preview for the existing widget tests.
  AuthCubit({this.repository}) : super(const AuthState());

  bool get _canUseLocalPreview => repository == null && kDebugMode;

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
      emit(
        AuthState(
          status: restored.isRegistered && restored.user != null
              ? AuthStatus.authenticated
              : AuthStatus.profileRequired,
          user: restored.user,
          sessionToken: restored.token,
          phoneNumber: restored.login,
          isAdmin: restored.isAdmin,
          isRegistered: restored.isRegistered && restored.user != null,
        ),
      );
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
      if (repository case final repo?) {
        await repo.requestOtp(normalizedLogin);
      } else if (_canUseLocalPreview) {
        await Future<void>.delayed(const Duration(milliseconds: 250));
      } else {
        throw const AuthRepositoryException(
          'Authentication is not configured.',
        );
      }

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
    String? name,
  }) async {
    final login = phoneNumber.trim();
    emit(state.copyWith(status: AuthStatus.loading, clearError: true));
    try {
      final repo = repository;
      if (repo != null) {
        final result = await repo.verifyOtp(login: login, otp: otp.trim());
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
          ),
        );
        return true;
      }

      if (!_canUseLocalPreview) {
        throw const AuthRepositoryException(
          'Authentication is not configured.',
        );
      }
      await Future<void>.delayed(const Duration(milliseconds: 300));
      if (otp.trim() != '123456') {
        throw const AuthRepositoryException(
          'Use the development test code to continue.',
        );
      }
      _countdownTimer?.cancel();
      final user = UserModel.demoPatient(identifier: login).copyWith(
        name: (name?.trim().isNotEmpty ?? false) ? name!.trim() : null,
      );
      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          isRegistered: true,
          isOtpSent: false,
          resendCountdown: 0,
          clearError: true,
        ),
      );
      return true;
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
        if (!_canUseLocalPreview) {
          throw const AuthRepositoryException(
            'Authentication is not configured.',
          );
        }
        final user = UserModel(
          id: 'PREVIEW-USER',
          name: name.trim(),
          emailOrPhone: verifiedLogin,
          phone: verifiedLogin.contains('@') ? null : verifiedLogin,
          email: verifiedLogin.contains('@') ? verifiedLogin : null,
          age: age,
          gender: gender,
          city: city,
          occupation: occupation,
          patientId: 'PREVIEW-USER',
          loggedInAt: DateTime.now(),
        );
        emit(
          state.copyWith(
            status: AuthStatus.authenticated,
            user: user,
            isRegistered: true,
            isOtpSent: false,
            clearError: true,
          ),
        );
        return true;
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
          isOtpSent: false,
          clearError: true,
        ),
      );
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
    emit(state.copyWith(status: AuthStatus.loading, clearError: true));
    try {
      final repo = repository;
      UserModel updated;
      if (repo == null) {
        if (!_canUseLocalPreview) {
          throw const AuthRepositoryException(
            'Authentication is not configured.',
          );
        }
        updated = current.copyWith(
          name: name,
          email: email,
          phone: phone,
          age: age,
          gender: gender,
          city: city,
          occupation: occupation,
          photoUrl: photoUrl,
          clearPhotoUrl: clearPhoto,
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

  Future<void> login({required String identifier, String? name}) async {
    if (repository != null || !_canUseLocalPreview) return;
    emit(state.copyWith(status: AuthStatus.loading));
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final user = UserModel.demoPatient(
      identifier: identifier,
    ).copyWith(name: (name?.trim().isNotEmpty ?? false) ? name!.trim() : null);
    emit(
      state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        clearError: true,
      ),
    );
  }

  Future<void> loginWithDemo() async {
    if (repository != null || !_canUseLocalPreview) return;
    _countdownTimer?.cancel();
    emit(state.copyWith(status: AuthStatus.loading));
    await Future<void>.delayed(const Duration(milliseconds: 200));
    emit(
      state.copyWith(
        status: AuthStatus.authenticated,
        user: UserModel.demoPatient(),
        isRegistered: true,
        isOtpSent: false,
        resendCountdown: 0,
        clearError: true,
      ),
    );
  }

  void loginAsGuest() {
    if (repository != null || !_canUseLocalPreview) return;
    _countdownTimer?.cancel();
    emit(
      state.copyWith(
        status: AuthStatus.authenticated,
        user: UserModel.guest(),
        isRegistered: false,
        isOtpSent: false,
        resendCountdown: 0,
        clearError: true,
      ),
    );
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

  void signOut() {
    _countdownTimer?.cancel();
    final clearFuture = repository?.clearSession();
    if (clearFuture != null) unawaited(clearFuture.catchError((_) {}));
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }

  String _message(Object error, String fallback) {
    if (error is AuthRepositoryException && error.message.isNotEmpty) {
      return error.message;
    }
    return fallback;
  }

  @override
  Future<void> close() {
    _countdownTimer?.cancel();
    return super.close();
  }
}
