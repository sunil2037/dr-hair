import '../../domain/models/user_model.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  failure,
}

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;
  final int resendCountdown;
  final bool isOtpSent;
  final String? phoneNumber;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
    this.resendCountdown = 0,
    this.isOtpSent = false,
    this.phoneNumber,
  });

  bool get isAuthenticated => status == AuthStatus.authenticated && user != null;
  bool get isGuest => user?.isGuest ?? false;
  bool get canResendOtp => resendCountdown <= 0;

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? errorMessage,
    int? resendCountdown,
    bool? isOtpSent,
    String? phoneNumber,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      resendCountdown: resendCountdown ?? this.resendCountdown,
      isOtpSent: isOtpSent ?? this.isOtpSent,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }
}
