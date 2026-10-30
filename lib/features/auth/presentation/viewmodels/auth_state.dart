import '../../domain/models/user_model.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  profileRequired,
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
  final String? sessionToken;
  final bool isRegistered;
  final bool isAdmin;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
    this.resendCountdown = 0,
    this.isOtpSent = false,
    this.phoneNumber,
    this.sessionToken,
    this.isRegistered = false,
    this.isAdmin = false,
  });

  bool get isAuthenticated =>
      status == AuthStatus.authenticated &&
          (user != null || sessionToken != null) ||
      status == AuthStatus.profileRequired && sessionToken != null;
  bool get requiresProfileCompletion => status == AuthStatus.profileRequired;
  bool get isGuest => user?.isGuest ?? false;
  bool get canResendOtp => resendCountdown <= 0;

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? errorMessage,
    int? resendCountdown,
    bool? isOtpSent,
    String? phoneNumber,
    String? sessionToken,
    bool? isRegistered,
    bool? isAdmin,
    bool clearUser = false,
    bool clearError = false,
    bool clearSession = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      resendCountdown: resendCountdown ?? this.resendCountdown,
      isOtpSent: isOtpSent ?? this.isOtpSent,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      sessionToken: clearSession ? null : (sessionToken ?? this.sessionToken),
      isRegistered: isRegistered ?? this.isRegistered,
      isAdmin: isAdmin ?? this.isAdmin,
    );
  }
}
