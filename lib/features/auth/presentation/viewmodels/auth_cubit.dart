import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/models/user_model.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  Timer? _countdownTimer;

  AuthCubit() : super(const AuthState());

  void checkAuthStatus() {
    if (state.status == AuthStatus.initial) {
      emit(state.copyWith(status: AuthStatus.unauthenticated));
    }
  }

  /// Sends a 6-digit OTP to the provided [phoneNumber] and starts a 30-second countdown.
  Future<void> sendOtp(String phoneNumber) async {
    emit(state.copyWith(status: AuthStatus.loading, clearError: true));
    await Future.delayed(const Duration(milliseconds: 250));

    _startCountdownTimer();
    emit(
      state.copyWith(
        status: AuthStatus.unauthenticated,
        isOtpSent: true,
        phoneNumber: phoneNumber,
        resendCountdown: 30,
        clearError: true,
      ),
    );
  }

  /// Resends the OTP and restarts the 30-second countdown timer.
  Future<void> resendOtp() async {
    if (state.resendCountdown > 0) return;

    emit(state.copyWith(status: AuthStatus.loading, clearError: true));
    await Future.delayed(const Duration(milliseconds: 200));

    _startCountdownTimer();
    emit(
      state.copyWith(
        status: AuthStatus.unauthenticated,
        resendCountdown: 30,
        clearError: true,
      ),
    );
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

  /// Verifies the 6-digit [otp] against the [phoneNumber].
  Future<bool> verifyOtp({
    required String otp,
    required String phoneNumber,
    String? name,
  }) async {
    emit(state.copyWith(status: AuthStatus.loading, clearError: true));
    await Future.delayed(const Duration(milliseconds: 300));

    if (otp.trim() != '123456') {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          errorMessage: 'Use the demo code 123456 to continue.',
        ),
      );
      return false;
    }

    _countdownTimer?.cancel();
    final resolvedName = (name != null && name.trim().isNotEmpty)
        ? name.trim()
        : 'Yashveer Soni';

    final user = UserModel(
      id: 'USR-${DateTime.now().millisecondsSinceEpoch % 10000}',
      name: resolvedName,
      emailOrPhone: phoneNumber,
      patientId: 'DRH-2024-8849',
      isGuest: false,
      loggedInAt: DateTime.now(),
    );

    emit(
      state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        isOtpSent: false,
        resendCountdown: 0,
        clearError: true,
      ),
    );
    return true;
  }

  Future<void> login({required String identifier, String? name}) async {
    emit(state.copyWith(status: AuthStatus.loading));
    await Future.delayed(const Duration(milliseconds: 200));
    final resolvedName = (name != null && name.trim().isNotEmpty)
        ? name.trim()
        : 'Yashveer Soni';

    final user = UserModel(
      id: 'USR-${DateTime.now().millisecondsSinceEpoch % 10000}',
      name: resolvedName,
      emailOrPhone: identifier,
      patientId: 'DRH-2024-8849',
      isGuest: false,
      loggedInAt: DateTime.now(),
    );

    emit(
      state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        clearError: true,
      ),
    );
  }

  Future<void> loginWithDemo() async {
    _countdownTimer?.cancel();
    emit(state.copyWith(status: AuthStatus.loading));
    await Future.delayed(const Duration(milliseconds: 200));
    emit(
      state.copyWith(
        status: AuthStatus.authenticated,
        user: UserModel.demoPatient(),
        isOtpSent: false,
        resendCountdown: 0,
        clearError: true,
      ),
    );
  }

  void loginAsGuest() {
    _countdownTimer?.cancel();
    emit(
      state.copyWith(
        status: AuthStatus.authenticated,
        user: UserModel.guest(),
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
        isOtpSent: false,
        resendCountdown: 0,
        clearError: true,
      ),
    );
  }

  void updateProfile({
    String? name,
    String? emailOrPhone,
    String? email,
    String? phone,
    String? photoUrl,
    bool clearPhoto = false,
  }) {
    final current = state.user ?? UserModel.demoPatient();
    final updated = current.copyWith(
      name: name,
      emailOrPhone: emailOrPhone,
      email: email,
      phone: phone,
      photoUrl: photoUrl,
      clearPhotoUrl: clearPhoto,
    );
    emit(state.copyWith(user: updated));
  }

  void signOut() {
    _countdownTimer?.cancel();
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }

  @override
  Future<void> close() {
    _countdownTimer?.cancel();
    return super.close();
  }
}
